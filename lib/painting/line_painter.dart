import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class LinePainter extends IToolPainter
{
  LinePainter({required super.painterOptions});
  final LineOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.lineOptions;
  Set<CoordinateSetI> _contentPoints = {};
  Set<CoordinateSetI> _linePoints = {};
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
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
      _cursorPosNorm.x = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      _cursorPosNorm.y = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      if (_cursorPosNorm != _previousCursorPosNorm)
      {
        _contentPoints = getRoundSquareContentPoints(PencilShape.round, _options.width.value, _cursorPosNorm);
        _previousCursorPosNorm.x = _cursorPosNorm.x;
        _previousCursorPosNorm.y = _cursorPosNorm.y;

        if (_lineStarted)
        {
          if (!_dragStarted || _lineEndPos1 == _lineEndPos2) // STRAIGHT LINE
          {
            if (_options.integerAspectRatio.value)
            {
              assert(_options.angles.isNotEmpty);
              final double currentAngle = atan2(_cursorPosNorm.x - _lineStartPos.x, _cursorPosNorm.y - _lineStartPos.y);
              AngleData? closestAngle;
              double closestDist = 0.0;
              for (final AngleData aData in _options.angles)
              {
                final double currentDist = (Helper.normAngle(aData.angle) - Helper.normAngle(currentAngle)).abs();
                if (closestAngle == null || currentDist < closestDist)
                {
                  closestAngle = aData;
                  closestDist = (Helper.normAngle(currentAngle) - Helper.normAngle(closestAngle.angle)).abs();
                }
              }


              if (closestAngle != null) //should never happen
              {
               double shortestDist = double.maxFinite;
               CoordinateSetI currentPos = CoordinateSetI.from(_lineStartPos);
               final Set<CoordinateSetI> lPoints = {};
               do
               {
                 final Set<CoordinateSetI> currPoints = {};
                 if (closestAngle.x.abs() > closestAngle.y.abs())
                 {
                    for (int i = 0; i < closestAngle.x.abs(); i++)
                    {
                      if (closestAngle.x > 0)
                      {
                        currentPos.x++;
                      }
                      else
                      {
                        currentPos.x--;
                      }
                      currPoints.add(CoordinateSetI.from(currentPos));
                    }
                    if (closestAngle.y > 0)
                    {
                       currentPos.y++;
                    }
                    else if (closestAngle.y < 0)
                    {
                       currentPos.y--;
                    }
                 }
                 else
                 {
                   for (int i = 0; i < closestAngle.y.abs(); i++)
                   {
                     if (closestAngle.y > 0)
                     {
                       currentPos.y++;
                     }
                     else
                     {
                       currentPos.y--;
                     }
                     currPoints.add(CoordinateSetI.from(currentPos));
                   }
                   if (closestAngle.x > 0)
                   {
                     currentPos.x++;
                   }
                   else if (closestAngle.x < 0)
                   {
                     currentPos.x--;
                   }
                 }

                 final dist = Helper.getDistance(_cursorPosNorm, currentPos);
                 if (dist < shortestDist)
                 {
                    shortestDist = dist;
                    lPoints.addAll(currPoints);
                 }
                 else
                 {
                    break;
                 }
               } while(true);


               if (_options.width.value == 1)
               {
                 _linePoints = lPoints;
               }
               else
               {
                 final Set<CoordinateSetI> widePoints = {};
                 for (final CoordinateSetI coord in lPoints)
                 {
                   widePoints.addAll(getRoundSquareContentPoints(PencilShape.round, _options.width.value, coord));
                 }
                 _linePoints = widePoints;
               }
              }
            }
            else
            {
              final Set<CoordinateSetI> bresenhamPoints = Helper.bresenham(_lineStartPos, _cursorPosNorm).toSet();
              if (_options.width.value == 1)
              {
                _linePoints = bresenhamPoints;
              }
              else
              {
                Set<CoordinateSetI> lPoints = {};
                for (final CoordinateSetI coord in bresenhamPoints)
                {
                  lPoints.addAll(getRoundSquareContentPoints(PencilShape.round, _options.width.value, coord));
                }
                _linePoints = lPoints;
              }
            }
          }
          else // CURVE
          {
            final Set<CoordinateSetI> curvePoints = _calculateQuadraticBezierCurve(_lineStartPos, _lineEndPos2, _lineEndPos1, _options.bezierCalculationPoints);
            if (_options.width.value == 1)
            {
              _linePoints = curvePoints;
            }
            else
            {
              Set<CoordinateSetI> widePoints = {};
              for (final CoordinateSetI coord in curvePoints)
              {
                widePoints.addAll(getRoundSquareContentPoints(PencilShape.round, _options.width.value, coord));
              }
              _linePoints = widePoints;
            }
          }
        }
      }
    }

    if (drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
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
          final HashMap<CoordinateSetI, ColorReference> drawingPixels =  getPixelsToDraw(coords: _linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: shaderOptions);
          if (!appState.selectionState.selection.isEmpty())
          {
            appState.selectionState.selection.addDirectlyAll(drawingPixels);
          }
          else
          {
            drawParams.currentLayer.setDataAll(drawingPixels);
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
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(_contentPoints);
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
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawParams})
  {
    if(appState.selectedColor.value != null && drawParams.cursorPos != null && _lineStarted)
    {
      return getPixelsToDraw(coords: _linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: shaderOptions);
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

  Set<CoordinateSetI> _calculateQuadraticBezierCurve(final CoordinateSetI p0, final CoordinateSetI p1, final CoordinateSetI p2, final int numPoints) {
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
}