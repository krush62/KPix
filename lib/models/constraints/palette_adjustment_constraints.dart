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

abstract final class PaletteAdjustmentConstraints
{
  static const double brightnessMin = -100.0;
  static const double brightnessDefault = 0.0;
  static const double brightnessMax = 100.0;

  static const double contrastMin = -100.0;
  static const double contrastDefault = 0.0;
  static const double contrastMax = 100.0;

  static const double saturationMin = -100.0;
  static const double saturationDefault = 0.0;
  static const double saturationMax = 100.0;

  static const double whiteBalanceMin = -100.0;
  static const double whiteBalanceDefault = 0.0;
  static const double whiteBalanceMax = 100.0;

  static const double tintMin = -100.0;
  static const double tintDefault = 0.0;
  static const double tintMax = 100.0;

  static const double hueShiftMin = -180.0;
  static const double hueShiftDefault = 0.0;
  static const double hueShiftMax = 180.0;

  static const double hueSpreadMin = -100.0;
  static const double hueSpreadDefault = 0.0;
  static const double hueSpreadMax = 100.0;

  /// How far a full white balance or tint drives the rgb channel gains.
  static const double channelGainStrength = 0.5;
}
