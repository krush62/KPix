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

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_grid_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_shading_layer.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

Future<LoadFileSet> _load({required final Uint8List bytes, final bool strict = false}) async
{
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
  return loadKPixFile(
    fileData: bytes,
    path: "format.kpix",
    drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
    shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
    frameConstraints: prefs.frameConstraints,
    strict: strict,
  );
}

Uint8List _bodyOf({required final Uint8List file}) => Uint8List.fromList(const ZLibDecoder().decodeBytes(Uint8List.sublistView(file, 5)));

Uint8List _withBody({required final Uint8List file, required final Uint8List body})
{
  final Uint8List compressed = const ZLibEncoder().encodeBytes(body);
  return Uint8List(5 + compressed.length)
    ..setAll(0, Uint8List.sublistView(file, 0, 5))
    ..setAll(5, compressed);
}

/// Where the first layer record starts in the uncompressed body.
int _firstLayerOffset()
{
  int offset = 1;
  for (final KPalRampData ramp in GetIt.I.get<PaletteState>().colorRamps)
  {
    offset += 11 + 3 * ramp.settings.colorCount;
  }
  //canvas size and layer count
  return offset + 6;
}

/// The raw pixel values of every drawing, shading and dither layer, top to bottom.
List<Map<CoordinateSetI, int>> _pixelsOf({required final HistoryState state})
{
  final List<Map<CoordinateSetI, int>> layers = <Map<CoordinateSetI, int>>[];
  for (final HistoryLayer layer in state.timeline.allLayers)
  {
    final PixelGridView? pixels = layer is HistoryDrawingLayer ? layer.pixels : layer is HistoryShadingLayer ? layer.pixels : null;
    if (pixels != null)
    {
      final Map<CoordinateSetI, int> values = <CoordinateSetI, int>{};
      pixels.forEachNonZero(action: (final int x, final int y, final int value) => values[CoordinateSetI(x: x, y: y)] = value);
      layers.add(values);
    }
  }
  return layers;
}

Future<void> _shade({required final ShadingLayerState layer, required final Map<CoordinateSetI, int> values}) async
{
  layer.addCoords(coords: HashMap<CoordinateSetI, int>.of(values));
  await settle();
}

