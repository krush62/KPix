/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY = ; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *  
 */

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

enum DrawingShape
{
  triangle(0, "Triangle", TablerIcons.triangle),
  rectangle(1, "Rectangle", TablerIcons.square),
  diamond(2, "Mid-Angle Rectangle", TablerIcons.diamonds),
  ellipse(3, "Ellipse", TablerIcons.circle),
  ngon(4, "Regular Polygon", TablerIcons.pentagon),
  star(5, "Star", TablerIcons.star);

  const DrawingShape(this.id, this.label, this.icon);

  final int id;
  final String label;
  final IconData icon;

  static Map<DrawingShape, String> getLabelMap()
  {
    final Map<DrawingShape, String> map = <DrawingShape, String>{};
    for (final DrawingShape shape in DrawingShape.values) {
      map[shape] = shape.name;
    }
    return map;
  }

  static Map<DrawingShape, ({String label, IconData icon})> getLabelIconMap()
  {
    final Map<DrawingShape, ({String label, IconData icon})> map = <DrawingShape, ({String label, IconData icon})>{};
    for (final DrawingShape shape in DrawingShape.values) {
      map[shape] = (label: shape.label, icon: shape.icon);
    }
    return map;
  }

  static DrawingShape fromId(final int id)
  {
    return DrawingShape.values.firstWhere((final DrawingShape shape) => shape.id == id,
    );
  }
}


abstract final class ToolShapeConstraints 
{
  static const DrawingShape shapeDefault = DrawingShape.rectangle;

  static const bool keepRatioDefault = false;

  static const bool strokeOnlyDefault = false;

  static const int strokeWidthMin = 1;
  static const int strokeWidthDefault = 1;
  static const int strokeWidthMax = 16;

  static const int cornerRadiusMin = 0;
  static const int cornerRadiusDefault = 0;
  static const int cornerRadiusMax = 16;

  static const int ellipseAngleMin = 0;
  static const int ellipseAngleDefault = 0;
  static const int ellipseAngleMax = 90;

  static const int ellipseAngleSteps = 5;

  static const int cornerCountMin = 5;
  static const int cornerCountDefault = 5;
  static const int cornerCountMax = 9;
}
