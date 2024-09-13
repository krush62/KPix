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
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/layer_widget.dart';

class SprayCanPainter extends IToolPainter
{
  SprayCanPainter({required super.painterOptions});

  final SprayCanOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.sprayCanOptions;
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateColorMap _drawingPixels = HashMap();
  Set<CoordinateSetI> _contentPoints = {};
  final Set<CoordinateSetI> _paintPositions = {};
  bool _waitingForRasterization = false;
  bool _isDown = false;
  late Timer timer;
  bool timerInitialized = false;

  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null)
    {
      _cursorPosNorm.x = getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      _cursorPosNorm.y = getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();

      _contentPoints = getRoundSquareContentPoints(shape: PencilShape.round, size: _options.radius.value * 2, position: _cursorPosNorm);

    }

    if (!_waitingForRasterization && drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
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
        if (_paintPositions.isNotEmpty)
        {
          _drawingPixels.addAll(getPixelsToDraw(coords: _paintPositions, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
          _paintPositions.clear();
        }
      }
      else if (!drawParams.primaryDown && _isDown)
      {
        timer.cancel();
        _dump(currentLayer: drawParams.currentLayer);
        _waitingForRasterization = true;
        _paintPositions.clear();
        _isDown = false;
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
      hasHistoryData = true;
    }
  }

  void _timeout({required final Timer timer})
  {
    final double r = _options.radius.value * sqrt(Random().nextDouble());
    final double theta = Random().nextDouble() * 2 * pi;
    final int x = (_cursorPosNorm.x + (r * cos(theta))).round();
    final int y = (_cursorPosNorm.y + (r * sin(theta))).round();
    _paintPositions.addAll(getRoundSquareContentPoints(shape: PencilShape.round, size: _options.blobSize.value, position: CoordinateSetI(x: x, y: y)));
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
    _drawingPixels.clear();
    _contentPoints.clear();
    _paintPositions.clear();
    _waitingForRasterization = false;
    _isDown = false;
    timer.cancel();
    timerInitialized = false;
  }

}