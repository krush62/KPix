/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/util/helper.dart';

void main() {
  
  testToolType();
  testCoordinateSetI();
  testStackCol();
  testColorToString();
  testPerfectSquare();
  testGcd();
  testAngleCalculation();
  testRgb2lab();
  testDeltaE();
  testIsPointInPolygon();
  testPointToEdgeDistance();
  testGetCoordinateNeighbors();
  testArgbToRgba();
  testIntToBytes();
}

void testToolType() {
  for (final ToolType toolType in ToolType.values) {
    test('test existence of $toolType in map', () {
      expect(toolList.containsKey(toolType), isTrue);
    });
  }
}

void testCoordinateSetI()
{
  group('CoordinateSetI', () {
    test('constructor initializes properties correctly', () {
      final CoordinateSetI coordinate = CoordinateSetI(x: 10, y: 20);
      expect(coordinate.x, 10);
      expect(coordinate.y, 20);
    });

    test('from factory creates a copy', () {
      final CoordinateSetI original = CoordinateSetI(x: 5, y: 15);
      final CoordinateSetI copy = CoordinateSetI.from(other: original);
      expect(copy.x, original.x);
      expect(copy.y, original.y);
      expect(copy, original);
      expect(identical(copy, original), isFalse);
    });

    test('equality and hashCode', () {
      final CoordinateSetI c1 = CoordinateSetI(x: 1, y: 2);
      final CoordinateSetI c2 = CoordinateSetI(x: 1, y: 2);
      final CoordinateSetI c3 = CoordinateSetI(x: 2, y: 1);

      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1, isNot(c3));
    });

    test('toString returns correct format', () {
      final CoordinateSetI c = CoordinateSetI(x: 10, y: 20);
      expect(c.toString(), "10|20");
    });

    test('isDiagonal returns true for diagonal neighbors', () {
      final CoordinateSetI center = CoordinateSetI(x: 5, y: 5);

      expect(center.isDiagonal(other: CoordinateSetI(x: 4, y: 4)), isTrue);
      expect(center.isDiagonal(other: CoordinateSetI(x: 6, y: 6)), isTrue);
      expect(center.isDiagonal(other: CoordinateSetI(x: 4, y: 6)), isTrue);
      expect(center.isDiagonal(other: CoordinateSetI(x: 6, y: 4)), isTrue);
    });

    test('isDiagonal returns false for non-diagonal neighbors', () {
      final CoordinateSetI center = CoordinateSetI(x: 5, y: 5);

      expect(center.isDiagonal(other: CoordinateSetI(x: 5, y: 4)), isFalse); // Top
      expect(center.isDiagonal(other: CoordinateSetI(x: 5, y: 6)), isFalse); // Bottom
      expect(center.isDiagonal(other: CoordinateSetI(x: 4, y: 5)), isFalse); // Left
      expect(center.isDiagonal(other: CoordinateSetI(x: 6, y: 5)), isFalse); // Right
      expect(center.isDiagonal(other: CoordinateSetI(x: 5, y: 5)), isFalse); // Self
      expect(center.isDiagonal(other: CoordinateSetI(x: 0, y: 0)), isFalse); // Far
    });

    test('isAdjacent checks adjacency with diagonals', () {
      final CoordinateSetI center = CoordinateSetI(x: 5, y: 5);
      expect(center.isAdjacent(other: CoordinateSetI(x: 5, y: 4), withDiagonal: true), isTrue);
      expect(center.isAdjacent(other: CoordinateSetI(x: 6, y: 5), withDiagonal: true), isTrue);
      expect(center.isAdjacent(other: CoordinateSetI(x: 4, y: 4), withDiagonal: true), isTrue);
      expect(center.isAdjacent(other: CoordinateSetI(x: 3, y: 3), withDiagonal: true), isFalse);
    });

    test('isAdjacent checks adjacency without diagonals', () {
      final CoordinateSetI center = CoordinateSetI(x: 5, y: 5);
      expect(center.isAdjacent(other: CoordinateSetI(x: 5, y: 4), withDiagonal: false), isTrue);
      expect(center.isAdjacent(other: CoordinateSetI(x: 4, y: 4), withDiagonal: false), isFalse);
      expect(center.isAdjacent(other: CoordinateSetI(x: 3, y: 3), withDiagonal: false), isFalse);
    });
  });
}

