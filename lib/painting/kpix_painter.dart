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
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/fill_painter.dart';
import 'package:kpix/painting/font_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/line_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/painting/shape_painter.dart';
import 'package:kpix/painting/spray_can_painter.dart';
import 'package:kpix/painting/stamp_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/typedefs.dart';

class KPixPainterOptions
{
  final double cursorSize;
  final double cursorBorderWidth;
  final double selectionSolidStrokeWidth;
  final double pixelExtension;
  final double selectionPolygonCircleRadius;
  final double selectionStrokeWidthLarge;
  final double selectionStrokeWidthSmall;

  KPixPainterOptions({
    required this.cursorSize,
    required this.cursorBorderWidth,
    required this.selectionSolidStrokeWidth,
    required this.pixelExtension,
    required this.selectionPolygonCircleRadius,
    required this.selectionStrokeWidthLarge,
    required this.selectionStrokeWidthSmall,
  });
}

class DrawingParameters
{
  final Offset offset;
  final Canvas canvas;
  final Paint paint;
  final int pixelSize;
  final CoordinateSetI canvasSize;
  final CoordinateSetI scaledCanvasSize;
  final CoordinateSetI drawingStart;
  final CoordinateSetI drawingEnd;
  final Size drawingSize;
  final CoordinateSetD? cursorPos;
  final bool primaryDown;
  final bool secondaryDown;
  final Offset primaryPressStart;
  final DrawingLayerState? currentDrawingLayer;
  final ReferenceLayerState? currentReferenceLayer;
  DrawingParameters({
    required this.offset,
    required this.canvas,
    required this.paint,
    required this.pixelSize,
    required this.canvasSize,
    required this.drawingSize,
    required this.cursorPos,
    required this.primaryDown,
    required this.secondaryDown,
    required this.primaryPressStart,
    required LayerState currentLayer
}) :
    scaledCanvasSize = CoordinateSetI(x: canvasSize.x * pixelSize, y: canvasSize.y * pixelSize),
    drawingStart = CoordinateSetI(x: offset.dx > 0 ? 0 : -(offset.dx / pixelSize).ceil(), y: offset.dy > 0 ? 0 : -(offset.dy / pixelSize).ceil()),
    drawingEnd = CoordinateSetI(x: offset.dx + (canvasSize.x * pixelSize) < drawingSize.width ? canvasSize.x : canvasSize.x - ((offset.dx + (canvasSize.x * pixelSize) - drawingSize.width) / pixelSize).floor(),
                                y: offset.dy + (canvasSize.y) * pixelSize < drawingSize.height ? canvasSize.y : canvasSize.y - ((offset.dy + (canvasSize.y * pixelSize) - drawingSize.height) / pixelSize).floor()),
    currentDrawingLayer = currentLayer.runtimeType == DrawingLayerState ? (currentLayer as DrawingLayerState) : null,
    currentReferenceLayer = currentLayer.runtimeType == ReferenceLayerState ? (currentLayer as ReferenceLayerState) : null;

}

class KPixPainter extends CustomPainter
{
  final AppState _appState;
  final ValueNotifier<Offset> _offset;
  final ValueNotifier<CoordinateSetD?> _coords;
  final ValueNotifier<bool> _isDragging;
  final ValueNotifier<bool> _stylusLongMoveStarted;
  final ValueNotifier<bool> _stylusLongMoveVertical;
  final ValueNotifier<bool> _stylusLongMoveHorizontal;
  final ValueNotifier<bool> _primaryDown;
  final ValueNotifier<bool> _secondaryDown;
  final ValueNotifier<Offset> _primaryPressStart;
  final KPixPainterOptions _options = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final GuiPreferenceContent _guiOptions = GetIt.I.get<PreferenceManager>().guiPreferenceContent;
  late Color _blackSelectionAlphaColor;
  late Color _whiteSelectionAlphaColor;
  late Color _blackBorderAlphaColor;
  late Map<ToolType, IToolPainter> toolPainterMap;
  late Size latestSize = const Size(0,0);
  late int _latestRasterSize = 8;
  late int _latestContrast = 50;
  IToolPainter? toolPainter;
  late ui.Image _checkerboardImage;

