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
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/selection_harness.dart';

/// Characterization tests for the history restore paths that nothing else
/// reaches.
///
/// The restore switches on [HistoryStateTypeGroup], and the rest of the suite
/// only ever drives `full` and `layerFull`. These pin down the two remaining
/// groups so that moving the restore out of ProjectSession can be shown to preserve
/// behaviour:
///
///  * `layerSelect` - selecting a different layer, restored by re-selecting.
///  * `colorSelect` - picking a different color, restored on its own without
///    touching layers.
void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);

  group("undoing a layer selection (layerSelect group)", ()
  {
    testWidgets("puts the previously selected layer back", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final LayerManager layers = GetIt.I.get<LayerManager>();
        final DrawingLayerState lower = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
        final DrawingLayerState upper = layers.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await settle();

        layers.selectLayer(newLayer: lower);
        await settle();
        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(lower));

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();
        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(upper),
            reason: "undo of a layer change should re-select the layer that was active before",);

        GetIt.I.get<HistoryController>().redoPressed();
        await settle();
        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(lower),
            reason: "redo should return to the layer the user had picked",);
      },);
    });

    testWidgets("leaves the layers themselves untouched", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final LayerManager layers = GetIt.I.get<LayerManager>();
        final DrawingLayerState lower = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;
        final DrawingLayerState upper = layers.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await settle();

        layers.selectLayer(newLayer: lower);
        await settle();

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();

        //a layerSelect restore must not rebuild the layers, only the selection
        final List<LayerState> after = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getAllLayers().toList();
        expect(after.length, 2);
        expect(after.contains(lower), isTrue, reason: "the lower layer should be the same instance");
        expect(after.contains(upper), isTrue, reason: "the upper layer should be the same instance");
      },);
    });
  });

  group("undoing a color selection (colorSelect group)", ()
  {
    testWidgets("puts the previously selected color back", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final ColorReference first = palette.colorRamps.first.references.first;
        final ColorReference second = palette.colorRamps.first.references.last;

        palette.colorSelected(color: first);
        await settle();
        palette.colorSelected(color: second);
        await settle();
        expect(palette.selectedColor, same(second));

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();
        expect(palette.selectedColor?.colorIndex, first.colorIndex,
            reason: "undo of a color change should restore the previous color",);

        GetIt.I.get<HistoryController>().redoPressed();
        await settle();
        expect(palette.selectedColor?.colorIndex, second.colorIndex,
            reason: "redo should return to the color the user had picked",);
      },);
    });

    testWidgets("does not disturb the layer or its content", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final DrawingLayerState layer = GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;

        palette.colorSelected(color: palette.colorRamps.first.references.last);
        await settle();

        GetIt.I.get<HistoryController>().undoPressed();
        await settle();

        expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(layer),
            reason: "a colorSelect restore should not rebuild layers",);
      },);
    });
  });
}
