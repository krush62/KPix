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
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/util/typedefs.dart';

class ShapePainter extends IToolPainter
{
  final ShapeOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.shapeOptions;
  final BehaviorPreferenceContent _behaviorPreferenceContent = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final CoordinateSetI _selectionStart = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _selectionEnd = CoordinateSetI(x: 0, y: 0);
  Offset _lastStartPos = const Offset(0,0);
  final CoordinateSetI _normStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lastNormStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lastNormEndPos = CoordinateSetI(x: 0, y: 0);
  bool _isStarted = false;
  bool _waitingForRasterization = false;
  CoordinateColorMap _drawingPixels = HashMap();

  ShapePainter({required super.painterOptions});


  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.currentDrawingLayer != null)
    {
      bool selectionChanged = false;
      if (_lastStartPos.dx != drawParams.primaryPressStart.dx || _lastStartPos.dx != drawParams.primaryPressStart.dy)
      {
        _normStartPos.x = getClosestPixel(value: drawParams.primaryPressStart.dx - drawParams.offset.dx, pixelSize: drawParams.pixelSize.toDouble());
        _normStartPos.y = getClosestPixel(value: drawParams.primaryPressStart.dy - drawParams.offset.dy, pixelSize: drawParams.pixelSize.toDouble());
        _lastStartPos = drawParams.primaryPressStart;
      }
      if (drawParams.cursorPos != null)
      {
        _cursorPosNorm.x = getClosestPixel(value: drawParams.cursorPos!.x - drawParams.offset.dx,pixelSize: drawParams.pixelSize.toDouble()).round();
        _cursorPosNorm.y = getClosestPixel(value: drawParams.cursorPos!.y - drawParams.offset.dy,pixelSize: drawParams.pixelSize.toDouble()).round();
      }

      if (_normStartPos != _lastNormStartPos)
      {
        _lastNormStartPos.x = _normStartPos.x;
        _lastNormStartPos.y = _normStartPos.y;
        selectionChanged = true;
      }
      if (_cursorPosNorm != _lastNormEndPos)
      {
        _lastNormEndPos.x = _cursorPosNorm.x;
        _lastNormEndPos.y = _cursorPosNorm.y;
        selectionChanged = true;
      }

      if (!_waitingForRasterization && drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden)
      {
        _isStarted = drawParams.primaryDown && drawParams.cursorPos != null;
        if (_isStarted)
        {
          final CoordinateSetI endPos = CoordinateSetI.from(other: _normStartPos);

          if (_hotkeyManager.shiftIsPressed)
          {
            endPos.x = _normStartPos.x + (_normStartPos.x - _cursorPosNorm.x);
            endPos.y = _normStartPos.y + (_normStartPos.y - _cursorPosNorm.y);
          }

          _selectionStart.x = min(endPos.x, _cursorPosNorm.x);
          _selectionStart.y = min(endPos.y, _cursorPosNorm.y);
          _selectionEnd.x = max(endPos.x, _cursorPosNorm.x);
          _selectionEnd.y = max(endPos.y, _cursorPosNorm.y);

          if (_options.keepRatio.value)
          {
            final int width = _selectionEnd.x - _selectionStart.x;
            final int height = _selectionEnd.y - _selectionStart.y;
            if (_hotkeyManager.shiftIsPressed)
            {
              final int diff = (width - height).abs();
              if (width > height)
              {
                _selectionStart.x += diff ~/ 2;
                _selectionEnd.x -= ((diff ~/ 2) + (diff % 2));
              }
              else
              {
                _selectionStart.y += diff ~/ 2;
                _selectionEnd.y -= ((diff ~/ 2) + (diff % 2));
              }
            }
            else
            {
              if (width > height) {
                if (_normStartPos.x < _cursorPosNorm.x) {
                  _selectionEnd.x = _selectionStart.x + height;
                } else {
                  _selectionStart.x = _selectionEnd.x - height;
                }
              } else {
                if (_normStartPos.y < _cursorPosNorm.y) {
                  _selectionEnd.y = _selectionStart.y + width;
                } else {
                  _selectionStart.y = _selectionEnd.y - width;
                }
              }
            }
          }

          if (selectionChanged)
          {
            final Set<CoordinateSetI> contentPoints = _calculateSelectionContent(options: _options, selectionStart: _selectionStart, selectionEnd: _selectionEnd);
            _drawingPixels = getPixelsToDraw(coords: contentPoints, currentLayer: drawParams.currentDrawingLayer!, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);

          }
        }
        if (!drawParams.primaryDown && _drawingPixels.isNotEmpty)
        {
          _dump(layer: drawParams.currentDrawingLayer!, canvasSize: drawParams.canvasSize);
          _waitingForRasterization = true;
        }
      }
      else if (drawParams.currentDrawingLayer!.rasterQueue.isEmpty && !drawParams.currentDrawingLayer!.isRasterizing && _drawingPixels.isNotEmpty && _waitingForRasterization)
      {
        _drawingPixels.clear();
        _waitingForRasterization = false;
      }
    }
  }

  void _dump({required final DrawingLayerState layer, required CoordinateSetI canvasSize})
  {
    if (_drawingPixels.isNotEmpty)
    {
      if (!appState.selectionState.selection.isEmpty)
      {
        appState.selectionState.selection.addDirectlyAll(list: _drawingPixels);
      }
      else if (!shaderOptions.isEnabled.value && _behaviorPreferenceContent.selectShapeAfterInsert.value)
      {
        appState.selectionState.addNewSelectionWithContent(colorMap: _drawingPixels);
      }
      else
      {
        layer.setDataAll(list: _drawingPixels);
      }
      hasHistoryData = true;
    }
  }

  @override
  CoordinateColorMap getCursorContent({required DrawingParameters drawParams})
  {
    if (drawParams.primaryDown || _waitingForRasterization)
    {
      return _drawingPixels;
    }
    else
    {
      return super.getCursorContent(drawParams: drawParams);
    }
  }


  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    assert(drawParams.cursorPos != null);

    if (_isStarted)
    {
      drawParams.paint.style = PaintingStyle.stroke;
      final CoordinateSetD cursorStartPos = CoordinateSetD(
          x: drawParams.offset.dx + _selectionStart.x * drawParams.pixelSize,
          y: drawParams.offset.dy +
              _selectionStart.y * drawParams.pixelSize);
      final CoordinateSetD cursorEndPos = CoordinateSetD(
          x: drawParams.offset.dx +
              (_selectionEnd.x + 1) * drawParams.pixelSize,
          y: drawParams.offset.dy +
              (_selectionEnd.y + 1) * drawParams.pixelSize);

      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = Colors.black;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = Colors.white;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
    }

    if (!drawParams.primaryDown)
    {
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + _cursorPosNorm.x * drawParams.pixelSize,
          y: drawParams.offset.dy + _cursorPosNorm.y * drawParams.pixelSize);
      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = Colors.black;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize, cursorPos.y + drawParams.pixelSize), drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = Colors.white;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize, cursorPos.y + drawParams.pixelSize), drawParams.paint);
    }
  }

  static Set<CoordinateSetI> _calculateSelectionContent({required ShapeOptions options, required CoordinateSetI selectionStart, required CoordinateSetI selectionEnd})
  {
    Set<CoordinateSetI> content = {};
    final double centerX = (selectionStart.x + selectionEnd.x + 1) / 2.0;
    final double centerY = (selectionStart.y + selectionEnd.y + 1) / 2.0;
    final double radiusX = (selectionEnd.x - selectionStart.x + 1) / 2.0;
    final double radiusY = (selectionEnd.y - selectionStart.y + 1) / 2.0;

    //RECTANGLE
    if (options.shape.value == ShapeShape.rectangle)
    {
      for (int x = selectionStart.x; x <= selectionEnd.x; x++)
      {
        for (int y = selectionStart.y; y <= selectionEnd.y; y++)
        {
          if (options.cornerRadius.value == 0 || _isPointInRoundedRectangle(testPoint: CoordinateSetI(x: x, y: y), topLeft: selectionStart, bottomRight: selectionEnd, radius: options.cornerRadius.value))
          {
            content.add(CoordinateSetI(x: x, y: y));
          }
        }
      }

      if (options.strokeOnly.value)
      {
        Set<CoordinateSetI> boundaryPoints = {};
        for (final CoordinateSetI coord in content)
        {
          if (!content.contains(CoordinateSetI(x: coord.x, y: coord.y + 1)) ||
              !content.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)) ||
              !content.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)) ||
              !content.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)))
          {
            boundaryPoints.add(coord);
          }
        }
        Set<CoordinateSetI> strokeContent = {};
        for (final CoordinateSetI coordContent in content)
        {
          int minDistance = 1000000000;
          for (final CoordinateSetI coordBoundary in boundaryPoints)
          {
            final int dSquaredDist = ((coordBoundary.x - coordContent.x) * (coordBoundary.x - coordContent.x)) + ((coordBoundary.y - coordContent.y) * (coordBoundary.y - coordContent.y));
            if (dSquaredDist < minDistance)
            {
              minDistance = dSquaredDist;
            }
          }
          if (minDistance < (options.strokeWidth.value * options.strokeWidth.value))
          {
            strokeContent.add(coordContent);
          }
        }
        content = strokeContent;
      }

    }
    //ELLIPSE
    else if (options.shape.value == ShapeShape.ellipse)
    {
      final double invRadiusXSquared = 1.0 / (radiusX * radiusX);
      final double invRadiusYSquared = 1.0 / (radiusY * radiusY);
      final double innerRadiusX = radiusX - options.strokeWidth.value;
      final double innerRadiusY = radiusY - options.strokeWidth.value;


      final double invInnerRadiusXSquared = 1.0 / (innerRadiusX * innerRadiusX);
      final double invInnerRadiusYSquared = 1.0 / (innerRadiusY * innerRadiusY);

      for (int x = selectionStart.x; x <= selectionEnd.x; x++)
      {
        for (int y = selectionStart.y; y <= selectionEnd.y; y++)
        {
          final double dx = (x + 0.5) - centerX;
          final double dy = (y + 0.5) - centerY;
          final double normalizedX = dx * dx * invRadiusXSquared;
          final double normalizedY = dy * dy * invRadiusYSquared;

          if (normalizedX + normalizedY <= 1.005)
          {
            if (!options.strokeOnly.value)
            {
              content.add(CoordinateSetI(x: x, y: y));
            }
            else
            {
              final double normalizedInnerX = dx * dx * invInnerRadiusXSquared;
              final double normalizedInnerY = dy * dy * invInnerRadiusYSquared;
              if (normalizedInnerX + normalizedInnerY >= 0.995)
              {
                content.add(CoordinateSetI(x: x, y: y));
              }
            }
          }
        }
      }
    }
    //OTHER SHAPES
    else
    {
      final List<CoordinateSetI> points = _getPolygonPoints(options: options, selectionStart: selectionStart, selectionEnd: selectionEnd);
      final CoordinateSetI min = Helper.getMin(coordList: points);
      final CoordinateSetI max = Helper.getMax(coordList: points);
      for (int x = min.x; x <= max.x; x++)
      {
        for (int y = min.y; y <= max.y; y++)
        {
          final CoordinateSetI point = CoordinateSetI(x: x, y: y);
          if (Helper.isPointInPolygon(point: point, polygon: points))
          {
            if (!options.strokeOnly.value || (Helper.getPointToEdgeDistance(point: point, polygon: points) <= options.strokeWidth.value))
            {
              content.add(point);
            }
          }
        }
      }
    }

    //clean up algorithm
    if ((options.shape.value == ShapeShape.ellipse || options.shape.value == ShapeShape.diamond || options.shape.value == ShapeShape.ngon || options.shape.value == ShapeShape.triangle) &&
        options.strokeOnly.value && options.strokeWidth.value == 1 && content.length > 2 && (selectionEnd.x - selectionStart.x).abs() > 2 && (selectionEnd.y - selectionStart.y).abs() > 2)
    {
      final Set<CoordinateSetI> edgyPixels = {};
      for (final CoordinateSetI curCoord in content)
      {
        final bool hasTop = content.contains(CoordinateSetI(x: curCoord.x, y: curCoord.y - 1));
        final bool hasBottom = content.contains(CoordinateSetI(x: curCoord.x, y: curCoord.y + 1));
        final bool hasLeft = content.contains(CoordinateSetI(x: curCoord.x - 1, y: curCoord.y));
        final bool hasRight = content.contains(CoordinateSetI(x: curCoord.x + 1, y: curCoord.y));
        if ((hasTop && hasLeft) || (hasTop && hasRight) || (hasBottom && hasLeft) || (hasBottom && hasRight))
        {
          edgyPixels.add(curCoord);
        }
      }

      final Set<CoordinateSetI> removePixels = {};
      for (final CoordinateSetI curCoord in edgyPixels)
      {

        final bool hasTop = edgyPixels.contains(CoordinateSetI(x: curCoord.x, y: curCoord.y - 1));
        final bool hasBottom = edgyPixels.contains(CoordinateSetI(x: curCoord.x, y: curCoord.y + 1));
        final bool hasLeft = edgyPixels.contains(CoordinateSetI(x: curCoord.x - 1, y: curCoord.y));
        final bool hasRight = edgyPixels.contains(CoordinateSetI(x: curCoord.x + 1, y: curCoord.y));

        if ((!hasTop && !hasBottom && !hasLeft && !hasRight) ||
            ((hasTop && curCoord.y <= centerY.round()) || (hasBottom && curCoord.y > centerY.round()) || (hasLeft && curCoord.x <= centerX.round()) || (hasRight && curCoord.x > centerX.round())))
        {
          removePixels.add(curCoord);
        }
      }
      for (final CoordinateSetI rPix in removePixels)
      {
        content.remove(rPix);
      }
    }
    return content;
  }

  static List<CoordinateSetI> _getPolygonPoints({required ShapeOptions options, required CoordinateSetI selectionStart, required CoordinateSetI selectionEnd})
  {
    List<CoordinateSetI> points = [];
    if (options.shape.value == ShapeShape.triangle)
    {
      points = [
        CoordinateSetI(x: selectionStart.x + (selectionEnd.x - selectionStart.x) ~/ 2,y: selectionStart.y - 1),
        CoordinateSetI(x: selectionEnd.x + 1, y: selectionEnd.y + 1),
        CoordinateSetI(x: selectionStart.x - 1, y: selectionEnd.y + 1),
      ];
    }
    else if (options.shape.value == ShapeShape.diamond)
    {
      points = [
        CoordinateSetI(x: selectionStart.x + ((selectionEnd.x - selectionStart.x) / 2).round(),y: selectionStart.y - 1),
        CoordinateSetI(x: selectionEnd.x + 1, y: selectionStart.y + ((selectionEnd.y - selectionStart.y) / 2).round()),
        CoordinateSetI(x: selectionStart.x + ((selectionEnd.x - selectionStart.x) / 2).round(),y: selectionEnd.y + 1),
        CoordinateSetI(x: selectionStart.x, y: selectionStart.y + ((selectionEnd.y - selectionStart.y) / 2).round()),
      ];
    }
    else if (options.shape.value == ShapeShape.star || options.shape.value == ShapeShape.ngon)
    {
      final double centerX = (selectionStart.x + selectionEnd.x) / 2;
      final double centerY = (selectionStart.y + selectionEnd.y) / 2;
      final double boxWidth = (selectionEnd.x - selectionStart.x + 1).toDouble();
      final double boxHeight = (selectionEnd.y - selectionStart.y + 1).toDouble();
      final double radiusOuterX = boxWidth / 2;
      final double radiusOuterY = boxHeight / 2;
      final double radiusInnerX = radiusOuterX / 2;
      final double radiusInnerY = radiusOuterY / 2;

      final double angleStep = pi / options.cornerCount.value;
      final double startAngle = options.cornerCount.value.isOdd ? -pi / 2 : 0;

      for (int i = 0; i < 2 * options.cornerCount.value; i++)
      {
        final bool isOuter = (i % 2 == 0);
        final double radiusX = isOuter ? radiusOuterX : radiusInnerX;
        final double radiusY = isOuter ? radiusOuterY : radiusInnerY;
        final double angle = startAngle + i * angleStep;

        final int x = (centerX + radiusX * cos(angle)).round();
        final int y = (centerY + radiusY * sin(angle)).round();

        if (isOuter || options.shape.value == ShapeShape.star)
        {
          points.add(CoordinateSetI(x: x, y: y));
        }
      }
    }

    return points;
  }

  static bool _isPointInRoundedRectangle(
      {required final CoordinateSetI testPoint,
        required final CoordinateSetI topLeft,
        required final CoordinateSetI bottomRight,
        required final int radius})
  {
    if ((testPoint.x >= topLeft.x + radius && testPoint.x <= bottomRight.x - radius && testPoint.y >= topLeft.y && testPoint.y <= bottomRight.y) ||
        (testPoint.y >= topLeft.y + radius && testPoint.y <= bottomRight.y - radius && testPoint.x >= topLeft.x && testPoint.x <= bottomRight.x))
    {
      return true;
    }

    final CoordinateSetI topLeftCorner = CoordinateSetI(x: topLeft.x + radius, y: topLeft.y + radius);
    final CoordinateSetI topRightCorner = CoordinateSetI(x: bottomRight.x - radius, y: topLeft.y + radius);
    final CoordinateSetI bottomLeftCorner = CoordinateSetI(x: topLeft.x + radius, y: bottomRight.y - radius);
    final CoordinateSetI bottomRightCorner = CoordinateSetI(x: bottomRight.x - radius, y: bottomRight.y - radius);

    if (_isPointInCircle(pt: testPoint, center: topLeftCorner, radius: radius) ||
        _isPointInCircle(pt: testPoint, center: topRightCorner, radius: radius) ||
        _isPointInCircle(pt: testPoint, center: bottomLeftCorner, radius: radius) ||
        _isPointInCircle(pt: testPoint, center: bottomRightCorner, radius: radius)) {
      return true;
    }

    return false;
  }


  static bool _isPointInCircle(
      {required final CoordinateSetI pt,
      required final CoordinateSetI center,
      required final int radius})
  {
    final int dx = pt.x - center.x;
    final int dy = pt.y - center.y;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void setStatusBarData({required DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    if (drawParams.cursorPos != null)
    {
      statusBarData.cursorPos = _cursorPosNorm;
      if (drawParams.primaryDown)
      {
        int width = (_selectionStart.x - _selectionEnd.x).abs() + 1;
        int height = (_selectionStart.y - _selectionEnd.y).abs() + 1;
        statusBarData.aspectRatio = statusBarData.diagonal = statusBarData.dimension = CoordinateSetI(x: width, y: height);
      }
    }
  }

  @override
  void reset()
  {
    _isStarted = false;
    _waitingForRasterization = false;
    _drawingPixels.clear();
  }

}