/// Saves the project, loads it back and expects the very same pixels.
Future<void> _expectRoundTrip() async
{
  final List<Map<CoordinateSetI, int>> saved = _pixelsOf(state: HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.saveData));
  final LoadFileSet loaded = await _load(bytes: (await createKPixData()).buffer.asUint8List());
  expect(loaded.historyState, isNotNull, reason: "load failed: ${loaded.status}");
  expect(_pixelsOf(state: loaded.historyState!), saved);
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 12, y: 10);

  testWidgets("a saved project has an uncompressed header followed by a zlib stream", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 3, y: 4): GetIt.I.get<PaletteState>().colorRamps.first.references.first,
      }),);
      await settle();

      final Uint8List bytes = (await createKPixData()).buffer.asUint8List();

      expect(ByteData.sublistView(bytes).getUint32(0), int.parse(magicNumber, radix: 16));
      expect(bytes[4], 6);
      expect(() => const ZLibDecoder().decodeBytes(Uint8List.sublistView(bytes, 5), verify: true), returnsNormally);
    },);
  });

  testWidgets("a damaged file is refused instead of loaded", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final Uint8List bytes = (await createKPixData()).buffer.asUint8List();
      bytes[bytes.length ~/ 2] ^= 0xFF;

      final LoadFileSet loaded = await _load(bytes: bytes);

      expect(loaded.historyState, isNull);
    },);
  });

  testWidgets("saving and loading keep every pixel of every layer", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
      //opposite corners, so the box spans the whole canvas
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 0, y: 0): ramps[0].references[0],
        CoordinateSetI(x: 11, y: 9): ramps[1].references[4],
        CoordinateSetI(x: 5, y: 5): ramps[2].references[2],
      }),);
      await settle();

      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, select: true).$2! as ShadingLayerState;
      await settle();
      await _shade(layer: shading, values: <CoordinateSetI, int>{CoordinateSetI(x: 2, y: 3): -3, CoordinateSetI(x: 7, y: 3): 0, CoordinateSetI(x: 9, y: 8): 5});

      //empty layers of both kinds
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DitherLayerState, select: true);
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true);
      await settle();

      final DrawingLayerState top = GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: true).$2! as DrawingLayerState;
      top.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 6, y: 1): ramps[3].references[1],
        CoordinateSetI(x: 8, y: 2): ramps[3].references[1],
      }),);
      await settle();

      final List<Map<CoordinateSetI, int>> saved = _pixelsOf(state: HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.saveData));
      expect(saved.map((final Map<CoordinateSetI, int> layer) => layer.length).toList(), <int>[2, 0, 0, 3, 3], reason: "setup: top to bottom");
      await _expectRoundTrip();
    },);
  });

  testWidgets("a layer with more than 255 colors keeps them all", (final WidgetTester tester) async
  {
    final CoordinateSetI size = CoordinateSetI(x: 20, y: 15);
    await withProject(tester: tester, canvasSize: size, body: (final ProjectSession projectSession) async
    {
      final List<KPalRampData> ramps = <KPalRampData>[
        for (int i = 0; i < 20; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()..colorCount = 15),
      ];
      GetIt.I.get<PaletteState>().colorRamps = ramps;
      GetIt.I.get<PaletteState>().selectedColor = ramps.first.references.first;
      final CoordinateColorMapNullable colors = CoordinateColorMapNullable();
      for (int i = 0; i < size.x * size.y; i++)
      {
        colors[CoordinateSetI(x: i % size.x, y: i ~/ size.x)] = ramps[i ~/ 15].references[i % 15];
      }
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: colors);
      await settle();

      expect(_pixelsOf(state: HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.saveData)).single.values.toSet().length, 300, reason: "setup");
      await _expectRoundTrip();
    },);
  });

  testWidgets("unknown ids for styles, lock, visibility, grid type and sat curve fall back with a warning", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final CoordinateSetI dot = CoordinateSetI(x: 3, y: 4);
      final DrawingLayerState drawing = layerAt(projectSession: projectSession, index: 0);
      drawing.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: GetIt.I.get<PaletteState>().colorRamps.first.references[1]}));
      await settle();
      //values other than the fallbacks, so a fallback shows
      drawing.lockState.value = LayerLockState.locked;
      drawing.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      drawing.settings.innerStrokeStyle.value = InnerStrokeStyle.solid;
      drawing.settings.dropShadowStyle.value = DropShadowStyle.solid;
      final GridLayerState grid = GetIt.I.get<LayerManager>().addNewLayer(layerType: GridLayerState, select: true).$2! as GridLayerState;
      grid.visibilityState.value = LayerVisibilityState.hidden;
      grid.gridTypeNotifier.value = GridType.values.last;
      await settle();

      final Uint8List file = (await createKPixData()).buffer.asUint8List();
      final Uint8List body = _bodyOf(file: file);
      const int satCurveOfFirstRamp = 9;
      final int gridRecord = _firstLayerOffset();
      //type, visibility, five bytes and four floats
      final int drawingRecord = gridRecord + 23;
      expect(body[gridRecord + 1], LayerVisibilityState.hidden.id, reason: "setup: grid visibility");
      expect(body[gridRecord + 4], GridType.values.last.id, reason: "setup: grid type");
      expect(body[drawingRecord + 2], LayerLockState.locked.id, reason: "setup: lock");
      expect(body[drawingRecord + 3], OuterStrokeStyle.solid.id, reason: "setup: outer stroke style");
      expect(body[drawingRecord + 10], InnerStrokeStyle.solid.id, reason: "setup: inner stroke style");
      expect(body[drawingRecord + 19], DropShadowStyle.solid.id, reason: "setup: drop shadow style");

      body[satCurveOfFirstRamp] = 99;
      body[gridRecord + 1] = 77;
      body[gridRecord + 4] = 88;
      body[drawingRecord + 2] = 66;
      body[drawingRecord + 3] = 55;
      body[drawingRecord + 10] = 44;
      body[drawingRecord + 19] = 33;
      final LoadFileSet loaded = await _load(bytes: _withBody(file: file, body: body));

      expect(loaded.historyState, isNotNull, reason: loaded.status);
      expect(loaded.status.split("\n").where((final String line) => line.isNotEmpty).toList(), <String>[
        "Invalid sat curve for palette 0: 99",
        "Invalid visibility type for layer 0: 77",
        "Invalid grid type for layer 0: 88",
        "Invalid lock type for layer 1: 66",
        "Invalid outer stroke style for layer 1: 55",
        "Invalid inner stroke style for layer 1: 44",
        "Invalid drop shadow style for layer 1: 33",
      ],);
      expect(loaded.historyState!.rampList.first.settings.satCurve, KPalConstraints.satCurveDefault);
      final List<HistoryLayer> layers = loaded.historyState!.timeline.allLayers.toList();
      final HistoryGridLayer loadedGrid = layers[0] as HistoryGridLayer;
      expect(loadedGrid.visibilityState, LayerVisibilityState.visible);
      expect(loadedGrid.gridType, GridType.rectangular);
      final HistoryDrawingLayer loadedDrawing = layers[1] as HistoryDrawingLayer;
      expect(loadedDrawing.lockState, LayerLockState.unlocked);
      expect(loadedDrawing.settings.outerStrokeStyle, OuterStrokeStyle.off);
      expect(loadedDrawing.settings.innerStrokeStyle, InnerStrokeStyle.off);
      expect(loadedDrawing.settings.dropShadowStyle, DropShadowStyle.off);
      expect(loadedDrawing.pixels.nonZeroCount, 1, reason: "the fields after a fallback are still read in step");
      expect(loadedDrawing.pixels.get(x: dot.x, y: dot.y), isNot(0));
    },);
  });

  testWidgets("a strict load refuses an unknown style id", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final Uint8List file = (await createKPixData()).buffer.asUint8List();
      final Uint8List body = _bodyOf(file: file);
      final int outerStrokeStyle = _firstLayerOffset() + 3;
      expect(body[outerStrokeStyle], OuterStrokeStyle.off.id, reason: "setup");
      body[outerStrokeStyle] = 55;

      final LoadFileSet loaded = await _load(bytes: _withBody(file: file, body: body), strict: true);

      expect(loaded.historyState, isNull);
      expect(loaded.status, "Invalid outer stroke style for layer 0: 55");
    },);
  });
}
