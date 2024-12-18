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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';

class ShadingLayerState extends LayerState
{
  static const int shadingMax = 5;
  static const int _brightnessStep = 255 ~/ ((shadingMax * 2) + 1);
  final HashMap<int, int> _thumbnailBrightnessMap = HashMap<int, int>();
  final HashMap<CoordinateSetI, int> _shadingData = HashMap<CoordinateSetI, int>();
  final ValueNotifier<LayerLockState> lockState = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
  bool _isRendering = false;
  bool _shouldRender = true;

  ShadingLayerState()
  {
    int counter = 0;
    for (int i = -shadingMax; i <= shadingMax; i++)
    {
      _thumbnailBrightnessMap[i] = counter * _brightnessStep;
      counter++;
    }
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {_updateTimerCallback(timer: t);});

  }

  void manualRender()
  {
    _shouldRender = true;
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
    for (final CoordinateSetI coord in coords)
    {
      if (_shadingData.containsKey(coord))
      {
        _shadingData.remove(coord);
      }
    }
    _shouldRender = true;
  }

  void addCoords({required final HashMap<CoordinateSetI, int> coords})
  {
    for (final MapEntry<CoordinateSetI, int> entry in coords.entries)
    {
      _shadingData[entry.key] = entry.value;
    }
    _shouldRender = true;
  }

  Future<ui.Image> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final ByteData byteDataImg = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    for (int x = 0; x < appState.canvasSize.x; x++)
    {
      for (int y = 0; y < appState.canvasSize.y; y++)
      {
        final int? valAt = _shadingData[CoordinateSetI(x: x, y: y)];
        int brightVal = _thumbnailBrightnessMap[0]!;
        if (valAt != null)
        {
          brightVal = _thumbnailBrightnessMap[valAt]?? 0;
        }
        final int pixelIndex = (y * appState.canvasSize.x + x) * 4;
        byteDataImg.setUint8(pixelIndex + 0, brightVal);
        byteDataImg.setUint8(pixelIndex + 1, brightVal);
        byteDataImg.setUint8(pixelIndex + 2, brightVal);
        byteDataImg.setUint8(pixelIndex + 3, 255);
      }
    }

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
    return completerImg.future;
  }

  void _rasterCreated({required final ui.Image image})
  {
    thumbnail.value = image;
    _isRendering = false;
    _shouldRender = false;
  }

  void _updateTimerCallback({required final Timer timer})
  {
    if (_shouldRender && !_isRendering)
    {
      _isRendering = true;
      _createRaster().then((final ui.Image image)
      {
        _rasterCreated(image: image);
      });
    }
  }

}
