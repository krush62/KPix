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
import 'package:kpix/layer_states/drawing_layer_settings.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';

class HistoryDrawingLayerSettings {
  final DrawingLayerSettingsConstraints constraints;

  final OuterStrokeStyle outerStrokeStyle;
  final HashMap<Alignment, bool> outerSelectionMap;
  final HistoryColorReference outerColorReference;
  final int outerDarkenBrighten;
  final int outerGlowDepth;
  final bool outerGlowDirection;

  final InnerStrokeStyle innerStrokeStyle;
  final HashMap<Alignment, bool> innerSelectionMap;
  final HistoryColorReference innerColorReference;
  final int innerDarkenBrighten;
  final int innerGlowDepth;
  final bool innerGlowDirection;
  final int bevelDistance;
  final int bevelStrength;

  final DropShadowStyle dropShadowStyle;
  final HistoryColorReference dropShadowColorReference;
  final CoordinateSetI dropShadowOffset;
  final int dropShadowDarkenBrighten;

  const HistoryDrawingLayerSettings({
    required this.constraints,
    required this.outerStrokeStyle,
    required this.outerSelectionMap,
    required this.outerColorReference,
    required this.outerDarkenBrighten,
    required this.outerGlowDepth,
    required this.outerGlowDirection,
    required this.innerStrokeStyle,
    required this.innerSelectionMap,
    required this.innerColorReference,
    required this.innerDarkenBrighten,
    required this.innerGlowDepth,
    required this.innerGlowDirection,
    required this.bevelDistance,
    required this.bevelStrength,
    required this.dropShadowStyle,
    required this.dropShadowColorReference,
    required this.dropShadowOffset,
    required this.dropShadowDarkenBrighten,
  });

  HistoryDrawingLayerSettings.defaultValues(
      {required this.constraints, required final HistoryColorReference colRef,})
      :
        outerStrokeStyle = OuterStrokeStyle.off,
        outerSelectionMap = HashMap<Alignment, bool>(),
        outerColorReference = colRef,
        outerDarkenBrighten = constraints.darkenBrightenDefault,
        outerGlowDepth = constraints.glowDepthDefault,
        outerGlowDirection = constraints.glowDirectionDefault,
        innerStrokeStyle = InnerStrokeStyle.off,
        innerSelectionMap = HashMap<Alignment, bool>(),
        innerColorReference = colRef,
        innerDarkenBrighten = constraints.darkenBrightenDefault,
        innerGlowDepth = constraints.glowDepthDefault,
        innerGlowDirection = constraints.glowDirectionDefault,
        bevelDistance = constraints.bevelDistanceDefault,
        bevelStrength = constraints.bevelStrengthDefault,
        dropShadowStyle = DropShadowStyle.off,
        dropShadowColorReference = colRef,
        dropShadowOffset = CoordinateSetI(
            x: constraints.dropShadowOffsetDefault,
            y: constraints.dropShadowOffsetDefault,),
        dropShadowDarkenBrighten = constraints.darkenBrightenDefault
  {
    for (final Alignment alignment in allAlignments) {
      outerSelectionMap[alignment] = alignment == Alignment.bottomRight;
      innerSelectionMap[alignment] = alignment == Alignment.bottomRight;
    }
  }

  HistoryDrawingLayerSettings.fromDrawingLayerSettings({required final DrawingLayerSettings settings,}) :
      constraints = settings.constraints,
      outerStrokeStyle = settings.outerStrokeStyle.value,
      outerSelectionMap = HashMap<Alignment, bool>(),
      outerColorReference = HistoryColorReference(colorIndex: settings.outerColorReference.value.colorIndex, rampIndex: settings.outerColorReference.value.ramp.getIndex()),
      outerDarkenBrighten = settings.outerDarkenBrighten.value,
      outerGlowDepth = settings.outerGlowDepth.value,
      outerGlowDirection = settings.outerGlowDirection.value,
      innerStrokeStyle = settings.innerStrokeStyle.value,
      innerSelectionMap = HashMap<Alignment, bool>(),
      innerColorReference = HistoryColorReference(colorIndex: settings.innerColorReference.value.colorIndex, rampIndex: settings.innerColorReference.value.ramp.getIndex()),
      innerDarkenBrighten = settings.innerDarkenBrighten.value,
      innerGlowDepth = settings.innerGlowDepth.value,
      innerGlowDirection = settings.innerGlowDirection.value,
      bevelDistance = settings.bevelDistance.value,
      bevelStrength = settings.bevelStrength.value,
      dropShadowStyle = settings.dropShadowStyle.value,
      dropShadowColorReference = HistoryColorReference(colorIndex: settings.dropShadowColorReference.value.colorIndex, rampIndex: settings.dropShadowColorReference.value.ramp.getIndex()),
      dropShadowOffset = CoordinateSetI.from(other: settings.dropShadowOffset.value),
      dropShadowDarkenBrighten = settings.dropShadowDarkenBrighten.value
  {
    for (final Alignment alignment in allAlignments)
    {
      outerSelectionMap[alignment] = settings.outerSelectionMap.value[alignment] ?? false;
      innerSelectionMap[alignment] = settings.innerSelectionMap.value[alignment] ?? false;
    }
  }


}
