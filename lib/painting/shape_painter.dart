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
    if (drawParams.currentRasterLayer != null && drawParams.cursorPosNorm != null)
    {
      final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;
      bool selectionChanged = false;
      if (_lastStartPos.dx != drawParams.primaryPressStart.dx || _lastStartPos.dy != drawParams.primaryPressStart.dy)
      {
        _normStartPos.x = IToolPainter.getClosestPixel(value: drawParams.primaryPressStart.dx - drawParams.offset.dx, pixelSize: drawParams.pixelSize.toDouble() / drawParams.pixelRatio);
        _normStartPos.y = IToolPainter.getClosestPixel(value: drawParams.primaryPressStart.dy - drawParams.offset.dy, pixelSize: drawParams.pixelSize.toDouble() / drawParams.pixelRatio);
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
            if (rasterLayer is DrawingLayerState)
            {
              _drawingPixels = getPixelsToDraw(coords: contentPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
            }
            else if (rasterLayer is ShadingLayerState)
            {
              _drawingPixels = getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, coords: contentPoints, shaderOptions: shaderOptions);
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
          if (rasterLayer is DrawingLayerState)
          {
            _drawingPixels = getPixelsToDraw(coords: contentPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
            _dumpDrawingLayer(layer: rasterLayer, canvasSize: drawParams.canvasSize);
            _waitingForRasterization = true;
          }
          else if (rasterLayer is ShadingLayerState)
          {
            dumpShading(shadingLayer: rasterLayer, coordinates: contentPoints, shaderOptions: shaderOptions);
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
    if (drawParams.cursorPosNorm != null)
    {
      if (_isStarted)
      {
        drawParams.paint.style = PaintingStyle.stroke;
        final CoordinateSetD cursorStartPos = CoordinateSetD(
          x: drawParams.offset.dx + _selectionStart.x * drawParams.pixelSize / drawParams.pixelRatio,
          y: drawParams.offset.dy +
              _selectionStart.y * drawParams.pixelSize / drawParams.pixelRatio,);
        final CoordinateSetD cursorEndPos = CoordinateSetD(
          x: drawParams.offset.dx +
              (_selectionEnd.x + 1) * drawParams.pixelSize / drawParams.pixelRatio,
          y: drawParams.offset.dy +
              (_selectionEnd.y + 1) * drawParams.pixelSize / drawParams.pixelRatio,);

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
          x: drawParams.offset.dx + drawParams.cursorPosNorm!.x * drawParams.pixelSize / drawParams.pixelRatio,
          y: drawParams.offset.dy + drawParams.cursorPosNorm!.y * drawParams.pixelSize / drawParams.pixelRatio,);
        drawParams.paint.style = PaintingStyle.stroke;
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
        drawParams.paint.color = blackToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize / drawParams.pixelRatio, cursorPos.y + drawParams.pixelSize / drawParams.pixelRatio), drawParams.paint);
        drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
        drawParams.paint.color = whiteToolAlphaColor;
        drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize / drawParams.pixelRatio, cursorPos.y + drawParams.pixelSize / drawParams.pixelRatio), drawParams.paint);
      }
    }
  }

  static Set<CoordinateSetI> _calculateSelectionContent({required final ShapeOptions options, required final CoordinateSetI selectionStart, required final CoordinateSetI selectionEnd})
  {
    Set<CoordinateSetI> content = <CoordinateSetI>{};
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
    }
    //ELLIPSE
    else if (options.shape.value == ShapeShape.ellipse)
    {
      final double invRadiusXSquared = 1.0 / (radiusX * radiusX);
      final double invRadiusYSquared = 1.0 / (radiusY * radiusY);

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
            content.add(CoordinateSetI(x: x, y: y));
          }
        }
      }
    }
    //OTHER SHAPES
    else
    {
      final List<CoordinateSetI> points = _getPolygonPoints(options: options, selectionStart: selectionStart, selectionEnd: selectionEnd);
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
    }

    if (options.strokeOnly.value)
    {
      content = _calculateInnerStrokeForWidth(content, options.strokeWidth.value);
    }
    return content;
  }





  static Set<CoordinateSetI> _calculateInnerStrokeForWidth(final Set<CoordinateSetI> filledShape, final int strokeWidth) {
    final Set<CoordinateSetI> innerStroke = <CoordinateSetI>{};
    final Set<CoordinateSetI> currentShape = Set<CoordinateSetI>.from(filledShape);

    for (int i = 0; i < strokeWidth; i++)
    {
      final Set<CoordinateSetI> boundaryCoords = <CoordinateSetI>{};

      // Find the current boundary
      for (final CoordinateSetI coord in currentShape)
      {
        final List<CoordinateSetI> neighbors = getCoordinateNeighbors(pixel: coord, withDiagonals: false);
        for (final CoordinateSetI neighbor in neighbors)
        {
          if (!currentShape.contains(neighbor))
          {
            boundaryCoords.add(coord);
            break;
          }
        }
      }

      innerStroke.addAll(boundaryCoords);

      currentShape.removeAll(boundaryCoords);

      if (currentShape.isEmpty)
      {
        break;
      }
    }

    return innerStroke;
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
        final bool isOuter = i.isEven;
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

    // Clamp points to bounds
    for (final CoordinateSetI point in points) {
      point.x = max(selectionStart.x, min(point.x, selectionEnd.x));
      point.y = max(selectionStart.y, min(point.y, selectionEnd.y));
    }

    return points;
  }

  static bool _isPointInRoundedRectangle(
      {required final CoordinateSetI testPoint,
        required final CoordinateSetI topLeft,
        required final CoordinateSetI bottomRight,
        required final int radius,})
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
