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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ReferenceImage
{
  final String path;
  final ui.Image image;

  ReferenceImage({required this.path, required this.image});
}

class ReferenceImageManager
{
  final List<ReferenceImage> _images = [];

  Future<ReferenceImage> addLoadedImage({required ui.Image img, required String path}) async
  {
    final String absolutePath = File(path).absolute.path;
    final List<ReferenceImage> duplicateImages = _images.where((i) => i.path == absolutePath).toList();
    if (duplicateImages.isNotEmpty)
    {
      return duplicateImages[0];
    }
    else
    {
      final ReferenceImage refImg = ReferenceImage(path: absolutePath, image: img);
      _images.add(refImg);
      return refImg;
    }
  }

  Future<ReferenceImage?> loadImageFile({required final String path}) async
  {
    try
    {
      final String absolutePath = File(path).absolute.path;
      final List<ReferenceImage> duplicateImages = _images.where((i) => i.path == absolutePath).toList();
      if (duplicateImages.isNotEmpty)
      {
         return duplicateImages[0];
      }
      else
      {
        final File imageFile = File(path);
        if (!await imageFile.exists())
        {
          return null;
        }
        else
        {
          final Uint8List imageBytes = await imageFile.readAsBytes();
          final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
          final ui.FrameInfo frame = await codec.getNextFrame();
          final ui.Image image = frame.image;
          final ReferenceImage refImg = ReferenceImage(path: imageFile.absolute.path, image: image);
          _images.add(refImg);
          return refImg;
        }
      }
    }
    catch (e)
    {
      return null;
    }
  }


  Future<void> removeImageByPath({required final String path}) async
  {
    final String absolutePath = File(path).absolute.path;
    final Iterable<ReferenceImage> foundImages = _images.where((i) => i.path == absolutePath);
    for (final ReferenceImage refImage in foundImages)
    {
      _images.remove(refImage);
    }
  }

  Future<void> removeImage({required final ReferenceImage refImage}) async
  {
    _images.remove(refImage);
  }
}