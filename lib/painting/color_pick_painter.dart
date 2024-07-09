import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/widgets/layer_widget.dart';

class ColorPickPainter extends IToolPainter
{
  ColorPickPainter({required super.painterOptions});
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  ColorReference? selectedColor;


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
      _cursorStartPos.x = drawParams.offset.dx + ((_cursorPosNorm.x + 0.5) * drawParams.pixelSize);
      _cursorStartPos.y = drawParams.offset.dy + ((_cursorPosNorm.y + 0.5) * drawParams.pixelSize);

      if (drawParams.primaryDown && _oldCursorPos != _cursorPosNorm)
      {
        _oldCursorPos.x = _cursorPosNorm.x;
        _oldCursorPos.y = _cursorPosNorm.y;
        ColorReference? colRef;
        for (final LayerState layer in appState.layers.value)
        {
          if (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.getColorReference(_cursorPosNorm) != null)
          {
            colRef = appState.selectionState.selection.getColorReference(_cursorPosNorm);
            break;
          }
          if (layer.getData(_cursorPosNorm) != null)
          {
            colRef = layer.getData(_cursorPosNorm);
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
    outlinePath.moveTo(_cursorStartPos.x, _cursorStartPos.y);
    outlinePath.lineTo(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y);
    outlinePath.lineTo(_cursorStartPos.x + (3 * painterOptions.cursorSize), _cursorStartPos.y + (-2 * painterOptions.cursorSize));
    outlinePath.lineTo(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (-3 * painterOptions.cursorSize));
    outlinePath.lineTo(_cursorStartPos.x, _cursorStartPos.y + (-1 * painterOptions.cursorSize));
    outlinePath.lineTo(_cursorStartPos.x, _cursorStartPos.y);

    final Path fillPath = Path();
    fillPath.moveTo(_cursorStartPos.x, _cursorStartPos.y);
    fillPath.lineTo(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y);
    fillPath.lineTo(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize));
    fillPath.lineTo(_cursorStartPos.x, _cursorStartPos.y + (-1 * painterOptions.cursorSize));


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

  @override
  void setStatusBarData({required DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPos != null ? _cursorPosNorm : null;
  }

}