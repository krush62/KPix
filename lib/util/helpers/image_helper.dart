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

import 'dart:ui' as ui;

/// Decodes the project thumbnail at [thumbnailPath].
///
/// Returns null when the file is missing or cannot be decoded. The latter
/// happens while a sync tool is still writing it, so a failure here is expected
/// and not worth a log entry: the cache retries a missing thumbnail on the next
/// scan.
Future<ui.Image?> loadThumbnail({required final String thumbnailPath}) async
{
  try
  {
    //instantiateImageCodecWithSize takes ownership of the buffer and disposes it
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(thumbnailPath);
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(buffer);
    try
    {
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    }
    finally
    {
      codec.dispose();
    }
  }
  catch (_)
  {
    return null;
  }
}
