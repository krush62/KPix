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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/color_names.dart';

class StylusPreferenceContent
{
  final ValueNotifier<int> stylusLongPressDelay;
  final ValueNotifier<double> stylusLongPressCancelDistance;
  final ValueNotifier<double> stylusZoomStepDistance;
  final ValueNotifier<double> stylusSizeStepDistance;
  final ValueNotifier<int> stylusPollInterval;
  final ValueNotifier<int> stylusPickMaxDuration;
  final int stylusLongPressDelayMin;
  final int stylusLongPressDelayMax;
  final double stylusLongPressCancelDistanceMin;
  final double stylusLongPressCancelDistanceMax;
  final double stylusZoomStepDistanceMin;
  final double stylusZoomStepDistanceMax;
  final double stylusSizeStepDistanceMin;
  final double stylusSizeStepDistanceMax;
  final int stylusPollIntervalMin;
  final int stylusPollIntervalMax;
  final int stylusPickMaxDurationMin;
  final int stylusPickMaxDurationMax;

  factory StylusPreferenceContent({
    required final int stylusLongPressDelay,
    required final int stylusLongPressDelayMin,
    required final int stylusLongPressDelayMax,
    required final double stylusLongPressCancelDistance,
    required final double stylusLongPressCancelDistanceMin,
    required final double stylusLongPressCancelDistanceMax,
    required final double stylusZoomStepDistance,
    required final double stylusZoomStepDistanceMin,
    required final double stylusZoomStepDistanceMax,
    required final double stylusSizeStepDistance,
    required final double stylusSizeStepDistanceMin,
    required final double stylusSizeStepDistanceMax,
    required final int stylusPollInterval,
    required final int stylusPollIntervalMin,
    required final int stylusPollIntervalMax,
    required final int stylusPickMaxDuration,
    required final int stylusPickMaxDurationMin,
    required final int stylusPickMaxDurationMax,
  })
  {
    return StylusPreferenceContent._(
      stylusLongPressCancelDistance: ValueNotifier<double>(stylusLongPressCancelDistance.clamp(stylusLongPressCancelDistanceMin, stylusLongPressCancelDistanceMax)),
      stylusLongPressCancelDistanceMin: stylusLongPressCancelDistanceMin,
      stylusLongPressCancelDistanceMax: stylusLongPressCancelDistanceMax,
      stylusLongPressDelay: ValueNotifier<int>(stylusLongPressDelay.clamp(stylusLongPressDelayMin, stylusLongPressDelayMax)),
      stylusLongPressDelayMin: stylusLongPressDelayMin,
      stylusLongPressDelayMax: stylusLongPressDelayMax,
      stylusPollInterval: ValueNotifier<int>(stylusPollInterval.clamp(stylusPollIntervalMin, stylusPollIntervalMax)),
      stylusPollIntervalMin: stylusPollIntervalMin,
      stylusPollIntervalMax: stylusPollIntervalMax,
      stylusSizeStepDistance: ValueNotifier<double>(stylusSizeStepDistance.clamp(stylusSizeStepDistanceMin, stylusSizeStepDistanceMax)),
      stylusSizeStepDistanceMin: stylusSizeStepDistanceMin,
      stylusSizeStepDistanceMax: stylusSizeStepDistanceMax,
      stylusZoomStepDistance: ValueNotifier<double>(stylusZoomStepDistance.clamp(stylusZoomStepDistanceMin, stylusZoomStepDistanceMax)),
      stylusZoomStepDistanceMin: stylusZoomStepDistanceMin,
      stylusZoomStepDistanceMax: stylusZoomStepDistanceMax,
      stylusPickMaxDuration: ValueNotifier<int>(stylusPickMaxDuration.clamp(stylusPickMaxDurationMin, stylusPickMaxDurationMax)),
      stylusPickMaxDurationMin: stylusPickMaxDurationMin,
      stylusPickMaxDurationMax: stylusLongPressDelayMax,
    );
  }

  StylusPreferenceContent._({
    required this.stylusLongPressDelay,
    required this.stylusLongPressCancelDistance,
    required this.stylusZoomStepDistance,
    required this.stylusSizeStepDistance,
    required this.stylusPollInterval,
    required this.stylusPickMaxDuration,
    required this.stylusLongPressDelayMin,
    required this.stylusLongPressDelayMax,
    required this.stylusLongPressCancelDistanceMin,
    required this.stylusLongPressCancelDistanceMax,
    required this.stylusZoomStepDistanceMin,
    required this.stylusZoomStepDistanceMax,
    required this.stylusSizeStepDistanceMin,
    required this.stylusSizeStepDistanceMax,
    required this.stylusPollIntervalMin,
    required this.stylusPollIntervalMax,
    required this.stylusPickMaxDurationMin,
    required this.stylusPickMaxDurationMax,});
}

