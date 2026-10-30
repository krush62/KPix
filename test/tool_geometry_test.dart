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
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/tool_geometry_helper.dart';

CoordinateSetI _c(final int x, final int y) => CoordinateSetI(x: x, y: y);

Set<CoordinateSetI> _rect({required final int left, required final int top, required final int right, required final int bottom})
{
  return <CoordinateSetI>{
    for (int x = left; x <= right; x++)
      for (int y = top; y <= bottom; y++) _c(x, y),
  };
}

/// The pixels of a brush stamped at every position, merged the way the
/// painters did it before [getStampedContentPoints].
List<CoordinateSetI> _unionOfStamps({required final PencilShape shape, required final int size, required final Iterable<CoordinateSetI> positions})
{
  final Set<CoordinateSetI> points = <CoordinateSetI>{};
  for (final CoordinateSetI position in positions)
  {
    points.addAll(getRoundSquareContentPoints(shape: shape, size: size, position: position));
  }
  return points.toList();
}

/// The unit edges of the outline of [coords], each written from its smaller end.
Set<String> _outlineEdges({required final Set<CoordinateSetI> coords})
{
  final Set<String> edges = <String>{};
  void add(final int x1, final int y1, final int x2, final int y2) => edges.add("$x1,$y1-$x2,$y2");
  for (final CoordinateSetI c in coords)
  {
    if (!coords.contains(_c(c.x - 1, c.y))) add(c.x, c.y, c.x, c.y + 1);
    if (!coords.contains(_c(c.x + 1, c.y))) add(c.x + 1, c.y, c.x + 1, c.y + 1);
    if (!coords.contains(_c(c.x, c.y - 1))) add(c.x, c.y, c.x + 1, c.y);
    if (!coords.contains(_c(c.x, c.y + 1))) add(c.x, c.y + 1, c.x + 1, c.y + 1);
  }
  return edges;
}

