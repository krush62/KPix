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

/// Limits and defaults for animation frame timing.
///
/// A plain value object: the preferences build one and the layer reads it, so
/// it belongs to neither of them.
class FrameConstraints
{
  final int minFps;
  final int maxFps;
  final int defaultFps;
  const FrameConstraints({required this.minFps, required this.maxFps, required this.defaultFps});
}
