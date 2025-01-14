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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helper.dart';

class SelectionPainter extends IToolPainter
{
  final CoordinateSetI selectionStart = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI selectionEnd = CoordinateSetI(x: 0, y: 0);
  bool hasNewSelection = false;
  final SelectOptions options = GetIt.I.get<PreferenceManager>().toolOptions.selectOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  bool movementStarted = false;
  List<CoordinateSetI> polygonPoints = <CoordinateSetI>[];
  bool polygonDown = false;
  final CoordinateSetI _normStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  Offset _lastStartPos = Offset.zero;
  bool _isStartOnCanvas = false;
  bool _shouldMove = false;

  SelectionPainter({required super.painterOptions});


  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.currentDrawingLayer != null)
    {
      if (_lastStartPos != drawParams.primaryPressStart)
      {
        _normStartPos.x = getClosestPixel(value: drawParams.primaryPressStart.dx - drawParams.offset.dx, pixelSize: drawParams.pixelSize.toDouble());
        _normStartPos.y = getClosestPixel(value: drawParams.primaryPressStart.dy - drawParams.offset.dy, pixelSize: drawParams.pixelSize.toDouble());
        _lastStartPos = drawParams.primaryPressStart;
      }
      if (drawParams.cursorPos != null)
      {
        _cursorPosNorm.x = getClosestPixel(value: drawParams.cursorPos!.x - drawParams.offset.dx,pixelSize: drawParams.pixelSize.toDouble());
        _cursorPosNorm.y = getClosestPixel(value: drawParams.cursorPos!.y - drawParams.offset.dy,pixelSize: drawParams.pixelSize.toDouble());
      }

      _isStartOnCanvas = drawParams.primaryDown && drawParams.cursorPos != null;
      if (_isStartOnCanvas)
      {
        _shouldMove = (drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden) &&
            (movementStarted || ((options.mode.value == SelectionMode.replace || options.mode.value == SelectionMode.add) && appState.selectionState.selection.contains(coord: _normStartPos) && (options.shape.value != SelectShape.polygon || polygonPoints.isEmpty)));
        if (_shouldMove)
        {
          movementStarted = true;
          appState.selectionState.setOffset(
            offset: CoordinateSetI(
              x: _cursorPosNorm.x - _normStartPos.x,
              y: _cursorPosNorm.y - _normStartPos.y,
            ),
            withContent: !_hotkeyManager.controlIsPressed
          );
        }
        else
        {
          if (options.shape.value == SelectShape.polygon)
          {
            polygonDown = true;
          }
          else if (options.shape.value == SelectShape.wand)
          {
            selectionEnd.x = _cursorPosNorm.x;
            selectionEnd.y = _cursorPosNorm.y;
            hasNewSelection = true;
          }
          else
          {
            selectionStart.x = min(_normStartPos.x, _cursorPosNorm.x);
            selectionStart.y = min(_normStartPos.y, _cursorPosNorm.y);
            selectionEnd.x = max(_normStartPos.x, _cursorPosNorm.x);
            selectionEnd.y = max(_normStartPos.y, _cursorPosNorm.y);


            if (options.keepAspectRatio.value)
            {
              final int width = selectionEnd.x - selectionStart.x;
              final int height = selectionEnd.y - selectionStart.y;
              if (width > height)
              {
                if (_normStartPos.x < _cursorPosNorm.x)
                {
                  selectionEnd.x = selectionStart.x + height;
                }
                else
                {
                  selectionStart.x = selectionEnd.x - height;
                }
              }
              else
              {
                if (_normStartPos.y < _cursorPosNorm.y)
                {
                  selectionEnd.y = selectionStart.y + width;
                }
                else
                {
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
        if (movementStarted)
        {
          movementStarted = false;
          appState.selectionState.finishMovement();
        }
        if (polygonDown)
        {
          final CoordinateSetI point = CoordinateSetI(x: _normStartPos.x, y: _normStartPos.y);
          bool isInsideCircle = false;
          if (polygonPoints.isNotEmpty)
          {
            if (getDistance(a: point, b: polygonPoints[0]) <= painterOptions.selectionPolygonCircleRadius / drawParams.pixelSize)
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
  }

  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    assert(drawParams.cursorPos != null);

    if (_isStartOnCanvas && !_shouldMove && !polygonDown && (options.shape.value == SelectShape.rectangle || options.shape.value == SelectShape.ellipse))
    {
      drawParams.paint.style = PaintingStyle.stroke;
      final CoordinateSetD cursorStartPos = CoordinateSetD(
          x: drawParams.offset.dx + selectionStart.x * drawParams.pixelSize,
          y: drawParams.offset.dy +
              selectionStart.y * drawParams.pixelSize,);
      final CoordinateSetD cursorEndPos = CoordinateSetD(
          x: drawParams.offset.dx +
              (selectionEnd.x + 1) * drawParams.pixelSize,
          y: drawParams.offset.dy +
              (selectionEnd.y + 1) * drawParams.pixelSize,);

      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;

      //RECTANGLE
      if (options.shape.value == SelectShape.rectangle)
      {
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = whiteToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
      }

      //ELLIPSE
      else if (options.shape.value == SelectShape.ellipse)
      {
        drawParams.canvas.drawOval(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = whiteToolAlphaColor;
        drawParams.canvas.drawOval(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
      }
    }

    if (!drawParams.primaryDown && options.shape.value == SelectShape.rectangle || options.shape.value == SelectShape.ellipse)
    {
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + _cursorPosNorm.x * drawParams.pixelSize,
          y: drawParams.offset.dy + _cursorPosNorm.y * drawParams.pixelSize,);
      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize, cursorPos.y + drawParams.pixelSize), drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize, cursorPos.y + drawParams.pixelSize), drawParams.paint);
    }
    else if (options.shape.value == SelectShape.polygon)
    {
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + (_cursorPosNorm.x + 0.5) * drawParams.pixelSize,
          y: drawParams.offset.dy + (_cursorPosNorm.y + 0.5) * drawParams.pixelSize,);

      final Path rhombusPath = Path();
      rhombusPath.moveTo(cursorPos.x - (1 * painterOptions.cursorSize), cursorPos.y);
      rhombusPath.lineTo(cursorPos.x, cursorPos.y - (1 * painterOptions.cursorSize));
      rhombusPath.lineTo(cursorPos.x + (1 * painterOptions.cursorSize), cursorPos.y);
      rhombusPath.lineTo(cursorPos.x, cursorPos.y + (1 * painterOptions.cursorSize));
      rhombusPath.lineTo(cursorPos.x - (1 * painterOptions.cursorSize), cursorPos.y);

      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawPath(rhombusPath, drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawPath(rhombusPath, drawParams.paint);
    }
    else if (options.shape.value == SelectShape.wand)
    {
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + (_cursorPosNorm.x + 0.5) * drawParams.pixelSize,
          y: drawParams.offset.dy + (_cursorPosNorm.y + 0.5) * drawParams.pixelSize,);
      final Path outlinePath = Path();
      outlinePath.moveTo(cursorPos.x + (1 * painterOptions.cursorSize), cursorPos.y);
      outlinePath.lineTo(cursorPos.x + (5 * painterOptions.cursorSize), cursorPos.y + (4 * painterOptions.cursorSize));
      outlinePath.lineTo(cursorPos.x + (4 * painterOptions.cursorSize), cursorPos.y + (5 * painterOptions.cursorSize));
      outlinePath.lineTo(cursorPos.x, cursorPos.y + (1 * painterOptions.cursorSize));
      outlinePath.lineTo(cursorPos.x + (1 * painterOptions.cursorSize), cursorPos.y);

      final Path fillPath = Path();
      fillPath.moveTo(cursorPos.x + (2 * painterOptions.cursorSize), cursorPos.y + (1 * painterOptions.cursorSize));
      fillPath.lineTo(cursorPos.x + (5 * painterOptions.cursorSize), cursorPos.y + (4 * painterOptions.cursorSize));
      fillPath.lineTo(cursorPos.x + (4 * painterOptions.cursorSize), cursorPos.y + (5 * painterOptions.cursorSize));
      fillPath.lineTo(cursorPos.x + (1 * painterOptions.cursorSize), cursorPos.y + (2 * painterOptions.cursorSize));


      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawPath(fillPath, drawParams.paint);

      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawPath(outlinePath, drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawPath(outlinePath, drawParams.paint);
    }
  }

  @override
  void drawExtras({required final DrawingParameters drawParams}) {
    if (options.shape.value == SelectShape.polygon && polygonPoints.isNotEmpty)
    {
      final CoordinateSetD? cursorPos = drawParams.cursorPos != null ?
      CoordinateSetD(
          x: drawParams.offset.dx + getClosestPixel(
              value: drawParams.cursorPos!.x - drawParams.offset.dx,
              pixelSize: drawParams.pixelSize.toDouble(),) * drawParams.pixelSize + (drawParams.pixelSize / 2),
          y: drawParams.offset.dy + getClosestPixel(
              value: drawParams.cursorPos!.y - drawParams.offset.dy,
              pixelSize: drawParams.pixelSize.toDouble(),) * drawParams.pixelSize + (drawParams.pixelSize / 2),)
          : null;


      final Path path = Path();
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
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawCircle(Offset((polygonPoints[0].x * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dx, (polygonPoints[0].y * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dy), painterOptions.selectionPolygonCircleRadius, drawParams.paint);
      drawParams.canvas.drawPath(path, drawParams.paint);

      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawCircle(Offset((polygonPoints[0].x * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dx, (polygonPoints[0].y * drawParams.pixelSize + (drawParams.pixelSize / 2)) + drawParams.offset.dy), painterOptions.selectionPolygonCircleRadius, drawParams.paint);
      drawParams.canvas.drawPath(path, drawParams.paint);
    }
  }

  @override
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    if (drawParams.cursorPos != null)
    {
      statusBarData.cursorPos = _cursorPosNorm;
      if ((options.shape.value == SelectShape.rectangle || options.shape.value == SelectShape.ellipse) && drawParams.primaryDown)
      {
        final int width = (selectionStart.x - selectionEnd.x).abs() + 1;
        final int height = (selectionStart.y - selectionEnd.y).abs() + 1;
        statusBarData.aspectRatio = statusBarData.diagonal = statusBarData.dimension = CoordinateSetI(x: width, y: height);
      }
    }
  }

  @override
  void reset()
  {
    hasNewSelection = false;
    movementStarted = false;
    polygonPoints.clear();
    polygonDown = false;
    _isStartOnCanvas = false;
    _shouldMove = false;
  }
}