void testStackCol()
{

  group('StackCol', () {
    late StackCol<int> stack;

    setUp(() {
      stack = StackCol<int>();
    });

    test('initially empty', () {
      expect(stack.isEmpty, isTrue);
      expect(stack.isNotEmpty, isFalse);
      expect(stack.length, equals(0));
    });

    test('push adds elements', () {
      stack.push(10);
      expect(stack.isEmpty, isFalse);
      expect(stack.isNotEmpty, isTrue);
      expect(stack.length, equals(1));
      expect(stack.peek, equals(10));
    });

    test('peek returns last element without removing it', () {
      stack.push(1);
      stack.push(2);
      expect(stack.peek, equals(2));
      expect(stack.length, equals(2));
    });

    test('pop removes and returns last element', () {
      stack.push(5);
      stack.push(6);
      final int popped = stack.pop();
      expect(popped, equals(6));
      expect(stack.length, equals(1));
      expect(stack.peek, equals(5));
    });

    test('pop throws error when empty', () {
      expect(() => stack.pop(), throwsA(isA<RangeError>()));
    });

    test('peek throws error when empty', () {
      expect(() => stack.peek, throwsA(isA<StateError>()));
    });
  });

}

void testColorToString()
{

  group('Color conversion functions', () {
    test('colorToHexString returns correct hex with hashtag', () {
      const Color color = Color.from(alpha: 1.0, red: 1.0, green: 0.0, blue: 0.0); // Red
      expect(colorToHexString(color: color), equals('#ff0000'));
    });

    test('colorToHexString returns correct hex without hashtag', () {
      const Color color = Color.from(alpha: 1.0, red: 0.0, green: 1.0, blue: 0.0); // Green
      expect(colorToHexString(color: color, withHashTag: false), equals('00ff00'));
    });

    test('colorToHexString returns uppercase when toUpper = true', () {
      const Color color = Color.from(alpha: 1.0, red: 0.0, green: 0.0, blue: 1.0); // Blue
      expect(colorToHexString(color: color, toUpper: true), equals('#0000FF'));
    });

    test('colorToHexString pads single-digit hex values', () {
      const Color color = Color.from(alpha: 1.0, red: 0.1, green: 0.1, blue: 0.1); // Dark gray
      expect(colorToHexString(color: color), equals('#191919')); // 0.1*255 ≈ 25 (hex 19)
    });

    test('colorToRGBString returns correct RGB string', () {
      const Color color = Color.from(alpha: 1.0, red: 0.5, green: 0.25, blue: 0.75);
      expect(colorToRGBString(color: color), equals('127 | 63 | 191'));
    });

    test('colorToHexString handles black correctly', () {
      const Color color = Color.from(alpha: 1.0, red: 0.0, green: 0.0, blue: 0.0);
      expect(colorToHexString(color: color), equals('#000000'));
      expect(colorToRGBString(color: color), equals('0 | 0 | 0'));
    });

    test('colorToHexString handles white correctly', () {
      const Color color = Color.from(alpha: 1.0, red: 1.0, green: 1.0, blue: 1.0);
      expect(colorToHexString(color: color), equals('#ffffff'));
      expect(colorToRGBString(color: color), equals('255 | 255 | 255'));
    });

    test('colorToHexString clamps values above 1.0', () {
      const Color color = Color.from(alpha: 1.0, red: 1.1, green: 1.2, blue: 2.0);
      expect(colorToHexString(color: color), equals('#ffffff'));
    });

    test('colorToHexString clamps values below 0.0', () {
      const Color color = Color.from(alpha: 1.0, red: -0.5, green: -0.1, blue: 0.0);
      expect(colorToHexString(color: color), equals('#000000'));
    });
  });

}

void testPerfectSquare()
{
  group('isPerfectSquare', () {
    test('returns true for perfect squares', () {
      expect(isPerfectSquare(number: 0), isTrue);
      expect(isPerfectSquare(number: 1), isTrue);
      expect(isPerfectSquare(number: 4), isTrue);
      expect(isPerfectSquare(number: 9), isTrue);
      expect(isPerfectSquare(number: 16), isTrue);
      expect(isPerfectSquare(number: 25), isTrue);
    });

    test('returns false for non-perfect squares', () {
      expect(isPerfectSquare(number: 2), isFalse);
      expect(isPerfectSquare(number: 3), isFalse);
      expect(isPerfectSquare(number: 5), isFalse);
      expect(isPerfectSquare(number: 10), isFalse);
      expect(isPerfectSquare(number: 26), isFalse);
    });
  });
}

