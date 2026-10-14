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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// The open project as a file would hold it, read back the way an import does.
Future<LoadFileSet> _saveAndLoad() async
{
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
  return loadKPixFile(
    fileData: (await createKPixData()).buffer.asUint8List(),
    path: "imported.kpix",
    drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
    shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
    frameConstraints: prefs.frameConstraints,
  );
}

/// What the first frame of the open project looks like, rendered the way a save
/// renders its thumbnail.
Future<ui.Image> _renderOpenProject() async
{
  final Frame frame = GetIt.I.get<DocumentState>().timeline.frames.value.first;
  return getImageFromLayers(
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    layerCollection: frame.layerList,
    selection: GetIt.I.get<DocumentState>().selectionState.selection,
    frame: frame,
  );
}

Future<Uint8List> _bytesOf({required final ui.Image image}) async
{
  final ByteData? bytes = await image.toByteData();
  return bytes!.buffer.asUint8List();
}

Future<ui.Image> _thumbnailOf({required final LoadFileSet loaded}) async
{
  expect(loaded.historyState, isNotNull, reason: "load failed: ${loaded.status}");
  final ui.Image? thumbnail = await getImageFromLoadFileSet(loadFileSet: loaded);
  expect(thumbnail, isNotNull);
  return thumbnail!;
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 6, y: 4);

  testWidgets("the thumbnail shows the drawing layers", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 1, y: 1): colors.first,
        CoordinateSetI(x: 5, y: 3): colors.last,
      }),);
      await settle();

      final ui.Image expected = await _renderOpenProject();
      final ui.Image thumbnail = await _thumbnailOf(loaded: await _saveAndLoad());

      expect(thumbnail.width, canvasSize.x);
      expect(thumbnail.height, canvasSize.y);
      expect(await _bytesOf(image: thumbnail), await _bytesOf(image: expected));
      thumbnail.dispose();
      expected.dispose();
    },);
  });

  testWidgets("the thumbnail does not take the size of the open project", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 5, y: 3): color,
      }),);
      await settle();

      final ui.Image expected = await _renderOpenProject();
      final LoadFileSet loaded = await _saveAndLoad();

      //the import happens while some other project is open
      GetIt.I.get<CanvasState>().changeCanvasSize(newSize: CoordinateSetI(x: 3, y: 8), offset: CoordinateSetI(x: 0, y: 0));
      await settle();

      final ui.Image thumbnail = await _thumbnailOf(loaded: loaded);

      expect(thumbnail.width, canvasSize.x);
      expect(thumbnail.height, canvasSize.y);
      expect(await _bytesOf(image: thumbnail), await _bytesOf(image: expected));
      thumbnail.dispose();
      expected.dispose();
    },);
  });

  testWidgets("the thumbnail shows shading layers over the layers below them", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
      final CoordinateSetI shaded = CoordinateSetI(x: 2, y: 1);
      layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        shaded: colors[1],
        CoordinateSetI(x: 3, y: 1): colors[1],
      }),);
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, select: true).$2! as ShadingLayerState;
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.from(<CoordinateSetI, int>{shaded: 1}));
      await settle();
      //settle only watches drawing layers
      await shading.rasterizationComplete;
      expect(GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getLayer(index: 0), shading, reason: "setup: the shading layer is on top");
      expect(GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getLayer(index: 1), isA<DrawingLayerState>());

      final ui.Image expected = await _renderOpenProject();
      final Uint8List expectedBytes = await _bytesOf(image: expected);
      final int index = (shaded.y * canvasSize.x + shaded.x) * 4;
      final int neighbour = (shaded.y * canvasSize.x + shaded.x + 1) * 4;
      expect(expectedBytes.sublist(index, index + 4), isNot(expectedBytes.sublist(neighbour, neighbour + 4)), reason: "setup: the shading shows in the open project");

      final ui.Image thumbnail = await _thumbnailOf(loaded: await _saveAndLoad());

      expect(await _bytesOf(image: thumbnail), expectedBytes);
      thumbnail.dispose();
      expected.dispose();
    },);
  });

  testWidgets("the thumbnail matches the open project with effects, dither and hidden layers", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async {
      final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
      final LayerManager layerManager = GetIt.I.get<LayerManager>();

      //bottom: an outline to the right, which only exists as an effect pixel
      final DrawingLayerState outlined = layerAt(projectSession: projectSession, index: 0);
      outlined.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): colors[1]}));
      outlined.settings.outerColorReference.value = colors[2];
      outlined.settings.outerSelectionMap.value = HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: alignment == Alignment.centerRight});
      outlined.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;

      //a shaded drop shadow that falls onto that outline
      final DrawingLayerState shadowed = layerManager.addNewLayer(layerType: DrawingLayerState, select: true).$2! as DrawingLayerState;
      shadowed.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 0): colors[3]}));
      shadowed.settings.dropShadowOffset.value = CoordinateSetI(x: 1, y: 1);
      shadowed.settings.dropShadowDarkenBrighten.value = 1;
      shadowed.settings.dropShadowStyle.value = DropShadowStyle.shade;

      final DitherLayerState dither = layerManager.addNewLayer(layerType: DitherLayerState, select: true).$2! as DitherLayerState;
      dither.addCoords(coords: HashMap<CoordinateSetI, int>.from(<CoordinateSetI, int>{CoordinateSetI(x: 1, y: 1): 1, CoordinateSetI(x: 2, y: 1): -1}));

      final DrawingLayerState hidden = layerManager.addNewLayer(layerType: DrawingLayerState, select: true).$2! as DrawingLayerState;
      hidden.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 2): colors.last}));
      layerManager.changeLayerVisibility(layerState: hidden);

      for (int pass = 0; pass < 2; pass++)
      {
        await settle();
        for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
        {
          for (int i = 0; i < frame.layerList.length; i++)
          {
            await frame.layerList.getLayer(index: i).rasterizationComplete;
          }
        }
      }

      final ui.Image expected = await _renderOpenProject();
      final ui.Image thumbnail = await _thumbnailOf(loaded: await _saveAndLoad());

      expect(await _bytesOf(image: thumbnail), await _bytesOf(image: expected));
      thumbnail.dispose();
      expected.dispose();
    },);
  });
}
