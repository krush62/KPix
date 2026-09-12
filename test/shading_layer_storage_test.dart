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
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/canvas_transformation.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_shading_layer.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

Frame _firstFrame()
{
  return GetIt.I.get<DocumentState>().timeline.frames.value.first;
}

/// The pixel at [coord] of what [layer] last rastered, as RGBA.
Future<int> _rgbaAt({required final RasterableLayerState layer, required final CoordinateSetI coord}) async
{
  final ui.Image? image = layer.rasterImageMap.value[_firstFrame()]?.raster;
  expect(image, isNotNull, reason: "setup: the layer has been rastered");
  final ByteData? bytes = await image!.toByteData();
  return bytes!.getUint32((coord.y * image.width + coord.x) * 4);
}

/// The current frame's layer at [index], as the given type.
T _layer<T extends LayerState>({required final int index})
{
  final LayerState layer = _firstFrame().layerList.getLayer(index: index);
  expect(layer, isA<T>(), reason: "setup: layer $index");
  return layer as T;
}

/// Adds a [type] layer above the drawing layer the project starts with.
Future<void> _addAbove({required final Type type}) async
{
  GetIt.I.get<LayerManager>().addNewLayer(layerType: type, select: true);
  await settle();
  _layer<DrawingLayerState>(index: 1);
}

HistoryShadingLayer _recordOf({required final ShadingLayerState layer})
{
  final HistoryState state = GetIt.I.get<HistoryManager>().getCurrentState()!;
  return state.timeline.allLayers.whereType<HistoryShadingLayer>().firstWhere((final HistoryShadingLayer record) => record.layerIdentity == identityHashCode(layer));
}

Future<void> _shade({required final ShadingLayerState layer, required final Map<CoordinateSetI, int> values}) async
{
  layer.addCoords(coords: HashMap<CoordinateSetI, int>.of(values));
  await settle();
  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);
  await settle();
}

