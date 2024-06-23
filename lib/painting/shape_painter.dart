import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class ShapePainter extends IToolPainter
{
  final ShapeOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.shapeOptions;
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final CoordinateSetI _selectionStart = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _selectionEnd = CoordinateSetI(x: 0, y: 0);
  Offset _lastStartPos = const Offset(0,0);
  final CoordinateSetI _normStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lastNormStartPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _normEndPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _lastNormEndPos = CoordinateSetI(x: 0, y: 0);
  bool _isStartOnCanvas = false;
  bool _waitingForRasterization = false;
  HashMap<CoordinateSetI, ColorReference> _drawingPixels = HashMap();


  ShapePainter({required super.painterOptions});


  @override
  void calculate({required DrawingParameters drawParams})
  {
    bool selectionChanged = false;
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

    if (_normStartPos != _lastNormStartPos)
    {
      _lastNormStartPos.x = _normStartPos.x;
      _lastNormStartPos.y = _normStartPos.y;
      selectionChanged = true;
    }
    if (_normEndPos != _lastNormEndPos)
    {
      _lastNormEndPos.x = _normEndPos.x;
      _lastNormEndPos.y = _normEndPos.y;
      selectionChanged = true;
    }

    if (!_waitingForRasterization)
    {
      _isStartOnCanvas = drawParams.primaryDown && drawParams.cursorPos != null && _normStartPos.x >= 0 && _normStartPos.y >= 0 && _normStartPos.x < appState.canvasWidth && _normStartPos.y < appState.canvasHeight;
      if (_isStartOnCanvas)
      {
        _selectionStart.x = max(_normStartPos.x < _normEndPos.x ? _normStartPos.x: _normEndPos.x, 0);
        _selectionStart.y = max(_normStartPos.y < _normEndPos.y ? _normStartPos.y : _normEndPos.y, 0);
        _selectionEnd.x = min(_normStartPos.x < _normEndPos.x ? (_normEndPos.x) : (_normStartPos.x), appState.canvasWidth - 1);
        _selectionEnd.y = min(_normStartPos.y < _normEndPos.y ? (_normEndPos.y) : (_normStartPos.y), appState.canvasHeight - 1);


        if (_options.keepRatio.value)
        {
          final int width = _selectionEnd.x - _selectionStart.x;
          final int height = _selectionEnd.y - _selectionStart.y;
          if (width > height) {
            if (_normStartPos.x < _normEndPos.x) {
              _selectionEnd.x = _selectionStart.x + height;
            } else {
              _selectionStart.x = _selectionEnd.x - height;
            }
          } else {
            if (_normStartPos.y < _normEndPos.y) {
              _selectionEnd.y = _selectionStart.y + width;
            } else {
              _selectionStart.y = _selectionEnd.y - width;
            }
          }
        }

        if (selectionChanged)
        {
          final Set<CoordinateSetI> contentPoints = _calculateSelectionContent(options: _options, selectionStart: _selectionStart, selectionEnd: _selectionEnd);
          _drawingPixels = getPixelsToDraw(coords: contentPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: _shaderOptions);

        }
      }
      if (!drawParams.primaryDown && _drawingPixels.isNotEmpty)
      {
        _dump(layer: drawParams.currentLayer, canvasSize: drawParams.canvasSize);
        _waitingForRasterization = true;
      }
    }
    else if (drawParams.currentLayer.rasterQueue.isEmpty && !drawParams.currentLayer.isRasterizing && _drawingPixels.isNotEmpty && _waitingForRasterization)
    {
      _drawingPixels.clear();
      _waitingForRasterization = false;
    }
  }

  void _dump({required final LayerState layer, required CoordinateSetI canvasSize})
  {
    if (_drawingPixels.isNotEmpty)
    {
      if (!appState.selectionState.selection.isEmpty())
      {
        appState.selectionState.selection.addDirectlyAll(_drawingPixels);
      }
      else
      {
        layer.setDataAll(_drawingPixels);
      }
    }
  }

  @override
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawPars})
  {
    if (drawPars.primaryDown || _waitingForRasterization)
    {
      return _drawingPixels;
    }
    else
    {
      return super.getCursorContent(drawPars: drawPars);
    }
  }


  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    assert(drawParams.cursorPos != null);

    if (_isStartOnCanvas)
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
          x: drawParams.offset.dx + _normEndPos.x * drawParams.pixelSize,
          y: drawParams.offset.dy + _normEndPos.y * drawParams.pixelSize);
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
    //RECTANGLE
    if (options.shape.value == ShapeShape.rectangle)
    {
      for (int x = selectionStart.x; x <= selectionEnd.x; x++)
      {
        for (int y = selectionStart.y; y <= selectionEnd.y; y++)
        {
          if (options.cornerRadius.value == 0 || _isPointInRoundedRectangle(CoordinateSetI(x: x, y: y), selectionStart, selectionEnd, options.cornerRadius.value))
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
      final double centerX = (selectionStart.x + selectionEnd.x + 1) / 2.0;
      final double centerY = (selectionStart.y + selectionEnd.y + 1) / 2.0;
      final double radiusX = (selectionEnd.x - selectionStart.x + 1) / 2.0;
      final double radiusY = (selectionEnd.y - selectionStart.y + 1) / 2.0;

      for (int x = selectionStart.x; x <= selectionEnd.x; x++)
      {
        for (int y = selectionStart.y; y <= selectionEnd.y; y++)
        {
          final double dx = (x + 0.5) - centerX;
          final double dy = (y + 0.5) - centerY;
          if ((dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1)
          {
            if (!options.strokeOnly.value || ((dx * dx) / ((radiusX - options.strokeWidth.value) * (radiusX - options.strokeWidth.value)) + (dy * dy) / ((radiusY - options.strokeWidth.value) * (radiusY - options.strokeWidth.value)) > 1))
            {
              content.add(CoordinateSetI(x: x, y: y));
            }
          }
        }
      }
    }
    else
    {
      final List<CoordinateSetI> points = _getPolygonPoints(options: options, selectionStart: selectionStart, selectionEnd: selectionEnd);

      final CoordinateSetI min = Helper.getMin(points);
      final CoordinateSetI max = Helper.getMax(points);
      for (int x = min.x; x <= max.x; x++)
      {
        for (int y = min.y; y <= max.y; y++)
        {
          if (Helper.isPointInPolygon(CoordinateSetI(x: x, y: y), points))
          {
            final CoordinateSetI point = CoordinateSetI(x: x, y: y);
            if (!options.strokeOnly.value || (Helper.getPointToEdgeDistance(point, points) < options.strokeWidth.value))
            {
              content.add(point);
            }
          }
        }
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

  static bool _isPointInRoundedRectangle(CoordinateSetI testPoint, CoordinateSetI topLeft, CoordinateSetI bottomRight, int radius)
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

    if (_isPointInCircle(testPoint, topLeftCorner, radius) ||
        _isPointInCircle(testPoint, topRightCorner, radius) ||
        _isPointInCircle(testPoint, bottomLeftCorner, radius) ||
        _isPointInCircle(testPoint, bottomRightCorner, radius)) {
      return true;
    }

    return false;
  }


  static bool _isPointInCircle(final CoordinateSetI pt, final CoordinateSetI center, final int radius)
  {
    final int dx = pt.x - center.x;
    final int dy = pt.y - center.y;
    return dx * dx + dy * dy <= radius * radius;
  }

}