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
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/models/app_state.dart';
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
  final bool glowDirectionDefault;
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
    required this.glowDirectionDefault,
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


class DrawingLayerSettings with ChangeNotifier {
  final DrawingLayerSettingsConstraints constraints;

  final ValueNotifier<OuterStrokeStyle> outerStrokeStyle;
  final ValueNotifier<HashMap<Alignment, bool>> outerSelectionMap;
  final ValueNotifier<ColorReference> outerColorReference;
  final ValueNotifier<int> outerDarkenBrighten;
  final ValueNotifier<int> outerGlowDepth;
  final ValueNotifier<bool> outerGlowDirection;

  final ValueNotifier<InnerStrokeStyle> innerStrokeStyle;
  final ValueNotifier<HashMap<Alignment, bool>> innerSelectionMap;
  final ValueNotifier<ColorReference> innerColorReference;
  final ValueNotifier<int> innerDarkenBrighten;
  final ValueNotifier<int> innerGlowDepth;
  final ValueNotifier<bool> innerGlowDirection;
  final ValueNotifier<int> bevelDistance;
  final ValueNotifier<int> bevelStrength;

  final ValueNotifier<DropShadowStyle> dropShadowStyle;
  final ValueNotifier<ColorReference> dropShadowColorReference;
  final ValueNotifier<CoordinateSetI> dropShadowOffset;
  final ValueNotifier<int> dropShadowDarkenBrighten;
  bool editStarted = false;
  bool hasChanges = false;

