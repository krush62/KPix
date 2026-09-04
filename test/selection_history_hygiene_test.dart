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
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Paints [color] at [coord] and files it under the pencil, the way the canvas
/// widget's history poll does after a stroke.
///
/// Tests that undo past the paint need it on the stack; writing to the layer
/// alone would leave the step before the selection holding an empty layer.
Future<void> _paintAndRecord({
  required final AppState appState,
  required final DrawingLayerState layer,
  required final CoordinateSetI coord,
  required final ColorReference color,
}) async
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{coord: color}));
  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);
  await settle(appState: appState);
}

/// The square from (1,1) to (2,2), as a lasso would hand it over.
Set<CoordinateSetI> _squarePolygon()
{
  return <CoordinateSetI>{
    CoordinateSetI(x: 1, y: 1),
    CoordinateSetI(x: 2, y: 1),
    CoordinateSetI(x: 1, y: 2),
    CoordinateSetI(x: 2, y: 2),
  };
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  group("a polygon selection", () {
    testWidgets("is recorded as its own undo step", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState layer = layerAt(appState: appState, index: 0);
        await _paintAndRecord(appState: appState, layer: layer, coord: pixel, color: color);

        final String descriptionBefore = GetIt.I.get<HistoryManager>().getCurrentDescription();
        GetIt.I.get<DocumentState>().selectionState.newSelectionFromPolygon(points: _squarePolygon());
        await settle(appState: appState);

        expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), "new selection",
            reason: "the lasso lifts pixels out of the layer, so it has to be undoable like the other select tools",);
        expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), isNot(descriptionBefore));
      },);
    });

    testWidgets("can be undone without losing the lifted pixels", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState layer = layerAt(appState: appState, index: 0);
        await _paintAndRecord(appState: appState, layer: layer, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.newSelectionFromPolygon(points: _squarePolygon());
        await settle(appState: appState);
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), color, reason: "setup: the pixel is floating");
        expect(layer.getDataEntry(coord: pixel), isNull);

        GetIt.I.get<HistoryController>().undoPressed();
        await settle(appState: appState);

        expect(GetIt.I.get<DocumentState>().selectionState.selection.selectedPixels, isEmpty, reason: "the selection is undone");
        //restoring rebuilds the layer it touched, so the live one has to be looked up again
        expect(layerAt(appState: appState, index: 0).getDataEntry(coord: pixel), color, reason: "and the pixel is back where it came from");
        expect(copiesOf(appState: appState, coord: pixel), 1);
      },);
    });
  });

  group("moving with nothing selected", () {
    testWidgets("does not touch the history stack", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final String descriptionBefore = GetIt.I.get<HistoryManager>().getCurrentDescription();
        final bool couldUndoBefore = GetIt.I.get<HistoryManager>().hasUndo.value;

        //what the arrow keys reach when no selection exists
        GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 0, y: -1), withContent: true);
        GetIt.I.get<DocumentState>().selectionState.finishMovement();
        await settle(appState: appState);

        expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), descriptionBefore);
        expect(GetIt.I.get<HistoryManager>().hasUndo.value, couldUndoBefore);
      },);
    });

    testWidgets("does not mark the project as changed", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        appState.hasChanges.value = false;

        GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 1, y: 0), withContent: true);
        GetIt.I.get<DocumentState>().selectionState.finishMovement();
        await settle(appState: appState);

        expect(appState.hasChanges.value, isFalse,
            reason: "pressing an arrow key on an untouched project must not prompt to save on close",);
      },);
    });

    testWidgets("an untouched selection reports itself as empty", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        expect(GetIt.I.get<DocumentState>().selectionState.selection.selectedPixels, isEmpty);
        expect(GetIt.I.get<DocumentState>().selectionState.selection.isEmpty, isTrue,
            reason: "the notifier drives every selection button, so it has to start out agreeing with the content",);
      },);
    });
  });

  group("moving a real selection", () {
    testWidgets("is still recorded", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState layer = layerAt(appState: appState, index: 0);
        await _paintAndRecord(appState: appState, layer: layer, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle(appState: appState);

        GetIt.I.get<DocumentState>().selectionState.setOffset(offset: CoordinateSetI(x: 1, y: 0), withContent: true);
        GetIt.I.get<DocumentState>().selectionState.finishMovement();
        await settle(appState: appState);

        expect(GetIt.I.get<HistoryManager>().getCurrentDescription(), "move selection");
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 2, y: 1)), color,
            reason: "the content moved with the selection",);
      },);
    });
  });
}
