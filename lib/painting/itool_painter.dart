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
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/util/typedefs.dart';

class BorderCoordinateSetI
{
  final CoordinateSetI coord;
  final List<List<CoordinateSetI>> borders;
  BorderCoordinateSetI._({required this.coord, required this.borders});

  factory BorderCoordinateSetI({required bool left, required bool right, required bool top, required bool bottom, required CoordinateSetI coord})
  {
    List<List<CoordinateSetI>> borders = [];
    if (left && right && !top && !bottom)
    {
      borders = [[coord, CoordinateSetI(x: coord.x, y: coord.y + 1)],[CoordinateSetI(x: coord.x + 1, y: coord.y), CoordinateSetI(x: coord.x + 1, y: coord.y + 1)]];
    }
    else if (!left && !right && top && bottom)
    {
      borders = [[coord, CoordinateSetI(x: coord.x + 1, y: coord.y)],[CoordinateSetI(x: coord.x, y: coord.y + 1), CoordinateSetI(x: coord.x + 1, y: coord.y + 1)]];
    }
    else
    {
      List<CoordinateSetI> path = [];
      final CoordinateSetI tl = coord;
      final CoordinateSetI tr = CoordinateSetI(x: coord.x + 1, y: coord.y);
      final CoordinateSetI br = CoordinateSetI(x: coord.x + 1, y: coord.y + 1);
      final CoordinateSetI bl = CoordinateSetI(x: coord.x, y: coord.y + 1);

      if (top && !right && !bottom && !left) //top
      {
        path.addAll([tl, tr]);
      }
      else if (!top && right && !bottom && !left) //right
      {
        path.addAll([tr, br]);
      }
      else if (!top && !right && bottom && !left) //bottom
      {
        path.addAll([br, bl]);
      }
      else if (!top && !right && !bottom && left) //left
      {
        path.addAll([bl, tl]);
      }
      else if (top && right && !bottom && !left) //tr
      {
        path.addAll([tl, tr, br]);
      }
      else if (!top && right && bottom && !left) //br
      {
        path.addAll([tr, br, bl]);
      }
      else if (!top && !right && bottom && left) //bl
      {
        path.addAll([br, bl, tl]);
      }
      else if (top && !right && !bottom && left) //tl
      {
        path.addAll([bl, tl, tr]);
      }
      else if (!top && right && bottom && left) // - top
      {
        path.addAll([tr, br, bl, tl]);
      }
      else if (top && !right && bottom && left) // - right
      {
        path.addAll([br, bl, tl, tr]);
      }
      else if (top && right && !bottom && left) // - bottom
      {
        path.addAll([bl, tl, tr, br]);
      }
      else if (top && right && bottom && !left) // - left
      {
        path.addAll([tl, tr, br, bl]);
      }
      if (path.isNotEmpty)
      {
        borders = [path];
      }

    }
    return BorderCoordinateSetI._(coord: coord, borders: borders);
  }

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
    required this.size
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


  void calculate({required DrawingParameters drawParams}){}
  void drawExtras({required DrawingParameters drawParams}){}
  //TODO this could be rasterized, too
  CoordinateColorMap getCursorContent({required DrawingParameters drawParams}){return HashMap();}
  void drawCursorOutline({required DrawingParameters drawParams});
  void reset() {}
  void setStatusBarData({required DrawingParameters drawParams})
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
    final Set<CoordinateSetI> coords = {};
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
          double dx = (x + 0.5) - centerX;
          double dy = (y + 0.5) - centerY;
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
      final int minX = drawingPixels.keys.map((c) => c.x).reduce((a, b) => a < b ? a : b);
      final int minY = drawingPixels.keys.map((c) => c.y).reduce((a, b) => a < b ? a : b);
      final int maxX = drawingPixels.keys.map((c) => c.x).reduce((a, b) => a > b ? a : b);
      final int maxY = drawingPixels.keys.map((c) => c.y).reduce((a, b) => a > b ? a : b);
      //print("min: $minX|$minY max: $maxX|$maxY");
      final CoordinateSetI offset = CoordinateSetI(x: minX, y: minY);
      final CoordinateSetI size = CoordinateSetI(x: maxX - minX + 1, y: maxY - minY + 1);
      final ByteData byteDataImg = ByteData(size.x * size.y * 4);
      for (final CoordinateColor entry in drawingPixels.entries)
      {
        final Color dColor = entry.value.getIdColor().color;
        final int index = ((entry.key.y - offset.y) * size.x + (entry.key.x - offset.x)) * 4;
        if (index < byteDataImg.lengthInBytes)
        {
          byteDataImg.setUint32(index, Helper.argbToRgba(argb: dColor.value));
        }
      }

      final Completer<ui.Image> completerImg = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          byteDataImg.buffer.asUint8List(),
          size.x,
          size.y,
          ui.PixelFormat.rgba8888, (ui.Image convertedImage)
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
    Set<CoordinateSetI> linePoints = {};
    final Set<CoordinateSetI> bresenhamPoints = Helper.bresenham(start: startPos, end: endPos).toSet();
    if (size == 1)
    {
      linePoints = bresenhamPoints;
    }
    else
    {
      final Set<CoordinateSetI> lPoints = {};
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

    Set<CoordinateSetI> linePoints = {};
    assert(angles.isNotEmpty);
    final double currentAngle = atan2(endPos.x - startPos.x, endPos.y - startPos.y);
    AngleData? closestAngle;
    double closestDist = 0.0;
    for (final AngleData aData in angles)
    {
      final double currentDist = (Helper.normAngle(angle: aData.angle) - Helper.normAngle(angle: currentAngle)).abs();
      if (closestAngle == null || currentDist < closestDist)
      {
        closestAngle = aData;
        closestDist = (Helper.normAngle(angle: currentAngle) - Helper.normAngle(angle: closestAngle.angle)).abs();
      }
    }

    if (closestAngle != null) //should never happen
    {
      double shortestDist = double.maxFinite;
      CoordinateSetI currentPos = CoordinateSetI.from(other: startPos);
      final Set<CoordinateSetI> lPoints = {};
      lPoints.add(startPos);
      bool firstRun = true;
      do
      {
        int startReducer = firstRun ? -1 : 0;
        firstRun = false;
        final Set<CoordinateSetI> currPoints = {};
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

        final dist = Helper.getDistance(a: endPos, b: currentPos);
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
        final Set<CoordinateSetI> widePoints = {};
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
    final List<CoordinateSetI> path = [];
    if (coords.length == 1)
    {
      path.add(coords.last);
      path.add(CoordinateSetI(x: coords.last.x + 1, y: coords.last.y));
      path.add(CoordinateSetI(x: coords.last.x + 1, y: coords.last.y + 1));
      path.add(CoordinateSetI(x: coords.last.x, y: coords.last.y + 1));
    }
    else
    {
      final List<BorderCoordinateSetI> boundaryPoints = [];
      for (final CoordinateSetI coord in coords)
      {
        BorderCoordinateSetI bcoord = BorderCoordinateSetI(
            coord: coord,
            left: !coords.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)),
            right: !coords.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)),
            top: !coords.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)),
            bottom: !coords.contains(CoordinateSetI(x: coord.x, y: coord.y + 1))
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

  CoordinateColorMap getPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
  {
    final CoordinateColorMap pixelMap = HashMap();
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
    return pixelMap;
  }

  CoordinateColorMap getStampPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final HashMap<CoordinateSetI, int> stampData, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
  {
    final CoordinateColorMap pixelMap = HashMap();
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

  int getClosestPixel({required double value, required double pixelSize})
  {
    final double remainder = value % pixelSize;
    final double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }
}