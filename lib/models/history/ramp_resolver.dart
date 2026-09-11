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

import 'dart:typed_data';

import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';

class RampResolver
{
  RampResolver({
    required final List<KPalRampData> liveRamps,
    required final List<HistoryRampData> historyRamps,
  }) : _live = liveRamps,
        _historyRamps = historyRamps,
        _byUuid = <String, int>{ for (int i = 0; i < liveRamps.length; i++) liveRamps[i].uuid: i };

  final List<KPalRampData> _live;
  final List<HistoryRampData> _historyRamps;
  final Map<String, int> _byUuid;
  PaletteCodec? _liveCodec;

  /// The live ramp list this resolver was built from.
  List<KPalRampData> get liveRamps
  {
    return _live;
  }

  /// A codec for [liveRamps], shared by every layer restored through this
  /// resolver.
  PaletteCodec get liveCodec
  {
    return _liveCodec ??= PaletteCodec(ramps: _live);
  }

  /// Whether pixel codes stored against the history's ramps are valid for
  /// [liveCodec] as they are: both lists hold the same ramps, by uuid, in the
  /// same order. That is the case for every restore short of a damaged state;
  /// otherwise [pixelLut] translates them.
  bool get pixelsLineUp
  {
    if (_historyRamps.length != _live.length)
    {
      return false;
    }
    for (int i = 0; i < _live.length; i++)
    {
      if (_historyRamps[i].uuid != _live[i].uuid)
      {
        return false;
      }
    }
    return true;
  }

  /// A table from pixel codes stored against the history's ramps to codes of
  /// [liveCodec] (see PaletteCodec).
  ///
  /// Ramps are matched by uuid. The pixels of a ramp that is gone become
  /// transparent, and a color index past the end of the live ramp is clamped,
  /// which is also how such a pixel is displayed.
  Uint16List pixelLut()
  {
    final Uint16List lut = Uint16List(_historyRamps.length * PaletteCodec.colorsPerRamp + 1);
    for (int historyIndex = 0; historyIndex < _historyRamps.length; historyIndex++)
    {
      final int? liveIndex = _byUuid[_historyRamps[historyIndex].uuid];
      if (liveIndex == null)
      {
        continue;
      }
      final int lastColor = _live[liveIndex].references.length - 1;
      for (int colorIndex = 0; colorIndex < PaletteCodec.colorsPerRamp; colorIndex++)
      {
        lut[PaletteCodec.codeOf(rampIndex: historyIndex, colorIndex: colorIndex)] = PaletteCodec.codeOf(rampIndex: liveIndex, colorIndex: colorIndex.clamp(0, lastColor));
      }
    }
    return lut;
  }

  /// Settings colours: positional lookup into the live ramp list.
  ColorReference byIndex({required final HistoryColorReference ref}) =>
      _live[ref.rampIndex].references[ref.colorIndex];
}
