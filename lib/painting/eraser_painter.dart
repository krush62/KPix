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
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/layer_widget.dart';

class EraserPainter extends IToolPainter
{
  final EraserOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.eraserOptions;
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
  bool _isDown = false;
  bool _hasErasedPixels = false;

  EraserPainter({required super.painterOptions});

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


      //if (_cursorPosNorm != _previousCursorPosNorm)
      {
        if (drawParams.primaryDown && drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
        {
          List<CoordinateSetI> pixelsToDelete = [_cursorPosNorm];
          if (!_cursorPosNorm.isAdjacent(other: _previousCursorPosNorm, withDiagonal: true))
          {
            pixelsToDelete.addAll(Helper.bresenham(start: _previousCursorPosNorm, end: _cursorPosNorm).sublist(1));
          }
          final CoordinateColorMapNullable refs = HashMap();
          for (final CoordinateSetI delCoord in pixelsToDelete)
          {
            Set<CoordinateSetI> content = getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: delCoord);
            final SelectionState selection = GetIt.I.get<AppState>().selectionState;
            for (final CoordinateSetI coord in content)
            {
              if (coord.x >= 0 && coord.y >= 0 &&
                  coord.x < drawParams.canvasSize.x &&
                  coord.y < drawParams.canvasSize.y)
              {
                if (selection.selection.isEmpty())
                {
                  if (drawParams.currentLayer.getDataEntry(coord: coord) != null)
                  {
                    refs[coord] = null;
                  }
                }
                else
                {
                  selection.selection.deleteDirectly(coord: coord);
                }
              }
              _hasErasedPixels = true;
            }
          }
          drawParams.currentLayer.setDataAll(list: refs);
        }
        _previousCursorPosNorm.x = _cursorPosNorm.x;
        _previousCursorPosNorm.y = _cursorPosNorm.y;
      }
    }
    if (drawParams.primaryDown && _isDown == false)
    {
      _isDown = true;
    }
    else if (!drawParams.primaryDown && _isDown == true)
    {
      _isDown = false;
      if (_hasErasedPixels)
      {
        hasHistoryData = true;
        _hasErasedPixels = false;
      }
    }
  }

  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    assert(drawParams.cursorPos != null);

    final Set<CoordinateSetI> contentPoints = getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: _cursorPosNorm);
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: contentPoints);

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
  void setStatusBarData({required DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPos != null ? _cursorPosNorm : null;
  }

  @override
  void reset()
  {
    _isDown = false;
    _hasErasedPixels = false;
  }

}

