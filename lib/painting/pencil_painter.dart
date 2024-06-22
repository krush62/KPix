import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class PencilPainter extends IToolPainter
{
  final PencilOptions options = GetIt.I.get<PreferenceManager>().toolOptions.pencilOptions;
  final KPixPainterOptions kPixPainterOptions = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final ShaderOptions shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final List<CoordinateSetI> paintPositions = [];
  final CoordinateSetI cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI previousCursorPosNorm = CoordinateSetI(x: 0, y: 0);
  Set<CoordinateSetI> contentPoints = {};
  bool waitingForRasterization = false;
  final HashMap<CoordinateSetI, ColorReference> drawingPixels = HashMap();

  PencilPainter({required super.painterOptions});

  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null) {
      cursorPosNorm.x = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      cursorPosNorm.y = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
       if (cursorPosNorm != previousCursorPosNorm)
       {
         contentPoints = getRoundSquareContentPoints(options.shape.value, options.size.value, cursorPosNorm);
         previousCursorPosNorm.x = cursorPosNorm.x;
         previousCursorPosNorm.y = cursorPosNorm.y;
       }
    }
    if (!waitingForRasterization)
    {
      if (drawParams.primaryDown)
      {
        if (paintPositions.isEmpty || cursorPosNorm.isAdjacent(paintPositions[paintPositions.length - 1], true))
        {
          paintPositions.add(CoordinateSetI(x: cursorPosNorm.x, y: cursorPosNorm.y));
          //PIXEL PERFECT
          if (paintPositions.length >= 3)
          {
            if (options.pixelPerfect.value && paintPositions[paintPositions.length-1].isDiagonal(paintPositions[paintPositions.length - 3]))
            {
              paintPositions.removeAt(paintPositions.length - 2);
            }
          }
        }
        else
        {
          paintPositions.addAll(Helper.bresenham(paintPositions[paintPositions.length - 1], cursorPosNorm).sublist(1));
        }
        if (paintPositions.length > 3)
        {
          final Set<CoordinateSetI> posSet = paintPositions.sublist(0, paintPositions.length - 3).toSet();
          final Set<CoordinateSetI> paintPoints = {};
          for (final CoordinateSetI pos in posSet)
          {
            paintPoints.addAll(getRoundSquareContentPoints(options.shape.value, options.size.value, pos));
          }
          drawingPixels.addAll(getPixelsToDraw(coords: paintPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: shaderOptions));
          paintPositions.removeRange(0, paintPositions.length - 3);
        }
      }
      else if (paintPositions.isNotEmpty) //final dumping
      {
        final Set<CoordinateSetI> posSet = paintPositions.toSet();
        final Set<CoordinateSetI> paintPoints = {};
        for (final CoordinateSetI pos in posSet)
        {
          paintPoints.addAll(getRoundSquareContentPoints(options.shape.value, options.size.value, pos));
        }
        drawingPixels.addAll(getPixelsToDraw(coords: paintPoints, currentLayer: drawParams.currentLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: shaderOptions));
        _dump(currentLayer: drawParams.currentLayer);
        waitingForRasterization = true;
        paintPositions.clear();
      }
    }
    else if (drawParams.currentLayer.rasterQueue.isEmpty && !drawParams.currentLayer.isRasterizing && drawingPixels.isNotEmpty)
    {
      drawingPixels.clear();
      waitingForRasterization = false;
    }
  }

  void _dump({required final LayerState currentLayer})
  {
    if (drawingPixels.isNotEmpty)
    {
      if (!appState.selectionState.selection.isEmpty())
      {
        appState.selectionState.selection.addDirectlyAll(drawingPixels);
      }
      else
      {
        currentLayer.setDataAll(drawingPixels);
      }
    }
  }

  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    //Surrounding
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
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawPars})
  {
    if(appState.selectedColor.value != null && drawPars.cursorPos != null)
    {
      return getPixelsToDraw(coords: contentPoints, canvasSize: drawPars.canvasSize, currentLayer: drawPars.currentLayer, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: shaderOptions);
    }
    else
    {
      return super.getCursorContent(drawPars: drawPars);
    }
  }

  @override
  HashMap<CoordinateSetI, ColorReference> getToolContent({required DrawingParameters drawPars})
  {
    if (drawPars.primaryDown || waitingForRasterization)
    {
      return drawingPixels;
    }
    else
    {
      return super.getToolContent(drawPars: drawPars);
    }
  }


}