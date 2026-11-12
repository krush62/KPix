/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;

/// Layers of the document that register with the raster scheduler.
int _liveScheduledLayers()
{
  final Set<LayerState> live = <LayerState>{};
  for (final Frame frame in _timeline.frames.value)
  {
    live.addAll(frame.layerList.getAllLayers());
  }
  return live.where((final LayerState layer) => layer is! ReferenceLayerState).length;
}

void _expectNoStrayLayers()
{
  expect(rasterScheduler.registeredLayerCount, _liveScheduledLayers(),
      reason: "a layer outside the document still registered with the scheduler is never released",);
}

void _releaseDocument()
{
  for (final Frame frame in _timeline.frames.value)
  {
    frame.layerList.clear(notify: false);
  }
}

ReferenceLayerState? _referenceLayer()
{
  for (final LayerState layer in _timeline.selectedFrame!.layerList.getAllLayers())
  {
    if (layer is ReferenceLayerState)
    {
      return layer;
    }
  }
  return null;
}

void main()
{
  final CoordinateSetI size = CoordinateSetI(x: 4, y: 4);

  testWidgets("a new project releases the layers of the previous one", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: size, body: (final ProjectSession projectSession) async {
      final LayerState previous = _timeline.selectedFrame!.layerList.getLayer(index: 0);

      projectSession.init(dimensions: size);
      await settle();

      expect(previous.isDisposed, isTrue);
      _expectNoStrayLayers();
      _releaseDocument();
    },);
  });

  testWidgets("deleting a frame releases the layers only it held", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: size, body: (final ProjectSession projectSession) async {
      final LayerState shared = _timeline.selectedFrame!.layerList.getLayer(index: 0);
      _timeline.linkFrameRight();
      _timeline.addNewFrameRight();
      await settle();
      expect(_timeline.frames.value.length, 3, reason: "setup");
      final Frame own = _timeline.selectedFrame!;
      final LayerState ownLayer = own.layerList.getLayer(index: 0);

      _timeline.deleteFrame();
      await settle();

      expect(ownLayer.isDisposed, isTrue);
      expect(own.layerList.isEmpty, isTrue, reason: "the collection lets go of its layers and composite");

      _timeline.selectFrameByIndex(index: 1);
      _timeline.deleteFrame();
      await settle();

      expect(shared.isDisposed, isFalse, reason: "the first frame still links the layer");
      _expectNoStrayLayers();
      _releaseDocument();
    },);
  });

  testWidgets("an imported image replaces the previous project's layers", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: size, body: (final ProjectSession projectSession) async {
      final LayerState previous = _timeline.selectedFrame!.layerList.getLayer(index: 0);
      final DrawingLayerState imported = DrawingLayerState(size: size, ramps: GetIt.I.get<PaletteState>().colorRamps);

      projectSession.importFile(importResult: ImportResult(
        result: ImageImportResult.success,
        data: ImportDataSet(referenceLayer: null, rampDataList: GetIt.I.get<PaletteState>().colorRamps, drawingLayer: imported, canvasSize: size),
      ),);
      await settle();

      expect(previous.isDisposed, isTrue);
      expect(imported.isDisposed, isFalse);
      _expectNoStrayLayers();
      _releaseDocument();
    },);
  });

  testWidgets("undoing a new frame releases the frame's layers", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: size, body: (final ProjectSession projectSession) async {
      _timeline.addNewFrameRight();
      await settle();
      final LayerState added = _timeline.selectedFrame!.layerList.getLayer(index: 0);

      await GetIt.I.get<HistoryController>().undoPressed()!.restore;
      await settle();

      expect(_timeline.frames.value.length, 1, reason: "setup");
      expect(added.isDisposed, isTrue);
      _expectNoStrayLayers();
      _releaseDocument();
    },);
  });

  testWidgets("a reference image is kept while undo can bring it back and released after", (final WidgetTester tester) async {
    await tester.pumpWidget(const ToastificationWrapper(child: MaterialApp(home: SizedBox.shrink())));
    late ReferenceImage image;
    await tester.runAsync(() async {
      final ProjectSession projectSession = await bootProject(canvasSize: size);
      final ReferenceImageManager images = GetIt.I.get<ReferenceImageManager>();
      image = await loadedReferenceImage();
      GetIt.I.get<LayerManager>().addReferenceLayerWithImage(image: image, select: true);
      await settle();
      GetIt.I.get<LayerManager>().layerDeletedSelected(deleteLayer: _referenceLayer());
      await settle();

      expect(await images.loadImageFile(path: image.path), same(image), reason: "an undo step still shows it");
      await GetIt.I.get<HistoryController>().undoPressed()!.restore;
      expect(_referenceLayer()?.image, same(image));

      projectSession.init(dimensions: size);
      await settle();
      //the file does not exist, so only the cache could answer
      expect(await images.loadImageFile(path: image.path), isNull);
      _releaseDocument();
    });
    await tester.pump();
    expect(image.image.debugDisposed, isTrue);
  });

  testWidgets("a duplicate reference image is released in favour of the cached one", (final WidgetTester tester) async {
    await tester.pumpWidget(const ToastificationWrapper(child: MaterialApp(home: SizedBox.shrink())));
    late ReferenceImage first;
    late ReferenceImage second;
    await tester.runAsync(() async {
      await bootProject(canvasSize: size);
      first = await loadedReferenceImage();
      second = await loadedReferenceImage();
      _releaseDocument();
    });
    await tester.pump();
    expect(second, same(first));
    expect(first.image.debugDisposed, isFalse);
  });
}
