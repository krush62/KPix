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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Serialises the project the way Ctrl+S does.
Future<Uint8List> _save({required final AppState appState}) async
{
  return (await createKPixData(appState: appState)).buffer.asUint8List();
}

/// Reads a project back the way opening a file does.
Future<LoadFileSet> _load({required final Uint8List bytes}) async
{
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
  return loadKPixFile(
    fileData: bytes,
    path: "round_trip.kpix",
    drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
    shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
    frameConstraints: prefs.frameConstraints,
  );
}

/// Every pixel the loaded file holds on its drawing layers, keyed by coordinate.
///
/// Values are the ramp/colour index pair as a string, so a test can compare what
/// a coordinate holds without reaching into the history colour type.
Map<CoordinateSetI, String> _pixelsOf({required final LoadFileSet loaded})
{
  final Map<CoordinateSetI, String> pixels = <CoordinateSetI, String>{};
  for (final HistoryLayer layer in loaded.historyState!.timeline.allLayers)
  {
    if (layer is HistoryDrawingLayer)
    {
      for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in layer.data.entries)
      {
        pixels[entry.key] = "${entry.value.rampIndex}/${entry.value.colorIndex}";
      }
    }
  }
  return pixels;
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  testWidgets("a project saved with a pasted selection can be read back", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
      await settle(appState: appState);

      //copy and paste leaves the clipboard floating over pixels that are still
      //on the layer, so the two pixel stores overlap
      appState.selectionState.selectAll();
      appState.selectionState.copy();
      appState.selectionState.paste();
      await settle(appState: appState);
      expect(layer.getDataEntry(coord: pixel), isNotNull, reason: "setup: the layer still holds the pasted-over pixel");
      expect(appState.selectionState.selection.getColorReference(coord: pixel), isNotNull, reason: "setup: and so does the selection");

      final LoadFileSet loaded = await _load(bytes: await _save(appState: appState));

      expect(loaded.historyState, isNotNull, reason: "load failed: ${loaded.status}");
      final Map<CoordinateSetI, String> pixels = _pixelsOf(loaded: loaded);
      expect(pixels.keys, <CoordinateSetI>[pixel], reason: "the overlap has to be written once, not counted twice");
    },);
  });

  testWidgets("a selection dragged off the canvas does not leak phantom pixels", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
      await settle(appState: appState);

      appState.selectionState.selectAll();
      appState.selectionState.setOffset(offset: CoordinateSetI(x: -10, y: 0), withContent: true);
      appState.selectionState.finishMovement();
      await settle(appState: appState);

      final LoadFileSet loaded = await _load(bytes: await _save(appState: appState));

      expect(loaded.historyState, isNotNull, reason: "load failed: ${loaded.status}");
      for (final CoordinateSetI coord in _pixelsOf(loaded: loaded).keys)
      {
        expect(coord.x, inInclusiveRange(0, canvasSize.x - 1), reason: "a pixel outside the canvas was written");
        expect(coord.y, inInclusiveRange(0, canvasSize.y - 1), reason: "a pixel outside the canvas was written");
      }
    },);
  });

  testWidgets("a selection stranded on a shading layer does not change the file", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState drawingLayer = layerAt(appState: appState, index: 0);
      drawingLayer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
      GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState);
      await settle(appState: appState);

      final int sizeWithoutSelection = (await _save(appState: appState)).lengthInBytes;

      //a selection made on a drawing layer survives a switch to a shading layer:
      //the content is handed back to the drawing layer but the buffer keeps a
      //copy, because a shading layer cannot hold colour references
      GetIt.I.get<LayerManager>().selectLayer(newLayer: drawingLayer);
      appState.selectionState.selectAll();
      GetIt.I.get<LayerManager>().selectLayer(newLayer: appState.timeline.selectedFrame!.layerList.getLayer(index: 0));
      await settle(appState: appState);
      expect(appState.timeline.getCurrentLayer(), isA<ShadingLayerState>(), reason: "setup: a shading layer is selected");
      expect(appState.selectionState.selection.selectedPixels, isNotEmpty, reason: "setup: with a selection still floating");

      final int sizeWithSelection = (await _save(appState: appState)).lengthInBytes;

      expect(sizeWithSelection, sizeWithoutSelection,
          reason: "the writer never merges a selection into a shading layer, so nothing may be reserved for one",);

      final LoadFileSet loaded = await _load(bytes: await _save(appState: appState));
      expect(loaded.historyState, isNotNull, reason: "load failed: ${loaded.status}");
    },);
  });

  testWidgets("an ordinary project still round-trips unchanged", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference first = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final ColorReference second = GetIt.I.get<PaletteState>().colorRamps.first.references.last;
      final DrawingLayerState lower = layerAt(appState: appState, index: 0);
      lower.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: first}));
      final DrawingLayerState upper = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
      upper.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 2, y: 3): second}));
      await settle(appState: appState);

      final LoadFileSet loaded = await _load(bytes: await _save(appState: appState));

      expect(loaded.historyState, isNotNull, reason: "load failed: ${loaded.status}");
      final Map<CoordinateSetI, String> pixels = _pixelsOf(loaded: loaded);
      expect(pixels.length, 2);
      expect(pixels[pixel], isNotNull);
      expect(pixels[CoordinateSetI(x: 2, y: 3)], isNotNull);
    },);
  });
}
