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

enum GridType
{
  rectangular(0, "Rectangular Grid", "REC"),
  diagonal(1, "Diagonal Grid", "DIA"),
  isometric(2, "Isometric Grid", "ISO"),
  hexagonal(3, "Hexagonal Grid", "HEX"),
  triangular(4, "Triangular Grid", "TRI"),
  brick(5, "Bricks", "BRK"),
  onePointPerspective(6, "1-Point Perspective", "1-Point"),
  twoPointPerspective(7, "2-Point Perspective", "2-Point"),
  threePointPerspective(8, "3-Point Perspective", "3-Point");

  const GridType(this.id, this.name, this.label);
  final int id;
  final String name;
  final String label;

  static GridType fromId(final int id)
  {
    return GridType.values.firstWhere((final GridType gridType) => gridType.id == id,
    );
  }
}

abstract final class GridLayerConstraints
{
  static const int opacityMin = 0;
  static const int opacityDefault = 100;
  static const int opacityMax = 100;

  static const int brightnessMin = 0;
  static const int brightnessDefault = 50;
  static const int brightnessMax = 100;

  static const int intervalXMin = 2;
  static const int intervalXDefault = 8;
  static const int intervalXMax = 64;

  static const int intervalYMin = 2;
  static const int intervalYDefault = 8;
  static const int intervalYMax = 64;

  static const double vanishingPointMin = -1.0;
  static const double vanishingPointMax = 2.0;
  static const double horizonDefault = 0.5;
  static const double vanishingPoint1Default = 0.1;
  static const double vanishingPoint2Default = 0.9;
  static const double vanishingPoint3Default = 0.9;
  static const GridType gridTypeDefault = GridType.rectangular;
}
