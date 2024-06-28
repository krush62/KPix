import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/font_manager.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class FontPainter extends IToolPainter
{
  FontPainter({required super.painterOptions});

  final TextOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.textOptions;
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  String _currentText = "";
  final Set<CoordinateSetI> _textContent = {};
  bool _down = false;


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
      _cursorStartPos.x = drawParams.offset.dx + ((_cursorPosNorm.x) * drawParams.pixelSize);
      _cursorStartPos.y = drawParams.offset.dy + ((_cursorPosNorm.y) * drawParams.pixelSize);
    }

    if (_currentText != _options.text.value || _oldCursorPos != _cursorPosNorm)
    {
      _textContent.clear();
      final KFont currentFont = _options.fontManager.getFont(_options.font.value!);
      int offset = 0;
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
                    _textContent.add(CoordinateSetI(x: _cursorPosNorm.x + offset + (x * _options.size.value) + a, y: _cursorPosNorm.y + (y * _options.size.value) + b));
                  }
                }
              }
            }
          }
          offset += ((glyph.width + 1) * _options.size.value);
        }
      }
      _currentText = _options.text.value;
    }

    if (drawParams.primaryDown && !_down)
    {
      _down = true;
    }
    else if (!drawParams.primaryDown && _down)
    {
      _dump(drawParams: drawParams);
      _down = false;
    }

    _oldCursorPos.x = _cursorPosNorm.x;
    _oldCursorPos.y = _cursorPosNorm.y;

  }

  void _dump({required final DrawingParameters drawParams})
  {
    if (_textContent.isNotEmpty)
    {
      final HashMap<CoordinateSetI, ColorReference> drawingPixels = getPixelsToDraw(coords: _textContent, canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: _shaderOptions);
      if (!appState.selectionState.selection.isEmpty())
      {
        appState.selectionState.selection.addDirectlyAll(drawingPixels);
      }
      else
      {
        drawParams.currentLayer.setDataAll(drawingPixels);
      }
    }
  }

  @override
  void drawCursorOutline({required DrawingParameters drawParams})
  {

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (-2 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (-1 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (-1 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (-2 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize)), drawParams.paint);
    drawParams.canvas.drawLine(Offset(_cursorStartPos.x + (-1 * painterOptions.cursorSize), _cursorStartPos.y + (-1 * painterOptions.cursorSize)), Offset(_cursorStartPos.x + (-1 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize)), drawParams.paint);

  }

  @override
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawPars})
  {
    if(appState.selectedColor.value != null && drawPars.cursorPos != null)
    {
      return getPixelsToDraw(coords: _textContent, canvasSize: drawPars.canvasSize, currentLayer: drawPars.currentLayer, selectedColor: appState.selectedColor.value!, selection: appState.selectionState, shaderOptions: _shaderOptions);
    }
    else
    {
      return super.getCursorContent(drawPars: drawPars);
    }
  }

}