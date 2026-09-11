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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

/// The layer whose effects are computed, as far as the effects look at it.
class LegacyLayer
{
  LegacyLayer({required this.dataAt});
  final ColorReference? Function(CoordinateSetI coord) dataAt;
  ColorReference? getDataEntry({required final CoordinateSetI coord}) => dataAt(coord);
}

/// The floating selection, as far as the inner stroke looks at it.
class LegacySelection
{
  LegacySelection({required this.colors});
  final Map<CoordinateSetI, ColorReference?> colors;
  bool contains({required final CoordinateSetI coord}) => colors.containsKey(coord);
  ColorReference? getColorReference({required final CoordinateSetI coord}) => colors[coord];
}

/// The map-based layer effects as they were before phase 5 of
/// docs/dev/pixel_storage_plan.md, kept as the reference the grid
/// implementation is checked against.
///
/// The method bodies are the original ones from DrawingLayerSettings. Only the
/// places that reached into other layers, the layer itself, the selection and
/// the canvas take their answers from the constructor arguments instead.
class LegacyLayerEffects
{
  LegacyLayerEffects({required this.settings, required this.colorBelow});

  final DrawingLayerSettings settings;

  /// What the original `_getColorReferenceAtPos` found in the layers below.
  final ColorReference? Function(CoordinateSetI coord, bool withSettingsPixels) colorBelow;

  ValueNotifier<OuterStrokeStyle> get outerStrokeStyle => settings.outerStrokeStyle;
  ValueNotifier<HashMap<Alignment, bool>> get outerSelectionMap => settings.outerSelectionMap;
  ValueNotifier<ColorReference> get outerColorReference => settings.outerColorReference;
  ValueNotifier<int> get outerDarkenBrighten => settings.outerDarkenBrighten;
  ValueNotifier<int> get outerGlowDepth => settings.outerGlowDepth;
  ValueNotifier<bool> get outerGlowRecursive => settings.outerGlowRecursive;
  ValueNotifier<InnerStrokeStyle> get innerStrokeStyle => settings.innerStrokeStyle;
  ValueNotifier<HashMap<Alignment, bool>> get innerSelectionMap => settings.innerSelectionMap;
  ValueNotifier<ColorReference> get innerColorReference => settings.innerColorReference;
  ValueNotifier<int> get innerDarkenBrighten => settings.innerDarkenBrighten;
  ValueNotifier<int> get innerGlowDepth => settings.innerGlowDepth;
  ValueNotifier<bool> get innerGlowRecursive => settings.innerGlowRecursive;
  ValueNotifier<int> get bevelDistance => settings.bevelDistance;
  ValueNotifier<int> get bevelStrength => settings.bevelStrength;
  ValueNotifier<DropShadowStyle> get dropShadowStyle => settings.dropShadowStyle;
  ValueNotifier<ColorReference> get dropShadowColorReference => settings.dropShadowColorReference;
  ValueNotifier<CoordinateSetI> get dropShadowOffset => settings.dropShadowOffset;
  ValueNotifier<int> get dropShadowDarkenBrighten => settings.dropShadowDarkenBrighten;

  CoordinateColorMap getSettingsPixels({required final CoordinateColorMap data, required final LegacyLayer layerState, required final List<Object> layerList, required final CoordinateSetI canvasSize, required final LegacySelection? selectionList})
  {
    final CoordinateColorMap shadowPixels = getDropShadowPixels(layerState: layerState, layers: layerList, data: data, canvasSize: canvasSize);
    final CoordinateColorMap outerPixels = getOuterStrokePixels(layerState: layerState, layers: layerList, data: data, canvasSize: canvasSize);
    final CoordinateColorMap innerPixels = getInnerStrokePixels(layerState: layerState, layers: layerList, data: data, canvasSize: canvasSize, selectionList: selectionList);

    shadowPixels.addAll(outerPixels);
    shadowPixels.addAll(innerPixels);
    return shadowPixels;
  }

