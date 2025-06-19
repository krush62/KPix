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

import 'package:flutter/material.dart';
import 'package:kpix/layer_states/layer_settings.dart';

class ShadingLayerSettingsConstraints
{
  final int shadingStepsMin;
  final int shadingStepsDefaultBrighten;
  final int shadingStepsDefaultDarken;
  final int shadingStepsMax;
  final int ditherStepsMax;

  const ShadingLayerSettingsConstraints({
    required this.shadingStepsMin,
    required this.shadingStepsDefaultBrighten,
    required this.shadingStepsDefaultDarken,
    required this.shadingStepsMax,
    required this.ditherStepsMax,
  });
}

class ShadingLayerSettings extends LayerSettings
{
  final ShadingLayerSettingsConstraints constraints;
  final ValueNotifier<int> shadingStepsMinus;
  final ValueNotifier<int> shadingStepsPlus;

  ShadingLayerSettings({required this.constraints, required final int shadingLow, required final int shadingHigh}) :
        shadingStepsMinus = ValueNotifier<int>(shadingLow),
        shadingStepsPlus = ValueNotifier<int>(shadingHigh)
  {
    _setupListeners();
  }

  ShadingLayerSettings.defaultValue({
    required this.constraints,
  }) :
        shadingStepsMinus = ValueNotifier<int>(constraints.shadingStepsDefaultDarken),
        shadingStepsPlus = ValueNotifier<int>(constraints.shadingStepsDefaultBrighten)
  {
    _setupListeners();
  }

  ShadingLayerSettings.from({required final ShadingLayerSettings other}) :
        constraints = other.constraints,
        shadingStepsMinus = ValueNotifier<int>(other.shadingStepsMinus.value),
        shadingStepsPlus = ValueNotifier<int>(other.shadingStepsPlus.value)
  {
    _setupListeners();
  }

  void _setupListeners()
  {
    shadingStepsMinus.addListener(valueChanged);
    shadingStepsPlus.addListener(valueChanged);
  }

  @override
  bool hasActiveSettings() {
    return shadingStepsMinus.value != constraints.shadingStepsDefaultDarken ||
        shadingStepsPlus.value != constraints.shadingStepsDefaultBrighten;
  }

}
