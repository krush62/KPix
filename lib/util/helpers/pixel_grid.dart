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

import 'dart:math';
import 'dart:typed_data';

/// Read access to a grid of 16-bit pixel values, shared by [PixelGrid] and
/// [PixelGridSnapshot].
///
/// Zero is the empty value; for color codes it is transparent (see
/// PaletteCodec). The grid is split into square tiles of [tileSize] pixels a
/// side, and a tile holding only zeros is not allocated, so empty and sparse
/// content costs little more than the tile table.
abstract class PixelGridView
{
  static const int _tileShift = 5;

  /// Pixels per tile side.
  static const int tileSize = 1 << _tileShift;
  static const int _tileMask = tileSize - 1;
  static const int _tileArea = tileSize * tileSize;

  final int width;
  final int height;
  final int _tilesX;
  final int _tilesY;
  final List<Uint16List?> _tiles;
  //non-zero pixels per tile; a tile whose count drops to zero is released
  final Uint16List _counts;
  int _nonZeroCount;

  PixelGridView._({
    required this.width,
    required this.height,
    required final List<Uint16List?> tiles,
    required final Uint16List counts,
    required final int nonZeroCount,
  }) :
        assert(width > 0 && height > 0, "a pixel grid needs at least one pixel, not ${width}x$height"),
        _tilesX = _tilesAlong(pixels: width),
        _tilesY = _tilesAlong(pixels: height),
        _tiles = tiles,
        _counts = counts,
        _nonZeroCount = nonZeroCount;

  static int _tilesAlong({required final int pixels})
  {
    return (pixels + _tileMask) >> _tileShift;
  }

  /// How many pixels hold a value other than zero.
  int get nonZeroCount
  {
    return _nonZeroCount;
  }

  bool get isEmpty
  {
    return _nonZeroCount == 0;
  }

  /// How many tiles hold memory, at [tileSize] × [tileSize] × 2 bytes each.
  int get allocatedTileCount
  {
    int count = 0;
    for (final Uint16List? tile in _tiles)
    {
      if (tile != null)
      {
        count++;
      }
    }
    return count;
  }

  /// The value at [x]|[y], or zero outside the grid.
  int get({required final int x, required final int y})
  {
    if (x < 0 || y < 0 || x >= width || y >= height)
    {
      return 0;
    }
    final Uint16List? tile = _tiles[(y >> _tileShift) * _tilesX + (x >> _tileShift)];
    return tile == null ? 0 : tile[((y & _tileMask) << _tileShift) | (x & _tileMask)];
  }

  /// Calls [action] for every pixel that is not zero, tile by tile.
  ///
  /// [action] must not change this grid.
  void forEachNonZero({required final void Function(int x, int y, int value) action})
  {
    for (int tileY = 0; tileY < _tilesY; tileY++)
    {
      final int top = tileY << _tileShift;
      final int rows = min(tileSize, height - top);
      for (int tileX = 0; tileX < _tilesX; tileX++)
      {
        final Uint16List? tile = _tiles[tileY * _tilesX + tileX];
        if (tile == null)
        {
          continue;
        }
        final int left = tileX << _tileShift;
        final int columns = min(tileSize, width - left);
        for (int row = 0; row < rows; row++)
        {
          final int rowStart = row << _tileShift;
          for (int column = 0; column < columns; column++)
          {
            final int value = tile[rowStart + column];
            if (value != 0)
            {
              action(left + column, top + row, value);
            }
          }
        }
      }
    }
  }

  /// A copy turned a quarter clockwise; width and height swap.
  PixelGrid rotatedClockwise()
  {
    final PixelGrid result = PixelGrid(width: height, height: width);
    forEachNonZero(action: (final int x, final int y, final int value) => result.set(x: height - 1 - y, y: x, value: value));
    return result;
  }

  /// A copy mirrored left to right.
  PixelGrid flippedHorizontally()
  {
    final PixelGrid result = PixelGrid(width: width, height: height);
    forEachNonZero(action: (final int x, final int y, final int value) => result.set(x: width - 1 - x, y: y, value: value));
    return result;
  }

