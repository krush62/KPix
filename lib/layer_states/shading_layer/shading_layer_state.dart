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
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings_widget.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class ShadingLayerState extends RasterableLayerState
{
  final ShadingLayerSettings settings;
  final HashMap<int, int> _thumbnailBrightnessMap = HashMap<int, int>();
  final HashMap<CoordinateSetI, int> _shadingData = HashMap<CoordinateSetI, int>();

  factory ShadingLayerState()
  {
    final ShadingLayerSettings settings = ShadingLayerSettings.defaultValue(constraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints);
    return ShadingLayerState._(settings: settings);
  }

  ShadingLayerState._({required this.settings}) : super(layerSettings: settings)
  {
    _init();
  }

  ShadingLayerState.withData({required final HashMap<CoordinateSetI, int> data, required final LayerLockState lState, required final ShadingLayerSettings newSettings, super.layerStack}) :
        settings = newSettings,
        super(layerSettings: newSettings)
  {
    _init();
    for (final MapEntry<CoordinateSetI, int> entry in data.entries)
    {
      _shadingData[entry.key] = entry.value;
    }
    lockState.value = lState;
  }

  factory ShadingLayerState.from({required final ShadingLayerState other, final List<RasterableLayerState>? layerStack})
  {
    final HashMap<CoordinateSetI, int> data = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> entry in other.shadingData.entries)
    {
      data[entry.key] = entry.value;
    }
    final ShadingLayerSettings settings = ShadingLayerSettings.from(other: other.settings);

    return ShadingLayerState.withData(data: data, lState: other.lockState.value, newSettings: settings, layerStack: layerStack);
  }

  void _update()
  {
    int counter = 0;
    final int brightnessStep = 255 ~/ (settings.shadingStepsMinus.value + settings.shadingStepsPlus.value + 1);
    for (int i = -settings.shadingStepsMinus.value; i <= settings.shadingStepsPlus.value; i++)
    {
      _thumbnailBrightnessMap[i] = counter * brightnessStep;
      counter++;
    }
  }

  void _init()
  {
    _update();
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {_updateTimerCallback(timer: t);});

    settings.addListener(() {
      _settingsChanged();
    });
  }

  void _settingsChanged()
  {
    for (final MapEntry<CoordinateSetI, int> entry in _shadingData.entries)
    {
      if (_shadingData[entry.key] != null)
      {
        _shadingData[entry.key] = _shadingData[entry.key]!.clamp(-settings.shadingStepsMinus.value, settings.shadingStepsPlus.value);
      }

    }
    doManualRaster = true;
  }

  HashMap<CoordinateSetI, int> get shadingData
  {
    return _shadingData;
  }

  bool hasCoord({required final CoordinateSetI coord})
  {
    return _shadingData.containsKey(coord);
  }

  int? getValueAt({required final CoordinateSetI coord})
  {
    return _shadingData[coord];
  }


  void removeCoords({required final Iterable<CoordinateSetI> coords})
  {
    if (lockState.value == LayerLockState.unlocked)
    {
      for (final CoordinateSetI coord in coords)
      {
        if (_shadingData.containsKey(coord))
        {
          _shadingData.remove(coord);
        }
      }
      doManualRaster = true;
    }
  }

  void addCoords({required final HashMap<CoordinateSetI, int> coords})
  {
    if (lockState.value == LayerLockState.unlocked)
    {
      for (final MapEntry<CoordinateSetI, int> entry in coords.entries)
      {
        _shadingData[entry.key] = entry.value.clamp(-settings.shadingStepsMinus.value, settings.shadingStepsPlus.value);
      }
      doManualRaster = true;
    }
  }

  Future<(ui.Image, ui.Image)> _createRasters() async
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
      for (int x = 0; x < appState.canvasSize.x; x++)
      {
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
          final int? valAt = _shadingData[CoordinateSetI(x: x, y: y)];
          int brightVal = _thumbnailBrightnessMap[0]!;
          if (valAt != null)
          {
            brightVal = _thumbnailBrightnessMap[valAt]?? 0;
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
                  final int targetColorIndex = (currentColorIndex + valAt).clamp(0, refCol.ramp.references.length - 1);
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

  void _rasterCreated({required final ui.Image thb, required final ui.Image img})
  {
    thumbnail.value = thb;
    previousRaster = rasterImage.value;
    rasterImage.value = img;
    isRasterizing = false;
    doManualRaster = false;
    if (layerStack == null)
    {
      GetIt.I.get<AppState>().newRasterData(layer: this);
    }

  }

  void _updateTimerCallback({required final Timer timer})
  {
    if (doManualRaster && !isRasterizing)
    {
      isRasterizing = true;
      _createRasters().then((final (ui.Image, ui.Image) images)
      {
        _rasterCreated(img: images.$1, thb: images.$2);
      });
    }
  }

  @override
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    final HashMap<CoordinateSetI, int> croppedContent = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> entry in _shadingData.entries)
    {
      final CoordinateSetI newCoord = CoordinateSetI(x: entry.key.x + offset.x, y: entry.key.y + offset.y);
      if (newCoord.x >= 0 && newCoord.x < newSize.x && newCoord.y >= 0 && newCoord.y < newSize.y)
      {
        croppedContent[newCoord] = entry.value;
      }
    }

    _shadingData.clear();
    _shadingData.addAll(croppedContent);
  }

  @override
  LayerSettingsWidget getSettingsWidget() {
    return ShadingLayerSettingsWidget(settings: settings);
  }

}
