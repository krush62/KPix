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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI origin = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI moved = CoordinateSetI(x: 2, y: 0);

  testWidgets("a linked layer reports different pixels for each frame it sits in", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle();

      timeline.linkFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle();

      final Frame frameOne = timeline.frames.value[0];
      final Frame frameTwo = timeline.frames.value[1];
      expect(frameTwo.layerList.getLayer(index: 0), same(layer), reason: "setup: one layer, two frames");

      GetIt.I.get<DocumentState>().selectionState.selectAll();
      GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 2, y: 0), withContent: true);
      GetIt.I.get<DocumentState>().selectionState.finishMovement();
      layer.doManualRaster = true;
      await settle();

      expect(layer.pixelsForFrame(frame: frameOne)[moved], color,
          reason: "the selected frame composites the floating content",);
      expect(layer.pixelsForFrame(frame: frameTwo)[moved], isNull,
          reason: "a dependent layer in the other frame must not compose with a drag that is not there",);
      expect(layer.pixelsForFrame(frame: frameTwo)[origin], isNull,
          reason: "and the pixel is out of the layer while it floats",);
    },);
  });

  testWidgets("an unlinked layer reports the same pixels with or without a frame", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle();

      final Frame frame = GetIt.I.get<DocumentState>().timeline.frames.value[0];
      expect(layer.pixelsForFrame(frame: frame)[origin], color);
      expect(layer.pixelsForFrame(frame: null)[origin], color,
          reason: "callers without a frame keep getting the selected frame's pixels",);
    },);
  });

  testWidgets("frames the layer has left stop being reported", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle();

      timeline.linkFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle();
      final Frame frameTwo = timeline.frames.value[1];
      expect(layer.rasterPixelsByFrame.containsKey(frameTwo), isTrue, reason: "setup: both frames are tracked");

      timeline.selectFrameByIndex(index: 1);
      timeline.deleteFrame();
      layer.doManualRaster = true;
      await settle();

      expect(layer.rasterPixelsByFrame.containsKey(frameTwo), isFalse,
          reason: "a per frame map for a frame the layer no longer sits in would never be released",);
    },);
  });
}
