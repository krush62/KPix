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

import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

typedef _CopiedColor = ({String rampUuid, int colorIndex});

/// Copied pixels, kept independent of the live palette.
///
/// A [ColorReference] points at one ramp object, but ramps get deleted, change
/// their color count, and are rebuilt as new objects by every full undo/redo.
/// The clipboard is not part of the history, so it cannot follow those changes.
/// Instead it remembers each color by ramp uuid and index, together with the
/// ramp's color count at copy time, and is matched against the palette only
/// when it is pasted.
class ClipboardContent
{
  final HashMap<CoordinateSetI, _CopiedColor?> _pixels;
  final Map<String, int> _colorCounts;

  factory ClipboardContent({required final CoordinateColorMapNullable colors})
  {
    final HashMap<CoordinateSetI, _CopiedColor?> pixels = HashMap<CoordinateSetI, _CopiedColor?>();
    final Map<String, int> colorCounts = <String, int>{};
    for (final CoordinateColorNullable entry in colors.entries)
    {
      final ColorReference? color = entry.value;
      if (color != null)
      {
        pixels[CoordinateSetI.from(other: entry.key)] = (rampUuid: color.ramp.uuid, colorIndex: color.colorIndex);
        colorCounts[color.ramp.uuid] = color.ramp.references.length;
      }
      else
      {
        pixels[CoordinateSetI.from(other: entry.key)] = null;
      }
    }
    return ClipboardContent._(pixels: pixels, colorCounts: colorCounts);
  }

  ClipboardContent._({required final HashMap<CoordinateSetI, _CopiedColor?> pixels, required final Map<String, int> colorCounts}) :
        _pixels = pixels,
        _colorCounts = colorCounts;

  /// The copied pixels as colors of [ramps], or null if none of them is left.
  ///
  /// A pixel whose ramp no longer exists becomes transparent, so the pasted
  /// selection keeps its shape. A ramp whose color count changed since copying
  /// is remapped the same way the layers were remapped.
  CoordinateColorMapNullable? resolve({required final List<KPalRampData> ramps})
  {
    final Map<String, KPalRampData> rampsByUuid = <String, KPalRampData>{for (final KPalRampData ramp in ramps) ramp.uuid: ramp};
    final Map<String, HashMap<int, int>> indexMaps = <String, HashMap<int, int>>{};
    final CoordinateColorMapNullable resolved = HashMap<CoordinateSetI, ColorReference?>();
    bool hasColor = false;
    for (final MapEntry<CoordinateSetI, _CopiedColor?> entry in _pixels.entries)
    {
      final _CopiedColor? copied = entry.value;
      final KPalRampData? ramp = copied != null ? rampsByUuid[copied.rampUuid] : null;
      ColorReference? color;
      if (copied != null && ramp != null)
      {
        final int copiedCount = _colorCounts[copied.rampUuid]!;
        int colorIndex = copied.colorIndex;
        if (copiedCount != ramp.references.length)
        {
          final HashMap<int, int> indexMap = indexMaps.putIfAbsent(copied.rampUuid, () => remapIndices(oldLength: copiedCount, newLength: ramp.references.length));
          colorIndex = indexMap[colorIndex]!;
        }
        color = ramp.references[colorIndex];
        hasColor = true;
      }
      resolved[CoordinateSetI.from(other: entry.key)] = color;
    }
    return hasColor ? resolved : null;
  }

  /// How many copied pixels use [ramp].
  int getPixelCountForRamp({required final KPalRampData ramp})
  {
    int count = 0;
    for (final _CopiedColor? copied in _pixels.values)
    {
      if (copied != null && copied.rampUuid == ramp.uuid)
      {
        count++;
      }
    }
    return count;
  }
}
