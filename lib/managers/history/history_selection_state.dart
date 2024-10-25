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
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class HistorySelectionState
{
  final HashMap<CoordinateSetI, HistoryColorReference?> content;
  final HistoryLayer? currentLayer;

  HistorySelectionState({required this.content, required this.currentLayer});

  factory HistorySelectionState.fromSelectionState({required final SelectionState sState, required final List<HistoryRampData> ramps, required HistoryLayer? historyLayer})
  {
    final CoordinateColorMapNullable otherCnt = sState.selection.selectedPixels;
    HashMap<CoordinateSetI, HistoryColorReference?> cnt = HashMap();
    for (final CoordinateColorNullable entry in otherCnt.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = Helper.getRampIndex(uuid: entry.value!.ramp.uuid, ramps: ramps);
        if (rampIndex != null)
        {
          cnt[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: entry.value!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        cnt[CoordinateSetI.from(other: entry.key)] = null;
      }
    }
    return HistorySelectionState(content: cnt, currentLayer: historyLayer);
  }

}