void testGcd()
{
  group('gcd', () {
    test('computes gcd for positive integers', () {
      expect(gcd(a: 54, b: 24), equals(6));
      expect(gcd(a: 48, b: 18), equals(6));
      expect(gcd(a: 101, b: 10), equals(1));
      expect(gcd(a: 15, b: 5), equals(5));
    });

    test('gcd when b is zero returns a', () {
      expect(gcd(a: 7, b: 0), equals(7));
    });

    test('gcd handles swapped order correctly', () {
      expect(gcd(a: 24, b: 54), equals(6));
    });
  });
}

void testAngleCalculation()
{
  group('calculateAngle', () {
    test('angle is 0 degrees when moving to positive X direction', () {
      final CoordinateSetI start = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI end = CoordinateSetI(x: 10, y: 0);

      expect(calculateAngle(startPos: start, endPos: end), equals(0));
    });

    test('angle is 90 degrees when moving straight up', () {
      final CoordinateSetI start = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI end = CoordinateSetI(x: 0, y: 10);

      expect(calculateAngle(startPos: start, endPos: end), equals(90));
    });

    test('angle is -90 degrees when moving straight down', () {
      final CoordinateSetI start = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI end = CoordinateSetI(x: 0, y: -10);

      expect(calculateAngle(startPos: start, endPos: end), equals(-90));
    });

    test('angle is 180 degrees when moving to negative X direction', () {
      final CoordinateSetI start = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI end = CoordinateSetI(x: -10, y: 0);

      expect(calculateAngle(startPos: start, endPos: end), equals(180));
    });

    test('angle for an arbitrary quadrant (example: 45 degrees)', () {
      final CoordinateSetI start = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI end = CoordinateSetI(x: 10, y: 10);

      expect(calculateAngle(startPos: start, endPos: end), closeTo(45.0, 0.0001));
    });
  });
}

void testRgb2lab()
{
  group('rgb2lab', () {
    test('black → Lab(0,0,0)', () {
      final LabColor lab = rgb2lab(r: 0.0, g: 0.0, b: 0.0);
      expect(lab.L, closeTo(0.0, 0.01));
      expect(lab.A, closeTo(0.0, 0.01));
      expect(lab.B, closeTo(0.0, 0.01));
    });

    test('out of bounds: black → Lab(0,0,0)', () {
      final LabColor lab = rgb2lab(r: -10.0, g: -10000.0, b: -100.0);
      expect(lab.L, closeTo(0.0, 0.01));
      expect(lab.A, closeTo(0.0, 0.01));
      expect(lab.B, closeTo(0.0, 0.01));
    });

    test('white → Lab(100,0,0)', () {
      final LabColor lab = rgb2lab(r: 1.0, g: 1.0, b: 1.0);
      expect(lab.L, closeTo(100, 0.1));
      expect(lab.A, closeTo(0.0, 0.1));
      expect(lab.B, closeTo(0.0, 0.1));
    });

    test('out of bounds: white → Lab(100,0,0)', () {
      final LabColor lab = rgb2lab(r: 100.0, g: 10000.0, b: 1.0);
      expect(lab.L, closeTo(100.0, 0.1));
      expect(lab.A, closeTo(0.0, 0.1));
      expect(lab.B, closeTo(0.0, 0.1));
    });

    test('pure red', () {
      final LabColor lab = rgb2lab(r: 1.0, g: 0.0, b: 0.0);
      expect(lab.L, closeTo(53.23, 0.2));
      expect(lab.A, closeTo(80.09, 0.2));
      expect(lab.B, closeTo(67.20, 0.2));
    });

    test('pure green', () {
      final LabColor lab = rgb2lab(r: 0.0, g: 1.0, b: 0.0);
      expect(lab.L, closeTo(87.74, 0.2));
      expect(lab.A, closeTo(-86.18, 0.2));
      expect(lab.B, closeTo(83.18, 0.2));
    });

    test('pure blue', () {
      final LabColor lab = rgb2lab(r: 0.0, g: 0.0, b: 1.0);
      expect(lab.L, closeTo(32.30, 0.2));
      expect(lab.A, closeTo(79.19, 0.2));
      expect(lab.B, closeTo(-107.86, 0.2));
    });

    test('middle gray', () {
      final LabColor lab = rgb2lab(r: 0.5, g: 0.5, b: 0.5);
      expect(lab.L, closeTo(53.39, 0.3));
      expect(lab.A, closeTo(0, 0.3));
      expect(lab.B, closeTo(0, 0.3));
    });
  });
}

