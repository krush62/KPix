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
import 'package:kpix/managers/history/history_pixel_change.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class HistoryDrawingLayer extends HistoryLayer
{
  static const int _maxDeltaDepth = 30;
  final LayerLockState lockState;
  final HistoryDrawingLayerSettings settings;
  final int _depth;
  final HashMap<CoordinateSetI, HistoryColorReference>? _fullData;
  final HashMap<CoordinateSetI, HistoryPixelChange>? _cumulativeDelta;
  final HistoryDrawingLayer? _parent;

  HistoryDrawingLayer.full({
    required super.visibilityState,
    required super.layerIdentity,
    required this.lockState,
    required this.settings,
    required final HashMap<CoordinateSetI, HistoryColorReference> fullData,
  })  : _depth         = 0,
        _fullData       = fullData,
        _cumulativeDelta = null,
        _parent         = null;

  HistoryDrawingLayer._delta({
    required super.visibilityState,
    required super.layerIdentity,
    required this.lockState,
    required this.settings,
    required final int depth,
    required final HashMap<CoordinateSetI, HistoryPixelChange> cumulativeDelta,
    required final HistoryDrawingLayer parent,
  })  : assert(parent._depth == 0, '_parent must always be a full snapshot'),
        _depth          = depth,
        _fullData       = null,
        _cumulativeDelta = cumulativeDelta,
        _parent         = parent;

  bool get isFullSnapshot => _depth == 0;

  HashMap<CoordinateSetI, HistoryColorReference> get data
  {
    if (_fullData != null) return _fullData;
    return _resolveData();
  }

  factory HistoryDrawingLayer.fromDrawingLayerState({
    required final DrawingLayerState  layerState,
    required final List<HistoryRampData> ramps,
  })
  {
    final Map<String, int> rampIndexByUuid = _buildRampIndex(ramps);
    return HistoryDrawingLayer.full(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryDrawingLayerSettings.fromDrawingLayerSettings(settings: layerState.settings),
      fullData:        _buildFullData(layerState: layerState, rampIndexByUuid: rampIndexByUuid),
    );
  }

  factory HistoryDrawingLayer.deltaFrom({
    required final DrawingLayerState  layerState,
    required final List<HistoryRampData> ramps,
    required final HistoryDrawingLayer   previousLayer,
  })
  {

    if (previousLayer._depth >= _maxDeltaDepth || layerState.rasterQueue.isEmpty)
    {
      return HistoryDrawingLayer.fromDrawingLayerState(
        layerState: layerState,
        ramps:      ramps,
      );
    }

    final Map<String, int> rampIndexByUuid = _buildRampIndex(ramps);

      final HashMap<CoordinateSetI, HistoryPixelChange> stepDelta =
    _computeStepDeltaFromRasterQueue(
      layerState:     layerState,
      previousLayer:  previousLayer,
      rampIndexByUuid: rampIndexByUuid,
    );

    final HistoryDrawingLayer parent =
    previousLayer.isFullSnapshot ? previousLayer : previousLayer._parent!;

    final HashMap<CoordinateSetI, HistoryPixelChange> newCumulative =
    previousLayer.isFullSnapshot
        ? stepDelta
        : _mergeCumulative(
      previous: previousLayer._cumulativeDelta!,
      step:     stepDelta,
    );

    return HistoryDrawingLayer._delta(
      visibilityState:  layerState.visibilityState.value,
      layerIdentity:    identityHashCode(layerState),
      lockState:        layerState.lockState.value,
      settings:         HistoryDrawingLayerSettings.fromDrawingLayerSettings(settings: layerState.settings),
      depth:            previousLayer._depth + 1,
      cumulativeDelta:  newCumulative,
      parent:           parent,
    );
  }

  HashMap<CoordinateSetI, HistoryColorReference> _resolveData()
  {
    final HashMap<CoordinateSetI, HistoryColorReference> resolved =
    HashMap<CoordinateSetI, HistoryColorReference>.from(_parent!._fullData!);

    for (final MapEntry<CoordinateSetI, HistoryPixelChange> e in _cumulativeDelta!.entries)
    {
      if (e.value.after != null)
      {
        resolved[e.key] = e.value.after!;
      }
      else
      {
        resolved.remove(e.key);
      }
    }
    return resolved;
  }

  HistoryColorReference? _resolveKey(final CoordinateSetI key)
  {
    if (_fullData != null) return _fullData[key];

    if (_cumulativeDelta!.containsKey(key))
    {
      return _cumulativeDelta[key]!.after;
    }

    return _parent!._fullData![key];
  }

  static Map<String, int> _buildRampIndex(final List<HistoryRampData> ramps)
  {
    return <String, int>{for (int r = 0; r < ramps.length; r++) ramps[r].uuid: r};
  }

  static HashMap<CoordinateSetI, HistoryColorReference> _buildFullData({
    required final DrawingLayerState layerState,
    required final Map<String, int>  rampIndexByUuid,
  })
  {
    final HashMap<CoordinateSetI, HistoryColorReference> dt =
    HashMap<CoordinateSetI, HistoryColorReference>();

    for (final CoordinateColor entry in layerState.getData().entries)
    {
      final int? rampIndex = rampIndexByUuid[entry.value.ramp.uuid];
      if (rampIndex != null)
      {
        dt[entry.key] =
            HistoryColorReference(colorIndex: entry.value.colorIndex, rampIndex: rampIndex);
      }
    }

    for (final CoordinateColorNullable entry in layerState.rasterQueue.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = rampIndexByUuid[entry.value!.ramp.uuid];
        if (rampIndex != null)
        {
          dt[entry.key] =
              HistoryColorReference(colorIndex: entry.value!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        dt.remove(entry.key);
      }
    }
    return dt;
  }

  static HashMap<CoordinateSetI, HistoryPixelChange> _computeStepDeltaFromRasterQueue({
    required final DrawingLayerState  layerState,
    required final HistoryDrawingLayer previousLayer,
    required final Map<String, int>   rampIndexByUuid,
  })
  {
    final HashMap<CoordinateSetI, HistoryPixelChange> delta =
    HashMap<CoordinateSetI, HistoryPixelChange>();

    for (final CoordinateColorNullable entry in layerState.rasterQueue.entries)
    {
      final HistoryColorReference? before = previousLayer._resolveKey(entry.key);

      final HistoryColorReference? after;
      if (entry.value != null)
      {
        final int? rampIndex = rampIndexByUuid[entry.value!.ramp.uuid];
        after = rampIndex != null
            ? HistoryColorReference(
            colorIndex: entry.value!.colorIndex, rampIndex: rampIndex)
            : null;
      }
      else
      {
        after = null;
      }

      if (before != after)
      {
        delta[entry.key] = HistoryPixelChange(before: before, after: after);
      }
    }
    return delta;
  }

  static HashMap<CoordinateSetI, HistoryPixelChange> _mergeCumulative({
    required final HashMap<CoordinateSetI, HistoryPixelChange> previous,
    required final HashMap<CoordinateSetI, HistoryPixelChange> step,
  })
  {
    if (step.isEmpty) return previous; // nothing changed — share the same map

    final HashMap<CoordinateSetI, HistoryPixelChange> result =
    HashMap<CoordinateSetI, HistoryPixelChange>.from(previous);

    for (final MapEntry<CoordinateSetI, HistoryPixelChange> e in step.entries)
    {
      final HistoryPixelChange? existing = result[e.key];

      if (existing != null)
      {
        if (e.value.after == existing.before)
        {
          result.remove(e.key);
        }
        else
        {
          result[e.key] = HistoryPixelChange(before: existing.before, after: e.value.after);
        }
      }
      else
      {
        result[e.key] = e.value;
      }
    }
    return result;
  }
}
