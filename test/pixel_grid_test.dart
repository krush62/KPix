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

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

//a multiple of the tile size in neither direction, so the last tiles are partial
const int _width = 70;
const int _height = 45;

typedef _Content = Map<(int, int), int>;

_Content _contentOf({required final PixelGridView grid})
{
  final _Content content = <(int, int), int>{};
  grid.forEachNonZero(action: (final int x, final int y, final int value) {
    expect(content.containsKey((x, y)), isFalse, reason: "$x|$y reported twice");
    content[(x, y)] = value;
  },);
  return content;
}

PixelGrid _gridWith({required final _Content content, final int width = _width, final int height = _height})
{
  final PixelGrid grid = PixelGrid(width: width, height: height);
  content.forEach((final (int, int) coord, final int value) => grid.set(x: coord.$1, y: coord.$2, value: value));
  return grid;
}

/// Pixels on and next to every tile border, the grid's corners included.
_Content _borderPattern()
{
  final List<int> xs = <int>[0, 1, 31, 32, 33, 63, 64, _width - 1];
  final List<int> ys = <int>[0, 31, 32, _height - 1];
  final _Content content = <(int, int), int>{};
  int value = 1;
  for (final int x in xs)
  {
    for (final int y in ys)
    {
      content[(x, y)] = value++;
    }
  }
  return content;
}

