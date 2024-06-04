import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/canvas_widget.dart';

abstract class IToolPainter
{
  final AppState appState = GetIt.I.get<AppState>();

  void drawTool({
    required DrawingParameters drawParams});

  void drawCursor({required DrawingParameters drawParams});
}

class KPixPainterOptions
{
  final double cursorSize;
  final double cursorBorderWidth;


  KPixPainterOptions({
    required this.cursorSize,
    required this.cursorBorderWidth
  });
}

class DrawingParameters
{
  final Offset offset;
  final Canvas canvas;
  final Paint paint;
  final int pixelSize;
  final CoordinateSetI canvasSize;
  final CoordinateSetI scaledCanvasSize;
  final CoordinateSetI drawingStart;
  final CoordinateSetI drawingEnd;
  final Size drawingSize;
  final CoordinateSetD? cursorPos;
  final bool primaryDown;
  final Offset primaryPressStart;
  DrawingParameters({
    required this.offset,
    required this.canvas,
    required this.paint,
    required this.pixelSize,
    required this.canvasSize,
    required this.drawingSize,
    required this.cursorPos,
    required this.primaryDown,
    required this.primaryPressStart
}) :
        scaledCanvasSize = CoordinateSetI(x: canvasSize.x * pixelSize, y: canvasSize.y * pixelSize),
        drawingStart = CoordinateSetI(x: offset.dx > 0 ? 0 : -(offset.dx / pixelSize).ceil(), y: offset.dy > 0 ? 0 : -(offset.dy / pixelSize).ceil()),
        drawingEnd = CoordinateSetI(x: offset.dx + (canvasSize.x * pixelSize) < drawingSize.width ? canvasSize.x : canvasSize.x - ((offset.dx + (canvasSize.x * pixelSize) - drawingSize.width) / pixelSize).floor(),
                                    y: offset.dy + (canvasSize.y) * pixelSize < drawingSize.height ? canvasSize.y : canvasSize.y - ((offset.dy + (canvasSize.y * pixelSize) - drawingSize.height) / pixelSize).floor());
}

class KPixPainter extends CustomPainter
{
  final AppState appState;
  final ValueNotifier<Offset> offset;
  final ValueNotifier<CoordinateSetD?> coords;
  final ValueNotifier<bool> isDragging;
  final ValueNotifier<bool> primaryDown;
  final ValueNotifier<Offset> primaryPressStart;
  final KPixPainterOptions options = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final Color checkerboardColor1;
  final Color checkerboardColor2;
  late Map<ToolType, IToolPainter> toolPainterMap;



  KPixPainter({
    required this.appState,
    required this.offset,
    required this.checkerboardColor1,
    required this.checkerboardColor2,
    required this.coords,
    required this.primaryDown,
    required this.primaryPressStart,
    required this.isDragging})
      : super(repaint: appState.repaintNotifier)
  {
    toolPainterMap = {
      ToolType.select: SelectionPainter()
    };
  }

  @override
  void paint(Canvas canvas, Size size) {

    DrawingParameters drawParams = DrawingParameters(
        offset: offset.value,
        canvas: canvas,
        paint: Paint(),
        pixelSize: appState.getZoomLevel() ~/ 100,
        canvasSize: CoordinateSetI(x: appState.canvasWidth, y: appState.canvasHeight),
        drawingSize: size,
        cursorPos: coords.value,
        primaryDown: primaryDown.value,
        primaryPressStart: primaryPressStart.value
        );


    //TODO this is too slow (solid color?)
    _drawCheckerboard(drawParams: drawParams);
    _drawLayers(drawParams: drawParams);
    _drawSelection(drawParams: drawParams);
    _drawToolOverlay(drawParams: drawParams);
    _drawCursor(drawParams: drawParams);
  }

