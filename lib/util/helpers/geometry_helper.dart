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

import 'dart:collection';
import 'dart:math';

class CoordinateSetD
{
  double x = 0;
  double y = 0;

  CoordinateSetD({required this.x, required this.y});

  factory CoordinateSetD.zero()
  {
    return CoordinateSetD(x: 0.0, y: 0.0);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
          other is CoordinateSetD &&
              runtimeType == other.runtimeType &&
              x == other.x &&
              y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return "$x|$y";
  }
}

class CoordinateSetI
{
  int x = 0;
  int y = 0;

  CoordinateSetI({required this.x, required this.y});

  factory CoordinateSetI.from({required final CoordinateSetI other})
  {
    return CoordinateSetI(x: other.x, y: other.y);
  }

  factory CoordinateSetI.zero()
  {
    return CoordinateSetI(x: 0, y: 0);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
          other is CoordinateSetI &&
              runtimeType == other.runtimeType &&
              x == other.x &&
              y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return "$x|$y";
  }

  /// Checks if the current coordinate is adjacent to the other coordinate.
  bool isAdjacent({required final CoordinateSetI other, required final bool withDiagonal})
  {
    bool adj = true;
    if (withDiagonal)
    {
      if (other.x < x - 1 || other.x > x + 1 || other.y < y - 1 || other.y > y + 1)
      {
        adj = false;
      }
    }
    else if
    (((other.x - x).abs() > 1 || other.y != y) && ((other.y - y).abs() > 1 || other.x != x))
    {
      adj = false;
    }
    return adj;
  }

  /// Checks if the current coordinate is diagonal to the other coordinate.
  bool isDiagonal({required final CoordinateSetI other})
  {
    return (x - other.x).abs() == 1 && (y - other.y).abs() == 1;
  }

  /// Checks if the given coordinates are between 0 and the current value.
  bool contains({required final CoordinateSetI coord})
  {
    return coord.x >= 0 && coord.y >= 0 && coord.x < x && coord.y < y;
  }

  /// Returns a coordinate set with the minimum values of x and y.
  CoordinateSetI.getMin({required final List<CoordinateSetI> coordList})
  {
    x = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x < b.x ? a : b).x;
    y = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y < b.y ? a : b).y;
  }

  /// Returns a coordinate set with the maximum values of x and y.
  CoordinateSetI.getMax({required final List<CoordinateSetI> coordList})
  {
    x = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x > b.x ? a : b).x;
    y = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y > b.y ? a : b).y;
  }

  /// Returns a list of neighbors of the given pixel coordinate.
  List<CoordinateSetI> getNeighbors({required final bool withDiagonals})
  {
    final List<CoordinateSetI> neighbors =  <CoordinateSetI>[
      CoordinateSetI(x: x + 1, y: y),
      CoordinateSetI(x: x - 1, y: y),
      CoordinateSetI(x: x, y: y + 1),
      CoordinateSetI(x: x, y: y - 1),
    ];

    if (withDiagonals)
    {
      neighbors.add(CoordinateSetI(x: x + 1, y: y + 1));
      neighbors.add(CoordinateSetI(x: x - 1, y: y - 1));
      neighbors.add(CoordinateSetI(x: x + 1, y: y - 1));
      neighbors.add(CoordinateSetI(x: x - 1, y: y + 1));
    }

    return neighbors;
  }

  /// Returns the distance between two coordinate sets.
  double distanceTo({required final CoordinateSetI b})
  {
    return sqrt(((x - b.x) * (x - b.x)) + ((y - b.y) * (y - b.y)));
  }

}

const double twoPi = 2 * pi;
/// Normalizes an angle to the range [0, 2pi).
double normAngle({required final double angle})
{
  return angle - (twoPi * (angle / twoPi).floor());
}

/// Converts an angle in degrees to radians.
double deg2rad({required final double angle})
{
  return angle * (pi / 180.0);
}

/// Converts an angle in radians to degrees.
double rad2deg({required final double angle})
{
  return angle * (180.0 / pi);
}


