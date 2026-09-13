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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/drawing_layer_settings_constraints.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// A style that can be offered as one segment of a style selector.
///
/// Implemented by the per-section style enums so the settings widget can build
/// their selectors with one generic builder instead of one per enum.
abstract interface class StyleOption
{
  /// The short text shown on the segment.
  String get label;

  /// The tooltip explaining what the style does.
  String get desc;
}

enum OuterStrokeStyle implements StyleOption
{
  off(     0, "OFF", "No outer stroke"),
  solid(   1, "SLD", "Solid color outer stroke"),
  relative(2, "RLT", "Color relative outer stroke"),
  glow(    3, "GLW", "Glowing outer stroke"),
  shade(   4, "SHD", "Shaded outer stroke");

  const OuterStrokeStyle(this.id, this.label, this.desc);
  final int id;
  @override
  final String label;
  @override
  final String desc;

  static OuterStrokeStyle fromId(final int id) {
    return OuterStrokeStyle.values.firstWhere((final OuterStrokeStyle oss) => oss.id == id);
  }
}

enum InnerStrokeStyle implements StyleOption
{
  off(0, "OFF", "No inner stroke"),
  solid(1, "SLD", "Solid color inner stroke"),
  bevel(2, "BVL", "Beveled inner stroke"),
  glow(3, "GLW", "Glowing inner stroke"),
  shade(4, "SHD", "Shaded inner stroke");

  const InnerStrokeStyle(this.id, this.label, this.desc);
  final int id;
  @override
  final String label;
  @override
  final String desc;

  static InnerStrokeStyle fromId(final int id) {
    return InnerStrokeStyle.values.firstWhere((final InnerStrokeStyle iss) => iss.id == id);
  }
}

enum DropShadowStyle implements StyleOption
{
  off(0, "OFF", "No drop shadow"),
  solid(1, "SLD", "Solid color drop shadow"),
  shade(2, "SHD", "Shaded drop shadow");

  const DropShadowStyle(this.id, this.label, this.desc);
  final int id;
  @override
  final String label;
  @override
  final String desc;

  static DropShadowStyle fromId(final int id) {
    return DropShadowStyle.values.firstWhere((final DropShadowStyle dss) => dss.id == id);
  }
}

class DrawingLayerSettings extends LayerSettings {
  final DrawingLayerSettingsConstraints constraints;

  final ValueNotifier<OuterStrokeStyle> outerStrokeStyle;
  final ValueNotifier<HashMap<Alignment, bool>> outerSelectionMap;
  final ValueNotifier<ColorReference> outerColorReference;
  final ValueNotifier<int> outerDarkenBrighten;
  final ValueNotifier<int> outerGlowDepth;
  final ValueNotifier<bool> outerGlowRecursive;

  final ValueNotifier<InnerStrokeStyle> innerStrokeStyle;
  final ValueNotifier<HashMap<Alignment, bool>> innerSelectionMap;
  final ValueNotifier<ColorReference> innerColorReference;
  final ValueNotifier<int> innerDarkenBrighten;
  final ValueNotifier<int> innerGlowDepth;
  final ValueNotifier<bool> innerGlowRecursive;
  final ValueNotifier<int> bevelDistance;
  final ValueNotifier<int> bevelStrength;

  final ValueNotifier<DropShadowStyle> dropShadowStyle;
  final ValueNotifier<ColorReference> dropShadowColorReference;
  final ValueNotifier<CoordinateSetI> dropShadowOffset;
  final ValueNotifier<int> dropShadowDarkenBrighten;

