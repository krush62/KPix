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
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/main/layer_widget.dart';

class PencilPainter extends IToolPainter
{
  final PencilOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.pencilOptions;
  final LineOptions _lineOptions = GetIt.I.get<PreferenceManager>().toolOptions.lineOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final List<CoordinateSetI> _paintPositions = [];
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
  int _previousToolSize = -1;
  Set<CoordinateSetI> _contentPoints = {};
  bool _waitingForRasterization = false;
  final CoordinateColorMap _drawingPixels = HashMap();
  CoordinateSetI? _lastDrawingPosition;
  bool _isLineDrawing = false;

  PencilPainter({required super.painterOptions});

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
       if (_cursorPosNorm != _previousCursorPosNorm || _previousToolSize != _options.size.value)
       {
         _contentPoints = getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: _cursorPosNorm);
         _previousCursorPosNorm.x = _cursorPosNorm.x;
         _previousCursorPosNorm.y = _cursorPosNorm.y;
         _previousToolSize = _options.size.value;
       }
    }
    if (!_waitingForRasterization)
    {
      if (drawParams.primaryDown)
      {
        if (drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
        {
          if (_hotkeyManager.shiftIsPressed)
          {
             _isLineDrawing = true;
          }
          else
          {
            if (_paintPositions.isEmpty || _cursorPosNorm.isAdjacent(other: _paintPositions[_paintPositions.length - 1], withDiagonal: true))
            {
              final CoordinateSetI drawPos = CoordinateSetI(x: _cursorPosNorm.x, y: _cursorPosNorm.y);
              _paintPositions.add(drawPos);
              _lastDrawingPosition = drawPos;
              //PIXEL PERFECT
              if (_paintPositions.length >= 3)
              {
                if (_options.pixelPerfect.value &&
                    _paintPositions[_paintPositions.length - 1].isDiagonal(other: _paintPositions[_paintPositions.length - 3]))
                {
                  _paintPositions.removeAt(_paintPositions.length - 2);
                }
              }
            }
            else
            {
              _paintPositions.addAll(Helper.bresenham(start: _paintPositions[_paintPositions.length - 1], end: _cursorPosNorm).sublist(1));
              _lastDrawingPosition = CoordinateSetI.from(other: _cursorPosNorm);
            }
          }
        }
        if (_paintPositions.length > 3)
        {
          final Set<CoordinateSetI> posSet = _paintPositions.sublist(0, _paintPositions.length - 3).toSet();
          final Set<CoordinateSetI> paintPoints = {};
          for (final CoordinateSetI pos in posSet)
          {
            paintPoints.addAll(getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: pos));
          }

          _drawingPixels.addAll(getPixelsToDraw(coords: paintPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
          _paintPositions.removeRange(0, _paintPositions.length - 3);
        }
      }
      else //final dumping
      {
        if (_paintPositions.isNotEmpty)
        {
          final Set<CoordinateSetI> posSet = _paintPositions.toSet();
          final Set<CoordinateSetI> paintPoints = {};
          for (final CoordinateSetI pos in posSet)
          {
            paintPoints.addAll(getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: pos));
          }
          _drawingPixels.addAll(getPixelsToDraw(coords: paintPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
          _dump(currentLayer: drawParams.currentLayer);
          _waitingForRasterization = true;
          _paintPositions.clear();
        }
        else if (_hotkeyManager.shiftIsPressed && _isLineDrawing)
        {
          final Set<CoordinateSetI> linePoints = _hotkeyManager.controlIsPressed ?
            getIntegerRatioLinePoints(startPos: _lastDrawingPosition!, endPos: _cursorPosNorm, size: _options.size.value, angles: _lineOptions.angles, shape: _options.shape.value) :
            getLinePoints(startPos: _lastDrawingPosition!, endPos: _cursorPosNorm, size: _options.size.value, shape: _options.shape.value);
          _drawingPixels.addAll(getPixelsToDraw(coords: linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
          _dump(currentLayer: drawParams.currentLayer);
          _waitingForRasterization = true;
          _lastDrawingPosition = CoordinateSetI.from(other: linePoints.last);
        }
        _isLineDrawing = false;

      }
    }
    else if (drawParams.currentLayer.rasterQueue.isEmpty && !drawParams.currentLayer.isRasterizing && _waitingForRasterization)
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
        appState.selectionState.selection.addDirectlyAll(list: _drawingPixels);
      }
      else
      {
        currentLayer.setDataAll(list: _drawingPixels);
      }
    }
    hasHistoryData = true;
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
    if(appState.selectedColor != null && drawParams.cursorPos != null)
    {
      if (_hotkeyManager.shiftIsPressed && _lastDrawingPosition != null && _paintPositions.isEmpty)
      {
        final Set<CoordinateSetI> linePoints = _hotkeyManager.controlIsPressed ?
        getIntegerRatioLinePoints(startPos: _lastDrawingPosition!, endPos: _cursorPosNorm, size: _options.size.value, angles: _lineOptions.angles, shape: _options.shape.value) :
        getLinePoints(startPos: _lastDrawingPosition!, endPos: _cursorPosNorm, size: _options.size.value, shape: _options.shape.value);
        return getPixelsToDraw(coords: linePoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
      }
      else
      {
        return getPixelsToDraw(coords: _contentPoints, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
      }
    }
    else
    {
      return super.getCursorContent(drawParams: drawParams);
    }
  }

  @override
  CoordinateColorMap getToolContent({required DrawingParameters drawParams})
  {
    if (drawParams.primaryDown || _waitingForRasterization)
    {
      return _drawingPixels;
    }
    else
    {
      return super.getToolContent(drawParams: drawParams);
    }
  }

  @override
  void setStatusBarData({required DrawingParameters drawParams})
  {
      super.setStatusBarData(drawParams: drawParams);
      statusBarData.cursorPos = drawParams.cursorPos != null ? _cursorPosNorm : null;
  }

  @override
  void reset()
  {
    _paintPositions.clear();
    _previousToolSize = -1;
    _contentPoints.clear();
    _waitingForRasterization = false;
    _drawingPixels.clear();
    _lastDrawingPosition = null;
    _isLineDrawing = false;
  }
}