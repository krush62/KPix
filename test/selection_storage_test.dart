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

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/kpal_ramp_data.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/selection_buffer.dart';
import 'package:kpix/util/typedefs.dart';
import 'support/selection_harness.dart';

SelectionState get _selectionState => GetIt.I.get<DocumentState>().selectionState;

/// Paints [pixels] on [layer] and lifts them into the selection, as a select
/// tool does.
Future<void> _float({required final DrawingLayerState layer, required final Map<CoordinateSetI, ColorReference> pixels}) async
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(pixels));
  await settle();
  _selectionState.newSelectionFromPolygon(points: pixels.keys.toSet());
  await settle();
}

/// What the selection floats, as "ramp uuid/color index" per position.
///
/// Undo and redo rebuild the palette's ramps as new objects, so the colors
/// cannot be compared by identity across them.
Map<CoordinateSetI, String> _floating()
{
  final Map<CoordinateSetI, String> floating = <CoordinateSetI, String>{};
  _selectionState.selection.forEachSelected(action: (final int x, final int y, final ColorReference? color)
  {
    floating[CoordinateSetI(x: x, y: y)] = color == null ? "none" : "${color.ramp.uuid}/${color.colorIndex}";
  },);
  return floating;
}

SelectionBufferSnapshot? _recordedPixels()
{
  return GetIt.I.get<HistoryManager>().getCurrentState()!.selectionState.pixels;
}

