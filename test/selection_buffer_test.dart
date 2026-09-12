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
import 'package:kpix/util/helpers/selection_buffer.dart';

typedef _Content = Map<(int, int), int>;

_Content _contentOf({required final SelectionBufferView view})
{
  final _Content content = <(int, int), int>{};
  view.forEach(action: (final int x, final int y, final int code) {
    expect(content.containsKey((x, y)), isFalse, reason: "$x|$y reported twice");
    content[(x, y)] = code;
  },);
  return content;
}

SelectionBuffer _bufferWith({required final _Content content})
{
  final SelectionBuffer buffer = SelectionBuffer();
  content.forEach((final (int, int) coord, final int code) => buffer.select(x: coord.$1, y: coord.$2, code: code));
  return buffer;
}

SelectionBounds? _boundsOf({required final _Content content})
{
  if (content.isEmpty)
  {
    return null;
  }
  final Iterable<int> xs = content.keys.map((final (int, int) coord) => coord.$1);
  final Iterable<int> ys = content.keys.map((final (int, int) coord) => coord.$2);
  return (left: xs.reduce(min), top: ys.reduce(min), right: xs.reduce(max), bottom: ys.reduce(max));
}

//the formulas of the map-based selection (SelectionList before the buffer)

_Content _flippedH({required final _Content content})
{
  final SelectionBounds box = _boundsOf(content: content)!;
  return <(int, int), int>{for (final MapEntry<(int, int), int> entry in content.entries) (box.right - entry.key.$1 + box.left, entry.key.$2): entry.value};
}

_Content _flippedV({required final _Content content})
{
  final SelectionBounds box = _boundsOf(content: content)!;
  return <(int, int), int>{for (final MapEntry<(int, int), int> entry in content.entries) (entry.key.$1, box.bottom - entry.key.$2 + box.top): entry.value};
}

_Content _rotated({required final _Content content})
{
  final SelectionBounds box = _boundsOf(content: content)!;
  final int centerX = (box.left + box.right) ~/ 2;
  final int centerY = (box.top + box.bottom) ~/ 2;
  return <(int, int), int>{for (final MapEntry<(int, int), int> entry in content.entries) (centerY - entry.key.$2 + centerX, entry.key.$1 - centerX + centerY): entry.value};
}

_Content _moved({required final _Content content, required final int dx, required final int dy})
{
  return <(int, int), int>{for (final MapEntry<(int, int), int> entry in content.entries) (entry.key.$1 + dx, entry.key.$2 + dy): entry.value};
}

/// An L-shaped selection with a hole, off the canvas on the left, so that no
/// transform can map it onto itself.
_Content _shape()
{
  return <(int, int), int>{
    (-3, 2): 0, (-2, 2): 5, (-1, 2): 6, (0, 2): 7,
    (-3, 3): 8, (-1, 3): 9,
    (-3, 4): 10,
    (-3, 5): 11, (-2, 5): 12,
  };
}

