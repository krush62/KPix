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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Puts [color] at [coord] on [layer] and waits for it to reach the layer data.
Future<void> _paint({
  required final ProjectSession projectSession,
  required final DrawingLayerState layer,
  required final CoordinateSetI coord,
  required final ColorReference color,
}) async
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{coord: color}));
  await settle();
}

/// The layers of the selected frame, top to bottom.
List<LayerState> _layers({required final ProjectSession projectSession})
{
  final List<LayerState> layers = <LayerState>[];
  for (int i = 0; i < GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.length; i++)
  {
    layers.add(GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getLayer(index: i));
  }
  return layers;
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  group("deleting a layer", () {
    testWidgets("does not strand the floating content on an unrelated layer", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState keeper = layerAt(projectSession: projectSession, index: 0);
        final DrawingLayerState doomed = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await _paint(projectSession: projectSession, layer: doomed, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), color, reason: "setup: the pixel is floating");

        GetIt.I.get<LayerManager>().layerDeletedSelected(deleteLayer: doomed);
        await settle();

        expect(GetIt.I.get<DocumentState>().selectionState.selection.selectedPixels, isEmpty,
            reason: "the layer the content belongs to is gone, so nothing may still be floating",);
        expect(keeper.getDataEntry(coord: pixel), isNull,
            reason: "the deleted layer's pixels must not reappear on the layer that happens to be selected next",);
      },);
    });

    testWidgets("keeps content that was handed to a layer that survives", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState keeper = layerAt(projectSession: projectSession, index: 0);
        final DrawingLayerState doomed = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await _paint(projectSession: projectSession, layer: keeper, coord: pixel, color: color);

        //select on the keeper, so the floating content belongs to it
        GetIt.I.get<LayerManager>().selectLayer(newLayer: keeper);
        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();

        GetIt.I.get<LayerManager>().layerDeletedSelected(deleteLayer: doomed);
        await settle();

        expect(keeper.getDataEntry(coord: pixel), color, reason: "the content belongs to a layer that is still there");
        expect(copiesOf(projectSession: projectSession, coord: pixel), 1);
      },);
    });
  });

  group("reordering layers", () {
    testWidgets("keeps the same layer selected when one moves down past it", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        await settle();

        final List<LayerState> before = _layers(projectSession: projectSession);
        expect(before.length, 3, reason: "setup: three layers");
        GetIt.I.get<LayerManager>().selectLayer(newLayer: before[1]);
        await settle();
        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(before[1]));

        //drag the top layer to the bottom, across the selected one
        GetIt.I.get<LayerManager>().changeLayerOrder(state: before[0], newPosition: 3);
        await settle();

        expect(_layers(projectSession: projectSession), <LayerState>[before[1], before[2], before[0]], reason: "setup: the move happened");
        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(before[1]),
            reason: "moving another layer must not quietly select a different one",);
      },);
    });

    testWidgets("keeps the same layer selected when one moves up past it", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        await settle();

        final List<LayerState> before = _layers(projectSession: projectSession);
        GetIt.I.get<LayerManager>().selectLayer(newLayer: before[1]);
        await settle();

        //drag the bottom layer to the top, across the selected one
        GetIt.I.get<LayerManager>().changeLayerOrder(state: before[2], newPosition: 0);
        await settle();

        expect(_layers(projectSession: projectSession), <LayerState>[before[2], before[0], before[1]], reason: "setup: the move happened");
        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(before[1]));
      },);
    });

    testWidgets("does not move a floating selection onto a different layer", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        await settle();

        final List<LayerState> before = _layers(projectSession: projectSession);
        final DrawingLayerState owner = before[1] as DrawingLayerState;
        GetIt.I.get<LayerManager>().selectLayer(newLayer: owner);
        await _paint(projectSession: projectSession, layer: owner, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), color);

        GetIt.I.get<LayerManager>().changeLayerOrder(state: before[0], newPosition: 3);
        await settle();
        GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
        await settle();

        expect(owner.getDataEntry(coord: pixel), color, reason: "the content has to land back on the layer it came from");
        expect(copiesOf(projectSession: projectSession, coord: pixel), 1);
      },);
    });
  });

  group("switching to a layer that cannot take the content", () {
    testWidgets("does not leave a copy floating over a locked layer", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState locked = layerAt(projectSession: projectSession, index: 0);
        final DrawingLayerState owner = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await _paint(projectSession: projectSession, layer: owner, coord: pixel, color: color);

        locked.lockState.value = LayerLockState.locked;
        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();

        GetIt.I.get<LayerManager>().selectLayer(newLayer: locked);
        await settle();

        expect(owner.getDataEntry(coord: pixel), color, reason: "the content goes back to the layer it came from");
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), isNull,
            reason: "a locked layer hands over nothing, so nothing may still be floating over it",);
        expect(copiesOf(projectSession: projectSession, coord: pixel), 1, reason: "the pixel would otherwise be drawn twice");
      },);
    });

    testWidgets("does not write through the lock on deselect", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState locked = layerAt(projectSession: projectSession, index: 0);
        final DrawingLayerState owner = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await _paint(projectSession: projectSession, layer: owner, coord: pixel, color: color);

        locked.lockState.value = LayerLockState.locked;
        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();
        GetIt.I.get<LayerManager>().selectLayer(newLayer: locked);
        await settle();

        GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
        await settle();

        expect(locked.getDataEntry(coord: pixel), isNull, reason: "deselecting must not stamp anything into a locked layer");
        expect(copiesOf(projectSession: projectSession, coord: pixel), 1);
      },);
    });

    testWidgets("does not leave a copy floating over a shading layer", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState owner = layerAt(projectSession: projectSession, index: 0);
        await _paint(projectSession: projectSession, layer: owner, coord: pixel, color: color);
        final LayerState? shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState);
        await settle();

        GetIt.I.get<LayerManager>().selectLayer(newLayer: owner);
        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();

        GetIt.I.get<LayerManager>().selectLayer(newLayer: shading!);
        await settle();

        expect(owner.getDataEntry(coord: pixel), color);
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), isNull,
            reason: "a shading layer holds no colour references, so nothing may be handed to it",);
        expect(copiesOf(projectSession: projectSession, coord: pixel), 1);
      },);
    });

    testWidgets("switching back to a drawing layer floats its content again", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState locked = layerAt(projectSession: projectSession, index: 0);
        final DrawingLayerState owner = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await _paint(projectSession: projectSession, layer: owner, coord: pixel, color: color);

        locked.lockState.value = LayerLockState.locked;
        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();

        GetIt.I.get<LayerManager>().selectLayer(newLayer: locked);
        await settle();
        GetIt.I.get<LayerManager>().selectLayer(newLayer: owner);
        await settle();

        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), color,
            reason: "coming back to the owning layer has to lift its pixels again",);
        expect(owner.getDataEntry(coord: pixel), isNull);
        expect(copiesOf(projectSession: projectSession, coord: pixel), 1);
      },);
    });
  });
}