void _changeColorCount({required final KPalRampData ramp, required final int colorCount})
{
  final KPalRampData original = KPalRampData(uuid: ramp.uuid, settings: KPalRampSettings.from(other: ramp.settings));
  ramp.settings.colorCount = colorCount;
  ramp.updateColors(colorCountChanged: true);
  GetIt.I.get<PaletteState>().updateRamp(ramp: ramp, originalData: original);
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 8, y: 6);
  final CoordinateSetI a = CoordinateSetI(x: 1, y: 1);
  final CoordinateSetI b = CoordinateSetI(x: 2, y: 1);

  testWidgets("a step that leaves the selection alone shares its pixels", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: palette.colorRamps[0].references[1]});
      final SelectionBufferSnapshot? floating = _recordedPixels();
      expect(floating, isNotNull, reason: "setup: the step recorded the selection");

      //a full-group step takes everything down again, the selection included
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.generic);
      await settle();
      expect(_recordedPixels(), same(floating), reason: "a step that did not touch the selection shares its pixels");

      _selectionState.selection.deleteDirectly(coord: a);
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.generic);
      await settle();
      expect(_recordedPixels(), isNot(same(floating)), reason: "but a change is recorded");
      expect(_recordedPixels()!.count, 1, reason: "the pixel stays selected without its color");
    },);
  });
  testWidgets("undo and redo put the floating pixels back where they were", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference color = palette.colorRamps[0].references[1];
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: color});

      _selectionState.setOffset(offset: CoordinateSetI(x: 2, y: 1), withContent: true);
      _selectionState.finishMovement();
      await settle();
      final CoordinateSetI moved = CoordinateSetI(x: a.x + 2, y: a.y + 1);
      expect(_floating().keys, <CoordinateSetI>[moved], reason: "setup: the content moved with the selection");

      GetIt.I.get<HistoryController>().undoPressed();
      await settle();
      expect(_selectionState.selection.getColorReference(coord: a), same(color), reason: "back where it was lifted");
      expect(_selectionState.selection.contains(coord: moved), isFalse);

      GetIt.I.get<HistoryController>().redoPressed();
      await settle();
      expect(_selectionState.selection.getColorReference(coord: moved), same(color));
      expect(copiesOf(projectSession: projectSession, coord: moved), 1, reason: "the pixel lives in the selection alone");
    },);
  });

  testWidgets("the floating colors survive a palette reorder, undo and redo", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{
        a: palette.colorRamps[1].references[2],
        b: palette.colorRamps[0].references[1],
      },);
      final Map<CoordinateSetI, String> expected = _floating();
      expect(expected.length, 2, reason: "setup: two colors of different ramps float");

      //a reorder moves the ramps the codes point at
      palette.changeColorOrder(ramp: palette.colorRamps[0], newPosition: 2);
      await settle();
      expect(_floating(), expected, reason: "a reorder changes no color");

      GetIt.I.get<HistoryController>().undoPressed();
      await settle();
      expect(_floating(), expected, reason: "and neither does undoing it");
      GetIt.I.get<HistoryController>().redoPressed();
      await settle();
      expect(_floating(), expected);
    },);
  });

  testWidgets("deleting a ramp empties its floating pixels and keeps the selection", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final KPalRampData doomed = palette.colorRamps[1];
      final ColorReference keeper = palette.colorRamps[0].references[1];
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: doomed.references[2], b: keeper});

      palette.deleteRamp(ramp: doomed);
      await settle();

      expect(_selectionState.selection.contains(coord: a), isTrue, reason: "the shape of the selection stays");
      expect(_selectionState.selection.getColorReference(coord: a), isNull, reason: "but the deleted color is gone");
      expect(_selectionState.selection.getColorReference(coord: b), same(keeper), reason: "the other ramp keeps its color");
      expect(palette.getPixelUsageForRamp(ramp: palette.colorRamps[0]).selection, 1);
    },);
  });

  testWidgets("a color count change moves the floating colors like the layers", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final KPalRampData brown = palette.colorRamps[2];
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: brown.references[6]});

      _changeColorCount(ramp: brown, colorCount: 3);
      await settle();

      expect(_selectionState.selection.getColorReference(coord: a), same(brown.references[2]), reason: "the floating pixel moved from 6 to 2, as a layer pixel does");
    },);
  });

  testWidgets("the layer shows what floats over it, of a ramp it has no pixels of", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final ColorReference own = palette.colorRamps[0].references[1];
      final ColorReference floating = palette.colorRamps[2].references[3];
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{a: own}));
      await settle();
      //an empty pixel is selected and then painted in, so that the color's ramp
      //is one the layer itself holds no pixel of
      _selectionState.newSelectionFromPolygon(points: <CoordinateSetI>{b});
      _selectionState.selection.addDirectly(coord: b, colRef: floating);
      await settle();

      final Frame frame = GetIt.I.get<DocumentState>().timeline.frames.value.first;
      expect(layer.compositeAt(frame: frame, coord: b), same(floating), reason: "the raster shows the floating color");
      expect(layer.compositeAt(frame: frame, coord: a), same(own));
      expect(layer.getDataEntry(coord: b), isNull, reason: "which is not in the layer itself");
    },);
  });

  testWidgets("the clipboard keeps what was copied when the selection changes afterwards", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{
        a: palette.colorRamps[0].references[1],
        b: palette.colorRamps[1].references[2],
      },);
      final Map<CoordinateSetI, String> copied = _floating();

      _selectionState.copy(keepSelection: true);
      expect(palette.getPixelUsageForRamp(ramp: palette.colorRamps[1]).clipboard, 1, reason: "the clipboard knows what it holds per ramp");

      //the copy shares its tiles with the selection, so a change afterwards must
      //not reach into it
      _selectionState.selection.delete(keepSelection: true);
      expect(_floating(), <CoordinateSetI, String>{a: "none", b: "none"}, reason: "setup: the floating colors are gone");

      _selectionState.paste();
      await settle();
      expect(_floating(), copied, reason: "pasting brings back what was copied");
    },);
  });

  testWidgets("a selection moved off the canvas keeps its real box and turns around it", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference color = palette.colorRamps[0].references[1];
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: color, b: color});

      //past the right edge of the 8 wide canvas
      _selectionState.setOffset(offset: CoordinateSetI(x: 10, y: 0), withContent: true);
      _selectionState.finishMovement();
      await settle();
      expect(_selectionState.selection.getBoundingBox(), (CoordinateSetI(x: 11, y: 1), CoordinateSetI(x: 12, y: 1)),
          reason: "the box is measured from the pixels, not from the canvas",);

      _selectionState.rotate();
      await settle();
      expect(_floating().keys.toSet(), <CoordinateSetI>{CoordinateSetI(x: 11, y: 1), CoordinateSetI(x: 11, y: 2)},
          reason: "turned around the middle of its own box",);
    },);
  });

  testWidgets("colors that arrived in another order than the palette's are lined up for the history", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      //the later ramp is lifted first, so the selection's codes start out in an
      //order of their own
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        a: palette.colorRamps[2].references[3],
        b: palette.colorRamps[0].references[1],
      },),);
      await settle();
      _selectionState.newSelectionFromPolygon(points: <CoordinateSetI>{a, b});
      await settle();
      final Map<CoordinateSetI, String> expected = _floating();
      final SelectionBufferSnapshot? first = _recordedPixels();

      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.generic);
      await settle();
      expect(_recordedPixels(), same(first), reason: "the codes were lined up with the palette, so the next step shares them");

      GetIt.I.get<HistoryController>().undoPressed();
      await settle();
      GetIt.I.get<HistoryController>().redoPressed();
      await settle();
      expect(_floating(), expected, reason: "and they still name the colors they were lifted with");
    },);
  });

  testWidgets("a floating color of a ramp outside the palette stays, but is left out of the record", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: palette.colorRamps[0].references[1]});

      //a palette replacement moves the selection onto ramps before the palette switches
      final List<KPalRampData> replacement = <KPalRampData>[KPalRampData(uuid: "replacement", settings: KPalRampSettings())];
      final Map<ColorReference, ColorReference> colorMap = getRampMap(rampList1: palette.colorRamps, rampList2: replacement);
      _selectionState.selection.remapColors(colorMap: HashMap<ColorReference, ColorReference>.of(colorMap));
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.generic);
      await settle();

      expect(_selectionState.selection.getColorReference(coord: a)?.ramp, same(replacement.first), reason: "the selection keeps the color");
      expect(_recordedPixels()!.codeAt(x: a.x, y: a.y), PaletteCodec.transparent, reason: "a code of a ramp the record does not list would not even load");
    },);
  });

  testWidgets("a restore translates the codes when the state's ramps are in another order", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{
        a: palette.colorRamps[1].references[2],
        b: palette.colorRamps[0].references[1],
      },);
      final Map<CoordinateSetI, String> expected = _floating();
      final HistoryState recorded = HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.generic);

      //a layer-only restore leaves the palette as it is, so its order can differ
      //from the one the state was recorded with
      palette.changeColorOrder(ramp: palette.colorRamps[0], newPosition: 2, addToHistoryStack: false);
      await settle();
      await GetIt.I.get<HistoryController>().restoreState(historyState: recorded, typeGroup: HistoryStateTypeGroup.layerFull);
      await settle();

      expect(_floating(), expected, reason: "the codes are read against the ramps of the state they came from");
    },);
  });

  testWidgets("a paste after a color count change lands on the remapped color", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final KPalRampData brown = palette.colorRamps[2];
      //a color in the middle of the ramp: clamping to the last one would not do
      await _float(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: brown.references[3]});
      _selectionState.copy();
      await settle();

      _changeColorCount(ramp: brown, colorCount: 3);
      await settle();
      _selectionState.paste();
      await settle();

      expect(_selectionState.selection.getColorReference(coord: a), same(brown.references[1]), reason: "index 3 of 7 becomes index 1 of 3, as it does for a layer");
    },);
  });
}
