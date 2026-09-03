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
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Two drawing layers, a single pixel on the upper one, and that pixel lifted
/// into the floating selection. Returns (upper, lower).
Future<(DrawingLayerState, DrawingLayerState)> _twoLayersWithFloatingPixel({
  required final AppState appState,
  required final CoordinateSetI pixel,
}) async
{
  final ColorReference color = appState.colorRamps.first.references.first;
  final DrawingLayerState lower = layerAt(appState: appState, index: 0);
  final DrawingLayerState upper = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
  upper.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
  await settle(appState: appState);

  appState.selectionState.selectAll();
  await settle(appState: appState);
  return (upper, lower);
}

/// What a drawing tool does while a selection is active: the stroke goes into
/// the selection buffer rather than the layer, and the canvas widget's history
/// poll files it under the tool's own identifier a moment later. See
/// `_dumpDrawing` in the painters and `_flushHistoryData` in the canvas widget.
void _paintIntoSelection({
  required final AppState appState,
  required final CoordinateSetI coord,
  required final ColorReference color,
})
{
  appState.selectionState.selection.addDirectlyAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{coord: color}));
  GetIt.I.get<HistoryManager>().addState(
    appState: appState,
    identifier: HistoryStateTypeIdentifier.toolPen,
    originLayer: appState.timeline.getCurrentLayer(),
  );
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  testWidgets("a selection hands its content over to the newly selected layer", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = appState.colorRamps.first.references.first;
      final (DrawingLayerState upper, DrawingLayerState lower) = await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      expect(appState.selectionState.selection.getColorReference(coord: pixel), color);
      expect(upper.getDataEntry(coord: pixel), isNull, reason: "a selection takes the pixels out of the layer");
      expect(copiesOf(appState: appState, coord: pixel), 1);

      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);

      expect(upper.getDataEntry(coord: pixel), color, reason: "the old layer gets the floating content back");
      expect(appState.selectionState.selection.getColorReference(coord: pixel), isNull, reason: "the selection now floats the new layer's content");
      expect(copiesOf(appState: appState, coord: pixel), 1);
    },);
  });

  testWidgets("undoing across a layer switch does not duplicate the handed-over pixel", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState _, DrawingLayerState lower) = await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);

      //an edit on top of the switch, so that undoing it restores the state the
      //switch left behind - which is where the stale snapshot used to surface
      appState.selectionState.flipH();
      await settle(appState: appState);

      appState.undoPressed();
      await settle(appState: appState);

      expect(copiesOf(appState: appState, coord: pixel), 1,
          reason: "the pixel must not sit on the old layer and in the floating selection at once",);
    },);
  });

  testWidgets("redoing across a layer switch does not duplicate the handed-over pixel", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState _, DrawingLayerState lower) = await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);
      appState.selectionState.flipH();
      await settle(appState: appState);

      appState.undoPressed();
      await settle(appState: appState);
      appState.redoPressed();
      await settle(appState: appState);

      expect(copiesOf(appState: appState, coord: pixel), 1);
    },);
  });

  testWidgets("a layer switch that moves content is recorded as its own step", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final (DrawingLayerState _, DrawingLayerState lower) = await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);

      expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), "select layer (move selection)",
          reason: "a switch that rewrites two layers cannot be filed as a plain selection change",);
    },);
  });

  testWidgets("a layer switch with nothing selected stays a cheap selection change", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final DrawingLayerState lower = layerAt(appState: appState, index: 0);
      appState.addNewLayer(layerType: DrawingLayerState, select: true);
      await settle(appState: appState);

      appState.selectLayer(newLayer: lower);
      await settle(appState: appState);

      expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), "select layer",
          reason: "with nothing floating the switch really does only move the selected index",);
    },);
  });

  testWidgets("starting playback commits the floating selection", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = appState.colorRamps.first.references.first;
      final Timeline timeline = appState.timeline;

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
      timeline.addNewFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle(appState: appState);

      appState.selectionState.selectAll();
      await settle(appState: appState);
      expect(appState.selectionState.selection.selectedPixels, isNotEmpty);

      timeline.togglePlaying();
      expect(appState.selectionState.selection.selectedPixels, isEmpty,
          reason: "playback reselects a layer per frame and would drag the content along",);
      expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), "deselect",
          reason: "committing the content is an edit and has to be undoable",);

      timeline.togglePlaying();
      await settle(appState: appState);

      expect(timeline.isPlaying.value, isFalse);
      expect(layer.getDataEntry(coord: pixel), color, reason: "the content stays on the layer it came from");
      expect(copiesOf(appState: appState, coord: pixel), 1);
    },);
  });

  testWidgets("advancing frames while playing neither records history nor dirties the project", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final Timeline timeline = appState.timeline;
      timeline.addNewFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle(appState: appState);

      final String descriptionBefore = GetIt.I.get<HistoryManager>().getCurrentDescription();
      appState.hasChanges.value = false;

      timeline.togglePlaying();
      timeline.selectFrameByIndex(index: 1);
      timeline.selectFrameByIndex(index: 0);

      expect(appState.hasChanges.value, isFalse, reason: "watching an animation is not an edit");
      expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), descriptionBefore);

      timeline.togglePlaying();
      await settle(appState: appState);
      expect(timeline.isPlaying.value, isFalse);
    },);
  });

  testWidgets("redo restores paint that went into the selection", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference original = appState.colorRamps.first.references.first;
      final ColorReference painted = appState.colorRamps.first.references.last;
      expect(painted, isNot(original), reason: "setup: the two colours have to be distinguishable");

      await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);
      expect(appState.selectionState.selection.getColorReference(coord: pixel), original);

      _paintIntoSelection(appState: appState, coord: pixel, color: painted);
      await settle(appState: appState);
      expect(appState.selectionState.selection.getColorReference(coord: pixel), painted);

      appState.undoPressed();
      await settle(appState: appState);
      expect(appState.selectionState.selection.getColorReference(coord: pixel), original, reason: "undo takes the stroke back off");

      appState.redoPressed();
      await settle(appState: appState);
      expect(appState.selectionState.selection.getColorReference(coord: pixel), painted,
          reason: "the stroke only ever lived in the selection, so a state sharing an older snapshot loses it",);
    },);
  });

  testWidgets("undoing a deselect brings back the painted content, not the original", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference painted = appState.colorRamps.first.references.last;
      final (DrawingLayerState upper, DrawingLayerState _) = await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      _paintIntoSelection(appState: appState, coord: pixel, color: painted);
      await settle(appState: appState);

      appState.selectionState.deselect(addToHistoryStack: true);
      await settle(appState: appState);
      expect(upper.getDataEntry(coord: pixel), painted, reason: "deselecting commits the stroke to the layer");

      appState.undoPressed();
      await settle(appState: appState);

      expect(appState.selectionState.selection.getColorReference(coord: pixel), painted,
          reason: "undoing the deselect has to float the stroke again, not the colour it replaced",);
      expect(copiesOf(appState: appState, coord: pixel), 1);
    },);
  });

  testWidgets("a state whose selection did not move shares the previous snapshot", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      final HistoryState? before = GetIt.I.get<HistoryManager>().getCurrentState();
      appState.changeLayerVisibility(layerState: layerAt(appState: appState, index: 1));
      await settle(appState: appState);
      final HistoryState? after = GetIt.I.get<HistoryManager>().getCurrentState();

      expect(before, isNotNull);
      expect(after, isNot(same(before)));
      expect(after!.selectionState, same(before!.selectionState),
          reason: "copying the selection map into every state is what the sharing exists to avoid",);
    },);
  });

  testWidgets("a state whose selection moved gets its own snapshot", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference painted = appState.colorRamps.first.references.last;
      await _twoLayersWithFloatingPixel(appState: appState, pixel: pixel);

      final HistoryState? before = GetIt.I.get<HistoryManager>().getCurrentState();
      _paintIntoSelection(appState: appState, coord: pixel, color: painted);
      await settle(appState: appState);
      final HistoryState? after = GetIt.I.get<HistoryManager>().getCurrentState();

      expect(after!.selectionState, isNot(same(before!.selectionState)));
      expect(after.selectionRevision, greaterThan(before.selectionRevision));
    },);
  });

  test("every write to the selection moves its revision", () async {
    final AppState appState = await bootProject(canvasSize: canvasSize);
    final ColorReference color = appState.colorRamps.first.references.first;
    final SelectionList selection = appState.selectionState.selection;

    int previous = selection.revision;
    void expectMoved(final String what)
    {
      expect(selection.revision, greaterThan(previous), reason: "$what has to move the revision");
      previous = selection.revision;
    }

    selection.addEmpty(coord: pixel);
    expectMoved("addEmpty");
    selection.addDirectly(coord: pixel, colRef: color);
    expectMoved("addDirectly");
    selection.addDirectlyAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
    expectMoved("addDirectlyAll");
    selection.flipH();
    expectMoved("flipH");
    selection.flipV();
    expectMoved("flipV");
    selection.rotate90cw();
    expectMoved("rotate90cw");
    selection.shiftSelection(offset: CoordinateSetI(x: 1, y: 0), withContent: true);
    expectMoved("shiftSelection");
    selection.deleteDirectly(coord: pixel);
    expectMoved("deleteDirectly");
    selection.delete(keepSelection: true);
    expectMoved("delete");
    selection.removeAll(coords: <CoordinateSetI>{pixel});
    expectMoved("removeAll");
    selection.transferAll(coords: <CoordinateSetI>{pixel});
    expectMoved("transferAll");
    selection.clear();
    expectMoved("clear");
    selection.changeLayer(oldLayer: null, newLayer: appState.timeline.getCurrentLayer()!);
    expectMoved("changeLayer");
  });
}
