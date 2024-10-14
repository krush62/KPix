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

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/main/layer_widget.dart';

class LinePainter extends IToolPainter
{
  LinePainter({required super.painterOptions});
  final LineOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.lineOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  Set<CoordinateSetI> _contentPoints = {};
  Set<CoordinateSetI> _linePoints = {};
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
  int _previousSize = -1;
  bool _lineStarted = false;
  bool _dragStarted = false;
  final CoordinateSetI _lineStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lineEndPos1 = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lineEndPos2 = CoordinateSetI(x: 0, y: 0);
  bool _isDown = false;



  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null) {
      _cursorPosNorm.x = getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      _cursorPosNorm.y = getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      if (_cursorPosNorm != _previousCursorPosNorm || _options.width.value != _previousSize)
      {
        _contentPoints = getRoundSquareContentPoints(shape: PencilShape.round, size: _options.width.value, position: _cursorPosNorm);
        _previousCursorPosNorm.x = _cursorPosNorm.x;
        _previousCursorPosNorm.y = _cursorPosNorm.y;
        _previousSize = _options.width.value;

        if (_lineStarted)
        {
          if (!_dragStarted || _lineEndPos1 == _lineEndPos2) // STRAIGHT LINE
          {
            if (_options.integerAspectRatio.value)
            {
              _linePoints = getIntegerRatioLinePoints(startPos: _lineStartPos, endPos: _cursorPosNorm, size: _options.width.value, angles: _options.angles, shape: PencilShape.round);
              if (_hotkeyManager.shiftIsPressed)
              {
                final Set<CoordinateSetI> otherDirPoints = {};
                for (final CoordinateSetI coord in _linePoints)
                {
                  otherDirPoints.add(CoordinateSetI(x: _lineStartPos.x + (_lineStartPos.x - coord.x), y: _lineStartPos.y + (_lineStartPos.y - coord.y)));
                }
                _linePoints.addAll(otherDirPoints);
              }
            }
            else
            {
              final CoordinateSetI startPos = _hotkeyManager.shiftIsPressed ? CoordinateSetI(x: _lineStartPos.x + (_lineStartPos.x - _cursorPosNorm.x), y: _lineStartPos.y + (_lineStartPos.y - _cursorPosNorm.y)) : _lineStartPos;
              _linePoints = getLinePoints(startPos: startPos, endPos: _cursorPosNorm, size: _options.width.value, shape: PencilShape.round);

            }
          }
          else // CURVE
          {
            final Set<CoordinateSetI> curvePoints = _calculateQuadraticBezierCurve(p0: _lineStartPos, p1: _lineEndPos2, p2: _lineEndPos1, numPoints: _options.bezierCalculationPoints);
            if (_options.width.value == 1)
            {
              _linePoints = curvePoints;
            }
            else
            {
              Set<CoordinateSetI> widePoints = {};
              for (final CoordinateSetI coord in curvePoints)
              {
                widePoints.addAll(getRoundSquareContentPoints(shape: PencilShape.round, size: _options.width.value, position: coord));
              }
              _linePoints = widePoints;
            }
          }
        }
      }
    }

    if (drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden)
    {
      if (drawParams.primaryDown)
      {
        if (!_isDown)
        {
          if (_lineStarted && !_dragStarted)
          {
            _lineEndPos1.x = _cursorPosNorm.x;
            _lineEndPos1.y = _cursorPosNorm.y;
            _dragStarted = true;
          }
          _isDown = true;
        }

        if (_dragStarted)
        {
          _lineEndPos2.x = _cursorPosNorm.x;
          _lineEndPos2.y = _cursorPosNorm.y;
        }
      }
      else if (!drawParams.primaryDown && _isDown)
      {
        //FIRST (set starting point)
        if (!_lineStarted)
        {
          _lineStartPos.x = _cursorPosNorm.x;
          _lineStartPos.y = _cursorPosNorm.y;
          _lineStarted = true;
        }
        else
        {
          final CoordinateColorMap drawingPixels = getPixelsToDraw(coords: _linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
          if (!appState.selectionState.selection.isEmpty())
          {
            appState.selectionState.selection.addDirectlyAll(list: drawingPixels);
          }
          else
          {
            drawParams.currentDrawingLayer!.setDataAll(list: drawingPixels);
          }
          hasHistoryData = true;
          _lineStarted = false;
          _dragStarted = false;
          _linePoints.clear();
        }
        _isDown = false;
      }
    }
  }

  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    //Surrounding
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: _contentPoints);
    Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[i].y * drawParams.pixelSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[i + 1].y * drawParams.pixelSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[0].y * drawParams.pixelSize) + drawParams.offset.dy);
      }
    }

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }

  @override
  CoordinateColorMap getCursorContent({required DrawingParameters drawParams})
  {
    if(drawParams.currentDrawingLayer != null && appState.selectedColor != null && drawParams.cursorPos != null && _lineStarted)
    {
      return getPixelsToDraw(coords: _linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
    }
    else
    {
      return super.getCursorContent(drawParams: drawParams);
    }
  }

  @override
  void drawExtras({required DrawingParameters drawParams})
  {
    /*if (_lineStarted && drawParams.cursorPos != null)
    {

      Path path = Path();
      path.moveTo(
          drawParams.offset.dx + ((_lineStartPos.x + 0.5) * drawParams.pixelSize),
          drawParams.offset.dy + ((_lineStartPos.y + 0.5) * drawParams.pixelSize));
      final CoordinateSetD targetPoint = CoordinateSetD(x: drawParams.offset.dx + ((_cursorPosNorm.x + 0.5) * drawParams.pixelSize), y: drawParams.offset.dy + ((_cursorPosNorm.y + 0.5) * drawParams.pixelSize));

      if (!_dragStarted)
      {
        path.lineTo(targetPoint.x, targetPoint.y);
      }
      else
      {
        final CoordinateSetD controlPoint = CoordinateSetD(x: drawParams.offset.dx + ((_lineEndPos1.x + 0.5) * drawParams.pixelSize), y: drawParams.offset.dy + ((_lineEndPos1.y + 0.5) * drawParams.pixelSize));
        path.quadraticBezierTo(targetPoint.x, targetPoint.y, controlPoint.x, controlPoint.y);
      }

      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = Colors.black;
      drawParams.canvas.drawPath(path, drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = Colors.white;
      drawParams.canvas.drawPath(path, drawParams.paint);

    }*/
  }

  Set<CoordinateSetI> _calculateQuadraticBezierCurve(
      {required final CoordinateSetI p0,
      required final CoordinateSetI p1,
      required final CoordinateSetI p2,
      required final int numPoints})
  {
    final Set<CoordinateSetI> points = {};

    for (int i = 0; i <= numPoints; i++)
    {
      final double t = i / numPoints;

      final double x = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x;
      final double y = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y;

      points.add(CoordinateSetI(x: x.round(), y: y.round()));
    }

    //cleaning
    final Set<CoordinateSetI> removePoints = {};
    for (final CoordinateSetI coord in points)
    {
      final bool hasRight = points.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)) && !removePoints.contains(CoordinateSetI(x: coord.x + 1, y: coord.y));
      final bool hasLeft = points.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)) && !removePoints.contains(CoordinateSetI(x: coord.x - 1, y: coord.y));
      final bool hasBottom = points.contains(CoordinateSetI(x: coord.x, y: coord.y + 1)) && !removePoints.contains(CoordinateSetI(x: coord.x, y: coord.y + 1));
      final bool hasTop = points.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)) && !removePoints.contains(CoordinateSetI(x: coord.x, y: coord.y - 1));

      if ((hasRight && hasTop) ||
        (hasRight && hasBottom) ||
        (hasLeft && hasTop) ||
        (hasLeft && hasBottom))
      {
        removePoints.add(coord);
      }
    }
    points.removeAll(removePoints);

    return points;
  }

  @override
  void setStatusBarData({required DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    if (drawParams.cursorPos != null)
    {
      statusBarData.cursorPos = _cursorPosNorm;
      if (_lineStarted)
      {
        final int width = (_cursorPosNorm.x - _lineStartPos.x).abs() + 1;
        final int height =(_cursorPosNorm.y - _lineStartPos.y).abs() + 1;
        statusBarData.aspectRatio = statusBarData.diagonal = statusBarData.dimension = CoordinateSetI(x: width, y: height);
        statusBarData.angle = _lineStartPos;
      }
    }
  }

  @override
  void reset()
  {
    _contentPoints.clear();
    _linePoints.clear();
    _previousSize = -1;
    _lineStarted = false;
    _dragStarted = false;
    _isDown = false;
  }
}