/// Returns true if the square root of the [number] is an integer.
bool isPerfectSquare({required final int number})
{
  final double squareRoot = sqrt(number);
  return squareRoot % 1 == 0;
}

/// Calculates the greatest common divisor (GCD) of two integers.
int gcd({required final int a, required final int b})
{
  if (b == 0) return a;
  return gcd(a: b, b: a % b);
}

/// Calculates the angle between two points.
double calculateAngle({required final CoordinateSetI startPos, required final CoordinateSetI endPos})
{
  final int dx = endPos.x - startPos.x;
  final int dy = endPos.y - startPos.y;
  final double angle = atan2(dy, dx);
  final double angleInDegrees = angle * (180.0 / pi);
  return angleInDegrees;
}

/// Returns true if the point is on the line segment.
bool _isPointOnLineSegment({required final CoordinateSetI p, required final CoordinateSetI a, required final CoordinateSetI b, final double epsilon = 1e-6})
{
  final int cross = (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
  if (cross.abs() > epsilon)
  {
    return false;
  }
  final double minX = min(a.x, b.x) - epsilon;
  final double maxX = max(a.x, b.x) + epsilon;
  final double minY = min(a.y, b.y) - epsilon;
  final double maxY = max(a.y, b.y) + epsilon;

  return p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY;
}

int _isLeft({required final CoordinateSetI a, required final CoordinateSetI b, required final CoordinateSetI p})
{
  return (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
}


/// Returns true if the polygon contains the point.
bool isPointInPolygon({required final CoordinateSetI point, required final List<CoordinateSetI> polygon, final double epsilon = 1e-6}) {
  final int n = polygon.length;
  int windingNumber = 0;

  for (int i = 0, j = n - 1; i < n; j = i++)
  {
    final CoordinateSetI pi = polygon[i];
    final CoordinateSetI pj = polygon[j];
    if (_isPointOnLineSegment(p: point, a: pi, b: pj, epsilon: epsilon)) {
      return true;
    }

    if (pi.y <= point.y) {
      if (pj.y > point.y) {
        if (_isLeft(a: pi, b: pj, p: point) > 0) {
          windingNumber++;
        }
      }
    } else { // Edge crosses downward
      if (pj.y <= point.y) {
        if (_isLeft(a: pi, b: pj, p: point) < 0) {
          windingNumber--;
        }
      }
    }
  }

  return windingNumber != 0;
}


/// Returns the distance between the point and the closest edge of the polygon.
double getPointToEdgeDistance({required final CoordinateSetI point, required final List<CoordinateSetI> polygon})
{
  double minDistance = double.infinity;

  for (int i = 0; i < polygon.length; i++)
  {
    final CoordinateSetI p1 = polygon[i];
    final CoordinateSetI p2 = polygon[(i + 1) % polygon.length];

    final int dx = p2.x - p1.x;
    final int dy = p2.y - p1.y;

    final int edgeLengthSquared = dx * dx + dy * dy;

    final int vx = point.x - p1.x;
    final int vy = point.y - p1.y;

    final int dotProduct = vx * dx + vy * dy;

    final double t = max(0, min(1, dotProduct / edgeLengthSquared));

    final double closestX = p1.x + t * dx;
    final double closestY = p1.y + t * dy;

    final double distanceSquared = (point.x - closestX) * (point.x - closestX) + (point.y - closestY) * (point.y - closestY);

    minDistance = min(minDistance, sqrt(distanceSquared));
  }

  return minDistance;
}

/// Returns a map from old indices to new indices.
HashMap<int, int> remapIndices({required final int oldLength, required final int newLength})
{
  final HashMap<int, int> indexMap = HashMap<int, int>();
  final int centerOld = oldLength ~/ 2;
  final int centerNew = newLength ~/ 2;
  for (int i = 0; i < oldLength; i++)
  {
    final int dist = i - centerOld;
    final int newIndex = (centerNew + dist).clamp(0, newLength - 1);
    indexMap[i] = newIndex;
  }

  return indexMap;
}
