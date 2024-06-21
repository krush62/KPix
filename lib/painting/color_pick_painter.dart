import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/widgets/layer_widget.dart';

class ColorPickPainter extends IToolPainter
{
  ColorPickPainter({required super.painterOptions});
  final CoordinateSetI cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  CoordinateSetI oldCursorPos = CoordinateSetI(x: 0, y: 0);
  bool buttonIsDown = false;
  ColorReference? selectedColor;


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
      cursorStartPos.x = drawParams.offset.dx + ((cursorPosNorm.x + 0.5) * drawParams.pixelSize);
      cursorStartPos.y = drawParams.offset.dy + ((cursorPosNorm.y + 0.5) * drawParams.pixelSize);

      if (drawParams.primaryDown && oldCursorPos != cursorPosNorm)
      {
        oldCursorPos = CoordinateSetI.from(cursorPosNorm);
        ColorReference? colRef;
        for (final LayerState layer in appState.layers.value)
        {
          if (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.getColorReference(cursorPosNorm) != null)
          {
            colRef = appState.selectionState.selection.getColorReference(cursorPosNorm);
            break;
          }
          if (layer.getData(cursorPosNorm.x, cursorPosNorm.y) != null)
          {
            colRef = layer.getData(cursorPosNorm.x, cursorPosNorm.y);
            break;
          }
        }
        if (colRef != null && colRef != appState.selectedColor.value)
        {
          selectedColor = colRef;
        }
      }
    }
  }


  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {

    final Path outlinePath = Path();
    outlinePath.moveTo(cursorStartPos.x, cursorStartPos.y);
    outlinePath.lineTo(cursorStartPos.x + (1 * painterOptions.cursorSize), cursorStartPos.y);
    outlinePath.lineTo(cursorStartPos.x + (3 * painterOptions.cursorSize), cursorStartPos.y + (-2 * painterOptions.cursorSize));
    outlinePath.lineTo(cursorStartPos.x + (2 * painterOptions.cursorSize), cursorStartPos.y + (-3 * painterOptions.cursorSize));
    outlinePath.lineTo(cursorStartPos.x, cursorStartPos.y + (-1 * painterOptions.cursorSize));
    outlinePath.lineTo(cursorStartPos.x, cursorStartPos.y);

    final Path fillPath = Path();
    fillPath.moveTo(cursorStartPos.x, cursorStartPos.y);
    fillPath.lineTo(cursorStartPos.x + (1 * painterOptions.cursorSize), cursorStartPos.y);
    fillPath.lineTo(cursorStartPos.x + (2 * painterOptions.cursorSize), cursorStartPos.y + (-1 * painterOptions.cursorSize));
    fillPath.lineTo(cursorStartPos.x, cursorStartPos.y + (-1 * painterOptions.cursorSize));


    drawParams.paint.style = PaintingStyle.fill;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(fillPath, drawParams.paint);

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(outlinePath, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawPath(outlinePath, drawParams.paint);
  }

}