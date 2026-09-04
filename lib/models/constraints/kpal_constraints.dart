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

enum SatCurve
{
  noFlat(0),
  darkFlat(1),
  brightFlat(2),
  linear(3);

  const SatCurve(this.id);

  final int id;

  static SatCurve fromId(final int id) {
    return SatCurve.values.firstWhere((final SatCurve curve) => curve.id == id);
  }
}

abstract final class KPalConstraints
{
  static const int colorCountMin = 3;
  static const int colorCountDefault = 7;
  static const int colorCountMax = 15;

  static const int baseHueMin = 0;
  static const int baseHueDefault = 180;
  static const int baseHueMax = 360;

  static const int baseSatMin = 0;
  static const int baseSatDefault = 60;
  static const int baseSatMax = 100;

  static const int hueShiftMin = -90;
  static const int hueShiftDefault = -10;
  static const int hueShiftMax = 90;

  static const double hueShiftExpMin = 0.5;
  static const double hueShiftExpDefault = 1.0;
  static const double hueShiftExpMax = 2.0;

  static const int satShiftMin = -25;
  static const int satShiftDefault = -10;
  static const int satShiftMax = 25;

  static const double satShiftExpMin = 0.5;
  static const double satShiftExpDefault = 1.0;
  static const double satShiftExpMax = 2.0;

  static const int valueRangeMin = 0;
  static const int valueRangeMinDefault = 15;
  static const int valueRangeMaxDefault = 95;
  static const int valueRangeMax = 100;

  static const SatCurve satCurveDefault = SatCurve.noFlat;

  static const int rampCountMin = 1;
  static const int rampCountDefault = 8;
  static const int rampCountMax = 64;

  static const int maxClusters = 16;
}

abstract final class KPalSliderConstraints
{
  static const int minHue = -50;
  static const int defaultHue = 0;
  static const int maxHue = 50;

  static const int minSat = -25;
  static const int defaultSat = 0;
  static const int maxSat = 25;

  static const int minVal = -25;
  static const int defaultVal = 0;
  static const int maxVal = 25;
}
