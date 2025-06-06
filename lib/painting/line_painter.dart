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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class LinePainter extends IToolPainter
{
  LinePainter({required super.painterOptions});
  final LineOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.lineOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  Set<CoordinateSetI> _contentPoints = <CoordinateSetI>{};
  Set<CoordinateSetI> _linePoints = <CoordinateSetI>{};
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
  int _previousSize = -1;
  bool _lineStarted = false;
  bool _dragStarted = false;
  final CoordinateSetI _lineStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lineEndPos1 = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lineEndPos2 = CoordinateSetI(x: 0, y: 0);
  bool _isDown = false;



  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.cursorPosNorm != null)
    {
      if (drawParams.cursorPosNorm! != _previousCursorPosNorm || _options.width.value != _previousSize)
      {
        _contentPoints = getRoundSquareContentPoints(shape: PencilShape.round, size: _options.width.value, position: drawParams.cursorPosNorm!);

        if (_lineStarted)
        {
          if ((_hotkeyManager.altIsPressed && !_hotkeyManager.shiftIsPressed) || drawParams.stylusButtonDown)
          {
            _lineStartPos.x -= _previousCursorPosNorm.x - drawParams.cursorPosNorm!.x;
            _lineStartPos.y -= _previousCursorPosNorm.y - drawParams.cursorPosNorm!.y;
          }

          if (!_dragStarted || _lineEndPos1 == _lineEndPos2) // STRAIGHT LINE
          {
            if (_options.integerAspectRatio.value)
            {
              _linePoints = getIntegerRatioLinePoints(startPos: _lineStartPos, endPos: drawParams.cursorPosNorm!, size: _options.width.value, angles: _options.angles, shape: PencilShape.round);
              if (_hotkeyManager.shiftIsPressed)
              {
                final Set<CoordinateSetI> otherDirPoints = <CoordinateSetI>{};
                for (final CoordinateSetI coord in _linePoints)
                {
                  otherDirPoints.add(CoordinateSetI(x: _lineStartPos.x + (_lineStartPos.x - coord.x), y: _lineStartPos.y + (_lineStartPos.y - coord.y)));
                }
                _linePoints.addAll(otherDirPoints);
              }
            }
            else
            {
              final CoordinateSetI startPos = _hotkeyManager.shiftIsPressed ? CoordinateSetI(x: _lineStartPos.x + (_lineStartPos.x - drawParams.cursorPosNorm!.x), y: _lineStartPos.y + (_lineStartPos.y - drawParams.cursorPosNorm!.y)) : _lineStartPos;
              if (_options.segmentSorting.value)
              {
                _linePoints = _smoothStraightLine(start: startPos, end: drawParams.cursorPosNorm!, size: _options.width.value, shape: PencilShape.round, sortStyle: _options.segmentSortStyle.value);
              }
              else
              {
                _linePoints = getLinePoints(startPos: startPos, endPos: drawParams.cursorPosNorm!, size: _options.width.value, shape: PencilShape.round);
              }
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
              final Set<CoordinateSetI> widePoints = <CoordinateSetI>{};
              for (final CoordinateSetI coord in curvePoints)
              {
                widePoints.addAll(getRoundSquareContentPoints(shape: PencilShape.round, size: _options.width.value, position: coord));
              }
              _linePoints = widePoints;
            }
          }
          final CoordinateColorMap cursorPixels = drawParams.currentDrawingLayer != null ?
            getPixelsToDraw(coords: _linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions, withShadingLayers: true) :
            getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentShadingLayer!, coords: _linePoints, shaderOptions: shaderOptions);

          final LayerState currentLayer = (drawParams.currentDrawingLayer != null) ? drawParams.currentDrawingLayer! : drawParams.currentShadingLayer!;
          rasterizeCursorPixels(drawingPixels: cursorPixels, currentLayer: currentLayer).then((final ContentRasterSet? rasterSet) {
            cursorRaster = rasterSet;
            hasAsyncUpdate = true;
          });
        }

        _previousCursorPosNorm.x = drawParams.cursorPosNorm!.x;
        _previousCursorPosNorm.y = drawParams.cursorPosNorm!.y;
        _previousSize = _options.width.value;

      }
    }

    if ((drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden) ||
        (drawParams.currentShadingLayer != null && drawParams.currentShadingLayer!.lockState.value != LayerLockState.locked && drawParams.currentShadingLayer!.visibilityState.value != LayerVisibilityState.hidden))
    {
      if (drawParams.primaryDown)
      {
        if (!_isDown)
        {
          if (_lineStarted && !_dragStarted)
          {
            _lineEndPos1.x = drawParams.cursorPosNorm!.x;
            _lineEndPos1.y = drawParams.cursorPosNorm!.y;
            _dragStarted = true;
          }
          _isDown = true;
        }

        if (_dragStarted)
        {
          _lineEndPos2.x = drawParams.cursorPosNorm!.x;
          _lineEndPos2.y = drawParams.cursorPosNorm!.y;
        }
      }
      else if (!drawParams.primaryDown && _isDown) //DUMPING
      {
        //FIRST (set starting point)
        if (!_lineStarted)
        {
          _lineStartPos.x = drawParams.cursorPosNorm!.x;
          _lineStartPos.y = drawParams.cursorPosNorm!.y;
          _lineStarted = true;
        }
        else
        {
          if (drawParams.currentDrawingLayer != null)
          {
            final CoordinateColorMap drawingPixels = getPixelsToDraw(coords: _linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
            if (!appState.selectionState.selection.isEmpty)
            {
              appState.selectionState.selection.addDirectlyAll(list: drawingPixels);
            }
            else
            {
              drawParams.currentDrawingLayer!.setDataAll(list: drawingPixels);
            }
          }
          else //SHADING LAYER
          {
            dumpShading(shadingLayer: drawParams.currentShadingLayer!, coordinates: _linePoints, shaderOptions: shaderOptions);
          }

          hasHistoryData = true;
          reset();
        }
        _isDown = false;
      }
    }

    if (drawParams.cursorPos == null || !_lineStarted)
    {
      cursorRaster = null;
    }
  }

  Set<CoordinateSetI> _smoothStraightLine({required final CoordinateSetI start, required final CoordinateSetI end, required final int size, required final PencilShape shape, required final SegmentSortStyle sortStyle})
  {

    final CoordinateSetI d = CoordinateSetI(x: (end.x - start.x).abs(), y: (end.y - start.y).abs());
    final CoordinateSetI s = CoordinateSetI(x: start.x < end.x ? 1 : -1, y: start.y < end.y ? 1 : -1);

    final bool isHorizontal = d.x > d.y;

    int err = d.x - d.y;
    final CoordinateSetI currentPoint = CoordinateSetI.from(other: start);

    List<int> segments = <int>[];
    int lengthCounter = 1;

    while (true)
    {
      if (currentPoint.x == end.x && currentPoint.y == end.y) break;
      final int e2 = err * 2;
      if (e2 > -d.y)
      {
        if (!isHorizontal)
        {
          segments.add(lengthCounter);
          lengthCounter = 0;
        }
        else
        {
          lengthCounter++;
        }
        err -= d.y;
        currentPoint.x += s.x;
      }
      if (e2 < d.x)
      {
        if (isHorizontal)
        {
          segments.add(lengthCounter);
          lengthCounter = 0;
        }
        else
        {
          lengthCounter++;
        }
        err += d.x;
        currentPoint.y += s.y;
      }
    }
    segments.add(lengthCounter);
    segments.removeWhere((final int element) {
      return element == 0;
    });
    segments.sort();
    if (sortStyle == SegmentSortStyle.desc || sortStyle == SegmentSortStyle.descAsc)
    {
      segments = segments.reversed.toList();
    }
    if (sortStyle == SegmentSortStyle.ascDesc || sortStyle == SegmentSortStyle.descAsc)
    {
      final List<int> pyramid = List<int>.filled(segments.length, 50);
      int left = 0;
      int right = segments.length - 1;

      for (int i = 0; i < segments.length; i++)
      {
        if (i.isEven)
        {
          pyramid[left++] = segments[i];
        }
        else
        {
          pyramid[right--] = segments[i];
        }
      }

      for (int i = 0; i < segments.length; i++)
      {
        segments[i] = pyramid[i];
      }
    }
    final Set<CoordinateSetI> points = <CoordinateSetI>{};
    final CoordinateSetI curPos = CoordinateSetI.from(other: start);
    for (final int segm in segments)
    {
      for (int i = 0; i < segm; i++)
      {
        if (isHorizontal)
        {
          if (end.x > start.x)
          {
            points.add(CoordinateSetI(x: curPos.x++, y: curPos.y));
          }
          else
          {
            points.add(CoordinateSetI(x: curPos.x--, y: curPos.y));
          }
        }
        else
        {
          if (end.y > start.y)
          {
            points.add(CoordinateSetI(x: curPos.x, y: curPos.y++));
          }
          else
          {
            points.add(CoordinateSetI(x: curPos.x, y: curPos.y--));
          }
        }
      }
      if (isHorizontal)
      {
        if (end.y > start.y)
        {
          curPos.y++;
        }
        else
        {
          curPos.y--;
        }
      }
      else
      {
        if (end.x > start.x)
        {
          curPos.x++;
        }
        else
        {
          curPos.x--;
        }
      }
    }

    if (size > 1)
    {
      final Set<CoordinateSetI> lPoints = <CoordinateSetI>{};
      for (final CoordinateSetI coord in points)
      {
        lPoints.addAll(getRoundSquareContentPoints(shape: shape, size: size, position: coord));
      }
      return lPoints;
    }
    else
    {
      return points;
    }
  }

  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: _contentPoints);
    final Path path = Path();
    if (pathPoints.isNotEmpty)
    {
      path.moveTo((pathPoints.first.x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints.first.y * drawParams.pixelSize) + drawParams.offset.dy);

      for (final CoordinateSetI point in pathPoints.skip(1))
      {
        path.lineTo((point.x * drawParams.pixelSize) + drawParams.offset.dx, (point.y * drawParams.pixelSize) + drawParams.offset.dy);
      }
      path.close();
    }

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = blackToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = whiteToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }

  Set<CoordinateSetI> _calculateQuadraticBezierCurve(
      {required final CoordinateSetI p0,
      required final CoordinateSetI p1,
      required final CoordinateSetI p2,
      required final int numPoints,})
  {
    final Set<CoordinateSetI> points = <CoordinateSetI>{};

    for (int i = 0; i <= numPoints; i++)
    {
      final double t = i / numPoints;

      final double x = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x;
      final double y = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y;

      points.add(CoordinateSetI(x: x.round(), y: y.round()));
    }

    //cleaning
    final Set<CoordinateSetI> removePoints = <CoordinateSetI>{};
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
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    if (drawParams.cursorPosNorm != null)
    {
      statusBarData.cursorPos = drawParams.cursorPosNorm;
      if (_lineStarted)
      {
        final int width = (drawParams.cursorPosNorm!.x - _lineStartPos.x).abs() + 1;
        final int height =(drawParams.cursorPosNorm!.y - _lineStartPos.y).abs() + 1;
        statusBarData.aspectRatio = statusBarData.diagonal = statusBarData.dimension = CoordinateSetI(x: width, y: height);
        statusBarData.angle = _lineStartPos;
      }
    }
  }

  @override
  void reset()
  {
    _previousCursorPosNorm.x = -1;
    _previousCursorPosNorm.y = -1;
    _lineStartPos.x = 0;
    _lineStartPos.y = 0;
    _lineEndPos1.x = 0;
    _lineEndPos2.y = 0;
    _contentPoints.clear();
    _linePoints.clear();
    _previousSize = -1;
    _lineStarted = false;
    _dragStarted = false;
    _isDown = false;
  }
}