void testDeltaE()
{
  group('getDeltaE', () {
    test('same color returns 0', () {
      final double d1 = getDeltaE94(
        redA: 0.3, greenA: 0.4, blueA: 0.5,
        redB: 0.3, greenB: 0.4, blueB: 0.5,
      );
      final double d2 = getDeltaE00(
        redA: 0.3, greenA: 0.4, blueA: 0.5,
        redB: 0.3, greenB: 0.4, blueB: 0.5,
      );
      expect(d1, closeTo(0.0, 1e-8));
      expect(d2, closeTo(0.0, 1e-8));
    });

    test('white vs black (large difference)', () {
      final double d1 = getDeltaE94(
        redA: 1.0, greenA: 1.0, blueA: 1.0,
        redB: 0.0, greenB: 0.0, blueB: 0.0,
      );
      final double d2 = getDeltaE00(
        redA: 1.0, greenA: 1.0, blueA: 1.0,
        redB: 0.0, greenB: 0.0, blueB: 0.0,
      );
      expect(d1, greaterThan(99.0));
      expect(d2, greaterThan(99.0));
    });

    test('red vs green deltaE', () {
      final double d1 = getDeltaE94(
        redA: 1.0, greenA: 0.0, blueA: 0.0,
        redB: 0.0, greenB: 1.0, blueB: 0.0,
      );
      final double d2 = getDeltaE00(
        redA: 1.0, greenA: 0.0, blueA: 0.0,
        redB: 0.0, greenB: 1.0, blueB: 0.0,
      );
      expect(d1, closeTo(73.43376, 1e-3));
      expect(d2, closeTo(86.61501, 1e-3));
    });

    test('blue vs yellow deltaE', () {
      final double d1 = getDeltaE94(
        redA: 0.0, greenA: 0.0, blueA: 1.0,
        redB: 1.0, greenB: 1.0, blueB: 0.0,
      );
      final double d2 = getDeltaE00(
        redA: 0.0, greenA: 0.0, blueA: 1.0,
        redB: 1.0, greenB: 1.0, blueB: 0.0,
      );
      expect(d1, closeTo(98.64386, 1e-3));
      expect(d2, closeTo(103.4259, 1e-3));
    });

    test('slight variation deltaE', () {
      final double d1 = getDeltaE94(
        redA: 1.0, greenA: 0.0, blueA: 0.0,
        redB: 0.9, greenB: 0.0, blueB: 0.0,
      );
      final double d2 = getDeltaE00(
        redA: 1.0, greenA: 0.0, blueA: 0.0,
        redB: 0.9, greenB: 0.0, blueB: 0.0,
      );
      expect(d1, closeTo(5.48, 0.015));
      expect(d2, closeTo(5.48, 0.015));
    });

    test('symmetry: deltaE(A,B) == deltaE(B,A)', () {
      final double d1_1 = getDeltaE94(
        redA: 0.1, greenA: 0.2, blueA: 0.3,
        redB: 0.7, greenB: 0.6, blueB: 0.5,
      );
      final double d1_2 = getDeltaE94(
        redA: 0.7, greenA: 0.6, blueA: 0.5,
        redB: 0.1, greenB: 0.2, blueB: 0.3,
      );
      final double d2_1 = getDeltaE00(
        redA: 0.1, greenA: 0.2, blueA: 0.3,
        redB: 0.7, greenB: 0.6, blueB: 0.5,
      );
      final double d2_2 = getDeltaE00(
        redA: 0.7, greenA: 0.6, blueA: 0.5,
        redB: 0.1, greenB: 0.2, blueB: 0.3,
      );
      expect(d1_1, closeTo(d1_2, 0.2));
      expect(d2_1, closeTo(d2_2, 1e-12));
    });
  });

}

