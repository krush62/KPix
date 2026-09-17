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
import 'package:kpix/l10n/app_localizations.dart';

enum ToolType
{
  pencil(TablerIcons.pencil),
  shape(TablerIcons.triangle_square_circle),
  fill(TablerIcons.droplet),
  select( TablerIcons.border_corners),
  pick(TablerIcons.color_picker),
  erase(TablerIcons.eraser),
  font(TablerIcons.typography),
  spraycan(TablerIcons.spray),
  line(Icons.multiline_chart),
  stamp(TablerIcons.rubber_stamp);

  const ToolType(this.icon);

  final IconData icon;

  String label(final AppLocalizations l10n) => switch(this)
  {
    pencil => l10n.pencil,
    shape => l10n.shape,
    fill => l10n.fill,
    select => l10n.select,
    pick => l10n.colorPicker,
    erase => l10n.eraser,
    font => l10n.text,
    spraycan => l10n.sprayCan,
    line => l10n.line,
    stamp => l10n.stamp,
  };

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
