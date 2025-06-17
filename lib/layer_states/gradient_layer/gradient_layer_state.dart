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
import 'dart:ui' as ui;

import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/gradient_layer/gradient_layer_settings.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';

class GradientLayerState extends RasterableLayerState
{
  final GradientLayerSettings settings;
  final HashMap<CoordinateSetI, int> _shadingData = HashMap<CoordinateSetI, int>();
  final HashMap<int, int> _thumbnailBrightnessMap = HashMap<int, int>();
  static const int _shadingSteps = 16;
  HashMap<int, List<List<int>>> _ditherMap = HashMap<int, List<List<int>>>();

  HashMap<CoordinateSetI, int> get shadingData
  {
    return _shadingData;
  }

  GradientLayerState._({required this.settings}) : super(layerSettings: settings)
  {
    _init();
  }

  GradientLayerState.withData({required final HashMap<CoordinateSetI, int> data, required final LayerLockState lState, required final GradientLayerSettings newSettings, super.layerStack}) :
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

  factory GradientLayerState.from({required final GradientLayerState other, final List<RasterableLayerState>? layerStack})
  {
    final HashMap<CoordinateSetI, int> data = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> entry in other.shadingData.entries)
    {
      data[entry.key] = entry.value;
    }
    final GradientLayerSettings settings = GradientLayerSettings.from(other: other.settings);

    return GradientLayerState.withData(data: data, lState: other.lockState.value, newSettings: settings, layerStack: layerStack);
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

  void _update()
  {
    int counter = 0;
    const int brightnessStep = 255 ~/ (_shadingSteps * 2 + 1);
    for (int i = -_shadingSteps; i <= _shadingSteps; i++)
    {
      _thumbnailBrightnessMap[i] = counter * brightnessStep;
      counter++;
    }
  }

  void _init()
  {
    _createDitherMap();
    _update();
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {_updateTimerCallback(timer: t);});
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

  @override
  LayerSettingsWidget getSettingsWidget() {
    // TODO: implement getSettingsWidget
    throw UnimplementedError();
  }

  @override
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    // TODO: implement resizeLayer
  }


}
