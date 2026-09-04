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

enum ToolType
{
  pencil("Pencil", TablerIcons.pencil),
  shape("Shapes", TablerIcons.triangle_square_circle),
  fill("Fill", TablerIcons.droplet),
  select("Select", TablerIcons.border_corners),
  pick("Color Pick", TablerIcons.color_picker),
  erase("Eraser", TablerIcons.eraser),
  font("Text", TablerIcons.typography),
  spraycan("Spray Can", TablerIcons.spray),
  line("Line", Icons.multiline_chart),
  stamp("Stamp", TablerIcons.rubber_stamp);

  const ToolType(this.title, this.icon);

  final String title;
  final IconData icon;

  bool isDrawTool()
  {
    return
      this == ToolType.pencil ||
          this == ToolType.shape ||
          this == ToolType.fill ||
          this == ToolType.font ||
          this == ToolType.spraycan ||
          this == ToolType.line ||
          this == ToolType.stamp;
  }
}