  DrawingLayerSettings({
    required this.constraints,
    required final OuterStrokeStyle outerStrokeStyle,
    required final HashMap<Alignment, bool> outerSelectionMap,
    required final ColorReference outerColorReference,
    required final int outerDarkenBrighten,
    required final int outerGlowDepth,
    required final bool outerGlowDirection,
    required final InnerStrokeStyle innerStrokeStyle,
    required final HashMap<Alignment, bool> innerSelectionMap,
    required final ColorReference innerColorReference,
    required final int innerDarkenBrighten,
    required final int innerGlowDepth,
    required final bool innerGlowDirection,
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
        outerGlowDirection = ValueNotifier<bool>(outerGlowDirection),
        innerGlowDirection = ValueNotifier<bool>(innerGlowDirection)
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
    outerGlowDirection = ValueNotifier<bool>(constraints.glowDirectionDefault),
    innerGlowDirection = ValueNotifier<bool>(constraints.glowDirectionDefault)
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
        outerGlowDirection = ValueNotifier<bool>(other.outerGlowDirection.value),
        innerGlowDirection = ValueNotifier<bool>(other.innerGlowDirection.value)
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

    outerStrokeStyle.addListener(_valueChanged);
    innerStrokeStyle.addListener(_valueChanged);
    dropShadowStyle.addListener(_valueChanged);
    outerSelectionMap.addListener(_valueChanged);
    innerSelectionMap.addListener(_valueChanged);
    outerColorReference.addListener(_valueChanged);
    innerColorReference.addListener(_valueChanged);
    dropShadowColorReference.addListener(_valueChanged);
    dropShadowOffset.addListener(_valueChanged);
    outerDarkenBrighten.addListener(_valueChanged);
    outerGlowDepth.addListener(_valueChanged);
    innerDarkenBrighten.addListener(_valueChanged);
    innerGlowDepth.addListener(_valueChanged);
    bevelDistance.addListener(_valueChanged);
    bevelStrength.addListener(_valueChanged);
    dropShadowDarkenBrighten.addListener(_valueChanged);
    outerGlowDirection.addListener(_valueChanged);
    innerGlowDirection.addListener(_valueChanged);
  }

  void _valueChanged()
  {
    if (editStarted)
    {
      hasChanges = true;
    }

    notifyListeners();
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
    final CoordinateColorMap shadowPixels = getDropShadowPixels(layerState: layerState, appState: appState, data: data);
    final CoordinateColorMap outerPixels = getOuterStrokePixels(layerState: layerState, appState: appState, data: data);
    final CoordinateColorMap innerPixels = getInnerStrokePixels(layerState: layerState, appState: appState, data: data);

    shadowPixels.addAll(outerPixels);
    shadowPixels.addAll(innerPixels);
    return shadowPixels;
  }

  CoordinateColorMap getDropShadowPixels({required final CoordinateColorMap data, required final DrawingLayerState layerState, required final AppState appState})
  {
    final CoordinateColorMap shadowPixels = CoordinateColorMap();
    if (dropShadowStyle.value != DropShadowStyle.off)
    {
      final Set<CoordinateSetI> dropShadowCoordinates = _getDropShadowCoordinates(dataPositions: data.keys, offset: dropShadowOffset.value, canvasSize: appState.canvasSize);
      for (final CoordinateSetI coord in dropShadowCoordinates)
      {
        if (dropShadowStyle.value == DropShadowStyle.solid)
        {
          shadowPixels[coord] = dropShadowColorReference.value;
        }
        else if (dropShadowStyle.value == DropShadowStyle.shade)
        {
          final ColorReference? currentColor = _getColorReferenceAtPos(coord: coord, appState: appState, layerState: layerState);
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

  CoordinateColorMap getOuterStrokePixels({required final CoordinateColorMap data, required final DrawingLayerState layerState, required final AppState appState})
  {
    final CoordinateColorMap outerPixels = CoordinateColorMap();
    if (outerStrokeStyle.value != OuterStrokeStyle.off)
    {
      final HashMap<CoordinateSetI, CoordinateSetI> outerStrokePixelsWithReference = _getOuterStrokePixelsWithReference(selectionMap: outerSelectionMap.value, dataPositions: data.keys, canvasSize: appState.canvasSize);
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
          final ColorReference? currentColor = _getColorReferenceAtPos(coord: pixelSet.key, appState: appState, layerState: layerState);
          if (currentColor != null)
          {
            final KPalRampData currentRamp = currentColor.ramp;
            final int rampIndex = (currentColor.colorIndex + outerDarkenBrighten.value).clamp(0, currentRamp.references.length - 1);
            outerPixels[pixelSet.key] = currentRamp.references[rampIndex];
          }
        }
        else if (outerStrokeStyle.value == OuterStrokeStyle.glow)
        {
          final ColorReference? currentColor = _getColorReferenceAtPos(coord: pixelSet.key, appState: appState, layerState: layerState);
          if (currentColor != null)
          {
            final KPalRampData currentRamp = currentColor.ramp;
            final int steps = outerGlowDirection.value ? outerGlowDepth.value : -outerGlowDepth.value;
            final int rampIndex = (currentColor.colorIndex + steps).clamp(0, currentRamp.references.length - 1);
            outerPixels[pixelSet.key] = currentRamp.references[rampIndex];
          }
        }
      }

      if (outerStrokeStyle.value == OuterStrokeStyle.glow)
      {
        for (int i = 1; i < outerGlowDepth.value; i++)
        {
          final Set<CoordinateSetI> setPixels = <CoordinateSetI>{};
          setPixels.addAll(data.keys);
          setPixels.addAll(outerPixels.keys);
          final HashMap<CoordinateSetI, CoordinateSetI> glowPixels = _getOuterStrokePixelsWithReference(selectionMap: outerSelectionMap.value, dataPositions: setPixels, canvasSize: appState.canvasSize);
          for (final CoordinateSetI glowPixel in glowPixels.keys)
          {
            final ColorReference? currentColor = _getColorReferenceAtPos(coord: glowPixel, appState: appState, layerState: layerState);
            if (currentColor != null)
            {
              final KPalRampData currentRamp = currentColor.ramp;
              final int steps = outerGlowDirection.value ? outerGlowDepth.value - i : -outerGlowDepth.value + i;
              final int rampIndex = (currentColor.colorIndex + steps).clamp(0, currentRamp.references.length - 1);
              outerPixels[glowPixel] = currentRamp.references[rampIndex];
            }
          }
        }
      }

    }
    return outerPixels;
  }

  CoordinateColorMap getInnerStrokePixels({required final CoordinateColorMap data, required final DrawingLayerState layerState, required final AppState appState})
  {
    final CoordinateColorMap innerPixels = CoordinateColorMap();
    if (innerStrokeStyle.value != InnerStrokeStyle.off)
    {
      final Set<CoordinateSetI> innerStrokePixels = _getInnerStrokeCoordinates(selectionMap: innerSelectionMap.value, data: data, canvasSize: appState.canvasSize);
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
            final ColorReference? currentColor = layerState.getDataEntry(coord: coord);
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
        final CoordinateColorMap dataPixels = CoordinateColorMap();
        dataPixels.addAll(data);
        for (int i = 0; i < innerGlowDepth.value; i++)
        {
          final Set<CoordinateSetI> innerStrokePixels = _getInnerStrokeCoordinates(selectionMap: innerSelectionMap.value, data: dataPixels, canvasSize: appState.canvasSize);
          for (final CoordinateSetI coord in innerStrokePixels)
          {
            final ColorReference? currentColor = layerState.getDataEntry(coord: coord);
            if (currentColor != null)
            {
              final KPalRampData currentRamp = currentColor.ramp;
              final int steps = innerGlowDirection.value ? innerGlowDepth.value - i : -innerGlowDepth.value + i;
              final int rampIndex = (currentColor.colorIndex + steps).clamp(0, currentRamp.references.length - 1);
              innerPixels[coord] = currentRamp.references[rampIndex];
            }
            dataPixels.remove(coord);
          }
        }
      }
      else if (innerStrokeStyle.value == InnerStrokeStyle.bevel)
      {
        final HashMap<Alignment, bool> oppositeSelectionMap = HashMap<Alignment, bool>();
        final HashMap<Alignment, bool> allDirectionsMap = HashMap<Alignment, bool>();
        for (final Alignment alignment in allAlignments)
        {
          oppositeSelectionMap[alignment] = false;
          allDirectionsMap[alignment] = true;
        }
        for (final MapEntry<Alignment, bool> entry in innerSelectionMap.value.entries)
        {
          if (entry.value == true)
          {
            oppositeSelectionMap[entry.key] = true;
            oppositeSelectionMap[_getOppositeAlignment(alignment: entry.key)] = true;
            break;
          }
        }

        final CoordinateColorMap dataPixels = CoordinateColorMap();
        dataPixels.addAll(data);
        for (int i = 0; i < bevelDistance.value; i++)
        {

          if (i == bevelDistance.value - 1)
          {
            final Set<CoordinateSetI> oppositeStrokePixels = _getInnerStrokeCoordinates(selectionMap: oppositeSelectionMap, data: dataPixels, canvasSize: appState.canvasSize);
            final Set<CoordinateSetI> directionPixels = _getInnerStrokeCoordinates(selectionMap: innerSelectionMap.value, data: dataPixels, canvasSize: appState.canvasSize);
            oppositeStrokePixels.removeAll(directionPixels);

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
            final Set<CoordinateSetI> oppositeStrokePixels = _getInnerStrokeCoordinates(selectionMap: allDirectionsMap, data: dataPixels, canvasSize: appState.canvasSize);
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

  static ColorReference? _getColorReferenceAtPos({required final CoordinateSetI coord, required final AppState appState, required final DrawingLayerState layerState, final bool withSettingsPixels = false})
  {
    ColorReference? currentColor;
    int colorShift = 0;
    final int currentIndex = appState.getLayerPosition(state: layerState);

    if (currentIndex != -1)
    {
      for (int i = appState.layerCount - 1; i >= currentIndex; i--)
      {
        final LayerState layer = appState.getLayerAt(index: i);
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

  Alignment _getOppositeAlignment({required final Alignment alignment})
  {
    if (alignment == Alignment.topLeft) {return Alignment.bottomRight;}
    else if (alignment == Alignment.topCenter) {return Alignment.bottomCenter;}
    else if (alignment == Alignment.topLeft) {return Alignment.bottomRight;}
    else if (alignment == Alignment.centerRight) {return Alignment.centerLeft;}
    else if (alignment == Alignment.bottomRight) {return Alignment.topLeft;}
    else if (alignment == Alignment.bottomCenter) {return Alignment.topCenter;}
    else if (alignment == Alignment.bottomLeft) {return Alignment.topRight;}
    else if (alignment == Alignment.centerLeft) {return Alignment.centerRight;}
    else {return Alignment.center;}
  }


}
