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

import 'package:kpix/util/helpers/pixel_grid.dart';

/// The box around the selected pixels, its edges included.
typedef SelectionBounds = ({int left, int top, int right, int bottom});

/// Read access to the pixels of a selection, shared by [SelectionBuffer] and
/// [SelectionBufferSnapshot].
///
/// A selection is not bound to the canvas: a floating selection can be moved
/// partly or wholly off it and keeps its pixels there. They are held in a
/// [PixelGrid] that only covers the selection, with its top left pixel placed
/// at an origin, so moving the selection moves the origin and nothing else.
///
/// Every selected pixel holds a color code (see PaletteCodec), whose codec the
/// owner of the selection keeps. The grid stores the code plus one: zero still
/// means "not selected", and a selected pixel without a color is 1.
abstract class SelectionBufferView
{
  int get _left;
  int get _top;
  PixelGridView? get _grid;

  /// Whether no pixel is selected.
  bool get isEmpty
  {
    final PixelGridView? grid = _grid;
    return grid == null || grid.isEmpty;
  }

  /// How many pixels are selected.
  int get count
  {
    return _grid?.nonZeroCount ?? 0;
  }

  /// Whether [x]|[y] is selected.
  bool contains({required final int x, required final int y})
  {
    final PixelGridView? grid = _grid;
    return grid != null && grid.get(x: x - _left, y: y - _top) != 0;
  }

  /// The code at [x]|[y], transparent included, or null where nothing is
  /// selected.
  int? codeAt({required final int x, required final int y})
  {
    final int value = _grid?.get(x: x - _left, y: y - _top) ?? 0;
    return value == 0 ? null : value - 1;
  }

  /// Calls [action] for every selected pixel, tile by tile.
  ///
  /// [action] must not change this selection.
  void forEach({required final void Function(int x, int y, int code) action})
  {
    final int left = _left;
    final int top = _top;
    _grid?.forEachNonZero(action: (final int x, final int y, final int value) => action(x + left, y + top, value - 1));
  }

  /// The box around the selected pixels, or null if nothing is selected.
  SelectionBounds? get bounds
  {
    return _measureBounds();
  }

  SelectionBounds? _measureBounds()
  {
    final PixelGridView? grid = _grid;
    if (grid == null)
    {
      return null;
    }
    int left = grid.width;
    int top = grid.height;
    int right = -1;
    int bottom = -1;
    grid.forEachNonZero(action: (final int x, final int y, final int value)
    {
      left = min(left, x);
      top = min(top, y);
      right = max(right, x);
      bottom = max(bottom, y);
    },);
    return right < 0 ? null : (left: left + _left, top: top + _top, right: right + _left, bottom: bottom + _top);
  }
}

/// The pixels of a live selection, see [SelectionBufferView].
///
/// The grid only ever grows while pixels are selected; deselected pixels
/// leave empty space behind, which costs nothing once a whole tile is empty.
/// [bounds] is always the tight box around what is selected, and the flips and
/// the rotation work on that box.
class SelectionBuffer extends SelectionBufferView
{
  int _originX = 0;
  int _originY = 0;
  PixelGrid? _pixels;
  //the tight box, kept up to date where that is cheap and measured otherwise
  SelectionBounds? _bounds;
  bool _boundsKnown = true;
  //the snapshot matching the current content, reused until the next change
  SelectionBufferSnapshot? _lastSnapshot;

  /// An empty selection.
  SelectionBuffer();

  /// A selection starting out with the pixels of [snapshot], sharing its tiles.
  SelectionBuffer.fromSnapshot({required final SelectionBufferSnapshot snapshot})
  {
    replaceWith(snapshot: snapshot);
  }

  @override
  int get _left => _originX;

  @override
  int get _top => _originY;

  @override
  PixelGridView? get _grid => _pixels;

