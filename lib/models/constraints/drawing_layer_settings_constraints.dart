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

/// Limits and defaults for the drawing-layer effects (strokes, glow, bevel, drop shadow).
///
/// A plain value object: the preferences build one and the layer reads it, so
/// it belongs to neither of them.
class DrawingLayerSettingsConstraints
{
  final int darkenBrightenMin;
  final int darkenBrightenDefault;
  final int darkenBrightenMax;
  final int glowDepthMin;
  final int glowDepthDefault;
  final int glowDepthMax;
  final bool glowRecursiveDefault;
  final int bevelDistanceMin;
  final int bevelDistanceDefault;
  final int bevelDistanceMax;
  final int bevelStrengthMin;
  final int bevelStrengthDefault;
  final int bevelStrengthMax;
  final int dropShadowOffsetMin;
  final int dropShadowOffsetDefault;
  final int dropShadowOffsetMax;

  const DrawingLayerSettingsConstraints({
    required this.darkenBrightenMin,
    required this.darkenBrightenDefault,
    required this.darkenBrightenMax,
    required this.glowDepthMin,
    required this.glowDepthDefault,
    required this.glowDepthMax,
    required this.glowRecursiveDefault,
    required this.bevelDistanceMin,
    required this.bevelDistanceDefault,
    required this.bevelDistanceMax,
    required this.bevelStrengthMin,
    required this.bevelStrengthDefault,
    required this.bevelStrengthMax,
    required this.dropShadowOffsetMin,
    required this.dropShadowOffsetDefault,
    required this.dropShadowOffsetMax,});
}
