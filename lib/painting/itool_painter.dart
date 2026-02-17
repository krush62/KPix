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
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
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
  ContentRasterSet? _contentRaster;
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

  ContentRasterSet? get contentRaster => _contentRaster;

  // ignore: use_setters_to_change_properties
  void setContentRasterData({required final ContentRasterSet content})
  {
      _contentRaster = content;
  }

  void resetContentRaster({required final LayerState currentLayer})
  {
    _waitForLayerToFinishRasterizing(currentLayer: currentLayer).then((final void _) {
      _contentRaster = null;
    });
  }

  Future<void> _waitForLayerToFinishRasterizing({required final LayerState currentLayer}) async
  {
    const int waitingTimeMs = 25;
    const int maxWaitingIterations = 40;
    const int initialDelay = 150;

    //TODO wait until rasterizing starts instead of static delay
    await Future<void>.delayed(const Duration(milliseconds: initialDelay));

    int iterations = 0;
    if (currentLayer is RasterableLayerState)
    {
      while (currentLayer.isRasterizing && iterations < maxWaitingIterations)
      {
        await Future<void>.delayed(const Duration(milliseconds: waitingTimeMs));
        iterations++;
      }
    }
    else if (currentLayer.runtimeType == GridLayerState)
    {
      final GridLayerState gLayer = currentLayer as GridLayerState;
      while (gLayer.isRendering && iterations < maxWaitingIterations)
      {
        await Future<void>.delayed(const Duration(milliseconds: waitingTimeMs));
        iterations++;
      }
    }
  }

  Future<ContentRasterSet?> rasterizePixels({required final CoordinateColorMap drawingPixels, required final LayerState currentLayer}) async
  {
    final Frame? frame = appState.timeline.selectedFrame;
    if (drawingPixels.isNotEmpty && frame != null && frame.layerList.contains(layer: currentLayer))
    {
      final CoordinateSetI min = getMin(coordList: drawingPixels.keys.toList());
      final CoordinateSetI max = getMax(coordList: drawingPixels.keys.toList());
      final CoordinateSetI offset = CoordinateSetI(x: min.x, y: min.y);
      final CoordinateSetI size = CoordinateSetI(x: max.x - min.x + 1, y: max.y - min.y + 1);
      final ByteData byteDataImg = ByteData(size.x * size.y * 4);
      final int? layerPosition = frame.layerList.getLayerPosition(state: currentLayer);

      if (layerPosition != null)
      {
        for (final CoordinateColor entry in drawingPixels.entries)
        {
          ColorReference colRef = entry.value;
          for (int i = layerPosition - 1; i >= 0; i--)
          {
            final LayerState currentLayer = frame.layerList.getLayer(index: i);
            if (currentLayer is DrawingLayerState && currentLayer.visibilityState.value == LayerVisibilityState.visible)
            {
              final int? shadingVal = currentLayer.settingsShadingPixels[frame]?[entry.key];
              if (shadingVal != null)
              {
                final int targetShading = (colRef.colorIndex + shadingVal).clamp(0, colRef.ramp.references.length - 1);
                colRef = colRef.ramp.references[targetShading];
              }
              else
              {
                final ColorReference? layerColRef = currentLayer.rasterPixels[entry.key];
                if (layerColRef != null)
                {
                  colRef = layerColRef;
                }
              }
            }
            else if (currentLayer is ShadingLayerState && currentLayer.visibilityState.value == LayerVisibilityState.visible)
            {
              final int? shadingVal = currentLayer.shadingData[entry.key];
              if (shadingVal != null)
              {
                if (currentLayer.runtimeType == ShadingLayerState)
                {
                  final int targetShading = (colRef.colorIndex + shadingVal).clamp(0, colRef.ramp.references.length - 1);
                  colRef = colRef.ramp.references[targetShading];
                }
                else if (currentLayer is DitherLayerState)
                {
                  final int currentVal = currentLayer.getDisplayValueAt(coord: entry.key);
                  if (currentVal != 0)
                  {
                    final int newColorIndex = (colRef.colorIndex + currentVal).clamp(0, colRef.ramp.references.length - 1);
                    colRef = colRef.ramp.references[newColorIndex];
                  }

                }
              }

            }
          }

          final Color dColor = colRef.getIdColor().color;
          final int index = ((entry.key.y - offset.y) * size.x + (entry.key.x - offset.x)) * 4;
          if (index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, argbToRgba(argb: dColor.toARGB32()));
          }
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
      lPoints.add(CoordinateSetI.from(other: startPos));
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
        if (dist <= shortestDist)
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

  CoordinateColorMap getPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
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
          if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord, withSettingsPixels: true) != selectedColor) ||
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
              if (layerRef.colorIndex + 1 < layerRef.ramp.references.length)
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

  ColorReference _getColorShading({required final CoordinateSetI coord, required final AppState appState, required final ColorReference inputColor, required final LayerState currentLayer})
  {
    ColorReference retColor = inputColor;
    final Frame? frame = appState.timeline.selectedFrame;
    if (frame != null && frame.layerList.contains(layer: currentLayer))
    {
      int colorShift = 0;
      final int? currentIndex = frame.layerList.getLayerPosition(state: currentLayer);
      if (currentIndex != null)
      {
        for (int i = currentIndex; i >= 0; i--)
        {
          final LayerState layer = frame.layerList.getLayer(index: i);
          if (layer is ShadingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
          {
            if (layer.hasCoord(coord: coord))
            {
              colorShift = (inputColor.colorIndex + colorShift + layer.getDisplayValueAt(coord: coord)!).clamp(0, inputColor.ramp.references.length - 1);
            }
          }
        }
      }
      if (colorShift != 0)
      {
        retColor = inputColor.ramp.references[colorShift];
      }
    }

    return retColor;
  }

  CoordinateColorMap getPixelsToDrawForShading({required final CoordinateSetI canvasSize, required final ShadingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final ShaderOptions shaderOptions})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    final Frame? frame = appState.timeline.selectedFrame;
    if (currentLayer.lockState.value == LayerLockState.unlocked && frame != null && frame.layerList.contains(layer: currentLayer))
    {
      for (final CoordinateSetI coord in coords)
      {
        if (coord.x >= 0 && coord.y >= 0 &&
            coord.x < canvasSize.x &&
            coord.y < canvasSize.y)
        {
          final int? currentLayerPos = frame.layerList.getLayerPosition(state: currentLayer);
          if (currentLayerPos != null && currentLayerPos >= 0)
          {
            ColorReference? currentColor;
            for (int i = frame.layerList.length - 1; i >= 0; i--)
            {
              final LayerState layer = frame.layerList.getLayer(index: i);
              if (layer.visibilityState.value == LayerVisibilityState.visible)
              {
                if (layer.runtimeType == DrawingLayerState)
                {
                  final DrawingLayerState drawingLayer = layer as DrawingLayerState;
                  final ColorReference? col = drawingLayer.getDataEntry(coord: coord, withSettingsPixels: true);
                  if (col != null)
                  {
                    currentColor = col;
                  }
                }
                else if (currentColor != null && layer is ShadingLayerState)
                {
                  if (layer.getDisplayValueAt(coord: coord) != null)
                  {
                    final int newColorIndex = (currentColor.colorIndex + layer.getDisplayValueAt(coord: coord)!).clamp(0, currentColor.ramp.references.length - 1);
                    currentColor = currentColor.ramp.references[newColorIndex];
                  }
                }
              }
            }

            if (currentColor != null)
            {
              int shift = shaderOptions.shaderDirection.value == ShaderDirection.right ? 1 : -1;
              final int currentVal = currentLayer.getRawValueAt(coord: coord) ?? 0;
              if (currentVal + shift < -currentLayer.settings.shadingStepsMinus.value || currentVal + shift > currentLayer.settings.shadingStepsPlus.value)
              {
                shift = 0;
              }
              if (currentLayer.runtimeType == ShadingLayerState)
              {
                final int newColorIndex = (currentColor.colorIndex + shift).clamp(0, currentColor.ramp.references.length - 1);
                pixelMap[coord] = currentColor.ramp.references[newColorIndex];
              }
              else if (currentLayer is DitherLayerState)
              {
                final int currentVal = currentLayer.getDisplayValueAt(coord: coord);
                final int ditherVal = currentLayer.getDisplayValueAt(coord: coord, shift: shift);
                if (currentVal != ditherVal)
                {
                  final int newColorIndex = (currentColor.colorIndex - currentVal + ditherVal).clamp(0, currentColor.ramp.references.length - 1);
                  pixelMap[coord] = currentColor.ramp.references[newColorIndex];
                }
              }
            }
          }
        }
      }
    }
    return pixelMap;
  }


  CoordinateColorMap getStampPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final HashMap<CoordinateSetI, int> stampData, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor, final bool withShadingLayers = false})
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
          final int index = (selectedColor.colorIndex + stampEntry.value).clamp(0, selectedColor.ramp.references.length - 1);
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
              final int index = (layerRef.colorIndex + stampEntry.value + 1).clamp(0, layerRef.ramp.references.length - 1);
              pixelMap[coord] = layerRef.ramp.references[index];
            }
            else
            {
              final int index = (layerRef.colorIndex - stampEntry.value - 1).clamp(0, layerRef.ramp.references.length - 1);
              pixelMap[coord] = layerRef.ramp.references[index];
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

  CoordinateColorMap getStampPixelsToDrawForShading({required final CoordinateSetI canvasSize, required final ShadingLayerState currentLayer, required final HashMap<CoordinateSetI, int> stampData, required final ShaderOptions shaderOptions, final bool withShadingLayers = false})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    final Frame? frame = appState.timeline.selectedFrame;
    if (frame != null && frame.layerList.contains(layer: currentLayer))
    {
      for (final MapEntry<CoordinateSetI, int> stampEntry in stampData.entries)
      {
        final CoordinateSetI coord = stampEntry.key;

        if (coord.x >= 0 && coord.y >= 0 &&
            coord.x < canvasSize.x &&
            coord.y < canvasSize.y)
        {
          final int? currentLayerPos = frame.layerList.getLayerPosition(state: currentLayer);
          if (currentLayerPos != null && currentLayerPos >= 0)
          {
            ColorReference? currentColor;
            for (int i = frame.layerList.length - 1; i >= currentLayerPos; i--)
            {
              final LayerState layer = frame.layerList.getLayer(index: i);
              if (layer.runtimeType == DrawingLayerState)
              {
                final DrawingLayerState drawingLayer = layer as DrawingLayerState;
                final ColorReference? col = drawingLayer.getDataEntry(coord: coord, withSettingsPixels: true);
                if (col != null)
                {
                  currentColor = col;
                }
              }
              else if (currentColor != null && layer is ShadingLayerState)
              {
                if (layer.hasCoord(coord: coord))
                {
                  final int newColorIndex = (currentColor.colorIndex + layer.getDisplayValueAt(coord: coord)!).clamp(0, currentColor.ramp.references.length -1);
                  currentColor = currentColor.ramp.references[newColorIndex];
                }
              }
            }
            if (currentColor != null)
            {
              final int shadingDirection = shaderOptions.shaderDirection.value == ShaderDirection.left ? -1 : 1;
              final int shadingAmount = (shadingDirection + (stampEntry.value * shadingDirection)).clamp(-currentLayer.settings.shadingStepsMinus.value, currentLayer.settings.shadingStepsPlus.value);
              if (currentLayer.runtimeType == ShadingLayerState)
              {
                final int targetIndex = (currentColor.colorIndex + shadingAmount).clamp(0, currentColor.ramp.references.length - 1);
                pixelMap[coord] = currentColor.ramp.references[targetIndex];
              }
              else if (currentLayer is DitherLayerState)
              {
                final int currentVal = currentLayer.getDisplayValueAt(coord: coord);
                final int ditherVal = currentLayer.getDisplayValueAt(coord: coord, shift: shadingAmount);
                if (currentVal != ditherVal)
                {
                  final int newColorIndex = (currentColor.colorIndex - currentVal + ditherVal).clamp(0, currentColor.ramp.references.length - 1);
                  pixelMap[coord] = currentColor.ramp.references[newColorIndex];
                }
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

  static int getClosestPixel({required final double value, required final double pixelSize})
  {
    final double remainder = value % pixelSize;
    final double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }

  void dumpStampShading({required final ShadingLayerState shadingLayer, required final HashMap<CoordinateSetI, int> stampData, required final ShaderOptions shaderOptions})
  {
    final List<CoordinateSetI> removeCoords = <CoordinateSetI>[];
    final HashMap<CoordinateSetI, int> changeCoords = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> entry in stampData.entries)
    {
      final int shadingDirection = shaderOptions.shaderDirection.value == ShaderDirection.left ? -1 : 1;
      final int currentShift = shadingLayer.hasCoord(coord: entry.key) ? shadingLayer.getRawValueAt(coord: entry.key)! : 0;
      final int targetShift = (shadingDirection + currentShift + (entry.value * shadingDirection)).clamp(-shadingLayer.settings.shadingStepsMinus.value, shadingLayer.settings.shadingStepsPlus.value);
      if (targetShift == 0)
      {
        removeCoords.add(entry.key);
      }
      else
      {
        changeCoords[entry.key] = targetShift;
      }
    }
    shadingLayer.removeCoords(coords: removeCoords);
    shadingLayer.addCoords(coords: changeCoords);

    //appState.rasterDrawingLayersAbove();

    hasHistoryData = true;
    resetContentRaster(currentLayer: shadingLayer);
  }

  void dumpShading({required final ShadingLayerState shadingLayer, required final Set<CoordinateSetI> coordinates, required final ShaderOptions shaderOptions})
  {
    final List<CoordinateSetI> removeCoords = <CoordinateSetI>[];
    final HashMap<CoordinateSetI, int> changeCoords = HashMap<CoordinateSetI, int>();
    for (final CoordinateSetI coord in coordinates)
    {
      final int currentShift = shaderOptions.shaderDirection.value == ShaderDirection.left ? -1 : 1;
      final int targetShift = (shadingLayer.hasCoord(coord: coord) ? shadingLayer.getRawValueAt(coord: coord)! + currentShift : currentShift).clamp(-shadingLayer.settings.shadingStepsMinus.value, shadingLayer.settings.shadingStepsPlus.value);
      if (targetShift == 0)
      {
        removeCoords.add(coord);
      }
      else
      {
        changeCoords[coord] = targetShift;
      }
    }
    shadingLayer.removeCoords(coords: removeCoords);
    shadingLayer.addCoords(coords: changeCoords);

    //appState.rasterDrawingLayersAbove();

    hasHistoryData = true;
    resetContentRaster(currentLayer: shadingLayer);
  }


  Set<CoordinateSetI> getMirrorPoints({required final Set<CoordinateSetI> coords, required final CoordinateSetI canvasSize, required final double? symmetryX, required final double? symmetryY})
  {
    if (symmetryX == null && symmetryY == null)
    {
      return coords;
    }

    final Set<CoordinateSetI> mirrorPoints = <CoordinateSetI>{};
    mirrorPoints.addAll(coords);

    for (final CoordinateSetI coord in coords)
    {
      if (symmetryX != null)
      {
        final CoordinateSetI m = CoordinateSetI(x: (symmetryX * 2 - coord.x - 1).toInt(), y: coord.y);
        if (m.x >= 0 && m.x < canvasSize.x)
        {
          mirrorPoints.add(m);
        }
      }
      if (symmetryY != null)
      {
        final CoordinateSetI m = CoordinateSetI(x: coord.x, y: (symmetryY * 2 - coord.y - 1).toInt());
        if (m.y >= 0 && m.y < canvasSize.y)
        {
          mirrorPoints.add(m);
        }
      }
      if (symmetryX != null && symmetryY != null)
      {
        final CoordinateSetI m = CoordinateSetI(x: (symmetryX * 2 - coord.x - 1).toInt(), y: (symmetryY * 2 - coord.y - 1).toInt());
        if (m.x >= 0 && m.x < canvasSize.x && m.y >= 0 && m.y < canvasSize.y)
        {
          mirrorPoints.add(m);
        }
      }
    }
    return mirrorPoints;
  }

  HashMap<CoordinateSetI, int> getStampMirrorPoints({required final HashMap<CoordinateSetI, int> stampData, required final CoordinateSetI canvasSize, required final double? symmetryX, required final double? symmetryY})
  {
    if (symmetryX == null && symmetryY == null)
    {
      return stampData;
    }

    final HashMap<CoordinateSetI, int> mirrorPoints = HashMap<CoordinateSetI, int>();
    mirrorPoints.addAll(stampData);

    for (final MapEntry<CoordinateSetI, int> entry in stampData.entries)
    {
      if (symmetryX != null)
      {
        final CoordinateSetI m = CoordinateSetI(x: (symmetryX * 2 - entry.key.x - 1).toInt(), y: entry.key.y);
        if (m.x >= 0 && m.x < canvasSize.x)
        {
          mirrorPoints[m] = entry.value;
        }
      }
      if (symmetryY != null)
      {
        final CoordinateSetI m = CoordinateSetI(x: entry.key.x, y: (symmetryY * 2 - entry.key.y - 1).toInt());
        if (m.y >= 0 && m.y < canvasSize.y)
        {
          mirrorPoints[m] = entry.value;
        }
      }
      if (symmetryX != null && symmetryY != null)
      {
        final CoordinateSetI m = CoordinateSetI(x: (symmetryX * 2 - entry.key.x - 1).toInt(), y: (symmetryY * 2 - entry.key.y - 1).toInt());
        if (m.x >= 0 && m.x < canvasSize.x && m.y >= 0 && m.y < canvasSize.y)
        {
          mirrorPoints[m] = entry.value;
        }
      }
    }
    return mirrorPoints;
  }

  ui.Path getPathFromList({required final List<MapEntry<int, int>> pointList, required final CoordinateSetD offsetPos, required final double scaling})
  {
    final ui.Path path = ui.Path();
    bool firstHandled = false;
    for (final MapEntry<int, int> entry in pointList)
    {
      if (!firstHandled)
      {
        path.moveTo(offsetPos.x + (entry.key * scaling), offsetPos.y + (entry.value * scaling));
        firstHandled = true;
      }
      else
      {
        path.lineTo(offsetPos.x + (entry.key * scaling),offsetPos.y + (entry.value * scaling));
      }
    }
    return path;
  }

}
