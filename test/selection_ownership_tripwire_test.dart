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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  /// Two drawing layers with a pixel on the upper one, lifted into the selection.
  /// Returns (upper, lower).
  Future<(DrawingLayerState, DrawingLayerState)> setUp({required final AppState appState}) async
  {
    final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
    final DrawingLayerState lower = layerAt(appState: appState, index: 0);
    final DrawingLayerState upper = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
    upper.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
    await settle(appState: appState);

    appState.selectionState.selectAll();
    await settle(appState: appState);
    return (upper, lower);
  }

  testWidgets("the selection records which layer its content came from", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      expect(appState.selectionState.selection.owner, isNull, reason: "nothing floating, nothing owned");

      final (DrawingLayerState upper, DrawingLayerState _) = await setUp(appState: appState);
      expect(appState.selectionState.selection.owner, same(upper),
          reason: "the pixels were taken out of the upper layer",);
    },);
  });

  testWidgets("ownership follows the content across a layer switch", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState _, DrawingLayerState lower) = await setUp(appState: appState);

      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);

      expect(appState.selectionState.selection.owner, same(lower),
          reason: "the hand-over moved the content, so it moved the ownership with it",);
    },);
  });

  testWidgets("ownership is released when the selection empties", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      await setUp(appState: appState);
      expect(appState.selectionState.selection.owner, isNotNull);

      appState.selectionState.deselect(addToHistoryStack: false);
      await settle(appState: appState);

      expect(appState.selectionState.selection.owner, isNull, reason: "nothing floats, so nobody owns it");
    },);
  });

  testWidgets("deselecting onto a layer the content does not belong to is caught", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState _, DrawingLayerState lower) = await setUp(appState: appState);

      //LayerCollection.selectLayer changes the selected layer without handing the
      //content over - the shape of every drift bug found so far. Deleting a layer
      //and reordering past the selected one both used to reach the selection this
      //way, and stamped the floating pixels onto whatever ended up selected.
      appState.timeline.selectedFrame!.layerList.selectLayer(newLayer: lower);
      await settle(appState: appState);

      expect(
        () => appState.selectionState.deselect(addToHistoryStack: false),
        throwsAssertionError,
        reason: "writing the content to a layer it never came from has to be loud, not silent",
      );
    },);
  });

  testWidgets("adding to a selection that belongs elsewhere is caught", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState _, DrawingLayerState lower) = await setUp(appState: appState);
      appState.selectionState.deselect(addToHistoryStack: false);
      await settle(appState: appState);

      //select on the lower layer, then move the selected layer out from under it
      appState.selectLayer(newLayer: lower);
      appState.selectionState.selectAll();
      await settle(appState: appState);
      appState.timeline.selectedFrame!.layerList.selectLayer(newLayer: layerAt(appState: appState, index: 0));
      await settle(appState: appState);

      expect(
        () => appState.selectionState.selection.transferAll(coords: <CoordinateSetI>{pixel}),
        throwsAssertionError,
        reason: "lifting more pixels into a selection owned by another layer would mix two layers together",
      );
    },);
  });

  testWidgets("a proper layer switch stays quiet", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState upper, DrawingLayerState lower) = await setUp(appState: appState);

      //the supported route hands the content over, so nothing is out of place
      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);
      appState.selectLayer(newLayer: upper);
      await settle(appState: appState);
      appState.selectionState.deselect(addToHistoryStack: false);
      await settle(appState: appState);

      expect(copiesOf(appState: appState, coord: pixel), 1, reason: "and the pixel is where it started");
    },);
  });
}
