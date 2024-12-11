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

import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';

class HistoryGridLayer extends HistoryLayer
{
  final int opacity;
  final GridType gridType;
  final int brightness;
  final int intervalX;
  final int intervalY;
  HistoryGridLayer({required super.visibilityState, required this.opacity, required this.gridType, required this.intervalX, required this.intervalY, required this.brightness});
  factory HistoryGridLayer.fromGridLayer({required final GridLayerState gridState})
  {
    return HistoryGridLayer(opacity: gridState.opacity, brightness: gridState.brightness, gridType: gridState.gridType, visibilityState: gridState.visibilityState.value, intervalX: gridState.intervalX, intervalY: gridState.intervalY);
  }
}
