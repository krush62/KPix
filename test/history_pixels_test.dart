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
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_drawing_layer_settings.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history/ramp_resolver.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/kpal_ramp_data.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// The history record of [layer] in the current history state.
HistoryDrawingLayer _recordOf({required final DrawingLayerState layer})
{
  final HistoryState state = GetIt.I.get<HistoryManager>().getCurrentState()!;
  return state.timeline.allLayers.whereType<HistoryDrawingLayer>().firstWhere((final HistoryDrawingLayer record) => record.layerIdentity == identityHashCode(layer));
}

/// A color as its ramp's uuid and its index, which survives the ramp objects
/// being rebuilt by a full restore.
String _describe({required final ColorReference? color})
{
  return color == null ? "-" : "${color.ramp.uuid}/${color.colorIndex}";
}

Future<void> _paintAndRecord({required final DrawingLayerState layer, required final Map<CoordinateSetI, ColorReference?> pixels}) async
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(pixels));
  await settle();
  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);
  await settle();
}

Future<void> _undo() async
{
  GetIt.I.get<HistoryController>().undoPressed();
  await settle();
}

Future<void> _redo() async
{
  GetIt.I.get<HistoryController>().redoPressed();
  await settle();
}

/// Drawing layers go into the history as grid snapshots that share tiles with
/// the layer and with each other. These pin down what that has to preserve:
/// every pixel through undo, redo, save and load, across palette changes.
void main()
{
  final CoordinateSetI a = CoordinateSetI(x: 1, y: 2);
  final CoordinateSetI b = CoordinateSetI(x: 5, y: 3);
  final CoordinateSetI c = CoordinateSetI(x: 7, y: 7);

  testWidgets("a history step shares the pixels of the layers it did not touch", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paintAndRecord(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: color});
      final PixelGridSnapshot before = _recordOf(layer: layer).pixels;

      //adding a layer takes a new record of every layer
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
      await settle();

      expect(_recordOf(layer: layer).pixels, same(before), reason: "an unchanged layer must not cost a copy of its pixels");
    },);
  });

  testWidgets("writes still waiting to be rastered are part of the history step", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
      final ColorReference color = ramps[2].references[3];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{b: color}));
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);

      expect(layer.rasterQueue, isNotEmpty, reason: "setup: the write had not been rastered yet");
      expect(_recordOf(layer: layer).pixels.get(x: b.x, y: b.y), PaletteCodec.codeOf(rampIndex: 2, colorIndex: 3));
      await settle();
    },);
  });

  testWidgets("undo and redo keep every pixel across a palette reorder", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference first = palette.colorRamps[0].references[1];
      final ColorReference third = palette.colorRamps[2].references[3];
      final ColorReference second = palette.colorRamps[1].references[0];
      await _paintAndRecord(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference?>{a: first, b: third});

      palette.changeColorOrder(ramp: palette.colorRamps[0], newPosition: 2);
      await settle();
      await _paintAndRecord(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference?>{c: second});

      Map<String, String> pixels() => <String, String>{
        "a": _describe(color: layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: a)),
        "b": _describe(color: layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: b)),
        "c": _describe(color: layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: c)),
      };
      final Map<String, String> painted = <String, String>{"a": _describe(color: first), "b": _describe(color: third), "c": _describe(color: second)};
      expect(pixels(), painted);

      await _undo();
      expect(pixels(), <String, String>{...painted, "c": "-"}, reason: "one step back: the reordered palette without the last stroke");
      await _undo();
      expect(pixels(), <String, String>{...painted, "c": "-"}, reason: "two steps back: the original order, same pixels");
      expect(palette.colorRamps.first.uuid, first.ramp.uuid, reason: "setup: the reorder was undone");
      await _redo();
      await _redo();
      expect(pixels(), painted);
    },);
  });

  testWidgets("undo and redo follow a color count change", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final KPalRampData ramp = palette.colorRamps.firstWhere((final KPalRampData r) => r.references.length >= 7);
      final int oldCount = ramp.references.length;
      await _paintAndRecord(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference?>{a: ramp.references[1]});

      final KPalRampData original = KPalRampData.from(other: ramp);
      ramp.settings.colorCount = 4;
      ramp.updateColors(colorCountChanged: true);
      palette.updateRamp(ramp: ramp, originalData: original);
      await settle();
      final int movedIndex = remapIndices(oldLength: oldCount, newLength: 4)[1]!;
      expect(layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: a)?.colorIndex, movedIndex);

      await _undo();
      expect(_describe(color: layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: a)), "${ramp.uuid}/1");
      expect(palette.colorRamps.firstWhere((final KPalRampData r) => r.uuid == ramp.uuid).references.length, oldCount);
      await _redo();
      expect(_describe(color: layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: a)), "${ramp.uuid}/$movedIndex");
    },);
  });

  testWidgets("after a palette reorder the layer's codes follow the palette again", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference color = palette.colorRamps[0].references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paintAndRecord(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: color});

      palette.changeColorOrder(ramp: palette.colorRamps[0], newPosition: 2);
      await settle();
      final int newIndex = palette.colorRamps.indexOf(color.ramp);
      expect(PaletteCodec.rampIndexOf(code: _recordOf(layer: layer).pixels.get(x: a.x, y: a.y)), newIndex,
          reason: "the record stores the ramp's position in the reordered palette",);

      final PixelGridSnapshot afterReorder = _recordOf(layer: layer).pixels;
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
      await settle();
      expect(_recordOf(layer: layer).pixels, same(afterReorder), reason: "once lined up, later steps share the pixels again");
      expect(layer.getDataEntry(coord: a), same(color), reason: "lining the codes up changes nothing visible");
    },);
  });

  testWidgets("colors of ramps outside the palette stay on the layer but out of the record", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paintAndRecord(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: palette.colorRamps[0].references[1]});

      //a palette replacement moves the layer onto ramps before the palette switches
      final List<KPalRampData> replacement = <KPalRampData>[KPalRampData(uuid: "replacement", settings: KPalRampSettings())];
      final Map<ColorReference, ColorReference> colorMap = getRampMap(rampList1: palette.colorRamps, rampList2: replacement);
      layer.remapAllColors(rampMap: HashMap<ColorReference, ColorReference>.of(colorMap));
      await settle();
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);

      expect(layer.getDataEntry(coord: a)?.ramp, same(replacement.first));
      expect(_recordOf(layer: layer).pixels.nonZeroCount, 0, reason: "a code of a ramp the record does not list would not even load");
    },);
  });

  testWidgets("a record is translated onto ramps that are in another order", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final List<KPalRampData> live = GetIt.I.get<PaletteState>().colorRamps;
      final List<HistoryRampData> recorded = <HistoryRampData>[
        for (final KPalRampData ramp in live) HistoryRampData(otherSettings: ramp.settings, notifierShifts: ramp.shifts, uuid: ramp.uuid),
      ];
      final PixelGrid pixels = PixelGrid(width: 8, height: 8);
      pixels.set(x: a.x, y: a.y, value: PaletteCodec.codeOf(rampIndex: 0, colorIndex: 2));
      pixels.set(x: b.x, y: b.y, value: PaletteCodec.codeOf(rampIndex: 1, colorIndex: 1));
      final HistoryDrawingLayer record = HistoryDrawingLayer(
        visibilityState: LayerVisibilityState.visible,
        layerIdentity: 1,
        lockState: LayerLockState.unlocked,
        settings: HistoryDrawingLayerSettings.defaultValues(constraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints, colRef: const HistoryColorReference(colorIndex: 0, rampIndex: 0)),
        pixels: pixels.snapshot(),
      );

      final List<KPalRampData> reversed = live.reversed.toList();
      final DrawingLayerState restored = await record.toLayerState(canvasSize: CoordinateSetI(x: 8, y: 8), ramps: RampResolver(liveRamps: reversed, historyRamps: recorded));
      expect(restored.getDataEntry(coord: a), same(live[0].references[2]));
      expect(restored.getDataEntry(coord: b), same(live[1].references[1]));
      restored.dispose();
    },);
  });

  testWidgets("saving and loading keeps every pixel", (final WidgetTester tester) async
  {
    //pixels on both sides of a tile border
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 40, y: 36), body: (final ProjectSession projectSession) async
    {
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
      final Map<CoordinateSetI, ColorReference?> painted = <CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 0, y: 0): ramps[0].references[0],
        CoordinateSetI(x: 31, y: 31): ramps[1].references[2],
        CoordinateSetI(x: 32, y: 31): ramps[2].references[3],
        CoordinateSetI(x: 31, y: 32): ramps[3].references[1],
        CoordinateSetI(x: 39, y: 35): ramps[ramps.length - 1].references[4],
      };
      await _paintAndRecord(layer: layerAt(projectSession: projectSession, index: 0), pixels: painted);

      final Uint8List bytes = (await createKPixData()).buffer.asUint8List();
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final LoadFileSet loaded = await loadKPixFile(
        fileData: bytes,
        path: "history_pixels.kpix",
        drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
        shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
        frameConstraints: prefs.frameConstraints,
      );
      expect(loaded.historyState, isNotNull, reason: loaded.status);

      final HistoryLayer first = loaded.historyState!.timeline.allLayers.first;
      expect(first, isA<HistoryDrawingLayer>());
      final PixelGridSnapshot pixels = (first as HistoryDrawingLayer).pixels;
      expect(pixels.nonZeroCount, painted.length);
      for (final MapEntry<CoordinateSetI, ColorReference?> entry in painted.entries)
      {
        final int code = pixels.get(x: entry.key.x, y: entry.key.y);
        expect(PaletteCodec.rampIndexOf(code: code), ramps.indexOf(entry.value!.ramp), reason: "ramp at ${entry.key}");
        expect(PaletteCodec.colorIndexOf(code: code), entry.value!.colorIndex, reason: "color at ${entry.key}");
      }
    },);
  });
}
