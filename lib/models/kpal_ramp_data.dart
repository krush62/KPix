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

import 'dart:collection';

import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/helpers/color_helper.dart';



/// Gets a map for converting one ramp to another
HashMap<ColorReference, ColorReference> getRampMap({required final List<KPalRampData> rampList1, required final List<KPalRampData> rampList2})
{
  final HashMap<ColorReference, ColorReference> rampMap = HashMap<ColorReference, ColorReference>();
  for (final KPalRampData kPalRampData in rampList1)
  {
    for (final ColorReference colRef in kPalRampData.references)
    {
      rampMap[colRef] = _getClosestColor(inputColor: colRef, rampList: rampList2);
    }
  }
  return rampMap;
}

/// Gets the closest color in the given ramp list to the input color.
ColorReference _getClosestColor({required final ColorReference inputColor, required final List<KPalRampData> rampList})
{
  assert(rampList.isNotEmpty);

  final double r = inputColor.getIdColor().color.r;
  final double g = inputColor.getIdColor().color.g;
  final double b = inputColor.getIdColor().color.b;
  late ColorReference closestColor;
  double closestVal = double.maxFinite;
  for (final KPalRampData kPalRampData in rampList)
  {
    for (int i = 0; i < kPalRampData.settings.colorCount; i++)
    {
      final double r2 = kPalRampData.shiftedColors[i].value.color.r;
      final double g2 = kPalRampData.shiftedColors[i].value.color.g;
      final double b2 = kPalRampData.shiftedColors[i].value.color.b;

      final double dist = getDeltaE00(redA: r, greenA: g, blueA: b, redB: r2, greenB: g2, blueB: b2);
      if (dist < closestVal)
      {
        closestColor = kPalRampData.references[i];
        closestVal = dist;
      }
    }
  }
  return closestColor;
}
