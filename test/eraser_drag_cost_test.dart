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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

KPixPainterOptions _painterOptions()
{
  return KPixPainterOptions(
    cursorSize: 1.0,
    cursorBorderWidth: 1.0,
    selectionSolidStrokeWidth: 1.0,
    pixelExtension: 0.0,
    selectionPolygonCircleRadius: 1.0,
    selectionStrokeWidthLarge: 1.0,
    selectionStrokeWidthSmall: 1.0,
    backupPainterPollingRateMs: 100,
  );
}

/// One paint of the canvas, which is when a tool gets its turn.
DrawingParameters _params({required final LayerState layer, required final CoordinateSetI cursor, required final bool primaryDown})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 1,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: const Size(4, 4),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: Offset.zero,
    pixelRatio: 1.0,
    currentLayer: layer,
    symmetryHorizontal: null,
    symmetryVertical: null,
    isPlaying: false,
  );
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 128, y: 128);

CoordinateColorMapNullable _filled({required final ColorReference color})
{
  final CoordinateColorMapNullable content = CoordinateColorMapNullable();
  for (int x = 0; x < _canvasSize.x; x++)
  {
    for (int y = 0; y < _canvasSize.y; y++)
    {
      content[CoordinateSetI(x: x, y: y)] = color;
    }
  }
  return content;
}

Future<void> _settleAll({required final List<ShadingLayerState> shadingLayers}) async
{
  await settle();
  for (int i = 0; i < 80; i++)
  {
    if (!shadingLayers.any((final ShadingLayerState layer) => layer.doManualRaster || layer.isRasterizing))
    {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main()
{
  testWidgets("holding the eraser where nothing is left to erase costs no rasters", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: _filled(color: GetIt.I.get<PaletteState>().colorRamps.first.references[2]));
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, addToHistoryStack: false).$2! as ShadingLayerState;
      final HashMap<CoordinateSetI, int> shades = HashMap<CoordinateSetI, int>();
      for (int x = 40; x < 90; x++)
      {
        for (int y = 40; y < 90; y++)
        {
          shades[CoordinateSetI(x: x, y: y)] = 1;
        }
      }
      shading.addCoords(coords: shades);
      await _settleAll(shadingLayers: <ShadingLayerState>[shading]);

      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 5;
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());
      final CoordinateSetI spot = CoordinateSetI(x: 64, y: 64);

      //the first paint of the press takes the pixels out
      painter.calculate(drawParams: _params(layer: layer, cursor: spot, primaryDown: true));
      await _settleAll(shadingLayers: <ShadingLayerState>[shading]);
      expect(layer.getDataEntry(coord: spot), isNull, reason: "setup: the press erased");

      int drawingRasters = 0;
      int shadingRasters = 0;
      void onDrawing() => drawingRasters++;
      void onShading() => shadingRasters++;
      layer.rasterImage.addListener(onDrawing);
      shading.rasterImage.addListener(onShading);

      //the canvas keeps painting while the button is held, and every paint gives
      //the tool another turn over the same pixels
      for (int i = 0; i < 25; i++)
      {
        painter.calculate(drawParams: _params(layer: layer, cursor: spot, primaryDown: true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await _settleAll(shadingLayers: <ShadingLayerState>[shading]);

      layer.rasterImage.removeListener(onDrawing);
      shading.rasterImage.removeListener(onShading);

      expect(drawingRasters, 0, reason: "a pass that finds nothing to erase changes nothing, so nothing has to be rendered again");
      expect(shadingRasters, 0, reason: "and nothing below the shading changed either");
    },);
  });

  testWidgets("a press that erases nothing leaves nothing for the history", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await settle();
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 20, y: 20)), isNull, reason: "setup: the layer is empty");

      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 20, y: 20), primaryDown: true));
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 20, y: 20), primaryDown: false));

      expect(painter.hasHistoryData, isFalse);
    },);
  });

  testWidgets("erasing inside a floating selection shows on the canvas", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: _filled(color: GetIt.I.get<PaletteState>().colorRamps.first.references[2]));
      await settle();
      //a selection holds the pixels it covers itself, and the layer's raster has
      //it composed in, so an erasure inside it has to make that raster again
      GetIt.I.get<DocumentState>().selectionState.selectAll();
      await settle();
      final CoordinateSetI spot = CoordinateSetI(x: 64, y: 64);
      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: spot), isNotNull, reason: "setup: the selection floats the pixels");

      int rasters = 0;
      void onRaster() => rasters++;
      layer.rasterImage.addListener(onRaster);

      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 3;
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());
      painter.calculate(drawParams: _params(layer: layer, cursor: spot, primaryDown: true));
      await settle();

      layer.rasterImage.removeListener(onRaster);

      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: spot), isNull, reason: "the pixel was taken out of the selection");
      expect(rasters, greaterThan(0), reason: "and the layer was rendered again so the canvas shows it gone");
      expect(painter.hasHistoryData, isFalse, reason: "the button is still down");
      painter.calculate(drawParams: _params(layer: layer, cursor: spot, primaryDown: false));
      expect(painter.hasHistoryData, isTrue, reason: "releasing after an erasure leaves an undo step");
    },);
  });

  testWidgets("a shading layer keeps up with an eraser drag below it", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: _filled(color: GetIt.I.get<PaletteState>().colorRamps.first.references[2]));
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, addToHistoryStack: false).$2! as ShadingLayerState;
      final HashMap<CoordinateSetI, int> shades = HashMap<CoordinateSetI, int>();
      for (int x = 0; x < _canvasSize.x; x++)
      {
        for (int y = 0; y < _canvasSize.y; y++)
        {
          shades[CoordinateSetI(x: x, y: y)] = 1;
        }
      }
      shading.addCoords(coords: shades);
      await _settleAll(shadingLayers: <ShadingLayerState>[shading]);

      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 5;
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());

      int shadingRasters = 0;
      void onShading() => shadingRasters++;
      shading.rasterImage.addListener(onShading);

      //a drag that finds something to erase on every paint, so the layer below
      //owes a raster for the whole of it
      for (int i = 0; i < 30; i++)
      {
        painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 30 + i, y: 64), primaryDown: true));
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 59, y: 64), primaryDown: false));
      shading.rasterImage.removeListener(onShading);

      //the shading used to get no turn at all until the drag ended, because the
      //layer it reads always had another batch owing
      expect(shadingRasters, greaterThan(3), reason: "the shading above followed the drag instead of waiting for it to end");
    },);
  });

  testWidgets("a write is rastered right away, not on the scheduler's next tick", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await settle();
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 5, y: 5): GetIt.I.get<PaletteState>().colorRamps.first.references[2]}));
      expect(layer.isRasterizing, isFalse, reason: "setup: nothing runs inside the write itself");
      await Future<void>.microtask(() {});
      expect(layer.isRasterizing, isTrue);
      await settle();
    },);
  });

  testWidgets("a drag does not rebuild the selected frame's composite after every batch", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: _filled(color: GetIt.I.get<PaletteState>().colorRamps.first.references[2]));
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final LayerCollection collection = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList;
      final ui.Image? first = collection.rasterImage;
      expect(first, isNotNull, reason: "setup: the composite is there once edits pause");

      for (int i = 0; i < 5; i++)
      {
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 10 + i, y: 10): null}));
        await settle();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(identical(collection.rasterImage, first), isTrue, reason: "batch ${i + 1} of a drag");
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(identical(collection.rasterImage, first), isFalse, reason: "it is rebuilt once the edits pause");
    },);
  });
}