  /// A copy mirrored top to bottom.
  PixelGrid flippedVertically()
  {
    final PixelGrid result = PixelGrid(width: width, height: height);
    forEachNonZero(action: (final int x, final int y, final int value) => result.set(x: x, y: height - 1 - y, value: value));
    return result;
  }

  /// A copy of size [newWidth] × [newHeight] with every pixel moved by
  /// [offsetX]|[offsetY]; whatever ends up outside is cut off.
  PixelGrid resized({required final int newWidth, required final int newHeight, required final int offsetX, required final int offsetY})
  {
    final PixelGrid result = PixelGrid(width: newWidth, height: newHeight);
    forEachNonZero(action: (final int x, final int y, final int value) => result.set(x: x + offsetX, y: y + offsetY, value: value));
    return result;
  }
}

/// A grid of 16-bit pixel values that can be snapshotted cheaply.
///
/// [snapshot] shares the tiles instead of copying them. They stay shared until
/// either side writes: a grid writes in place only into tiles it created since
/// its last snapshot, and clones any other tile first. That keeps every
/// snapshot unchanged without reference counting, and makes a snapshot cost the
/// tile table plus the tiles written afterwards.
class PixelGrid extends PixelGridView
{
  //1 where this grid may write into the tile in place: it created the tile
  //after its last snapshot, so nothing else can be holding it
  final Uint8List _owned;
  //the snapshot matching the current content, reused until the next change
  PixelGridSnapshot? _lastSnapshot;

  /// An empty grid.
  factory PixelGrid({required final int width, required final int height})
  {
    final int tileCount = PixelGridView._tilesAlong(pixels: width) * PixelGridView._tilesAlong(pixels: height);
    return PixelGrid._(
      width: width,
      height: height,
      tiles: List<Uint16List?>.filled(tileCount, null),
      counts: Uint16List(tileCount),
      nonZeroCount: 0,
      owned: Uint8List(tileCount),
      lastSnapshot: null,
    );
  }

  /// A grid starting out with the content of [snapshot], sharing its tiles.
  factory PixelGrid.fromSnapshot({required final PixelGridSnapshot snapshot})
  {
    return PixelGrid._(
      width: snapshot.width,
      height: snapshot.height,
      tiles: List<Uint16List?>.of(snapshot._tiles, growable: false),
      counts: Uint16List.fromList(snapshot._counts),
      nonZeroCount: snapshot._nonZeroCount,
      owned: Uint8List(snapshot._tiles.length),
      lastSnapshot: snapshot,
    );
  }

  PixelGrid._({
    required super.width,
    required super.height,
    required super.tiles,
    required super.counts,
    required super.nonZeroCount,
    required final Uint8List owned,
    required final PixelGridSnapshot? lastSnapshot,
  }) :
        _owned = owned,
        _lastSnapshot = lastSnapshot,
        super._();

  /// Sets the pixel at [x]|[y] to [value]; zero empties it.
  ///
  /// A pixel outside the grid cannot hold anything, so writing there does
  /// nothing.
  void set({required final int x, required final int y, required final int value})
  {
    assert(value >= 0 && value <= 0xFFFF, "$value does not fit into 16 bits");
    if (x < 0 || y < 0 || x >= width || y >= height)
    {
      return;
    }
    final int tileIndex = (y >> PixelGridView._tileShift) * _tilesX + (x >> PixelGridView._tileShift);
    final int pixelIndex = ((y & PixelGridView._tileMask) << PixelGridView._tileShift) | (x & PixelGridView._tileMask);
    Uint16List? tile = _tiles[tileIndex];
    if (tile == null)
    {
      if (value == 0)
      {
        return;
      }
      tile = Uint16List(PixelGridView._tileArea);
      _tiles[tileIndex] = tile;
      _owned[tileIndex] = 1;
    }

    final int previous = tile[pixelIndex];
    if (previous == value)
    {
      return;
    }
    _lastSnapshot = null;

    if (value == 0 && _counts[tileIndex] == 1)
    {
      //the tile's last pixel goes, so the tile goes instead of being written to
      _tiles[tileIndex] = null;
      _owned[tileIndex] = 0;
      _counts[tileIndex] = 0;
      _nonZeroCount--;
      return;
    }
    if (_owned[tileIndex] == 0)
    {
      tile = Uint16List.fromList(tile);
      _tiles[tileIndex] = tile;
      _owned[tileIndex] = 1;
    }
    tile[pixelIndex] = value;
    if (previous == 0)
    {
      _counts[tileIndex]++;
      _nonZeroCount++;
    }
    else if (value == 0)
    {
      _counts[tileIndex]--;
      _nonZeroCount--;
    }
  }

