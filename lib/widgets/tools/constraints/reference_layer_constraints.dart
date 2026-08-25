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

abstract final class ReferenceLayerConstraints
{
  static const int opacityDefault = 100;
  static const int opacityMin = 0;
  static const int opacityMax = 100;
  static const double aspectRatioDefault = 0.0;
  static const double aspectRatioMin = -5.0;
  static const double aspectRatioMax = 5.0;
  static const int zoomDefault = 1000;
  static const int zoomMin = 1;
  static const int zoomMax = 2000;
  static const double zoomCurveExponent = 2.0;
  static const double brightnessDefault = 0.0;
  static const double brightnessMin = -1.0;
  static const double brightnessMax = 1.0;
  static const double saturationDefault = 1.0;
  static const double saturationMin = 0.0;
  static const double saturationMax = 2.0;
  static const double contrastDefault = 1.0;
  static const double contrastMin = 0.0;
  static const double contrastMax = 2.0;
  static const double warmthDefault = 0.0;
  static const double warmthMin = -1.0;
  static const double warmthMax = 1.0;

}