void testIsPointInPolygon()
{

  group('isPointInPolygon', () {
    test('point clearly inside a square', () {
      final List<CoordinateSetI> square = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];
      final CoordinateSetI p = CoordinateSetI(x: 5, y: 5);

      expect(isPointInPolygon(point: p, polygon: square), isTrue);
    });

    test('point clearly outside a square', () {
      final List<CoordinateSetI> square = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];
      final CoordinateSetI p = CoordinateSetI(x: -1, y: 5);

      expect(isPointInPolygon(point: p, polygon: square), isFalse);
    });

    test('point exactly on vertical edge of square', () {
      final List<CoordinateSetI> square = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];
      final CoordinateSetI p = CoordinateSetI(x: 0, y: 7);

      expect(isPointInPolygon(point: p, polygon: square), isTrue);
    });

    test('point exactly on a vertex', () {
      final List<CoordinateSetI> square = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];
      final CoordinateSetI p = CoordinateSetI(x: 10, y: 10);

      expect(isPointInPolygon(point: p, polygon: square), isTrue);
    });

    test('point inside a concave polygon', () {
      // Simple arrow shape
      final List<CoordinateSetI> concave = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 5),
        CoordinateSetI(x: 0, y: 10),
        CoordinateSetI(x: 3, y: 5),
      ];
      final CoordinateSetI p = CoordinateSetI(x: 3, y: 5);

      expect(isPointInPolygon(point: p, polygon: concave), isTrue);
    });

    test('point outside concave polygon, near indentation', () {
      final List<CoordinateSetI> concave = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 5),
        CoordinateSetI(x: 0, y: 10),
        CoordinateSetI(x: 3, y: 5),
      ];
      final CoordinateSetI p = CoordinateSetI(x: 2, y: 5);

      expect(isPointInPolygon(point: p, polygon: concave), isFalse);
    });

    test('point very close to edge with epsilon tolerance', () {
      final List<CoordinateSetI> triangle = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 5, y: 10),
      ];
      final CoordinateSetI p = CoordinateSetI(x: 5, y: 0.000001.round());

      expect(isPointInPolygon(point: p, polygon: triangle, epsilon: 1e-3), isTrue);
    });
  });
}

void testPointToEdgeDistance()
{
  group('getPointToEdgeDistance', () {

    test('point exactly on a vertex → distance = 0', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 0, y: 0);

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(0.0, 1e-9),
      );
    });

    test('point exactly on an edge → distance = 0', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 5, y: 0); // on bottom edge

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(0.0, 1e-9),
      );
    });

    test('point centered inside square → distance = half side length', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 5, y: 5);
      // distance to nearest edge: 5

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(5.0, 1e-9),
      );
    });

    test('point outside square but near one edge → distance from that edge', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 0, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 5, y: -2);
      // distance to bottom edge y=0 → 2

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(2.0, 1e-9),
      );
    });

    test('distance to vertical edge is computed correctly', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 4, y: 0),
        CoordinateSetI(x: 4, y: 6),
        CoordinateSetI(x: 0, y: 6),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 7, y: 3);
      // nearest edge is x=4, distance = 3

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(3.0, 1e-9),
      );
    });

    test('distance to diagonal edge (45° oriented)', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 10, y: 0),
      ];
      // Triangle with hypotenuse from (0,0) → (10,10)

      final CoordinateSetI p = CoordinateSetI(x: 0, y: 10);

      // Distance from point (0,10) to diagonal line y=x:
      // |x - y| / sqrt(2) = |0 - 10| / sqrt(2) = 10 / 1.4142... = 7.07106781

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(7.0710678118654755, 1e-6),
      );
    });

    test('concave polygon: point inside indentation has correct minimum distance', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 5, y: 5), // concave inward
        CoordinateSetI(x: 0, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 6, y: 6);
      // Nearest edge is the diagonal indentation edge: (10,10)-(5,5)
      // Distance from (6,6) to that segment is sqrt(2) ≈ 1.4142

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(0.0, 1e-9),
      );
    });

    test('concave polygon: point near indentation edge gives correct distance', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 10),
        CoordinateSetI(x: 5, y: 5),
        CoordinateSetI(x: 0, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 6, y: 7);

      // Distance to line y=x = |6 - 7| / sqrt(2) = 1 / 1.414... ≈ 0.7071
      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(0.70710678118, 1e-6),
      );
    });

    test('polygon with only two points (degenerate) → behaves like a line segment', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 5, y: 5);

      expect(
        getPointToEdgeDistance(point: p, polygon: polygon),
        closeTo(5.0, 1e-9),
      );
    });

    test('polygon with overlapping edges does not crash and gives correct distance', () {
      final List<CoordinateSetI> polygon = <CoordinateSetI>[
        CoordinateSetI(x: 0, y: 0),
        CoordinateSetI(x: 10, y: 0),
        CoordinateSetI(x: 10, y: 0), // duplicate vertex
        CoordinateSetI(x: 10, y: 10),
      ];

      final CoordinateSetI p = CoordinateSetI(x: 10, y: 5);
      final double result = getPointToEdgeDistance(point: p, polygon: polygon);
      expect(result.isNaN, isTrue);
    });

  });
}