class TouchPreferenceContent
{
  final ValueNotifier<double> zoomStepDistance;
  final ValueNotifier<int> singleTouchDelay;

  final double zoomStepDistanceMin;
  final double zoomStepDistanceMax;
  final int singleTouchDelayMin;
  final int singleTouchDelayMax;

  factory TouchPreferenceContent({
    required final int singleTouchDelay,
    required final int singleTouchDelayMin,
    required final int singleTouchDelayMax,
    required final double zoomStepDistance,
    required final double zoomStepDistanceMin,
    required final double zoomStepDistanceMax,
  })
  {
    return TouchPreferenceContent._(
      singleTouchDelay: ValueNotifier<int>(singleTouchDelay.clamp(singleTouchDelayMin, singleTouchDelayMax)),
      singleTouchDelayMin: singleTouchDelayMin,
      singleTouchDelayMax: singleTouchDelayMax,
      zoomStepDistance: ValueNotifier<double>(zoomStepDistance.clamp(zoomStepDistanceMin, zoomStepDistanceMax)),
      zoomStepDistanceMin: zoomStepDistanceMin,
      zoomStepDistanceMax: zoomStepDistanceMax,
    );
  }

  TouchPreferenceContent._({
    required this.singleTouchDelay,
    required this.singleTouchDelayMin,
    required this.singleTouchDelayMax,
    required this.zoomStepDistance,
    required this.zoomStepDistanceMin,
    required this.zoomStepDistanceMax,
  });
}

//THEME
const Map<int, ThemeMode> themeTypeIndexMap =
<int, ThemeMode>{
  0:ThemeMode.system,
  1:ThemeMode.light,
  2:ThemeMode.dark,
};
const Map<ThemeMode, String> themeTypeStringMap =
<ThemeMode, String>{
  ThemeMode.system:"System",
  ThemeMode.light:"Light",
  ThemeMode.dark:"Dark",
};

//RASTER SIZE
const List<int> rasterSizes = <int>[2, 4, 8, 12, 16, 24, 36, 48, 64];

//RASTER CONTRAST
const int rasterContrastMin = 0;
const int rasterContrastMax = 100;
const int rasterContrastDivisions = 20;

const int opacityMin = 0;
const int opacityMax = 100;


class GuiPreferenceContent
{
  final ValueNotifier<ThemeMode> themeType;
  final ValueNotifier<int> rasterSizeIndex;
  final ValueNotifier<int> rasterContrast;
  final ValueNotifier<int> toolOpacity;
  final ValueNotifier<int> selectionOpacity;
  final ValueNotifier<int> canvasBorderOpacity;
  final ValueNotifier<ColorNameScheme> colorNameScheme;

  factory GuiPreferenceContent({required final int themeTypeValue, required final int rasterSizeValue, required final int rasterContrast, required final int colorNameSchemeValue, required final int canvasBorderOpacityValue, required final int selectionOpacityValue, required final int toolOpacityValue})
  {
    final ThemeMode themeType = themeTypeIndexMap[themeTypeValue]?? ThemeMode.system;
    final int rasterSizeIndex = max(rasterSizes.indexOf(rasterSizeValue), 0);
    final int rasterContrastNormalized = rasterContrast.clamp(rasterContrastMin, rasterContrastMax);
    final ColorNameScheme colorNameScheme = ColorNameScheme.fromId(colorNameSchemeValue);
    final int toolOpacity = toolOpacityValue.clamp(opacityMin, opacityMax);
    final int selectionOpacity = selectionOpacityValue.clamp(opacityMin, opacityMax);
    final int canvasBorderOpacity = canvasBorderOpacityValue.clamp(opacityMin, opacityMax);

    return GuiPreferenceContent._(
      themeType: ValueNotifier<ThemeMode>(themeType),
      rasterSizeIndex: ValueNotifier<int>(rasterSizeIndex),
      rasterContrast: ValueNotifier<int>(rasterContrastNormalized),
      colorNameScheme:ValueNotifier<ColorNameScheme>(colorNameScheme),
      canvasBorderOpacity: ValueNotifier<int>(canvasBorderOpacity),
      selectionOpacity: ValueNotifier<int>(selectionOpacity),
      toolOpacity: ValueNotifier<int>(toolOpacity),
    );
  }

