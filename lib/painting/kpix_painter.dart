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

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
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
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/timeline/frame_blending_widget.dart';

class KPixPainterOptions
{
  final double cursorSize;
  final double cursorBorderWidth;
  final double selectionSolidStrokeWidth;
  final double pixelExtension;
  final double selectionPolygonCircleRadius;
  final double selectionStrokeWidthLarge;
  final double selectionStrokeWidthSmall;
  final int backupPainterPollingRateMs;

  KPixPainterOptions({
    required this.cursorSize,
    required this.cursorBorderWidth,
    required this.selectionSolidStrokeWidth,
    required this.pixelExtension,
    required this.selectionPolygonCircleRadius,
    required this.selectionStrokeWidthLarge,
    required this.selectionStrokeWidthSmall,
    required this.backupPainterPollingRateMs,
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
  final Size drawingSize;
  final CoordinateSetD? cursorPos;
  final CoordinateSetI? cursorPosNorm;
  final bool primaryDown;
  final bool secondaryDown;
  final bool stylusButtonDown;
  final Offset primaryPressStart;
  final ReferenceLayerState? currentReferenceLayer;
  final GridLayerState? currentGridLayer;
  final RasterableLayerState? currentRasterLayer;
  final double pixelRatio;
  final double? symmetryHorizontal;
  final double? symmetryVertical;
  final bool isPlaying;
  DrawingParameters({
    required this.offset,
    required this.canvas,
    required this.paint,
    required this.pixelSize,
    required this.canvasSize,
    required this.drawingSize,
    required this.cursorPos,
    required this.cursorPosNorm,
    required this.primaryDown,
    required this.stylusButtonDown,
    required this.secondaryDown,
    required this.primaryPressStart,
    required this.pixelRatio,
    required final LayerState currentLayer,
    required this.symmetryHorizontal,
    required this.symmetryVertical,
    required this.isPlaying,
}) :
    scaledCanvasSize = CoordinateSetI(x: canvasSize.x * pixelSize, y: canvasSize.y * pixelSize),
    currentRasterLayer = currentLayer is RasterableLayerState ? currentLayer : null,
    currentReferenceLayer = currentLayer.runtimeType == ReferenceLayerState ? (currentLayer as ReferenceLayerState) : null,
    currentGridLayer = currentLayer.runtimeType == GridLayerState ? (currentLayer as GridLayerState) : null;
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
  final ValueNotifier<bool> _stylusButton1Down;
  final ValueNotifier<bool> _primaryDown;
  final ValueNotifier<bool> _secondaryDown;
  final ValueNotifier<Offset> _primaryPressStart;
  final KPixPainterOptions _options = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final GuiPreferenceContent _guiOptions = GetIt.I.get<PreferenceManager>().guiPreferenceContent;
  final FrameBlendingOptions _frameBlendingOptions = GetIt.I.get<PreferenceManager>().frameBlendingOptions;
  late Color _blackSelectionAlphaColor;
  late Color _whiteSelectionAlphaColor;
  late Color _blackBorderAlphaColor;
  late Map<ToolType, IToolPainter> toolPainterMap;
  late Size latestSize = Size.zero;
  late int _latestRasterSize = 8;
  late int _latestContrast = 50;
  IToolPainter? toolPainter;
  late ui.Image _checkerboardImage;
  ui.Image? _backupImage;

  // status for reference layer movements
  bool _referenceImgMovementStarted = false;
  final CoordinateSetD _referenceImgNormStartPos = CoordinateSetD(x: 0, y: 0);
  final CoordinateSetD _referenceImgcursorPosNorm = CoordinateSetD(x: 0, y: 0);
  Offset _referenceImglastStartPos = Offset.zero;
  final CoordinateSetD _referenceImgLastReferenceOffset = CoordinateSetD(x: 0, y: 0);

  KPixPainter({
    required final AppState appState,
    required final ValueNotifier<Offset> offset,
    required final ValueNotifier<CoordinateSetD?> coords,
    required final ValueNotifier<bool> primaryDown,
    required final ValueNotifier<bool> secondaryDown,
    required final ValueNotifier<Offset> primaryPressStart,
    required final ValueNotifier<bool> isDragging,
    required final ValueNotifier<bool> stylusLongMoveStarted,
    required final ValueNotifier<bool> stylusLongMoveVertical,
    required final ValueNotifier<bool> stylusButton1Down,
    required final ValueNotifier<bool> stylusLongMoveHorizontal,})
      : _appState = appState,
        _offset = offset,
        _coords = coords,
        _isDragging = isDragging,
        _stylusLongMoveStarted = stylusLongMoveStarted,
        _stylusLongMoveVertical = stylusLongMoveVertical,
        _stylusLongMoveHorizontal = stylusLongMoveHorizontal,
        _stylusButton1Down = stylusButton1Down,
        _primaryDown = primaryDown,
        _secondaryDown = secondaryDown,
        _primaryPressStart = primaryPressStart,
        super(repaint: appState.repaintNotifier)
  {
    Timer.periodic(Duration(milliseconds: _options.backupPainterPollingRateMs), (final Timer t) {_captureTimeout();});
    _guiOptions.selectionOpacity.addListener(() {
      _setSelectionColors(percentageValue: _guiOptions.selectionOpacity.value);
    },);
    _setSelectionColors(percentageValue: _guiOptions.selectionOpacity.value);

    _guiOptions.canvasBorderOpacity.addListener(() {
      _setCanvasBorderColor(percentageValue: _guiOptions.canvasBorderOpacity.value);
    },);
    _setCanvasBorderColor(percentageValue: _guiOptions.canvasBorderOpacity.value);

    toolPainterMap = <ToolType, IToolPainter>{
      ToolType.select: SelectionPainter(painterOptions: _options),
      ToolType.erase: EraserPainter(painterOptions: _options),
      ToolType.pencil: PencilPainter(painterOptions: _options),
      ToolType.pick: ColorPickPainter(painterOptions: _options),
      ToolType.fill: FillPainter(painterOptions: _options),
      ToolType.shape: ShapePainter(painterOptions: _options),
      ToolType.font: FontPainter(painterOptions: _options),
      ToolType.spraycan: SprayCanPainter(painterOptions: _options),
      ToolType.line: LinePainter(painterOptions: _options),
      ToolType.stamp: StampPainter(painterOptions: _options),
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
  void paint(final Canvas canvas, final Size size)
  {
    if (_appState.timeline.getCurrentLayer() != null)
    {
      final IToolPainter? currentToolPainter = toolPainterMap[_appState.selectedTool];
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

      final Paint noFilterPainter = Paint()..filterQuality = FilterQuality.none..isAntiAlias = false;
      final DrawingParameters drawParams = DrawingParameters(
        pixelRatio: _appState.devicePixelRatio,
        symmetryHorizontal: _appState.symmetryState.horizontalActivated.value ? _appState.symmetryState.horizontalValue.value : null,
        symmetryVertical: _appState.symmetryState.verticalActivated.value ? _appState.symmetryState.verticalValue.value : null,
        stylusButtonDown: _stylusButton1Down.value,
        offset: _offset.value,
        canvas: canvas,
        paint: noFilterPainter,
        pixelSize: _appState.zoomFactor,
        canvasSize: _appState.canvasSize,
        drawingSize: size,
        cursorPos: _coords.value,
        cursorPosNorm: _coords.value != null ? CoordinateSetI(x: IToolPainter.getClosestPixel(value: _coords.value!.x - _offset.value.dx,pixelSize: _appState.zoomFactor.toDouble() / _appState.devicePixelRatio), y: IToolPainter.getClosestPixel(value: _coords.value!.y - _offset.value.dy,pixelSize: _appState.zoomFactor.toDouble() / _appState.devicePixelRatio)) : null,
        primaryDown: _primaryDown.value,
        secondaryDown: _secondaryDown.value,
        primaryPressStart: _primaryPressStart.value,
        currentLayer: _appState.timeline.getCurrentLayer()!,
        isPlaying: _appState.timeline.isPlaying.value,
      );

      if (drawParams.currentReferenceLayer != null && !drawParams.isPlaying)
      {
        _drawReferenceBorder(drawParams: drawParams, refLayer: drawParams.currentReferenceLayer!);
      }

      _drawCheckerboard(drawParams: drawParams);
      _drawCanvasBorder(drawParams: drawParams);
      if (drawParams.currentRasterLayer != null && !drawParams.isPlaying)
      {
        toolPainter?.calculate(drawParams: drawParams);
      }
      if (drawParams.currentReferenceLayer != null && !drawParams.isPlaying)
      {
        _handleReferenceLayer(drawParams: drawParams, refLayer: drawParams.currentReferenceLayer!);
      }
      _drawLayers(drawParams: drawParams);
      if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer.runtimeType == DrawingLayerState && !drawParams.isPlaying)
      {
        _drawSelection(drawParams: drawParams);
      }
      if (drawParams.currentRasterLayer != null && !drawParams.isPlaying)
      {
        toolPainter?.drawExtras(drawParams: drawParams);
      }

      if (!drawParams.isPlaying)
      {
        _drawCursor(drawParams: drawParams);
      }

      if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer.runtimeType == DrawingLayerState)
      {
        toolPainter?.setStatusBarData(drawParams: drawParams);
      }
      if (drawParams.symmetryHorizontal != null || drawParams.symmetryVertical != null && !drawParams.isPlaying)
      {
        _drawSymmetry(drawParams: drawParams);
      }
    }
  }

  void _drawCanvasBorder({required final DrawingParameters drawParams, final int width = 2})
  {
    final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
    final ui.Rect borderRect = ui.Rect.fromLTWH(
        drawParams.offset.dx - width,
        drawParams.offset.dy - width,
        drawParams.canvasSize.x * effPxSize + (width * 2),
        drawParams.canvasSize.y * effPxSize + (width * 2),);

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
      final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
      final ui.Image image = refLayer.image!.image;

      final ui.Rect borderRect = ui.Rect.fromLTWH(
          drawParams.offset.dx + (refLayer.offsetX * effPxSize),
          drawParams.offset.dy + (refLayer.offsetY * effPxSize),
          image.width * refLayer.zoomFactor * refLayer.aspectRatioFactorX * effPxSize,
          image.height * refLayer.zoomFactor * refLayer.aspectRatioFactorY * effPxSize,
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
    final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
    if (_referenceImglastStartPos != drawParams.primaryPressStart)
    {
      _referenceImgNormStartPos.x = (drawParams.primaryPressStart.dx - drawParams.offset.dx) / effPxSize;
      _referenceImgNormStartPos.y = (drawParams.primaryPressStart.dy - drawParams.offset.dy) / effPxSize;
      _referenceImglastStartPos = drawParams.primaryPressStart;
      _referenceImgMovementStarted = true;
    }
    if (drawParams.cursorPos != null)
    {
       _referenceImgcursorPosNorm.x = (drawParams.cursorPos!.x - drawParams.offset.dx) / effPxSize;
       _referenceImgcursorPosNorm.y = (drawParams.cursorPos!.y - drawParams.offset.dy) / effPxSize;

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
    final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
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
                      (line.startLoc.x * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,),
              drawParams.paint,);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * effPxSize) +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.startLoc.y * effPxSize),),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * effPxSize) +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.endLoc.y * effPxSize) + effPxSize,),
              drawParams.paint,);
        } else if (line.selectDir == SelectionDirection.right) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,),
              drawParams.paint,);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * effPxSize) +
                      effPxSize -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.startLoc.y * effPxSize),),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * effPxSize) +
                      effPxSize -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.endLoc.y * effPxSize) + effPxSize,),
              drawParams.paint,);
        } else if (line.selectDir == SelectionDirection.top) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,),
              drawParams.paint,);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx + (line.startLoc.x * effPxSize),
                  _offset.value.dy +
                      (line.startLoc.y * effPxSize) +
                      _options.selectionSolidStrokeWidth / 2,),
              Offset(
                  _offset.value.dx + (line.endLoc.x * effPxSize) + effPxSize,
                  _offset.value.dy +
                      (line.endLoc.y * effPxSize) +
                      _options.selectionSolidStrokeWidth / 2,),
              drawParams.paint,);
        } else if (line.selectDir == SelectionDirection.bottom) {
          drawParams.paint.color = _blackSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * effPxSize) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * effPxSize) +
                      effPxSize +
                      _options.selectionSolidStrokeWidth / 2,),
              drawParams.paint,);
          drawParams.paint.color = _whiteSelectionAlphaColor;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx + (line.startLoc.x * effPxSize),
                  _offset.value.dy +
                      (line.startLoc.y * effPxSize) +
                      effPxSize -
                      _options.selectionSolidStrokeWidth / 2,),
              Offset(
                  _offset.value.dx + (line.endLoc.x * effPxSize) + effPxSize,
                  _offset.value.dy +
                      (line.endLoc.y * effPxSize) +
                      effPxSize -
                      _options.selectionSolidStrokeWidth / 2,),
              drawParams.paint,);
        }
      }
    }
  }

  bool _isForbidden({required final DrawingParameters drawParams})
  {
    final bool onCanvas = isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos);
    final bool isHidden = drawParams.currentRasterLayer != null && drawParams.currentRasterLayer!.visibilityState.value == LayerVisibilityState.hidden;
    final bool isLocked = drawParams.currentRasterLayer != null && drawParams.currentRasterLayer!.lockState.value == LayerLockState.locked;
    final bool forbiddenDrawingTool = toolPainter.runtimeType != SelectionPainter && toolPainter.runtimeType != ColorPickPainter;
    final bool isDrawingLayer = drawParams.currentRasterLayer != null && drawParams.currentRasterLayer!.runtimeType == DrawingLayerState;
    final bool isShadingLayer = drawParams.currentRasterLayer != null && drawParams.currentRasterLayer! is ShadingLayerState;


    final bool isForbidden =
        //locked or hidden drawing layers
        (onCanvas && forbiddenDrawingTool && isDrawingLayer && (isHidden || isLocked)) ||
        //locked or hidden shading layers
        (onCanvas && isShadingLayer && (isHidden || isLocked)) ||
        //grid layers
        drawParams.currentGridLayer != null;
    return isForbidden;
  }

  void _drawCursor({required final DrawingParameters drawParams})
  {
    if (_coords.value != null)
    {

      if (!_isDragging.value && !drawParams.secondaryDown /*&& isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!)*/ && toolPainter != null && (drawParams.currentRasterLayer != null || drawParams.currentGridLayer != null))
      {
        if (_isForbidden(drawParams: drawParams))
        {
          final double circleWidth = _options.cursorSize * 2;
          final double lineX = cos(pi / 4.0) * circleWidth;
          final double lineY = sin(pi / 4.0) * circleWidth;

          drawParams.paint.color = Colors.black;
          drawParams.paint.style = PaintingStyle.stroke;
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthLarge;
          drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), circleWidth, drawParams.paint);

          drawParams.paint.strokeWidth = _options.selectionStrokeWidthLarge;
          drawParams.canvas.drawLine(ui.Offset(_coords.value!.x - lineX, _coords.value!.y - lineY), ui.Offset(_coords.value!.x + lineX, _coords.value!.y + lineY), drawParams.paint);

          drawParams.paint.color = Colors.white;
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthSmall;
          drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), circleWidth, drawParams.paint);

          drawParams.paint.strokeWidth = _options.selectionStrokeWidthSmall;
          drawParams.canvas.drawLine(ui.Offset(_coords.value!.x - lineX, _coords.value!.y - lineY), ui.Offset(_coords.value!.x + lineX, _coords.value!.y + lineY), drawParams.paint);

        }
        else
        {
          toolPainter!.drawCursorOutline(drawParams: drawParams);
        }
      }
      else
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
          final Path path1 = Path();
          path1.moveTo(_coords.value!.x + (-1 * _options.cursorSize), _coords.value!.y + (-1 * _options.cursorSize));
          path1.lineTo(_coords.value!.x + (-2 * _options.cursorSize), _coords.value!.y);
          path1.lineTo(_coords.value!.x + (-1 * _options.cursorSize), _coords.value!.y + (1 * _options.cursorSize));

          final Path path2 = Path();
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
          final Path path = Path();
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

  void _drawSymmetry({required final DrawingParameters drawParams})
  {
    const double offset = 32.0;
    const double strokeWidthWhite = 3.0;
    const double strokeWidthBlack = 1.0;
    const int strokeAlphaWhite = 96;
    const int strokeAlphaBlack = 192;

    final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
    final Paint p1 = Paint();
    p1.color = Colors.white.withAlpha(strokeAlphaWhite);
    p1.style = PaintingStyle.stroke;
    p1.strokeWidth = strokeWidthWhite;

    final Paint p2 = Paint();
    p2.color = Colors.black.withAlpha(strokeAlphaBlack);
    p2.style = PaintingStyle.stroke;
    p2.strokeWidth = strokeWidthBlack;


    //HORIZONTAL
    if (drawParams.symmetryHorizontal != null)
    {
      final double horVal = drawParams.offset.dx + (drawParams.symmetryHorizontal! * effPxSize);
      final Offset start = Offset(horVal, drawParams.offset.dy - offset);
      final Offset end = Offset(horVal, drawParams.offset.dy + (drawParams.canvasSize.y * effPxSize) + offset);

      drawParams.canvas.drawLine(start, end, p1);
      drawParams.canvas.drawLine(start, end, p2);
    }

    //VERTICAL
    if (drawParams.symmetryVertical != null)
    {
      final double vertVal = drawParams.offset.dy + (drawParams.symmetryVertical! * effPxSize);
      final Offset start = Offset(drawParams.offset.dx - offset, vertVal);
      final Offset end = Offset(drawParams.offset.dx + (drawParams.canvasSize.x * effPxSize) + offset, vertVal);

      drawParams.canvas.drawLine(start, end, p1);
      drawParams.canvas.drawLine(start, end, p2);
    }
  }


  final List<int> _previousRasterHashes = <int>[]; //TODO move me

  bool _shouldCapture()
  {
    final Frame? frame = _appState.timeline.selectedFrame;
    if (frame != null)
    {
      final Iterable<RasterableLayerState> rasterLayers = frame.layerList.getVisibleRasterLayers();
      if (rasterLayers.length != _previousRasterHashes.length)
      {
        return true;
      }
      final List<int> rasterHashes = <int>[];
      for (final RasterableLayerState drawingLayer in rasterLayers)
      {
        if (drawingLayer.isRasterizing)
        {
          return false;
        }
        if (drawingLayer.rasterImage.value == null)
        {
          return false;
        }
        else
        {
          rasterHashes.add(drawingLayer.rasterImage.value!.hashCode);
        }
      }

      for (final int hash in rasterHashes)
      {
        if (!_previousRasterHashes.contains(hash))
        {
          return true;
        }
      }
    }

    return false;
  }



  void _captureTimeout()
  {
    if (_shouldCapture())
    {
      getImageFromLayers(canvasSize: _appState.canvasSize, layerCollection: _appState.timeline.selectedFrame!.layerList, selection: _appState.selectionState.selection, frame: _appState.timeline.selectedFrame).then((final ui.Image img) {
        _backupImage = img;
        final Frame? frame = _appState.timeline.selectedFrame;
        if (frame != null)
        {
          final Iterable<RasterableLayerState> rasterLayers = frame.layerList.getVisibleRasterLayers();
          _previousRasterHashes.clear();
          for (final RasterableLayerState rasterLayer in rasterLayers)
          {
            if (rasterLayer.rasterImage.value != null)
            {
              _previousRasterHashes.add(rasterLayer.rasterImage.value.hashCode);
            }
          }
        }
      });
    }
  }

  void _drawRasterImage({required final DrawingParameters drawParams, required final double pxlSzDbl, required final ui.Image displayImage, Paint? painter})
  {
    painter ??= drawParams.paint;

    final CoordinateSetD effCanvasSize = CoordinateSetD(
        x: drawParams.scaledCanvasSize.x / _appState.devicePixelRatio,
        y: drawParams.scaledCanvasSize.y / _appState.devicePixelRatio,);

    final double rightDifference = (drawParams.offset.dx + effCanvasSize.x) - latestSize.width;
    final double bottomDifference = (drawParams.offset.dy + effCanvasSize.y) - latestSize.height;
    final double leftDifference = -drawParams.offset.dx;
    final double topDifference = -drawParams.offset.dy;

    final double rightExceed = rightDifference > 0 ? rightDifference : 0;
    final double bottomExceed = bottomDifference > 0 ? bottomDifference : 0;
    final double leftExceed = leftDifference > 0 ? leftDifference : 0;
    final double topExceed = topDifference > 0 ? topDifference : 0;

    final double horizontalExceedFactor = 1.0 - (leftExceed + rightExceed) / effCanvasSize.x;
    final double verticalExceedFactor = 1.0 - (topExceed + bottomExceed) / effCanvasSize.y;

    final double destX = drawParams.offset.dx < 0 ? 0.0 : drawParams.offset.dx;
    final double destY = drawParams.offset.dy < 0 ? 0.0 : drawParams.offset.dy;

    final ui.Rect destRect = ui.Rect.fromLTWH(
      destX,
      destY,
      effCanvasSize.x - leftExceed - rightExceed,
      effCanvasSize.y - topExceed - bottomExceed,
    );

    final ui.Rect srcRect = ui.Rect.fromLTWH(
      leftExceed > 0 ? leftExceed / pxlSzDbl * _appState.devicePixelRatio : 0,
      topExceed > 0 ? topExceed / pxlSzDbl * _appState.devicePixelRatio : 0,
      drawParams.canvasSize.x.toDouble() * horizontalExceedFactor,
      drawParams.canvasSize.y.toDouble() * verticalExceedFactor,
    );

    drawParams.canvas.drawImageRect(
      displayImage,
      srcRect,
      destRect,
      painter,
    );
  }

  void _drawLayers({required final DrawingParameters drawParams})
  {
    final Frame? frame = _appState.timeline.selectedFrame;
    final double pxlSzDbl = drawParams.pixelSize.toDouble();

    if (frame != null)
    {
      if (drawParams.isPlaying && frame.layerList.rasterImage != null)
      {
        _drawRasterImage(drawParams: drawParams, pxlSzDbl: pxlSzDbl, displayImage: frame.layerList.rasterImage!);
      }
      else
      {
        final List<LayerState> visibleLayers = frame.layerList.getVisibleLayers().toList();
        final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
        final CoordinateSetD effCanvasSize = CoordinateSetD(
          x: drawParams.scaledCanvasSize.x / _appState.devicePixelRatio,
          y: drawParams.scaledCanvasSize.y / _appState.devicePixelRatio,);
        final bool hasRasterizingLayers = visibleLayers.whereType<RasterableLayerState>().any((final RasterableLayerState rasterLayer) => rasterLayer.isRasterizing);
        if (!hasRasterizingLayers || _backupImage == null)
        {
          for (int i = visibleLayers.length - 1; i >= 0; i--)
          {
            final LayerState vLayer = visibleLayers[i];
            if (vLayer is RasterableLayerState)
            {
              final ui.Image? mapImage = vLayer.rasterImageMap.value[frame]?.raster;
              final ui.Image? rasterImage = vLayer.rasterImage.value;
              final ui.Image? previousRaster = vLayer.previousRaster;
              final ui.Image? displayImage = vLayer.isRasterizing ? previousRaster : (mapImage ?? rasterImage);

              if (displayImage != null)
              {
                _drawRasterImage(drawParams: drawParams, pxlSzDbl: pxlSzDbl, displayImage: displayImage);
              }
            }
            else if (visibleLayers[i].runtimeType == ReferenceLayerState)
            {
              final ReferenceLayerState refLayer = visibleLayers[i] as ReferenceLayerState;
              if (refLayer.image != null)
              {

                final ui.Image image = refLayer.image!.image;

                final ui.Rect srcRect = ui.Rect.fromLTWH(
                  -refLayer.offsetX / refLayer.zoomFactor / refLayer.aspectRatioFactorX,
                  -refLayer.offsetY / refLayer.zoomFactor / refLayer.aspectRatioFactorY,
                  drawParams.canvasSize.x.toDouble() / refLayer.zoomFactor / refLayer.aspectRatioFactorX,
                  drawParams.canvasSize.y.toDouble() / refLayer.zoomFactor / refLayer.aspectRatioFactorY,
                );

                final ui.Rect targetRect = ui.Rect.fromLTWH(
                  drawParams.offset.dx,
                  drawParams.offset.dy,
                  effCanvasSize.x,
                  effCanvasSize.y,
                );

                final Paint paint = Paint()..color = Color.fromARGB((refLayer.opacity.toDouble() * 2.55).round(), 255, 255, 255);
                drawParams.canvas.drawImageRect(image, srcRect, targetRect, paint);
              }
            }
            else if (visibleLayers[i].runtimeType == GridLayerState)
            {
              final GridLayerState gridLayer = visibleLayers[i] as GridLayerState;
              if (gridLayer.raster != null)
              {
                _drawRasterImage(drawParams: drawParams, pxlSzDbl: pxlSzDbl, displayImage: gridLayer.raster!);
              }
            }
          }

          if (!drawParams.isPlaying)
          {
            final ContentRasterSet? cursorRasterSet = toolPainter?.cursorRaster;
            if (cursorRasterSet != null)
            {
              paintImage(
                canvas: drawParams.canvas,
                rect: ui.Rect.fromLTWH(drawParams.offset.dx + (cursorRasterSet.offset.x * effPxSize) , drawParams.offset.dy + (cursorRasterSet.offset.y * effPxSize),
                  cursorRasterSet.size.x * effPxSize,
                  cursorRasterSet.size.y * effPxSize,),
                image: cursorRasterSet.image,
                scale: 1.0 / pxlSzDbl * _appState.devicePixelRatio,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
                filterQuality: FilterQuality.none,);
            }

            final ContentRasterSet? contentRasterSet = toolPainter?.contentRaster;
            if (contentRasterSet != null)
            {
              paintImage(
                canvas: drawParams.canvas,
                rect: ui.Rect.fromLTWH(drawParams.offset.dx + (contentRasterSet.offset.x * effPxSize) , drawParams.offset.dy + (contentRasterSet.offset.y * effPxSize),
                  contentRasterSet.size.x * drawParams.pixelSize * _appState.devicePixelRatio,
                  contentRasterSet.size.y * drawParams.pixelSize * _appState.devicePixelRatio,),
                image: contentRasterSet.image,
                scale: 1.0 / pxlSzDbl * _appState.devicePixelRatio,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
                filterQuality: FilterQuality.none,);
            }
          }
        }
        else
        {
          _drawRasterImage(drawParams: drawParams, pxlSzDbl: pxlSzDbl, displayImage: _backupImage!);
        }

        if (_frameBlendingOptions.enabled.value && _frameBlendingOptions.framesAfter.value + _frameBlendingOptions.framesBefore.value > 0 && _appState.timeline.frames.value.length > 1)
        {
          _drawFrameBlending(drawParams: drawParams, pxlSzDbl: pxlSzDbl);
        }
      }
    }
  }

  void _drawFrameBlending({required final DrawingParameters drawParams, required final double pxlSzDbl})
  {
    final int currentFrameIndex = _appState.timeline.selectedFrameIndex;
    final List<Frame> frameList = _appState.timeline.frames.value;
    final List<Frame> framesToBlend = <Frame>[];
    final Color beforeTintColor = _frameBlendingOptions.tinting.value ? Colors.red : Colors.white;
    final Color afterTintColor = _frameBlendingOptions.tinting.value ? Colors.green : Colors.white;

    void processFrames(
        final int frameCount,
        final Color tintColor,
        final bool wrapAround,
        final bool directionAfter,
        )
    {
      for (int i = 0; i < frameCount; i++)
      {
        final int frameIndexOffset = directionAfter ? i + 1 : -(i + 1);
        final int targetFrameIndex = currentFrameIndex + frameIndexOffset;
        Frame? frameToProcess;

        if (directionAfter)
        {
          if (targetFrameIndex < frameList.length)
          {
            frameToProcess = frameList[targetFrameIndex];
          }
          else if (wrapAround)
          {
            frameToProcess = frameList[targetFrameIndex % frameList.length];
          }
        }
        else
        {
          if (targetFrameIndex >= 0)
          {
            frameToProcess = frameList[targetFrameIndex];
          }
          else if (wrapAround)
          {
            final int positiveIndex = (frameList.length + (targetFrameIndex % frameList.length)) % frameList.length;
            frameToProcess = frameList[positiveIndex];
          }
        }

        if (frameToProcess == null || frameToProcess == _appState.timeline.selectedFrame || framesToBlend.contains(frameToProcess))
        {
          break;
        }
        else
        {
          double opacity = _frameBlendingOptions.opacity.value;
          if (_frameBlendingOptions.gradualOpacity.value && i > 0)
          {
            final double step = _frameBlendingOptions.opacity.value / frameCount;
            opacity = _frameBlendingOptions.opacity.value - (i * step);
          }
          final int alpha = (opacity * 255).round().clamp(0, 255);
          final Paint paint = Paint()
            ..colorFilter = ColorFilter.mode(
              tintColor.withAlpha(alpha),
              BlendMode.modulate,
            );

          ui.Image? img;
          if (_frameBlendingOptions.activeLayerOnly.value)
          {
            final LayerState? activeLayer = frameToProcess.layerList.getSelectedLayer();
            if (activeLayer != null && activeLayer is RasterableLayerState)
            {
              img = activeLayer.rasterImage.value;
            }
          }
          else
          {
            img = frameToProcess.layerList.rasterImage;
          }

          if (img != null)
          {
            _drawRasterImage(drawParams: drawParams, pxlSzDbl: pxlSzDbl, displayImage: img, painter: paint);
          }
          framesToBlend.add(frameToProcess);
        }
      }
    }

    //AFTER FRAMES
    processFrames(
      _frameBlendingOptions.framesAfter.value,
      afterTintColor,
      _frameBlendingOptions.wrapAroundAfter.value,
      true,
    );

    //BEFORE FRAMES
    processFrames(
      _frameBlendingOptions.framesBefore.value,
      beforeTintColor,
      _frameBlendingOptions.wrapAroundBefore.value,
      false,
    );
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
    final double effPxSize = drawParams.pixelSize.toDouble() / _appState.devicePixelRatio;
    final CoordinateSetD effCanvasSize = CoordinateSetD(
      x: drawParams.scaledCanvasSize.x / _appState.devicePixelRatio,
      y: drawParams.scaledCanvasSize.y / _appState.devicePixelRatio,);

    paintImage(
        canvas: drawParams.canvas,
        rect: ui.Rect.fromLTWH(drawParams.offset.dx, drawParams.offset.dy, effCanvasSize.x, effCanvasSize.y),
        image: _checkerboardImage,
        scale: 1.0 / effPxSize,
        fit: BoxFit.none,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.none,);
  }


  static bool isOnCanvas({required final DrawingParameters drawParams, required final CoordinateSetD? testCoords})
  {
    if (testCoords == null)
    {
      return false;
    }
    else
    {
      final CoordinateSetD effCanvasSize = CoordinateSetD(
        x: drawParams.scaledCanvasSize.x / drawParams.pixelRatio,
        y: drawParams.scaledCanvasSize.y / drawParams.pixelRatio,);

      bool isOn = false;
      if (testCoords.x >= drawParams.offset.dx && testCoords.x < drawParams.offset.dx + effCanvasSize.x && testCoords.y >= drawParams.offset.dy && testCoords.y < drawParams.offset.dy + effCanvasSize.y)
      {
        isOn = true;
      }
      return isOn;
    }
  }



  @override
  bool shouldRepaint(final CustomPainter oldDelegate) => false;
}
