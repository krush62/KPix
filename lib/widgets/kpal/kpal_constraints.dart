/*
 *
 *  * KPix
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

class KPalSliderConstraints
{
  final int minHue;
  final int minSat;
  final int minVal;

  final int maxHue;
  final int maxSat;
  final int maxVal;

  final int defaultHue;
  final int defaultSat;
  final int defaultVal;

  KPalSliderConstraints({
    required this.minHue,
    required this.minSat,
    required this.minVal,
    required this.maxHue,
    required this.maxSat,
    required this.maxVal,
    required this.defaultHue,
    required this.defaultSat,
    required this.defaultVal,
  });
}