void main()
{
  test("an empty selection has nothing, no box and no snapshot", ()
  {
    final SelectionBuffer buffer = SelectionBuffer();
    expect(buffer.isEmpty, isTrue);
    expect(buffer.count, 0);
    expect(buffer.contains(x: 0, y: 0), isFalse);
    expect(buffer.codeAt(x: 0, y: 0), isNull);
    expect(buffer.bounds, isNull);
    expect(buffer.snapshot(), isNull);
    buffer.flipHorizontally();
    buffer.rotateClockwise();
    buffer.moveBy(dx: 3, dy: 3);
    expect(buffer.isEmpty, isTrue, reason: "nothing to transform or move");
  });

  test("a selected pixel keeps its code, transparent included", ()
  {
    final SelectionBuffer buffer = _bufferWith(content: <(int, int), int>{(3, 4): 0, (5, 6): 17});
    expect(buffer.count, 2);
    expect(buffer.contains(x: 3, y: 4), isTrue, reason: "selected without a color");
    expect(buffer.codeAt(x: 3, y: 4), 0);
    expect(buffer.codeAt(x: 5, y: 6), 17);
    expect(buffer.contains(x: 4, y: 5), isFalse, reason: "inside the box, but not selected");
    buffer.select(x: 5, y: 6, code: 0);
    expect(buffer.codeAt(x: 5, y: 6), 0, reason: "a new code for a selected pixel");
    expect(buffer.count, 2);
  });

  test("grows in every direction, far off the canvas included", ()
  {
    final _Content content = <(int, int), int>{(0, 0): 1, (-40, -3): 2, (100, 70): 3, (-1, 90): 4, (250, -64): 5};
    final SelectionBuffer buffer = _bufferWith(content: content);
    expect(_contentOf(view: buffer), content);
    expect(buffer.bounds, (left: -40, top: -64, right: 250, bottom: 90));
  });

  test("covering first changes nothing that is selected", ()
  {
    final SelectionBuffer buffer = _bufferWith(content: <(int, int), int>{(1, 1): 7});
    buffer.cover(left: -100, top: -5, right: 3, bottom: 200);
    expect(_contentOf(view: buffer), <(int, int), int>{(1, 1): 7});
    expect(buffer.bounds, (left: 1, top: 1, right: 1, bottom: 1), reason: "the box is around what is selected, not around the room");
  });

  test("the box stays tight when pixels are deselected", ()
  {
    final _Content block = <(int, int), int>{for (int x = 2; x < 9; x++) for (int y = -2; y < 4; y++) (x, y): x};
    final SelectionBuffer buffer = _bufferWith(content: block);
    for (int y = -2; y < 4; y++)
    {
      buffer.deselect(x: 8, y: y);
      buffer.deselect(x: 2, y: y);
    }
    buffer.deselect(x: 5, y: -2);
    expect(buffer.bounds, (left: 3, top: -2, right: 7, bottom: 3));
    buffer.deselect(x: 50, y: 50);
    expect(buffer.count, 5 * 6 - 1, reason: "deselecting what is not selected does nothing");

    for (final (int, int) coord in block.keys)
    {
      buffer.deselect(x: coord.$1, y: coord.$2);
    }
    expect(buffer.isEmpty, isTrue);
    expect(buffer.bounds, isNull);
    expect(buffer.snapshot(), isNull);
  });

  test("moving shifts every pixel and the box", ()
  {
    final SelectionBuffer buffer = _bufferWith(content: _shape());
    buffer.moveBy(dx: 30, dy: -7);
    expect(_contentOf(view: buffer), _moved(content: _shape(), dx: 30, dy: -7));
    expect(buffer.bounds, (left: 27, top: -5, right: 30, bottom: -2));
  });

  test("flips mirror within the tight box, also after deselecting left room in the grid", ()
  {
    final _Content content = _shape();
    final SelectionBuffer buffer = _bufferWith(content: <(int, int), int>{...content, (40, 40): 1, (-20, -20): 1});
    buffer.deselect(x: 40, y: 40);
    buffer.deselect(x: -20, y: -20);

    buffer.flipHorizontally();
    expect(_contentOf(view: buffer), _flippedH(content: content));
    buffer.flipVertically();
    expect(_contentOf(view: buffer), _flippedV(content: _flippedH(content: content)));
    expect(buffer.bounds, _boundsOf(content: content), reason: "flipping keeps the box");
  });

  test("turns around the middle of its box, rounded towards zero like before", ()
  {
    //an even width and odd height, left of the canvas, so the middle is
    //rounded, and rounded towards zero rather than down
    _Content expected = _shape();
    final SelectionBuffer buffer = _bufferWith(content: expected);
    for (int turn = 1; turn <= 4; turn++)
    {
      buffer.rotateClockwise();
      expected = _rotated(content: expected);
      expect(_contentOf(view: buffer), expected, reason: "turn $turn");
      expect(buffer.bounds, _boundsOf(content: expected), reason: "turn $turn");
    }
  });

  test("a snapshot stays as it was when the selection changes, and the other way round", ()
  {
    final SelectionBuffer buffer = _bufferWith(content: _shape());
    final SelectionBufferSnapshot frozen = buffer.snapshot()!;
    buffer.select(x: -2, y: 3, code: 40);
    buffer.deselect(x: -3, y: 2);
    buffer.remap(lut: Uint16List(64));
    buffer.moveBy(dx: 1, dy: 1);
    buffer.rotateClockwise();
    expect(_contentOf(view: frozen), _shape());

    final SelectionBuffer other = SelectionBuffer.fromSnapshot(snapshot: frozen);
    final _Content before = _contentOf(view: buffer);
    other.select(x: 0, y: 2, code: 44);
    other.flipVertically();
    expect(_contentOf(view: frozen), _shape());
    expect(_contentOf(view: buffer), before);
  });

  test("hands out the same snapshot until something changes", ()
  {
    final SelectionBuffer buffer = _bufferWith(content: _shape());
    final SelectionBufferSnapshot first = buffer.snapshot()!;
    expect(buffer.snapshot(), same(first));
    buffer.select(x: 0, y: 2, code: 7);
    expect(buffer.snapshot(), same(first), reason: "the same code again changes nothing");
    buffer.moveBy(dx: 1, dy: 0);
    final SelectionBufferSnapshot moved = buffer.snapshot()!;
    expect(moved, isNot(same(first)));
    expect(_contentOf(view: moved), _moved(content: _shape(), dx: 1, dy: 0));
  });

  test("remapping changes the codes but not what is selected", ()
  {
    final SelectionBuffer buffer = _bufferWith(content: <(int, int), int>{(0, 0): 0, (1, 0): 17, (2, 0): 18});
    final Uint16List lut = Uint16List(19);
    lut[17] = 3;
    buffer.remap(lut: lut);
    expect(_contentOf(view: buffer), <(int, int), int>{(0, 0): 0, (1, 0): 3, (2, 0): 0});
  });

  test("replacing takes over a snapshot, and nothing deselects everything", ()
  {
    final SelectionBufferSnapshot shape = _bufferWith(content: _shape()).snapshot()!;
    final SelectionBuffer buffer = _bufferWith(content: <(int, int), int>{(50, 50): 1});
    buffer.replaceWith(snapshot: shape);
    expect(_contentOf(view: buffer), _shape());
    expect(buffer.bounds, _boundsOf(content: _shape()));
    expect(buffer.snapshot(), same(shape));
    buffer.replaceWith(snapshot: null);
    expect(buffer.isEmpty, isTrue);
  });

  test("a random run matches a plain map", ()
  {
    final Random random = Random(7);
    final SelectionBuffer buffer = SelectionBuffer();
    _Content expected = <(int, int), int>{};
    final List<(SelectionBufferSnapshot?, _Content)> frozen = <(SelectionBufferSnapshot?, _Content)>[];
    for (int step = 0; step < 6000; step++)
    {
      final int action = random.nextInt(100);
      if (action < 60)
      {
        final (int, int) coord = (random.nextInt(120) - 40, random.nextInt(90) - 30);
        final int code = random.nextInt(50);
        buffer.select(x: coord.$1, y: coord.$2, code: code);
        expected[coord] = code;
      }
      else if (action < 90)
      {
        final (int, int) coord = expected.isNotEmpty && random.nextBool() ? expected.keys.elementAt(random.nextInt(expected.length)) : (random.nextInt(120) - 40, random.nextInt(90) - 30);
        buffer.deselect(x: coord.$1, y: coord.$2);
        expected.remove(coord);
      }
      else if (expected.isNotEmpty && action < 93)
      {
        final int dx = random.nextInt(21) - 10;
        final int dy = random.nextInt(21) - 10;
        buffer.moveBy(dx: dx, dy: dy);
        expected = _moved(content: expected, dx: dx, dy: dy);
      }
      else if (expected.isNotEmpty && action < 95)
      {
        buffer.flipHorizontally();
        expected = _flippedH(content: expected);
      }
      else if (expected.isNotEmpty && action < 97)
      {
        buffer.flipVertically();
        expected = _flippedV(content: expected);
      }
      else if (expected.isNotEmpty && action < 99)
      {
        buffer.rotateClockwise();
        expected = _rotated(content: expected);
      }
      else
      {
        frozen.add((buffer.snapshot(), Map<(int, int), int>.of(expected)));
      }
      if (step % 250 == 0)
      {
        expect(_contentOf(view: buffer), expected, reason: "step $step");
        expect(buffer.bounds, _boundsOf(content: expected), reason: "step $step");
      }
    }
    expect(_contentOf(view: buffer), expected);
    expect(buffer.count, expected.length);
    for (final (SelectionBufferSnapshot?, _Content) entry in frozen)
    {
      expect(entry.$1 == null ? <(int, int), int>{} : _contentOf(view: entry.$1!), entry.$2, reason: "a snapshot changed later");
    }
  });
}
