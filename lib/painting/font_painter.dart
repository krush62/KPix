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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
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
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    if (drawParams.cursorPosNorm != null)
    {
      _cursorStartPos.x = drawParams.offset.dx + ((drawParams.cursorPosNorm!.x) * effPxlSize);
      _cursorStartPos.y = drawParams.offset.dy + ((drawParams.cursorPosNorm!.y) * effPxlSize);

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

        CoordinateColorMap cursorPixels = CoordinateColorMap();
        if (drawParams.currentRasterLayer != null)
        {
          final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: _textContent, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
          final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;
          if (rasterLayer is DrawingLayerState)
          {
            cursorPixels = getPixelsToDraw(coords: mirrorPoints, canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
          }
          else if (rasterLayer is ShadingLayerState)
          {
            cursorPixels = getPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, coords: mirrorPoints, shaderOptions: shaderOptions);
          }

          rasterizePixels(drawingPixels: cursorPixels, currentLayer: rasterLayer).then((final ContentRasterSet? rasterSet) {
            cursorRaster = rasterSet;
            hasAsyncUpdate = true;
          });
        }
      }

      //DUMP
      if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer!.lockState.value != LayerLockState.locked && drawParams.currentRasterLayer!.visibilityState.value != LayerVisibilityState.hidden)
      {
        final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;
        if (drawParams.primaryDown && !_down)
        {
          _down = true;
        }
        else if (!drawParams.primaryDown && _down)
        {
          if (_textContent.isNotEmpty)
          {
            final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: _textContent, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
            if (rasterLayer is DrawingLayerState)
            {
              final CoordinateColorMap drawingPixels = getPixelsToDraw(coords: mirrorPoints, canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
              _dumpDrawing(drawParams: drawParams, drawingPixels: drawingPixels);
            }
            else if (rasterLayer is ShadingLayerState)
            {
              dumpShading(shadingLayer: rasterLayer, coordinates: mirrorPoints, shaderOptions: shaderOptions);
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
      if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer is DrawingLayerState)
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
          (drawParams.currentRasterLayer! as DrawingLayerState).setDataAll(list: drawingPixels);
        }
        hasHistoryData = true;
      }
    }

  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final double effPixelSize = drawParams.pixelSize / drawParams.pixelRatio;
    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (painterOptions.cursorSize)), Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (3 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (painterOptions.cursorSize)), Offset(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (3 * painterOptions.cursorSize)), drawParams.paint);

    if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer is DrawingLayerState)
    {
      final KFont currentFont = _options.fontManager.getFont(type: _options.font.value!);
      final int width = _getTextWidth(currentFont: currentFont);

      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + drawParams.cursorPosNorm!.x * effPixelSize,
          y: drawParams.offset.dy + drawParams.cursorPosNorm!.y * effPixelSize,);
      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      final Rect strokeRect = Rect.fromLTWH(
        -(width * effPixelSize * _options.size.value) + cursorPos.x,
        -(currentFont.height * effPixelSize * _options.size.value) + cursorPos.y,
        width * effPixelSize * _options.size.value,
        currentFont.height * effPixelSize * _options.size.value,);

      drawParams.canvas.drawRect(strokeRect, drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawRect(strokeRect, drawParams.paint);
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
