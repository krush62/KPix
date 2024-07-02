import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class PencilPainter extends IToolPainter
{
  final PencilOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.pencilOptions;
  //TODO put this into iToolPainter and remove from subclasses
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final List<CoordinateSetI> _paintPositions = [];
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
  Set<CoordinateSetI> _contentPoints = {};
  bool _waitingForRasterization = false;
  final HashMap<CoordinateSetI, ColorReference> _drawingPixels = HashMap();

  PencilPainter({required super.painterOptions});

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
         _contentPoints = getRoundSquareContentPoints(_options.shape.value, _options.size.value, _cursorPosNorm);
         _previousCursorPosNorm.x = _cursorPosNorm.x;
         _previousCursorPosNorm.y = _cursorPosNorm.y;
       }
    }
    if (!_waitingForRasterization)
    {
      if (drawParams.primaryDown)
      {
        if (_paintPositions.isEmpty || _cursorPosNorm.isAdjacent(_paintPositions[_paintPositions.length - 1], true))
        {
          _paintPositions.add(CoordinateSetI(x: _cursorPosNorm.x, y: _cursorPosNorm.y));
          //PIXEL PERFECT
          if (_paintPositions.length >= 3)
          {
            if (_options.pixelPerfect.value && _paintPositions[_paintPositions.length-1].isDiagonal(_paintPositions[_paintPositions.length - 3]))
            {
              _paintPositions.removeAt(_paintPositions.length - 2);
            }
          }
        }
        else
        {
          _paintPositions.addAll(Helper.bresenham(_paintPositions[_paintPositions.length - 1], _cursorPosNorm).sublist(1));
        }
        if (_paintPositions.length > 3)
        {
          final Set<CoordinateSetI> posSet = _paintPositions.sublist(0, _paintPositions.length - 3).toSet();
          final Set<CoordinateSetI> paintPoints = {};
          for (final CoordinateSetI pos in posSet)
          {
            paintPoints.addAll(getRoundSquareContentPoints(_options.shape.value, _options.size.value, pos));
          }
          _drawingPixels.addAll(getPixelsToDraw(coords: paintPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: _shaderOptions));
          _paintPositions.removeRange(0, _paintPositions.length - 3);
        }
      }
      else if (_paintPositions.isNotEmpty) //final dumping
      {
        final Set<CoordinateSetI> posSet = _paintPositions.toSet();
        final Set<CoordinateSetI> paintPoints = {};
        for (final CoordinateSetI pos in posSet)
        {
          paintPoints.addAll(getRoundSquareContentPoints(_options.shape.value, _options.size.value, pos));
        }
        _drawingPixels.addAll(getPixelsToDraw(coords: paintPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: _shaderOptions));
        _dump(currentLayer: drawParams.currentLayer);
        _waitingForRasterization = true;
        _paintPositions.clear();
      }
    }
    else if (drawParams.currentLayer.rasterQueue.isEmpty && !drawParams.currentLayer.isRasterizing && _drawingPixels.isNotEmpty && _waitingForRasterization)
    {
      _drawingPixels.clear();
      _waitingForRasterization = false;
    }
  }

  void _dump({required final LayerState currentLayer})
  {
    if (_drawingPixels.isNotEmpty)
    {
      if (!appState.selectionState.selection.isEmpty())
      {
        appState.selectionState.selection.addDirectlyAll(_drawingPixels);
      }
      else
      {
        currentLayer.setDataAll(_drawingPixels);
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
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawPars})
  {
    if(appState.selectedColor.value != null && drawPars.cursorPos != null)
    {
      return getPixelsToDraw(coords: _contentPoints, canvasSize: drawPars.canvasSize, currentLayer: drawPars.currentLayer, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: _shaderOptions);
    }
    else
    {
      return super.getCursorContent(drawPars: drawPars);
    }
  }

  @override
  HashMap<CoordinateSetI, ColorReference> getToolContent({required DrawingParameters drawPars})
  {
    if (drawPars.primaryDown || _waitingForRasterization)
    {
      return _drawingPixels;
    }
    else
    {
      return super.getToolContent(drawPars: drawPars);
    }
  }


}