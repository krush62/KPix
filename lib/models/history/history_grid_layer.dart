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

import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/ramp_resolver.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

class HistoryGridLayer extends HistoryLayer
{
  final int opacity;
  final GridType gridType;
  final int brightness;
  final int intervalX;
  final int intervalY;
  final double horizonPosition;
  final double vanishingPoint1;
  final double vanishingPoint2;
  final double vanishingPoint3;
  HistoryGridLayer({required super.visibilityState, required super.layerIdentity, required this.opacity, required this.gridType, required this.intervalX, required this.intervalY, required this.brightness, required this.vanishingPoint1, required this.vanishingPoint2, required this.vanishingPoint3, required this.horizonPosition});
  factory HistoryGridLayer.fromGridLayer({required final GridLayerState gridState})
  {
    return HistoryGridLayer(opacity: gridState.opacity, brightness: gridState.brightness, gridType: gridState.gridType, visibilityState: gridState.visibilityState.value, layerIdentity: identityHashCode(gridState), intervalX: gridState.intervalX, intervalY: gridState.intervalY, horizonPosition: gridState.horizonPosition, vanishingPoint1: gridState.vanishingPoint1, vanishingPoint2: gridState.vanishingPoint2, vanishingPoint3: gridState.vanishingPoint3);
  }
  @override
  Future<GridLayerState> toLayerState({
    required final CoordinateSetI canvasSize,
    required final RampResolver ramps,
  }) async
  {
    return GridLayerState(
      opacity: opacity,
      brightness: brightness,
      gridType: gridType,
      intervalX: intervalX,
      intervalY: intervalY,
      horizonPosition: horizonPosition,
      vanishingPoint1: vanishingPoint1,
      vanishingPoint2: vanishingPoint2,
      vanishingPoint3: vanishingPoint3,
    );
  }
}
