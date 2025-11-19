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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class ShapePainter extends IToolPainter
{
  final ShapeOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.shapeOptions;
  final BehaviorPreferenceContent _behaviorPreferenceContent = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final CoordinateSetI _selectionStart = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _selectionEnd = CoordinateSetI(x: 0, y: 0);
  Offset _lastStartPos = Offset.zero;
  final CoordinateSetI _normStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lastNormStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lastNormEndPos = CoordinateSetI(x: 0, y: 0);
  bool _isStarted = false;
  bool _waitingForRasterization = false;
  CoordinateColorMap _drawingPixels = HashMap<CoordinateSetI, ColorReference>();

  ShapePainter({required super.painterOptions});


  @override
  void calculate({required final DrawingParameters drawParams})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    if (drawParams.currentRasterLayer != null && drawParams.cursorPosNorm != null)
    {
      final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;
      bool selectionChanged = false;
      if (_lastStartPos.dx != drawParams.primaryPressStart.dx || _lastStartPos.dy != drawParams.primaryPressStart.dy)
      {
        _normStartPos.x = IToolPainter.getClosestPixel(value: drawParams.primaryPressStart.dx - drawParams.offset.dx, pixelSize: effPxlSize);
        _normStartPos.y = IToolPainter.getClosestPixel(value: drawParams.primaryPressStart.dy - drawParams.offset.dy, pixelSize: effPxlSize);
        _lastStartPos = drawParams.primaryPressStart;
      }



      if (!_waitingForRasterization && (rasterLayer.lockState.value != LayerLockState.locked && rasterLayer.visibilityState.value != LayerVisibilityState.hidden))
      {
        _isStarted = drawParams.primaryDown && drawParams.cursorPos != null;
        if (_isStarted)
        {
          if ((_hotkeyManager.altIsPressed && !_hotkeyManager.shiftIsPressed) || drawParams.stylusButtonDown)
          {
            _normStartPos.x -= _lastNormEndPos.x - drawParams.cursorPosNorm!.x;
            _normStartPos.y -= _lastNormEndPos.y - drawParams.cursorPosNorm!.y;
          }


          final CoordinateSetI endPos = CoordinateSetI.from(other: _normStartPos);

          if (_hotkeyManager.shiftIsPressed)
          {
            endPos.x = _normStartPos.x + (_normStartPos.x - drawParams.cursorPosNorm!.x);
            endPos.y = _normStartPos.y + (_normStartPos.y - drawParams.cursorPosNorm!.y);
          }

          _selectionStart.x = min(endPos.x, drawParams.cursorPosNorm!.x);
          _selectionStart.y = min(endPos.y, drawParams.cursorPosNorm!.y);
          _selectionEnd.x = max(endPos.x, drawParams.cursorPosNorm!.x);
          _selectionEnd.y = max(endPos.y, drawParams.cursorPosNorm!.y);

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
                _selectionEnd.x -= (diff ~/ 2) + (diff % 2);
              }
              else
              {
                _selectionStart.y += diff ~/ 2;
                _selectionEnd.y -= (diff ~/ 2) + (diff % 2);
              }
            }
            else
            {
              if (width > height)
              {
                if (_normStartPos.x < drawParams.cursorPosNorm!.x) {
                  _selectionEnd.x = _selectionStart.x + height;
                }
                else
                {
                  _selectionStart.x = _selectionEnd.x - height;
                }
              }
              else
              {
                if (_normStartPos.y < drawParams.cursorPosNorm!.y)
                {
                  _selectionEnd.y = _selectionStart.y + width;
                }
                else
                {
                  _selectionStart.y = _selectionEnd.y - width;
                }
              }
            }
          }

          if (_normStartPos != _lastNormStartPos)
          {
            _lastNormStartPos.x = _normStartPos.x;
            _lastNormStartPos.y = _normStartPos.y;
            selectionChanged = true;
          }
          if (drawParams.cursorPosNorm! != _lastNormEndPos)
          {
            _lastNormEndPos.x = drawParams.cursorPosNorm!.x;
            _lastNormEndPos.y = drawParams.cursorPosNorm!.y;
            selectionChanged = true;
          }

          if (selectionChanged)
          {
            final Set<CoordinateSetI> contentPoints = _calculateSelectionContent(options: _options, selectionStart: _selectionStart, selectionEnd: _selectionEnd);
            final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: contentPoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
            if (rasterLayer is DrawingLayerState)
            {
              _drawingPixels = getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
            }
            else if (rasterLayer is ShadingLayerState)
            {
              _drawingPixels = getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, coords: mirrorPoints, shaderOptions: shaderOptions);
            }

            rasterizePixels(drawingPixels: _drawingPixels, currentLayer: rasterLayer).then((final ContentRasterSet? rasterSet) {
              cursorRaster = rasterSet;
              hasAsyncUpdate = true;
            });
          }
        }
        if (!drawParams.primaryDown && _drawingPixels.isNotEmpty) //DUMPING
        {
          final Set<CoordinateSetI> contentPoints = _calculateSelectionContent(options: _options, selectionStart: _selectionStart, selectionEnd: _selectionEnd);
          final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: contentPoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
          if (rasterLayer is DrawingLayerState)
          {
            _drawingPixels = getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
            _dumpDrawingLayer(layer: rasterLayer, canvasSize: drawParams.canvasSize);
            _waitingForRasterization = true;
          }
          else if (rasterLayer is ShadingLayerState)
          {
            dumpShading(shadingLayer: rasterLayer, coordinates: mirrorPoints, shaderOptions: shaderOptions);
            _drawingPixels.clear();
          }
        }
      }
      else if (_drawingPixels.isNotEmpty && _waitingForRasterization && (rasterLayer is DrawingLayerState && rasterLayer.rasterQueue.isEmpty && !rasterLayer.isRasterizing))
      {
        _drawingPixels.clear();
        _waitingForRasterization = false;

      }
      if (!drawParams.primaryDown && !_waitingForRasterization)
      {
        cursorRaster = null;
      }
    }
  }

  void _dumpDrawingLayer({required final DrawingLayerState layer, required final CoordinateSetI canvasSize})
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
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    if (drawParams.cursorPosNorm != null)
    {
      if (_isStarted)
      {
        drawParams.paint.style = PaintingStyle.stroke;
        final CoordinateSetD cursorStartPos = CoordinateSetD(
          x: drawParams.offset.dx + _selectionStart.x * effPxlSize,
          y: drawParams.offset.dy +
              _selectionStart.y * effPxlSize,);
        final CoordinateSetD cursorEndPos = CoordinateSetD(
          x: drawParams.offset.dx +
              (_selectionEnd.x + 1) * effPxlSize,
          y: drawParams.offset.dy +
              (_selectionEnd.y + 1) * effPxlSize,);

        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
        drawParams.paint.color = blackToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = whiteToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorStartPos.x, cursorStartPos.y, cursorEndPos.x, cursorEndPos.y), drawParams.paint);
      }

      if (!drawParams.primaryDown)
      {
        final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + drawParams.cursorPosNorm!.x * effPxlSize,
          y: drawParams.offset.dy + drawParams.cursorPosNorm!.y * effPxlSize,);
        drawParams.paint.style = PaintingStyle.stroke;
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
        drawParams.paint.color = blackToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + effPxlSize, cursorPos.y + effPxlSize), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = whiteToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + effPxlSize, cursorPos.y + effPxlSize), drawParams.paint);
      }
    }
  }

  static Set<CoordinateSetI> _calculateSelectionContent({required final ShapeOptions options, required final CoordinateSetI selectionStart, required final CoordinateSetI selectionEnd})
  {
    Set<CoordinateSetI> content = <CoordinateSetI>{};
    final int width = selectionEnd.x - selectionStart.x + 1;
    final int height = selectionEnd.y - selectionStart.y + 1;

    //RECTANGLE
    if (options.shape.value == ShapeShape.rectangle)
    {
      final CoordinateSetI innerSelectionStart = CoordinateSetI(x: selectionStart.x + options.strokeWidth.value, y: selectionStart.y + options.strokeWidth.value);
      final CoordinateSetI innerSelectionEnd = CoordinateSetI(x: selectionEnd.x - options.strokeWidth.value, y: selectionEnd.y - options.strokeWidth.value);
      final int innerWidth = innerSelectionEnd.x - innerSelectionStart.x + 1;
      final int innerHeight = innerSelectionEnd.y - innerSelectionStart.y + 1;
      final int outerWidth = selectionEnd.x - selectionStart.x + 1;
      final int outerHeight = selectionEnd.y - selectionStart.y + 1;
      final double shrinkX = innerWidth / outerWidth;
      final double shrinkY = innerHeight / outerHeight;
      final double shrinkFactor = min(shrinkX, shrinkY);
      final int maxInnerRadius = min(innerWidth, innerHeight) ~/ 2;
      final int innerCornerRadius = min((options.cornerRadius.value * shrinkFactor).floor() - 1, maxInnerRadius);

      final Set<CoordinateSetI> innerContent = <CoordinateSetI>{};
      if (options.strokeOnly.value)
      {
        //calculate inner rectangle
        for (int x = innerSelectionStart.x; x <= innerSelectionEnd.x; x++)
        {
          for (int y = innerSelectionStart.y; y <= innerSelectionEnd.y; y++)
          {
            if (_isPointInRoundedRectangle(testPoint: CoordinateSetI(x: x, y: y), topLeft: innerSelectionStart, bottomRight: innerSelectionEnd, radius: innerCornerRadius))
            {
              innerContent.add(CoordinateSetI(x: x, y: y));
            }
          }
        }
      }


      final int usedCornerRadius = min(options.cornerRadius.value, min(width, height) ~/ 2);

      for (int x = selectionStart.x; x <= selectionEnd.x; x++)
      {
        for (int y = selectionStart.y; y <= selectionEnd.y; y++)
        {
          if (usedCornerRadius == 0 || _isPointInRoundedRectangle(testPoint: CoordinateSetI(x: x, y: y), topLeft: selectionStart, bottomRight: selectionEnd, radius: usedCornerRadius))
          {
            if (!innerContent.contains(CoordinateSetI(x: x, y: y)))
            {
              content.add(CoordinateSetI(x: x, y: y));
            }
          }
        }
      }
    }
    //ELLIPSE
    else if (options.shape.value == ShapeShape.ellipse)
    {
      if (options.strokeOnly.value)
      {
        content.addAll(drawStrokedEllipse(start: selectionStart, end: selectionEnd, strokeWidth: options.strokeWidth.value));
      }
      else
      {
        content.addAll(drawFilledEllipse(start: selectionStart, end: selectionEnd));
      }
    }
    //OTHER SHAPES (POLYGONS)
    else
    {
      final List<CoordinateSetI> points = _getPolygonPoints(options: options, selectionStart: selectionStart, selectionEnd: selectionEnd);
      if (options.strokeOnly.value && options.strokeWidth.value == 1)
      {
        for (int i = 0; i < points.length; i++)
        {
          final CoordinateSetI pointOrigin = points[i];
          final CoordinateSetI pointTarget = points[(i + 1) % points.length];
          content.addAll(bresenham(start: pointOrigin, end: pointTarget));
        }
      }
      else
      {
        final CoordinateSetI min = getMin(coordList: points);
        final CoordinateSetI max = getMax(coordList: points);
        for (int x = min.x; x <= max.x; x++)
        {
          for (int y = min.y; y <= max.y; y++)
          {
            final CoordinateSetI point = CoordinateSetI(x: x, y: y);
            if (isPointInPolygon(point: point, polygon: points))
            {
              content.add(point);
            }
          }
        }

        if (options.strokeOnly.value)
        {
          final List<CoordinateSetD> polygonVertices = points.map((final CoordinateSetI c) => CoordinateSetD(x: c.x.toDouble(), y: c.y.toDouble())).toList();
          content = _calculateInnerStrokeForWidth(content, polygonVertices, options.strokeWidth.value);
        }
      }
    }

    return content;
  }


  static double _pointToSegmentDistance(final CoordinateSetD pd, final CoordinateSetD p1, final CoordinateSetD p2)
  {
    final double dx = p2.x - p1.x;
    final double dy = p2.y - p1.y;

    if (dx == 0 && dy == 0)
    {
      return sqrt((pd.x - p1.x) * (pd.x - p1.x) + (pd.x - p1.y) * (pd.y - p1.y));
    }

    final double t = ((pd.x - p1.x) * dx + (pd.y - p1.y) * dy) / (dx * dx + dy * dy);
    final double tc = t.clamp(0.0, 1.0);

    final double cx = p1.x + tc * dx;
    final double cy = p1.y + tc * dy;

    final double dxp = pd.x - cx;
    final double dyp = pd.y - cy;

    return sqrt(dxp * dxp + dyp * dyp);
  }

  static double _distanceToPolygonEdges(final CoordinateSetD pd, final List<CoordinateSetD> vertices)
  {
    double minDist = double.infinity;
    for (int i = 0; i < vertices.length; i++)
    {
      final CoordinateSetD p1 = vertices[i];
      final CoordinateSetD p2 = vertices[(i + 1) % vertices.length];
      final double dist = _pointToSegmentDistance(pd, p1, p2);
      if (dist < minDist)
      {
        minDist = dist;
      }
    }
    return minDist;
  }


  static Set<CoordinateSetI> _calculateInnerStrokeForWidth(final Set<CoordinateSetI> filledShape, final List<CoordinateSetD> polygonVertices, final int strokeWidth)
  {
    final Set<CoordinateSetI> result = <CoordinateSetI>{};

    for (final CoordinateSetI p in filledShape)
    {
      final CoordinateSetD pd = CoordinateSetD(x: p.x.toDouble(), y: p.y.toDouble());
      final double dist = _distanceToPolygonEdges(pd, polygonVertices);
      if (dist < strokeWidth)
      {
        result.add(p);
      }
    }
    return result;
  }

  static List<CoordinateSetI> _getPolygonPoints({required final ShapeOptions options, required final CoordinateSetI selectionStart, required final CoordinateSetI selectionEnd})
  {
    List<CoordinateSetI> points = <CoordinateSetI>[];
    if (options.shape.value == ShapeShape.triangle)
    {
      points = <CoordinateSetI>[
        CoordinateSetI(x: selectionStart.x + (selectionEnd.x - selectionStart.x) ~/ 2, y: selectionStart.y - 1),
        CoordinateSetI(x: selectionEnd.x + 1, y: selectionEnd.y + 1),
        CoordinateSetI(x: selectionStart.x - 1, y: selectionEnd.y + 1),
      ];
    }
    else if (options.shape.value == ShapeShape.diamond)
    {
      final int centerX = selectionStart.x + ((selectionEnd.x - selectionStart.x) / 2).round();
      final int centerY = selectionStart.y + ((selectionEnd.y - selectionStart.y) / 2).round();

      // Define diamond points before clamping
      points = <CoordinateSetI>[
        CoordinateSetI(x: centerX, y: max(selectionStart.y, selectionStart.y - 1)),
        CoordinateSetI(x: min(selectionEnd.x, selectionEnd.x + 1), y: centerY),
        CoordinateSetI(x: centerX, y: min(selectionEnd.y, selectionEnd.y + 1)),
        CoordinateSetI(x: max(selectionStart.x, selectionStart.x - 1), y: centerY),
      ];
    }
    else if (options.shape.value == ShapeShape.star || options.shape.value == ShapeShape.ngon)
    {
      final int n = options.cornerCount.value;
      final bool isStar = options.shape.value == ShapeShape.star;

      final double left   = min(selectionStart.x, selectionEnd.x).toDouble();
      final double top    = min(selectionStart.y, selectionEnd.y).toDouble();
      final double width  = (selectionEnd.x - selectionStart.x).abs().toDouble();
      final double height = (selectionEnd.y - selectionStart.y).abs().toDouble();

      final double centerX = left + width / 2;
      final double centerY = top  + height / 2;

      final double radiusOuterX = width  / 2;
      final double radiusOuterY = height / 2;

      const double innerRatio = 0.5;
      final double radiusInnerX = radiusOuterX * innerRatio;
      final double radiusInnerY = radiusOuterY * innerRatio;

      final int pointCount = isStar ? 2 * n : n;
      final double angleStep = 2 * pi / pointCount;
      const double startAngle = -pi / 2; // Point upward

      for (int i = 0; i < pointCount; i++)
      {
        final double angle = startAngle + i * angleStep;
        final bool isOuter = !isStar || i.isEven;
        final double rx = isOuter ? radiusOuterX : radiusInnerX;
        final double ry = isOuter ? radiusOuterY : radiusInnerY;
        final int x = (centerX + rx * cos(angle)).round();
        final int y = (centerY + ry * sin(angle)).round();
        points.add(CoordinateSetI(x: x, y: y));
      }
    }

    // Clamp points to bounds
    for (final CoordinateSetI point in points) {
      point.x = max(selectionStart.x, min(point.x, selectionEnd.x));
      point.y = max(selectionStart.y, min(point.y, selectionEnd.y));
    }

    return points;
  }

  static bool _isPointInRoundedRectangle({
    required final CoordinateSetI testPoint,
    required final CoordinateSetI topLeft,
    required final CoordinateSetI bottomRight,
    required final int radius,
  }) {
    // Clamp radius to fit rectangle
    final int rx = min(radius, (bottomRight.x - topLeft.x) ~/ 2);
    final int ry = min(radius, (bottomRight.y - topLeft.y) ~/ 2);

    // Central rectangle (vertical and horizontal bars)
    if ((testPoint.x >= topLeft.x + rx && testPoint.x <= bottomRight.x - rx &&
        testPoint.y >= topLeft.y && testPoint.y <= bottomRight.y) ||
        (testPoint.y >= topLeft.y + ry && testPoint.y <= bottomRight.y - ry &&
            testPoint.x >= topLeft.x && testPoint.x <= bottomRight.x)) {
      return true;
    }

    // Corner circles
    final CoordinateSetI topLeftCorner = CoordinateSetI(x: topLeft.x + rx, y: topLeft.y + ry);
    final CoordinateSetI topRightCorner = CoordinateSetI(x: bottomRight.x - rx, y: topLeft.y + ry);
    final CoordinateSetI bottomLeftCorner = CoordinateSetI(x: topLeft.x + rx, y: bottomRight.y - ry);
    final CoordinateSetI bottomRightCorner = CoordinateSetI(x: bottomRight.x - rx, y: bottomRight.y - ry);

    if (_isPointInCircle(pt: testPoint, center: topLeftCorner, radius: rx) ||
        _isPointInCircle(pt: testPoint, center: topRightCorner, radius: rx) ||
        _isPointInCircle(pt: testPoint, center: bottomLeftCorner, radius: rx) ||
        _isPointInCircle(pt: testPoint, center: bottomRightCorner, radius: rx)) {
      return true;
    }

    return false;
  }


  static bool _isPointInCircle(
      {required final CoordinateSetI pt,
      required final CoordinateSetI center,
      required final int radius,})
  {
    final int dx = pt.x - center.x;
    final int dy = pt.y - center.y;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    if (drawParams.cursorPos != null)
    {
      statusBarData.cursorPos = drawParams.cursorPosNorm;
      if (drawParams.primaryDown)
      {
        final int width = (_selectionStart.x - _selectionEnd.x).abs() + 1;
        final int height = (_selectionStart.y - _selectionEnd.y).abs() + 1;
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
