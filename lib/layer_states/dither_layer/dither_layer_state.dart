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
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class DitherLayerState extends ShadingLayerState
{
  final HashMap<int, List<List<int>>> _ditherMap = HashMap<int, List<List<int>>>();

  DitherLayerState() : this._();

  DitherLayerState._() : super()
  {
    settings.shadingStepsMinus.value = settings.constraints.ditherStepsMax;
    settings.shadingStepsPlus.value = settings.constraints.ditherStepsMax;
    _createDitherMap();
    update();
  }

  @override
  factory DitherLayerState.from({required final DitherLayerState other, final List<RasterableLayerState>? layerStack})
  {
    final HashMap<CoordinateSetI, int> data = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> entry in other.shadingData.entries)
    {
      data[entry.key] = entry.value;
    }
    final ShadingLayerSettings settings = ShadingLayerSettings.from(other: other.settings);

    return DitherLayerState.withData(data: data, lState: other.lockState.value, newSettings: settings, layerStack: layerStack);
  }

  @override
  DitherLayerState.withData({required super.data, required super.lState, required super.newSettings, super.layerStack})
  : super.withData()
  {
    settings.shadingStepsMinus.value = settings.constraints.ditherStepsMax;
    settings.shadingStepsPlus.value = settings.constraints.ditherStepsMax;
    _createDitherMap();
    update();
  }


  void _createDitherMap()
  {
    _ditherMap.clear();

    _ditherMap[0] = <List<int>>[
      <int>[0, 0, 0, 0],
      <int>[0, 0, 0, 0],
      <int>[0, 0, 0, 0],
      <int>[0, 0, 0, 0],
    ];
    _ditherMap[1] = <List<int>>[
      <int>[0, 0, 0, 0],
      <int>[0, 1, 0, 0],
      <int>[0, 0, 0, 0],
      <int>[0, 0, 0, 0],
    ];
    _ditherMap[2] = <List<int>>[
      <int>[0, 0, 0, 0],
      <int>[0, 1, 0, 0],
      <int>[0, 0, 0, 0],
      <int>[0, 0, 0, 1],
    ];
    _ditherMap[3] = <List<int>>[
      <int>[0, 0, 0, 0],
      <int>[0, 1, 0, 1],
      <int>[0, 0, 0, 0],
      <int>[0, 0, 0, 1],
    ];
    _ditherMap[4] = <List<int>>[
      <int>[0, 0, 0, 0],
      <int>[0, 1, 0, 1],
      <int>[0, 0, 0, 0],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[5] = <List<int>>[
      <int>[1, 0, 0, 0],
      <int>[0, 1, 0, 1],
      <int>[0, 0, 0, 0],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[6] = <List<int>>[
      <int>[1, 0, 0, 0],
      <int>[0, 1, 0, 1],
      <int>[0, 0, 1, 0],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[7] = <List<int>>[
      <int>[1, 0, 1, 0],
      <int>[0, 1, 0, 1],
      <int>[0, 0, 1, 0],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[8] = <List<int>>[
      <int>[1, 0, 1, 0],
      <int>[0, 1, 0, 1],
      <int>[1, 0, 1, 0],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[9] = <List<int>>[
      <int>[1, 1, 1, 0],
      <int>[0, 1, 0, 1],
      <int>[1, 0, 1, 0],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[10] = <List<int>>[
      <int>[1, 1, 1, 0],
      <int>[0, 1, 0, 1],
      <int>[1, 0, 1, 1],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[11] = <List<int>>[
      <int>[1, 1, 1, 0],
      <int>[0, 1, 0, 1],
      <int>[1, 1, 1, 1],
      <int>[0, 1, 0, 1],
    ];
    _ditherMap[12] = <List<int>>[
      <int>[1, 1, 1, 0],
      <int>[0, 1, 0, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 0, 1],
    ];
    _ditherMap[13] = <List<int>>[
      <int>[1, 1, 1, 1],
      <int>[0, 1, 0, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 0, 1],
    ];
    _ditherMap[14] = <List<int>>[
      <int>[1, 1, 1, 1],
      <int>[0, 1, 1, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 0, 1],
    ];
    _ditherMap[15] = <List<int>>[
      <int>[1, 1, 1, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 0, 1],
    ];
    _ditherMap[16] = <List<int>>[
      <int>[1, 1, 1, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 1, 1],
      <int>[1, 1, 1, 1],
    ];
    final List<int> positiveKeys = _ditherMap.keys.toList();
    for (final int pKey in positiveKeys)
    {
      final List<List<int>> negativeList = <List<int>>[];
      for (int i = 0; i < 4; i++)
      {
        final List<int> row = <int>[];
        for (int j = 0; j < 4; j++)
        {
          row.add(_ditherMap[pKey]![i][j] == 1 ? -1 : 0);
        }
        negativeList.add(row);
      }
      _ditherMap[-pKey] = negativeList;
    }
  }

  @override
  Future<(ui.Image, ui.Image)> createRasters() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final ByteData byteDataThb = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    final ByteData byteDataImg = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    final CoordinateColorMap allColorPixels = CoordinateColorMap();

    final List<RasterableLayerState> rasterLayers = layerStack != null ? layerStack! : appState.visibleRasterLayers.toList();
    int currentIndex = -1;
    for (int i = 0; i < rasterLayers.length; i++)
    {
      if (rasterLayers[i] == this)
      {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex != -1)
    {
      //_ditherData.clear();
      for (int x = 0; x < appState.canvasSize.x; x++)
      {
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
          final int? valAt = sData[coord];
          int brightVal = thumbnailBrightnessMap[0]!;
          if (valAt != null)
          {
            brightVal = thumbnailBrightnessMap[valAt]?? 0;
            if (currentIndex != -1)
            {
              for (int i = currentIndex + 1; i < rasterLayers.length; i++)
              {
                final RasterableLayerState layer = rasterLayers[i];
                ColorReference? refCol;
                if (layer.visibilityState.value == LayerVisibilityState.visible)
                {
                  refCol = layer.rasterPixels[coord];
                }
                if (refCol != null)
                {
                  final int currentColorIndex = refCol.colorIndex;
                  final int ditherVal = getDisplayValueAt(coord: coord);
                  final int targetColorIndex = (currentColorIndex + ditherVal).clamp(0, refCol.ramp.references.length - 1);
                  allColorPixels[coord] = refCol.ramp.references[targetColorIndex];
                  final Color usageColor = refCol.ramp.references[targetColorIndex].getIdColor().color;
                  final int index = (y * appState.canvasSize.x + x) * 4;
                  if (index >= 0 && index < byteDataImg.lengthInBytes)
                  {
                    byteDataImg.setUint32(index, argbToRgba(argb: usageColor.toARGB32()));
                  }
                  break;
                }
              }
            }
          }
          final int pixelIndex = (y * appState.canvasSize.x + x) * 4;
          byteDataThb.setUint8(pixelIndex + 0, brightVal);
          byteDataThb.setUint8(pixelIndex + 1, brightVal);
          byteDataThb.setUint8(pixelIndex + 2, brightVal);
          byteDataThb.setUint8(pixelIndex + 3, 255);
        }
      }
      rasterPixels = allColorPixels;
    }

    final Completer<ui.Image> completerThb = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataThb.buffer.asUint8List(),
        appState.canvasSize.x,
        appState.canvasSize.y,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      completerThb.complete(convertedImage);
    }
    );
    final ui.Image thbImg = await completerThb.future;

    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataImg.buffer.asUint8List(),
        appState.canvasSize.x,
        appState.canvasSize.y,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      completerImg.complete(convertedImage);
    }
    );
    final ui.Image rasterImg = await completerImg.future;
    return (rasterImg, thbImg);
  }

  /*@override
  HashMap<CoordinateSetI, int> get shadingData
  {
    return _ditherData;
  }*/

  @override
  bool hasCoord({required final CoordinateSetI coord})
  {
    return sData.containsKey(coord);
  }

  @override
  int getDisplayValueAt({required final CoordinateSetI coord, final int shift = 0})
  {
    final int? valAt = getRawValueAt(coord: coord);
    if (valAt != null)
    {
      final int shiftedVal = valAt + shift;
      if (shiftedVal != 0 && _ditherMap.containsKey(shiftedVal))
      {
        return _ditherMap[shiftedVal]![coord.y % 4][coord.x % 4];
      }
      else
      {
        return 0;
      }
    }
    else if (shift != 0)
    {
      return _ditherMap[shift]![coord.y % 4][coord.x % 4];
    }
    else
    {
      return 0;
    }
  }

  @override
  int? getRawValueAt({required final CoordinateSetI coord})
  {
    return sData[coord];
  }



}
