import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/stamp_manager.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class StampPainter extends IToolPainter
{
  StampPainter({required super.painterOptions});

  final StampOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.stampOptions;
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  bool _down = false;
  final HashMap<CoordinateSetI, int> _stampData = HashMap();

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

    if (_oldCursorPos != _cursorPosNorm)
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
    final HashMap<CoordinateSetI, ColorReference> drawingPixels = getStampPixelsToDraw(canvasSize: drawParams.canvasSize, currentLayer: drawParams.currentLayer, stampData: _stampData, selection: appState.selectionState, shaderOptions: _shaderOptions, selectedColor: appState.selectedColor.value!);
    if (!appState.selectionState.selection.isEmpty())
    {
      appState.selectionState.selection.addDirectlyAll(drawingPixels);
    }
    /*else if (!_shaderOptions.isEnabled.value)
    {
      appState.selectionState.add(data: drawingPixels, notify: false);
    }*/
    else
    {
      drawParams.currentLayer.setDataAll(drawingPixels);
    }
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
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawPars})
  {
    if(appState.selectedColor.value != null && drawPars.cursorPos != null)
    {
      return getStampPixelsToDraw(canvasSize: drawPars.canvasSize, currentLayer: drawPars.currentLayer, stampData: _stampData, selection: appState.selectionState, shaderOptions: _shaderOptions, selectedColor: appState.selectedColor.value!);
    }
    else
    {
      return super.getCursorContent(drawPars: drawPars);
    }
  }

}