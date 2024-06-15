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
  final EraserOptions options = GetIt.I.get<PreferenceManager>().toolOptions.eraserOptions;
  final CoordinateSetI cursorPosNorm = CoordinateSetI(x: 0, y: 0);

  EraserPainter({required super.painterOptions});

  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null)
    {
      cursorPosNorm.x = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      cursorPosNorm.y = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();

      if (drawParams.primaryDown && drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
      {
        Set<CoordinateSetI> content = getContentPoints(options.shape.value, options.size.value, cursorPosNorm);
        final SelectionState selection = GetIt.I.get<AppState>().selectionState;
        for (final CoordinateSetI coord in content)
        {
          if (coord.x >= 0 && coord.y >= 0 &&
              coord.x < drawParams.canvasSize.x &&
              coord.y < drawParams.canvasSize.y) {
            if (selection.selection.isEmpty()) {
              if (drawParams.currentLayer.getData(coord.x, coord.y) != null) {
                drawParams.currentLayer.setData(coord.x, coord.y, null);
              }
            }
            else {
              selection.selection.deleteDirectly(coord);
            }
          }
        }
      }
    }
  }

  @override
  void drawCursor({required DrawingParameters drawParams})
  {
    final Set<CoordinateSetI> contentPoints = getContentPoints(options.shape.value, options.size.value, cursorPosNorm);
    final List<CoordinateSetI> pathPoints = getBoundaryPath(contentPoints);

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
  void drawExtras({required DrawingParameters drawParams}) {
    //nothing to do
  }

  @override
  void drawTool({required DrawingParameters drawParams})
  {
    //nothing to do
  }




}

