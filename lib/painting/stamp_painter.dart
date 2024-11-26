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

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/util/typedefs.dart';

class StampPainter extends IToolPainter
{
  StampPainter({required super.painterOptions});

  final StampOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.stampOptions;
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  bool _down = false;
  final HashMap<CoordinateSetI, int> _stampData = HashMap();
  int _previousSize = -1;

  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null)
    {
      _cursorPosNorm.x = getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      _cursorPosNorm.y = getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      _cursorStartPos.x = drawParams.offset.dx + ((_cursorPosNorm.x) * drawParams.pixelSize);
      _cursorStartPos.y = drawParams.offset.dy + ((_cursorPosNorm.y) * drawParams.pixelSize);
    }

    if (drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden)
    {
      if (_oldCursorPos != _cursorPosNorm || _previousSize != _options.scale.value)
      {
        _stampData.clear();
        final KStamp currentStamp = _options.stampManager.stampMap[_options.stamp.value]!;
        for (final MapEntry<CoordinateSetI, int> entry in currentStamp.data.entries)
        {
          int stampX = entry.key.x;
          int stampY = entry.key.y;
          if (_options.flipH.value)
          {
            stampX = currentStamp.width - stampX;
          }
          if (_options.flipV.value)
          {
            stampY = currentStamp.height - stampY;
          }

          for (int x = 0; x < _options.scale.value; x++)
          {
            for (int y = 0; y < _options.scale.value; y++)
            {
              _stampData[CoordinateSetI(x: _cursorPosNorm.x + (stampX * _options.scale.value) + x, y: _cursorPosNorm.y + (stampY * _options.scale.value) + y)] = entry.value;
            }
          }
        }
        _previousSize = _options.scale.value;

        final CoordinateColorMap cursorPixels = getStampPixelsToDraw(canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, stampData: _stampData, selection: appState.selectionState, shaderOptions: shaderOptions, selectedColor: appState.selectedColor!);
        rasterizeDrawingPixels(drawingPixels: cursorPixels).then((final ContentRasterSet? rasterSet) {
          cursorRaster = rasterSet;
          hasAsyncUpdate = true;
        });


      }

      if (drawParams.primaryDown && !_down)
      {
        _down = true;
      }
      else if (!drawParams.primaryDown && _down)
      {
        _dump(canvasSize: drawParams.canvasSize, drawingLayer: drawParams.currentDrawingLayer!);
        _down = false;
      }
    }

    _oldCursorPos.x = _cursorPosNorm.x;
    _oldCursorPos.y = _cursorPosNorm.y;

    if (drawParams.cursorPos == null)
    {
      cursorRaster = null;
    }

  }

  void _dump({required final CoordinateSetI canvasSize, required final DrawingLayerState drawingLayer})
  {
    final CoordinateColorMap drawingPixels = getStampPixelsToDraw(canvasSize: canvasSize, currentLayer: drawingLayer, stampData: _stampData, selection: appState.selectionState, shaderOptions: shaderOptions, selectedColor: appState.selectedColor!);
    if (!appState.selectionState.selection.isEmpty)
    {
      appState.selectionState.selection.addDirectlyAll(list: drawingPixels);
    }
    /*else if (!_shaderOptions.isEnabled.value)
    {
      appState.selectionState.add(data: drawingPixels, notify: false);
    }*/
    else
    {
      drawingLayer.setDataAll(list: drawingPixels);
    }
    hasHistoryData = true;
  }

  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {
    Path path = Path();
    path.moveTo(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (0 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (-5 * painterOptions.cursorSize), _cursorStartPos.y + (0 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (-5 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (-3 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (-4 * painterOptions.cursorSize), _cursorStartPos.y + (-4 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (-1 * painterOptions.cursorSize), _cursorStartPos.y + (-4 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (-2 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (0 * painterOptions.cursorSize));

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }

  @override
  void setStatusBarData({required DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPos != null ? _cursorPosNorm : null;
  }

  @override
  void reset()
  {
    _down = false;
    _stampData.clear();
    _previousSize = -1;
  }

}