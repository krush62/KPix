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
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_shading_change.dart';
import 'package:kpix/managers/history/history_shading_layer_settings.dart';
import 'package:kpix/util/helper.dart';

class HistoryShadingLayer extends HistoryLayer
{
  static const int _maxDeltaDepth = 30;
  final LayerLockState lockState;
  final HistoryShadingLayerSettings settings;

  final int _depth;
  final HashMap<CoordinateSetI, int>? _fullData;
  final HashMap<CoordinateSetI, HistoryShadingChange>? _cumulativeDelta;
  final HistoryShadingLayer? _parent;

  HistoryShadingLayer.full({
    required super.visibilityState,
    required super.layerIdentity,
    required this.lockState,
    required this.settings,
    required final HashMap<CoordinateSetI, int> fullData,
  })  : _depth          = 0,
        _fullData        = fullData,
        _cumulativeDelta = null,
        _parent          = null;

  HistoryShadingLayer._delta({
    required super.visibilityState,
    required super.layerIdentity,
    required this.lockState,
    required this.settings,
    required final int depth,
    required final HashMap<CoordinateSetI, HistoryShadingChange>   cumulativeDelta,
    required final HistoryShadingLayer parent,
  })  : assert(parent._depth == 0, '_parent must always be a full snapshot'),
        _depth          = depth,
        _fullData        = null,
        _cumulativeDelta = cumulativeDelta,
        _parent          = parent;

  bool get isFullSnapshot => _depth == 0;

  HashMap<CoordinateSetI, int> get data
  {
    if (_fullData != null) return _fullData;
    return _resolveData();
  }