  /// Empties every pixel.
  void clear()
  {
    if (_nonZeroCount == 0)
    {
      return;
    }
    _tiles.fillRange(0, _tiles.length, null);
    _counts.fillRange(0, _counts.length, 0);
    _owned.fillRange(0, _owned.length, 0);
    _nonZeroCount = 0;
    _lastSnapshot = null;
  }

  /// Replaces every value `v` with `lut[v]`, e.g. to follow a palette change
  /// (see PaletteCodec.remapLut).
  ///
  /// Zero has to stay zero. A tile the table does not change stays shared with
  /// earlier snapshots. A value past the end of [lut] cannot be translated; it
  /// asserts, and becomes zero in release builds.
  void remap({required final Uint16List lut})
  {
    assert(lut.isNotEmpty && lut[0] == 0, "remapping must keep empty pixels empty");
    for (int tileIndex = 0; tileIndex < _tiles.length; tileIndex++)
    {
      Uint16List? tile = _tiles[tileIndex];
      if (tile == null)
      {
        continue;
      }
      int pixelIndex = 0;
      while (pixelIndex < PixelGridView._tileArea && _translate(lut: lut, value: tile[pixelIndex]) == tile[pixelIndex])
      {
        pixelIndex++;
      }
      if (pixelIndex == PixelGridView._tileArea)
      {
        continue;
      }

      _lastSnapshot = null;
      if (_owned[tileIndex] == 0)
      {
        tile = Uint16List.fromList(tile);
        _tiles[tileIndex] = tile;
        _owned[tileIndex] = 1;
      }
      int count = _counts[tileIndex];
      for (; pixelIndex < PixelGridView._tileArea; pixelIndex++)
      {
        final int value = tile[pixelIndex];
        if (value != 0)
        {
          final int translated = _translate(lut: lut, value: value);
          if (translated != value)
          {
            tile[pixelIndex] = translated;
            if (translated == 0)
            {
              count--;
            }
          }
        }
      }
      _nonZeroCount -= _counts[tileIndex] - count;
      _counts[tileIndex] = count;
      if (count == 0)
      {
        _tiles[tileIndex] = null;
        _owned[tileIndex] = 0;
      }
    }
  }

  static int _translate({required final Uint16List lut, required final int value})
  {
    assert(value < lut.length, "value $value has no entry in a table of ${lut.length}");
    return value < lut.length ? lut[value] : 0;
  }

  /// A frozen copy of the current content.
  ///
  /// Shares the tiles instead of copying them, and hands out the same snapshot
  /// again as long as nothing changed in between.
  PixelGridSnapshot snapshot()
  {
    final PixelGridSnapshot? last = _lastSnapshot;
    if (last != null)
    {
      return last;
    }
    _owned.fillRange(0, _owned.length, 0);
    return _lastSnapshot = PixelGridSnapshot._(
      width: width,
      height: height,
      tiles: List<Uint16List?>.unmodifiable(_tiles),
      counts: Uint16List.fromList(_counts),
      nonZeroCount: _nonZeroCount,
    );
  }

  /// An independent grid with the same content, sharing tiles until either
  /// side writes.
  PixelGrid copy()
  {
    return PixelGrid.fromSnapshot(snapshot: snapshot());
  }
}

/// A frozen copy of a [PixelGrid], for example for the history.
///
/// See [PixelGrid.snapshot].
class PixelGridSnapshot extends PixelGridView
{
  PixelGridSnapshot._({
    required super.width,
    required super.height,
    required super.tiles,
    required super.counts,
    required super.nonZeroCount,
  }) : super._();
}
