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
import 'dart:typed_data';

import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/selection_buffer.dart';

typedef _CopiedRamp = ({String uuid, int colorCount});

/// Copied pixels matched against the live palette, ready to be pasted.
typedef ResolvedClipboard = ({SelectionBufferSnapshot pixels, PaletteCodec codec});

/// Copied pixels, kept independent of the live palette.
///
/// A code names a color by the position of its ramp, but ramps get deleted,
/// change their color count, and are rebuilt as new objects by every full
/// undo/redo. The clipboard is not part of the history, so it cannot follow
/// those changes. Instead it remembers the ramp behind each code by uuid,
/// together with its color count at copy time, and is matched against the
/// palette only when it is pasted.
class ClipboardContent
{
  final SelectionBufferSnapshot _pixels;
  //the ramps the codes in _pixels refer to, by their position
  final List<_CopiedRamp> _ramps;

  /// Copies [pixels], whose codes belong to [codec]. The pixels share their
  /// tiles with wherever they were copied from.
  factory ClipboardContent({required final SelectionBufferSnapshot pixels, required final PaletteCodec codec})
  {
    return ClipboardContent._(
      pixels: pixels,
      ramps: <_CopiedRamp>[for (final KPalRampData ramp in codec.ramps) (uuid: ramp.uuid, colorCount: ramp.references.length)],
    );
  }

  ClipboardContent._({required final SelectionBufferSnapshot pixels, required final List<_CopiedRamp> ramps}) :
        _pixels = pixels,
        _ramps = ramps;

  /// The copied pixels as codes for [ramps], or null if none of the copied
  /// colors is left.
  ///
  /// A pixel whose ramp no longer exists becomes transparent, so the pasted
  /// selection keeps its shape. A ramp whose color count changed since copying
  /// is remapped the same way the layers were remapped.
  ResolvedClipboard? resolve({required final List<KPalRampData> ramps})
  {
    final Map<String, int> positions = <String, int>{for (int i = 0; i < ramps.length; i++) ramps[i].uuid: i};
    final Uint16List lut = Uint16List(_ramps.length * PaletteCodec.colorsPerRamp + 1);
    for (int rampIndex = 0; rampIndex < _ramps.length; rampIndex++)
    {
      final _CopiedRamp copied = _ramps[rampIndex];
      final int? position = positions[copied.uuid];
      if (position == null)
      {
        continue;
      }
      final int liveCount = ramps[position].references.length;
      final HashMap<int, int>? indexMap = copied.colorCount != liveCount ? remapIndices(oldLength: copied.colorCount, newLength: liveCount) : null;
      for (int colorIndex = 0; colorIndex < PaletteCodec.colorsPerRamp; colorIndex++)
      {
        //a code past the ramp's colors stands for its last one, as decoding does
        final int copiedIndex = colorIndex.clamp(0, copied.colorCount - 1);
        lut[PaletteCodec.codeOf(rampIndex: rampIndex, colorIndex: colorIndex)] = PaletteCodec.codeOf(rampIndex: position, colorIndex: indexMap == null ? copiedIndex : indexMap[copiedIndex]!);
      }
    }

    final SelectionBuffer resolved = SelectionBuffer.fromSnapshot(snapshot: _pixels);
    resolved.remap(lut: lut);
    bool hasColor = false;
    resolved.forEach(action: (final int x, final int y, final int code)
    {
      hasColor = hasColor || code != PaletteCodec.transparent;
    },);
    return hasColor ? (pixels: resolved.snapshot()!, codec: PaletteCodec(ramps: ramps)) : null;
  }

  /// How many copied pixels use [ramp].
  int getPixelCountForRamp({required final KPalRampData ramp})
  {
    final int rampIndex = _ramps.indexWhere((final _CopiedRamp copied) => copied.uuid == ramp.uuid);
    if (rampIndex < 0)
    {
      return 0;
    }
    int count = 0;
    _pixels.forEach(action: (final int x, final int y, final int code)
    {
      if (code != PaletteCodec.transparent && PaletteCodec.rampIndexOf(code: code) == rampIndex)
      {
        count++;
      }
    },);
    return count;
  }
}