  @override
  SelectionBounds? get bounds
  {
    if (!_boundsKnown)
    {
      _bounds = _measureBounds();
      _boundsKnown = true;
    }
    return _bounds;
  }

  /// Makes room for pixels from [left]|[top] to [right]|[bottom], so that a
  /// batch of [select] calls grows the grid once at most.
  void cover({required final int left, required final int top, required final int right, required final int bottom})
  {
    assert(left <= right && top <= bottom, "$left|$top to $right|$bottom is not a box");
    final PixelGrid? grid = _pixels;
    if (grid == null)
    {
      _pixels = PixelGrid(width: right - left + 1, height: bottom - top + 1);
      _originX = left;
      _originY = top;
      return;
    }
    final int gridRight = _originX + grid.width - 1;
    final int gridBottom = _originY + grid.height - 1;
    if (left >= _originX && top >= _originY && right <= gridRight && bottom <= gridBottom)
    {
      return;
    }
    //a side that needs room grows by at least the grid's size, so that selecting
    //pixel by pixel outwards stays linear
    final int newLeft = left < _originX ? min(left, _originX - grid.width) : _originX;
    final int newTop = top < _originY ? min(top, _originY - grid.height) : _originY;
    final int newRight = right > gridRight ? max(right, gridRight + grid.width) : gridRight;
    final int newBottom = bottom > gridBottom ? max(bottom, gridBottom + grid.height) : gridBottom;
    _pixels = grid.resized(newWidth: newRight - newLeft + 1, newHeight: newBottom - newTop + 1, offsetX: _originX - newLeft, offsetY: _originY - newTop);
    _originX = newLeft;
    _originY = newTop;
  }

  /// Selects [x]|[y] holding [code], or gives an already selected pixel that
  /// code.
  void select({required final int x, required final int y, required final int code})
  {
    assert(code >= 0 && code < 0xFFFF, "$code is not a color code");
    cover(left: x, top: y, right: x, bottom: y);
    _pixels!.set(x: x - _originX, y: y - _originY, value: code + 1);
    if (_boundsKnown)
    {
      final SelectionBounds? box = _bounds;
      _bounds = box == null ? (left: x, top: y, right: x, bottom: y) : (left: min(box.left, x), top: min(box.top, y), right: max(box.right, x), bottom: max(box.bottom, y));
    }
  }

  /// Deselects [x]|[y].
  void deselect({required final int x, required final int y})
  {
    final PixelGrid? grid = _pixels;
    if (grid == null || grid.get(x: x - _originX, y: y - _originY) == 0)
    {
      return;
    }
    grid.set(x: x - _originX, y: y - _originY, value: 0);
    if (grid.isEmpty)
    {
      clear();
    }
    else
    {
      _boundsKnown = false;
    }
  }

  /// Deselects everything.
  void clear()
  {
    _pixels = null;
    _originX = 0;
    _originY = 0;
    _bounds = null;
    _boundsKnown = true;
    _lastSnapshot = null;
  }

  /// Moves every selected pixel by [dx]|[dy].
  void moveBy({required final int dx, required final int dy})
  {
    if (_pixels == null)
    {
      return;
    }
    _originX += dx;
    _originY += dy;
    final SelectionBounds? box = _bounds;
    if (box != null)
    {
      _bounds = (left: box.left + dx, top: box.top + dy, right: box.right + dx, bottom: box.bottom + dy);
    }
  }

  /// Replaces every code `c` with `lut[c]`, e.g. to follow a palette change
  /// (see PaletteCodec.remapLut). What is selected stays selected.
  void remap({required final Uint16List lut})
  {
    final PixelGrid? grid = _pixels;
    if (grid == null)
    {
      return;
    }
    final Uint16List biased = Uint16List(lut.length + 1);
    for (int code = 0; code < lut.length; code++)
    {
      biased[code + 1] = lut[code] + 1;
    }
    grid.remap(lut: biased);
  }

