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

import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class BorderCoordinateSetI
{
  final CoordinateSetI coord;
  final List<List<CoordinateSetI>> borders;


  factory BorderCoordinateSetI({required final bool left, required final bool right, required final bool top, required final bool bottom, required final CoordinateSetI coord})
  {
    List<List<CoordinateSetI>> borders = <List<CoordinateSetI>>[];
    if (left && right && !top && !bottom)
    {
      borders = <List<CoordinateSetI>>[<CoordinateSetI>[coord, CoordinateSetI(x: coord.x, y: coord.y + 1)],<CoordinateSetI>[CoordinateSetI(x: coord.x + 1, y: coord.y), CoordinateSetI(x: coord.x + 1, y: coord.y + 1)]];
    }
    else if (!left && !right && top && bottom)
    {
      borders = <List<CoordinateSetI>>[<CoordinateSetI>[coord, CoordinateSetI(x: coord.x + 1, y: coord.y)],<CoordinateSetI>[CoordinateSetI(x: coord.x, y: coord.y + 1), CoordinateSetI(x: coord.x + 1, y: coord.y + 1)]];
    }
    else
    {
      final List<CoordinateSetI> path = <CoordinateSetI>[];
      final CoordinateSetI tl = coord;
      final CoordinateSetI tr = CoordinateSetI(x: coord.x + 1, y: coord.y);
      final CoordinateSetI br = CoordinateSetI(x: coord.x + 1, y: coord.y + 1);
      final CoordinateSetI bl = CoordinateSetI(x: coord.x, y: coord.y + 1);

      if (top && !right && !bottom && !left) //top
      {
        path.addAll(<CoordinateSetI>[tl, tr]);
      }
      else if (!top && right && !bottom && !left) //right
      {
        path.addAll(<CoordinateSetI>[tr, br]);
      }
      else if (!top && !right && bottom && !left) //bottom
      {
        path.addAll(<CoordinateSetI>[br, bl]);
      }
      else if (!top && !right && !bottom && left) //left
      {
        path.addAll(<CoordinateSetI>[bl, tl]);
      }
      else if (top && right && !bottom && !left) //tr
      {
        path.addAll(<CoordinateSetI>[tl, tr, br]);
      }
      else if (!top && right && bottom && !left) //br
      {
        path.addAll(<CoordinateSetI>[tr, br, bl]);
      }
      else if (!top && !right && bottom && left) //bl
      {
        path.addAll(<CoordinateSetI>[br, bl, tl]);
      }
      else if (top && !right && !bottom && left) //tl
      {
        path.addAll(<CoordinateSetI>[bl, tl, tr]);
      }
      else if (!top && right && bottom && left) // - top
      {
        path.addAll(<CoordinateSetI>[tr, br, bl, tl]);
      }
      else if (top && !right && bottom && left) // - right
      {
        path.addAll(<CoordinateSetI>[br, bl, tl, tr]);
      }
      else if (top && right && !bottom && left) // - bottom
      {
        path.addAll(<CoordinateSetI>[bl, tl, tr, br]);
      }
      else if (top && right && bottom && !left) // - left
      {
        path.addAll(<CoordinateSetI>[tl, tr, br, bl]);
      }
      if (path.isNotEmpty)
      {
        borders = <List<CoordinateSetI>>[path];
      }

    }
    return BorderCoordinateSetI._(coord: coord, borders: borders);
  }

  BorderCoordinateSetI._({required this.coord, required this.borders});

}

class StatusBarData
{
  CoordinateSetI? cursorPos;
  CoordinateSetI? dimension;
  CoordinateSetI? diagonal;
  CoordinateSetI? aspectRatio;
  CoordinateSetI? angle;
}

class ContentRasterSet
{
  final ui.Image image;
  final CoordinateSetI offset;
  final CoordinateSetI size;

  const ContentRasterSet({
    required this.image,
    required this.offset,
    required this.size,
  });
}


abstract class IToolPainter
{
  final AppState appState = GetIt.I.get<AppState>();
  final ShaderOptions shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final GuiPreferenceContent guiPrefs = GetIt.I.get<PreferenceManager>().guiPreferenceContent;
  final KPixPainterOptions painterOptions;
  final StatusBarData statusBarData = StatusBarData();
  late Color blackToolAlphaColor;
  late Color whiteToolAlphaColor;
  bool hasHistoryData = false;
  ContentRasterSet? contentRaster;
  ContentRasterSet? cursorRaster;
  bool hasAsyncUpdate = false;

