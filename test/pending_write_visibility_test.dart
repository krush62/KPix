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
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Writes [color] at [coord] without waiting for the raster.
///
/// The value sits in the layer's raster queue until the next render folds it
/// into the layer data - the window every test here is about.
void _write({
  required final DrawingLayerState layer,
  required final CoordinateSetI coord,
  required final ColorReference? color,
})
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{coord: color}));
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  testWidgets("a pixel reads back as the colour last written to it", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference first = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final ColorReference second = GetIt.I.get<PaletteState>().colorRamps.first.references.last;
      expect(second, isNot(first), reason: "setup: the two colours have to be distinguishable");

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, coord: pixel, color: first);
      await settle(appState: appState);
      expect(layer.getDataEntry(coord: pixel), first, reason: "setup: the first colour is rendered");

      //no settle: the second write is still queued while the layer data holds the first
      _write(layer: layer, coord: pixel, color: second);

      expect(layer.getDataEntry(coord: pixel), second,
          reason: "a queued write is newer than the rendered data and has to win: expected colour ${second.colorIndex}, layer data still holds ${first.colorIndex}",);

      await settle(appState: appState);
      expect(layer.getDataEntry(coord: pixel), second, reason: "and still wins once it is rendered");
    },);
  });

  testWidgets("an erased pixel reads back as empty before the raster runs", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, coord: pixel, color: color);
      await settle(appState: appState);

      //a queued null means erased, which has to be told apart from nothing queued
      _write(layer: layer, coord: pixel, color: null);

      expect(layer.getDataEntry(coord: pixel), isNull, reason: "the erase is queued and has to be visible");
      await settle(appState: appState);
      expect(layer.getDataEntry(coord: pixel), isNull);
    },);
  });

  testWidgets("selecting right after a stroke lifts the stroke, not what it covered", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference covered = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final ColorReference stroke = GetIt.I.get<PaletteState>().colorRamps.first.references.last;

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, coord: pixel, color: covered);
      await settle(appState: appState);

      //paint over it and select before the raster has caught up, the way a user
      //does when they drag a selection straight after a stroke
      _write(layer: layer, coord: pixel, color: stroke);
      GetIt.I.get<DocumentState>().selectionState.selectAll();
      await settle(appState: appState);

      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: pixel), stroke,
          reason: "the selection must lift the stroke (colour ${stroke.colorIndex}), not the colour it covered (${covered.colorIndex})",);
      expect(copiesOf(appState: appState, coord: pixel), 1);
    },);
  });

  testWidgets("filling right after a stroke sees the stroke", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference covered = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final ColorReference stroke = GetIt.I.get<PaletteState>().colorRamps.first.references.last;

      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      _write(layer: layer, coord: pixel, color: covered);
      await settle(appState: appState);
      _write(layer: layer, coord: pixel, color: stroke);

      //what the wand and the fill tool ask the layer for when deciding which
      //neighbouring pixels match
      expect(layer.getDataEntry(coord: pixel), stroke,
          reason: "flood fill would otherwise spread across a colour that is no longer there",);
    },);
  });
}
