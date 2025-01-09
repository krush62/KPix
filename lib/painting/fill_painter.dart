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
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class FillPainter extends IToolPainter
{
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);

  FillPainter({required super.painterOptions});
  final FillOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.fillOptions;
  bool _isDown = false;
  bool _shouldDraw = false;

  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null)
    {
      _cursorPosNorm.x = getClosestPixel(value: drawParams.cursorPos!.x - drawParams.offset.dx,pixelSize: drawParams.pixelSize.toDouble());
      _cursorPosNorm.y = getClosestPixel(value: drawParams.cursorPos!.y - drawParams.offset.dy,pixelSize: drawParams.pixelSize.toDouble());
    }
    if (drawParams.primaryDown && !_isDown && KPixPainter.isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!))
    {
      _shouldDraw = true;
      _isDown = true;
    }
    else if (_isDown && !drawParams.primaryDown)
    {
      _isDown = false;
    }
  }


  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    assert(drawParams.cursorPos != null);

    final CoordinateSetD cursorPos = CoordinateSetD(
        x: drawParams.offset.dx + (_cursorPosNorm.x + 0.5) * drawParams.pixelSize,
        y: drawParams.offset.dy + (_cursorPosNorm.y + 0.5) * drawParams.pixelSize,);
    final Path outlinePath = Path();
    outlinePath.moveTo(cursorPos.x, cursorPos.y);
    outlinePath.lineTo(cursorPos.x + (3 * painterOptions.cursorSize), cursorPos.y - (3 * painterOptions.cursorSize));
    outlinePath.lineTo(cursorPos.x + (6 * painterOptions.cursorSize), cursorPos.y);
    outlinePath.lineTo(cursorPos.x + (4 * painterOptions.cursorSize), cursorPos.y + (2 * painterOptions.cursorSize));
    outlinePath.lineTo(cursorPos.x + (2 * painterOptions.cursorSize), cursorPos.y);
    outlinePath.lineTo(cursorPos.x, cursorPos.y);

    final Path fillPath = Path();
    fillPath.moveTo(cursorPos.x, cursorPos.y);
    fillPath.lineTo(cursorPos.x + (1 * painterOptions.cursorSize), cursorPos.y - (1 * painterOptions.cursorSize));
    fillPath.lineTo(cursorPos.x + (5 * painterOptions.cursorSize), cursorPos.y - (1 * painterOptions.cursorSize));
    fillPath.lineTo(cursorPos.x + (6 * painterOptions.cursorSize), cursorPos.y);
    fillPath.lineTo(cursorPos.x + (4 * painterOptions.cursorSize), cursorPos.y + (2 * painterOptions.cursorSize));
    fillPath.lineTo(cursorPos.x + (2 * painterOptions.cursorSize), cursorPos.y);

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
  void drawExtras({required final DrawingParameters drawParams}) {
    if (_shouldDraw && (drawParams.currentDrawingLayer != null || drawParams.currentShadingLayer != null))
    {
      if ((drawParams.currentDrawingLayer != null && drawParams.currentDrawingLayer!.visibilityState.value == LayerVisibilityState.visible && (drawParams.currentDrawingLayer!.lockState.value == LayerLockState.unlocked || (drawParams.currentDrawingLayer!.lockState.value == LayerLockState.transparency && drawParams.currentDrawingLayer!.getDataEntry(coord: _cursorPosNorm) != null))) ||
        (drawParams.currentShadingLayer != null && drawParams.currentShadingLayer!.visibilityState.value == LayerVisibilityState.visible && drawParams.currentShadingLayer!.lockState.value == LayerLockState.unlocked))
      {
        if (_options.fillAdjacent.value)
        {
          if (drawParams.currentDrawingLayer != null)
          {
            _floodFill(fillColor: appState.selectedColor!, layer: drawParams.currentDrawingLayer!, start: _cursorPosNorm, doShade: shaderOptions.isEnabled.value, shadeDirection: shaderOptions.shaderDirection.value, shadeCurrentRampOnly: shaderOptions.onlyCurrentRampEnabled.value, fillWholeRamp: _options.fillWholeRamp.value);
          }
          else //SHADING LAYER
          {
            _floodFillShading(layer: drawParams.currentShadingLayer!, start: _cursorPosNorm, shadeDirection: shaderOptions.shaderDirection.value);
            appState.rasterDrawingLayersBelow(layer: drawParams.currentShadingLayer!);
          }
        }
        else
        {
          if (drawParams.currentDrawingLayer != null)
          {
            _wholeFill(fillColor: appState.selectedColor!, layer: drawParams.currentDrawingLayer!, start: _cursorPosNorm, doShade: shaderOptions.isEnabled.value, shadeDirection: shaderOptions.shaderDirection.value, shadeCurrentRampOnly: shaderOptions.onlyCurrentRampEnabled.value, fillWholeRamp: _options.fillWholeRamp.value);
          }
          else //SHADING LAYER
          {
            _wholeFillShading(layer: drawParams.currentShadingLayer!, start: _cursorPosNorm, shadeDirection: shaderOptions.shaderDirection.value);
            appState.rasterDrawingLayersBelow(layer: drawParams.currentShadingLayer!);
          }

        }
        hasHistoryData = true;
      }
      _shouldDraw = false;
    }
  }

  void _floodFill({
    required final ColorReference fillColor,
    required final DrawingLayerState layer,
    required final CoordinateSetI start,
    required final bool doShade,
    required final ShaderDirection shadeDirection,
    required final bool shadeCurrentRampOnly,
    required final bool fillWholeRamp,})
  {
    final int numRows = appState.canvasSize.y;
    final int numCols = appState.canvasSize.x;
    final List<List<bool>> visited = List<List<bool>>.generate(numCols, (final _) => List<bool>.filled(numRows, false));
    final ColorReference? startValue = (appState.currentLayer == layer && appState.selectionState.selection.contains(coord: start)) ? appState.selectionState.selection.getColorReference(coord: start) : layer.getDataEntry(coord: start);
    final StackCol<CoordinateSetI> pointStack = StackCol<CoordinateSetI>();
    final CoordinateColorMap layerPixels = HashMap<CoordinateSetI, ColorReference>();
    final CoordinateColorMap selectionPixels = HashMap<CoordinateSetI, ColorReference>();

    pointStack.push(CoordinateSetI(x: start.x, y: start.y));

    while(pointStack.isNotEmpty)
    {
      final CoordinateSetI curCoord = pointStack.pop();
      final ColorReference? refAtPos = (appState.currentLayer == layer && appState.selectionState.selection.contains(coord: curCoord)) ? appState.selectionState.selection.getColorReference(coord: curCoord) : layer.getDataEntry(coord: curCoord);
      if (!visited[curCoord.x][curCoord.y] &&
          (appState.selectionState.selection.isEmpty || (!appState.selectionState.selection.isEmpty && appState.selectionState.selection.contains(coord: curCoord))) &&
          (
              refAtPos == startValue ||
                  (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
                  (refAtPos != null && doShade && !shadeCurrentRampOnly && fillWholeRamp)

          ))
      {
        visited[curCoord.x][curCoord.y] = true;

        //draw on selection
        if (appState.currentLayer == layer && appState.selectionState.selection.contains(coord: curCoord))
        {
          if (!doShade || refAtPos == null)
          {
            selectionPixels[curCoord] = fillColor;
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.shiftedColors.length)
            {
              selectionPixels[curCoord] = refAtPos.ramp.references[refAtPos.colorIndex + 1];
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              selectionPixels[curCoord] = refAtPos.ramp.references[refAtPos.colorIndex - 1];
            }
          }
        }
        else //draw on layer
        {
          if (!doShade || refAtPos == null)
          {
            layerPixels[curCoord] = fillColor;
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.shiftedColors.length)
            {
              layerPixels[curCoord] = refAtPos.ramp.references[refAtPos.colorIndex + 1];
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              layerPixels[curCoord] = refAtPos.ramp.references[refAtPos.colorIndex - 1];
            }
          }
        }
        if (curCoord.x + 1 < numCols)
        {
          pointStack.push(CoordinateSetI(x: curCoord.x + 1, y: curCoord.y));
        }
        if (curCoord.x > 0)
        {
          pointStack.push(CoordinateSetI(x: curCoord.x - 1, y: curCoord.y));
        }
        if (curCoord.y + 1 < numRows)
        {
          pointStack.push(CoordinateSetI(x: curCoord.x, y: curCoord.y + 1));
        }
        if (curCoord.y > 0)
        {
          pointStack.push(CoordinateSetI(x: curCoord.x, y: curCoord.y - 1));
        }
      }
    }

    if (layerPixels.isNotEmpty)
    {
      layer.setDataAll(list: layerPixels);
    }
    if (selectionPixels.isNotEmpty)
    {
      appState.selectionState.selection.addDirectlyAll(list: selectionPixels);
    }

  }

  void _floodFillShading({
    required final ShadingLayerState layer,
    required final CoordinateSetI start,
    required final ShaderDirection shadeDirection,})
  {
    final int numRows = appState.canvasSize.y;
    final int numCols = appState.canvasSize.x;
    final List<List<bool>> visited = List<List<bool>>.generate(numCols, (final _) => List<bool>.filled(numRows, false));
    final int? startValue = layer.getValueAt(coord: start);
    final StackCol<CoordinateSetI> stackPoints = StackCol<CoordinateSetI>();
    final HashMap<CoordinateSetI, int> addPixels = HashMap<CoordinateSetI, int>();
    final Set<CoordinateSetI> removePixels = <CoordinateSetI>{};

    stackPoints.push(CoordinateSetI(x: start.x, y: start.y));

    while(stackPoints.isNotEmpty)
    {
      final CoordinateSetI curCoord = stackPoints.pop();
      final int? shadeAtPos = layer.getValueAt(coord: curCoord);
      if (!visited[curCoord.x][curCoord.y] && shadeAtPos == startValue)
      {
        visited[curCoord.x][curCoord.y] = true;
        int shadeVal = shadeAtPos?? 0;

        if (shadeDirection == ShaderDirection.right)
        {
           shadeVal++;
        }
        else
        {
          shadeVal--;
        }

        final int finalShadeVal = shadeVal.clamp(layer.settings.shadingLow.value, layer.settings.shadingHigh.value);
        if (finalShadeVal == 0)
        {
           removePixels.add(curCoord);
        }
        else
        {
           addPixels[curCoord] = finalShadeVal;
        }


        if (curCoord.x + 1 < numCols)
        {
          stackPoints.push(CoordinateSetI(x: curCoord.x + 1, y: curCoord.y));
        }
        if (curCoord.x > 0)
        {
          stackPoints.push(CoordinateSetI(x: curCoord.x - 1, y: curCoord.y));
        }
        if (curCoord.y + 1 < numRows)
        {
          stackPoints.push(CoordinateSetI(x: curCoord.x, y: curCoord.y + 1));
        }
        if (curCoord.y > 0)
        {
          stackPoints.push(CoordinateSetI(x: curCoord.x, y: curCoord.y - 1));
        }
      }
    }

    if (removePixels.isNotEmpty)
    {
      layer.removeCoords(coords: removePixels);
    }

    if (addPixels.isNotEmpty)
    {
      layer.addCoords(coords: addPixels);
    }
  }

  void _wholeFill({
    required final ColorReference fillColor,
    required final DrawingLayerState layer,
    required final CoordinateSetI start,
    required final bool doShade,
    required final ShaderDirection shadeDirection,
    required final bool shadeCurrentRampOnly,
    required final bool fillWholeRamp,})
  {

    //on layer
    if (appState.selectionState.selection.isEmpty)
    {
      final ColorReference? startValue = layer.getDataEntry(coord: start);
      final CoordinateColorMapNullable refs = HashMap<CoordinateSetI, ColorReference?>();
      for (int x = 0; x < appState.canvasSize.x; x++)
      {
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          final ColorReference? refAtPos = layer.getDataEntry(coord: curCoord);
          if (
              refAtPos == startValue ||
              (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
              (refAtPos != null && doShade && !shadeCurrentRampOnly && fillWholeRamp))
          {
            if (!doShade || refAtPos == null)
            {
              refs[curCoord] = fillColor;
            }
            else
            {
              if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.shiftedColors.length)
              {
                refs[curCoord] = refAtPos.ramp.references[refAtPos.colorIndex + 1];
              }
              else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
              {
                refs[curCoord] = refAtPos.ramp.references[refAtPos.colorIndex - 1];
              }
            }
          }
        }
      }
      layer.setDataAll(list: refs);
    }
    //on selection
    else if (!appState.selectionState.selection.isEmpty && appState.selectionState.selection.contains(coord: start))
    {
      final ColorReference? startValue = appState.selectionState.selection.getColorReference(coord: start);
      final Iterable<CoordinateSetI> selectionCoords = appState.selectionState.selection.getCoordinates();
      for (final CoordinateSetI curCoord in selectionCoords)
      {
        final ColorReference? refAtPos = appState.selectionState.selection.getColorReference(coord: curCoord);
        if (refAtPos == startValue ||
            (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
            (refAtPos != null && doShade && !shadeCurrentRampOnly && fillWholeRamp))
        {
          if (!doShade || refAtPos == null)
          {
            appState.selectionState.selection.addDirectly(coord: curCoord, colRef: fillColor);
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.shiftedColors.length)
            {
              appState.selectionState.selection.addDirectly(coord: curCoord, colRef: refAtPos.ramp.references[refAtPos.colorIndex + 1]);
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              appState.selectionState.selection.addDirectly(coord: curCoord, colRef: refAtPos.ramp.references[refAtPos.colorIndex - 1]);
            }
          }
        }
      }
    }
  }

  void _wholeFillShading({
    required final ShadingLayerState layer,
    required final CoordinateSetI start,
    required final ShaderDirection shadeDirection,
  })
  {
    final int? startValue = layer.getValueAt(coord: start);
    final HashMap<CoordinateSetI, int> addPixels = HashMap<CoordinateSetI, int>();
    final Set<CoordinateSetI> removePixels = <CoordinateSetI>{};
    for (int x = 0; x < appState.canvasSize.x; x++)
    {
      for (int y = 0; y < appState.canvasSize.y; y++)
      {
        final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
        final int? shadeAtPos = layer.getValueAt(coord: curCoord);
        if (shadeAtPos == startValue)
        {
          int shadeVal = shadeAtPos?? 0;
          if (shadeDirection == ShaderDirection.right)
          {
             shadeVal++;
          }
          else
          {
            shadeVal--;
          }

          final int finalShadeVal = shadeVal.clamp(layer.settings.shadingLow.value, layer.settings.shadingHigh.value);
          if (finalShadeVal == 0)
          {
            removePixels.add(curCoord);
          }
          else
          {
            addPixels[curCoord] = finalShadeVal;
          }
        }
      }
    }
    if (removePixels.isNotEmpty)
    {
      layer.removeCoords(coords: removePixels);
    }

    if (addPixels.isNotEmpty)
    {
      layer.addCoords(coords: addPixels);
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
    _isDown = false;
    _shouldDraw = false;
  }
  
}
