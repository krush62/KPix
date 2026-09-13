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
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:kpix/painting/content_raster_set.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// One square of a [StrokePreview].
class _PreviewTile
{
  final CoordinateSetI offset;
  final Uint8List _rgba = Uint8List(StrokePreview.tileSize * StrokePreview.tileSize * 4);
  late final ByteData _writer = ByteData.view(_rgba.buffer);
  //raised by every write; a tile whose image is older is rendered again
  int version = 0;
  int shownVersion = 0;
  ContentRasterSet? raster;

  _PreviewTile({required this.offset});

  void write({required final int x, required final int y, required final int rgba})
  {
    _writer.setUint32(((y - offset.y) * StrokePreview.tileSize + (x - offset.x)) * 4, rgba);
    version++;
  }
}

/// What a stroke that is still being drawn looks like on the canvas.
///
/// A stroke grows by a few pixels per frame, so building one image of all of it
/// every frame gets slower the longer the stroke is. Instead, the pixels that are
/// settled are written once into square tiles, and only the tiles they touch are
/// turned into images again. The pixels at the tip of the stroke can still
/// change (pixel perfect takes corners back), so they are handed over as a whole
/// every frame and drawn on top of the tiles.
///
/// The images are made asynchronously. The result of a [render] is only shown
/// once all its images are there, and never after the result of a later render,
/// so the tiles and the tip always match.
class StrokePreview
{
  /// Pixels per tile side.
  static const int tileSize = 128;
  //tile keys are tileY * _tileKeyFactor + tileX
  static const int _tileKeyFactor = 1 << 20;

  /// Called whenever the images change.
  final void Function() onUpdate;

  final Map<int, _PreviewTile> _tiles = <int, _PreviewTile>{};
  Map<CoordinateSetI, int> _tip = HashMap<CoordinateSetI, int>();
  int _tipVersion = 0;
  int _shownTipVersion = 0;
  ContentRasterSet? _tipRaster;
  int _lastRender = 0;
  int _shownRender = 0;
  bool _isDisposed = false;

  StrokePreview({required this.onUpdate});

  /// Sets the settled pixel at [x]|[y] to [rgba], as `ui.PixelFormat.rgba8888`
  /// reads it. Pixels left of or above the canvas are ignored.
  void addPixel({required final int x, required final int y, required final int rgba})
  {
    if (x < 0 || y < 0)
    {
      return;
    }
    final int tileX = x ~/ tileSize;
    final int tileY = y ~/ tileSize;
    final _PreviewTile tile = _tiles.putIfAbsent(tileY * _tileKeyFactor + tileX, () => _PreviewTile(offset: CoordinateSetI(x: tileX * tileSize, y: tileY * tileSize)));
    tile.write(x: x, y: y, rgba: rgba);
  }

  /// Replaces the pixels of the tip, as RGBA values like in [addPixel].
  void setTip({required final Map<CoordinateSetI, int> pixels})
  {
    _tip = pixels;
    _tipVersion++;
  }

  /// The images to draw, in order: the tiles, then the tip.
  List<ContentRasterSet> get rasters
  {
    final List<ContentRasterSet> rasters = <ContentRasterSet>[];
    for (final _PreviewTile tile in _tiles.values)
    {
      final ContentRasterSet? raster = tile.raster;
      if (raster != null)
      {
        rasters.add(raster);
      }
    }
    final ContentRasterSet? tipRaster = _tipRaster;
    if (tipRaster != null)
    {
      rasters.add(tipRaster);
    }
    return rasters;
  }

  /// Makes images of everything written since the last result that was shown,
  /// and shows them together once they are all there.
  Future<void> render() async
  {
    if (_isDisposed)
    {
      return;
    }
    final int renderId = ++_lastRender;

    //every tile that is not shown as it is now is rendered again, also when an
    //earlier render is still busy with it: that render may be overtaken
    final List<(_PreviewTile, int)> tiles = <(_PreviewTile, int)>[];
    final List<Future<ui.Image>> tileImages = <Future<ui.Image>>[];
    for (final _PreviewTile tile in _tiles.values)
    {
      if (tile.version != tile.shownVersion)
      {
        tiles.add((tile, tile.version));
        //the bytes are copied because later writes must not reach this image
        tileImages.add(_decode(pixels: Uint8List.fromList(tile._rgba), width: tileSize, height: tileSize));
      }
    }

    final int tipVersion = _tipVersion;
    final bool tipChanged = tipVersion != _shownTipVersion;
    CoordinateSetI? tipOffset;
    CoordinateSetI? tipSize;
    Future<ui.Image>? tipImage;
    if (tipChanged && _tip.isNotEmpty)
    {
      final CoordinateSetI min = CoordinateSetI.getMin(coordList: _tip.keys.toList());
      final CoordinateSetI max = CoordinateSetI.getMax(coordList: _tip.keys.toList());
      tipOffset = min;
      tipSize = CoordinateSetI(x: max.x - min.x + 1, y: max.y - min.y + 1);
      final ByteData bytes = ByteData(tipSize.x * tipSize.y * 4);
      for (final MapEntry<CoordinateSetI, int> entry in _tip.entries)
      {
        bytes.setUint32(((entry.key.y - min.y) * tipSize.x + (entry.key.x - min.x)) * 4, entry.value);
      }
      tipImage = _decode(pixels: bytes.buffer.asUint8List(), width: tipSize.x, height: tipSize.y);
    }

    final List<ui.Image> images = await Future.wait<ui.Image>(tileImages);
    final ui.Image? decodedTip = tipImage == null ? null : await tipImage;

    if (_isDisposed || renderId < _shownRender)
    {
      //never shown, so nothing else holds these
      for (final ui.Image image in images)
      {
        image.dispose();
      }
      decodedTip?.dispose();
      return;
    }

    //a later render started later, so it cannot have seen older versions
    for (int i = 0; i < tiles.length; i++)
    {
      final (_PreviewTile tile, int version) = tiles[i];
      tile.raster = ContentRasterSet(image: images[i], offset: tile.offset, size: CoordinateSetI(x: tileSize, y: tileSize));
      tile.shownVersion = version;
    }
    if (tipChanged)
    {
      _tipRaster = decodedTip == null ? null : ContentRasterSet(image: decodedTip, offset: tipOffset!, size: tipSize!);
      _shownTipVersion = tipVersion;
    }
    _shownRender = renderId;
    onUpdate();
  }

  /// Drops everything; renders still running are thrown away when they finish.
  ///
  /// The images that were shown are left to the garbage collector, as the
  /// canvas may still hold on to the last ones it drew.
  void dispose()
  {
    _isDisposed = true;
    _tiles.clear();
    _tip = HashMap<CoordinateSetI, int>();
    _tipRaster = null;
  }

  static Future<ui.Image> _decode({required final Uint8List pixels, required final int width, required final int height})
  {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888, (final ui.Image image)
    {
      completer.complete(image);
    },);
    return completer.future;
  }
}
