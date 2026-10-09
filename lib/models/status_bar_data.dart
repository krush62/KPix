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

import 'package:kpix/util/helpers/geometry_helper.dart';

/// The measurements a tool reports while it is being dragged.
class StatusBarData
{
  CoordinateSetI? cursorPos;
  CoordinateSetI? dimension;
  CoordinateSetI? diagonal;
  CoordinateSetI? aspectRatio;
  CoordinateSetI? angle;
}

/// The measurements a tool shows next to the cursor while it is in use.
class CursorInfo
{
  final CoordinateSetI? dimension;
  final double? length;
  final double? angle;

  /// Pixel extent of the box spanned by [startPos] and [endPos].
  CursorInfo.box({required final CoordinateSetI startPos, required final CoordinateSetI endPos}) :
      dimension = CoordinateSetI(x: (endPos.x - startPos.x).abs() + 1, y: (endPos.y - startPos.y).abs() + 1),
      length = null,
      angle = null;

  /// Length and angle of a line, measured like the status bar does.
  CursorInfo.line({required final CoordinateSetI startPos, required final CoordinateSetI endPos}) :
      dimension = null,
      length = _diagonal(width: (endPos.x - startPos.x).abs() + 1, height: (endPos.y - startPos.y).abs() + 1),
      angle = calculateAngle(startPos: startPos, endPos: endPos);

  static double _diagonal({required final int width, required final int height})
  {
    return sqrt((width * width).toDouble() + (height * height).toDouble());
  }
}
