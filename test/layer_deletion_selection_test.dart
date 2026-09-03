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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/selection_harness.dart';

List<LayerState> _layers({required final AppState appState})
{
  final List<LayerState> layers = <LayerState>[];
  for (int i = 0; i < appState.timeline.selectedFrame!.layerList.length; i++)
  {
    layers.add(appState.timeline.selectedFrame!.layerList.getLayer(index: i));
  }
  return layers;
}

Future<List<LayerState>> _threeLayers({required final AppState appState}) async
{
  appState.addNewLayer(layerType: DrawingLayerState);
  appState.addNewLayer(layerType: DrawingLayerState);
  await settle(appState: appState);
  final List<LayerState> layers = _layers(appState: appState);
  expect(layers.length, 3, reason: "setup: three layers, top to bottom");
  return layers;
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);

  testWidgets("deleting the selected layer selects the one that takes its place", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final List<LayerState> before = await _threeLayers(appState: appState);
      appState.selectLayer(newLayer: before[1]);
      await settle(appState: appState);

      appState.layerDeletedSelected(deleteLayer: before[1]);
      await settle(appState: appState);

      expect(_layers(appState: appState), <LayerState>[before[0], before[2]]);
      expect(appState.timeline.getCurrentLayer(), same(before[2]),
          reason: "the layer that moved up into the gap is the natural next selection",);
    },);
  });

  testWidgets("deleting the selected bottom layer selects the one above it", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final List<LayerState> before = await _threeLayers(appState: appState);
      appState.selectLayer(newLayer: before[2]);
      await settle(appState: appState);

      appState.layerDeletedSelected(deleteLayer: before[2]);
      await settle(appState: appState);

      expect(_layers(appState: appState), <LayerState>[before[0], before[1]]);
      expect(appState.timeline.getCurrentLayer(), same(before[1]),
          reason: "there is nothing below, so the selection moves up instead",);
    },);
  });

  testWidgets("deleting a layer above the selected one keeps the selection", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final List<LayerState> before = await _threeLayers(appState: appState);
      appState.selectLayer(newLayer: before[2]);
      await settle(appState: appState);

      appState.layerDeletedSelected(deleteLayer: before[0]);
      await settle(appState: appState);

      expect(_layers(appState: appState), <LayerState>[before[1], before[2]]);
      expect(appState.timeline.getCurrentLayer(), same(before[2]),
          reason: "deleting an unrelated layer must not move the selection",);
    },);
  });

  testWidgets("deleting a layer below the selected one keeps the selection", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final List<LayerState> before = await _threeLayers(appState: appState);
      appState.selectLayer(newLayer: before[0]);
      await settle(appState: appState);

      appState.layerDeletedSelected(deleteLayer: before[2]);
      await settle(appState: appState);

      expect(_layers(appState: appState), <LayerState>[before[0], before[1]]);
      expect(appState.timeline.getCurrentLayer(), same(before[0]));
    },);
  });

  testWidgets("the last layer cannot be deleted", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final LayerState only = layerAt(appState: appState, index: 0);
      appState.layerDeletedSelected(deleteLayer: only);
      await settle(appState: appState);

      expect(_layers(appState: appState), <LayerState>[only]);
      expect(appState.timeline.getCurrentLayer(), same(only));
    },);
  });
}
