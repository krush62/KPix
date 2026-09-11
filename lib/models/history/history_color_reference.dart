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

import 'package:kpix/models/constraints/kpal_constraints.dart';

class HistoryColorReference
{
  final int colorIndex;
  final int rampIndex;

  const HistoryColorReference({required this.colorIndex, required this.rampIndex});

  /// The shared instance for [colorIndex] of the ramp at [rampIndex].
  ///
  /// History snapshots hold one of these per pixel, but the values repeat: ramps
  /// added by hand stop at [KPalConstraints.rampCountMax], with up to
  /// [KPalConstraints.colorCountMax] colors each. Pixel data takes them from here
  /// instead of allocating an equal object per pixel. Palettes loaded from files
  /// can hold more ramps; colors beyond that limit get an instance of their own.
  factory HistoryColorReference.of({required final int colorIndex, required final int rampIndex})
  {
    if (rampIndex < 0 || rampIndex >= KPalConstraints.rampCountMax || colorIndex < 0 || colorIndex >= KPalConstraints.colorCountMax)
    {
      return HistoryColorReference(colorIndex: colorIndex, rampIndex: rampIndex);
    }
    return _shared[rampIndex * KPalConstraints.colorCountMax + colorIndex] ??= HistoryColorReference(colorIndex: colorIndex, rampIndex: rampIndex);
  }

  static final List<HistoryColorReference?> _shared = List<HistoryColorReference?>.filled(KPalConstraints.rampCountMax * KPalConstraints.colorCountMax, null);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
          other is HistoryColorReference &&
              rampIndex  == other.rampIndex &&
              colorIndex == other.colorIndex;

  @override
  int get hashCode => Object.hash(rampIndex, colorIndex);
}