  // status for reference layer movements
  bool _referenceImgMovementStarted = false;
  final CoordinateSetD _referenceImgNormStartPos = CoordinateSetD(x: 0, y: 0);
  final CoordinateSetD _referenceImgcursorPosNorm = CoordinateSetD(x: 0, y: 0);
  Offset _referenceImglastStartPos = const Offset(0, 0);
  final CoordinateSetD _referenceImgLastReferenceOffset = CoordinateSetD(x: 0, y: 0);


  KPixPainter({
    required AppState appState,
    required ValueNotifier<Offset> offset,
    required ValueNotifier<CoordinateSetD?> coords,
    required ValueNotifier<bool> primaryDown,
    required ValueNotifier<bool> secondaryDown,
    required ValueNotifier<Offset> primaryPressStart,
    required ValueNotifier<bool> isDragging,
    required ValueNotifier<bool> stylusLongMoveStarted,
    required ValueNotifier<bool> stylusLongMoveVertical,
    required ValueNotifier<bool> stylusLongMoveHorizontal})
      : _appState = appState,
        _offset = offset,
        _coords = coords,
        _isDragging = isDragging,
        _stylusLongMoveStarted = stylusLongMoveStarted,
        _stylusLongMoveVertical = stylusLongMoveVertical,
        _stylusLongMoveHorizontal = stylusLongMoveHorizontal,
        _primaryDown = primaryDown,
        _secondaryDown = secondaryDown,
        _primaryPressStart = primaryPressStart,
        super(repaint: appState.repaintNotifier)
  {
    _guiOptions.selectionOpacity.addListener(() {
      _setSelectionColors(percentageValue: _guiOptions.selectionOpacity.value);
    },);
    _setSelectionColors(percentageValue: _guiOptions.selectionOpacity.value);

    _guiOptions.canvasBorderOpacity.addListener(() {
      _setCanvasBorderColor(percentageValue: _guiOptions.canvasBorderOpacity.value);
    },);
    _setCanvasBorderColor(percentageValue: _guiOptions.canvasBorderOpacity.value);

    toolPainterMap = {
      ToolType.select: SelectionPainter(painterOptions: _options),
      ToolType.erase: EraserPainter(painterOptions: _options),
      ToolType.pencil: PencilPainter(painterOptions: _options),
      ToolType.pick: ColorPickPainter(painterOptions: _options),
      ToolType.fill: FillPainter(painterOptions: _options),
      ToolType.shape: ShapePainter(painterOptions: _options),
      ToolType.font: FontPainter(painterOptions: _options),
      ToolType.spraycan: SprayCanPainter(painterOptions: _options),
      ToolType.line: LinePainter(painterOptions: _options),
      ToolType.stamp: StampPainter(painterOptions: _options)
    };

  }

  void _setSelectionColors({required final int percentageValue})
  {
    final int alignedValue = (percentageValue.toDouble() * 2.55).round();
    _blackSelectionAlphaColor = Colors.black.withAlpha(alignedValue);
    _whiteSelectionAlphaColor = Colors.white.withAlpha(alignedValue);
  }

  void _setCanvasBorderColor({required final int percentageValue})
  {
    final int alignedValue = (percentageValue.toDouble() * 2.55).round();
    _blackBorderAlphaColor = Colors.black.withAlpha(alignedValue);
  }

