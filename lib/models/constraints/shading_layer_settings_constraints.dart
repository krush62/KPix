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

/// Limits and defaults for the shading and dither layers.
///
/// A plain value object: the preferences build one and the layer reads it, so
/// it belongs to neither of them.
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