/// Shading and dither layers keep their steps in a grid of signed pixels.
/// These pin down the rendering on top of the layers below, the history,
/// saving and loading, and canvas changes.
void main()
{
  final CoordinateSetI a = CoordinateSetI(x: 2, y: 2);
  final CoordinateSetI b = CoordinateSetI(x: 5, y: 1);

  testWidgets("a shading layer shades the layer below, also where only a region is rendered again", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 32, y: 32), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[2];
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{a: color, b: color}));
      await settle();
      await _addAbove(type: ShadingLayerState);
      final ShadingLayerState shading = _layer<ShadingLayerState>(index: 0);

      await _shade(layer: shading, values: <CoordinateSetI, int>{a: 1});
      expect(shading.compositeAt(frame: _firstFrame(), coord: a), same(color.ramp.references[color.colorIndex + 1]));
      expect(shading.compositeAt(frame: _firstFrame(), coord: b), isNull, reason: "no step there");

      //the second raster is a full one as well: a region is only patched into a
      //raster that has a predecessor
      await _shade(layer: shading, values: <CoordinateSetI, int>{CoordinateSetI(x: 18, y: 12): 1});
      //a small change is rendered as a region into the frame's pixels
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{b: -1}));
      await settle();
      expect(shading.compositeAt(frame: _firstFrame(), coord: b), same(color.ramp.references[color.colorIndex - 1]));
      expect(shading.compositeAt(frame: _firstFrame(), coord: a), same(color.ramp.references[color.colorIndex + 1]), reason: "kept outside the region");
      shading.removeCoords(coords: <CoordinateSetI>[a]);
      await settle();
      expect(shading.compositeAt(frame: _firstFrame(), coord: a), isNull);
    },);
  });

  testWidgets("a dither layer applies its pattern", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[2];
      final CoordinateSetI origin = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI next = CoordinateSetI(x: 1, y: 0);
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color, next: color}));
      await settle();
      await _addAbove(type: DitherLayerState);
      final DitherLayerState dither = _layer<DitherLayerState>(index: 0);

      //half the steps: a checkerboard, set at 0|0 and clear at 1|0
      await _shade(layer: dither, values: <CoordinateSetI, int>{origin: 8, next: 8});
      expect(dither.getRawValueAt(coord: origin), 8);
      expect(dither.compositeAt(frame: _firstFrame(), coord: origin), same(color.ramp.references[color.colorIndex + 1]));
      expect(dither.compositeAt(frame: _firstFrame(), coord: next), same(color));
    },);
  });

  testWidgets("undo and redo restore the steps, and an unchanged layer shares its record's pixels", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      await _addAbove(type: ShadingLayerState);
      await _shade(layer: _layer<ShadingLayerState>(index: 0), values: <CoordinateSetI, int>{a: 0, b: -2});
      final PixelGridSnapshot recorded = _recordOf(layer: _layer<ShadingLayerState>(index: 0)).pixels;

      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
      await settle();
      expect(_recordOf(layer: _layer<ShadingLayerState>(index: 1)).pixels, same(recorded), reason: "a step that did not touch the layer shares its pixels");
      GetIt.I.get<HistoryController>().undoPressed();
      await settle();

      await _shade(layer: _layer<ShadingLayerState>(index: 0), values: <CoordinateSetI, int>{a: 3});
      GetIt.I.get<HistoryController>().undoPressed();
      await settle();
      expect(_layer<ShadingLayerState>(index: 0).getRawValueAt(coord: a), 0, reason: "a step of zero is a step");
      expect(_layer<ShadingLayerState>(index: 0).getRawValueAt(coord: b), -2);
      GetIt.I.get<HistoryController>().redoPressed();
      await settle();
      expect(_layer<ShadingLayerState>(index: 0).getRawValueAt(coord: a), 3);
    },);
  });

  testWidgets("a record keeps the layer's settings even when the steps did not change", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      await _addAbove(type: ShadingLayerState);
      final ShadingLayerState shading = _layer<ShadingLayerState>(index: 0);
      await _shade(layer: shading, values: <CoordinateSetI, int>{a: 1});

      final int changed = shading.settings.shadingStepsMinus.value == 1 ? 2 : 1;
      shading.settings.shadingStepsMinus.value = changed;
      await settle();
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: shading);

      expect(_recordOf(layer: shading).settings.shadingLow, changed);
    },);
  });

  testWidgets("saving and loading keep shading and dither steps", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      await _addAbove(type: ShadingLayerState);
      await _shade(layer: _layer<ShadingLayerState>(index: 0), values: <CoordinateSetI, int>{a: -3, b: 0});
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DitherLayerState, select: true);
      await settle();
      await _shade(layer: _layer<DitherLayerState>(index: 0), values: <CoordinateSetI, int>{a: 16, b: -7});

      final Uint8List bytes = (await createKPixData()).buffer.asUint8List();
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final LoadFileSet loaded = await loadKPixFile(
        fileData: bytes,
        path: "shading.kpix",
        drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
        shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
        frameConstraints: prefs.frameConstraints,
      );
      expect(loaded.historyState, isNotNull, reason: loaded.status);

      final List<HistoryLayer> layers = loaded.historyState!.timeline.allLayers.toList();
      final HistoryDitherLayer dither = layers.whereType<HistoryDitherLayer>().single;
      final HistoryShadingLayer shading = layers.whereType<HistoryShadingLayer>().firstWhere((final HistoryShadingLayer layer) => layer is! HistoryDitherLayer);
      expect(shading.pixels.getSigned(x: a.x, y: a.y), -3);
      expect(shading.pixels.getSigned(x: b.x, y: b.y), 0);
      expect(shading.pixels.nonZeroCount, 2);
      expect(dither.pixels.getSigned(x: a.x, y: a.y), 16);
      expect(dither.pixels.getSigned(x: b.x, y: b.y), -7);
    },);
  });

  testWidgets("rotating the canvas turns a shading layer with it", (final WidgetTester tester) async
  {
    //not square, so the size shows whether the layer turned
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 6, y: 4), body: (final ProjectSession projectSession) async
    {
      await _addAbove(type: ShadingLayerState);
      await _shade(layer: _layer<ShadingLayerState>(index: 0), values: <CoordinateSetI, int>{CoordinateSetI(x: 1, y: 0): 2});

      GetIt.I.get<CanvasState>().canvasTransform(transformation: CanvasTransformation.rotate);
      await settle();

      final ShadingLayerState shading = _layer<ShadingLayerState>(index: 0);
      //a quarter clockwise: x|y becomes (height - 1 - y)|x
      expect(shading.getRawValueAt(coord: CoordinateSetI(x: 3, y: 1)), 2);
      expect(shading.getRawValueAt(coord: CoordinateSetI(x: 1, y: 0)), isNull);
      //the new bottom rows were outside the layer before it turned
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 2, y: 5): 1}));
      expect(shading.getRawValueAt(coord: CoordinateSetI(x: 2, y: 5)), 1);
    },);
  });

  testWidgets("resizing the canvas moves and crops the steps", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 6, y: 4), body: (final ProjectSession projectSession) async
    {
      await _addAbove(type: ShadingLayerState);
      await _shade(layer: _layer<ShadingLayerState>(index: 0), values: <CoordinateSetI, int>{CoordinateSetI(x: 1, y: 0): 2, CoordinateSetI(x: 0, y: 3): -1});

      GetIt.I.get<CanvasState>().changeCanvasSize(newSize: CoordinateSetI(x: 8, y: 5), offset: CoordinateSetI(x: 2, y: -1));
      await settle();

      final ShadingLayerState shading = _layer<ShadingLayerState>(index: 0);
      expect(shading.getRawValueAt(coord: CoordinateSetI(x: 2, y: 2)), -1);
      int steps = 0;
      shading.forEachValue(action: (final int x, final int y, final int value) => steps++);
      expect(steps, 1, reason: "the step moved above the top edge is cut off");
    },);
  });

  testWidgets("lowering a limit clamps the steps beyond it", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      await _addAbove(type: ShadingLayerState);
      final ShadingLayerState shading = _layer<ShadingLayerState>(index: 0);
      final int highest = shading.settings.constraints.shadingStepsMax;
      final int lowest = shading.settings.constraints.shadingStepsMin;
      expect(highest, greaterThan(lowest), reason: "setup");
      shading.settings.shadingStepsPlus.value = highest;
      await _shade(layer: shading, values: <CoordinateSetI, int>{a: highest, b: -1});

      shading.settings.shadingStepsPlus.value = lowest;
      await settle();
      expect(shading.getRawValueAt(coord: a), lowest);
      expect(shading.getRawValueAt(coord: b), -1, reason: "within the other limit");
    },);
  });

  testWidgets("rastering a shading layer shades the drawing layer below and removes the shading layer", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[2];
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{a: color, b: color}));
      await settle();
      await _addAbove(type: ShadingLayerState);
      await _shade(layer: _layer<ShadingLayerState>(index: 0), values: <CoordinateSetI, int>{a: -1});

      GetIt.I.get<LayerManager>().layerRasterPressed(rasterLayer: _layer<ShadingLayerState>(index: 0));
      await settle();

      final DrawingLayerState drawing = _layer<DrawingLayerState>(index: 0);
      expect(drawing.getDataEntry(coord: a), same(color.ramp.references[color.colorIndex - 1]));
      expect(drawing.getDataEntry(coord: b), same(color));
    },);
  });

  testWidgets("the rendered image shows the shaded colors, in a full and in a partial render", (final WidgetTester tester) async
  {
    //a canvas that is not square, so that a row stride mix-up shows
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 20, y: 14), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[2];
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{a: color, b: color}));
      await settle();
      await _addAbove(type: ShadingLayerState);
      final ShadingLayerState shading = _layer<ShadingLayerState>(index: 0);

      await _shade(layer: shading, values: <CoordinateSetI, int>{a: 1});
      expect(await _rgbaAt(layer: shading, coord: a), RgbaCache().rgbaOf(reference: color.ramp.references[color.colorIndex + 1]));
      expect(await _rgbaAt(layer: shading, coord: b), 0, reason: "nothing is shaded there");

      //the second raster is full as well, a region is only patched into a
      //raster that has a predecessor
      await _shade(layer: shading, values: <CoordinateSetI, int>{CoordinateSetI(x: 18, y: 12): 1});
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{b: -1}));
      await settle();
      expect(await _rgbaAt(layer: shading, coord: b), RgbaCache().rgbaOf(reference: color.ramp.references[color.colorIndex - 1]), reason: "the region the change touched");
      expect(await _rgbaAt(layer: shading, coord: a), RgbaCache().rgbaOf(reference: color.ramp.references[color.colorIndex + 1]), reason: "and the rest of the image is kept");

      shading.removeCoords(coords: <CoordinateSetI>[a]);
      await settle();
      expect(await _rgbaAt(layer: shading, coord: a), 0, reason: "a pixel that is no longer shaded is cleared");
    },);
  });

  testWidgets("the rendered image of a dither layer follows its pattern", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[2];
      final CoordinateSetI origin = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI next = CoordinateSetI(x: 1, y: 0);
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color, next: color}));
      await settle();
      await _addAbove(type: DitherLayerState);
      final DitherLayerState dither = _layer<DitherLayerState>(index: 0);

      await _shade(layer: dither, values: <CoordinateSetI, int>{origin: 8, next: 8});
      expect(await _rgbaAt(layer: dither, coord: origin), RgbaCache().rgbaOf(reference: color.ramp.references[color.colorIndex + 1]));
      expect(await _rgbaAt(layer: dither, coord: next), RgbaCache().rgbaOf(reference: color), reason: "the checkerboard leaves this one alone");
    },);
  });
}
