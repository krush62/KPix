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

import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer_settings.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class HistoryDrawingLayer extends HistoryLayer
{
  final LayerLockState lockState;
  final HashMap<CoordinateSetI, HistoryColorReference> data;
  final HistoryDrawingLayerSettings settings;
  HistoryDrawingLayer({required super.visibilityState, required super.layerIdentity, required this.lockState, required this.data, required this.settings});
  factory HistoryDrawingLayer.fromDrawingLayerState({required final DrawingLayerState layerState, required final List<HistoryRampData> ramps })
  {
    final LayerVisibilityState visState = layerState.visibilityState.value;
    final LayerLockState  lState = layerState.lockState.value;
    final int identity = identityHashCode(layerState);
    final HashMap<CoordinateSetI, HistoryColorReference> dt = HashMap<CoordinateSetI, HistoryColorReference>();
    final CoordinateColorMap lData = layerState.getData();
    for (final CoordinateColor entry in lData.entries)
    {
      final int? rampIndex = getRampIndex(uuid: entry.value.ramp.uuid, ramps: ramps);
      if (rampIndex != null)
      {
        dt[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: entry.value.colorIndex, rampIndex: rampIndex);
      }
    }
    for (final CoordinateColorNullable entry in layerState.rasterQueue.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = getRampIndex(uuid: entry.value!.ramp.uuid, ramps: ramps);
        if (rampIndex != null)
        {
          dt[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: entry.value!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        dt.remove(entry.key);
      }
    }
    final HistoryDrawingLayerSettings settings = HistoryDrawingLayerSettings.fromDrawingLayerSettings(settings: layerState.settings);
    return HistoryDrawingLayer(visibilityState: visState, layerIdentity: identity, lockState: lState, data: dt, settings: settings);
  }
}
