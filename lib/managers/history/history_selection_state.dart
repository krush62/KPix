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

import 'dart:collection';

import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

class HistorySelectionState
{
  final Set<CoordinateSetI> mask;
  final HashMap<CoordinateSetI, HistoryColorReference> colors;
  final int maskRevision;

  HistorySelectionState({required this.mask, required this.colors, this.maskRevision = -1});

  HistorySelectionState.empty()
      : mask = <CoordinateSetI>{},
        colors = HashMap<CoordinateSetI, HistoryColorReference>(),
        maskRevision = -1;

  bool get isEmpty => mask.isEmpty;

  factory HistorySelectionState.fromSelectionState({required final SelectionState sState, required final List<HistoryRampData> ramps, final HistorySelectionState? previous})
  {
    final Map<String, int> rampIndexByUuid = <String, int>{
      for (int r = 0; r < ramps.length; r++) ramps[r].uuid: r,
    };

    final Map<CoordinateSetI, ColorReference?> live = sState.selection.selectedPixels;
    final int maskRevision = sState.selection.maskRevision;

    final Set<CoordinateSetI> mask;
    if (previous != null && previous.maskRevision == maskRevision && previous.mask.length == live.length)
    {
      mask = previous.mask;
    }
    else
    {
      final Set<CoordinateSetI> freshMask = <CoordinateSetI>{};
      for (final CoordinateSetI coord in live.keys)
      {
        freshMask.add(CoordinateSetI.from(other: coord));
      }
      mask = freshMask;
    }

    final HashMap<CoordinateSetI, HistoryColorReference> colors = HashMap<CoordinateSetI, HistoryColorReference>();
    for (final CoordinateColorNullable entry in live.entries)
    {
      final ColorReference? colorRef = entry.value;
      if (colorRef != null)
      {
        final int? rampIndex = rampIndexByUuid[colorRef.ramp.uuid];
        if (rampIndex != null)
        {
          colors[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: colorRef.colorIndex, rampIndex: rampIndex);
        }
      }
    }

    return HistorySelectionState(mask: mask, colors: colors, maskRevision: maskRevision);
  }
}
