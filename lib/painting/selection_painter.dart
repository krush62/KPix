import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class SelectionPainter extends IToolPainter
{
  final CoordinateSetI selectionStart = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI selectionEnd = CoordinateSetI(x: 0, y: 0);
  bool hasNewSelection = false;
  final SelectOptions options = GetIt.I.get<PreferenceManager>().toolOptions.selectOptions;
  bool movementStarted = false;
  List<CoordinateSetI> polygonPoints = [];
  bool polygonDown = false;
  final CoordinateSetI _normStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _normEndPos = CoordinateSetI(x: 0, y: 0);
  Offset _lastStartPos = const Offset(0,0);
  bool _isStartOnCanvas = false;
  bool _shouldMove = false;

  SelectionPainter({required super.painterOptions});


  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (_lastStartPos.dx != drawParams.primaryPressStart.dx || _lastStartPos.dx != drawParams.primaryPressStart.dy)
    {
      _normStartPos.x = KPixPainter.getClosestPixel(value: drawParams.primaryPressStart.dx - drawParams.offset.dx, pixelSize: drawParams.pixelSize.toDouble());
      _normStartPos.y = KPixPainter.getClosestPixel(value: drawParams.primaryPressStart.dy - drawParams.offset.dy, pixelSize: drawParams.pixelSize.toDouble());
      _lastStartPos = drawParams.primaryPressStart;
    }
    if (drawParams.cursorPos != null)
    {
      _normEndPos.x = KPixPainter.getClosestPixel(value: drawParams.cursorPos!.x - drawParams.offset.dx,pixelSize: drawParams.pixelSize.toDouble()).round();
      _normEndPos.y = KPixPainter.getClosestPixel(value: drawParams.cursorPos!.y - drawParams.offset.dy,pixelSize: drawParams.pixelSize.toDouble()).round();
    }

    _isStartOnCanvas = drawParams.primaryDown && drawParams.cursorPos != null && _normStartPos.x >= 0 && _normStartPos.y >= 0 && _normStartPos.x < appState.canvasWidth && _normStartPos.y < appState.canvasHeight;
    if (_isStartOnCanvas)
    {
      _shouldMove = (drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden) && (movementStarted ||
          ((options.mode.value == SelectionMode.replace || options.mode.value == SelectionMode.add) && appState.selectionState.selection.contains(_normStartPos) && (options.shape.value != SelectShape.polygon || polygonPoints.isEmpty)));
      if (_shouldMove)
      {
        movementStarted = true;
        appState.selectionState.setOffset(CoordinateSetI(
            x: _normEndPos.x - _normStartPos.x,
            y: _normEndPos.y - _normStartPos.y));
      }
      else
      {
        if (options.shape.value == SelectShape.polygon)
        {
          polygonDown = true;
        }
        else
        {
          selectionStart.x = _normStartPos.x < _normEndPos.x
              ? _normStartPos.x
              : _normEndPos.x;
          selectionStart.y = _normStartPos.y < _normEndPos.y
              ? _normStartPos.y
              : _normEndPos.y;
          selectionEnd.x = _normStartPos.x < _normEndPos.x
              ? (_normEndPos.x)
              : (_normStartPos.x);
          selectionEnd.y = _normStartPos.y < _normEndPos.y
              ? (_normEndPos.y)
              : (_normStartPos.y);

          if (selectionStart.x < 0) {
            selectionStart.x = 0;
          }

          if (selectionStart.y < 0) {
            selectionStart.y = 0;
          }

          if (selectionEnd.x > appState.canvasWidth - 1) {
            selectionEnd.x = appState.canvasWidth - 1;
          }

          if (selectionEnd.y > appState.canvasHeight - 1) {
            selectionEnd.y = appState.canvasHeight - 1;
          }

          if (options.keepAspectRatio.value) {
            final int width = selectionEnd.x - selectionStart.x;
            final int height = selectionEnd.y - selectionStart.y;
            if (width > height) {
              if (_normStartPos.x < _normEndPos.x) {
                selectionEnd.x = selectionStart.x + height;
              } else {
                selectionStart.x = selectionEnd.x - height;
              }
            } else {
              if (_normStartPos.y < _normEndPos.y) {
                selectionEnd.y = selectionStart.y + width;
              } else {
                selectionStart.y = selectionEnd.y - width;
              }
            }
          }
          hasNewSelection = true;
        }
      }
    }
    else if (!drawParams.primaryDown)
    {
      if (movementStarted) {
        movementStarted = false;
        appState.selectionState.finishMovement();
      }
      if (polygonDown)
      {
        final CoordinateSetI point = CoordinateSetI(
            x: _normStartPos.x,
            y: _normStartPos.y);


        bool isInsideCircle = false;

        if (polygonPoints.isNotEmpty) {

          final double distance = sqrt(pow(point.x - polygonPoints[0].x, 2) + pow(point.y - polygonPoints[0].y, 2));
          if (distance <= painterOptions.selectionPolygonCircleRadius / drawParams.pixelSize)
          {
            isInsideCircle = true;
          }
        }

        if (polygonPoints.isEmpty || !isInsideCircle)
        {
          polygonPoints.add(point);
          polygonDown = false;
        }
        else
        {
          if (polygonPoints.length > 2)
          {
            hasNewSelection = true;
          }
          else
          {
            polygonDown = false;
          }
        }
      }

    }
    else //NO BUTTON PRESS AND NOT ON CANVAS
    {

    }
  }


  @override
  void drawTool({required final DrawingParameters drawParams})
  {
    if (_isStartOnCanvas && !_shouldMove && !polygonDown)
    {
      drawParams.paint.style = PaintingStyle.stroke;
      final CoordinateSetD cursorStartPos = CoordinateSetD(
          x: drawParams.offset.dx + selectionStart.x * drawParams.pixelSize,
          y: drawParams.offset.dy +
              selectionStart.y * drawParams.pixelSize);
      final CoordinateSetD cursorEndPos = CoordinateSetD(
          x: drawParams.offset.dx +
              (selectionEnd.x + 1) * drawParams.pixelSize,
          y: drawParams.offset.dy +
              (selectionEnd.y + 1) * drawParams.pixelSize);

      //RECTANGLE
      if (options.shape.value == SelectShape.rectangle) {
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = Colors.white;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
      }

      //ELLIPSE
      else if (options.shape.value == SelectShape.ellipse)
      {
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawOval(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = Colors.white;
        drawParams.canvas.drawOval(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
      }
    }
  }

  @override
  void drawCursor({
    required DrawingParameters drawParams})
  {
    if (!drawParams.primaryDown)
    {
      drawParams.paint.style = PaintingStyle.stroke;
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + _normEndPos.x * drawParams.pixelSize,
          y: drawParams.offset.dy + _normEndPos.y * drawParams.pixelSize);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = Colors.black;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize, cursorPos.y + drawParams.pixelSize), drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = Colors.white;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize, cursorPos.y + drawParams.pixelSize), drawParams.paint);

    }
  }

  @override
  void drawExtras({required DrawingParameters drawParams}) {
    if (options.shape.value == SelectShape.polygon && polygonPoints.isNotEmpty)
    {
      final CoordinateSetD? cursorPos = drawParams.cursorPos != null ?
      CoordinateSetD(
          x: drawParams.offset.dx + KPixPainter.getClosestPixel(
              value: drawParams.cursorPos!.x - drawParams.offset.dx,
              pixelSize: drawParams.pixelSize.toDouble()) * drawParams.pixelSize + (drawParams.pixelSize / 2),
          y: drawParams.offset.dy + KPixPainter.getClosestPixel(
              value: drawParams.cursorPos!.y - drawParams.offset.dy,
              pixelSize: drawParams.pixelSize.toDouble()) * drawParams.pixelSize + (drawParams.pixelSize / 2))
          : null;


      Path path = Path();
      for (int i = 0; i < polygonPoints.length; i++)
      {
        if (i == 0)
        {
          path.moveTo((polygonPoints[i].x * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dx, (polygonPoints[i].y * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dy);
        }

        if (i < polygonPoints.length - 1)
        {
          path.lineTo((polygonPoints[i + 1].x * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dx, (polygonPoints[i + 1].y * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dy);
        }
        else if (cursorPos != null)
        {
          path.lineTo(cursorPos.x, cursorPos.y);
        }
      }

      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = Colors.black;
      drawParams.canvas.drawCircle(Offset((polygonPoints[0].x * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dx, (polygonPoints[0].y * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dy), painterOptions.selectionPolygonCircleRadius, drawParams.paint);
      drawParams.canvas.drawPath(path, drawParams.paint);

      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = Colors.white;
      drawParams.canvas.drawCircle(Offset((polygonPoints[0].x * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dx, (polygonPoints[0].y * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dy), painterOptions.selectionPolygonCircleRadius, drawParams.paint);
      drawParams.canvas.drawPath(path, drawParams.paint);
    }
  }
}