  DrawingLayerSettings({
    required this.constraints,
    required final OuterStrokeStyle outerStrokeStyle,
    required final HashMap<Alignment, bool> outerSelectionMap,
    required final ColorReference outerColorReference,
    required final int outerDarkenBrighten,
    required final int outerGlowDepth,
    required final bool outerGlowRecursive,
    required final InnerStrokeStyle innerStrokeStyle,
    required final HashMap<Alignment, bool> innerSelectionMap,
    required final ColorReference innerColorReference,
    required final int innerDarkenBrighten,
    required final int innerGlowDepth,
    required final bool innerGlowRecursive,
    required final int bevelDistance,
    required final int bevelStrength,
    required final DropShadowStyle dropShadowStyle,
    required final ColorReference dropShadowColorReference,
    required final CoordinateSetI dropShadowOffset,
    required final int dropShadowDarkenBrighten,
  })
      :
        outerStrokeStyle = ValueNotifier<OuterStrokeStyle>(outerStrokeStyle),
        outerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(
            outerSelectionMap,),
        outerDarkenBrighten = ValueNotifier<int>(outerDarkenBrighten),
        outerGlowDepth = ValueNotifier<int>(outerGlowDepth),
        innerStrokeStyle = ValueNotifier<InnerStrokeStyle>(innerStrokeStyle),
        innerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(
            innerSelectionMap,),
        innerDarkenBrighten = ValueNotifier<int>(innerDarkenBrighten),
        innerGlowDepth = ValueNotifier<int>(innerGlowDepth),
        bevelDistance = ValueNotifier<int>(bevelDistance),
        bevelStrength = ValueNotifier<int>(bevelStrength),
        outerColorReference = ValueNotifier<ColorReference>(
            outerColorReference,),
        innerColorReference = ValueNotifier<ColorReference>(
            innerColorReference,),
        dropShadowStyle = ValueNotifier<DropShadowStyle>(dropShadowStyle),
        dropShadowColorReference = ValueNotifier<ColorReference>(
            dropShadowColorReference,),
        dropShadowOffset = ValueNotifier<CoordinateSetI>(dropShadowOffset,),
        dropShadowDarkenBrighten = ValueNotifier<int>(dropShadowDarkenBrighten),
        outerGlowRecursive = ValueNotifier<bool>(outerGlowRecursive),
        innerGlowRecursive = ValueNotifier<bool>(innerGlowRecursive)
  {
    _setupListeners();
  }

