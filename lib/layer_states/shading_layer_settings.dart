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

class ShadingLayerSettingsConstraints
{
  final int shadingAmountMin;
  final int shadingAmountDefault;
  final int shadingAmountMax;

  const ShadingLayerSettingsConstraints({
    required this.shadingAmountMin,
    required this.shadingAmountDefault,
    required this.shadingAmountMax,
  });
}

class ShadingLayerSettings with ChangeNotifier
{
  final ShadingLayerSettingsConstraints constraints;
  final ValueNotifier<int> shadingLow;
  final ValueNotifier<int> shadingHigh;

  ShadingLayerSettings({
    required this.constraints,
  }) :
        shadingLow = ValueNotifier<int>(-constraints.shadingAmountDefault),
        shadingHigh = ValueNotifier<int>(constraints.shadingAmountDefault)
  {
    _init();
  }

  ShadingLayerSettings.from({required final ShadingLayerSettings other}) :
        constraints = other.constraints,
        shadingLow = ValueNotifier<int>(other.shadingLow.value),
        shadingHigh = ValueNotifier<int>(other.shadingHigh.value)
  {
    _init();
  }

  void _init()
  {
    shadingLow.addListener(_valueChanged);
    shadingHigh.addListener(_valueChanged);
  }

  void _valueChanged()
  {
    notifyListeners();
  }
}
