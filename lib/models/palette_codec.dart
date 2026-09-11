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
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/util/helpers/color_helper.dart';

/// Translates between palette colors and the 16-bit codes that pixel buffers
/// store.
///
/// A code names a color by position: `rampIndex * colorsPerRamp + colorIndex + 1`,
/// where `rampIndex` is the ramp's place in the palette and [transparent] (0)
/// means no color. That is the same (ramp index, color index) pair the history
/// and the .kpix file store, so converting to and from them needs no lookup.
///
/// Because codes are positional, a codec belongs to one ramp order. Codes stay
/// valid as long as that order does; when ramps are deleted, reordered or
/// replaced, a [remapLut] from the old codec to the new one moves a whole
/// buffer over in one pass. Color counts are always read from the ramps
/// themselves, so a codec does not go stale when a ramp changes its colors. The
/// pixels of a ramp whose color count changed still need moving, through a
/// [remapLut] with that ramp's index map.
class PaletteCodec
{
  /// The code of an empty pixel.
  static const int transparent = 0;

  /// Code slots per ramp. A power of two above [KPalConstraints.colorCountMax],
  /// so that ramp and color index are a shift and a mask apart.
  static const int colorsPerRamp = 16;
  static const int _colorBits = 4;
  static const int _colorMask = colorsPerRamp - 1;

  /// The most ramps whose codes still fit into 16 bits.
  ///
  /// Far above [KPalConstraints.rampCountMax], which only limits adding ramps
  /// by hand; palette and project files can bring up to 255.
  static const int maxRamps = 0xFFFF ~/ colorsPerRamp;

  final List<KPalRampData> _ramps;
  final Map<KPalRampData, int> _rampIndices;

  PaletteCodec({required final List<KPalRampData> ramps}) :
        assert(ramps.length <= maxRamps, "${ramps.length} ramps do not fit into 16-bit color codes"),
        assert(KPalConstraints.colorCountMax < colorsPerRamp, "a ramp's colors have to fit into its code slots"),
        _ramps = List<KPalRampData>.unmodifiable(ramps),
        _rampIndices = HashMap<KPalRampData, int>.identity()
  {
    for (int i = 0; i < _ramps.length; i++)
    {
      _rampIndices[_ramps[i]] = i;
    }
  }

  /// The ramps, in the order the codes refer to.
  List<KPalRampData> get ramps
  {
    return _ramps;
  }

  /// One past the highest code this codec produces, which is also the length of
  /// its lookup tables.
  int get codeCount
  {
    return _ramps.length * colorsPerRamp + 1;
  }

  /// Whether this codec was built for exactly [ramps], in this order.
  bool matches({required final List<KPalRampData> ramps})
  {
    if (ramps.length != _ramps.length)
    {
      return false;
    }
    for (int i = 0; i < ramps.length; i++)
    {
      if (!identical(ramps[i], _ramps[i]))
      {
        return false;
      }
    }
    return true;
  }

  /// The code for the color at [colorIndex] of the ramp at [rampIndex].
  static int codeOf({required final int rampIndex, required final int colorIndex})
  {
    return (rampIndex << _colorBits) + colorIndex + 1;
  }

  /// The ramp index a non-transparent [code] refers to.
  static int rampIndexOf({required final int code})
  {
    return (code - 1) >> _colorBits;
  }

  /// The color index a non-transparent [code] refers to.
  static int colorIndexOf({required final int code})
  {
    return (code - 1) & _colorMask;
  }

  /// The code for [color], or [transparent] for null.
  ///
  /// A color index past the end of its ramp is clamped, which is how such a
  /// color is displayed as well. A ramp that is not part of this palette is a
  /// stale reference; it asserts, and encodes as [transparent] in release builds.
  int encode({required final ColorReference? color})
  {
    if (color == null)
    {
      return transparent;
    }
    final int? rampIndex = _rampIndices[color.ramp];
    if (rampIndex == null)
    {
      assert(false, "Color of ramp ${color.ramp.uuid} is not part of this palette.");
      return transparent;
    }
    return codeOf(rampIndex: rampIndex, colorIndex: color.colorIndex.clamp(0, color.ramp.references.length - 1));
  }

