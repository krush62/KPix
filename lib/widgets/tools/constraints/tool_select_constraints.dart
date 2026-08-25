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

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

enum SelectShape
{
  rectangle(0, "Rectangle", TablerIcons.square),
  ellipse(1, "Ellipse", TablerIcons.circle),
  polygon(2, "Polygon", TablerIcons.polygon),
  wand(3, "Wand", TablerIcons.wand);

  const SelectShape(this.id, this.label, this.icon);

  final int id;
  final String label;
  final IconData icon;

  static Map<SelectShape, String> getLabelMap()
  {
    final Map<SelectShape, String> map = <SelectShape, String>{};
    for (final SelectShape shape in SelectShape.values) {
      map[shape] = shape.name;
    }
    return map;
  }

  static Map<SelectShape, ({String label, IconData icon})> getLabelIconMap()
  {
    final Map<SelectShape, ({String label, IconData icon})> map = <SelectShape, ({String label, IconData icon})>{};
    for (final SelectShape shape in SelectShape.values) {
      map[shape] = (label: shape.label, icon: shape.icon);
    }
    return map;
  }

  static SelectShape fromId(final int id)
  {
    return SelectShape.values.firstWhere((final SelectShape shape) => shape.id == id,
    );
  }
}

enum SelectMode
{
  replace(0, "Replace Selection", TablerIcons.repeat),
  add(1, "Add to Selection", TablerIcons.plus),
  subtract(2, "Subtract from Selection", TablerIcons.minus),
  intersect(3, "Intersect with Selection", TablerIcons.plus_minus);

  const SelectMode(this.id, this.label, this.icon);
  final int id;
  final String label;
  final IconData icon;
}

abstract final class SelectConstraints
{
  static const SelectShape shapeDefault = SelectShape.rectangle;
  static const bool keepAspectRatioDefault = false;
  static const SelectMode modeDefault = SelectMode.replace;
  static const bool wandContinuousDefault = true;
  static const bool wandWholeRampDefault = false;
}
