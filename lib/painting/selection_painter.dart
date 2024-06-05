import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';

class SelectionPainter extends IToolPainter
{
  final CoordinateSetI selectionStart = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI selectionEnd = CoordinateSetI(x: 0, y: 0);
  bool hasNewSelection = false;
  final SelectOptions options = GetIt.I.get<PreferenceManager>().toolOptions.selectOptions;
  bool movementStarted = false;

  SelectionPainter({required super.painterOptions});

  @override
  void drawTool({required final DrawingParameters drawParams})
  {
    if (drawParams.primaryDown &&
        drawParams.cursorPos != null &&
        KPixPainter.isOnCanvas
        (
          drawParams: drawParams,
          testCoords: CoordinateSetD(
              x: drawParams.primaryPressStart.dx,
              y: drawParams.primaryPressStart.dy)))
    {
      CoordinateSetI normalizedStart = CoordinateSetI(
          x: KPixPainter.getClosestPixel(
              value:
              drawParams.primaryPressStart.dx - drawParams.offset.dx,
              pixelSize: drawParams.pixelSize.toDouble())
              .round(),
          y: KPixPainter.getClosestPixel(
              value:
              drawParams.primaryPressStart.dy - drawParams.offset.dy,
              pixelSize: drawParams.pixelSize.toDouble())
              .round());
      CoordinateSetI normalizedEnd = CoordinateSetI(
          x: KPixPainter.getClosestPixel(
              value: drawParams.cursorPos!.x - drawParams.offset.dx,
              pixelSize: drawParams.pixelSize.toDouble())
              .round(),
          y: KPixPainter.getClosestPixel(
              value: drawParams.cursorPos!.y - drawParams.offset.dy,
              pixelSize: drawParams.pixelSize.toDouble())
              .round());


      //MOVE
      if (movementStarted || ((options.mode == SelectionMode.replace || options.mode == SelectionMode.add) && appState.selectionState.selection.contains(normalizedStart)))
      {
        movementStarted = true;
        appState.selectionState.setOffset(CoordinateSetI(x: normalizedEnd.x - normalizedStart.x, y: normalizedEnd.y - normalizedStart.y));
      }
      else //DRAW
      {
        drawParams.paint.style = PaintingStyle.stroke;
        drawParams.paint.strokeWidth = painterOptions.selectionDashStrokeWidth;


        selectionStart.x = normalizedStart.x < normalizedEnd.x
            ? normalizedStart.x
            : normalizedEnd.x;
        selectionStart.y = normalizedStart.y < normalizedEnd.y
            ? normalizedStart.y
            : normalizedEnd.y;
        selectionEnd.x = normalizedStart.x < normalizedEnd.x
            ? (normalizedEnd.x)
            : (normalizedStart.x);
        selectionEnd.y = normalizedStart.y < normalizedEnd.y
            ? (normalizedEnd.y)
            : (normalizedStart.y);

        if (selectionStart.x < 0) {
          selectionStart.x = 0;
        }

        if (selectionStart.y < 0) {
          selectionStart.y = 0;
        }

        if (selectionEnd.x > appState.canvasWidth - 1) {
          selectionEnd.x = appState.canvasWidth - 1;
        }

        if (selectionEnd.y > appState.canvasHeight - 1) {
          selectionEnd.y = appState.canvasHeight - 1;
        }

        if (options.keepAspectRatio) {
          final int width = selectionEnd.x - selectionStart.x;
          final int height = selectionEnd.y - selectionStart.y;
          if (width > height) {
            if (normalizedStart.x < normalizedEnd.x) {
              selectionEnd.x = selectionStart.x + height;
            } else {
              selectionStart.x = selectionEnd.x - height;
            }
          } else {
            if (normalizedStart.y < normalizedEnd.y) {
              selectionEnd.y = selectionStart.y + width;
            } else {
              selectionStart.y = selectionEnd.y - width;
            }
          }
        }
        hasNewSelection = true;


        final CoordinateSetD cursorStartPos = CoordinateSetD(
            x: drawParams.offset.dx + selectionStart.x * drawParams.pixelSize,
            y: drawParams.offset.dy + selectionStart.y * drawParams.pixelSize);
        final CoordinateSetD cursorEndPos = CoordinateSetD(
            x: drawParams.offset.dx + (selectionEnd.x + 1) * drawParams.pixelSize,
            y: drawParams.offset.dy +
                (selectionEnd.y + 1) * drawParams.pixelSize);

        bool colorFlip = false;

        if (options.shape == SelectShape.rectangle) {
          //DRAW DASHED LINE
          for (double i = cursorStartPos.x; i < cursorEndPos.x;
          i += painterOptions.selectionDashSegmentLength) {
            drawParams.paint.color = colorFlip ? Colors.black : Colors.white;
            double end = (i + painterOptions.selectionDashSegmentLength) <= cursorEndPos.x
                ? i + painterOptions.selectionDashSegmentLength
                : cursorEndPos.x;
            drawParams.canvas.drawLine(
                Offset(i, cursorStartPos.y), Offset(end, cursorStartPos.y),
                drawParams.paint);
            drawParams.canvas.drawLine(
                Offset(i, cursorEndPos.y), Offset(end, cursorEndPos.y),
                drawParams.paint);
            colorFlip = !colorFlip;
          }

          colorFlip = false;

          for (double i = cursorStartPos.y; i < cursorEndPos.y;
          i += painterOptions.selectionDashSegmentLength) {
            drawParams.paint.color = colorFlip ? Colors.black : Colors.white;
            double end = (i + painterOptions.selectionDashSegmentLength) <= cursorEndPos.y
                ? i + painterOptions.selectionDashSegmentLength
                : cursorEndPos.y;
            drawParams.canvas.drawLine(
                Offset(cursorStartPos.x, i), Offset(cursorStartPos.x, end),
                drawParams.paint);
            drawParams.canvas.drawLine(
                Offset(cursorEndPos.x, i), Offset(cursorEndPos.x, end),
                drawParams.paint);
            colorFlip = !colorFlip;
          }
        }
        else if (options.shape == SelectShape.ellipse)
        {
          final double segmentAngle = (2 * pi) / painterOptions.selectionCircleSegmentCount;
          for (int i = 0; i < painterOptions.selectionCircleSegmentCount; i++) {
            drawParams.paint.color = colorFlip ? Colors.black : Colors.white;
            drawParams.canvas.drawArc(Rect.fromLTRB(
                cursorStartPos.x, cursorStartPos.y, cursorEndPos.x,
                cursorEndPos.y), i * segmentAngle, segmentAngle, false, drawParams.paint);
            colorFlip = !colorFlip;
          }
        }

      }
    }
    else //NO BUTTON PRESS AND NOT ON CANVAS
    {
      movementStarted = false;
      appState.selectionState.finishMovement();
    }
  }