  @override
  void paint(Canvas canvas, Size size)
  {
    if (_appState.getSelectedLayer() != null)
    {
      final currentToolPainter = toolPainterMap[_appState.selectedTool];
      if (currentToolPainter != toolPainter)
      {
        if (toolPainter != null)
        {
          toolPainter!.reset();
        }
        toolPainter = currentToolPainter;
      }
      if (size != latestSize || rasterSizes[_guiOptions.rasterSizeIndex.value] != _latestRasterSize || _guiOptions.rasterContrast.value != _latestContrast)
      {
        latestSize = size;
        _latestRasterSize = rasterSizes[_guiOptions.rasterSizeIndex.value];
        _latestContrast = _guiOptions.rasterContrast.value;
        _createCheckerboard();
      }

      DrawingParameters drawParams = DrawingParameters(
        offset: _offset.value,
        canvas: canvas,
        paint: Paint(),
        pixelSize: _appState.zoomFactor,
        canvasSize: _appState.canvasSize,
        drawingSize: size,
        cursorPos: _coords.value,
        primaryDown: _primaryDown.value,
        secondaryDown: _secondaryDown.value,
        primaryPressStart: _primaryPressStart.value,
        currentLayer: _appState.getSelectedLayer()!,
      );

      if (drawParams.currentReferenceLayer != null)
      {
        _drawReferenceBorder(drawParams: drawParams, refLayer: drawParams.currentReferenceLayer!);
      }

      _drawCheckerboard(drawParams: drawParams);
      _drawCanvasBorder(drawParams: drawParams);
      if (drawParams.currentDrawingLayer != null)
      {
        toolPainter?.calculate(drawParams: drawParams);
      }
      if (drawParams.currentReferenceLayer != null)
      {
        _handleReferenceLayer(drawParams: drawParams, refLayer: drawParams.currentReferenceLayer!);
      }
      _drawLayers(drawParams: drawParams);
      if (drawParams.currentDrawingLayer != null)
      {
        _drawSelection(drawParams: drawParams);
      }
      if (drawParams.currentDrawingLayer != null)
      {
        toolPainter?.drawExtras(drawParams: drawParams);
      }
      _drawCursor(drawParams: drawParams);
      if (drawParams.currentDrawingLayer != null)
      {
        toolPainter?.setStatusBarData(drawParams: drawParams);
      }
    }
  }

  void _drawCanvasBorder({required final DrawingParameters drawParams, final int width = 2})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    final ui.Rect borderRect = ui.Rect.fromLTWH(
        drawParams.offset.dx - width,
        drawParams.offset.dy - width,
        drawParams.canvasSize.x * pxlSzDbl + (width * 2),
        drawParams.canvasSize.y * pxlSzDbl + (width * 2));

