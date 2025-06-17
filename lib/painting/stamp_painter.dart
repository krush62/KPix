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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';

class StampPainter extends IToolPainter
{
  StampPainter({required super.painterOptions});

  final StampOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.stampOptions;
  final StampManager _manager = GetIt.I.get<StampManager>();
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI _oldCursorPos = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetD _cursorStartPos = CoordinateSetD(x: 0.0, y: 0.0);
  bool _down = false;
  final HashMap<CoordinateSetI, int> _stampData = HashMap<CoordinateSetI, int>();
  int _previousSize = -1;
  bool _lastShadingEnabled = false;
  ShaderDirection _lastShadingDirection = ShaderDirection.left;
  bool _lastShadingCurrentRamp = false;
  ColorReference? _lastColorSelection;

  @override
  void calculate({required final DrawingParameters drawParams})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    if (drawParams.cursorPos != null)
    {
      _cursorPosNorm.x = IToolPainter.getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: effPxlSize,)
          ;
      _cursorPosNorm.y = IToolPainter.getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: effPxlSize,)
          ;
      _cursorStartPos.x = drawParams.offset.dx + ((_cursorPosNorm.x) * effPxlSize);
      _cursorStartPos.y = drawParams.offset.dy + ((_cursorPosNorm.y) * effPxlSize);
    }

    if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer!.lockState.value != LayerLockState.locked && drawParams.currentRasterLayer!.visibilityState.value != LayerVisibilityState.hidden)
    {
      final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;

      final bool shouldUpdate =
        _oldCursorPos != _cursorPosNorm ||
        _previousSize != _options.scale.value ||
        _lastShadingEnabled != shaderOptions.isEnabled.value ||
        _lastShadingCurrentRamp != shaderOptions.onlyCurrentRampEnabled.value ||
        _lastShadingDirection != shaderOptions.shaderDirection.value ||
        _lastColorSelection != appState.selectedColor;

      if (shouldUpdate && _manager.selectedStamp.value != null)
      {
        _stampData.clear();
        final StampManagerEntryData currentStamp = _manager.selectedStamp.value!;
        for (final MapEntry<CoordinateSetI, int> entry in currentStamp.data.entries)
        {
          int stampX = entry.key.x - currentStamp.width;
          int stampY = entry.key.y - currentStamp.height;
          if (_options.flipH.value)
          {
            stampX = -(stampX + currentStamp.width) - 1;
          }
          if (_options.flipV.value)
          {
            stampY = -(stampY + currentStamp.height) - 1;
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

        CoordinateColorMap cursorPixels = CoordinateColorMap();
        if (rasterLayer is DrawingLayerState)
        {
          cursorPixels = getStampPixelsToDraw(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, stampData: _stampData, selection: appState.selectionState, shaderOptions: shaderOptions, selectedColor: appState.selectedColor!, withShadingLayers: true);
        }
        else if (rasterLayer is ShadingLayerState)
        {
          cursorPixels = getStampPixelsToDrawForShading(canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, stampData: _stampData, shaderOptions: shaderOptions);
        }


        rasterizePixels(drawingPixels: cursorPixels, currentLayer: rasterLayer).then((final ContentRasterSet? rasterSet) {
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
        if (rasterLayer is DrawingLayerState)
        {
          _dump(canvasSize: drawParams.canvasSize, drawingLayer: rasterLayer);
        }
        else if (rasterLayer is ShadingLayerState)
        {
          dumpStampShading(shadingLayer: rasterLayer, stampData: _stampData, shaderOptions: shaderOptions);
        }

        _down = false;
      }
    }

    _oldCursorPos.x = _cursorPosNorm.x;
    _oldCursorPos.y = _cursorPosNorm.y;
    _lastShadingEnabled = shaderOptions.isEnabled.value;
    _lastShadingCurrentRamp = shaderOptions.onlyCurrentRampEnabled.value;
    _lastShadingDirection = shaderOptions.shaderDirection.value;
    _lastColorSelection = appState.selectedColor;

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
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    final Path path = Path();
    path.moveTo(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (0 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (5 * painterOptions.cursorSize), _cursorStartPos.y + (0 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (5 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (3 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (4 * painterOptions.cursorSize), _cursorStartPos.y + (4 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (1 * painterOptions.cursorSize), _cursorStartPos.y + (4 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (2 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (1 * painterOptions.cursorSize));
    path.lineTo(_cursorStartPos.x + (0 * painterOptions.cursorSize), _cursorStartPos.y + (0 * painterOptions.cursorSize));

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawPath(path, drawParams.paint);

    if (drawParams.currentRasterLayer != null && drawParams.currentRasterLayer is DrawingLayerState && _manager.selectedStamp.value != null)
    {
      final StampManagerEntryData currentStamp = _manager.selectedStamp.value!;
      final CoordinateSetD cursorPos = CoordinateSetD(
          x: drawParams.offset.dx + _cursorPosNorm.x * effPxlSize,
          y: drawParams.offset.dy + _cursorPosNorm.y * effPxlSize,);
      drawParams.paint.style = PaintingStyle.stroke;
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
      drawParams.paint.color = blackToolAlphaColor;
      drawParams.canvas.drawRect(Rect.fromLTWH(cursorPos.x - (currentStamp.width * effPxlSize * _options.scale.value), cursorPos.y - (currentStamp.height * effPxlSize * _options.scale.value), currentStamp.width * _options.scale.value * effPxlSize, currentStamp.height * _options.scale.value * effPxlSize), drawParams.paint);
      drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
      drawParams.paint.color = whiteToolAlphaColor;
      drawParams.canvas.drawRect(Rect.fromLTWH(cursorPos.x - (currentStamp.width * effPxlSize * _options.scale.value), cursorPos.y - (currentStamp.height * effPxlSize * _options.scale.value), currentStamp.width * _options.scale.value * effPxlSize, currentStamp.height * _options.scale.value * effPxlSize), drawParams.paint);
    }
  }

  @override
  void setStatusBarData({required final DrawingParameters drawParams})
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
