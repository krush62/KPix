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
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/selection_harness.dart';

/// Changes to reference layer properties (position, zoom, ...) are history steps.
void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);

  LayerCollection layerList() => GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList;

  ReferenceLayerState addReferenceLayer()
  {
    return GetIt.I.get<LayerManager>().addNewLayer(layerType: ReferenceLayerState, select: true).$2! as ReferenceLayerState;
  }

  Future<void> undo() async
  {
    await GetIt.I.get<HistoryController>().undoPressed()!.restore;
  }

  Future<void> redo() async
  {
    await GetIt.I.get<HistoryController>().redoPressed()!.restore;
  }

  testWidgets("a property change can be undone and redone", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      GetIt.I.registerSingleton<ReferenceImageManager>(ReferenceImageManager());
      final ReferenceLayerState reference = addReferenceLayer();
      final int position = layerList().getLayerPosition(state: reference)!;
      final int defaultZoom = reference.zoomSliderValue;

      reference.offsetXNotifier.value = 5;
      reference.offsetYNotifier.value = -3;
      reference.setZoomSliderValue(newVal: defaultZoom + 100);
      GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: reference);
      expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.layerSettingsChange);

      await undo();
      final ReferenceLayerState undone = layerList().getLayer(index: position) as ReferenceLayerState;
      expect(undone.offsetX, 0);
      expect(undone.offsetY, 0);
      expect(undone.zoomSliderValue, defaultZoom);

      await redo();
      final ReferenceLayerState redone = layerList().getLayer(index: position) as ReferenceLayerState;
      expect(redone.offsetX, 5);
      expect(redone.offsetY, -3);
      expect(redone.zoomSliderValue, defaultZoom + 100);
    },);
  });

  testWidgets("an interaction that changed nothing adds no step", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      GetIt.I.registerSingleton<ReferenceImageManager>(ReferenceImageManager());
      final HistoryManager history = GetIt.I.get<HistoryManager>();
      final ReferenceLayerState reference = addReferenceLayer();
      final int position = layerList().getLayerPosition(state: reference)!;

      GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: reference);
      expect(history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerNewReference);

      reference.offsetXNotifier.value = 5;
      GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: reference);
      await undo();

      //the restore replaced the layer object, which must still be recognized as unchanged
      final ReferenceLayerState restored = layerList().getLayer(index: position) as ReferenceLayerState;
      GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: restored);
      expect(history.hasRedo.value, isTrue, reason: "a no-op commit must not discard the redo step");
    },);
  });

  testWidgets("merging keeps steps of different layers apart", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      GetIt.I.registerSingleton<ReferenceImageManager>(ReferenceImageManager());
      final LayerManager layers = GetIt.I.get<LayerManager>();
      final ReferenceLayerState first = addReferenceLayer();
      final ReferenceLayerState second = addReferenceLayer();
      final int firstPosition = layerList().getLayerPosition(state: first)!;

      first.offsetXNotifier.value = 5;
      layers.commitReferenceLayerChange(layer: first);
      //enough steps on the second layer to push the first step into the compressed part
      for (int i = 1; i <= 20; i++)
      {
        second.offsetXNotifier.value = i.toDouble();
        layers.commitReferenceLayerChange(layer: second);
      }

      int guard = 0;
      while (GetIt.I.get<HistoryManager>().getCurrentIdentifier() != HistoryStateTypeIdentifier.layerNewReference && guard++ < 50)
      {
        await undo();
      }
      final ReferenceLayerState restoredFirst = layerList().getLayer(index: firstPosition) as ReferenceLayerState;
      expect(restoredFirst.offsetX, 0, reason: "the change of the first layer must not be merged away");
    },);
  });
}
