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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
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
    if (drawParams.currentRasterLayer != null)
    {
      final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;
      if (drawParams.cursorPos != null)
      {
        _cursorPoints = getRoundSquareContentPoints(shape: PencilShape.round, size: _options.radius.value * 2, position: drawParams.cursorPosNorm!);
        _lastCursorPosNorm = drawParams.cursorPosNorm;
        if (!_waitingForDump && (rasterLayer.lockState.value != LayerLockState.locked && rasterLayer.visibilityState.value != LayerVisibilityState.hidden))
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
              if (rasterLayer is DrawingLayerState)
              {
                _drawingPixels.addAll(getPixelsToDraw(coords: _allPaintPositions, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
              }
              else if (rasterLayer is ShadingLayerState)
              {
                _drawingPixels.addAll(getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, coords: _allPaintPositions, shaderOptions: shaderOptions));
              }

              rasterizePixels(drawingPixels: _drawingPixels, currentLayer: rasterLayer).then((final ContentRasterSet? rasterSet)
              {
                if (rasterSet != null)
                {
                  setContentRasterData(content: rasterSet);
                }
                else
                {
                  resetContentRaster(currentLayer: rasterLayer);
                }

                hasAsyncUpdate = true;
              });
              _hasNewPositions = false;
            }
          }
          else if (!drawParams.primaryDown && _isDown)
          {
            timer.cancel();
            _drawingPixels.clear();
            if (rasterLayer is DrawingLayerState)
            {
              _drawingPixels.addAll(getPixelsToDraw(coords: _allPaintPositions, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
              _dumpDrawing(currentLayer: rasterLayer);
              _waitingForDump = true;
            }
            else if (rasterLayer is ShadingLayerState)
            {
              _drawingPixels.addAll(getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, coords: _allPaintPositions, shaderOptions: shaderOptions));
              dumpShading(shadingLayer: rasterLayer, coordinates: _allPaintPositions, shaderOptions: shaderOptions);
              _drawingPixels.clear();
            }

            _allPaintPositions.clear();
            _isDown = false;
          }
        }
        else if (rasterLayer is DrawingLayerState && rasterLayer.rasterQueue.isEmpty && rasterLayer.isRasterizing && _waitingForDump)
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
      hasHistoryData = true;
      resetContentRaster(currentLayer: currentLayer);
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