  /// Mirrors the selection left to right within its box.
  void flipHorizontally()
  {
    _replaceWithinBounds(turned: false, place: (final int x, final int y, final int width, final int height) => (width - 1 - x, y));
  }

  /// Mirrors the selection top to bottom within its box.
  void flipVertically()
  {
    _replaceWithinBounds(turned: false, place: (final int x, final int y, final int width, final int height) => (x, height - 1 - y));
  }

  /// Turns the selection a quarter clockwise around the middle of its box.
  ///
  /// The middle is rounded towards zero on both axes, as the selection always
  /// did, so turning four times can move it by a pixel.
  void rotateClockwise()
  {
    final SelectionBounds? box = bounds;
    if (box == null)
    {
      return;
    }
    final int centerX = (box.left + box.right) ~/ 2;
    final int centerY = (box.top + box.bottom) ~/ 2;
    _replaceWithinBounds(turned: true, place: (final int x, final int y, final int width, final int height) => (height - 1 - y, x));
    _originX = centerX + centerY - box.bottom;
    _originY = centerY - centerX + box.left;
    _bounds = (left: _originX, top: _originY, right: _originX + box.bottom - box.top, bottom: _originY + box.right - box.left);
  }

  /// Moves every pixel into a new grid that fits the tight box and starts out
  /// at the box's top left. [place] gives the new spot of the pixel at x|y,
  /// both relative to the box of size width × height; [turned] swaps the new
  /// grid's width and height.
  void _replaceWithinBounds({required final bool turned, required final (int, int) Function(int x, int y, int width, int height) place})
  {
    final SelectionBounds? box = bounds;
    final PixelGrid? grid = _pixels;
    if (box == null || grid == null)
    {
      return;
    }
    final int width = box.right - box.left + 1;
    final int height = box.bottom - box.top + 1;
    final PixelGrid result = PixelGrid(width: turned ? height : width, height: turned ? width : height);
    final int shiftX = _originX - box.left;
    final int shiftY = _originY - box.top;
    grid.forEachNonZero(action: (final int x, final int y, final int value)
    {
      final (int placedX, int placedY) = place(x + shiftX, y + shiftY, width, height);
      result.set(x: placedX, y: placedY, value: value);
    },);
    _pixels = result;
    _originX = box.left;
    _originY = box.top;
  }

  /// A frozen copy of the selection that shares its tiles, or null if nothing
  /// is selected. Hands out the same snapshot again as long as nothing changed.
  SelectionBufferSnapshot? snapshot()
  {
    final PixelGrid? grid = _pixels;
    if (grid == null || grid.isEmpty)
    {
      return null;
    }
    final PixelGridSnapshot pixels = grid.snapshot();
    final SelectionBufferSnapshot? last = _lastSnapshot;
    if (last != null && identical(last._pixels, pixels) && last._left == _originX && last._top == _originY)
    {
      return last;
    }
    return _lastSnapshot = SelectionBufferSnapshot._(left: _originX, top: _originY, pixels: pixels);
  }

  /// Takes over the pixels of [snapshot], sharing its tiles, or deselects
  /// everything for null.
  void replaceWith({required final SelectionBufferSnapshot? snapshot})
  {
    if (snapshot == null)
    {
      clear();
      return;
    }
    _pixels = PixelGrid.fromSnapshot(snapshot: snapshot._pixels);
    _originX = snapshot._left;
    _originY = snapshot._top;
    _boundsKnown = false;
    _lastSnapshot = snapshot;
  }
}

/// A frozen selection, see [SelectionBuffer.snapshot].
class SelectionBufferSnapshot extends SelectionBufferView
{
  @override
  final int _left;
  @override
  final int _top;
  final PixelGridSnapshot _pixels;

  SelectionBufferSnapshot._({required final int left, required final int top, required final PixelGridSnapshot pixels}) :
        _left = left,
        _top = top,
        _pixels = pixels;

  @override
  PixelGridView get _grid => _pixels;
}