void main()
{
  group("reading and writing", ()
  {
    test("a new grid is empty", ()
    {
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      expect(grid.isEmpty, isTrue);
      expect(grid.nonZeroCount, 0);
      expect(grid.allocatedTileCount, 0);
      expect(grid.get(x: 5, y: 5), 0);
      expect(_contentOf(grid: grid), isEmpty);
    });

    test("keeps values on both sides of every tile border", ()
    {
      final _Content pattern = _borderPattern();
      final PixelGrid grid = _gridWith(content: pattern);
      for (final MapEntry<(int, int), int> entry in pattern.entries)
      {
        expect(grid.get(x: entry.key.$1, y: entry.key.$2), entry.value, reason: "pixel ${entry.key}");
      }
      expect(_contentOf(grid: grid), pattern, reason: "no pixel may appear that was not written");
      expect(grid.nonZeroCount, pattern.length);
    });

    test("reads zero and ignores writes outside the grid", ()
    {
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      for (final (int, int) outside in <(int, int)>[(-1, 0), (0, -1), (_width, 0), (0, _height), (_width, _height - 1), (-1, -1)])
      {
        grid.set(x: outside.$1, y: outside.$2, value: 7);
        expect(grid.get(x: outside.$1, y: outside.$2), 0);
      }
      expect(grid.isEmpty, isTrue, reason: "a write past the edge must not land on another pixel");
      expect(grid.allocatedTileCount, 0);
    });

    test("counts pixels and releases tiles that become empty", ()
    {
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      grid.set(x: 1, y: 1, value: 3);
      grid.set(x: 2, y: 1, value: 3);
      grid.set(x: 40, y: 40, value: 9);
      expect(grid.nonZeroCount, 3);
      expect(grid.allocatedTileCount, 2);

      grid.set(x: 1, y: 1, value: 4);
      grid.set(x: 2, y: 1, value: 3);
      expect(grid.nonZeroCount, 3, reason: "overwriting a pixel does not add one");

      grid.set(x: 1, y: 1, value: 0);
      grid.set(x: 2, y: 1, value: 0);
      grid.set(x: 3, y: 1, value: 0);
      expect(grid.nonZeroCount, 1);
      expect(grid.allocatedTileCount, 1, reason: "the emptied tile gives its memory back");

      grid.clear();
      expect(grid.isEmpty, isTrue);
      expect(grid.allocatedTileCount, 0);
      expect(grid.get(x: 40, y: 40), 0);
    });
  });

  group("snapshots", ()
  {
    test("a snapshot keeps its content while the grid changes", ()
    {
      final _Content pattern = _borderPattern();
      final PixelGrid grid = _gridWith(content: pattern);
      final PixelGridSnapshot snapshot = grid.snapshot();

      grid.set(x: 0, y: 0, value: 999);
      grid.set(x: 31, y: 31, value: 0);
      grid.set(x: 10, y: 10, value: 5);

      expect(_contentOf(grid: snapshot), pattern);
      expect(snapshot.nonZeroCount, pattern.length);
      expect(grid.get(x: 0, y: 0), 999);
      expect(grid.get(x: 31, y: 31), 0);
      expect(grid.get(x: 10, y: 10), 5);
    });

    test("every snapshot keeps the state of its moment", ()
    {
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      grid.set(x: 3, y: 3, value: 1);
      final PixelGridSnapshot first = grid.snapshot();
      grid.set(x: 3, y: 3, value: 2);
      grid.set(x: 50, y: 20, value: 2);
      final PixelGridSnapshot second = grid.snapshot();
      grid.set(x: 3, y: 3, value: 0);

      expect(_contentOf(grid: first), <(int, int), int>{(3, 3): 1});
      expect(_contentOf(grid: second), <(int, int), int>{(3, 3): 2, (50, 20): 2});
      expect(_contentOf(grid: grid), <(int, int), int>{(50, 20): 2});
    });

    test("erasing the last pixel of a shared tile leaves the snapshot alone", ()
    {
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      grid.set(x: 40, y: 5, value: 8);
      final PixelGridSnapshot snapshot = grid.snapshot();
      grid.set(x: 40, y: 5, value: 0);

      expect(grid.allocatedTileCount, 0);
      expect(snapshot.get(x: 40, y: 5), 8);
      expect(snapshot.allocatedTileCount, 1);
    });

    test("a grid restored from a snapshot is independent in both directions", ()
    {
      final PixelGrid original = _gridWith(content: <(int, int), int>{(4, 4): 1, (60, 40): 2});
      final PixelGridSnapshot snapshot = original.snapshot();
      final PixelGrid restored = PixelGrid.fromSnapshot(snapshot: snapshot);

      restored.set(x: 4, y: 4, value: 11);
      original.set(x: 60, y: 40, value: 22);

      expect(_contentOf(grid: snapshot), <(int, int), int>{(4, 4): 1, (60, 40): 2});
      expect(_contentOf(grid: restored), <(int, int), int>{(4, 4): 11, (60, 40): 2});
      expect(_contentOf(grid: original), <(int, int), int>{(4, 4): 1, (60, 40): 22});
    });

    test("a copy is independent in both directions", ()
    {
      final PixelGrid original = _gridWith(content: <(int, int), int>{(4, 4): 1});
      final PixelGrid copy = original.copy();
      copy.set(x: 4, y: 4, value: 5);
      original.set(x: 5, y: 4, value: 6);

      expect(_contentOf(grid: copy), <(int, int), int>{(4, 4): 5});
      expect(_contentOf(grid: original), <(int, int), int>{(4, 4): 1, (5, 4): 6});
    });

    test("an unchanged grid hands out the same snapshot", ()
    {
      final PixelGrid grid = _gridWith(content: <(int, int), int>{(4, 4): 1});
      final PixelGridSnapshot snapshot = grid.snapshot();
      expect(grid.snapshot(), same(snapshot));

      grid.set(x: 4, y: 4, value: 1);
      grid.set(x: 9, y: 9, value: 0);
      grid.set(x: -1, y: 0, value: 3);
      expect(grid.snapshot(), same(snapshot), reason: "writes that change nothing keep the snapshot");
      expect(PixelGrid.fromSnapshot(snapshot: snapshot).snapshot(), same(snapshot));

      grid.set(x: 4, y: 4, value: 2);
      expect(grid.snapshot(), isNot(same(snapshot)));
    });

    test("random writes and snapshots agree with a plain map", ()
    {
      final Random random = Random(42);
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      final _Content reference = <(int, int), int>{};
      final List<(PixelGridSnapshot, _Content)> taken = <(PixelGridSnapshot, _Content)>[];

      for (int step = 0; step < 20000; step++)
      {
        //a few writes land outside, and about a third erase
        final int x = random.nextInt(_width + 4) - 2;
        final int y = random.nextInt(_height + 4) - 2;
        final int value = random.nextInt(3) == 0 ? 0 : random.nextInt(0xFFFF) + 1;
        grid.set(x: x, y: y, value: value);
        if (x >= 0 && y >= 0 && x < _width && y < _height)
        {
          if (value == 0)
          {
            reference.remove((x, y));
          }
          else
          {
            reference[(x, y)] = value;
          }
        }
        if (step % 2500 == 0)
        {
          taken.add((grid.snapshot(), Map<(int, int), int>.of(reference)));
        }
      }

      expect(_contentOf(grid: grid), reference);
      expect(grid.nonZeroCount, reference.length);
      final Set<(int, int)> usedTiles = reference.keys.map((final (int, int) c) => (c.$1 ~/ PixelGridView.tileSize, c.$2 ~/ PixelGridView.tileSize)).toSet();
      expect(grid.allocatedTileCount, usedTiles.length);
      for (final (PixelGridSnapshot snapshot, _Content content) in taken)
      {
        expect(_contentOf(grid: snapshot), content);
        expect(snapshot.nonZeroCount, content.length);
      }
    });
  });

  group("remap", ()
  {
    Uint16List lutWith({required final Map<int, int> changes})
    {
      final Uint16List lut = Uint16List(20);
      for (int i = 0; i < lut.length; i++)
      {
        lut[i] = changes[i] ?? i;
      }
      return lut;
    }

    test("translates values, keeps empty pixels empty and drops what maps to zero", ()
    {
      final PixelGrid grid = _gridWith(content: <(int, int), int>{(1, 1): 5, (2, 1): 6, (40, 40): 7});
      grid.remap(lut: lutWith(changes: <int, int>{5: 15, 7: 0}));

      expect(_contentOf(grid: grid), <(int, int), int>{(1, 1): 15, (2, 1): 6});
      expect(grid.nonZeroCount, 2);
      expect(grid.allocatedTileCount, 1, reason: "the tile whose only pixel went is released");
    });

    test("a snapshot taken before keeps the old values", ()
    {
      final PixelGrid grid = _gridWith(content: <(int, int), int>{(1, 1): 5});
      final PixelGridSnapshot snapshot = grid.snapshot();
      grid.remap(lut: lutWith(changes: <int, int>{5: 9}));

      expect(snapshot.get(x: 1, y: 1), 5);
      expect(grid.get(x: 1, y: 1), 9);
    });

    test("a table that changes nothing keeps the snapshot", ()
    {
      final PixelGrid grid = _gridWith(content: <(int, int), int>{(1, 1): 5, (40, 40): 7});
      final PixelGridSnapshot snapshot = grid.snapshot();
      grid.remap(lut: lutWith(changes: <int, int>{9: 10}));
      expect(grid.snapshot(), same(snapshot));
    });

    test("a value the table does not cover asserts", ()
    {
      final PixelGrid grid = _gridWith(content: <(int, int), int>{(1, 1): 50});
      expect(() => grid.remap(lut: lutWith(changes: <int, int>{})), throwsA(isA<AssertionError>()));
    });
  });

  group("signed values", ()
  {
    test("keep zero and negative values apart from no value", ()
    {
      final PixelGrid grid = PixelGrid(width: _width, height: _height);
      grid.setSigned(x: 1, y: 1, value: 0);
      grid.setSigned(x: 2, y: 1, value: -SignedPixels.maxMagnitude);
      grid.setSigned(x: 3, y: 1, value: SignedPixels.maxMagnitude);

      expect(grid.getSigned(x: 1, y: 1), 0);
      expect(grid.getSigned(x: 2, y: 1), -SignedPixels.maxMagnitude);
      expect(grid.getSigned(x: 3, y: 1), SignedPixels.maxMagnitude);
      expect(grid.getSigned(x: 4, y: 1), isNull);

      final Map<(int, int), int> values = <(int, int), int>{};
      grid.forEachSigned(action: (final int x, final int y, final int value) => values[(x, y)] = value);
      expect(values, <(int, int), int>{(1, 1): 0, (2, 1): -SignedPixels.maxMagnitude, (3, 1): SignedPixels.maxMagnitude});

      grid.setSigned(x: 1, y: 1, value: null);
      expect(grid.getSigned(x: 1, y: 1), isNull);
      expect(grid.nonZeroCount, 2);
    });
  });

  group("transforms follow the layer's coordinate math", ()
  {
    //DrawingLayerState.transformLayer and resizeLayer, applied to a plain map
    _Content reference({required final _Content content, required final (int, int) Function(int x, int y) move, required final int width, required final int height})
    {
      final _Content moved = <(int, int), int>{};
      content.forEach((final (int, int) coord, final int value) {
        final (int, int) target = move(coord.$1, coord.$2);
        if (target.$1 >= 0 && target.$2 >= 0 && target.$1 < width && target.$2 < height)
        {
          moved[target] = value;
        }
      });
      return moved;
    }

    final _Content pattern = _borderPattern();

    test("rotating a quarter clockwise", ()
    {
      final PixelGrid rotated = _gridWith(content: pattern).rotatedClockwise();
      expect(rotated.width, _height);
      expect(rotated.height, _width);
      expect(_contentOf(grid: rotated), reference(content: pattern, move: (final int x, final int y) => ((_height - 1) - y, x), width: _height, height: _width));
    });

    test("flipping horizontally", ()
    {
      final PixelGrid flipped = _gridWith(content: pattern).flippedHorizontally();
      expect(_contentOf(grid: flipped), reference(content: pattern, move: (final int x, final int y) => ((_width - 1) - x, y), width: _width, height: _height));
    });

    test("flipping vertically", ()
    {
      final PixelGrid flipped = _gridWith(content: pattern).flippedVertically();
      expect(_contentOf(grid: flipped), reference(content: pattern, move: (final int x, final int y) => (x, (_height - 1) - y), width: _width, height: _height));
    });

    test("resizing moves and crops", ()
    {
      for (final (int, int, int, int) resize in <(int, int, int, int)>[(100, 60, 7, 3), (40, 30, -20, -10), (_width, _height, _width, 0)])
      {
        final (int newWidth, int newHeight, int offsetX, int offsetY) = resize;
        final PixelGrid resized = _gridWith(content: pattern).resized(newWidth: newWidth, newHeight: newHeight, offsetX: offsetX, offsetY: offsetY);
        expect(resized.width, newWidth);
        expect(resized.height, newHeight);
        expect(_contentOf(grid: resized), reference(content: pattern, move: (final int x, final int y) => (x + offsetX, y + offsetY), width: newWidth, height: newHeight),
            reason: "resize to ${newWidth}x$newHeight by $offsetX|$offsetY",);
      }
    });
  });
}
