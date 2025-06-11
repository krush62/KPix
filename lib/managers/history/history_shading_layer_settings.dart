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

import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';

class HistoryShadingLayerSettings
{
  final int shadingLow;
  final int shadingHigh;
  final ShadingLayerSettingsConstraints constraints;

  const HistoryShadingLayerSettings({
    required this.constraints,
    required this.shadingLow,
    required this.shadingHigh,
  });

  HistoryShadingLayerSettings.defaultValue({required this.constraints}) :
      shadingLow = constraints.shadingStepsMin,
      shadingHigh = constraints.shadingStepsMax;

  HistoryShadingLayerSettings.fromShadingLayerSettings({required final ShadingLayerSettings settings}) :
      constraints = settings.constraints,
      shadingLow = settings.shadingStepsMinus.value,
      shadingHigh = settings.shadingStepsPlus.value;

}
