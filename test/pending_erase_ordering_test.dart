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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';

import 'support/selection_harness.dart';

void _write({
  required final DrawingLayerState layer,
  required final Map<CoordinateSetI, ColorReference?> pixels,
})
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(pixels));
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI left = CoordinateSetI(x: 1, y: 1);
  //flipping a 4 wide canvas maps x to 3 - x, so these two swap places and each
  //one's destination is the other one's source
  final CoordinateSetI right = CoordinateSetI(x: 2, y: 1);

  testWidgets("an erasure issued during a raster does not outlive a later write", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference before = appState.colorRamps.first.references.first;
      final ColorReference after = appState.colorRamps.first.references.last;

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, pixels: <CoordinateSetI, ColorReference?>{left: before});
      await settle(appState: appState);

      //pin the window: a raster is in flight, which is when the erasure used to
      //be deferred behind everything issued after it
      layer.isRasterizing = true;
      layer.removeDataAll(removeCoordList: <CoordinateSetI>{left});
      _write(layer: layer, pixels: <CoordinateSetI, ColorReference?>{left: after});
      layer.isRasterizing = false;
      await settle(appState: appState);

      expect(layer.getDataEntry(coord: left), after,
          reason: "the write came after the erasure, so it is the one that survives",);
    },);
  });

  testWidgets("an erasure issued during a raster still erases", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = appState.colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, pixels: <CoordinateSetI, ColorReference?>{left: color});
      await settle(appState: appState);

      layer.isRasterizing = true;
      layer.removeDataAll(removeCoordList: <CoordinateSetI>{left});
      layer.isRasterizing = false;
      await settle(appState: appState);

      expect(layer.getDataEntry(coord: left), isNull, reason: "an erasure on its own still has to erase");
    },);
  });

  testWidgets("flipping during a raster keeps the layer", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference leftColor = appState.colorRamps.first.references.first;
      final ColorReference rightColor = appState.colorRamps.first.references.last;
      expect(rightColor, isNot(leftColor), reason: "setup: the two colours have to be distinguishable");

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, pixels: <CoordinateSetI, ColorReference?>{left: leftColor, right: rightColor});
      await settle(appState: appState);

      //transformLayer removes the old coordinates and then writes the rotated
      //ones. Here every destination is also somebody's source, so a deferred
      //erasure lands on the finished result and wipes the whole layer.
      layer.isRasterizing = true;
      layer.transformLayer(transformation: CanvasTransformation.flipH, oldSize: canvasSize);
      layer.isRasterizing = false;
      await settle(appState: appState);

      expect(layer.getDataEntry(coord: left), rightColor, reason: "the two pixels swap sides");
      expect(layer.getDataEntry(coord: right), leftColor);
    },);
  });

  testWidgets("flipping outside a raster keeps working", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference leftColor = appState.colorRamps.first.references.first;
      final ColorReference rightColor = appState.colorRamps.first.references.last;

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, pixels: <CoordinateSetI, ColorReference?>{left: leftColor, right: rightColor});
      await settle(appState: appState);

      layer.transformLayer(transformation: CanvasTransformation.flipH, oldSize: canvasSize);
      await settle(appState: appState);

      expect(layer.getDataEntry(coord: left), rightColor, reason: "the quiet case has to keep working too");
      expect(layer.getDataEntry(coord: right), leftColor);
    },);
  });

  testWidgets("selecting during a raster takes the pixels out of the layer", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = appState.colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, pixels: <CoordinateSetI, ColorReference?>{left: color});
      await settle(appState: appState);

      //a selection lifts pixels by reading them and then erasing them; while the
      //erasure was deferred the pixel briefly sat on the layer and in the
      //selection at once, and a history snapshot taken in that window kept both
      layer.isRasterizing = true;
      appState.selectionState.selectAll();
      expect(copiesOf(appState: appState, coord: left), 1,
          reason: "the pixel may not be on the layer and in the selection at the same time",);

      layer.isRasterizing = false;
      await settle(appState: appState);
      expect(copiesOf(appState: appState, coord: left), 1);
    },);
  });
}
