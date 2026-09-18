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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// A regional raster repaints only the regions tracked before it started, on top
/// of the image it had. Whatever changed outside them stays on the canvas as it
/// was until something forces a full raster - toggling the layer's visibility,
/// for one - which is what makes this kind of bug look intermittent.

final CoordinateSetI _canvasSize = CoordinateSetI(x: 64, y: 64);

/// What the layer's raster shows at [coord], as RGBA; 0 where it shows nothing.
Future<int> _shownAt({required final DrawingLayerState layer, required final CoordinateSetI coord}) async
{
  final ui.Image image = layer.rasterImage.value!;
  final ByteData bytes = (await image.toByteData())!;
  return bytes.getUint32((coord.y * image.width + coord.x) * 4);
}

int _rgbaOf({required final ColorReference color})
{
  return argbToRgba(argb: color.getIdColor().color.toARGB32());
}

/// Writes [pixels] to [layer] and waits for the raster, then does it once more
/// elsewhere so the layer has an image of its own to render regions onto (the
/// first raster after an empty start is always a full one).
Future<void> _prepare({required final DrawingLayerState layer, required final CoordinateColorMapNullable pixels, required final ColorReference color}) async
{
  layer.setDataAll(list: pixels);
  await settle();
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 63, y: 63): color}));
  await settle();
}

DrawingParameters _eraserParams({required final DrawingLayerState layer, required final CoordinateSetI cursor, required final bool primaryDown})
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

void main()
{
  testWidgets("a pixel erased while the layer is rasterizing leaves the canvas too", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final CoordinateColorMapNullable row = CoordinateColorMapNullable();
      for (int x = 0; x < _canvasSize.x; x++)
      {
        row[CoordinateSetI(x: x, y: 10)] = color;
      }
      await _prepare(layer: layer, pixels: row, color: color);

      final CoordinateSetI early = CoordinateSetI(x: 5, y: 10);
      final CoordinateSetI late = CoordinateSetI(x: 50, y: 10);
      expect(await _shownAt(layer: layer, coord: early), _rgbaOf(color: color), reason: "setup: the row shows");

      //an eraser drag hands over a batch on every paint, and paints keep coming
      //while a raster is being made; the next raster then picks up this one
      //together with the batches that came after it
      layer.isRasterizing = true;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{early: null}));
      layer.isRasterizing = false;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{late: null}));
      await settle();

      expect(layer.getDataEntry(coord: early), isNull, reason: "setup: the layer holds the erasure");
      expect(await _shownAt(layer: layer, coord: late), 0);
      expect(await _shownAt(layer: layer, coord: early), 0, reason: "the erasure that came in during the raster has to be repainted too");
      expect(await _shownAt(layer: layer, coord: CoordinateSetI(x: 30, y: 10)), _rgbaOf(color: color), reason: "what was not erased still shows");
    },);
  });

  testWidgets("an eraser drag leaves none of the pixels it passed over on the canvas", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final CoordinateColorMapNullable band = CoordinateColorMapNullable();
      for (int x = 0; x < _canvasSize.x; x++)
      {
        for (int y = 20; y < 44; y++)
        {
          band[CoordinateSetI(x: x, y: y)] = color;
        }
      }
      await _prepare(layer: layer, pixels: band, color: color);

      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 3;
      final EraserPainter painter = EraserPainter(painterOptions: KPixPainterOptions(
        cursorSize: 1.0,
        cursorBorderWidth: 1.0,
        selectionSolidStrokeWidth: 1.0,
        pixelExtension: 0.0,
        selectionPolygonCircleRadius: 1.0,
        selectionStrokeWidthLarge: 1.0,
        selectionStrokeWidthSmall: 1.0,
        backupPainterPollingRateMs: 100,
      ),);
      //paints come faster than rasters finish, so batches keep landing on a
      //layer that is busy rendering the previous ones
      for (int i = 0; i < 3; i++)
      {
        for (int x = 2; x < 62; x++)
        {
          painter.calculate(drawParams: _eraserParams(layer: layer, cursor: CoordinateSetI(x: x, y: 26 + i * 6), primaryDown: true));
          await Future<void>.delayed(const Duration(milliseconds: 3));
        }
        painter.calculate(drawParams: _eraserParams(layer: layer, cursor: CoordinateSetI(x: 61, y: 26 + i * 6), primaryDown: false));
      }
      await settle();

      final ui.Image image = layer.rasterImage.value!;
      final ByteData bytes = (await image.toByteData())!;
      final List<String> stale = <String>[];
      int erased = 0;
      for (int y = 0; y < _canvasSize.y; y++)
      {
        for (int x = 0; x < _canvasSize.x; x++)
        {
          final ColorReference? held = layer.getDataEntry(coord: CoordinateSetI(x: x, y: y));
          final int shown = bytes.getUint32((y * image.width + x) * 4);
          if (held == null && band.containsKey(CoordinateSetI(x: x, y: y)))
          {
            erased++;
          }
          if (shown != (held == null ? 0 : _rgbaOf(color: held)))
          {
            stale.add("$x|$y");
          }
        }
      }
      expect(erased, greaterThan(100), reason: "setup: the drag erased");
      expect(stale, isEmpty, reason: "the canvas has to show what the layer holds");
    },);
  });

  testWidgets("moving a selection right after drawing elsewhere repaints both", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final CoordinateSetI dot = CoordinateSetI(x: 10, y: 10);
      await _prepare(layer: layer, pixels: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: color}), color: color);

      final SelectionState selectionState = GetIt.I.get<DocumentState>().selectionState;
      selectionState.newSelectionFromShape(start: CoordinateSetI(x: 8, y: 8), end: CoordinateSetI(x: 12, y: 12), selectShape: SelectShape.rectangle);
      await settle();
      expect(await _shownAt(layer: layer, coord: dot), _rgbaOf(color: color), reason: "setup: the dot floats in the selection and still shows");

      //a stroke lands elsewhere, and before its raster runs the selection is
      //moved, which asks for a raster without saying where
      final CoordinateSetI stroke = CoordinateSetI(x: 40, y: 40);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{stroke: color}));
      selectionState.setOffset(offset: CoordinateSetI(x: 1, y: 0), withContent: true);
      selectionState.finishMovement();
      await settle();

      expect(await _shownAt(layer: layer, coord: stroke), _rgbaOf(color: color));
      expect(await _shownAt(layer: layer, coord: CoordinateSetI(x: 11, y: 10)), _rgbaOf(color: color), reason: "the dot shows where it was moved to");
      expect(await _shownAt(layer: layer, coord: dot), 0, reason: "and not where it was any more");
    },);
  });
}