  /// The color [code] stands for, or null for [transparent].
  ///
  /// Hands out the ramp's own reference object. A color index past the end of
  /// the ramp is clamped like in [encode]; a ramp index past the end of the
  /// palette asserts, and decodes as null in release builds.
  ColorReference? decode({required final int code})
  {
    if (code == transparent)
    {
      return null;
    }
    final int rampIndex = rampIndexOf(code: code);
    if (rampIndex >= _ramps.length)
    {
      assert(false, "Color code $code refers to ramp $rampIndex, but the palette has ${_ramps.length}.");
      return null;
    }
    final List<ColorReference> references = _ramps[rampIndex].references;
    return references[colorIndexOf(code: code).clamp(0, references.length - 1)];
  }

  /// The RGBA value of every code, as the ramps look right now.
  ///
  /// Meant to be built once per render, like the RgbaCache it replaces: later
  /// color changes need a new table. [transparent] maps to 0, and slots past a
  /// ramp's color count map to its last color, matching [decode].
  Uint32List rgbaLut()
  {
    final Uint32List lut = Uint32List(codeCount);
    for (int rampIndex = 0; rampIndex < _ramps.length; rampIndex++)
    {
      final List<ColorReference> references = _ramps[rampIndex].references;
      for (int colorIndex = 0; colorIndex < colorsPerRamp; colorIndex++)
      {
        final ColorReference color = references[colorIndex.clamp(0, references.length - 1)];
        lut[codeOf(rampIndex: rampIndex, colorIndex: colorIndex)] = argbToRgba(argb: color.getIdColor().color.toARGB32());
      }
    }
    return lut;
  }

  /// A table from this codec's codes to [target]'s, keeping every color whose
  /// ramp is still part of [target]'s palette.
  ///
  /// This covers deleting, reordering and adding ramps. A color keeps its color
  /// index, and a ramp missing from [target] maps to [transparent].
  /// [colorIndexMaps] moves the colors of ramps whose color count changed (see
  /// `remapIndices`); an index such a map does not cover becomes [transparent].
  Uint16List remapLut({required final PaletteCodec target, final Map<KPalRampData, Map<int, int>> colorIndexMaps = const <KPalRampData, Map<int, int>>{}})
  {
    final Uint16List lut = Uint16List(codeCount);
    for (int rampIndex = 0; rampIndex < _ramps.length; rampIndex++)
    {
      final KPalRampData ramp = _ramps[rampIndex];
      final int? targetRampIndex = target._rampIndices[ramp];
      if (targetRampIndex == null)
      {
        continue;
      }
      final Map<int, int>? indexMap = colorIndexMaps[ramp];
      final int lastColor = ramp.references.length - 1;
      for (int colorIndex = 0; colorIndex < colorsPerRamp; colorIndex++)
      {
        final int? targetColorIndex = indexMap == null ? colorIndex : indexMap[colorIndex];
        if (targetColorIndex != null)
        {
          lut[codeOf(rampIndex: rampIndex, colorIndex: colorIndex)] = codeOf(rampIndex: targetRampIndex, colorIndex: targetColorIndex.clamp(0, lastColor));
        }
      }
    }
    return lut;
  }

  /// A table from this codec's codes to [target]'s through [colorMap], as
  /// replacing the palette does. A color the map does not cover becomes
  /// [transparent].
  Uint16List remapLutByColor({required final PaletteCodec target, required final Map<ColorReference, ColorReference> colorMap})
  {
    final Uint16List lut = Uint16List(codeCount);
    for (int rampIndex = 0; rampIndex < _ramps.length; rampIndex++)
    {
      final List<ColorReference> references = _ramps[rampIndex].references;
      for (int colorIndex = 0; colorIndex < colorsPerRamp; colorIndex++)
      {
        final ColorReference source = references[colorIndex.clamp(0, references.length - 1)];
        lut[codeOf(rampIndex: rampIndex, colorIndex: colorIndex)] = target.encode(color: colorMap[source]);
      }
    }
    return lut;
  }
}
