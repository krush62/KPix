/*
 *
 *  * KPix
 *  * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *  *
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:kpix/models/constraints/value_limits.dart';

export 'package:kpix/models/constraints/value_limits.dart';

enum SatCurve
{
  noFlat(0, 1),
  darkFlat(1, 0),
  brightFlat(2, 3),
  linear(3, 2);

  const SatCurve(this.id, this.kPalId);

  final int id;

  /// The id in a kpal file, which the original KPal numbers differently.
  final int kPalId;

  static SatCurve? fromId(final int id) {
    return SatCurve.values.where((final SatCurve curve) => curve.id == id).firstOrNull;
  }

  static SatCurve? fromKPalId(final int id) {
    return SatCurve.values.where((final SatCurve curve) => curve.kPalId == id).firstOrNull;
  }
}

abstract final class KPalConstraints
{
  static const ValueLimits<int> colorCountLimits = ValueLimits<int>(min: 3, defaultValue: 7, max: 15);
  static const ValueLimits<int> baseHueLimits = ValueLimits<int>(min: 0, defaultValue: 180, max: 360);
  static const ValueLimits<int> baseSatLimits = ValueLimits<int>(min: 0, defaultValue: 60, max: 100);
  static const ValueLimits<int> hueShiftLimits = ValueLimits<int>(min: -90, defaultValue: -10, max: 90);
  static const ValueLimits<double> hueShiftExpLimits = ValueLimits<double>(min: 0.5, defaultValue: 1.0, max: 2.0);
  static const ValueLimits<int> satShiftLimits = ValueLimits<int>(min: -25, defaultValue: -10, max: 25);
  static const ValueLimits<double> satShiftExpLimits = ValueLimits<double>(min: 0.5, defaultValue: 1.0, max: 2.0);

  static const int valueRangeMin = 0;
  static const int valueRangeMinDefault = 15;
  static const int valueRangeMaxDefault = 95;
  static const int valueRangeMax = 100;

  static const SatCurve satCurveDefault = SatCurve.noFlat;

  static const ValueLimits<int> rampCountLimits = ValueLimits<int>(min: 1, defaultValue: 8, max: 64);

  static const int maxClusters = 16;
}

abstract final class KPalSliderConstraints
{
  static const ValueLimits<int> hueLimits = ValueLimits<int>(min: -50, defaultValue: 0, max: 50);
  static const ValueLimits<int> satLimits = ValueLimits<int>(min: -25, defaultValue: 0, max: 25);
  static const ValueLimits<int> valLimits = ValueLimits<int>(min: -25, defaultValue: 0, max: 25);
}
