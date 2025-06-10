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
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
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
  2:InnerStrokeStyle.bevel,
  3:InnerStrokeStyle.glow,
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
  final bool glowRecursiveDefault;
  final int bevelDistanceMin;
  final int bevelDistanceDefault;
  final int bevelDistanceMax;
  final int bevelStrengthMin;
  final int bevelStrengthDefault;
  final int bevelStrengthMax;
  final int dropShadowOffsetMin;
  final int dropShadowOffsetDefault;
  final int dropShadowOffsetMax;

  const DrawingLayerSettingsConstraints({
    required this.darkenBrightenMin,
    required this.darkenBrightenDefault,
    required this.darkenBrightenMax,
    required this.glowDepthMin,
    required this.glowDepthDefault,
    required this.glowDepthMax,
    required this.glowRecursiveDefault,
    required this.bevelDistanceMin,
    required this.bevelDistanceDefault,
    required this.bevelDistanceMax,
    required this.bevelStrengthMin,
    required this.bevelStrengthDefault,
    required this.bevelStrengthMax,
    required this.dropShadowOffsetMin,
    required this.dropShadowOffsetDefault,
    required this.dropShadowOffsetMax,});
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


  CoordinateColorMap getSettingsPixels({required final CoordinateColorMap data, required final DrawingLayerState layerState})
  {
    final AppState appState = GetIt.I.get<AppState>();
    final SelectionList? selectionList = appState.getSelectedLayer() == layerState ? appState.selectionState.selection : null;

    List<LayerState> layers;
    if (layerState.layerStack != null)
    {
      layers = layerState.layerStack!;
    }
    else
    {
      layers = <LayerState>[];
      for (int i = 0; i < appState.layerCount; i++)
      {
        layers.add(appState.getLayerAt(index: i));
      }
    }

    final CoordinateColorMap shadowPixels = getDropShadowPixels(layerState: layerState, layers: layers, data: data, canvasSize: appState.canvasSize);
    final CoordinateColorMap outerPixels = getOuterStrokePixels(layerState: layerState, layers: layers, data: data, canvasSize: appState.canvasSize);
    final CoordinateColorMap innerPixels = getInnerStrokePixels(layerState: layerState, layers: layers, data: data, canvasSize: appState.canvasSize, selectionList: selectionList);

    shadowPixels.addAll(outerPixels);
    shadowPixels.addAll(innerPixels);
    return shadowPixels;
  }

  HashMap<CoordinateSetI, int> getOuterShadingPixels({required final CoordinateColorMap data})
  {
    final AppState appState = GetIt.I.get<AppState>();
    final HashMap<CoordinateSetI, int> dropShadowPixels = HashMap<CoordinateSetI, int>();
    final HashMap<CoordinateSetI, int> outerPixels = HashMap<CoordinateSetI, int>();

    if (dropShadowStyle.value == DropShadowStyle.shade)
    {
      final Set<CoordinateSetI> dropShadowCoordinates = _getDropShadowCoordinates(dataPositions: data.keys, offset: dropShadowOffset.value, canvasSize: appState.canvasSize);
      for (final CoordinateSetI coord in dropShadowCoordinates)
      {
        dropShadowPixels[coord] = dropShadowDarkenBrighten.value;
      }
    }

    if (outerStrokeStyle.value == OuterStrokeStyle.shade || outerStrokeStyle.value == OuterStrokeStyle.glow)
    {
      final HashMap<CoordinateSetI, CoordinateSetI> outerStrokePixelsWithReference = _getOuterStrokePixelsWithReference(selectionMap: outerSelectionMap.value, dataPositions: data.keys, canvasSize: appState.canvasSize);
      for (final MapEntry<CoordinateSetI, CoordinateSetI> pixelSet in outerStrokePixelsWithReference.entries)
      {
        if (outerStrokeStyle.value == OuterStrokeStyle.shade)
        {
          outerPixels[pixelSet.key] = outerDarkenBrighten.value;
        }
        else if (outerStrokeStyle.value == OuterStrokeStyle.glow)
        {
          int lastSelfGlowAmount = 100000;
          for (int i = 0; i < outerGlowDepth.value.abs(); i++)
          {
            final Set<CoordinateSetI> setPixels = <CoordinateSetI>{};
            setPixels.addAll(data.keys);
            setPixels.addAll(outerPixels.keys);
            final HashMap<CoordinateSetI, int> glowPixels = _getOuterStrokePixelsWithAmount(selectionMap: outerSelectionMap.value, dataPositions: setPixels, canvasSize: appState.canvasSize);
            int highestSelfGlowAmount = 0;
            for (final MapEntry<CoordinateSetI, int> glowPixel in glowPixels.entries)
            {
              final int selfGlowAmount = outerGlowRecursive.value ? min(glowPixel.value - 1, lastSelfGlowAmount) : 0;
              highestSelfGlowAmount = max(highestSelfGlowAmount, selfGlowAmount);
              final int steps = outerGlowDepth.value > 0 ? outerGlowDepth.value - i + selfGlowAmount : outerGlowDepth.value + i - selfGlowAmount;
              outerPixels[pixelSet.key] = steps;
            }
            lastSelfGlowAmount = highestSelfGlowAmount;
          }
        }

      }
    }
    dropShadowPixels.addAll(outerPixels);
    return dropShadowPixels;
  }

  CoordinateColorMap getDropShadowPixels({required final CoordinateColorMap data, required final DrawingLayerState layerState, required final CoordinateSetI canvasSize, required final List<LayerState> layers})
  {
    final CoordinateColorMap shadowPixels = CoordinateColorMap();
    if (dropShadowStyle.value != DropShadowStyle.off)
    {
      final Set<CoordinateSetI> dropShadowCoordinates = _getDropShadowCoordinates(dataPositions: data.keys, offset: dropShadowOffset.value, canvasSize: canvasSize);
      for (final CoordinateSetI coord in dropShadowCoordinates)
      {
        if (dropShadowStyle.value == DropShadowStyle.solid)
        {
          shadowPixels[coord] = dropShadowColorReference.value;
        }
        else if (dropShadowStyle.value == DropShadowStyle.shade)
        {
          final ColorReference? currentColor = _getColorReferenceAtPos(coord: coord, layers: layers, layerState: layerState, withSettingsPixels: true);

          if (currentColor != null)
          {
            final KPalRampData currentRamp = currentColor.ramp;
            final int rampIndex = (currentColor.colorIndex + dropShadowDarkenBrighten.value).clamp(0, currentRamp.references.length - 1);
            shadowPixels[coord] = currentRamp.references[rampIndex];
          }
        }
      }
    }
    return shadowPixels;
  }

  CoordinateColorMap getOuterStrokePixels({required final CoordinateColorMap data, required final DrawingLayerState layerState, required final CoordinateSetI canvasSize, required final List<LayerState> layers})
  {
    final CoordinateColorMap outerPixels = CoordinateColorMap();
    if (outerStrokeStyle.value == OuterStrokeStyle.solid || outerStrokeStyle.value == OuterStrokeStyle.shade || outerStrokeStyle.value == OuterStrokeStyle.relative)
    {
      final HashMap<CoordinateSetI, CoordinateSetI> outerStrokePixelsWithReference = _getOuterStrokePixelsWithReference(selectionMap: outerSelectionMap.value, dataPositions: data.keys, canvasSize: canvasSize);
      for (final MapEntry<CoordinateSetI, CoordinateSetI> pixelSet in outerStrokePixelsWithReference.entries)
      {
        if (outerStrokeStyle.value == OuterStrokeStyle.solid)
        {
          outerPixels[pixelSet.key] = outerColorReference.value;
        }
        else if (outerStrokeStyle.value == OuterStrokeStyle.relative)
        {
          final ColorReference currentColor = data[pixelSet.value]!;
          final KPalRampData currentRamp = currentColor.ramp;
          final int rampIndex = (currentColor.colorIndex + outerDarkenBrighten.value).clamp(0, currentRamp.references.length - 1);
          outerPixels[pixelSet.key] = currentRamp.references[rampIndex];
        }
        else if (outerStrokeStyle.value == OuterStrokeStyle.shade)
        {
          final ColorReference? currentColor = _getColorReferenceAtPos(coord: pixelSet.key, layers: layers, layerState: layerState);
          if (currentColor != null)
          {
            final KPalRampData currentRamp = currentColor.ramp;
            final int rampIndex = (currentColor.colorIndex + outerDarkenBrighten.value).clamp(0, currentRamp.references.length - 1);
            outerPixels[pixelSet.key] = currentRamp.references[rampIndex];
          }
        }
      }
    }
    else if (outerStrokeStyle.value == OuterStrokeStyle.glow)
    {
      int lastSelfGlowAmount = 100000;
      for (int i = 0; i < outerGlowDepth.value.abs(); i++)
      {
        final Set<CoordinateSetI> setPixels = <CoordinateSetI>{};
        setPixels.addAll(data.keys);
        setPixels.addAll(outerPixels.keys);
        final HashMap<CoordinateSetI, int> glowPixels = _getOuterStrokePixelsWithAmount(selectionMap: outerSelectionMap.value, dataPositions: setPixels, canvasSize: canvasSize);
        int highestSelfGlowAmount = 0;
        for (final MapEntry<CoordinateSetI, int> glowPixel in glowPixels.entries)
        {
          final ColorReference? currentColor = _getColorReferenceAtPos(coord: glowPixel.key, layers: layers, layerState: layerState);
          if (currentColor != null)
          {
            final KPalRampData currentRamp = currentColor.ramp;
            final int selfGlowAmount = outerGlowRecursive.value ? min(glowPixel.value - 1, lastSelfGlowAmount) : 0;
            highestSelfGlowAmount = max(highestSelfGlowAmount, selfGlowAmount);
            final int steps = outerGlowDepth.value > 0 ? outerGlowDepth.value - i + selfGlowAmount : outerGlowDepth.value + i - selfGlowAmount;
            final int rampIndex = (currentColor.colorIndex + steps).clamp(0, currentRamp.references.length - 1);
            outerPixels[glowPixel.key] = currentRamp.references[rampIndex];
          }
        }
        lastSelfGlowAmount = highestSelfGlowAmount;
      }
    }


    return outerPixels;
  }

  CoordinateColorMap getInnerStrokePixels({required final CoordinateColorMap data, required final DrawingLayerState layerState, required final CoordinateSetI canvasSize, required final List<LayerState> layers, required final SelectionList? selectionList})
  {
    final CoordinateColorMap innerPixels = CoordinateColorMap();
    if (innerStrokeStyle.value != InnerStrokeStyle.off)
    {
      final Set<CoordinateSetI> innerStrokePixels = _getInnerStrokeCoordinates(selectionMap: innerSelectionMap.value, data: data, canvasSize: canvasSize);
      if (innerStrokeStyle.value == InnerStrokeStyle.solid || innerStrokeStyle.value == InnerStrokeStyle.shade)
      {
        for (final CoordinateSetI coord in innerStrokePixels)
        {
          if (innerStrokeStyle.value == InnerStrokeStyle.solid)
          {
            innerPixels[coord] = innerColorReference.value;
          }
          else if (innerStrokeStyle.value == InnerStrokeStyle.shade)
          {
            final ColorReference? currentColor;
            if (selectionList != null && selectionList.contains(coord: coord))
            {
              currentColor = selectionList.getColorReference(coord: coord);
            }
            else
            {
              currentColor = layerState.getDataEntry(coord: coord);
            }
            if (currentColor != null)
            {
              final KPalRampData currentRamp = currentColor.ramp;
              final int rampIndex = (currentColor.colorIndex + innerDarkenBrighten.value).clamp(0, currentRamp.references.length - 1);
              innerPixels[coord] = currentRamp.references[rampIndex];
            }
          }
        }
      }
      else if (innerStrokeStyle.value == InnerStrokeStyle.glow)
      {
        int lastSelfGlowAmount = 100000;
        final CoordinateColorMap dataPixels = CoordinateColorMap();
        dataPixels.addAll(data);
        for (int i = 0; i < innerGlowDepth.value.abs(); i++)
        {
          final Map<CoordinateSetI, int> innerStrokePixels = _getInnerStrokeCoordinatesWithAmount(selectionMap: innerSelectionMap.value, data: dataPixels, canvasSize: canvasSize);
          int highestSelfGlowAmount = 0;
          for (final MapEntry<CoordinateSetI, int> coord in innerStrokePixels.entries)
          {
            final ColorReference? currentColor;
            if (selectionList != null && selectionList.contains(coord: coord.key))
            {
              currentColor = selectionList.getColorReference(coord: coord.key);
            }
            else
            {
              currentColor = layerState.getDataEntry(coord: coord.key);
            }
            if (currentColor != null)
            {
              final KPalRampData currentRamp = currentColor.ramp;
              final int selfGlowAmount = innerGlowRecursive.value ? min(coord.value - 1, lastSelfGlowAmount) : 0;
              highestSelfGlowAmount = max(highestSelfGlowAmount, selfGlowAmount);
              final int steps = innerGlowDepth.value > 0 ? innerGlowDepth.value - i + selfGlowAmount: innerGlowDepth.value + i - selfGlowAmount;
              final int rampIndex = (currentColor.colorIndex + steps).clamp(0, currentRamp.references.length - 1);
              innerPixels[coord.key] = currentRamp.references[rampIndex];
            }
            dataPixels.remove(coord.key);
          }
          lastSelfGlowAmount = highestSelfGlowAmount;
        }
      }
      else if (innerStrokeStyle.value == InnerStrokeStyle.bevel)
      {
        final HashMap<Alignment, bool> usedSelectionMap = HashMap<Alignment, bool>();
        final HashMap<Alignment, bool> oppositeSelectionMap = HashMap<Alignment, bool>();
        final HashMap<Alignment, bool> allDirectionsMap = HashMap<Alignment, bool>();
        for (final Alignment alignment in allAlignments)
        {
          usedSelectionMap[alignment] = false;
          oppositeSelectionMap[alignment] = false;
          allDirectionsMap[alignment] = true;
        }

        for (final MapEntry<Alignment, bool> entry in innerSelectionMap.value.entries)
        {
          if (entry.value == true)
          {
            if (_alignmentIsDiagonal(alignment: entry.key))
            {
              final Set<Alignment> adjacentAlignments = _getAdjacentDirections(alignment: entry.key);
              for (final Alignment alignment in adjacentAlignments)
              {
                usedSelectionMap[alignment] = true;
              }
            }
            else
            {
              usedSelectionMap[entry.key] = true;
            }
            final Set<Alignment> oppositeAlignments = _getOppositeAlignments(alignment: entry.key);
            for (final Alignment oppAlign in oppositeAlignments)
            {
              oppositeSelectionMap[oppAlign] = true;
            }
            break;
          }
        }

        final CoordinateColorMap dataPixels = CoordinateColorMap();
        dataPixels.addAll(data);
        for (int i = 0; i < bevelDistance.value; i++)
        {
          if (i == bevelDistance.value - 1)
          {

            final Set<CoordinateSetI> oppositeStrokePixels = _getInnerStrokeCoordinates(selectionMap: oppositeSelectionMap, data: dataPixels, canvasSize: canvasSize);
            final Set<CoordinateSetI> directionPixels = _getInnerStrokeCoordinates(selectionMap: usedSelectionMap, data: dataPixels, canvasSize: canvasSize);

            for (final CoordinateSetI coord in oppositeStrokePixels)
            {
              final ColorReference? currentColor = layerState.getDataEntry(coord: coord);
              if (currentColor != null)
              {
                final KPalRampData currentRamp = currentColor.ramp;
                final int rampIndex = (currentColor.colorIndex - bevelStrength.value).clamp(0, currentRamp.references.length - 1);
                innerPixels[coord] = currentRamp.references[rampIndex];
              }
            }
            for (final CoordinateSetI coord in directionPixels)
            {
              final ColorReference? currentColor = layerState.getDataEntry(coord: coord);
              if (currentColor != null)
              {
                final KPalRampData currentRamp = currentColor.ramp;
                final int rampIndex = (currentColor.colorIndex + bevelStrength.value).clamp(0, currentRamp.references.length - 1);
                innerPixels[coord] = currentRamp.references[rampIndex];
              }
            }
          }
          else
          {
            final Set<CoordinateSetI> oppositeStrokePixels = _getInnerStrokeCoordinates(selectionMap: allDirectionsMap, data: dataPixels, canvasSize: canvasSize);
            for (final CoordinateSetI coord in oppositeStrokePixels)
            {
              dataPixels.remove(coord);
            }
          }
        }
      }
    }
    return innerPixels;
  }

  static HashMap<CoordinateSetI, CoordinateSetI> _getOuterStrokePixelsWithReference({required final HashMap<Alignment, bool> selectionMap, required final Iterable<CoordinateSetI> dataPositions, required final CoordinateSetI canvasSize})
  {
    final HashMap<CoordinateSetI, CoordinateSetI> outerStrokePixels = HashMap<CoordinateSetI, CoordinateSetI>();
    for (final CoordinateSetI dataPosition in dataPositions)
    {
      final HashMap<Alignment, CoordinateSetI> surroundingPixels = _getAllSurroundingPositions(pos: dataPosition);
      for (final MapEntry<Alignment, CoordinateSetI> surroundEntry in surroundingPixels.entries)
      {
        if (selectionMap[surroundEntry.key] != null && (selectionMap[surroundEntry.key] ?? false == true) && !dataPositions.contains(surroundEntry.value) &&
            surroundEntry.value.x >= 0 && surroundEntry.value.x < canvasSize.x && surroundEntry.value.y >= 0 && surroundEntry.value.y < canvasSize.y &&
            (outerStrokePixels[surroundEntry.value] == null || _isAdjacentAlignment(alignment: surroundEntry.key)))
        {
          outerStrokePixels[surroundEntry.value] = dataPosition;
        }
      }

    }
    return outerStrokePixels;
  }

  static HashMap<CoordinateSetI, int> _getOuterStrokePixelsWithAmount({required final HashMap<Alignment, bool> selectionMap, required final Iterable<CoordinateSetI> dataPositions, required final CoordinateSetI canvasSize})
  {
    final HashMap<CoordinateSetI, int> outerStrokePixels = HashMap<CoordinateSetI, int>();
    for (final CoordinateSetI dataPosition in dataPositions)
    {
      final HashMap<Alignment, CoordinateSetI> surroundingPixels = _getAllSurroundingPositions(pos: dataPosition);
      for (final MapEntry<Alignment, CoordinateSetI> surroundEntry in surroundingPixels.entries)
      {
        if (selectionMap[surroundEntry.key] != null && (selectionMap[surroundEntry.key] ?? false == true) && !dataPositions.contains(surroundEntry.value) &&
            surroundEntry.value.x >= 0 && surroundEntry.value.x < canvasSize.x && surroundEntry.value.y >= 0 && surroundEntry.value.y < canvasSize.y)
        {
          if (outerStrokePixels.containsKey(surroundEntry.value))
          {
            outerStrokePixels[surroundEntry.value] = outerStrokePixels[surroundEntry.value]! + 1;
          }
          else
          {
            outerStrokePixels[surroundEntry.value] = 1;
          }
        }
      }

    }
    return outerStrokePixels;
  }

  static HashMap<Alignment, CoordinateSetI> _getAllSurroundingPositions({required final CoordinateSetI pos})
  {
    final HashMap<Alignment, CoordinateSetI> surroundingPixels = HashMap<Alignment, CoordinateSetI>();
    surroundingPixels[Alignment.topLeft] = CoordinateSetI(x: pos.x - 1, y: pos.y - 1);
    surroundingPixels[Alignment.topCenter] = CoordinateSetI(x: pos.x, y: pos.y - 1);
    surroundingPixels[Alignment.topRight] = CoordinateSetI(x: pos.x + 1, y: pos.y - 1);
    surroundingPixels[Alignment.centerRight] = CoordinateSetI(x: pos.x + 1, y: pos.y);
    surroundingPixels[Alignment.bottomRight] = CoordinateSetI(x: pos.x + 1, y: pos.y + 1);
    surroundingPixels[Alignment.bottomCenter] = CoordinateSetI(x: pos.x, y: pos.y + 1);
    surroundingPixels[Alignment.bottomLeft] = CoordinateSetI(x: pos.x - 1, y: pos.y + 1);
    surroundingPixels[Alignment.centerLeft] = CoordinateSetI(x: pos.x - 1, y: pos.y);

    return surroundingPixels;
  }

  static bool _isAdjacentAlignment({required final Alignment alignment})
  {
    return alignment == Alignment.topCenter ||
        alignment == Alignment.centerRight ||
        alignment == Alignment.bottomCenter ||
        alignment == Alignment.centerLeft;
  }

  static ColorReference? _getColorReferenceAtPos({required final CoordinateSetI coord, required final List<LayerState> layers, required final DrawingLayerState layerState, final bool withSettingsPixels = false})
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
        if (layer.runtimeType == DrawingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
        {
          final DrawingLayerState drawingLayerState = layer as DrawingLayerState;
          final ColorReference? colRef = drawingLayerState.getDataEntry(coord: coord, withSettingsPixels: withSettingsPixels);

          if (colRef != null)
          {
            currentColor = colRef;
            colorShift = 0;
          }
        }
        else if (layer.runtimeType == ShadingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
        {
          final ShadingLayerState shadingLayer = layer as ShadingLayerState;
          if (shadingLayer.hasCoord(coord: coord))
          {
            colorShift += shadingLayer.getValueAt(coord: coord)!;
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

  static Set<CoordinateSetI> _getDropShadowCoordinates({required final Iterable<CoordinateSetI> dataPositions, required final CoordinateSetI offset, required final CoordinateSetI canvasSize})
  {
    final Set<CoordinateSetI> coords = <CoordinateSetI>{};
    for (final CoordinateSetI dataCoord in dataPositions)
    {
      final CoordinateSetI coord = CoordinateSetI(x: dataCoord.x + offset.x, y: dataCoord.y + offset.y);
      if (!dataPositions.contains(coord) && coord.x >= 0 && coord.x < canvasSize.x && coord.y >= 0 && coord.y < canvasSize.y)
      {
        coords.add(coord);
      }
    }
    return coords;
  }

  static Set<CoordinateSetI> _getInnerStrokeCoordinates({required final HashMap<Alignment, bool> selectionMap, required final CoordinateColorMap data, required final CoordinateSetI canvasSize})
  {
    final Set<CoordinateSetI> coords = <CoordinateSetI>{};

    for (final CoordinateSetI dataPosition in data.keys)
    {
      final HashMap<Alignment, CoordinateSetI> surroundingPixels = _getAllSurroundingPositions(pos: dataPosition);
      for (final MapEntry<Alignment, CoordinateSetI> surroundEntry in surroundingPixels.entries)
      {
        if (data[surroundEntry.value] == null && selectionMap[surroundEntry.key] == true)
        {
          coords.add(dataPosition);
          break;
        }
      }

    }
    return coords;
  }

  static Map<CoordinateSetI, int> _getInnerStrokeCoordinatesWithAmount({required final HashMap<Alignment, bool> selectionMap, required final CoordinateColorMap data, required final CoordinateSetI canvasSize})
  {
    final Map<CoordinateSetI, int> coords = <CoordinateSetI, int>{};

    for (final CoordinateSetI dataPosition in data.keys)
    {
      final HashMap<Alignment, CoordinateSetI> surroundingPixels = _getAllSurroundingPositions(pos: dataPosition);
      for (final MapEntry<Alignment, CoordinateSetI> surroundEntry in surroundingPixels.entries)
      {
        if (data[surroundEntry.value] == null && selectionMap[surroundEntry.key] == true)
        {
          if (coords.containsKey(dataPosition))
          {
            coords[dataPosition] = coords[dataPosition]! + 1;
          }
          else
          {
            coords[dataPosition] = 1;
          }
        }
      }

    }
    return coords;
  }

  Set<Alignment> _getOppositeAlignments({required final Alignment alignment, final bool useDiagonals = false})
  {
    if (alignment == Alignment.topLeft)
    {
      if (useDiagonals)
      {
        return <Alignment>{Alignment.bottomRight};
      }
      else
      {
        return _getAdjacentDirections(alignment: Alignment.bottomRight);
      }
    }
    else if (alignment == Alignment.topRight)
    {
      if (useDiagonals)
      {
        return <Alignment>{Alignment.bottomLeft};
      }
      else
      {
        return _getAdjacentDirections(alignment: Alignment.bottomLeft);
      }
    }
    else if (alignment == Alignment.bottomRight)
    {
      if (useDiagonals)
      {
        return <Alignment>{Alignment.topLeft};
      }
      else
      {
        return _getAdjacentDirections(alignment: Alignment.topLeft);
      }
    }
    else if (alignment == Alignment.bottomLeft)
    {
      if (useDiagonals)
      {
        return <Alignment>{Alignment.topRight};
      }
      else
      {
        return _getAdjacentDirections(alignment: Alignment.topRight);
      }
    }
    else if (alignment == Alignment.topCenter) {return <Alignment>{Alignment.bottomCenter};}
    else if (alignment == Alignment.centerRight) {return <Alignment>{Alignment.centerLeft};}
    else if (alignment == Alignment.bottomCenter) {return <Alignment>{Alignment.topCenter};}
    else if (alignment == Alignment.centerLeft) {return <Alignment>{Alignment.centerRight};}
    else {return <Alignment>{Alignment.center};}
  }

  bool _alignmentIsDiagonal({required final Alignment alignment})
  {
    if (alignment == Alignment.topLeft || alignment == Alignment.topRight || alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft)
    {
      return true;
    }
    return false;
  }

  Set<Alignment> _getAdjacentDirections({required final Alignment alignment})
  {
    if (alignment == Alignment.topLeft)
    {
      return <Alignment>{Alignment.centerLeft, Alignment.topCenter};
    }
    else if (alignment == Alignment.topCenter)
    {
      return <Alignment>{Alignment.topLeft, Alignment.topRight};
    }
    else if (alignment == Alignment.topRight)
    {
      return <Alignment>{Alignment.topCenter, Alignment.centerRight};
    }
    else if (alignment == Alignment.centerRight)
    {
      return <Alignment>{Alignment.topRight, Alignment.bottomRight};
    }
    else if (alignment == Alignment.bottomRight)
    {
      return <Alignment>{Alignment.centerRight, Alignment.bottomCenter};
    }
    else if (alignment == Alignment.bottomCenter)
    {
      return <Alignment>{Alignment.bottomLeft, Alignment.bottomRight};
    }
    else if (alignment == Alignment.bottomLeft)
    {
      return <Alignment>{Alignment.bottomCenter, Alignment.centerLeft};
    }
    else if (alignment == Alignment.centerLeft)
    {
      return <Alignment>{Alignment.bottomLeft, Alignment.topLeft};
    }
    else
    {
      return <Alignment>{alignment};
    }
  }

  @override
  bool hasActiveSettings()
  {
    return outerStrokeStyle.value != OuterStrokeStyle.off ||
        innerStrokeStyle.value != InnerStrokeStyle.off ||
        dropShadowStyle.value != DropShadowStyle.off;
  }

}