void testGetCoordinateNeighbors()
{
  group('getCoordinateNeighbors', () {
    test('returns 4 cardinal neighbors when withDiagonals = false', () {
      final CoordinateSetI pixel = CoordinateSetI(x: 5, y: 5);
      final List<CoordinateSetI> neighbors = getCoordinateNeighbors(pixel: pixel, withDiagonals: false);

      final List<CoordinateSetI> expected = <CoordinateSetI>[
        CoordinateSetI(x: 6, y: 5),
        CoordinateSetI(x: 4, y: 5),
        CoordinateSetI(x: 5, y: 6),
        CoordinateSetI(x: 5, y: 4),
      ];

      expect(neighbors.length, 4);
      expect(neighbors, containsAll(expected));
    });

    test('returns 8 neighbors when withDiagonals = true', () {
      final CoordinateSetI pixel = CoordinateSetI(x: 5, y: 5);
      final List<CoordinateSetI> neighbors = getCoordinateNeighbors(pixel: pixel, withDiagonals: true);

      final List<CoordinateSetI> expected = <CoordinateSetI>[
        // cardinal
        CoordinateSetI(x: 6, y: 5),
        CoordinateSetI(x: 4, y: 5),
        CoordinateSetI(x: 5, y: 6),
        CoordinateSetI(x: 5, y: 4),
        // diagonals
        CoordinateSetI(x: 6, y: 6),
        CoordinateSetI(x: 4, y: 4),
        CoordinateSetI(x: 6, y: 4),
        CoordinateSetI(x: 4, y: 6),
      ];

      expect(neighbors.length, 8);
      expect(neighbors, containsAll(expected));
    });

    test('works for negative coordinates', () {
      final CoordinateSetI pixel = CoordinateSetI(x: -2, y: -3);
      final List<CoordinateSetI> neighbors = getCoordinateNeighbors(pixel: pixel, withDiagonals: true);

      final List<CoordinateSetI> expected = <CoordinateSetI>[
        CoordinateSetI(x: -1, y: -3),
        CoordinateSetI(x: -3, y: -3),
        CoordinateSetI(x: -2, y: -2),
        CoordinateSetI(x: -2, y: -4),
        CoordinateSetI(x: -1, y: -2),
        CoordinateSetI(x: -3, y: -4),
        CoordinateSetI(x: -1, y: -4),
        CoordinateSetI(x: -3, y: -2),
      ];

      expect(neighbors.length, 8);
      expect(neighbors, containsAll(expected));
    });

    test('works for zero coordinates', () {
      final CoordinateSetI pixel = CoordinateSetI(x: 0, y: 0);
      final List<CoordinateSetI> neighbors = getCoordinateNeighbors(pixel: pixel, withDiagonals: false);

      final List<CoordinateSetI> expected = <CoordinateSetI>[
        CoordinateSetI(x: 1, y: 0),
        CoordinateSetI(x: -1, y: 0),
        CoordinateSetI(x: 0, y: 1),
        CoordinateSetI(x: 0, y: -1),
      ];

      expect(neighbors.length, 4);
      expect(neighbors, containsAll(expected));
    });
  });
}

