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

import 'package:flutter/material.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';

enum OuterStrokeStyle
{
  off,
  solid,
  relative,
  shade
}

enum InnerStrokeStyle
{
  off,
  solid,
  glow,
  shade
}

enum DropShadowStyle
{
  off,
  solid,
  shade
}


class DrawingLayerSettings
{
  final ValueNotifier<OuterStrokeStyle> outerStrokeStyle = ValueNotifier<OuterStrokeStyle>(OuterStrokeStyle.off);
  final ValueNotifier<InnerStrokeStyle> innerStrokeStyle = ValueNotifier<InnerStrokeStyle>(InnerStrokeStyle.off);
  final ValueNotifier<DropShadowStyle> dropShadowStyle = ValueNotifier<DropShadowStyle>(DropShadowStyle.off);
  final HashMap<Alignment, ValueNotifier<bool>> outerSelectionMap = HashMap<Alignment, ValueNotifier<bool>>();
  final HashMap<Alignment, ValueNotifier<bool>> innerSelectionMap = HashMap<Alignment, ValueNotifier<bool>>();
  late ValueNotifier<ColorReference> outerColorReference;
  late ValueNotifier<ColorReference> innerColorReference;
  final ValueNotifier<CoordinateSetI> dropShadowCoordinates = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: 0, y: 0));

  DrawingLayerSettings({required final ColorReference startingColor})
  {
    outerColorReference = ValueNotifier<ColorReference>(startingColor);
    innerColorReference = ValueNotifier<ColorReference>(startingColor);
     for (final Alignment alignment in allAlignments)
     {
       outerSelectionMap[alignment] = ValueNotifier<bool>(false);
       innerSelectionMap[alignment] = ValueNotifier<bool>(false);
     }
  }
}