  void _drawSelection({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    drawParams.paint.style = PaintingStyle.stroke;
    //TODO magic numbers and values
    double strokeWidth = 2;
    drawParams.paint.strokeWidth = strokeWidth;

    for (final SelectionLine line in appState.selectionState.selectionLines)
    {
      if (line.selectDir == SelectionDirection.Left)
      {
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl) - strokeWidth / 2, offset.value.dy + (line.startLoc.y * pxlSzDbl) - strokeWidth / 2),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) - strokeWidth / 2, offset.value.dy + (line.endLoc.y  * pxlSzDbl) + pxlSzDbl + strokeWidth / 2), drawParams.paint);
        drawParams.paint.color = Colors.white;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl) + strokeWidth / 2, offset.value.dy + (line.startLoc.y * pxlSzDbl)),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + strokeWidth / 2, offset.value.dy + (line.endLoc.y  * pxlSzDbl) + pxlSzDbl), drawParams.paint);
      }
      else if (line.selectDir == SelectionDirection.Right)
      {
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl) + pxlSzDbl + strokeWidth / 2, offset.value.dy + (line.startLoc.y * pxlSzDbl) - strokeWidth / 2),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl + strokeWidth / 2, offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl + strokeWidth / 2), drawParams.paint);
        drawParams.paint.color = Colors.white;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl) + pxlSzDbl - strokeWidth / 2, offset.value.dy + (line.startLoc.y * pxlSzDbl)),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl - strokeWidth / 2, offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl), drawParams.paint);
      }
      else if (line.selectDir == SelectionDirection.Top)
      {
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl) - strokeWidth / 2, offset.value.dy + (line.startLoc.y * pxlSzDbl) - strokeWidth / 2),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl + strokeWidth / 2, offset.value.dy + (line.endLoc.y * pxlSzDbl) - strokeWidth / 2), drawParams.paint);
        drawParams.paint.color = Colors.white;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl), offset.value.dy + (line.startLoc.y * pxlSzDbl) + strokeWidth / 2),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl, offset.value.dy + (line.endLoc.y * pxlSzDbl) + strokeWidth / 2), drawParams.paint);
      }
      else if (line.selectDir == SelectionDirection.Bottom)
      {
        drawParams.paint.color = Colors.black;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl) - strokeWidth / 2, offset.value.dy + (line.startLoc.y * pxlSzDbl) + pxlSzDbl + strokeWidth / 2),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl + strokeWidth / 2, offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl + strokeWidth / 2), drawParams.paint);
        drawParams.paint.color = Colors.white;
        drawParams.canvas.drawLine(
            Offset(offset.value.dx + (line.startLoc.x * pxlSzDbl), offset.value.dy + (line.startLoc.y * pxlSzDbl) + pxlSzDbl - strokeWidth / 2),
            Offset(offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl, offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl - strokeWidth / 2), drawParams.paint);
      }

    }
  }

  void _drawToolOverlay({required final DrawingParameters drawParams})
  {
    if (coords.value != null)
    {
      IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
      toolPainter?.drawTool(drawParams: drawParams);
    }
  }

  void _drawCursor({required final DrawingParameters drawParams})
  {
    if (coords.value != null)
    {
      if (!isDragging.value && isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!))
      {
        IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
        if (toolPainter != null)
        {
          toolPainter.drawCursor(
              drawParams: drawParams);
        }
        else
        {
          //TODO TEMP
          drawParams.paint.style = PaintingStyle.fill;
          drawParams.paint.color = Colors.red;
          drawParams.canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), 10, drawParams.paint);
        }
      }
      else
      {
        drawParams.paint.color = checkerboardColor1;
        drawParams.canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), options.cursorSize + options.cursorBorderWidth, drawParams.paint);
        drawParams.paint.color = checkerboardColor2;
        drawParams.canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), options.cursorSize, drawParams.paint);
      }
    }
  }

  void _drawLayers({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    //TODO temp
    final double extension = 0.1;
    final List<LayerState> layers = appState.layers.value;
    for (int x = drawParams.drawingStart.x; x < drawParams.drawingEnd.x; x++)
    {
      for (int y = drawParams.drawingStart.y; y < drawParams.drawingEnd.y; y++)
      {
        for (int i = 0; i < layers.length; i++)
        {
          if (layers[i].visibilityState.value == LayerVisibilityState.visible) {
            ColorReference? layerColor = layers[i].data[x][y];
            if (layerColor != null) {
              drawParams.paint.color =
                  layerColor.ramp.colors[layerColor.colorIndex].value.color;
              drawParams.canvas.drawRect(Rect.fromLTWH(offset.value.dx + (x * pxlSzDbl) - extension,
                  offset.value.dy + (y * pxlSzDbl) - extension, pxlSzDbl + (2.0 * extension), pxlSzDbl + (2.0 * extension)), drawParams.paint);
              break;
            }
          }
        }
      }
    }
  }

  void _drawCheckerboard({required final DrawingParameters drawParams})
  {
    bool rowFlip = false;
    bool colFlip = false;
    //TODO THIS FORMULA NEEDS TO BE ADJUSTED
   double cbSizeDbl = (drawParams.pixelSize / 2).clamp(8.0, 64.0);

    for (int i = drawParams.drawingStart.x * drawParams.pixelSize; i < drawParams.drawingEnd.x * drawParams.pixelSize; i += cbSizeDbl.floor())
    {
      colFlip = rowFlip;
      for (int j = drawParams.drawingStart.y * drawParams.pixelSize; j < drawParams.drawingEnd.y * drawParams.pixelSize; j += cbSizeDbl.floor())
      {
        drawParams.paint.color = colFlip ? checkerboardColor1 : checkerboardColor2;
        double width = cbSizeDbl;
        double height = cbSizeDbl;
        if (i + cbSizeDbl > drawParams.scaledCanvasSize.x)
        {
          width = drawParams.scaledCanvasSize.x - i.toDouble();
        }

        if (j + cbSizeDbl > drawParams.scaledCanvasSize.y)
        {
          height = drawParams.scaledCanvasSize.y - j.toDouble();
        }

        drawParams.canvas.drawRect(
          Rect.fromLTWH(offset.value.dx + i, offset.value.dy + j , width, height),
          drawParams.paint,
        );

        colFlip = !colFlip;
      }
      rowFlip = !rowFlip;
    }

    /*paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    paint.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(offset.value.dx - 4, offset.value.dy - 4 , scaledCanvasWidth + 8, scaledCanvasHeight + 6),
      paint,
    );*/
  }


  static int getClosestPixel({required double value, required double pixelSize})
  {
    double remainder = value % pixelSize;
    double lowerMultiple = value - remainder;
    double upperMultiple = value + (pixelSize - remainder);
    return (value - lowerMultiple) <= (upperMultiple - value) ? (lowerMultiple / pixelSize).round()  : (upperMultiple / pixelSize).round();
  }




  static bool isOnCanvas({required final DrawingParameters drawParams, required final CoordinateSetD testCoords})
  {
    bool isOn = false;
    if (testCoords.x >= drawParams.offset.dx && testCoords.x < drawParams.offset.dx + drawParams.scaledCanvasSize.x && testCoords.y >= drawParams.offset.dy && testCoords.y < drawParams.offset.dy + drawParams.scaledCanvasSize.y)
    {
      isOn = true;
    }
    return isOn;
  }



  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

