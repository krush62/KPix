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

import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/managers/history/history_layer.dart';

class HistoryReferenceLayer extends HistoryLayer
{
  final String path;
  final int opacity;
  final double offsetX;
  final double offsetY;
  final int zoom;
  final double aspectRatio;
  HistoryReferenceLayer({required super.visibilityState, required super.layerIdentity, required this.opacity, required this.offsetX, required this.offsetY, required this.path, required this.zoom, required this.aspectRatio});
  factory HistoryReferenceLayer.fromReferenceLayer({required final ReferenceLayerState referenceState})
  {
    return HistoryReferenceLayer(visibilityState: referenceState.visibilityState.value, layerIdentity: identityHashCode(referenceState), path: referenceState.imageNotifier.value == null ? "" : referenceState.imageNotifier.value!.path, offsetX: referenceState.offsetXNotifier.value, offsetY: referenceState.offsetYNotifier.value, opacity: referenceState.opacityNotifier.value, zoom: referenceState.zoomNotifier.value, aspectRatio: referenceState.aspectRatioNotifier.value);
  }
}
