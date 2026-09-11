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

import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_shading_layer_settings.dart';
import 'package:kpix/models/history/ramp_resolver.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

class HistoryShadingLayer extends HistoryLayer
{
  final LayerLockState lockState;
  final HistoryShadingLayerSettings settings;

  /// The shading steps as signed pixels (see SignedPixels).
  ///
  /// A snapshot shares its tiles with the layer it was taken from and with
  /// earlier snapshots, so a history step only costs the tiles that changed.
  final PixelGridSnapshot pixels;

  HistoryShadingLayer({
    required super.visibilityState,
    required super.layerIdentity,
    required this.lockState,
    required this.settings,
    required this.pixels,
  });

  factory HistoryShadingLayer.fromShadingLayerState({required final ShadingLayerState layerState})
  {
    return HistoryShadingLayer(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings),
      pixels:          layerState.historySnapshot(),
    );
  }

  /// Rebuilds the live settings object shared by shading and dither layers.
  ShadingLayerSettings _toShadingSettings()
  {
    return ShadingLayerSettings(
      constraints: settings.constraints,
      shadingLow: settings.shadingLow,
      shadingHigh: settings.shadingHigh,
    );
  }

  /// A grid of the shading steps for a layer on a canvas of [canvasSize].
  PixelGrid _values({required final CoordinateSetI canvasSize})
  {
    final PixelGrid values = PixelGrid.fromSnapshot(snapshot: pixels);
    if (values.width == canvasSize.x && values.height == canvasSize.y)
    {
      return values;
    }
    return values.resized(newWidth: canvasSize.x, newHeight: canvasSize.y, offsetX: 0, offsetY: 0);
  }

  @override
  Future<ShadingLayerState> toLayerState({
    required final CoordinateSetI canvasSize,
    required final RampResolver ramps,
  }) async
  {
    return ShadingLayerState.withData(
      data: _values(canvasSize: canvasSize),
      lState: lockState,
      newSettings: _toShadingSettings(),
    );
  }
}

class HistoryDitherLayer extends HistoryShadingLayer
{
  HistoryDitherLayer({
    required super.visibilityState,
    required super.layerIdentity,
    required super.lockState,
    required super.settings,
    required super.pixels,
  });

  factory HistoryDitherLayer.fromDitherLayerState({required final DitherLayerState layerState})
  {
    return HistoryDitherLayer(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryShadingLayerSettings.fromShadingLayerSettings(settings: layerState.settings),
      pixels:          layerState.historySnapshot(),
    );
  }

  @override
  Future<DitherLayerState> toLayerState({
    required final CoordinateSetI canvasSize,
    required final RampResolver ramps,
  }) async
  {
    return DitherLayerState.withData(
      data: _values(canvasSize: canvasSize),
      lState: lockState,
      newSettings: _toShadingSettings(),
    );
  }
}
