
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class FillPainter extends IToolPainter
{
  final CoordinateSetI _normCursorPos = CoordinateSetI(x: 0, y: 0);

  FillPainter({required super.painterOptions});
  final FillOptions options = GetIt.I.get<PreferenceManager>().toolOptions.fillOptions;
  final ShaderOptions shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  bool isDown = false;
  bool shouldDraw = false;

  @override
  void calculate({required DrawingParameters drawParams}) {
    if (drawParams.cursorPos != null && KPixPainter.isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!))
    {
      _normCursorPos.x = KPixPainter.getClosestPixel(value: drawParams.cursorPos!.x - drawParams.offset.dx,pixelSize: drawParams.pixelSize.toDouble()).round();
      _normCursorPos.y = KPixPainter.getClosestPixel(value: drawParams.cursorPos!.y - drawParams.offset.dy,pixelSize: drawParams.pixelSize.toDouble()).round();
    }
    if (drawParams.primaryDown && !isDown && KPixPainter.isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!))
    {
      shouldDraw = true;
      isDown = true;
    }
    else if (isDown && !drawParams.primaryDown)
    {
      isDown = false;
    }
  }

  @override
  void drawCursor({required DrawingParameters drawParams}) {
    assert(drawParams.cursorPos != null);
    final CoordinateSetD cursorPos = CoordinateSetD(
        x: drawParams.offset.dx + (_normCursorPos.x + 0.5) * drawParams.pixelSize,
        y: drawParams.offset.dy + (_normCursorPos.y + 0.5) * drawParams.pixelSize);

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
    // TODO: implement drawExtras
  }

  @override
  void drawTool({required DrawingParameters drawParams}) {
    if (shouldDraw)
    {
      if (options.fillAdjacent.value)
      {
        _floodFill(fillColor: appState.selectedColor.value!, layer: drawParams.currentLayer, start: _normCursorPos, doShade: shaderOptions.isEnabled.value, shadeDirection: shaderOptions.shaderDirection.value, shadeCurrentRampOnly: shaderOptions.onlyCurrentRampEnabled.value, fillWholeRamp: options.fillWholeRamp.value);
      }
      else
      {
        _wholeFill(fillColor: appState.selectedColor.value!, layer: drawParams.currentLayer, start: _normCursorPos, doShade: shaderOptions.isEnabled.value, shadeDirection: shaderOptions.shaderDirection.value, shadeCurrentRampOnly: shaderOptions.onlyCurrentRampEnabled.value, fillWholeRamp: options.fillWholeRamp.value);
      }
      shouldDraw = false;
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
    final int numRows = appState.canvasHeight;
    final int numCols = appState.canvasWidth;
    final List<List<bool>> visited = List.generate(numCols, (_) => List.filled(numRows, false));
    final ColorReference? startValue = (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.contains(start)) ? appState.selectionState.selection.getColorReference(start) : layer.getData(start.x, start.y);

    void fill(int x, int y) {
      if (x < 0 || y >= numRows || y < 0 || x >= numCols) return;
      final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
      final ColorReference? refAtPos = (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.contains(curCoord)) ? appState.selectionState.selection.getColorReference(curCoord) : layer.getData(curCoord.x, curCoord.y);
      if (!visited[x][y] &&
          (appState.selectionState.selection.isEmpty() || (!appState.selectionState.selection.isEmpty() && appState.selectionState.selection.contains(curCoord))) &&
          (
            refAtPos == startValue ||
            (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
            (refAtPos != null && doShade && !shadeCurrentRampOnly)
      ))
      {
        visited[x][y] = true;

        //draw on selection
        if (appState.selectionState.selection.currentLayer == layer && appState.selectionState.selection.contains(curCoord))
        {
          if (!doShade || refAtPos == null)
          {
            appState.selectionState.selection.addDirectly(curCoord, fillColor);
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
            {
              appState.selectionState.selection.addDirectly(curCoord, ColorReference(colorIndex: refAtPos.colorIndex + 1, ramp: refAtPos.ramp));
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              appState.selectionState.selection.addDirectly(curCoord, ColorReference(colorIndex: refAtPos.colorIndex - 1, ramp: refAtPos.ramp));
            }
          }
        }
        else //draw on layer
        {
          if (!doShade || refAtPos == null)
          {
            layer.setData(x, y, fillColor);
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
            {
              layer.setData(x, y, ColorReference(colorIndex: refAtPos.colorIndex + 1, ramp: refAtPos.ramp));
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              layer.setData(x, y, ColorReference(colorIndex: refAtPos.colorIndex - 1, ramp: refAtPos.ramp));
            }
          }
        }

        fill(x + 1, y);
        fill(x - 1, y);
        fill(x, y + 1);
        fill(x, y - 1);
      }
    }

    fill(start.x, start.y);
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
      final ColorReference? startValue = layer.getData(start.x, start.y);
      for (int x = 0; x < appState.canvasWidth; x++)
      {
        for (int y = 0; y < appState.canvasHeight; y++)
        {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          final ColorReference? refAtPos = layer.getData(curCoord.x, curCoord.y);
          if (refAtPos == startValue ||
              (refAtPos != null && startValue != null && fillWholeRamp && refAtPos.ramp == startValue.ramp) ||
              (refAtPos != null && doShade && !shadeCurrentRampOnly))
          {
            if (!doShade || refAtPos == null)
            {
              layer.setData(x, y, fillColor);
            }
            else
            {
              if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
              {
                layer.setData(x, y, ColorReference(colorIndex: refAtPos.colorIndex + 1, ramp: refAtPos.ramp));
              }
              else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
              {
                layer.setData(x, y, ColorReference(colorIndex: refAtPos.colorIndex - 1, ramp: refAtPos.ramp));
              }
            }
          }
        }
      }
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
            (refAtPos != null && doShade && !shadeCurrentRampOnly))
        {
          if (!doShade || refAtPos == null)
          {
            appState.selectionState.selection.addDirectly(curCoord, fillColor);
          }
          else
          {
            if (shadeDirection == ShaderDirection.right && refAtPos.colorIndex + 1 < refAtPos.ramp.colors.length)
            {
              appState.selectionState.selection.addDirectly(curCoord, ColorReference(colorIndex: refAtPos.colorIndex + 1, ramp: refAtPos.ramp));
            }
            else if (shadeDirection == ShaderDirection.left && refAtPos.colorIndex - 1 >= 0)
            {
              appState.selectionState.selection.addDirectly(curCoord, ColorReference(colorIndex: refAtPos.colorIndex - 1, ramp: refAtPos.ramp));
            }
          }
        }
      }
    }
  }
  
}