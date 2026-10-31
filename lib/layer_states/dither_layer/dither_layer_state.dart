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


import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/history/history_dither_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/layer_settings/shading_layer_settings_widget.dart';

class DitherLayerState extends ShadingLayerState
{
  @override
  LayerKind get kind => LayerKind.dither;

  final HashMap<int, List<List<int>>> _ditherMap = HashMap<int, List<List<int>>>();

  @override IconData get icon => Icons.gradient;

  @override
  DitherLayerState copy({final List<RasterableLayerState>? layerStack}) =>
      DitherLayerState.from(other: this, layerStack: layerStack);


  @override
  HistoryDitherLayer toHistoryLayer({
  required final List<HistoryRampData> ramps,
  final HistoryLayer? previousLayer,
  })
  {
    //a snapshot shares the tiles that did not change, so there is no need for
    //a delta against the previous one
    return HistoryDitherLayer.fromDitherLayerState(layerState: this);
  }

  DitherLayerState() : this._();

  DitherLayerState._() : super()
  {
    settings.shadingStepsMinus.value = settings.constraints.ditherStepsMax;
    settings.shadingStepsPlus.value = settings.constraints.ditherStepsMax;
    _createDitherMap();
    update();
  }

  factory DitherLayerState.from({required final DitherLayerState other, final List<RasterableLayerState>? layerStack})
  {
    final ShadingLayerSettings settings = ShadingLayerSettings.from(other: other.settings);
    return DitherLayerState.withData(data: other.shadingValues.copy(), lState: other.lockState.value, newSettings: settings, layerStack: layerStack);
  }

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


  /// The step the dither pattern of [value] makes at [x]|[y].
  @override
  int stepAt({required final int value, required final int x, required final int y})
  {
    return value != 0 && _ditherMap.containsKey(value) ? _ditherMap[value]![y % 4][x % 4] : 0;
  }

  @override
  int getDisplayValueAt({required final CoordinateSetI coord, final int shift = 0})
  {
    final int? valAt = getRawValueAt(coord: coord);
    if (valAt != null)
    {
      return stepAt(value: valAt + shift, x: coord.x, y: coord.y);
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
  LayerSettingsWidget getSettingsWidget() {
    return ShadingLayerSettingsWidget(settings: settings, isForDithering: true);
  }


}
