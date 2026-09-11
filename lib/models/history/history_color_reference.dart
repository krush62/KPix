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
  /// History snapshots hold one of these per pixel, but a palette only has
  /// [KPalConstraints.rampCountMax] ramps of up to [KPalConstraints.colorCountMax]
  /// colors, so pixel data takes them from here instead of allocating an equal
  /// object per pixel. Values outside those limits cannot come from a valid
  /// palette; they still get an instance of their own rather than an error.
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
