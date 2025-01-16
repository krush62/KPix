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

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class SprayCanPainter extends IToolPainter
{
  SprayCanPainter({required super.painterOptions});

  final SprayCanOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.sprayCanOptions;
  final CoordinateColorMap _drawingPixels = HashMap<CoordinateSetI, ColorReference>();
  CoordinateSetI? _lastCursorPosNorm;
  Set<CoordinateSetI> _cursorPoints = <CoordinateSetI>{};
  final Set<CoordinateSetI> _allPaintPositions = <CoordinateSetI>{};
  bool _waitingForDump = false;
  bool _isDown = false;
  late Timer timer;
  bool timerInitialized = false;
  bool _hasNewPositions = false;

  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.currentDrawingLayer != null || drawParams.currentShadingLayer != null)
    {
      if (drawParams.cursorPos != null)
      {
        _cursorPoints = getRoundSquareContentPoints(shape: PencilShape.round, size: _options.radius.value * 2, position: drawParams.cursorPosNorm!);
        _lastCursorPosNorm = drawParams.cursorPosNorm;
        if (!_waitingForDump && (
            (drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden) ||
            (drawParams.currentShadingLayer != null && drawParams.currentShadingLayer!.lockState.value != LayerLockState.locked && drawParams.currentShadingLayer!.visibilityState.value != LayerVisibilityState.hidden)))
        {
          if (drawParams.primaryDown)
          {
            if (!timerInitialized || !timer.isActive)
            {
              timer = Timer.periodic(Duration(milliseconds: 500 ~/ _options.intensity.value), (final Timer timer) {_timeout(timer: timer);});
              timerInitialized = true;
            }

            if (!_isDown)
            {
              _isDown = true;
            }
            if (_hasNewPositions)
            {
              _drawingPixels.clear();
              _drawingPixels.addAll(
              drawParams.currentDrawingLayer != null ?
                getPixelsToDraw(coords: _allPaintPositions, currentLayer: drawParams.currentDrawingLayer!, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions, withShadingLayers: true) :
                getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentShadingLayer!, coords: _allPaintPositions, shaderOptions: shaderOptions),
              );

              rasterizeDrawingPixels(drawingPixels: _drawingPixels).then((final ContentRasterSet? rasterSet) {
                contentRaster = rasterSet;
                hasAsyncUpdate = true;
              });
              _hasNewPositions = false;
            }
          }
          else if (!drawParams.primaryDown && _isDown)
          {
            timer.cancel();
            _drawingPixels.clear();
            _drawingPixels.addAll(
              drawParams.currentDrawingLayer != null ?
              getPixelsToDraw(coords: _allPaintPositions, currentLayer: drawParams.currentDrawingLayer!, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions) :
              getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentShadingLayer!, coords: _allPaintPositions, shaderOptions: shaderOptions),
            );

            if (drawParams.currentDrawingLayer != null)
            {
              _dumpDrawing(currentLayer: drawParams.currentDrawingLayer!);
              _waitingForDump = true;
            }
            else
            {
              dumpShading(shadingLayer: drawParams.currentShadingLayer!, coordinates: _allPaintPositions, shaderOptions: shaderOptions);
              _drawingPixels.clear();
            }

            _allPaintPositions.clear();
            _isDown = false;
          }
        }
        else if (drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.rasterQueue.isEmpty && !drawParams.currentDrawingLayer!.isRasterizing && _waitingForDump)
        {
          _drawingPixels.clear();
          _waitingForDump = false;
        }
      }
    }
  }

  void _dumpDrawing({required final DrawingLayerState currentLayer})
  {
    if (_drawingPixels.isNotEmpty)
    {
      if (!appState.selectionState.selection.isEmpty)
      {
        appState.selectionState.selection.addDirectlyAll(list: _drawingPixels);
      }
      else
      {
        currentLayer.setDataAll(list: _drawingPixels);
      }
      contentRaster = null;
      hasHistoryData = true;
    }
  }

  void _timeout({required final Timer timer})
  {
    if (_lastCursorPosNorm != null)
    {
      final double r = _options.radius.value * sqrt(Random().nextDouble());
      final double theta = Random().nextDouble() * 2 * pi;
      final int x = (_lastCursorPosNorm!.x + (r * cos(theta))).round();
      final int y = (_lastCursorPosNorm!.y + (r * sin(theta))).round();
      _allPaintPositions.addAll(getRoundSquareContentPoints(shape: PencilShape.round, size: _options.blobSize.value, position: CoordinateSetI(x: x, y: y)));
      hasAsyncUpdate = true;
      _hasNewPositions = true;
    }
  }


  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    //Surrounding
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: _cursorPoints);
    final Path path = Path();
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
    drawParams.paint.color = blackToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = whiteToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }



  @override
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPosNorm;
  }

  @override
  void reset()
  {
    _drawingPixels.clear();
    _cursorPoints.clear();
    _hasNewPositions = false;
    _allPaintPositions.clear();
    _waitingForDump = false;
    _isDown = false;
    if (timerInitialized)
    {
      timer.cancel();
    }
    timerInitialized = false;
  }

}
