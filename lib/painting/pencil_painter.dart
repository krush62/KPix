import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class PencilPainter extends IToolPainter
{
  final PencilOptions options = GetIt.I.get<PreferenceManager>().toolOptions.pencilOptions;
  final KPixPainterOptions kPixPainterOptions = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final ShaderOptions shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final List<CoordinateSetI> paintPositions = [];
  final CoordinateSetI cursorPosNorm = CoordinateSetI(x: 0, y: 0);



  PencilPainter({required super.painterOptions});

  @override
  void calculate({required DrawingParameters drawParams})
  {
    if (drawParams.cursorPos != null) {
      cursorPosNorm.x = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.x - drawParams.offset.dx,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
      cursorPosNorm.y = KPixPainter.getClosestPixel(
          value: drawParams.cursorPos!.y - drawParams.offset.dy,
          pixelSize: drawParams.pixelSize.toDouble())
          .round();
    }
    if (drawParams.primaryDown)
    {

      if (paintPositions.isEmpty || cursorPosNorm.isAdjacent(paintPositions[paintPositions.length - 1], true))
      {
        paintPositions.add(CoordinateSetI(x: cursorPosNorm.x, y: cursorPosNorm.y));
        if (options.size.value == 1 && options.pixelPerfect.value && paintPositions.length >= 3)
        {
          if (paintPositions[paintPositions.length-1].isDiagonal(paintPositions[paintPositions.length - 3]))
          {
            paintPositions.removeAt(paintPositions.length - 2);
          }
        }
      }
      else
      {
        paintPositions.addAll(Helper.bresenham(paintPositions[paintPositions.length - 1], cursorPosNorm).sublist(1));
      }
    }
    else if (paintPositions.isNotEmpty)
    {
      final Set<CoordinateSetI> posSet = paintPositions.toSet();
      final Set<CoordinateSetI> paintPoints = {};
      for (final CoordinateSetI pos in posSet)
      {
        paintPoints.addAll(getContentPoints(options.shape.value, options.size.value, pos));
      }

      final HashMap<CoordinateSetI, ColorReference> drawMap = getPixelsToDraw(drawParams: drawParams, coords: paintPoints);
      final bool dumpToSelection = !appState.selectionState.selection.isEmpty();
      for (final MapEntry<CoordinateSetI, ColorReference> entry in drawMap.entries)
      {
        if (dumpToSelection)
        {
          appState.selectionState.selection.addDirectly(entry.key, entry.value);
        }
        else
        {
          drawParams.currentLayer.data[entry.key.x][entry.key.y] = entry.value;
        }
      }
      paintPositions.clear();
    }
  }

  @override
  void drawCursor({required DrawingParameters drawParams}) {


    final Set<CoordinateSetI> contentPoints = getContentPoints(options.shape.value, options.size.value, cursorPosNorm);
    if(appState.selectedColor.value != null)
    {
      HashMap<CoordinateSetI, ColorReference> drawMap =  getPixelsToDraw(drawParams: drawParams, coords: contentPoints);
      drawParams.paint.style = PaintingStyle.fill;
      for (final MapEntry<CoordinateSetI, ColorReference> entry in drawMap.entries)
      {
        _drawPixel(drawParams: drawParams, entry: entry);
      }
    }


    //Surrounding
    final List<CoordinateSetI> pathPoints = getBoundaryPath(contentPoints);
    Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[i].y * drawParams.pixelSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[i + 1].y * drawParams.pixelSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[0].y * drawParams.pixelSize) + drawParams.offset.dy);
      }
    }

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }

  @override
  void drawExtras({required DrawingParameters drawParams}) {
    // TODO: implement drawExtras
  }

  @override
  void drawTool({required DrawingParameters drawParams}) {
    if (drawParams.primaryDown)
    {
      final Set<CoordinateSetI> posSet = paintPositions.toSet();
      final Set<CoordinateSetI> paintPoints = {};
      for (final CoordinateSetI pos in posSet)
      {
        paintPoints.addAll(getContentPoints(options.shape.value, options.size.value, pos));
      }

      final HashMap<CoordinateSetI, ColorReference> drawMap = getPixelsToDraw(drawParams: drawParams, coords: paintPoints);
      drawParams.paint.style = PaintingStyle.fill;
      for (final MapEntry<CoordinateSetI, ColorReference> entry in drawMap.entries)
      {
         _drawPixel(drawParams: drawParams, entry: entry);
      }
    }
  }


  HashMap<CoordinateSetI, ColorReference> getPixelsToDraw({required DrawingParameters drawParams, required Set<CoordinateSetI> coords})
  {
    final HashMap<CoordinateSetI, ColorReference> pixelMap = HashMap();
    final SelectionState selection = appState.selectionState;
    for (final CoordinateSetI coord in coords)
    {
      if (coord.x >= 0 && coord.y >= 0 &&
          coord.x < drawParams.canvasSize.x &&
          coord.y < drawParams.canvasSize.y)
      {
        if (!shaderOptions.isEnabled.value) //without shading
        {
          //if no selection and current pixel is different
          if ((selection.selection.isEmpty() && drawParams.currentLayer.data[coord.x][coord.y] != appState.selectedColor.value) ||
              //if selection and selection contains pixel and selection pixel is different
              (!selection.selection.isEmpty() && selection.selection.contains(coord) && selection.selection.getColorReference(coord) != appState.selectedColor.value))
          {
            pixelMap[coord] = appState.selectedColor.value!;
          }
        }
        //with shading
        else
          //if no selection and pixel is not null
          if ((selection.selection.isEmpty() && drawParams.currentLayer.data[coord.x][coord.y] != null) ||
            //if selection and selection contains pixel and pixel is not null
            (!selection.selection.isEmpty() && selection.selection.contains(coord) && selection.selection.getColorReference(coord) != null))
        {
          final ColorReference layerRef = selection.selection.isEmpty() ? drawParams.currentLayer.data[coord.x][coord.y]! : selection.selection.getColorReference(coord)!;
          if (layerRef.ramp.uuid == appState.selectedColor.value!.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value)
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              if (layerRef.colorIndex + 1 < layerRef.ramp.colors.length)
              {
                pixelMap[coord] = ColorReference(colorIndex: layerRef.colorIndex + 1, ramp: layerRef.ramp);
              }
            }
            else
            {
              if (layerRef.colorIndex - 1 > 0)
              {
                pixelMap[coord] = ColorReference(colorIndex: layerRef.colorIndex - 1, ramp: layerRef.ramp);
              }
            }
          }
        }
      }
    }
    return pixelMap;
  }

  void _drawPixel({required DrawingParameters drawParams, required MapEntry<CoordinateSetI, ColorReference> entry})
  {
    drawParams.paint.color = entry.value.getIdColor().color;
    drawParams.canvas.drawRect(
        Rect.fromLTWH(
            drawParams.offset.dx + (entry.key.x * drawParams.pixelSize.toDouble()) - kPixPainterOptions.pixelExtensionFactor,
            drawParams.offset.dy + (entry.key.y * drawParams.pixelSize.toDouble()) - kPixPainterOptions.pixelExtensionFactor,
            drawParams.pixelSize.toDouble() + (2.0 * kPixPainterOptions.pixelExtensionFactor),
            drawParams.pixelSize.toDouble() + (2.0 * kPixPainterOptions.pixelExtensionFactor)),
        drawParams.paint);
  }
}