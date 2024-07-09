import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class EraserPainter extends IToolPainter
{
  final EraserOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.eraserOptions;
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);

  EraserPainter({required super.painterOptions});

  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null)
    {
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
        if (drawParams.primaryDown && drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
        {
          List<CoordinateSetI> pixelsToDelete = [_cursorPosNorm];
          if (!_cursorPosNorm.isAdjacent(_previousCursorPosNorm, true))
          {
            pixelsToDelete.addAll(Helper.bresenham(_previousCursorPosNorm, _cursorPosNorm).sublist(1));
          }
          final HashMap<CoordinateSetI, ColorReference?> refs = HashMap();
          for (final CoordinateSetI delCoord in pixelsToDelete)
          {
            Set<CoordinateSetI> content = getRoundSquareContentPoints(_options.shape.value, _options.size.value, delCoord);
            final SelectionState selection = GetIt.I.get<AppState>().selectionState;
            for (final CoordinateSetI coord in content)
            {
              if (coord.x >= 0 && coord.y >= 0 &&
                  coord.x < drawParams.canvasSize.x &&
                  coord.y < drawParams.canvasSize.y)
              {
                if (selection.selection.isEmpty())
                {
                  if (drawParams.currentLayer.getData(coord) != null)
                  {
                    //drawParams.currentLayer.setData(coord, null);
                    refs[coord] = null;
                  }
                }
                else
                {
                  selection.selection.deleteDirectly(coord);
                }
              }
            }
          }
          drawParams.currentLayer.setDataAll(refs);
        }
        _previousCursorPosNorm.x = _cursorPosNorm.x;
        _previousCursorPosNorm.y = _cursorPosNorm.y;
      }
    }
  }

  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    assert(drawParams.cursorPos != null);

    final Set<CoordinateSetI> contentPoints = getRoundSquareContentPoints(_options.shape.value, _options.size.value, _cursorPosNorm);
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(contentPoints);

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

}