  HashMap<CoordinateSetI, int> getOuterShadingPixels({required final CoordinateColorMap data, required final CoordinateSetI canvasSize}) {
    final ({CoordinateSetI canvasSize}) canvasState = (canvasSize: canvasSize);
    final HashMap<CoordinateSetI, int> dropShadowPixels = HashMap<CoordinateSetI, int>();
    final HashMap<CoordinateSetI, int> outerEffectPixels = HashMap<CoordinateSetI, int>();

    if (dropShadowStyle.value == DropShadowStyle.shade) {
      final Set<CoordinateSetI> dropShadowCoordinates = _getDropShadowCoordinates(
          dataPositions: data.keys, offset: dropShadowOffset.value, canvasSize: canvasState.canvasSize,);
      for (final CoordinateSetI coord in dropShadowCoordinates) {
        dropShadowPixels[coord] = dropShadowDarkenBrighten.value;
      }
    }

    if (outerStrokeStyle.value == OuterStrokeStyle.shade) {
      final HashMap<CoordinateSetI, CoordinateSetI> outerStrokePixelsWithReference =
      _getOuterStrokePixelsWithReference(
          selectionMap: outerSelectionMap.value, dataPositions: data.keys, canvasSize: canvasState.canvasSize,);
      for (final MapEntry<CoordinateSetI, CoordinateSetI> pixelSet in outerStrokePixelsWithReference.entries) {
        outerEffectPixels[pixelSet.key] = outerDarkenBrighten.value;
      }
    } else if (outerStrokeStyle.value == OuterStrokeStyle.glow) {
      Set<CoordinateSetI> currentLayerEdge = Set<CoordinateSetI>.from(data.keys);
      final Set<CoordinateSetI> allProcessedGlowPixels = <CoordinateSetI>{};
      allProcessedGlowPixels.addAll(data.keys); // Assuming glow is strictly OUTSIDE original data

      int lastIterationHighestSelfGlowAmount = 100000;

      for (int i = 0; i < outerGlowDepth.value.abs(); i++) {
        if (currentLayerEdge.isEmpty) {
          break;
        }

        final HashMap<CoordinateSetI, int> newPotentialGlowPixels =
        _getOuterStrokePixelsWithAmount(
            selectionMap: outerSelectionMap.value,
            dataPositions: currentLayerEdge,
            canvasSize: canvasState.canvasSize,);

        final Set<CoordinateSetI> nextLayerEdgeCandidates = <CoordinateSetI>{};
        int currentIterationHighestSelfGlowAmount = 0;

        for (final MapEntry<CoordinateSetI, int> glowEntry in newPotentialGlowPixels.entries) {
          final CoordinateSetI pixelCoord = glowEntry.key;
          final int baseAmount = glowEntry.value;

          if (!allProcessedGlowPixels.contains(pixelCoord)) {
            int selfGlowAmount = 0;
            if (outerGlowRecursive.value) {
              selfGlowAmount = min(baseAmount - 1 < 0 ? 0 : baseAmount - 1, lastIterationHighestSelfGlowAmount);
              currentIterationHighestSelfGlowAmount = max(currentIterationHighestSelfGlowAmount, selfGlowAmount);
            }

            final int steps = outerGlowDepth.value > 0
                ? outerGlowDepth.value - i + selfGlowAmount
                : outerGlowDepth.value + i - selfGlowAmount;

            outerEffectPixels[pixelCoord] = steps;

            nextLayerEdgeCandidates.add(pixelCoord);
            allProcessedGlowPixels.add(pixelCoord);
          }
        }

        currentLayerEdge = nextLayerEdgeCandidates;
        if (outerGlowRecursive.value) {
          lastIterationHighestSelfGlowAmount = currentIterationHighestSelfGlowAmount;
        }
        if (currentLayerEdge.isEmpty) {
          break;
        }
      }
    }

    dropShadowPixels.addAll(outerEffectPixels);
    return dropShadowPixels;
  }

  CoordinateColorMap getDropShadowPixels({required final CoordinateColorMap data, required final LegacyLayer layerState, required final CoordinateSetI canvasSize, required final List<Object> layers})
  {
    final CoordinateColorMap shadowPixels = CoordinateColorMap();
    if (dropShadowStyle.value != DropShadowStyle.off)
    {
      final Set<CoordinateSetI> dropShadowOriginCoordinates = <CoordinateSetI>{};
      dropShadowOriginCoordinates.addAll(data.keys);

      if (outerStrokeStyle.value == OuterStrokeStyle.relative || outerStrokeStyle.value == OuterStrokeStyle.solid)
      {
        final Iterable<CoordinateSetI> outerPixels = _getOuterStrokePixelsWithReference(selectionMap: outerSelectionMap.value, dataPositions: data.keys, canvasSize: canvasSize).keys;
        dropShadowOriginCoordinates.addAll(outerPixels);
      }
      final Set<CoordinateSetI> dropShadowCoordinates = _getDropShadowCoordinates(dataPositions: dropShadowOriginCoordinates, offset: dropShadowOffset.value, canvasSize: canvasSize);

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

  CoordinateColorMap getOuterStrokePixels({required final CoordinateColorMap data, required final LegacyLayer layerState, required final CoordinateSetI canvasSize, required final List<Object> layers})
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

  CoordinateColorMap getInnerStrokePixels({required final CoordinateColorMap data, required final LegacyLayer layerState, required final CoordinateSetI canvasSize, required final List<Object> layers, required final LegacySelection? selectionList})
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
            canvasSize.contains(coord: surroundEntry.value) &&
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
            canvasSize.contains(coord: surroundEntry.value))
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

  //the walk through the layers below is not part of what phase 5 rewrote, so
  //both implementations get it from the same callback
  ColorReference? _getColorReferenceAtPos({required final CoordinateSetI coord, required final List<Object> layers, required final LegacyLayer layerState, final bool withSettingsPixels = false})
  {
    return colorBelow(coord, withSettingsPixels);
  }

  static Set<CoordinateSetI> _getDropShadowCoordinates({required final Iterable<CoordinateSetI> dataPositions, required final CoordinateSetI offset, required final CoordinateSetI canvasSize})
  {
    final Set<CoordinateSetI> coords = <CoordinateSetI>{};
    for (final CoordinateSetI dataCoord in dataPositions)
    {
      final CoordinateSetI coord = CoordinateSetI(x: dataCoord.x + offset.x, y: dataCoord.y + offset.y);
      if (!dataPositions.contains(coord) && canvasSize.contains(coord: coord))
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
}
