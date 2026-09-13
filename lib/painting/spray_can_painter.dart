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
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

class SprayCanPainter extends IToolPainter
{
  SprayCanPainter({required super.painterOptions, final Random? random}) : _random = random ?? Random();

  final Random _random;
  final SprayCanOptions _options = GetIt.I.get<ToolOptions>().sprayCanOptions;
  final CoordinateColorMap _drawingPixels = HashMap<CoordinateSetI, ColorReference>();
  CoordinateSetI? _lastCursorPosNorm;
  Set<CoordinateSetI> _cursorPoints = <CoordinateSetI>{};
  final Set<CoordinateSetI> _allPaintPositions = <CoordinateSetI>{};
  //the sprayed pixels whose colors are not worked out yet
  final Set<CoordinateSetI> _newPaintPositions = <CoordinateSetI>{};
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
              timer = Timer.periodic(Duration(milliseconds: 500 ~/ _options.intensity.value), (final Timer timer) {spray();});
              timerInitialized = true;
            }

            if (!_isDown)
            {
              _isDown = true;
            }
            if (_hasNewPositions)
            {
              //only the pixels sprayed since the last update are new; the colors
              //of the others are already in _drawingPixels and in the preview
              final CoordinateColorMap newPixels = _takeNewPixels(drawParams: drawParams, rasterLayer: rasterLayer);
              _drawingPixels.addAll(newPixels);
              updateStrokePreview(settledPixels: newPixels, currentLayer: rasterLayer);
              _hasNewPositions = false;
            }
          }
          else if (!drawParams.primaryDown && _isDown)
          {
            timer.cancel();
            if (rasterLayer is DrawingLayerState)
            {
              _drawingPixels.addAll(_takeNewPixels(drawParams: drawParams, rasterLayer: rasterLayer));
              _dumpDrawing(currentLayer: rasterLayer);
              _waitingForDump = true;
            }
            else if (rasterLayer is ShadingLayerState)
            {
              //shading steps add up per pixel, so the whole spray goes in at once
              final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: _allPaintPositions, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
              dumpShading(shadingLayer: rasterLayer, coordinates: mirrorPoints, shaderOptions: shaderOptions);
              _drawingPixels.clear();
            }

            _allPaintPositions.clear();
            _newPaintPositions.clear();
            _isDown = false;
          }
        }
        else if (_waitingForDump)
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
      if (!documentState.selectionState.selection.isEmpty)
      {
        documentState.selectionState.selection.addDirectlyAll(list: _drawingPixels);
      }
      else
      {
        currentLayer.setDataAll(list: _drawingPixels);
      }
      hasHistoryData = true;
      resetContentRaster(currentLayer: currentLayer);
    }
  }

  /// The colors of the pixels sprayed since the last call, as they go onto
  /// [rasterLayer].
  CoordinateColorMap _takeNewPixels({required final DrawingParameters drawParams, required final RasterableLayerState rasterLayer})
  {
    CoordinateColorMap pixels = CoordinateColorMap();
    //without symmetry, the mirror points are the set itself, so it is only
    //emptied once they are used
    final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: _newPaintPositions, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
    if (rasterLayer is DrawingLayerState)
    {
      pixels = getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: paletteState.selectedColor!, selection: documentState.selectionState, shaderOptions: shaderOptions);
    }
    else if (rasterLayer is ShadingLayerState)
    {
      pixels = getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, coords: mirrorPoints, shaderOptions: shaderOptions);
    }
    _newPaintPositions.clear();
    return pixels;
  }

  /// Sprays one blob around the cursor; the timer calls this while the button
  /// is held.
  @visibleForTesting
  void spray()
  {
    if (_lastCursorPosNorm != null)
    {
      final double r = _options.radius.value * sqrt(_random.nextDouble());
      final double theta = _random.nextDouble() * 2 * pi;
      final int x = (_lastCursorPosNorm!.x + (r * cos(theta))).round();
      final int y = (_lastCursorPosNorm!.y + (r * sin(theta))).round();
      for (final CoordinateSetI point in getRoundSquareContentPoints(shape: PencilShape.round, size: _options.blobSize.value, position: CoordinateSetI(x: x, y: y)))
      {
        if (_allPaintPositions.add(point))
        {
          _newPaintPositions.add(point);
        }
      }
      hasAsyncUpdate = true;
      _hasNewPositions = true;
    }
  }


  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    //Surrounding
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: _cursorPoints);
    final Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * effPxlSize) + drawParams.offset.dx, (pathPoints[i].y * effPxlSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * effPxlSize) + drawParams.offset.dx, (pathPoints[i + 1].y * effPxlSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * effPxlSize) + drawParams.offset.dx, (pathPoints[0].y * effPxlSize) + drawParams.offset.dy);
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
    _newPaintPositions.clear();
    discardStrokePreview();
    _waitingForDump = false;
    _isDown = false;
    if (timerInitialized)
    {
      timer.cancel();
    }
    timerInitialized = false;
  }

}
