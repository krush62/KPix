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

import 'package:flutter/material.dart';

const double _goldenAngle = 137.50776405003785;
const double _saturation = 0.3;
final Map<int, double> _hueMap = <int, double>{};

Color _getColorWithHue({required final double hue, required final BuildContext context, required final bool selected})
{
  return HSVColor.fromAHSV(1.0, hue, _saturation, selected ? HSVColor.fromColor(Theme.of(context).primaryColor).value : HSVColor.fromColor(Theme.of(context).primaryColorDark).value).toColor();
}

void resetColorSupplier()
{
  _hueMap.clear();
}

Color getColorForLayer({required final int hashCode, required final BuildContext context, required final bool selected})
{
  if (_hueMap.containsKey(hashCode))
  {
    return _getColorWithHue(hue: _hueMap[hashCode]!, context: context, selected: selected);
  }
  else
  {
    final double hue = _hueMap.length * _goldenAngle % 360;
    final Color color = _getColorWithHue(hue: hue, context: context, selected: selected);
    _hueMap[hashCode] = hue;
    return color;
  }
}
