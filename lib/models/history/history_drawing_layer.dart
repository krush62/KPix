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

import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/history/history_drawing_layer_settings.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/ramp_resolver.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

class HistoryDrawingLayer extends HistoryLayer
{
  final LayerLockState lockState;
  final HistoryDrawingLayerSettings settings;

  /// The pixels as color codes (see PaletteCodec) whose ramp indices refer to
  /// the ramp list of the history state this layer belongs to.
  ///
  /// A snapshot shares its tiles with the layer it was taken from and with
  /// earlier snapshots, so a history step only costs the tiles that changed.
  final PixelGridSnapshot pixels;

  HistoryDrawingLayer({
    required super.visibilityState,
    required super.layerIdentity,
    required this.lockState,
    required this.settings,
    required this.pixels,
  });

  factory HistoryDrawingLayer.fromDrawingLayerState({
    required final DrawingLayerState layerState,
    required final List<HistoryRampData> ramps,
  })
  {
    return HistoryDrawingLayer(
      visibilityState: layerState.visibilityState.value,
      layerIdentity:   identityHashCode(layerState),
      lockState:       layerState.lockState.value,
      settings:        HistoryDrawingLayerSettings.fromDrawingLayerSettings(settings: layerState.settings),
      pixels:          layerState.historySnapshot(ramps: ramps),
    );
  }

  @override
  Future<DrawingLayerState> toLayerState({
    required final CoordinateSetI canvasSize,
    required final RampResolver ramps,
  }) async
  {
    PixelGrid content = PixelGrid.fromSnapshot(snapshot: pixels);
    if (!ramps.pixelsLineUp)
    {
      content.remap(lut: ramps.pixelLut());
    }
    if (content.width != canvasSize.x || content.height != canvasSize.y)
    {
      content = content.resized(newWidth: canvasSize.x, newHeight: canvasSize.y, offsetX: 0, offsetY: 0);
    }

    final DrawingLayerSettings drawingLayerSettings = DrawingLayerSettings(
      constraints: settings.constraints,
      outerStrokeStyle: settings.outerStrokeStyle,
      outerSelectionMap: settings.outerSelectionMap,
      outerColorReference: ramps.byIndex(ref: settings.outerColorReference),
      outerDarkenBrighten: settings.outerDarkenBrighten,
      outerGlowDepth: settings.outerGlowDepth,
      outerGlowRecursive: settings.outerGlowRecursive,
      innerStrokeStyle: settings.innerStrokeStyle,
      innerSelectionMap: settings.innerSelectionMap,
      innerColorReference: ramps.byIndex(ref: settings.innerColorReference),
      innerDarkenBrighten: settings.innerDarkenBrighten,
      innerGlowDepth: settings.innerGlowDepth,
      innerGlowRecursive: settings.innerGlowRecursive,
      bevelDistance: settings.bevelDistance,
      bevelStrength: settings.bevelStrength,
      dropShadowStyle: settings.dropShadowStyle,
      dropShadowColorReference: ramps.byIndex(ref: settings.dropShadowColorReference),
      dropShadowOffset: settings.dropShadowOffset,
      dropShadowDarkenBrighten: settings.dropShadowDarkenBrighten,
    );

    final DrawingLayerState drawingLayer = DrawingLayerState.fromPixels(
      pixels: content,
      codec: ramps.liveCodec,
      drawingLayerSettings: drawingLayerSettings,
    );
    drawingLayer.lockState.value = lockState;
    return drawingLayer;
  }
}