  @override
  void drawCursor({
    required DrawingParameters drawParams})
  {
    if (!drawParams.primaryDown)
    {
      drawParams.paint.style = PaintingStyle.stroke;
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + KPixPainter.getClosestPixel(
              value: drawParams.cursorPos!.x - drawParams.offset.dx,
              pixelSize: drawParams.pixelSize.toDouble()) * drawParams.pixelSize,
          y: drawParams.offset.dy + KPixPainter.getClosestPixel(
              value: drawParams.cursorPos!.y - drawParams.offset.dy,
              pixelSize: drawParams.pixelSize.toDouble()) * drawParams.pixelSize);
      drawParams.paint.strokeWidth = painterOptions.selectionCursorStrokeWidth;
      drawParams.paint.color = Colors.black;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x - painterOptions.selectionCursorStrokeWidth, cursorPos.y - painterOptions.selectionCursorStrokeWidth, cursorPos.x + drawParams.pixelSize + painterOptions.selectionCursorStrokeWidth , cursorPos.y + drawParams.pixelSize + painterOptions.selectionCursorStrokeWidth), drawParams.paint);
      drawParams.paint.color = Colors.white;
      drawParams.canvas.drawRect(Rect.fromLTRB(cursorPos.x, cursorPos.y, cursorPos.x + drawParams.pixelSize , cursorPos.y + drawParams.pixelSize), drawParams.paint);
    }
  }
}