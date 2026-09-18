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

import 'package:flutter/material.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// How the image import turned pixels into palette colors before that work
/// moved to a background isolate: every pixel through HSV, then matched against
/// the palette with a fresh Lab conversion for each comparison.
///
/// The rewrite is only meant to be faster, so which palette color a pixel color
/// ends up on has to stay the same, which is what [legacyFindClosestColor] is
/// kept around to check.
///
/// Where a pixel ends up did change: [legacyLayerContent] drops a fully
/// transparent pixel instead of leaving it empty, so everything behind it moves
/// up by one and the image comes out skewed. That was a bug, and it is fixed,
/// so this one only lines up with the import for images without transparency.

const int _fullCircle = 360;
const int _byteLength = 255;

List<KHSV> legacyExtractColorsFromImage({required final ByteData imgBytes, final int alphaThreshold = 0})
{
  final Uint8List u8 = imgBytes.buffer.asUint8List(
    imgBytes.offsetInBytes,
    imgBytes.lengthInBytes,
  );
  final int pixelCount = u8.length ~/ 4;

  final List<KHSV>colors = <KHSV>[];
  for (int i = 0; i < pixelCount; i++)
  {
    final int base = i * 4;
    final int r = u8[base + 0];
    final int g = u8[base + 1];
    final int b = u8[base + 2];
    final int a = u8[base + 3];
    if (a <= alphaThreshold) continue;

    // Inline RGB -> HSV (same math you use elsewhere)
    final double rf = r / _byteLength;
    final double gf = g / _byteLength;
    final double bf = b / _byteLength;
    double maxc = rf;
    double minc = rf;
    if (gf > maxc) maxc = gf; if (bf > maxc) maxc = bf;
    if (gf < minc) minc = gf; if (bf < minc) minc = bf;
    final double delta = maxc - minc;

    double h;
    double s;
    final double v = maxc;
    if (delta == 0.0)
    {
      h = 0.0; s = 0.0;
    }
    else
    {
      s = (maxc == 0.0) ? 0.0 : delta / maxc;
      if (maxc == rf)
      {
        h = 60.0 * (((gf - bf) / delta) % 6.0);
      }
      else if (maxc == gf)
      {
        h = 60.0 * (((bf - rf) / delta) + 2.0);
      }
      else
      {
        h = 60.0 * (((rf - gf) / delta) + 4.0);
      }
      if (h < 0) h += _fullCircle;
      if (h >= _fullCircle) h -= _fullCircle;
    }
    colors.add(KHSV(h: h, s: s, v: v));
  }
  return colors;
}

HashMap<CoordinateSetI, ColorReference?> legacyLayerContent({required final List<KHSV> colorList, required final int width, required final List<KPalRampData> ramps})
{
  final HashMap<CoordinateSetI, ColorReference?> layerContent = HashMap<CoordinateSetI, ColorReference?>();
  int row = 0;
  int col = 0;
  for (int i = 0; i < colorList.length; i++)
  {
    if (col >= width)
    {
      col = 0;
      row++;
    }
    final CoordinateSetI coord = CoordinateSetI(x: col, y: row);
    final ColorReference reference = legacyFindClosestColor(color: colorList[i], ramps: ramps);
    layerContent[coord] = reference;
    col++;
  }
  return layerContent;
}

ColorReference legacyFindClosestColor({required final KHSV color, required final List<KPalRampData> ramps,})
{
  final Color pixelColor = color.toColor();

  ColorReference? closestReference;
  double closestDelta = double.infinity;

  for (final KPalRampData ramp in ramps)
  {
    for (final ColorReference reference in ramp.references)
    {
      final Color refColor = reference.getIdColor().color;

      final double delta = getDeltaE00(
        redA: refColor.r,
        greenA: refColor.g,
        blueA: refColor.b,
        redB: pixelColor.r,
        greenB: pixelColor.g,
        blueB: pixelColor.b,
      );

      if (delta < closestDelta) {
        closestReference = reference;
        closestDelta = delta;
      }
    }
  }
  // closestReference is guaranteed non-null if ramps has at least one reference
  return closestReference!;
}
