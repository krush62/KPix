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
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

Future<void> _paintAndRecord({
  required final ProjectSession projectSession,
  required final DrawingLayerState layer,
  required final CoordinateSetI coord,
  required final ColorReference color,
}) async
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{coord: color}));
  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);
  await settle();
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  group("duplicating carries the floating content", () {
    testWidgets("a duplicated layer holds the committed selection", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState source = layerAt(projectSession: projectSession, index: 0);
        await _paintAndRecord(projectSession: projectSession, layer: source, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), color, reason: "setup: the pixel is floating");

        final DrawingLayerState copy = GetIt.I.get<LayerManager>().layerDuplicateSelected(duplicateLayer: source)! as DrawingLayerState;
        await settle();

        expect(copy.getDataEntry(coord: pixel), color,
            reason: "duplicating commits the selection first, so the copy has to include it",);
        expect(source.getDataEntry(coord: pixel), color);
      },);
    });

    testWidgets("a copied frame holds the committed selection", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
        final DrawingLayerState source = layerAt(projectSession: projectSession, index: 0);
        await _paintAndRecord(projectSession: projectSession, layer: source, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();

        timeline.copyFrameRight();
        await settle();

        expect(timeline.frames.value.length, 2, reason: "setup: the frame was copied");
        final DrawingLayerState copied = timeline.frames.value[1].layerList.getLayer(index: 0) as DrawingLayerState;
        expect(copied, isNot(same(source)), reason: "setup: a copy, not a link");
        expect(copied.getDataEntry(coord: pixel), color,
            reason: "the copied frame has to look like the frame it was copied from",);
      },);
    });

    testWidgets("a linked frame shares the layer that holds the content", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
        final DrawingLayerState source = layerAt(projectSession: projectSession, index: 0);
        await _paintAndRecord(projectSession: projectSession, layer: source, coord: pixel, color: color);

        GetIt.I.get<DocumentState>().selectionState.selectAll();
        await settle();

        timeline.linkFrameRight();
        await settle();

        expect(timeline.frames.value[1].layerList.getLayer(index: 0), same(source), reason: "setup: a link");
        expect(source.getDataEntry(coord: pixel), color,
            reason: "the content is committed before the frame is added, so both frames show it",);
        expect(GetIt.I.get<DocumentState>().selectionState.selection.selectedPixels, isEmpty);
      },);
    });
  });

  group("undoing a canvas resize", () {
    testWidgets("restores the reported dimensions", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        expect(GetIt.I.get<CanvasState>().canvasSize.x, 4);
        expect(GetIt.I.get<StatusBarState>().statusBarDimensionString.value, isNotNull);
        final String? before = GetIt.I.get<StatusBarState>().statusBarDimensionString.value;

        GetIt.I.get<CanvasState>().changeCanvasSize(newSize: CoordinateSetI(x: 8, y: 8), offset: CoordinateSetI(x: 0, y: 0));
        await settle();
        expect(GetIt.I.get<CanvasState>().canvasSize.x, 8);
        expect(GetIt.I.get<StatusBarState>().statusBarDimensionString.value, isNot(before));

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();

        expect(GetIt.I.get<CanvasState>().canvasSize.x, 4, reason: "the canvas itself is back");
        expect(GetIt.I.get<StatusBarState>().statusBarDimensionString.value, before,
            reason: "and the status bar has to agree with it",);
      },);
    });

    testWidgets("restores the dimensions after a crop", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
        await _paintAndRecord(projectSession: projectSession, layer: layer, coord: pixel, color: color);
        final String? before = GetIt.I.get<StatusBarState>().statusBarDimensionString.value;

        GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(
          start: CoordinateSetI(x: 1, y: 1),
          end: CoordinateSetI(x: 2, y: 2),
          selectShape: SelectShape.rectangle,
        );
        await settle();
        GetIt.I.get<CanvasState>().cropToSelection();
        await settle();
        expect(GetIt.I.get<CanvasState>().canvasSize.x, 2, reason: "setup: cropped to the selection");

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();

        expect(GetIt.I.get<CanvasState>().canvasSize.x, 4);
        expect(GetIt.I.get<StatusBarState>().statusBarDimensionString.value, before);
      },);
    });
  });

  group("the unsaved marker", () {
    testWidgets("clears when undo returns to the saved state", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);

        projectSession.fileSaved(saveName: "test", path: "test.kpix");
        expect(projectSession.hasChanges.value, isFalse, reason: "setup: just saved");

        await _paintAndRecord(projectSession: projectSession, layer: layer, coord: pixel, color: color);
        expect(projectSession.hasChanges.value, isTrue, reason: "setup: drawing is a change");

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();

        expect(projectSession.hasChanges.value, isFalse,
            reason: "the project matches the file on disk again, so it is not unsaved",);
      },);
    });

    testWidgets("comes back when redo leaves the saved state", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);

        projectSession.fileSaved(saveName: "test", path: "test.kpix");
        await _paintAndRecord(projectSession: projectSession, layer: layer, coord: pixel, color: color);
        GetIt.I.get<HistoryController>().undoPressed();
        await settle();
        expect(projectSession.hasChanges.value, isFalse);

        GetIt.I.get<HistoryController>().redoPressed();
        await settle();

        expect(projectSession.hasChanges.value, isTrue, reason: "the stroke is back, so the project differs from the file again");
      },);
    });

    testWidgets("undoing to a different state still counts as changed", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
        final ColorReference first = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
        final ColorReference second = GetIt.I.get<PaletteState>().colorRamps.first.references.last;
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);

        await _paintAndRecord(projectSession: projectSession, layer: layer, coord: pixel, color: first);
        projectSession.fileSaved(saveName: "test", path: "test.kpix");

        await _paintAndRecord(projectSession: projectSession, layer: layer, coord: CoordinateSetI(x: 2, y: 2), color: second);
        await _paintAndRecord(projectSession: projectSession, layer: layer, coord: CoordinateSetI(x: 3, y: 3), color: second);
        GetIt.I.get<HistoryController>().undoPressed();
        await settle();

        expect(projectSession.hasChanges.value, isTrue,
            reason: "one stroke past the saved state is still a change",);
      },);
    });
  });
}