  factory HistoryShadingLayer.fromShadingLayerState({required final ShadingLayerState layerState})
  {
    return HistoryShadingLayer.full(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings),
      fullData:        _buildFullData(layerState.shadingData),
    );
  }

  factory HistoryShadingLayer.deltaFrom({
    required final ShadingLayerState  layerState,
    required final HistoryShadingLayer previousLayer,
  })
  {
    if (previousLayer._depth >= _maxDeltaDepth)
    {
      return HistoryShadingLayer.fromShadingLayerState(layerState: layerState);
    }

    final HashMap<CoordinateSetI, HistoryShadingChange> stepDelta =
    _computeStepDelta(
      newData:       layerState.shadingData,
      previousLayer: previousLayer,
    );

    if (stepDelta.isEmpty) return previousLayer;

    final HistoryShadingLayer parent =
    previousLayer.isFullSnapshot ? previousLayer : previousLayer._parent!;

    final HashMap<CoordinateSetI, HistoryShadingChange> newCumulative =
    previousLayer.isFullSnapshot
        ? stepDelta
        : _mergeCumulative(previous: previousLayer._cumulativeDelta!, step: stepDelta);

    return HistoryShadingLayer._delta(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings),
      depth:           previousLayer._depth + 1,
      cumulativeDelta: newCumulative,
      parent:          parent,
    );
  }

  HashMap<CoordinateSetI, int> _resolveData()
  {
    final HashMap<CoordinateSetI, int> resolved =
    HashMap<CoordinateSetI, int>.from(_parent!._fullData!);

    for (final MapEntry<CoordinateSetI, HistoryShadingChange> e in _cumulativeDelta!.entries)
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

  int? _resolveKey(final CoordinateSetI key)
  {
    if (_fullData != null) return _fullData[key];

    if (_cumulativeDelta!.containsKey(key))
    {
      return _cumulativeDelta[key]!.after; // may be null (coordinate erased)
    }

    return _parent!._fullData![key];
  }

  static HashMap<CoordinateSetI, int> _buildFullData(
      final HashMap<CoordinateSetI, int> source,)
  {
    final HashMap<CoordinateSetI, int> dt = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> e in source.entries)
    {
      dt[e.key] = e.value;
    }
    return dt;
  }

  static HashMap<CoordinateSetI, HistoryShadingChange> _computeStepDelta({
    required final HashMap<CoordinateSetI, int>  newData,
    required final HistoryShadingLayer            previousLayer,
  })
  {
    final HashMap<CoordinateSetI, HistoryShadingChange> delta =
    HashMap<CoordinateSetI, HistoryShadingChange>();

    for (final MapEntry<CoordinateSetI, int> e in newData.entries)
    {
      final int? before = previousLayer._resolveKey(e.key);
      if (before != e.value)
      {
        delta[e.key] = HistoryShadingChange(before: before, after: e.value);
      }
    }

    final Iterable<CoordinateSetI> prevKeys = previousLayer.isFullSnapshot
        ? previousLayer._fullData!.keys
        : previousLayer._resolveData().keys;

    for (final CoordinateSetI key in prevKeys)
    {
      if (!newData.containsKey(key))
      {
        delta[key] = HistoryShadingChange(
          before: previousLayer._resolveKey(key),
        );
      }
    }

    return delta;
  }

  static HashMap<CoordinateSetI, HistoryShadingChange> _mergeCumulative({
    required final HashMap<CoordinateSetI, HistoryShadingChange> previous,
    required final HashMap<CoordinateSetI, HistoryShadingChange> step,
  })
  {
    if (step.isEmpty) return previous;

    final HashMap<CoordinateSetI, HistoryShadingChange> result =
    HashMap<CoordinateSetI, HistoryShadingChange>.from(previous);

    for (final MapEntry<CoordinateSetI, HistoryShadingChange> e in step.entries)
    {
      final HistoryShadingChange? existing = result[e.key];

      if (existing != null)
      {
        if (e.value.after == existing.before)
        {
          // Net-zero change relative to the base snapshot → remove.
          result.remove(e.key);
        }
        else
        {
          result[e.key] = HistoryShadingChange(before: existing.before, after: e.value.after);
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

class HistoryDitherLayer extends HistoryShadingLayer
{
  HistoryDitherLayer.full({
    required super.visibilityState,
    required super.layerIdentity,
    required super.lockState,
    required super.settings,
    required super.fullData,
  }) : super.full();

  HistoryDitherLayer._delta({
    required super.visibilityState,
    required super.layerIdentity,
    required super.lockState,
    required super.settings,
    required super.depth,
    required super.cumulativeDelta,
    required super.parent,
  }) : super._delta();

  factory HistoryDitherLayer.fromDitherLayerState({required final DitherLayerState layerState})
  {
    return HistoryDitherLayer.full(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings),
      fullData:        HistoryShadingLayer._buildFullData(layerState.shadingData),
    );
  }

  factory HistoryDitherLayer.deltaFrom({
    required final DitherLayerState   layerState,
    required final HistoryDitherLayer  previousLayer,
  })
  {
    if (previousLayer._depth >= HistoryShadingLayer._maxDeltaDepth)
    {
      return HistoryDitherLayer.fromDitherLayerState(layerState: layerState);
    }

    final HashMap<CoordinateSetI, HistoryShadingChange> stepDelta =
    HistoryShadingLayer._computeStepDelta(
      newData:       layerState.shadingData,
      previousLayer: previousLayer,
    );

    if (stepDelta.isEmpty) return previousLayer;

    final HistoryShadingLayer parent =
    previousLayer.isFullSnapshot ? previousLayer : previousLayer._parent!;

    final HashMap<CoordinateSetI, HistoryShadingChange> newCumulative =
    previousLayer.isFullSnapshot
        ? stepDelta
        : HistoryShadingLayer._mergeCumulative(
      previous: previousLayer._cumulativeDelta!,
      step:     stepDelta,
    );

    return HistoryDitherLayer._delta(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings),
      depth:           previousLayer._depth + 1,
      cumulativeDelta: newCumulative,
      parent:          parent,
    );
  }
}
