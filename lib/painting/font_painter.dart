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
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class FontPainter extends IToolPainter
{
  FontPainter({required super.painterOptions});

  final TextOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.textOptions;
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  int _previousSize = -1;
  String _currentText = "";
  final Set<CoordinateSetI> _textContent = <CoordinateSetI>{};
  bool _down = false;
  bool _lastShadingEnabled = false;
  ShaderDirection _lastShadingDirection = ShaderDirection.left;
  bool _lastShadingCurrentRamp = false;
  ColorReference? _lastColorSelection;


  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.cursorPosNorm != null)
    {
      _cursorStartPos.x = drawParams.offset.dx + ((drawParams.cursorPosNorm!.x) * drawParams.pixelSize);
      _cursorStartPos.y = drawParams.offset.dy + ((drawParams.cursorPosNorm!.y) * drawParams.pixelSize);

      final bool shouldUpdate =
          _currentText != _options.text.value ||
          _oldCursorPos != drawParams.cursorPosNorm! ||
          _previousSize != _options.size.value ||
          _lastShadingEnabled != shaderOptions.isEnabled.value ||
          _lastShadingCurrentRamp != shaderOptions.onlyCurrentRampEnabled.value ||
          _lastShadingDirection != shaderOptions.shaderDirection.value ||
          _lastColorSelection != appState.selectedColor;

      if (shouldUpdate)
      {
        _textContent.clear();
        final KFont currentFont = _options.fontManager.getFont(type: _options.font.value!);
        int offset = 0;

        final int textWidth = _getTextWidth(currentFont: currentFont);
        for (int i = 0; i < _options.text.value.length; i++)
        {
          final int unicodeVal = _options.text.value.codeUnitAt(i);
          final Glyph? glyph = currentFont.glyphMap[unicodeVal];
          if (glyph != null)
          {
            for (int x = 0; x < glyph.width; x++)
            {
              for (int y = 0; y < currentFont.height; y++)
              {
                final bool valAtPos = glyph.dataMatrix[x][y];
                if (valAtPos)
                {
                  for (int a = 0; a < _options.size.value; a++)
                  {
                    for (int b = 0; b < _options.size.value; b++)
                    {
                      _textContent.add(CoordinateSetI(x: -(textWidth * _options.size.value) + drawParams.cursorPosNorm!.x + offset + (x * _options.size.value) + a, y: -(currentFont.height * _options.size.value) + drawParams.cursorPosNorm!.y + (y * _options.size.value) + b));
                    }
                  }
                }
              }
            }
            offset += (glyph.width + 1) * _options.size.value;
          }
        }
        _currentText = _options.text.value;
        _previousSize = _options.size.value;

        final CoordinateColorMap cursorPixels = drawParams.currentDrawingLayer != null ?
          getPixelsToDraw(coords: _textContent, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions, withShadingLayers: true) :
          getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentShadingLayer!, coords: _textContent, shaderOptions: shaderOptions);
        rasterizeDrawingPixels(drawingPixels: cursorPixels).then((final ContentRasterSet? rasterSet) {
          cursorRaster = rasterSet;
          hasAsyncUpdate = true;
        });
      }

      //DUMP
      if ((drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.lockState.value != LayerLockState.locked && drawParams.currentDrawingLayer!.visibilityState.value != LayerVisibilityState.hidden) ||
          drawParams.currentShadingLayer != null && drawParams.currentShadingLayer!.lockState.value != LayerLockState.locked && drawParams.currentShadingLayer!.visibilityState.value != LayerVisibilityState.hidden)
      {
        if (drawParams.primaryDown && !_down)
        {
          _down = true;
        }
        else if (!drawParams.primaryDown && _down)
        {
          if (_textContent.isNotEmpty)
          {
            if (drawParams.currentDrawingLayer != null)
            {
              final CoordinateColorMap drawingPixels = getPixelsToDraw(coords: _textContent, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentDrawingLayer!, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
              _dumpDrawing(drawParams: drawParams, drawingPixels: drawingPixels);
            }
            else
            {
              dumpShading(shadingLayer: drawParams.currentShadingLayer!, coordinates: _textContent, shaderOptions: shaderOptions);
            }
          }
          _down = false;
        }
      }

      _oldCursorPos.x = drawParams.cursorPosNorm!.x;
      _oldCursorPos.y = drawParams.cursorPosNorm!.y;
      _lastShadingEnabled = shaderOptions.isEnabled.value;
      _lastShadingCurrentRamp = shaderOptions.onlyCurrentRampEnabled.value;
      _lastShadingDirection = shaderOptions.shaderDirection.value;
      _lastColorSelection = appState.selectedColor;

    }
    else
    {
      cursorRaster = null;
    }
  }

  int _getTextWidth({required final KFont currentFont})
  {
    int textWidth = 0;
    for (int i = 0; i < _options.text.value.length; i++)
    {
      final int unicodeVal = _options.text.value.codeUnitAt(i);
      final Glyph? glyph = currentFont.glyphMap[unicodeVal];
      if (glyph != null)
      {
        textWidth += glyph.width + 1;
      }
    }
    return textWidth;
  }

    void _dumpDrawing({required final DrawingParameters drawParams, required final CoordinateColorMap drawingPixels})
    {
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
        drawParams.currentDrawingLayer!.setDataAll(list: drawingPixels);
      }
      hasHistoryData = true;

  }

  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (painterOptions.cursorSize)), Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (3 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (painterOptions.cursorSize)), Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (3 * painterOptions.cursorSize)), drawParams.paint);

    if (drawParams.currentDrawingLayer != null)
    {
      final KFont currentFont = _options.fontManager.getFont(type: _options.font.value!);
      final int width = _getTextWidth(currentFont: currentFont);

      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + drawParams.cursorPosNorm!.x * drawParams.pixelSize,
          y: drawParams.offset.dy + drawParams.cursorPosNorm!.y * drawParams.pixelSize,);
      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawRect(Rect.fromLTWH(-(width * drawParams.pixelSize * _options.size.value).toDouble() + cursorPos.x, -(currentFont.height * drawParams.pixelSize * _options.size.value).toDouble() + cursorPos.y, (width * drawParams.pixelSize * _options.size.value).toDouble(), (currentFont.height * drawParams.pixelSize * _options.size.value).toDouble()), drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawRect(Rect.fromLTWH(-(width * drawParams.pixelSize * _options.size.value).toDouble() + cursorPos.x, -(currentFont.height * drawParams.pixelSize * _options.size.value).toDouble() + cursorPos.y, (width * drawParams.pixelSize * _options.size.value).toDouble(), (currentFont.height * drawParams.pixelSize * _options.size.value).toDouble()), drawParams.paint);
    }
  }

  @override
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPosNorm;
  }

  @override
  void reset()
  {
    _previousSize = -1;
    _currentText = "";
    _textContent.clear();
    _down = false;
  }

}
