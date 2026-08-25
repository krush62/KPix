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

import 'package:kpix/util/helpers/geometry_helper.dart';

/// Implementation of Bresenham's line algorithm.
List<CoordinateSetI> bresenham({required final CoordinateSetI start, required final CoordinateSetI end})
{
  final List<CoordinateSetI> points = <CoordinateSetI>[];
  final CoordinateSetI d = CoordinateSetI(x: (end.x - start.x).abs(), y: (end.y - start.y).abs());
  final CoordinateSetI s = CoordinateSetI(x: start.x < end.x ? 1 : -1, y: start.y < end.y ? 1 : -1);

  int err = d.x - d.y;
  final CoordinateSetI currentPoint = CoordinateSetI.from(other: start);

  while (true)
  {
    points.add(CoordinateSetI.from(other: currentPoint));
    if (currentPoint.x == end.x && currentPoint.y == end.y) break;
    final int e2 = err * 2;
    if (e2 > -d.y)
    {
      err -= d.y;
      currentPoint.x += s.x;
    }
    if (e2 < d.x) {
      err += d.x;
      currentPoint.y += s.y;
    }
  }

  return points;
}

Set<CoordinateSetI> _drawEllipse({required final CoordinateSetI start, required final CoordinateSetI end,
  required final void Function(int x0, int y0, int x1, int y1, int vPixels, Set<CoordinateSetI> pixels) plot,})
{
  final Set<CoordinateSetI> pixels = <CoordinateSetI>{};

  int x0 = start.x;
  int y0 = start.y;
  int x1 = end.x;
  int y1 = end.y;

  int hPixels = 0;
  int vPixels = 0;

  if (x0 > x1) [x0, x1] = <int>[x1, x0];
  if (y0 > y1) [y0, y1] = <int>[y1, y0];

  final int w = x1 - x0 + 1;
  final int h = y1 - y0 + 1;

  final int hDiameter = w - hPixels;
  final int vDiameter = h - vPixels;

  if (<int>[8, 12, 22].contains(w)) hPixels++;
  if (<int>[8, 12, 22].contains(h)) vPixels++;

  hPixels = (hDiameter > 5 ? hPixels : 0);
  vPixels = (vDiameter > 5 ? vPixels : 0);

  if (hDiameter.isEven && hDiameter > 5) hPixels--;
  if (vDiameter.isEven && vDiameter > 5) vPixels--;

  x1 -= hPixels;
  y1 -= vPixels;

  int a = (x1 - x0).abs();
  final int b = (y1 - y0).abs();
  int b1 = b & 1;

  double dx = 4 * (1 - a) * b * b.toDouble();
  double dy = 4 * (b1 + 1) * a * a.toDouble();
  double err = dx + dy + b1 * a * a.toDouble();
  double e2;

  y0 += (b + 1) ~/ 2;
  y1 = y0 - b1;
  a = 8 * a * a;
  b1 = 8 * b * b;

  final int initialY0 = y0;
  final int initialY1 = y1;
  final int initialX0 = x0;
  final int initialX1 = x1 + hPixels;

  // Main loop
  do
  {
    plot(x0, y0 + vPixels, x1 + hPixels, y1, vPixels, pixels);

    e2 = 2 * err;
    if (e2 <= dy)
    {
      y0++;
      y1--;
      err += dy += a.toDouble();
    }
    if (e2 >= dx || 2 * err > dy)
    {
      x0++;
      x1--;
      err += dx += b1.toDouble();
    }
  }
  while (x0 <= x1);

  // Flat ellipse correction
  while (y0 + vPixels - y1 + 1 <= h)
  {
    plot(x0 - 1, y0 + vPixels, x1 + 1 + hPixels, y1, vPixels, pixels);
    y0++;
    y1--;
  }

  // Extra horizontal/vertical midsection pixels
  if (hPixels > 0)
  {
    for (int y = y1 + 1; y <= y0 + vPixels - 1; y++)
    {
      plot(x0, y, x1 + hPixels, y, 0, pixels);
    }
  }
  if (vPixels > 0)
  {
    for (int y = initialY1 + 1; y < initialY0 + vPixels; y++) {
      pixels.add(CoordinateSetI(x: initialX0, y: y));
      pixels.add(CoordinateSetI(x: initialX1, y: y));
    }
  }

  return pixels;
}


/// Draws a stroked ellipse inside the given bounds and stroke width.
Set<CoordinateSetI> drawStrokedEllipse({required final CoordinateSetI start, required final CoordinateSetI end, required final int strokeWidth})
{
  final int width = end.x - start.x + 1;
  final int height = end.y - start.y + 1;

  if (strokeWidth == 1)
  {
    return _drawEllipse(
      start: start,
      end: end,
      plot: (final int x0, final int y0, final int x1, final int y1, final int vPixels, final Set<CoordinateSetI> pixels)
      {
        pixels.add(CoordinateSetI(x: x0, y: y0));       // Quadrant II
        pixels.add(CoordinateSetI(x: x1, y: y0));       // Quadrant I
        pixels.add(CoordinateSetI(x: x0, y: y1));       // Quadrant III
        pixels.add(CoordinateSetI(x: x1, y: y1));       // Quadrant IV
      },
    );
  }
  else
  {
    final Set<CoordinateSetI> pixels = _drawEllipse(
      start: start,
      end: end,
      plot: (final int x0, final int y0, final int x1, final int y1, final int vPixels, final Set<CoordinateSetI> pixels)
      {
        for (int x = x0; x <= x1; x++)
        {
          pixels.add(CoordinateSetI(x: x, y: y0)); // top half
          pixels.add(CoordinateSetI(x: x, y: y1)); // bottom half
        }
      },
    );

    if (width > strokeWidth * 2 && height > strokeWidth * 2)
    {
      final CoordinateSetI innerSelectionStart = CoordinateSetI(x: start.x + strokeWidth, y: start.y + strokeWidth);
      final CoordinateSetI innerSelectionEnd = CoordinateSetI(x: end.x - strokeWidth, y: end.y - strokeWidth);
      final Set<CoordinateSetI> innerCircleContent = drawFilledEllipse(start: innerSelectionStart, end: innerSelectionEnd);
      pixels.removeAll(innerCircleContent);
    }
    return pixels;
  }
}

/// Draws a filled ellipse inside the given bounds.
Set<CoordinateSetI> drawFilledEllipse({required final CoordinateSetI start, required final CoordinateSetI end})
{
  return _drawEllipse(
    start: start,
    end: end,
    plot: (final int x0, final int y0, final int x1, final int y1, final int vPixels, final Set<CoordinateSetI> pixels)
    {
      for (int x = x0; x <= x1; x++)
      {
        pixels.add(CoordinateSetI(x: x, y: y0)); // top half
        pixels.add(CoordinateSetI(x: x, y: y1)); // bottom half
      }
    },
  );
}