  GuiPreferenceContent._({required this.themeType, required this.rasterSizeIndex, required this.rasterContrast, required this.colorNameScheme, required this.canvasBorderOpacity, required this.selectionOpacity, required this.toolOpacity});

}

enum CursorType
{
  none(0, "None", SystemMouseCursors.none),
  crossHair(1, "CrossHair", SystemMouseCursors.precise),
  arrow(2, "Arrow", SystemMouseCursors.basic);

  final int id;
  final String name;
  final SystemMouseCursor systemCursor;

  const CursorType(this.id, this.name, this.systemCursor);

  static Map<CursorType, String> getNameMap()
  {
    final Map<CursorType, String> map = <CursorType, String>{};
    for (final CursorType curs in CursorType.values) {
      map[curs] = curs.name;
    }
    return map;
  }

  static CursorType fromId(final int id) {
    return CursorType.values.firstWhere((final CursorType curs) => curs.id == id);
  }

}


class DesktopPreferenceContent
{
  final ValueNotifier<CursorType> cursorType;
  factory DesktopPreferenceContent({required final int cursorTypeValue})
  {
    final CursorType cursorType = CursorType.fromId(cursorTypeValue);
    return DesktopPreferenceContent._(cursorType: ValueNotifier<CursorType>(cursorType));
  }

  DesktopPreferenceContent._({required this.cursorType});
}

//UNDO STEPS
const int undoStepsMin = 10;
const int undoStepsMax = 256;

class BehaviorPreferenceContent
{
  final ValueNotifier<int> undoSteps;
  final ValueNotifier<bool> selectShapeAfterInsert;
  final ValueNotifier<bool> selectLayerAfterInsert;
  final ValueNotifier<bool> showReferenceOutsideCanvas;
  final ValueNotifier<int> shadingStepsMinus;
  final ValueNotifier<int> shadingStepsPlus;
  final int undoStepsMax;
  final int undoStepsMin;
  final ShadingLayerSettingsConstraints shadingConstraints;
  final FrameConstraints frameConstraints;
  final ValueNotifier<int> fps;
  final ValueNotifier<bool> useCustomProjectDirectory;
  final ValueNotifier<String> customProjectDirectory;

  factory BehaviorPreferenceContent({required final int undoSteps, required final bool selectAfterInsert, required final bool selectLayerAfterInsert, required final int undoStepsMax, required final int undoStepsMin, required final ShadingLayerSettingsConstraints shadingConstraints, required final FrameConstraints frameConstraints, required final bool showReferenceOutsideCanvas, required final bool useCustomProjectDirectory, required final String customProjectDirectory})
  {
    return BehaviorPreferenceContent._(
      undoSteps: ValueNotifier<int>(undoSteps.clamp(undoStepsMin, undoStepsMax)),
      selectShapeAfterInsert: ValueNotifier<bool>(selectAfterInsert),
      selectLayerAfterInsert: ValueNotifier<bool>(selectLayerAfterInsert),
      frameConstraints: frameConstraints,
      fps: ValueNotifier<int>(frameConstraints.defaultFps),
      shadingStepsMinus: ValueNotifier<int>(shadingConstraints.shadingStepsDefaultDarken),
      shadingStepsPlus: ValueNotifier<int>(shadingConstraints.shadingStepsDefaultBrighten),
      shadingConstraints: shadingConstraints,
      undoStepsMax: undoStepsMax,
      undoStepsMin: undoStepsMin,
      showReferenceOutsideCanvas: ValueNotifier<bool>(showReferenceOutsideCanvas),
      useCustomProjectDirectory: ValueNotifier<bool>(useCustomProjectDirectory),
      customProjectDirectory: ValueNotifier<String>(customProjectDirectory),
    );
  }

  BehaviorPreferenceContent._({required this.undoSteps, required this.selectShapeAfterInsert, required this.selectLayerAfterInsert, required this.undoStepsMax, required this.undoStepsMin, required this.shadingStepsMinus, required this.shadingStepsPlus, required this.shadingConstraints, required this.fps, required this.frameConstraints, required this.showReferenceOutsideCanvas, required this.useCustomProjectDirectory, required this.customProjectDirectory});

}
