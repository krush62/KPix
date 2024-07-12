
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class FillPainter extends IToolPainter
{
  final CoordinateSetI _cursorPosNorm = CoordinateSetI(x: 0, y: 0);

  FillPainter({required super.painterOptions});
  final FillOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.fillOptions;
  bool _isDown = false;
  bool _shouldDraw = false;

  @override
  void calculate({required DrawingParameters drawParams}) {
    if (drawParams.cursorPos != null && KPixPainter.isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!))
    {
      _cursorPosNorm.x = KPixPainter.getClosestPixel(value: drawParams.cursorPos!.x - drawParams.offset.dx,pixelSize: drawParams.pixelSize.toDouble()).round();
      _cursorPosNorm.y = KPixPainter.getClosestPixel(value: drawParams.cursorPos!.y - drawParams.offset.dy,pixelSize: drawParams.pixelSize.toDouble()).round();
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
  void drawCursorOutline({required DrawingParameters drawParams}) {
    assert(drawParams.cursorPos != null);
    final CoordinateSetD cursorPos = CoordinateSetD(
        x: drawParams.offset.dx + (_cursorPosNorm.x + 0.5) * drawParams.pixelSize,
        y: drawParams.offset.dy + (_cursorPosNorm.y + 0.5) * drawParams.pixelSize);

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
  void drawExtras({required DrawingParameters drawParams}) {
    if (_shouldDraw)
    {
      if (_options.fillAdjacent.value)
      {
        _floodFill(fillColor: appState.selectedColor.value!, layer: drawParams.currentLayer, start: _cursorPosNorm, doShade: shaderOptions.isEnabled.value, shadeDirection: shaderOptions.shaderDirection.value, shadeCurrentRampOnly: shaderOptions.onlyCurrentRampEnabled.value, fillWholeRamp: _options.fillWholeRamp.value);
      }
      else
      {
        _wholeFill(fillColor: appState.selectedColor.value!, layer: drawParams.currentLayer, start: _cursorPosNorm, doShade: shaderOptions.isEnabled.value, shadeDirection: shaderOptions.shaderDirection.value, shadeCurrentRampOnly: shaderOptions.onlyCurrentRampEnabled.value, fillWholeRamp: _options.fillWholeRamp.value);
      }
      _shouldDraw = false;
      hasHistoryData = true;
    }
  }

  void _floodFill({
    required final ColorReference fillColor,
    required final LayerState layer,
    required final CoordinateSetI start,
    required final bool doShade,
    required final ShaderDirection shadeDirection,
    required final bool shadeCurrentRampOnly,
    required final bool fillWholeRamp})
  {
    final int numRows = appState.canvasSize.y;
    final int numCols = appState.canvasSize.x;
    final List<List<bool>> visited = List.generate(numCols, (_) => List.filled(numRows, false));
    final ColorReference? startValue = (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.contains(start)) ? appState.selectionState.selection.getColorReference(start) : layer.getDataEntry(start);
    final StackCol<CoordinateSetI> pointStack = StackCol<CoordinateSetI>();
    final HashMap<CoordinateSetI, ColorReference> layerPixels = HashMap();
    final HashMap<CoordinateSetI, ColorReference> selectionPixels = HashMap();

    pointStack.push(CoordinateSetI(x: start.x, y: start.y));

    while(pointStack.isNotEmpty)
    {
      final CoordinateSetI curCoord = pointStack.pop();
      final ColorReference? refAtPos = (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.contains(curCoord)) ? appState.selectionState.selection.getColorReference(curCoord) : layer.getDataEntry(curCoord);
      if (!visited[curCoord.x][curCoord.y] &&
          (appState.selectionState.selection.isEmpty() || (!appState.selectionState.selection.isEmpty() && appState.selectionState.selection.contains(curCoord))) &&
          (
              refAtPos == startValue ||
                  (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
                  (refAtPos != null && doShade && !shadeCurrentRampOnly && fillWholeRamp)

          ))
      {
        visited[curCoord.x][curCoord.y] = true;

        //draw on selection
        if (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.contains(curCoord))
        {
          if (!doShade || refAtPos == null)
          {
            selectionPixels[curCoord] = fillColor;
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
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
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
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
      layer.setDataAll(layerPixels);
    }
    if (selectionPixels.isNotEmpty)
    {
      appState.selectionState.selection.addDirectlyAll(selectionPixels);
    }

  }

  void _wholeFill({
    required final ColorReference fillColor,
    required final LayerState layer,
    required final CoordinateSetI start,
    required final bool doShade,
    required final ShaderDirection shadeDirection,
    required final bool shadeCurrentRampOnly,
    required final bool fillWholeRamp})
  {

    //on layer
    if (appState.selectionState.selection.isEmpty())
    {
      final ColorReference? startValue = layer.getDataEntry(start);
      final HashMap<CoordinateSetI, ColorReference?> refs = HashMap();
      for (int x = 0; x < appState.canvasSize.x; x++)
      {
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          final ColorReference? refAtPos = layer.getDataEntry(curCoord);
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
              if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
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
      layer.setDataAll(refs);
    }
    //on selection
    else if (!appState.selectionState.selection.isEmpty() && appState.selectionState.selection.contains(start))
    {
      final ColorReference? startValue = appState.selectionState.selection.getColorReference(start);
      final Iterable<CoordinateSetI> selectionCoords = appState.selectionState.selection.getCoordinates();
      for (final CoordinateSetI curCoord in selectionCoords)
      {
        final ColorReference? refAtPos = appState.selectionState.selection.getColorReference(curCoord);
        if (refAtPos == startValue ||
            (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
            (refAtPos != null && doShade && !shadeCurrentRampOnly && fillWholeRamp))
        {
          if (!doShade || refAtPos == null)
          {
            appState.selectionState.selection.addDirectly(curCoord, fillColor);
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
            {
              appState.selectionState.selection.addDirectly(curCoord, refAtPos.ramp.references[refAtPos.colorIndex + 1]);
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              appState.selectionState.selection.addDirectly(curCoord, refAtPos.ramp.references[refAtPos.colorIndex - 1]);
            }
          }
        }
      }
    }
  }

  @override
  void setStatusBarData({required DrawingParameters drawParams})
  {
    super.setStatusBarData(drawParams: drawParams);
    statusBarData.cursorPos = drawParams.cursorPos != null ? _cursorPosNorm : null;
  }
  
}