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
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

enum OuterStrokeStyle
{
  off,
  solid,
  relative,
  glow,
  shade
}

const Map<int, OuterStrokeStyle> outerStrokeStyleValueMap = <int, OuterStrokeStyle>{
  0:OuterStrokeStyle.off,
  1:OuterStrokeStyle.solid,
  2:OuterStrokeStyle.relative,
  3:OuterStrokeStyle.glow,
  4:OuterStrokeStyle.shade,
};

enum InnerStrokeStyle
{
  off,
  solid,
  glow,
  bevel,
  shade
}

const Map<int, InnerStrokeStyle> innerStrokeStyleValueMap = <int, InnerStrokeStyle>{
  0:InnerStrokeStyle.off,
  1:InnerStrokeStyle.solid,
  3:InnerStrokeStyle.glow,
  2:InnerStrokeStyle.bevel,
  4:InnerStrokeStyle.shade,
};

enum DropShadowStyle
{
  off,
  solid,
  shade
}

const Map<int, DropShadowStyle> dropShadowStyleValueMap = <int, DropShadowStyle>{
  0:DropShadowStyle.off,
  1:DropShadowStyle.solid,
  2:DropShadowStyle.shade,
};

class DrawingLayerSettingsConstraints
{
  final int darkenBrightenMin;
  final int darkenBrightenDefault;
  final int darkenBrightenMax;
  final int glowDepthMin;
  final int glowDepthDefault;
  final int glowDepthMax;
  final int bevelDistanceMin;
  final int bevelDistanceDefault;
  final int bevelDistanceMax;
  final int dropShadowOffsetMin;
  final int dropShadowOffsetDefault;
  final int dropShadowOffsetMax;

  DrawingLayerSettingsConstraints({
    required this.darkenBrightenMin,
    required this.darkenBrightenDefault,
    required this.darkenBrightenMax,
    required this.glowDepthMin,
    required this.glowDepthDefault,
    required this.glowDepthMax,
    required this.bevelDistanceMin,
    required this.bevelDistanceDefault,
    required this.bevelDistanceMax,
    required this.dropShadowOffsetMin,
    required this.dropShadowOffsetDefault,
    required this.dropShadowOffsetMax,});
}


class DrawingLayerSettings
{
  final DrawingLayerSettingsConstraints constraints;
  final ValueNotifier<OuterStrokeStyle> outerStrokeStyle = ValueNotifier<OuterStrokeStyle>(OuterStrokeStyle.off);
  final ValueNotifier<InnerStrokeStyle> innerStrokeStyle = ValueNotifier<InnerStrokeStyle>(InnerStrokeStyle.off);
  final ValueNotifier<DropShadowStyle> dropShadowStyle = ValueNotifier<DropShadowStyle>(DropShadowStyle.off);
  final ValueNotifier<HashMap<Alignment, bool>> outerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>());
  final ValueNotifier<HashMap<Alignment, bool>> innerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>());
  final ValueNotifier<HashMap<Alignment, bool>> dropShadowSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>());
  final ValueNotifier<ColorReference> outerColorReference;
  final ValueNotifier<ColorReference> innerColorReference;
  final ValueNotifier<ColorReference> dropShadowColorReference;
  final ValueNotifier<CoordinateSetI> dropShadowOffset;
  final ValueNotifier<int> outerDarkenBrighten;
  final ValueNotifier<int> outerGlowDepth;
  final ValueNotifier<int> innerDarkenBrighten;
  final ValueNotifier<int> innerGlowDepth;
  final ValueNotifier<int> bevelDistance;
  final ValueNotifier<int> dropShadowDarkenBrighten;

  DrawingLayerSettings({required final ColorReference startingColor, required this.constraints}) :
    outerDarkenBrighten = ValueNotifier<int>(constraints.darkenBrightenDefault),
    outerGlowDepth = ValueNotifier<int>(constraints.glowDepthDefault),
    innerDarkenBrighten = ValueNotifier<int>(constraints.darkenBrightenDefault),
    innerGlowDepth = ValueNotifier<int>(constraints.glowDepthDefault),
    bevelDistance = ValueNotifier<int>(constraints.bevelDistanceDefault),
    outerColorReference = ValueNotifier<ColorReference>(startingColor),
    innerColorReference = ValueNotifier<ColorReference>(startingColor),
    dropShadowColorReference = ValueNotifier<ColorReference>(startingColor),
    dropShadowOffset = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: constraints.dropShadowOffsetDefault, y: constraints.dropShadowOffsetDefault),),
    dropShadowDarkenBrighten = ValueNotifier<int>(constraints.darkenBrightenDefault)
  {
   for (final Alignment alignment in allAlignments)
   {
     outerSelectionMap.value[alignment] = alignment == Alignment.bottomRight;
     innerSelectionMap.value[alignment] = alignment == Alignment.bottomRight;
     dropShadowSelectionMap.value[alignment] = alignment == Alignment.bottomRight;
   }
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    if (outerColorReference.value.ramp == ramp)
    {
      outerColorReference.value = GetIt.I.get<AppState>().colorRamps[0].references[0];
    }
    if (innerColorReference.value.ramp == ramp)
    {
      innerColorReference.value = GetIt.I.get<AppState>().colorRamps[0].references[0];
    }
    if (dropShadowColorReference.value.ramp == ramp)
    {
      dropShadowColorReference.value = GetIt.I.get<AppState>().colorRamps[0].references[0];
    }
  }
}
