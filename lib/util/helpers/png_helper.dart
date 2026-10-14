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

import 'package:image/image.dart' as img;

/// Decoded PNG pixels as straight RGBA bytes, row by row.
class RgbaPixels
{
  final int width;
  final int height;
  final ByteData bytes;

  const RgbaPixels({required this.width, required this.height, required this.bytes});
}

/// Decodes [pngBytes] in Dart, so it can run on a background isolate and needs
/// no GPU readback. Returns null if the data cannot be decoded.
RgbaPixels? decodePngToRgba({required final Uint8List pngBytes})
{
  img.Image? image;
  try
  {
    image = img.decodePng(pngBytes);
  }
  catch (_)
  {
    return null;
  }
  if (image == null)
  {
    return null;
  }
  if (image.format != img.Format.uint8)
  {
    image = image.convert(format: img.Format.uint8);
  }
  final Uint8List rgba = Uint8List(image.width * image.height * 4);
  int i = 0;
  //the pixel iterator resolves palettes and reports a missing alpha channel as opaque
  for (final img.Pixel pixel in image)
  {
    rgba[i++] = pixel.r.toInt();
    rgba[i++] = pixel.g.toInt();
    rgba[i++] = pixel.b.toInt();
    rgba[i++] = pixel.a.toInt();
  }
  return RgbaPixels(width: image.width, height: image.height, bytes: ByteData.sublistView(rgba));
}
