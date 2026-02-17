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

  static const List<MapEntry<int, int>> _symbolPathOutline = <MapEntry<int, int>>[
    MapEntry<int, int>(0, 0),
    MapEntry<int, int>(1, 0),
    MapEntry<int, int>(3, -2),
    MapEntry<int, int>(2, -3),
    MapEntry<int, int>(0, -1),
    MapEntry<int, int>(0, 0),
  ];

  static const List<MapEntry<int, int>> _symbolPathFill = <MapEntry<int, int>>[
    MapEntry<int, int>(0, 0),
    MapEntry<int, int>(1, 0),
    MapEntry<int, int>(2, -1),
    MapEntry<int, int>(0, -1),
  ];


  @override
  void calculate({required final DrawingParameters drawParams})
  {
    final double effPixelSize = drawParams.pixelSize / drawParams.pixelRatio;
    if (drawParams.cursorPosNorm != null)
    {
      _cursorStartPos.x = drawParams.offset.dx + ((drawParams.cursorPosNorm!.x + 0.5) * effPixelSize);
      _cursorStartPos.y = drawParams.offset.dy + ((drawParams.cursorPosNorm!.y + 0.5) * effPixelSize);

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

    final Path outlinePath = getPathFromList(pointList: _symbolPathOutline, offsetPos: _cursorStartPos, scaling: painterOptions.cursorSize);
    final Path fillPath =  getPathFromList(pointList: _symbolPathFill, offsetPos: _cursorStartPos, scaling: painterOptions.cursorSize);


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
