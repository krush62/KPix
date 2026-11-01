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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// How large a canvas pixel is on screen while a tool is driven.
const int toolPixelSize = 4;

KPixPainterOptions testPainterOptions()
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

/// The middle of the pixel [coord] on screen, with the canvas at the origin.
Offset screenPosOf({required final CoordinateSetI coord})
{
  return Offset(coord.x * toolPixelSize + toolPixelSize / 2, coord.y * toolPixelSize + toolPixelSize / 2);
}

DrawingParameters toolParams({
  required final LayerState layer,
  required final CoordinateSetI? cursor,
  final bool primaryDown = false,
  final CoordinateSetI? pressStart,
  final double? symmetryHorizontal,
  final double? symmetryVertical,
  final bool stylusButtonDown = false,
  final Canvas? canvas,
})
{
  final Offset? cursorOnScreen = cursor == null ? null : screenPosOf(coord: cursor);
  return DrawingParameters(
    offset: Offset.zero,
    canvas: canvas ?? Canvas(ui.PictureRecorder()),
    paint: Paint(),
    pixelSize: toolPixelSize,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: const Size(640, 640),
    cursorPos: cursorOnScreen == null ? null : CoordinateSetD(x: cursorOnScreen.dx, y: cursorOnScreen.dy),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: stylusButtonDown,
    secondaryDown: false,
    primaryPressStart: pressStart == null ? Offset.zero : screenPosOf(coord: pressStart),
    pixelRatio: 1.0,
    currentLayer: layer,
    symmetryHorizontal: symmetryHorizontal,
    symmetryVertical: symmetryVertical,
    isPlaying: false,
  );
}

/// Presses at the first of [path], moves along it and releases at the last.
void dragTool({required final IToolPainter painter, required final LayerState layer, required final List<CoordinateSetI> path, final double? symmetryHorizontal, final double? symmetryVertical})
{
  final CoordinateSetI start = path.first;
  painter.calculate(drawParams: toolParams(layer: layer, cursor: start, symmetryHorizontal: symmetryHorizontal, symmetryVertical: symmetryVertical));
  for (final CoordinateSetI coord in path)
  {
    painter.calculate(drawParams: toolParams(layer: layer, cursor: coord, primaryDown: true, pressStart: start, symmetryHorizontal: symmetryHorizontal, symmetryVertical: symmetryVertical));
    painter.drawExtras(drawParams: toolParams(layer: layer, cursor: coord, primaryDown: true, pressStart: start, symmetryHorizontal: symmetryHorizontal, symmetryVertical: symmetryVertical));
  }
  painter.calculate(drawParams: toolParams(layer: layer, cursor: path.last, pressStart: start, symmetryHorizontal: symmetryHorizontal, symmetryVertical: symmetryVertical));
}

/// What a tool draws and calls without a canvas behind it: the outline, the status
/// bar and the cursor info, which have to cope with a cursor on and off the canvas.
void exerciseToolOverlays({required final IToolPainter painter, required final LayerState layer, required final CoordinateSetI cursor})
{
  final DrawingParameters params = toolParams(layer: layer, cursor: cursor);
  painter.calculate(drawParams: params);
  painter.drawExtras(drawParams: params);
  painter.drawCursorOutline(drawParams: params);
  painter.setStatusBarData(drawParams: params);
  painter.getCursorInfo(drawParams: params);
}

/// The pixels of [layer], with their effects left out.
Map<CoordinateSetI, ColorReference> colorsOf({required final DrawingLayerState layer})
{
  final CoordinateSetI size = GetIt.I.get<CanvasState>().canvasSize;
  final Map<CoordinateSetI, ColorReference> colors = <CoordinateSetI, ColorReference>{};
  for (int x = 0; x < size.x; x++)
  {
    for (int y = 0; y < size.y; y++)
    {
      final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
      final ColorReference? color = layer.getDataEntry(coord: coord);
      if (color != null)
      {
        colors[coord] = color;
      }
    }
  }
  return colors;
}

/// The values of a shading layer.
Map<CoordinateSetI, int> shadesOf({required final ShadingLayerState layer})
{
  final CoordinateSetI size = GetIt.I.get<CanvasState>().canvasSize;
  final Map<CoordinateSetI, int> shades = <CoordinateSetI, int>{};
  for (int x = 0; x < size.x; x++)
  {
    for (int y = 0; y < size.y; y++)
    {
      final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
      final int? value = layer.getRawValueAt(coord: coord);
      if (value != null)
      {
        shades[coord] = value;
      }
    }
  }
  return shades;
}

/// [coords] as rows of text for the [size] canvas, which makes a shape readable in
/// a test and in its failure message.
List<String> patternOf({required final Iterable<CoordinateSetI> coords, required final CoordinateSetI size})
{
  final Set<CoordinateSetI> set = coords.toSet();
  return <String>[
    for (int y = 0; y < size.y; y++)
      <String>[
        for (int x = 0; x < size.x; x++) set.contains(CoordinateSetI(x: x, y: y)) ? "#" : ".",
      ].join(),
  ];
}