    final Paint p = Paint();
    p.color = _blackBorderAlphaColor;
    p.style = ui.PaintingStyle.stroke;
    p.strokeWidth = width.toDouble();
    drawParams.canvas.drawRect(borderRect, p);

  }

  void _drawReferenceBorder({required final DrawingParameters drawParams, required final ReferenceLayerState refLayer})
  {
    if (refLayer.image != null)
    {
      final double pxlSzDbl = drawParams.pixelSize.toDouble();
      final ui.Image image = refLayer.image!.image;

      final ui.Rect borderRect = ui.Rect.fromLTWH(
          drawParams.offset.dx + (refLayer.offsetX * pxlSzDbl),
          drawParams.offset.dy + (refLayer.offsetY * pxlSzDbl),
          image.width * refLayer.zoomFactor * refLayer.aspectRatioFactorX * pxlSzDbl,
          image.height * refLayer.zoomFactor * refLayer.aspectRatioFactorY * pxlSzDbl
      );

      final Paint p = Paint();
      p.color = _blackSelectionAlphaColor;
      p.style = ui.PaintingStyle.stroke;
      p.strokeWidth = 1;
      drawParams.canvas.drawRect(borderRect, p);
    }
  }

  void _handleReferenceLayer({required final DrawingParameters drawParams, required final ReferenceLayerState refLayer})
  {
    if (_referenceImglastStartPos != drawParams.primaryPressStart)
    {
      _referenceImgNormStartPos.x = (drawParams.primaryPressStart.dx - drawParams.offset.dx) / drawParams.pixelSize.toDouble();
      _referenceImgNormStartPos.y = (drawParams.primaryPressStart.dy - drawParams.offset.dy) / drawParams.pixelSize.toDouble();
      _referenceImglastStartPos = drawParams.primaryPressStart;
      _referenceImgMovementStarted = true;
    }
    if (drawParams.cursorPos != null)
    {
       _referenceImgcursorPosNorm.x = (drawParams.cursorPos!.x - drawParams.offset.dx) / drawParams.pixelSize.toDouble();
       _referenceImgcursorPosNorm.y = (drawParams.cursorPos!.y - drawParams.offset.dy) / drawParams.pixelSize.toDouble();

       if (drawParams.primaryDown)
       {
         final CoordinateSetD offset = CoordinateSetD(x: _referenceImgcursorPosNorm.x - _referenceImgNormStartPos.x, y: _referenceImgcursorPosNorm.y - _referenceImgNormStartPos.y);
         if (offset != _referenceImgLastReferenceOffset)
         {
           refLayer.offsetXNotifier.value += offset.x - _referenceImgLastReferenceOffset.x;
           refLayer.offsetYNotifier.value += offset.y - _referenceImgLastReferenceOffset.y;
           _referenceImgLastReferenceOffset.x = offset.x;
           _referenceImgLastReferenceOffset.y = offset.y;
         }
       }
    }

    if (!drawParams.primaryDown && _referenceImgMovementStarted)
    {
      _referenceImgLastReferenceOffset.x = 0;
      _referenceImgLastReferenceOffset.y = 0;
      _referenceImgMovementStarted = false;
    }
  }

  void _drawSelection({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = _options.selectionSolidStrokeWidth;

    if (!_appState.selectionState.selection.isEmpty)
    {
      for (final SelectionLine line in _appState.selectionState.selectionLines) {
        if (line.selectDir == SelectionDirection.left) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.startLoc.y * pxlSzDbl)),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.right) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.startLoc.y * pxlSzDbl)),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.top) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx + (line.startLoc.x * pxlSzDbl),
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.bottom) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx + (line.startLoc.x * pxlSzDbl),
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
        }
      }
    }
  }

  void _drawCursor({required final DrawingParameters drawParams})
  {
    if (_coords.value != null)
    {
      if (!_isDragging.value /*&& isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!)*/ && toolPainter != null && drawParams.currentDrawingLayer != null)
      {
        toolPainter!.drawCursorOutline(drawParams: drawParams);
      }
      else if (!_stylusLongMoveStarted.value)
      {
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), _options.cursorSize + _options.cursorBorderWidth, drawParams.paint);
        drawParams.paint.color = _whiteSelectionAlphaColor;
        drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), _options.cursorSize, drawParams.paint);
      }

      if (_stylusLongMoveStarted.value)
      {
        if (_stylusLongMoveHorizontal.value)
        {
          Path path1 = Path();
          path1.moveTo(_coords.value!.x + (-1 * _options.cursorSize), _coords.value!.y + (-1 * _options.cursorSize));
          path1.lineTo(_coords.value!.x + (-2 * _options.cursorSize), _coords.value!.y);
          path1.lineTo(_coords.value!.x + (-1 * _options.cursorSize), _coords.value!.y + (1 * _options.cursorSize));

          Path path2 = Path();
          path1.moveTo(_coords.value!.x + (1 * _options.cursorSize), _coords.value!.y + (-1 * _options.cursorSize));
          path1.lineTo(_coords.value!.x + (2 * _options.cursorSize), _coords.value!.y);
          path1.lineTo(_coords.value!.x + (1 * _options.cursorSize), _coords.value!.y + (1 * _options.cursorSize));

          drawParams.paint.style = PaintingStyle.stroke;
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthLarge;
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawPath(path1, drawParams.paint);
          drawParams.canvas.drawPath(path2, drawParams.paint);
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthSmall;
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawPath(path1, drawParams.paint);
          drawParams.canvas.drawPath(path2, drawParams.paint);

        }
        else if (_stylusLongMoveVertical.value)
        {
          Path path = Path();
          path.moveTo(_coords.value!.x + (-2 * _options.cursorSize), _coords.value!.y + (2 * _options.cursorSize));
          path.lineTo(_coords.value!.x, _coords.value!.y);
          path.lineTo(_coords.value!.x + (2 * _options.cursorSize), _coords.value!.y);
          path.lineTo(_coords.value!.x + (2 * _options.cursorSize), _coords.value!.y + (-2 * _options.cursorSize));
          path.lineTo(_coords.value!.x, _coords.value!.y + (-2 * _options.cursorSize));
          path.lineTo(_coords.value!.x, _coords.value!.y);
          drawParams.paint.style = PaintingStyle.stroke;
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthLarge;
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawPath(path, drawParams.paint);
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthSmall;
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawPath(path, drawParams.paint);
        }
      }
    }
  }

  void _drawLayers({required final DrawingParameters drawParams})
  {
    final List<LayerState> layers = _appState.layers;
    final bool hasRasterizingLayers = layers.whereType<DrawingLayerState>().where((l) => (l.visibilityState.value == LayerVisibilityState.visible && (l.thumbnail.value == null || l.isRasterizing))).isNotEmpty;

    if (hasRasterizingLayers)
    {
      //SKIP FRAME
    }
    else
    {
      final double pxlSzDbl = drawParams.pixelSize.toDouble();

      for (int i = layers.length - 1; i >= 0; i--)
      {
        if (layers[i].visibilityState.value == LayerVisibilityState.visible)
        {
          if (layers[i].runtimeType == DrawingLayerState)
          {
            final DrawingLayerState drawingLayer = layers[i] as DrawingLayerState;
            if (drawingLayer.thumbnail.value != null)
            {
              //TODO can we optimize this by not drawing the full raster image???
              paintImage(
                  canvas: drawParams.canvas,
                  rect: ui.Rect.fromLTWH(drawParams.offset.dx, drawParams.offset.dy,
                      drawParams.scaledCanvasSize.x.toDouble(),
                      drawParams.scaledCanvasSize.y.toDouble()),
                  image: drawingLayer.thumbnail.value!,
                  scale: 1.0 / pxlSzDbl,
                  fit: BoxFit.none,
                  alignment: Alignment.topLeft,
                  filterQuality: FilterQuality.none);
            }

            if (layers[i].isSelected.value)
            {
              final CoordinateColorMap selectedLayerCursorContent = toolPainter != null ? toolPainter!.getCursorContent(drawParams: drawParams) : HashMap();
              final CoordinateColorMap toolContent = toolPainter != null ? toolPainter!.getToolContent(drawParams: drawParams) : HashMap();
              for (int x = drawParams.drawingStart.x; x < drawParams.drawingEnd.x; x++)
              {
                for (int y = drawParams.drawingStart.y; y < drawParams.drawingEnd.y; y++)
                {
                  Color? drawColor;
                  //DRAW CURSOR CONTENT PIXEL
                  final selLayerCoord = CoordinateSetI(x: x, y: y);
                  if (selectedLayerCursorContent.keys.contains(selLayerCoord))
                  {
                    drawColor = selectedLayerCursorContent[selLayerCoord]!.getIdColor().color;
                  }

                  //DRAW TOOL CONTENT
                  if (drawColor == null && toolContent.keys.contains(selLayerCoord))
                  {
                    drawColor = toolContent[selLayerCoord]!.getIdColor().color;
                  }

                  //DRAW SELECTION PIXEL
                  /*if (drawColor == null)
                  {
                    ColorReference? selColor = _appState.selectionState.selection.getColorReference(coord: CoordinateSetI(x: x, y: y));
                    if (selColor != null)
                    {
                      drawColor = selColor.getIdColor().color;
                    }
                  }*/
                  if (drawColor != null)
                  {
                    drawParams.paint.color = drawColor;
                    drawParams.canvas.drawRect(Rect.fromLTWH(
                        _offset.value.dx + (x * pxlSzDbl) - _options.pixelExtension,
                        _offset.value.dy + (y * pxlSzDbl) - _options.pixelExtension,
                        pxlSzDbl + (2.0 * _options.pixelExtension),
                        pxlSzDbl + (2.0 * _options.pixelExtension)),
                        drawParams.paint);
                  }
                }
              }
            }
          }
          else if (layers[i].runtimeType == ReferenceLayerState)
          {
            final ReferenceLayerState refLayer = layers[i] as ReferenceLayerState;
            if (refLayer.image != null)
            {
              final ui.Image image = refLayer.image!.image;

              final ui.Rect srcRect = ui.Rect.fromLTWH(
                -refLayer.offsetX / refLayer.zoomFactor / refLayer.aspectRatioFactorX,
                -refLayer.offsetY / refLayer.zoomFactor / refLayer.aspectRatioFactorY,
                drawParams.canvasSize.x.toDouble() / refLayer.zoomFactor / refLayer.aspectRatioFactorX,
                drawParams.canvasSize.y.toDouble() / refLayer.zoomFactor / refLayer.aspectRatioFactorY
              );

              final ui.Rect targetRect = ui.Rect.fromLTWH(
                drawParams.offset.dx,
                drawParams.offset.dy,
                drawParams.scaledCanvasSize.x.toDouble(),
                drawParams.scaledCanvasSize.y.toDouble(),
              );

              final Paint paint = Paint()..color = Color.fromARGB((refLayer.opacity.toDouble() * 2.55).round(), 255, 255, 255);
              drawParams.canvas.drawImageRect(image, srcRect, targetRect, paint);
            }
          }
          else if (layers[i].runtimeType == GridLayerState)
          {
            final GridLayerState gridLayer = layers[i] as GridLayerState;
            if (gridLayer.raster != null)
            {
              //TODO can we optimize this by not drawing the full raster image???
              paintImage(
                  canvas: drawParams.canvas,
                  rect: ui.Rect.fromLTWH(drawParams.offset.dx, drawParams.offset.dy,
                      drawParams.scaledCanvasSize.x.toDouble(),
                      drawParams.scaledCanvasSize.y.toDouble()),
                  image: gridLayer.raster!,
                  scale: 1.0 / pxlSzDbl,
                  fit: BoxFit.none,
                  alignment: Alignment.topLeft,
                  filterQuality: FilterQuality.none);
            }
          }
        }
      }
    }
  }

  (ui.Color, ui.Color) getCheckerBoardColors(final int contrast)
  {
    final int difference = (contrast.toDouble() * (127.0 / rasterContrastMax)).toInt();
    final int val1 = 127 + difference;
    final int val2 = 128 - difference;
    return (ui.Color.fromARGB(255, val1, val1, val1), ui.Color.fromARGB(255, val2, val2, val2));
  }

  void _createCheckerboard()
  {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();
    bool rowFlip = false;
    bool colFlip = false;

    final (ui.Color, ui.Color) checkerColors = getCheckerBoardColors(_latestContrast);

    for (int x = 0; x < latestSize.width; x += _latestRasterSize)
    {
      colFlip = rowFlip;
      for (int y = 0; y < latestSize.height; y += _latestRasterSize)
      {
        paint.color = colFlip ? checkerColors.$1 : checkerColors.$2;
        int width = _latestRasterSize;
        int height = _latestRasterSize;
        if (x + _latestRasterSize > latestSize.width.floor())
        {
          width = latestSize.width.floor() - x;
        }

        if (y + _latestRasterSize > latestSize.height.floor())
        {
          height = latestSize.height.floor() - y;
        }
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble() , width.toDouble(), height.toDouble()),
          paint,
        );
        colFlip = !colFlip;
      }
      rowFlip = !rowFlip;
    }
    final ui.Picture picture = recorder.endRecording();
    _checkerboardImage = picture.toImageSync(latestSize.width.floor(), latestSize.height.floor());
  }

  void _drawCheckerboard({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    paintImage(
        canvas: drawParams.canvas,
        rect: ui.Rect.fromLTWH(drawParams.offset.dx, drawParams.offset.dy, drawParams.scaledCanvasSize.x.toDouble(), drawParams.scaledCanvasSize.y.toDouble()),
        image: _checkerboardImage,
        scale: 1.0 / pxlSzDbl,
        fit: BoxFit.none,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.none);
  }



  static bool isOnCanvas({required final DrawingParameters drawParams, required final CoordinateSetD testCoords})
  {
    bool isOn = false;
    if (testCoords.x >= drawParams.offset.dx && testCoords.x < drawParams.offset.dx + drawParams.scaledCanvasSize.x && testCoords.y >= drawParams.offset.dy && testCoords.y < drawParams.offset.dy + drawParams.scaledCanvasSize.y)
    {
      isOn = true;
    }
    return isOn;
  }



  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

