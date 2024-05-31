import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/canvas_widget.dart';

abstract class IToolPainter
{
  void drawTool({
    required Canvas canvas,
    required Paint paint,
    required int pixelSize,
    required int scaledCanvasWidth,
    required int scaledCanvasHeight,
    required Offset offset,
    required Offset primaryPressStart,
    required bool primaryDown,
    required CoordinateSetD coords});

  void drawCursor({required Canvas canvas,
      required Paint paint,
      required Offset offset,
      required bool primaryDown,
      required CoordinateSetD coords,
      required int pixelSize});
}

class KPixPainterOptions
{
  final int checkerBoardSize;
  final double cursorSize;
  final double cursorBorderWidth;


  KPixPainterOptions({
    required this.checkerBoardSize,
    required this.cursorSize,
    required this.cursorBorderWidth
  });
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
    final int zoomLevelFactor = appState.getZoomLevel() ~/ 100;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final int scaledCanvasWidth = appState.canvasWidth * zoomLevelFactor;
    final int scaledCanvasHeight = appState.canvasHeight * zoomLevelFactor;

    _drawCheckerboard(canvas: canvas, paint: paint, scaledCanvasWidth: scaledCanvasWidth, scaledCanvasHeight: scaledCanvasHeight);
    _drawLayers(canvas: canvas, paint: paint, pixelSize: zoomLevelFactor);
    _drawToolOverlay(canvas: canvas, paint: paint, pixelSize: zoomLevelFactor, scaledCanvasWidth: scaledCanvasWidth, scaledCanvasHeight: scaledCanvasHeight);
    _drawCursor(canvas: canvas, paint: paint, pixelSize: zoomLevelFactor, scaledCanvasWidth: scaledCanvasWidth, scaledCanvasHeight: scaledCanvasHeight);

  }



  void _drawToolOverlay({required final Canvas canvas, required final Paint paint, required final int pixelSize, required final int scaledCanvasWidth, required final int scaledCanvasHeight})
  {
    //TODO
    if (coords.value != null)
    {
      IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
      toolPainter?.drawTool(
          canvas: canvas,
          paint: paint,
          pixelSize: pixelSize,
          scaledCanvasWidth: scaledCanvasWidth,
          scaledCanvasHeight: scaledCanvasHeight,
          offset: offset.value,
          primaryPressStart: primaryPressStart.value,
          primaryDown: primaryDown.value,
          coords: coords.value!);
    }
    //FOR SELECTION

  }

  void _drawCursor({required final Canvas canvas, required final Paint paint, required final int pixelSize, required final int scaledCanvasWidth, required final int scaledCanvasHeight})
  {

    if (coords.value != null)
    {
      if (!isDragging.value && isOnCanvas(pos: coords.value!, scaledCanvasWidth: scaledCanvasWidth, scaledCanvasHeight: scaledCanvasHeight, offset: offset.value))
      {
        IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
        if (toolPainter != null)
        {
          toolPainter.drawCursor(
              canvas: canvas,
              paint: paint,
              offset: offset.value,
              primaryDown: primaryDown.value,
              coords: coords.value!,
              pixelSize: pixelSize);
        }
        else
        {
          //TODO TEMP
          paint.style = PaintingStyle.fill;
          paint.color = Colors.red;
          canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), 10, paint);
        }
      }
      else
      {
        paint.color = checkerboardColor1;
        canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), options.cursorSize + options.cursorBorderWidth, paint);
        paint.color = checkerboardColor2;
        canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), options.cursorSize, paint);
      }
    }
  }

  void _drawLayers({required final Canvas canvas, required final Paint paint, required final int pixelSize})
  {
    final double pxlSzDbl = pixelSize.toDouble();
    final List<LayerState> layers = appState.layers.value;
    for (int x = 0; x < appState.canvasWidth; x++)
    {
      for (int y = 0; y < appState.canvasHeight; y++)
      {
        for (int i = 0; i < layers.length; i++)
        {
          if (layers[i].visibilityState.value == LayerVisibilityState.visible) {
            ColorReference? layerColor = layers[i].data[x][y];
            if (layerColor != null) {
              paint.color =
                  layerColor.ramp.colors[layerColor.colorIndex].value.color;
              canvas.drawRect(Rect.fromLTWH(offset.value.dx + (x * pxlSzDbl),
                  offset.value.dy + (y * pxlSzDbl), pxlSzDbl, pxlSzDbl), paint);
              break;
            }
          }
        }
      }
    }
  }

  void _drawCheckerboard({required final Canvas canvas, required final Paint paint, required final int scaledCanvasWidth, required final int scaledCanvasHeight})
  {
    bool rowFlip = false;
    bool colFlip = false;
    final double cbSizeDbl = options.checkerBoardSize.toDouble();
    for (int i = 0; i < scaledCanvasWidth; i += options.checkerBoardSize)
    {
      colFlip = rowFlip;
      for (int j = 0; j < scaledCanvasHeight; j += options.checkerBoardSize)
      {
        paint.color = colFlip ? checkerboardColor1 : checkerboardColor2;
        double width = cbSizeDbl;
        double height = cbSizeDbl;
        if (i + cbSizeDbl > scaledCanvasWidth)
        {
          width = scaledCanvasWidth - i.toDouble();
        }

        if (j + cbSizeDbl > scaledCanvasHeight)
        {
          height = scaledCanvasHeight - j.toDouble();
        }

        canvas.drawRect(
          Rect.fromLTWH(offset.value.dx + i, offset.value.dy + j , width, height),
          paint,
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


  static double getClosestPixel({required double value, required double pixelSize})
  {
    double remainder = value % pixelSize.toDouble();
    double lowerMultiple = value - remainder;
    double upperMultiple = value + (pixelSize - remainder);
    return (value - lowerMultiple) <= (upperMultiple - value) ? lowerMultiple : upperMultiple;
  }




  static bool isOnCanvas({required final CoordinateSetD pos, required final int scaledCanvasWidth, required final int scaledCanvasHeight, required final Offset offset})
  {
    bool isOn = false;
    if (pos.x >= offset.dx && pos.x < offset.dx + scaledCanvasWidth && pos.y >= offset.dy && pos.y < offset.dy + scaledCanvasHeight)
    {
      isOn = true;
    }
    return isOn;
  }



  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

