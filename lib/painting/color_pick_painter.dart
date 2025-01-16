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

import 'package:flutter/material.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/util/helper.dart';

class ColorPickPainter extends IToolPainter
{
  ColorPickPainter({required super.painterOptions});
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  ColorReference? selectedColor;


  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.cursorPosNorm != null)
    {
      _cursorStartPos.x = drawParams.offset.dx + ((drawParams.cursorPosNorm!.x + 0.5) * drawParams.pixelSize);
      _cursorStartPos.y = drawParams.offset.dy + ((drawParams.cursorPosNorm!.y + 0.5) * drawParams.pixelSize);

      if (drawParams.secondaryDown || (drawParams.primaryDown && _oldCursorPos != drawParams.cursorPosNorm))
      {
        _oldCursorPos.x = drawParams.cursorPosNorm!.x;
        _oldCursorPos.y = drawParams.cursorPosNorm!.y;
        final ColorReference? colRef = appState.getColorFromImageAtPosition(normPos: drawParams.cursorPosNorm!);
        if (colRef != null && colRef != appState.selectedColor)
        {
          selectedColor = colRef;
        }
      }
    }
  }

  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
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
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPosNorm;
  }
}
