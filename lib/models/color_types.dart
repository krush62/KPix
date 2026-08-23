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

import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';

class IdColor
{
  final KHSV hsv;
  final Color color;
  final String uuid;
  IdColor({required this.hsv, required this.uuid}) : color = hsv.toColor();
  String getTooltipText()
  {
    final String name = GetIt.I.get<PreferenceManager>().colorNames.getColorName(r: color.r, g: color.g, b: color.b);
    final String hsv = "${this.hsv.h.round()}° ${(this.hsv.s * 100).round()}% ${(this.hsv.v * 100).round()}%";
    final String rgb = colorToRGBString(color: color);
    final String hex = colorToHexString(color: color);
    return "$name\n$hsv\n$rgb\n$hex";
  }
}

enum SatCurve
{
  noFlat,
  darkFlat,
  brightFlat,
  linear,
}

const Map<int, SatCurve> satCurveMap =
<int, SatCurve>{
  0:SatCurve.noFlat,
  1:SatCurve.darkFlat,
  2:SatCurve.brightFlat,
  3:SatCurve.linear,
};

class KPalRampSettings
{
  final KPalConstraints constraints;
  late int colorCount;
  late int baseHue;
  late int hueShift;
  late double hueShiftExp;
  late int baseSat;
  late int satShift;
  late double satShiftExp;
  late int valueRangeMin;
  late int valueRangeMax;
  late SatCurve satCurve;

  KPalRampSettings({required this.constraints})
  {
    colorCount = constraints.colorCountDefault;
    baseHue = constraints.baseHueDefault;
    baseSat = constraints.baseSatDefault;
    hueShift = constraints.hueShiftDefault;
    hueShiftExp = constraints.hueShiftExpDefault;
    satShift = constraints.satShiftDefault;
    satShiftExp = constraints.satShiftExpDefault;
    valueRangeMin = constraints.valueRangeMinDefault;
    valueRangeMax = constraints.valueRangeMaxDefault;
    satCurve = satCurveMap[constraints.satCurveDefault] ?? SatCurve.noFlat;
  }

  KPalRampSettings.fromValues({
    required this.constraints,
    required this.colorCount,
    required this.baseHue,
    required this.hueShift,
    required this.hueShiftExp,
    required this.baseSat,
    required this.satShift,
    required this.satShiftExp,
    required this.valueRangeMin,
    required this.valueRangeMax,
    required this.satCurve,
  });

  factory KPalRampSettings.from({required final KPalRampSettings other})
  {
    final KPalRampSettings newSettings = KPalRampSettings(constraints: other.constraints);
    newSettings.colorCount = other.colorCount;
    newSettings.baseHue = other.baseHue;
    newSettings.baseSat = other.baseSat;
    newSettings.hueShift = other.hueShift;
    newSettings.hueShiftExp = other.hueShiftExp;
    newSettings.satShift = other.satShift;
    newSettings.satShiftExp = other.satShiftExp;
    newSettings.valueRangeMin = other.valueRangeMin;
    newSettings.valueRangeMax = other.valueRangeMax;
    newSettings.satCurve = other.satCurve;
    return newSettings;
  }
}

class KPalConstraints
{
  final int colorCountMin;
  final int colorCountMax;
  final int colorCountDefault;
  final int baseHueMin;
  final int baseHueMax;
  final int baseHueDefault;
  final int baseSatMin;
  final int baseSatMax;
  final int baseSatDefault;
  final int hueShiftMin;
  final int hueShiftMax;
  final int hueShiftDefault;
  final double hueShiftExpMin;
  final double hueShiftExpMax;
  final double hueShiftExpDefault;
  final int satShiftMin;
  final int satShiftMax;
  final int satShiftDefault;
  final double satShiftExpMin;
  final double satShiftExpMax;
  final double satShiftExpDefault;
  final int valueRangeMin;
  final int valueRangeMinDefault;
  final int valueRangeMax;
  final int valueRangeMaxDefault;
  final int satCurveDefault;
  final int rampCountMin;
  final int rampCountMax;
  final int rampCountDefault;
  final int maxClusters;

  KPalConstraints({
    required this.colorCountMin,
    required this.colorCountMax,
    required this.colorCountDefault,
    required this.baseHueMin,
    required this.baseHueMax,
    required this.baseHueDefault,
    required this.baseSatMin,
    required this.baseSatMax,
    required this.baseSatDefault,
    required this.hueShiftMin,
    required this.hueShiftMax,
    required this.hueShiftDefault,
    required this.hueShiftExpMin,
    required this.hueShiftExpMax,
    required this.hueShiftExpDefault,
    required this.satShiftMin,
    required this.satShiftMax,
    required this.satShiftDefault,
    required this.satShiftExpMin,
    required this.satShiftExpMax,
    required this.satShiftExpDefault,
    required this.valueRangeMin,
    required this.valueRangeMinDefault,
    required this.valueRangeMax,
    required this.valueRangeMaxDefault,
    required this.satCurveDefault,
    required this.rampCountMin,
    required this.rampCountMax,
    required this.rampCountDefault,
    required this.maxClusters,
  });
}