  DrawingLayerSettings.defaultValues({required final ColorReference startingColor, required this.constraints}) :
    outerStrokeStyle = ValueNotifier<OuterStrokeStyle>(OuterStrokeStyle.off),
    outerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>()),
    outerDarkenBrighten = ValueNotifier<int>(constraints.darkenBrightenDefault),
    outerGlowDepth = ValueNotifier<int>(constraints.glowDepthDefault),
    innerStrokeStyle = ValueNotifier<InnerStrokeStyle>(InnerStrokeStyle.off),
    innerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>()),
    innerDarkenBrighten = ValueNotifier<int>(constraints.darkenBrightenDefault),
    innerGlowDepth = ValueNotifier<int>(constraints.glowDepthDefault),
    bevelDistance = ValueNotifier<int>(constraints.bevelDistanceDefault),
    bevelStrength = ValueNotifier<int>(constraints.bevelStrengthDefault),
    outerColorReference = ValueNotifier<ColorReference>(startingColor),
    innerColorReference = ValueNotifier<ColorReference>(startingColor),
    dropShadowStyle = ValueNotifier<DropShadowStyle>(DropShadowStyle.off),
    dropShadowColorReference = ValueNotifier<ColorReference>(startingColor),
    dropShadowOffset = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: constraints.dropShadowOffsetDefault, y: constraints.dropShadowOffsetDefault),),
    dropShadowDarkenBrighten = ValueNotifier<int>(constraints.darkenBrightenDefault),
    outerGlowRecursive = ValueNotifier<bool>(constraints.glowRecursiveDefault),
    innerGlowRecursive = ValueNotifier<bool>(constraints.glowRecursiveDefault)
  {
    for (final Alignment alignment in allAlignments)
    {
      outerSelectionMap.value[alignment] = alignment == Alignment.bottomRight;
      innerSelectionMap.value[alignment] = alignment == Alignment.bottomRight;
    }
   _setupListeners();
  }

  DrawingLayerSettings.fromOther({required final DrawingLayerSettings other}) :
        constraints = other.constraints,
        outerStrokeStyle = ValueNotifier<OuterStrokeStyle>(other.outerStrokeStyle.value),
        outerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>()),
        outerDarkenBrighten = ValueNotifier<int>(other.outerDarkenBrighten.value),
        outerGlowDepth = ValueNotifier<int>(other.outerGlowDepth.value),
        innerStrokeStyle = ValueNotifier<InnerStrokeStyle>(other.innerStrokeStyle.value),
        innerSelectionMap = ValueNotifier<HashMap<Alignment, bool>>(HashMap<Alignment, bool>()),
        innerDarkenBrighten = ValueNotifier<int>(other.innerDarkenBrighten.value),
        innerGlowDepth = ValueNotifier<int>(other.innerGlowDepth.value),
        bevelDistance = ValueNotifier<int>(other.bevelDistance.value),
        bevelStrength = ValueNotifier<int>(other.bevelStrength.value),
        outerColorReference = ValueNotifier<ColorReference>(other.outerColorReference.value),
        innerColorReference = ValueNotifier<ColorReference>(other.innerColorReference.value),
        dropShadowStyle = ValueNotifier<DropShadowStyle>(other.dropShadowStyle.value),
        dropShadowColorReference = ValueNotifier<ColorReference>(other.dropShadowColorReference.value),
        dropShadowOffset = ValueNotifier<CoordinateSetI>(CoordinateSetI.from(other: other.dropShadowOffset.value)),
        dropShadowDarkenBrighten = ValueNotifier<int>(other.dropShadowDarkenBrighten.value),
        outerGlowRecursive = ValueNotifier<bool>(other.outerGlowRecursive.value),
        innerGlowRecursive = ValueNotifier<bool>(other.innerGlowRecursive.value)
  {
    for (final Alignment alignment in allAlignments)
    {
      outerSelectionMap.value[alignment] = other.outerSelectionMap.value[alignment] ?? false;
      innerSelectionMap.value[alignment] = other.innerSelectionMap.value[alignment] ?? false;
    }
    _setupListeners();
  }

  void _setupListeners()
  {

    outerStrokeStyle.addListener(valueChanged);
    innerStrokeStyle.addListener(valueChanged);
    dropShadowStyle.addListener(valueChanged);
    outerSelectionMap.addListener(valueChanged);
    innerSelectionMap.addListener(valueChanged);
    outerColorReference.addListener(valueChanged);
    innerColorReference.addListener(valueChanged);
    dropShadowColorReference.addListener(valueChanged);
    dropShadowOffset.addListener(valueChanged);
    outerDarkenBrighten.addListener(valueChanged);
    outerGlowDepth.addListener(valueChanged);
    innerDarkenBrighten.addListener(valueChanged);
    innerGlowDepth.addListener(valueChanged);
    bevelDistance.addListener(valueChanged);
    bevelStrength.addListener(valueChanged);
    dropShadowDarkenBrighten.addListener(valueChanged);
    outerGlowRecursive.addListener(valueChanged);
    innerGlowRecursive.addListener(valueChanged);
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    final Set<ValueNotifier<ColorReference>> colorCandidates = <ValueNotifier<ColorReference>>{outerColorReference, innerColorReference, dropShadowColorReference};
    final ColorReference resetColor = GetIt.I.get<PaletteState>().colorRamps[0].references[0];
    for (final ValueNotifier<ColorReference> colorRef in colorCandidates)
    {
      if (colorRef.value.ramp == ramp)
      {
        colorRef.value = resetColor;
      }
    }
  }

  /// What the layers below [layerState] in [layers] show at [coord]: the
  /// topmost visible drawing layer pixel there, shaded by the visible shading
  /// layers above it. [withSettingsPixels] includes those layers' effects.
  static ColorReference? colorBelow({required final CoordinateSetI coord, required final List<LayerState> layers, required final DrawingLayerState layerState, final bool withSettingsPixels = false})
  {
    ColorReference? currentColor;
    int colorShift = 0;
    int currentIndex = -1;
    for (int i = 0; i < layers.length; i++)
    {
      if (layers[i] == layerState)
      {
        currentIndex = i;
        break;
      }
    }
    if (currentIndex != -1)
    {
      for (int i = layers.length - 1; i > currentIndex; i--)
      {
        final LayerState layer = layers[i];
        if (layer is DrawingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
        {
          final ColorReference? colRef = layer.getDataEntry(coord: coord, withSettingsPixels: withSettingsPixels);

          if (colRef != null)
          {
            currentColor = colRef;
            colorShift = 0;
          }
        }
        else if (layer is ShadingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
        {
          final ShadingLayerState shadingLayer = layer;
          if (shadingLayer.hasCoord(coord: coord))
          {
            colorShift += shadingLayer.getDisplayValueAt(coord: coord)!;
          }
        }
      }
    }
    if (currentColor != null && colorShift != 0)
    {
      final int finalIndex = (currentColor.colorIndex + colorShift).clamp(0, currentColor.ramp.references.length - 1);
      currentColor = currentColor.ramp.references[finalIndex];
    }

    return currentColor;
  }

  @override
  bool hasActiveSettings()
  {
    return outerStrokeStyle.value != OuterStrokeStyle.off ||
        innerStrokeStyle.value != InnerStrokeStyle.off ||
        dropShadowStyle.value != DropShadowStyle.off;
  }

  bool get readsLayersBelow
  {
    return outerStrokeStyle.value == OuterStrokeStyle.shade ||
        outerStrokeStyle.value == OuterStrokeStyle.glow ||
        dropShadowStyle.value == DropShadowStyle.shade;
  }

}
