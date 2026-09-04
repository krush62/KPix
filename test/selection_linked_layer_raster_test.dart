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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Whether the rendered image has anything opaque at [coord].
Future<bool> _isPainted({required final ui.Image image, required final CoordinateSetI coord}) async
{
  final ByteData? bytes = await image.toByteData();
  final int index = (coord.y * image.width + coord.x) * 4;
  return bytes!.getUint8(index + 3) != 0;
}

/// The raster the layer produced for [frame].
Future<ui.Image> _rasterFor({required final DrawingLayerState layer, required final Frame frame}) async
{
  final ui.Image? image = layer.rasterImageMap.value[frame]?.raster;
  expect(image, isNotNull, reason: "the layer has not produced a raster for this frame yet");
  return image!;
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI origin = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI moved = CoordinateSetI(x: 2, y: 0);

  testWidgets("a floating selection is only rendered into the frame it sits in", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle();

      //link the layer into a second frame, so one layer feeds two rasters
      timeline.linkFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle();

      final Frame frameOne = timeline.frames.value[0];
      final Frame frameTwo = timeline.frames.value[1];
      expect(frameOne.layerList.getLayer(index: 0), same(layer), reason: "setup: the same layer object");
      expect(frameTwo.layerList.getLayer(index: 0), same(layer), reason: "setup: in both frames");
      expect(timeline.selectedFrame, same(frameOne), reason: "setup: the first frame is selected");

      //lift the pixel into the selection and drag it somewhere else
      GetIt.I.get<DocumentState>().selectionState.selectAll();
      GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 2, y: 0), withContent: true);
      GetIt.I.get<DocumentState>().selectionState.finishMovement();
      layer.doManualRaster = true;
      await settle();

      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: moved), color, reason: "setup: the content moved");
      expect(layer.getDataEntry(coord: origin), isNull, reason: "setup: and left the layer");

      final ui.Image rasterOne = await _rasterFor(layer: layer, frame: frameOne);
      final ui.Image rasterTwo = await _rasterFor(layer: layer, frame: frameTwo);

      expect(await _isPainted(image: rasterOne, coord: moved), isTrue,
          reason: "the selected frame shows the floating content at its dragged position",);
      expect(await _isPainted(image: rasterTwo, coord: moved), isFalse,
          reason: "the other frame is not where the selection sits, so it must not show a drag in progress",);
      expect(await _isPainted(image: rasterTwo, coord: origin), isFalse,
          reason: "the pixel is out of the layer while it floats, so the other frame shows nothing",);
    },);
  });

  testWidgets("an unlinked layer still shows its own floating selection", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle();

      GetIt.I.get<DocumentState>().selectionState.selectAll();
      GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 2, y: 0), withContent: true);
      GetIt.I.get<DocumentState>().selectionState.finishMovement();
      layer.doManualRaster = true;
      await settle();

      final ui.Image raster = await _rasterFor(layer: layer, frame: GetIt.I.get<DocumentState>().timeline.frames.value[0]);
      expect(await _isPainted(image: raster, coord: moved), isTrue,
          reason: "the ordinary single-frame case has to keep compositing the selection",);
      expect(await _isPainted(image: raster, coord: origin), isFalse);
    },);
  });

  testWidgets("the other frame shows the content again once it is committed", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle();

      timeline.linkFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle();

      GetIt.I.get<DocumentState>().selectionState.selectAll();
      GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 2, y: 0), withContent: true);
      GetIt.I.get<DocumentState>().selectionState.finishMovement();
      await settle();

      //anchoring writes the pixels into the shared layer, so both frames show them
      GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
      layer.doManualRaster = true;
      await settle();

      final ui.Image rasterTwo = await _rasterFor(layer: layer, frame: timeline.frames.value[1]);
      expect(await _isPainted(image: rasterTwo, coord: moved), isTrue,
          reason: "a linked layer shares its pixels, so a committed move shows up in every frame",);
    },);
  });
}
