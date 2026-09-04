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


import 'package:flutter/foundation.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/util/file_handler.dart';

/// Loads the stamps from disk and remembers which one is selected.
class StampManager
{
  final ValueNotifier<StampMap> stampMap = ValueNotifier<StampMap>(<String, List<StampManagerEntryData>>{});
  final ValueNotifier<StampManagerEntryData?> selectedStamp = ValueNotifier<StampManagerEntryData?>(null);
  final ValueNotifier<String?> selectedFolder = ValueNotifier<String?>(null);

  Future<void> loadAllStamps() async
  {
    stampMap.value = await loadStamps(loadUserStamps: !kIsWeb);
    for (final MapEntry<String, List<StampManagerEntryData>> stampList in stampMap.value.entries)
    {
      if (stampList.value.isNotEmpty)
      {
        selectedFolder.value = stampList.key;
        selectedStamp.value = stampList.value.first;
      }
    }
  }


}
