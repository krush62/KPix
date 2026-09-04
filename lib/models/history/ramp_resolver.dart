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

import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/util/helpers/color_helper.dart';

class RampResolver
{
  RampResolver({
    required final List<KPalRampData> liveRamps,
    required final List<HistoryRampData> historyRamps,
  }) : _live = liveRamps,
        _historyRamps = historyRamps,
        _byUuid = <String, KPalRampData>{ for (final KPalRampData r in liveRamps) r.uuid: r };

  final List<KPalRampData> _live;
  final List<HistoryRampData> _historyRamps;
  final Map<String, KPalRampData> _byUuid;

  /// Pixel data: match the ramp by uuid, skip the pixel if it's gone.
  ColorReference? byUuid({required final HistoryColorReference ref})
  {
    final KPalRampData? ramp = _byUuid[_historyRamps[ref.rampIndex].uuid];
    return ramp == null
        ? null
        : ColorReference(colorIndex: ref.colorIndex, ramp: ramp);
  }

  /// The live ramp list this resolver was built from.
  List<KPalRampData> get liveRamps
  {
    return _live;
  }

  /// Settings colours: positional lookup into the live ramp list.
  ColorReference byIndex({required final HistoryColorReference ref}) =>
      _live[ref.rampIndex].references[ref.colorIndex];
}