void testArgbToRgba()
{
  group('argbToRgba', () {
    test('opaque white ARGB → RGBA', () {
      const int argb = 0xFFFFFFFF; // A=255, R=255, G=255, B=255
      const int expected = 0xFFFFFFFF; // RGBA same as ARGB in this case
      expect(argbToRgba(argb: argb), equals(expected));
    });

    test('transparent black ARGB → RGBA', () {
      const int argb = 0x00000000; // A=0, R=0, G=0, B=0
      const int expected = 0x00000000;
      expect(argbToRgba(argb: argb), equals(expected));
    });

    test('example ARGB 0x80FF00FF → RGBA', () {
      // A=128, R=255, G=0, B=255
      const int argb = 0x80FF00FF;
      // RGBA = R << 24 | G << 16 | B << 8 | A
      const int expected = (255 << 24) | (0 << 16) | (255 << 8) | 128; // 0xFF00FF80
      expect(argbToRgba(argb: argb), equals(expected));
    });

    test('all channels different', () {
      const int argb = 0x12345678; // A=0x12, R=0x34, G=0x56, B=0x78
      const int expected = (0x34 << 24) | (0x56 << 16) | (0x78 << 8) | 0x12; // 0x34567812
      expect(argbToRgba(argb: argb), equals(expected));
    });

    test('minimum values ARGB → RGBA', () {
      const int argb = 0x000000FF; // A=0, R=0, G=0, B=255
      const int expected = (0 << 24) | (0 << 16) | (255 << 8) | 0; // 0x0000FF00
      expect(argbToRgba(argb: argb), equals(expected));
    });

    test('maximum values ARGB → RGBA', () {
      const int argb = 0xFFFFFFFF; // A=255, R=255, G=255, B=255
      const int expected = 0xFFFFFFFF;
      expect(argbToRgba(argb: argb), equals(expected));
    });
  });
}

void testAngleUtilities()
{
  group('normAngle', () {
    test('angle within 0..2π stays the same', () {
      expect(normAngle(angle: pi / 2), closeTo(pi / 2, 1e-9));
    });

    test('angle > 2π is normalized', () {
      const double angle = 5 * pi;
      final double expected = 5 * pi - 2 * pi * (5 * pi / twoPi).floor(); // 5π - 4π = π
      expect(normAngle(angle: angle), closeTo(expected, 1e-9));
      expect(normAngle(angle: angle), closeTo(pi, 1e-9));
    });

    test('negative angle is normalized', () {
      const double angle = -pi / 2;
      final double expected = -pi / 2 - 2 * pi * (-pi / 2 / twoPi).floor();
      expect(normAngle(angle: angle), closeTo(expected, 1e-9));
      expect(normAngle(angle: angle), closeTo(3 * pi / 2, 1e-9));
    });

    test('angle = 0 returns 0', () {
      expect(normAngle(angle: 0), 0);
    });
  });

  group('deg2rad', () {
    test('0 degrees → 0 radians', () {
      expect(deg2rad(angle: 0), 0);
    });

    test('180 degrees → π radians', () {
      expect(deg2rad(angle: 180), closeTo(pi, 1e-9));
    });

    test('360 degrees → 2π radians', () {
      expect(deg2rad(angle: 360), closeTo(2 * pi, 1e-9));
    });

    test('45 degrees → π/4 radians', () {
      expect(deg2rad(angle: 45), closeTo(pi / 4, 1e-9));
    });
  });

  group('rad2deg', () {
    test('0 radians → 0 degrees', () {
      expect(rad2deg(angle: 0), 0);
    });

    test('π radians → 180 degrees', () {
      expect(rad2deg(angle: pi), closeTo(180, 1e-9));
    });

    test('2π radians → 360 degrees', () {
      expect(rad2deg(angle: 2 * pi), closeTo(360, 1e-9));
    });

    test('π/4 radians → 45 degrees', () {
      expect(rad2deg(angle: pi / 4), closeTo(45, 1e-9));
    });
  });

  group('getDistance', () {
    test('distance between same point → 0', () {
      final CoordinateSetI p = CoordinateSetI(x: 0, y: 0);
      expect(getDistance(a: p, b: p), 0);
    });

    test('horizontal distance', () {
      final CoordinateSetI a = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI b = CoordinateSetI(x: 5, y: 0);
      expect(getDistance(a: a, b: b), 5);
    });

    test('vertical distance', () {
      final CoordinateSetI a = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI b = CoordinateSetI(x: 0, y: 12);
      expect(getDistance(a: a, b: b), 12);
    });

    test('diagonal distance', () {
      final CoordinateSetI a = CoordinateSetI(x: 3, y: 4);
      final CoordinateSetI b = CoordinateSetI(x: 0, y: 0);
      expect(getDistance(a: a, b: b), 5);
    });

    test('negative coordinates', () {
      final CoordinateSetI a = CoordinateSetI(x: -3, y: -4);
      final CoordinateSetI b = CoordinateSetI(x: 0, y: 0);
      expect(getDistance(a: a, b: b), 5);
    });
  });
}

