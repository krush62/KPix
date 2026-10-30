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
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 10, y: 8);

/// A layer with a pixel at 3|3, selected from 2|2 to 5|4 so the pixel floats.
Future<(DrawingLayerState, SelectionState)> _floatingPixel({required final ProjectSession projectSession}) async
{
  final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 3, y: 3): GetIt.I.get<PaletteState>().colorRamps.first.references[1]}));
  await settle();
  final SelectionState selectionState = GetIt.I.get<DocumentState>().selectionState;
  selectionState.newSelectionFromShape(start: CoordinateSetI(x: 2, y: 2), end: CoordinateSetI(x: 5, y: 4), selectShape: SelectShape.rectangle);
  await settle();
  return (layer, selectionState);
}

void main()
{
  for (final (String condition, SelectionActionResult delete, SelectionActionResult cut, SelectionActionResult transform) refusal in <(String, SelectionActionResult, SelectionActionResult, SelectionActionResult)>[
    ("hidden", SelectionActionResult.hiddenLayerDelete, SelectionActionResult.hiddenLayerCut, SelectionActionResult.hiddenLayerTransform),
    ("locked", SelectionActionResult.lockedLayerDelete, SelectionActionResult.lockedLayerCut, SelectionActionResult.lockedLayerTransform),
  ])
  {
    testWidgets("delete, cut and transforms on a ${refusal.$1} layer are refused and change nothing", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final (DrawingLayerState layer, SelectionState selectionState) = await _floatingPixel(projectSession: projectSession);
        final ColorReference? floating = selectionState.selection.getColorReference(coord: CoordinateSetI(x: 3, y: 3));
        expect(floating, isNotNull, reason: "setup: the pixel floats");
        if (refusal.$1 == "hidden")
        {
          layer.visibilityState.value = LayerVisibilityState.hidden;
        }
        else
        {
          layer.lockState.value = LayerLockState.locked;
        }
        await settle();

        expect(selectionState.delete(), refusal.$2);
        expect(selectionState.cut(), refusal.$3);
        expect(selectionState.flipH(), refusal.$4);
        expect(selectionState.flipV(), refusal.$4);
        expect(selectionState.rotate(), refusal.$4);
        await settle();

        expect(selectionState.selection.getColorReference(coord: CoordinateSetI(x: 3, y: 3)), floating);
        expect(selectionState.hasClipboard, isFalse);
        expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionNew);
      },);
    });
  }

  testWidgets("a cut is a single undo step", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final (DrawingLayerState _, SelectionState selectionState) = await _floatingPixel(projectSession: projectSession);
      final CoordinateSetI pixel = CoordinateSetI(x: 3, y: 3);
      expect(selectionState.cut(), SelectionActionResult.success);
      await settle();
      expect(selectionState.selection.getColorReference(coord: pixel), isNull, reason: "setup: the pixel was cut");
      expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionCut);

      GetIt.I.get<HistoryController>().undoPressed();
      await settle();

      expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionNew);
      expect(selectionState.selection.getColorReference(coord: pixel), isNotNull);
    },);
  });

  testWidgets("align moves the selection box to the edges and the middle of the canvas", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final (DrawingLayerState _, SelectionState selectionState) = await _floatingPixel(projectSession: projectSession);
      (int, int, int, int) box()
      {
        final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selectionState.selection.getBoundingBox();
        return (topLeft!.x, topLeft.y, bottomRight!.x, bottomRight.y);
      }
      expect(box(), (2, 2, 5, 4), reason: "setup");

      selectionState.alignSelectionLeft();
      expect(box(), (0, 2, 3, 4));
      selectionState.alignSelectionRight();
      expect(box(), (6, 2, 9, 4));
      selectionState.alignSelectionTop();
      expect(box(), (6, 0, 9, 2));
      selectionState.alignSelectionBottom();
      expect(box(), (6, 5, 9, 7));
      //a box 4 wide on a canvas 10 wide, and 3 high on 8
      selectionState.centerSelectionH();
      expect(box(), (3, 5, 6, 7));
      selectionState.centerSelectionV();
      expect(box(), (3, 3, 6, 5));
      await settle();
      expect(selectionState.selection.getColorReference(coord: CoordinateSetI(x: 4, y: 4)), isNotNull, reason: "the floating pixel moved with the box");
    },);
  });
}
