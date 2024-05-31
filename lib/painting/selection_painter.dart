import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/kpix_painter.dart';

class SelectionPainter extends IToolPainter
{

  @override
  void drawTool({required Canvas canvas,
    required Paint paint,
    required int pixelSize,
    required int scaledCanvasWidth,
    required int scaledCanvasHeight,
    required Offset offset,
    required Offset primaryPressStart,
    required bool primaryDown,
    required CoordinateSetD coords})
  {
    if (primaryDown && KPixPainter.isOnCanvas(pos: CoordinateSetD(x: primaryPressStart.dx, y: primaryPressStart.dy), scaledCanvasWidth: scaledCanvasWidth, scaledCanvasHeight: scaledCanvasHeight, offset: offset))
    {
      paint.style = PaintingStyle.stroke;
      //TODO magic numbers and values
      paint.strokeWidth = 4;
      final CoordinateSetD cursorStartPos = CoordinateSetD(
          x: offset.dx + KPixPainter.getClosestPixel(value: primaryPressStart.dx - offset.dx, pixelSize: pixelSize.toDouble()),
          y: offset.dy + KPixPainter.getClosestPixel(value: primaryPressStart.dy - offset.dy, pixelSize: pixelSize.toDouble()));
      final CoordinateSetD cursorEndPos = CoordinateSetD(
          x: offset.dx + KPixPainter.getClosestPixel(value: coords.x - offset.dx, pixelSize: pixelSize.toDouble()),
          y: offset.dy + KPixPainter.getClosestPixel(value: coords.y - offset.dy, pixelSize: pixelSize.toDouble()));

      //TODO magic
      const double segmentLength = 8.0;

      CoordinateSetD startPos = CoordinateSetD(x: cursorStartPos.x < cursorEndPos.x ? cursorStartPos.x : cursorEndPos.x, y: cursorStartPos.y < cursorEndPos.y ? cursorStartPos.y : cursorEndPos.y);
      CoordinateSetD endPos = CoordinateSetD(x: cursorStartPos.x < cursorEndPos.x ? cursorEndPos.x : cursorStartPos.x, y: cursorStartPos.y < cursorEndPos.y ? cursorEndPos.y : cursorStartPos.y);

      bool colorFlip = false;

      for (double i = startPos.x; i < endPos.x; i += segmentLength)
      {
        //TODO magic
        paint.color = colorFlip ? Colors.black : Colors.white;
        double end = (i + segmentLength) <= endPos.x ? i + segmentLength : endPos.x;
        canvas.drawLine(Offset(i, startPos.y), Offset(end, startPos.y), paint);
        canvas.drawLine(Offset(i, endPos.y), Offset(end, endPos.y), paint);
        colorFlip = !colorFlip;
      }

      colorFlip = false;

      for (double i = startPos.y; i < endPos.y; i += segmentLength)
      {
        //TODO magic
        paint.color = colorFlip ? Colors.black : Colors.white;
        double end = (i + segmentLength) <= endPos.y ? i + segmentLength : endPos.y;
        canvas.drawLine(Offset(startPos.x, i), Offset(startPos.x, end), paint);
        canvas.drawLine(Offset(endPos.x, i), Offset(endPos.x, end), paint);
        colorFlip = !colorFlip;
      }
    }
  }

  @override
  void drawCursor({
    required Canvas canvas,
    required Paint paint,
    required Offset offset,
    required bool primaryDown,
    required CoordinateSetD coords,
    required int pixelSize})
  {
    if (!primaryDown)
    {
      paint.style = PaintingStyle.stroke;
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: offset.dx + KPixPainter.getClosestPixel(
              value: coords.x - offset.dx,
              pixelSize: pixelSize.toDouble()),
          y: offset.dy + KPixPainter.getClosestPixel(
              value: coords.y - offset.dy,
              pixelSize: pixelSize.toDouble()));
      //TODO magic
      paint.color = Colors.black;
      canvas.drawLine(Offset(cursorPos.x, cursorPos.y),
          Offset(cursorPos.x + pixelSize, cursorPos.y), paint);
      canvas.drawLine(Offset(cursorPos.x, cursorPos.y + pixelSize),
          Offset(cursorPos.x + pixelSize, cursorPos.y + pixelSize),
          paint);
      //TODO magic
      paint.color = Colors.white;
      canvas.drawLine(Offset(cursorPos.x, cursorPos.y),
          Offset(cursorPos.x, cursorPos.y + pixelSize), paint);
      canvas.drawLine(Offset(cursorPos.x + pixelSize, cursorPos.y),
          Offset(cursorPos.x + pixelSize, cursorPos.y + pixelSize),
          paint);
    }

  }
}