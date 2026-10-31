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

import 'package:flutter/scheduler.dart';

/// Decodes the project thumbnail at [thumbnailPath].
///
/// Returns null when the file is missing or cannot be decoded. The latter
/// happens while a sync tool is still writing it, so a failure here is expected
/// and not worth a log entry: the cache retries a missing thumbnail on the next
/// scan.
/// Disposes [images] once the frame that may still draw them is over.
void disposeAfterFrame({required final Iterable<ui.Image> images})
{
  SchedulerBinding.instance.addPostFrameCallback((final Duration _)
  {
    for (final ui.Image image in images)
    {
      image.dispose();
    }
  });
  //disposal can be triggered from a microtask, where no frame is pending and the
  //callback would otherwise sit until something else asks for one
  SchedulerBinding.instance.scheduleFrame();
}

/// Collects replaced images and disposes them together after the current frame.
class ImageRetirer
{
  final List<ui.Image> _pending = <ui.Image>[];

  void retire({required final ui.Image image})
  {
    _pending.add(image);
    if (_pending.length > 1)
    {
      //a flush is already scheduled and will take this one too
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) => disposeNow());
    //nothing else may be dirty, in which case no frame would ever be produced
    SchedulerBinding.instance.scheduleFrame();
  }

  void disposeNow()
  {
    final List<ui.Image> images = List<ui.Image>.of(_pending);
    _pending.clear();
    for (final ui.Image image in images)
    {
      image.dispose();
    }
  }
}

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
