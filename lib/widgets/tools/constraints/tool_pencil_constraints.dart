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

enum PencilShape
{
  round(0, "Round"),
  square(1, "Square");

  const PencilShape(this.id, this.label);

  final int id;
  final String label;

  static Map<PencilShape, String> getLabelMap()
  {
    final Map<PencilShape, String> map = <PencilShape, String>{};
    for (final PencilShape shape in PencilShape.values)
    {
      map[shape] = shape.label;
    }
    return map;
  }

  static PencilShape fromId(final int id)
  {
    return PencilShape.values.firstWhere((final PencilShape shape) => shape.id == id,
    );
  }
}

abstract final class PencilConstraints
{
  static const int sizeMin = 1;
  static const int sizeDefault = 1;
  static const int sizeMax = 32;
  static const PencilShape shapeDefault = PencilShape.round;
  static const bool pixelPerfectDefault = true;
}
