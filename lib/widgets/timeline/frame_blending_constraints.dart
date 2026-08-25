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

abstract final class FrameBlendingConstraints
{
  static const bool enabledDefault = false;
  static const bool wrapBeforeDefault = true;
  static const bool wrapAfterDefault = true;
  static const bool gradualOpacityDefault = true;
  static const bool tintingDefault = false;
  static const bool activeLayerOnlyDefault = false;

  static const int framesBeforeDefault = 1;
  static const int framesAfterDefault = 1;
  static const int frameOffsetMax = 4;
  static const int frameOffsetMin = 1;

  static const double opacityMin = 0.1;
  static const double opacityDefault = 0.4;
  static const double opacityMax = 0.9;
  static const double opacityStep = 0.1;
}