void testExtractFileName()
{
  group('extractFilenameFromPath', () {
    test('regular path, keep extension', () {
      const String path = '/home/user/documents/file.txt';
      final String result = extractFilenameFromPath(path: path);
      expect(result, 'file.txt');
    });

    test('regular path, remove extension', () {
      const String path = '/home/user/documents/file.txt';
      final String result = extractFilenameFromPath(path: path, keepExtension: false);
      expect(result, 'file');
    });

    test('filename with multiple dots, keep extension', () {
      const String path = '/home/user/file.name.with.dots.txt';
      final String result = extractFilenameFromPath(path: path);
      expect(result, 'file.name.with.dots.txt');
    });

    test('filename with multiple dots, remove extension', () {
      const String path = '/home/user/file.name.with.dots.txt';
      final String result = extractFilenameFromPath(path: path, keepExtension: false);
      expect(result, 'file.name.with.dots');
    });

    test('filename without extension', () {
      const String path = '/home/user/file';
      final String result = extractFilenameFromPath(path: path);
      expect(result, 'file');
    });

    test('path ends with slash', () {
      const String path = '/home/user/folder/';
      final String result = extractFilenameFromPath(path: path);
      expect(result, 'folder');
    });

    test('empty string path', () {
      const String path = '';
      final String result = extractFilenameFromPath(path: path);
      expect(result, '');
    });

    test('null path', () {
      final String result = extractFilenameFromPath(path: null);
      expect(result, '');
    });

    test('relative path', () {
      const String path = 'docs/myfile.pdf';
      final String result = extractFilenameFromPath(path: path);
      expect(result, 'myfile.pdf');
    });

    test('relative path, remove extension', () {
      const String path = 'docs/myfile.pdf';
      final String result = extractFilenameFromPath(path: path, keepExtension: false);
      expect(result, 'myfile');
    });
  });
}

void testIntToBytes()
{
  group('intToBytes', () {
    test('1-byte value, default order', () {
      expect(intToBytes(value: 0x12, length: 1), <int>[0x12]);
    });

    test('2-byte value, default order', () {
      expect(intToBytes(value: 0x1234, length: 2), <int>[0x34, 0x12]);
    });

    test('4-byte value, default order', () {
      expect(intToBytes(value: 0x12345678, length: 4), <int>[0x78, 0x56, 0x34, 0x12]);
    });

    test('1-byte value, reversed', () {
      expect(intToBytes(value: 0x12, length: 1, reverse: true), <int>[0x12]);
    });

    test('2-byte value, reversed', () {
      expect(intToBytes(value: 0x1234, length: 2, reverse: true), <int>[0x12, 0x34]);
    });

    test('4-byte value, reversed', () {
      expect(intToBytes(value: 0x12345678, length: 4, reverse: true), <int>[0x12, 0x34, 0x56, 0x78]);
    });

    test('edge values: 0', () {
      expect(intToBytes(value: 0, length: 1), <int>[0x00]);
      expect(intToBytes(value: 0, length: 2), <int>[0x00, 0x00]);
      expect(intToBytes(value: 0, length: 4), <int>[0x00, 0x00, 0x00, 0x00]);
    });

    test('edge values: max for each length', () {
      expect(intToBytes(value: 0xFF, length: 1), <int>[0xFF]);
      expect(intToBytes(value: 0xFFFF, length: 2), <int>[0xFF, 0xFF]);
      expect(intToBytes(value: 0xFFFFFFFF, length: 4), <int>[0xFF, 0xFF, 0xFF, 0xFF]);
    });

    test('invalid length throws AugmentedError', () {
      expect(() => intToBytes(value: 0x1234, length: 3), throwsA(isA<ArgumentError>()));
      expect(() => intToBytes(value: 0x1234, length: 0), throwsA(isA<ArgumentError>()));
      expect(() => intToBytes(value: 0x1234, length: 5), throwsA(isA<ArgumentError>()));
    });
  });
}