void main()
{
  group("brush pixels", () {
    test("a square brush covers its full box, one pixel further right and down when even", () {
      expect(getRoundSquareContentPoints(shape: PencilShape.square, size: 1, position: _c(4, -2)), <CoordinateSetI>{_c(4, -2)});
      expect(getRoundSquareContentPoints(shape: PencilShape.square, size: 2, position: _c(4, -2)), _rect(left: 4, top: -2, right: 5, bottom: -1));
      expect(getRoundSquareContentPoints(shape: PencilShape.square, size: 3, position: _c(4, -2)), _rect(left: 3, top: -3, right: 5, bottom: -1));
      expect(getRoundSquareContentPoints(shape: PencilShape.square, size: 4, position: _c(4, -2)), _rect(left: 3, top: -3, right: 6, bottom: 0));
    });

    test("a round brush leaves out the corners of that box", () {
      final Set<CoordinateSetI> box = _rect(left: -2, top: -2, right: 2, bottom: 2);
      final Set<CoordinateSetI> corners = <CoordinateSetI>{_c(-2, -2), _c(2, -2), _c(-2, 2), _c(2, 2)};
      expect(getRoundSquareContentPoints(shape: PencilShape.round, size: 5, position: _c(0, 0)), box.difference(corners));
    });

    test("stamping along positions gives the pixels, in order, of merging a stamp per position", () {
      final Random random = Random(7);
      for (final PencilShape shape in PencilShape.values)
      {
        for (int size = PencilConstraints.sizeMin; size <= PencilConstraints.sizeMax; size++)
        {
          final List<CoordinateSetI> positions = <CoordinateSetI>[];
          int x = random.nextInt(40) - 20;
          int y = random.nextInt(40) - 20;
          for (int i = 0; i < 30; i++)
          {
            //mostly neighbors, sometimes a repeat or a jump
            final int kind = random.nextInt(10);
            if (kind == 0)
            {
              x += random.nextInt(21) - 10;
              y += random.nextInt(21) - 10;
            }
            else if (kind > 1)
            {
              x += random.nextInt(3) - 1;
              y += random.nextInt(3) - 1;
            }
            positions.add(_c(x, y));
          }
          expect(getStampedContentPoints(shape: shape, size: size, positions: positions).toList(), _unionOfStamps(shape: shape, size: size, positions: positions),
              reason: "${shape.name} brush of size $size",);
        }
      }
    });

    test("stamping works the same far from the origin and without positions", () {
      final List<CoordinateSetI> far = <CoordinateSetI>[_c(70001, -65536), _c(70002, -65535), _c(70000, -65537)];
      for (final PencilShape shape in PencilShape.values)
      {
        expect(getStampedContentPoints(shape: shape, size: 7, positions: far).toList(), _unionOfStamps(shape: shape, size: 7, positions: far));
        expect(getStampedContentPoints(shape: shape, size: 7, positions: <CoordinateSetI>[]), isEmpty);
      }
    });

    test("stamping gives the same pixels when the stamped area is too large for a bit mask", () {
      //about 36 million pixels between the two ends
      final List<CoordinateSetI> apart = <CoordinateSetI>[_c(0, 0), _c(1, 0), _c(0, 0), _c(6000, 6000), _c(6001, 6001)];
      for (final PencilShape shape in PencilShape.values)
      {
        expect(getStampedContentPoints(shape: shape, size: 5, positions: apart).toList(), _unionOfStamps(shape: shape, size: 5, positions: apart));
      }
    });
  });

  group("lines", () {
    test("a thin line is the plain Bresenham line", () {
      expect(getLinePoints(startPos: _c(0, 0), endPos: _c(7, 3), size: 1, shape: PencilShape.round), bresenham(start: _c(0, 0), end: _c(7, 3)).toSet());
    });

    test("a wide line stamps the brush along it", () {
      expect(getLinePoints(startPos: _c(0, 0), endPos: _c(4, 0), size: 3, shape: PencilShape.square), _rect(left: -1, top: -1, right: 5, bottom: 1));
    });
  });

  group("integer ratio lines", () {
    final Set<AngleData> compass = <AngleData>{AngleData(x: 0, y: 1), AngleData(x: 1, y: 0), AngleData(x: 0, y: -1), AngleData(x: -1, y: 0)};

    test("the closest angle is found across the wrap around zero", () {
      //just left of straight down, which is closer to the angle 0 than to -pi/2
      expect(getClosestAngle(startPos: _c(0, 0), endPos: _c(-1, 100), angles: compass)!.y, 1);
      expect(getClosestAngle(startPos: _c(0, 0), endPos: _c(1, 100), angles: compass)!.y, 1);
    });

    test("the closest angle picks the nearest direction and needs angles to pick from", () {
      final AngleData closest = getClosestAngle(startPos: _c(5, 5), endPos: _c(15, 9), angles: <AngleData>{AngleData(x: 1, y: 0), AngleData(x: 2, y: 1), AngleData(x: 1, y: 1)})!;
      expect((closest.x, closest.y), (2, 1));
      expect(getClosestAngle(startPos: _c(0, 0), endPos: _c(1, 1), angles: <AngleData>{}), isNull);
    });

    test("angles are the same when their ratio is", () {
      expect(AngleData(x: 2, y: 1), AngleData(x: 4, y: 2));
      expect(AngleData(x: 2, y: 1), isNot(AngleData(x: 1, y: 2)));
      expect(AngleData(x: 2, y: 1), isNot(AngleData(x: -2, y: -1)));
    });

    test("a point snaps to the closest full multiple of the pattern", () {
      final Set<AngleData> ratio = <AngleData>{AngleData(x: 2, y: 1)};
      expect(getIntegerRatioSnappedPoint(startPos: _c(0, 0), endPos: _c(10, 4), angles: ratio), _c(10, 5));
      expect(getIntegerRatioSnappedPoint(startPos: _c(3, 3), endPos: _c(13, 7), angles: ratio), _c(13, 8));
      expect(getIntegerRatioSnappedPoint(startPos: _c(3, 3), endPos: _c(10, 4), angles: compass), _c(10, 3));
    });

    test("a line repeats the pattern and stops before overshooting", () {
      expect(
        getIntegerRatioLinePoints(startPos: _c(0, 0), endPos: _c(6, 3), size: 1, shape: PencilShape.round, angles: <AngleData>{AngleData(x: 2, y: 1)}),
        <CoordinateSetI>{_c(0, 0), _c(1, 0), _c(2, 1), _c(3, 1), _c(4, 2), _c(5, 2)},
      );
      expect(
        getIntegerRatioLinePoints(startPos: _c(0, 0), endPos: _c(-3, -6), size: 1, shape: PencilShape.round, angles: <AngleData>{AngleData(x: -1, y: -2)}),
        <CoordinateSetI>{_c(0, 0), _c(0, -1), _c(-1, -2), _c(-1, -3), _c(-2, -4), _c(-2, -5)},
      );
    });

    test("a straight line reaches the end point", () {
      expect(
        getIntegerRatioLinePoints(startPos: _c(3, 3), endPos: _c(0, 3), size: 1, shape: PencilShape.round, angles: compass),
        <CoordinateSetI>{_c(3, 3), _c(2, 3), _c(1, 3), _c(0, 3)},
      );
    });

    test("a wide line stamps the brush along the pattern", () {
      final Set<CoordinateSetI> spine = getIntegerRatioLinePoints(startPos: _c(0, 0), endPos: _c(6, 3), size: 1, shape: PencilShape.round, angles: <AngleData>{AngleData(x: 2, y: 1)});
      expect(
        getIntegerRatioLinePoints(startPos: _c(0, 0), endPos: _c(6, 3), size: 3, shape: PencilShape.square, angles: <AngleData>{AngleData(x: 2, y: 1)}).toList(),
        _unionOfStamps(shape: PencilShape.square, size: 3, positions: spine),
      );
    });
  });

  group("boundary path", () {
    test("nothing has no boundary, and a pixel its four corners", () {
      expect(getBoundaryPath(coords: <CoordinateSetI>{}), isEmpty);
      expect(getBoundaryPath(coords: <CoordinateSetI>{_c(4, -2)}), <CoordinateSetI>[_c(4, -2), _c(5, -2), _c(5, -1), _c(4, -1)]);
    });

    test("walks once along every edge of every brush and comes back to the start", () {
      for (final PencilShape shape in PencilShape.values)
      {
        for (int size = PencilConstraints.sizeMin; size <= PencilConstraints.sizeMax; size++)
        {
          final Set<CoordinateSetI> brush = getRoundSquareContentPoints(shape: shape, size: size, position: _c(3, -5));
          final List<CoordinateSetI> path = getBoundaryPath(coords: brush);
          final List<String> walked = <String>[];
          for (int i = 0; i < path.length; i++)
          {
            final CoordinateSetI a = path[i];
            final CoordinateSetI b = path[(i + 1) % path.length];
            if (a == b) //closing a path whose last point repeats its first
            {
              continue;
            }
            final bool ordered = a.x < b.x || (a.x == b.x && a.y < b.y);
            walked.add(ordered ? "${a.x},${a.y}-${b.x},${b.y}" : "${b.x},${b.y}-${a.x},${a.y}");
          }
          expect(walked.toSet(), _outlineEdges(coords: brush), reason: "${shape.name} brush of size $size");
          expect(walked.length, walked.toSet().length, reason: "${shape.name} brush of size $size");
        }
      }
    });
  });

  test("the closest pixel is the one a position falls into", () {
    expect(getClosestPixel(value: 0, pixelSize: 4), 0);
    expect(getClosestPixel(value: 3.9, pixelSize: 4), 0);
    expect(getClosestPixel(value: 4, pixelSize: 4), 1);
    expect(getClosestPixel(value: -0.5, pixelSize: 4), -1);
    expect(getClosestPixel(value: 1.25, pixelSize: 0.5), 2);
  });

  group("mirroring", () {
    final CoordinateSetI canvas = _c(8, 6);

    test("without an axis nothing is added", () {
      final Set<CoordinateSetI> coords = <CoordinateSetI>{_c(1, 2)};
      expect(getMirrorPoints(coords: coords, canvasSize: canvas, symmetryX: null, symmetryY: null), coords);
    });

    test("each axis adds the pixel across it, and both axes also the opposite one", () {
      final Set<CoordinateSetI> coords = <CoordinateSetI>{_c(1, 2)};
      expect(getMirrorPoints(coords: coords, canvasSize: canvas, symmetryX: 4, symmetryY: null), <CoordinateSetI>{_c(1, 2), _c(6, 2)});
      expect(getMirrorPoints(coords: coords, canvasSize: canvas, symmetryX: null, symmetryY: 3), <CoordinateSetI>{_c(1, 2), _c(1, 3)});
      expect(getMirrorPoints(coords: coords, canvasSize: canvas, symmetryX: 4, symmetryY: 3), <CoordinateSetI>{_c(1, 2), _c(6, 2), _c(1, 3), _c(6, 3)});
    });

    test("an axis between pixels mirrors around the pixel edge", () {
      expect(getMirrorPoints(coords: <CoordinateSetI>{_c(1, 2)}, canvasSize: canvas, symmetryX: 3.5, symmetryY: null), <CoordinateSetI>{_c(1, 2), _c(5, 2)});
    });

    test("mirrored pixels off the canvas are dropped, the originals are not", () {
      final Set<CoordinateSetI> coords = <CoordinateSetI>{_c(5, 2), _c(9, 2)};
      expect(getMirrorPoints(coords: coords, canvasSize: canvas, symmetryX: 1, symmetryY: null), coords);
      //the x image lands on the canvas, the y and opposite images do not
      expect(getMirrorPoints(coords: <CoordinateSetI>{_c(5, 2)}, canvasSize: canvas, symmetryX: 6, symmetryY: 1), <CoordinateSetI>{_c(5, 2), _c(6, 2)});
    });

    test("a stamp mirrors like plain pixels and keeps its values", () {
      final HashMap<CoordinateSetI, int> stamp = HashMap<CoordinateSetI, int>()..[_c(1, 2)] = 3..[_c(2, 0)] = 5;
      final HashMap<CoordinateSetI, int> mirrored = getStampMirrorPoints(stampData: stamp, canvasSize: canvas, symmetryX: 4, symmetryY: 3);
      expect(mirrored.keys.toSet(), getMirrorPoints(coords: stamp.keys.toSet(), canvasSize: canvas, symmetryX: 4, symmetryY: 3));
      expect(mirrored[_c(6, 2)], 3);
      expect(mirrored[_c(1, 3)], 3);
      expect(mirrored[_c(6, 3)], 3);
      expect(mirrored[_c(5, 5)], 5);
    });

    test("a stamp without an axis stays as it is, and drops what lands off the canvas", () {
      final HashMap<CoordinateSetI, int> stamp = HashMap<CoordinateSetI, int>()..[_c(5, 2)] = 3;
      expect(getStampMirrorPoints(stampData: stamp, canvasSize: canvas, symmetryX: null, symmetryY: null), stamp);
      expect(getStampMirrorPoints(stampData: stamp, canvasSize: canvas, symmetryX: 1, symmetryY: null), stamp);
    });
  });
}
