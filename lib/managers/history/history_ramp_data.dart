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

import 'package:kpix/managers/history/history_shift_set.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class HistoryRampData
{
  final String uuid;
  final KPalRampSettings settings;
  final List<HistoryShiftSet> shiftSets = [];
  HistoryRampData({required KPalRampSettings otherSettings, required List<ShiftSet> notifierShifts, required this.uuid}) : settings = KPalRampSettings.from(other: otherSettings)
  {
    for (int i = 0; i < settings.colorCount; i++)
    {
      final ShiftSet notifierShiftSet = notifierShifts[i];
      shiftSets.add(HistoryShiftSet(hueShift: notifierShiftSet.hueShiftNotifier.value, satShift: notifierShiftSet.satShiftNotifier.value, valShift: notifierShiftSet.valShiftNotifier.value));
    }
  }
}