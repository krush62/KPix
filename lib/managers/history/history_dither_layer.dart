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

import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_shading_layer_settings.dart';
import 'package:kpix/util/helper.dart';

class HistoryDitherLayer extends HistoryShadingLayer
{

  HistoryDitherLayer({required super.visibilityState, required super.layerIdentity, required super.lockState, required super.data, required super.settings});
  factory HistoryDitherLayer.fromDitherLayerState({required final DitherLayerState layerState})
  {
    final LayerVisibilityState visState = layerState.visibilityState.value;
    final LayerLockState  lState = layerState.lockState.value;
    final int identity = identityHashCode(layerState);

    final HashMap<CoordinateSetI, int> dt = HashMap<CoordinateSetI, int>();
    final HashMap<CoordinateSetI, int> lData = layerState.shadingData;
    for (final MapEntry<CoordinateSetI, int> entry in lData.entries)
    {
      dt[entry.key] = entry.value;
    }
    final HistoryShadingLayerSettings settings = HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings);
    return HistoryDitherLayer(visibilityState: visState, layerIdentity: identity, lockState: lState, data: dt, settings: settings);
  }
}