  IToolPainter({required this.painterOptions})
  {
    guiPrefs.toolOpacity.addListener(() {
      _setOutlineColors(percentageValue: guiPrefs.toolOpacity.value);
    },);
    _setOutlineColors(percentageValue: guiPrefs.toolOpacity.value);
  }

  void _setOutlineColors({required final int percentageValue})
  {
    final int alignedValue = (percentageValue.toDouble() * 2.55).round();
    blackToolAlphaColor = Colors.black.withAlpha(alignedValue);
    whiteToolAlphaColor = Colors.white.withAlpha(alignedValue);
  }


  void calculate({required final DrawingParameters drawParams}){}
  void drawExtras({required final DrawingParameters drawParams}){}
  void drawCursorOutline({required final DrawingParameters drawParams});
  void reset() {}
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    statusBarData.cursorPos = null;
    statusBarData.dimension = null;
    statusBarData.diagonal = null;
    statusBarData.aspectRatio = null;
    statusBarData.angle = null;
  }



  Set<CoordinateSetI> getRoundSquareContentPoints({required final PencilShape shape, required final int size, required final CoordinateSetI position})
  {
    final CoordinateSetI startPos = CoordinateSetI(x: position.x - ((size - 1) ~/ 2), y: position.y - ((size - 1) ~/ 2));
    final CoordinateSetI endPos = CoordinateSetI(x: position.x + (size ~/ 2), y: position.y + (size ~/ 2));
    final Set<CoordinateSetI> coords = <CoordinateSetI>{};
    if (shape == PencilShape.square)
    {
      for (int x = startPos.x; x <= endPos.x; x++)
      {
        for (int y = startPos.y; y <= endPos.y; y++)
        {
          coords.add(CoordinateSetI(x: x, y: y));
        }
      }
    }
    else if (shape == PencilShape.round) {
      final double centerX = (startPos.x + endPos.x + 1) / 2.0;
      final double centerY = (startPos.y + endPos.y + 1) / 2.0;
      final double radiusX = (endPos.x - startPos.x + 1) / 2.0;
      final double radiusY = (endPos.y - startPos.y + 1) / 2.0;

      for (int x = startPos.x; x <= endPos.x; x++) {
        for (int y = startPos.y; y <= endPos.y; y++) {
          final double dx = (x + 0.5) - centerX;
          final double dy = (y + 0.5) - centerY;
          if ((dx * dx) / (radiusX * radiusX) +
              (dy * dy) / (radiusY * radiusY) <= 1) {
            coords.add(CoordinateSetI(x: x, y: y));
          }
        }
      }
    }
    return coords;
  }

  Future<ContentRasterSet?> rasterizeDrawingPixels({required final CoordinateColorMap drawingPixels}) async
  {
    if (drawingPixels.isNotEmpty)
    {
      final CoordinateSetI min = getMin(coordList: drawingPixels.keys.toList());
      final CoordinateSetI max = getMax(coordList: drawingPixels.keys.toList());
      //print("min: $minX|$minY max: $maxX|$maxY");
      final CoordinateSetI offset = CoordinateSetI(x: min.x, y: min.y);
      final CoordinateSetI size = CoordinateSetI(x: max.x - min.x + 1, y: max.y - min.y + 1);
      final ByteData byteDataImg = ByteData(size.x * size.y * 4);
      for (final CoordinateColor entry in drawingPixels.entries)
      {
        final Color dColor = entry.value.getIdColor().color;
        final int index = ((entry.key.y - offset.y) * size.x + (entry.key.x - offset.x)) * 4;
        if (index < byteDataImg.lengthInBytes)
        {
          byteDataImg.setUint32(index, argbToRgba(argb: dColor.value));
        }
      }

      final Completer<ui.Image> completerImg = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          byteDataImg.buffer.asUint8List(),
          size.x,
          size.y,
          ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
      {
        completerImg.complete(convertedImage);
      }
      );
      return ContentRasterSet(image: await completerImg.future, offset: offset, size: size);
    }
    else
    {
      return null;
    }
  }

  Set<CoordinateSetI> getLinePoints({required final CoordinateSetI startPos, required final CoordinateSetI endPos, required final int size, required final PencilShape shape})
  {
    Set<CoordinateSetI> linePoints = <CoordinateSetI>{};
    final Set<CoordinateSetI> bresenhamPoints = bresenham(start: startPos, end: endPos).toSet();
    if (size == 1)
    {
      linePoints = bresenhamPoints;
    }
    else
    {
      final Set<CoordinateSetI> lPoints = <CoordinateSetI>{};
      for (final CoordinateSetI coord in bresenhamPoints)
      {
        lPoints.addAll(getRoundSquareContentPoints(shape: shape, size: size, position: coord));
      }
      linePoints = lPoints;
    }
    return linePoints;
  }

  Set<CoordinateSetI> getIntegerRatioLinePoints({required final CoordinateSetI startPos, required final CoordinateSetI endPos, required final int size, required final PencilShape shape, required final Set<AngleData> angles})
  {

    Set<CoordinateSetI> linePoints = <CoordinateSetI>{};
    assert(angles.isNotEmpty);
    final double currentAngle = atan2(endPos.x - startPos.x, endPos.y - startPos.y);
    AngleData? closestAngle;
    double closestDist = 0.0;
    for (final AngleData aData in angles)
    {
      final double currentDist = (normAngle(angle: aData.angle) - normAngle(angle: currentAngle)).abs();
      if (closestAngle == null || currentDist < closestDist)
      {
        closestAngle = aData;
        closestDist = (normAngle(angle: currentAngle) - normAngle(angle: closestAngle.angle)).abs();
      }
    }

    if (closestAngle != null) //should never happen
    {
      double shortestDist = double.maxFinite;
      final CoordinateSetI currentPos = CoordinateSetI.from(other: startPos);
      final Set<CoordinateSetI> lPoints = <CoordinateSetI>{};
      lPoints.add(startPos);
      bool firstRun = true;
      do
      {
        final int startReducer = firstRun ? -1 : 0;
        firstRun = false;
        final Set<CoordinateSetI> currPoints = <CoordinateSetI>{};
        if (closestAngle.x.abs() > closestAngle.y.abs())
        {
          for (int i = 0; i < closestAngle.x.abs() + startReducer; i++)
          {
            if (closestAngle.x > 0)
            {
              currentPos.x++;
            }
            else
            {
              currentPos.x--;
            }
            currPoints.add(CoordinateSetI.from(other: currentPos));
          }
          if (closestAngle.y > 0)
          {
            currentPos.y++;
          }
          else if (closestAngle.y < 0)
          {
            currentPos.y--;
          }
        }
        else
        {
          for (int i = 0; i < closestAngle.y.abs() + startReducer; i++)
          {
            if (closestAngle.y > 0)
            {
              currentPos.y++;
            }
            else
            {
              currentPos.y--;
            }
            currPoints.add(CoordinateSetI.from(other: currentPos));
          }
          if (closestAngle.x > 0)
          {
            currentPos.x++;
          }
          else if (closestAngle.x < 0)
          {
            currentPos.x--;
          }
        }

        final double dist = getDistance(a: endPos, b: currentPos);
        if (dist < shortestDist)
        {
          shortestDist = dist;
          lPoints.addAll(currPoints);
        }
        else
        {
          break;
        }
      } while(true);


      if (size == 1)
      {
        linePoints = lPoints;
      }
      else
      {
        final Set<CoordinateSetI> widePoints = <CoordinateSetI>{};
        for (final CoordinateSetI coord in lPoints)
        {
          widePoints.addAll(getRoundSquareContentPoints(shape: shape, size: size, position: coord));
        }
        linePoints = widePoints;
      }
    }

    return linePoints;
  }


  static List<CoordinateSetI> getBoundaryPath({required final Set<CoordinateSetI> coords})
  {
    final List<CoordinateSetI> path = <CoordinateSetI>[];
    if (coords.length == 1)
    {
      path.add(coords.last);
      path.add(CoordinateSetI(x: coords.last.x + 1, y: coords.last.y));
      path.add(CoordinateSetI(x: coords.last.x + 1, y: coords.last.y + 1));
      path.add(CoordinateSetI(x: coords.last.x, y: coords.last.y + 1));
    }
    else
    {
      final List<BorderCoordinateSetI> boundaryPoints = <BorderCoordinateSetI>[];
      for (final CoordinateSetI coord in coords)
      {
        final BorderCoordinateSetI bcoord = BorderCoordinateSetI(
            coord: coord,
            left: !coords.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)),
            right: !coords.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)),
            top: !coords.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)),
            bottom: !coords.contains(CoordinateSetI(x: coord.x, y: coord.y + 1)),
        );

        if (bcoord.borders.isNotEmpty)
        {
          boundaryPoints.add(bcoord);
        }
      }

      bool itemAdded = true;
      while (boundaryPoints.isNotEmpty && itemAdded)
      {
        itemAdded = false;
        if (path.isEmpty)
        {
          final BorderCoordinateSetI bPoint = boundaryPoints[0];
          path.addAll(bPoint.borders[0]);
          if (bPoint.borders.length == 1)
          {
            boundaryPoints.remove(bPoint);
          }
          else if (bPoint.borders.length == 2)
          {
            bPoint.borders.removeAt(0);
          }
          itemAdded = true;
        }
        else
        {
          for (int i = 0; i < boundaryPoints.length; i++)
          {
            final BorderCoordinateSetI bPoint = boundaryPoints[i];
            for (int j = 0; j < bPoint.borders.length; j++)
            {
              if (bPoint.borders[j][0] == path[path.length - 1])
              {
                path.addAll(bPoint.borders[j].sublist(1));
                bPoint.borders.removeAt(j);
                itemAdded = true;
                break;
              }
              else if (bPoint.borders[j][bPoint.borders[j].length - 1] == path[0])
              {
                path.insertAll(0, bPoint.borders[j].sublist(0, bPoint.borders[j].length - 1));
                bPoint.borders.removeAt(j);
                itemAdded = true;
                break;
              }
            }
            if (itemAdded)
            {
              if (bPoint.borders.isEmpty)
              {
                boundaryPoints.remove(bPoint);
              }
              break;
            }
          }
        }
      }
    }
    return path;
  }

  CoordinateColorMap getPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor, final bool withShadingLayers = false})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    for (final CoordinateSetI coord in coords)
    {
      if (coord.x >= 0 && coord.y >= 0 &&
          coord.x < canvasSize.x &&
          coord.y < canvasSize.y)
      {
        if (!shaderOptions.isEnabled.value) //without shading
        {
          //if no selection and current pixel is different
          if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord) != selectedColor) ||
              //if selection and selection contains pixel and selection pixel is different
              (!selection.selection.isEmpty && selection.selection.contains(coord: coord) && selection.selection.getColorReference(coord: coord) != selectedColor))
          {
            if ((currentLayer.lockState.value == LayerLockState.transparency && currentLayer.getDataEntry(coord: coord) != null) || currentLayer.lockState.value == LayerLockState.unlocked)
            {
              pixelMap[coord] = selectedColor;
            }
          }
        }
        //with shading
        else
          //if no selection and pixel is not null
        if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord) != null) ||
            //if selection and selection contains pixel and pixel is not null
            (!selection.selection.isEmpty && selection.selection.contains(coord: coord) && selection.selection.getColorReference(coord: coord) != null))
        {
          final ColorReference layerRef = selection.selection.isEmpty ? currentLayer.getDataEntry(coord: coord)! : selection.selection.getColorReference(coord: coord)!;
          if (layerRef.ramp.uuid == selectedColor.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value)
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              if (layerRef.colorIndex + 1 < layerRef.ramp.shiftedColors.length)
              {
                pixelMap[coord] = layerRef.ramp.references[layerRef.colorIndex  + 1];
              }
            }
            else
            {
              if (layerRef.colorIndex > 0)
              {
                pixelMap[coord] = layerRef.ramp.references[layerRef.colorIndex  - 1];
              }
            }
          }
        }
      }
    }


    if (withShadingLayers)
    {
      final CoordinateColorMap shadedPixelMap = HashMap<CoordinateSetI, ColorReference>();
      for (final CoordinateColor entry in pixelMap.entries)
      {
        shadedPixelMap[entry.key] = _getColorShading(coord: entry.key, appState: appState, inputColor: entry.value, currentLayer: currentLayer);
      }
      return shadedPixelMap;
    }
    else
    {
      return pixelMap;
    }
  }

  ColorReference _getColorShading({required final CoordinateSetI coord, required final AppState appState, required final ColorReference inputColor, required final LayerState currentLayer})
  {
    ColorReference retColor = inputColor;
    int colorShift = 0;
    final int currentIndex = appState.getLayerPosition(state: currentLayer);
    if (currentIndex != -1)
    {
      for (int i = 0; i < appState.layers.length; i++)
      {
        if (appState.layers[i].runtimeType == ShadingLayerState && appState.layers[i].visibilityState.value == LayerVisibilityState.visible)
        {
          final ShadingLayerState shadingLayer = appState.layers[i] as ShadingLayerState;
          if (shadingLayer.shadingData[coord] != null)
          {
            colorShift = (inputColor.colorIndex + colorShift + shadingLayer.shadingData[coord]!).clamp(0, inputColor.ramp.shiftedColors.length - 1);
          }
        }
      }
    }
    if (colorShift != 0)
    {
      retColor = ColorReference(colorIndex: colorShift, ramp: inputColor.ramp);
    }
    return retColor;
  }

  CoordinateColorMap getPixelsToDrawForShading({required final CoordinateSetI canvasSize, required final ShadingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final ShaderOptions shaderOptions})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    if (currentLayer.lockState.value == LayerLockState.unlocked)
    {
      for (final CoordinateSetI coord in coords)
      {
        if (coord.x >= 0 && coord.y >= 0 &&
            coord.x < canvasSize.x &&
            coord.y < canvasSize.y)
        {
          final List<LayerState> layers = appState.layers;
          final int currentLayerPos = appState.getLayerPosition(state: currentLayer);
          if (currentLayerPos >= 0)
          {
            ColorReference? currentColor;
            for (int i = layers.length - 1; i >= currentLayerPos; i--)
            {
              if (layers[i].runtimeType == DrawingLayerState)
              {
                final DrawingLayerState drawingLayer = layers[i] as DrawingLayerState;
                final ColorReference? col = drawingLayer.getDataEntry(coord: coord);
                if (col != null)
                {
                  currentColor = ColorReference(colorIndex: col.colorIndex, ramp: col.ramp);
                }
              }
              else if (currentColor != null && layers[i].runtimeType == ShadingLayerState)
              {
                final ShadingLayerState shadingLayer = layers[i] as ShadingLayerState;
                if (shadingLayer.shadingData[coord] != null)
                {
                  final int newColorIndex = currentColor.colorIndex + shadingLayer.shadingData[coord]!.clamp(0, currentColor.ramp.shiftedColors.length - 1);
                  currentColor = ColorReference(colorIndex: newColorIndex, ramp: currentColor.ramp);
                }
              }
            }
            if (currentColor != null)
            {
              final int shift = shaderOptions.shaderDirection.value == ShaderDirection.right ? 1 : -1;
              final int newColorIndex = (currentColor.colorIndex + shift).clamp(0, currentColor.ramp.shiftedColors.length - 1);
              pixelMap[coord] = ColorReference(colorIndex: newColorIndex, ramp: currentColor.ramp);
            }
          }
        }
      }
    }
    return pixelMap;
  }



  CoordinateColorMap getStampPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final HashMap<CoordinateSetI, int> stampData, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    for (final MapEntry<CoordinateSetI, int> stampEntry in stampData.entries)
    {
      final CoordinateSetI coord = stampEntry.key;

      if (coord.x >= 0 && coord.y >= 0 &&
          coord.x < canvasSize.x &&
          coord.y < canvasSize.y)
      {
        if (!shaderOptions.isEnabled.value) //without shading
        {
          final int index = (selectedColor.colorIndex + stampEntry.value).clamp(0, selectedColor.ramp.shiftedColors.length - 1);
          final ColorReference drawColor = selectedColor.ramp.references[index];
          //if no selection and current pixel is different
          if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord) != drawColor) ||
              //if selection and selection contains pixel and selection pixel is different
              (!selection.selection.isEmpty && selection.selection.contains(coord: coord) && selection.selection.getColorReference(coord: coord) != drawColor))
          {
            if ((currentLayer.lockState.value == LayerLockState.transparency && currentLayer.getDataEntry(coord: coord) != null) || currentLayer.lockState.value == LayerLockState.unlocked)
            {
              pixelMap[coord] = drawColor;
            }
          }
        }
        //with shading
        else
          //if no selection and pixel is not null
        if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord) != null) ||
            //if selection and selection contains pixel and pixel is not null
            (!selection.selection.isEmpty && selection.selection.contains(coord: coord) && selection.selection.getColorReference(coord: coord) != null))
        {
          final ColorReference layerRef = selection.selection.isEmpty ? currentLayer.getDataEntry(coord: coord)! : selection.selection.getColorReference(coord: coord)!;
          if (layerRef.ramp.uuid == selectedColor.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value) //all ramps
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              final int index = (layerRef.colorIndex + stampEntry.value + 1).clamp(0, layerRef.ramp.shiftedColors.length - 1);
              pixelMap[coord] = layerRef.ramp.references[index];
            }
            else
            {
              final int index = (layerRef.colorIndex - stampEntry.value - 1).clamp(0, layerRef.ramp.shiftedColors.length - 1);
              pixelMap[coord] = layerRef.ramp.references[index];
            }
          }
        }
      }
    }
    return pixelMap;
  }

  int getClosestPixel({required final double value, required final double pixelSize})
  {
    final double remainder = value % pixelSize;
    final double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }
}
