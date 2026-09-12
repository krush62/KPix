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

import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/selection_buffer.dart';

class HistorySelectionState
{
  /// The selected pixels, as codes whose ramp index is the ramp's place in the
  /// state's ramp list (see PaletteCodec), or null without a selection.
  ///
  /// A snapshot shares its tiles with the live selection and with earlier
  /// snapshots, so a history step only costs the tiles that changed.
  final SelectionBufferSnapshot? pixels;

  HistorySelectionState({required this.pixels});

  HistorySelectionState.empty() : pixels = null;

  bool get isEmpty => pixels == null;

  factory HistorySelectionState.fromSelectionState({required final SelectionState sState, required final List<HistoryRampData> ramps})
  {
    return HistorySelectionState(pixels: sState.selection.historySnapshot(ramps: ramps));
  }
}
