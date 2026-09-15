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

enum SelectShape
{
  rectangle(0, TablerIcons.square),
  ellipse(1, TablerIcons.circle),
  polygon(2, TablerIcons.polygon),
  wand(3, TablerIcons.wand);

  const SelectShape(this.id, this.icon);

  final int id;
  final IconData icon;

  String label(final AppLocalizations l10n) => switch (this)
  {
    rectangle => l10n.rectangle,
    ellipse => l10n.ellipse,
    polygon => l10n.polygon,
    wand => l10n.wand,
  };

  static Map<SelectShape, String> getLabelMap(final AppLocalizations l10n)
  {
    final Map<SelectShape, String> map = <SelectShape, String>{};
    for (final SelectShape shape in SelectShape.values) {
      map[shape] = shape.label(l10n);
    }
    return map;
  }

  static Map<SelectShape, ({String label, IconData icon})> getLabelIconMap(final AppLocalizations l10n)
  {
    final Map<SelectShape, ({String label, IconData icon})> map = <SelectShape, ({String label, IconData icon})>{};
    for (final SelectShape shape in SelectShape.values) {
      map[shape] = (label: shape.label(l10n), icon: shape.icon);
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
  replace(0, TablerIcons.repeat),
  add(1, TablerIcons.plus),
  subtract(2, TablerIcons.minus),
  intersect(3, TablerIcons.plus_minus);

  const SelectMode(this.id, this.icon);
  final int id;
  final IconData icon;

  String label(final AppLocalizations l10n) => switch(this)
  {
    replace => l10n.replaceSelection,
    add => l10n.addToSelection,
    subtract => l10n.subtractFromSelection,
    intersect => l10n.intersectWithSelection,
  };
}

abstract final class SelectConstraints
{
  static const SelectShape shapeDefault = SelectShape.rectangle;
  static const bool keepAspectRatioDefault = false;
  static const SelectMode modeDefault = SelectMode.replace;
  static const bool wandContinuousDefault = true;
  static const bool wandWholeRampDefault = false;
}
