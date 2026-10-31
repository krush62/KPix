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
import 'package:kpix/kpix_language.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/frame_constraints.dart';
import 'package:kpix/models/constraints/shading_layer_settings_constraints.dart';
import 'package:kpix/util/color_names.dart';

/// A preference with limits of its own: a notifier that starts out within them.
class RangedPref<T extends num> extends ValueNotifier<T>
{
  final T min;
  final T max;

  RangedPref({required final T value, required this.min, required this.max}) : super(value.clamp(min, max) as T);
}

class StylusPreferenceContent
{
  final RangedPref<int> stylusLongPressDelay;
  final RangedPref<double> stylusLongPressCancelDistance;
  final RangedPref<double> stylusZoomStepDistance;
  final RangedPref<double> stylusSizeStepDistance;
  final RangedPref<int> stylusPickMaxDuration;

  StylusPreferenceContent({
    required this.stylusLongPressDelay,
    required this.stylusLongPressCancelDistance,
    required this.stylusZoomStepDistance,
    required this.stylusSizeStepDistance,
    required this.stylusPickMaxDuration,
  });

  void copyValuesFrom({required final StylusPreferenceContent other})
  {
    stylusLongPressDelay.value = other.stylusLongPressDelay.value;
    stylusLongPressCancelDistance.value = other.stylusLongPressCancelDistance.value;
    stylusZoomStepDistance.value = other.stylusZoomStepDistance.value;
    stylusSizeStepDistance.value = other.stylusSizeStepDistance.value;
    stylusPickMaxDuration.value = other.stylusPickMaxDuration.value;
  }
}

class TouchPreferenceContent
{
  final RangedPref<double> zoomStepDistance;
  final RangedPref<int> singleTouchDelay;
  final ValueNotifier<bool> showJoysticks;

  factory TouchPreferenceContent({
    required final RangedPref<int> singleTouchDelay,
    required final RangedPref<double> zoomStepDistance,
    required final bool showJoysticks,
  })
  {
    return TouchPreferenceContent._(
      singleTouchDelay: singleTouchDelay,
      zoomStepDistance: zoomStepDistance,
      showJoysticks: ValueNotifier<bool>(showJoysticks),
    );
  }

  TouchPreferenceContent._({
    required this.singleTouchDelay,
    required this.zoomStepDistance,
    required this.showJoysticks,
  });

  void copyValuesFrom({required final TouchPreferenceContent other})
  {
    singleTouchDelay.value = other.singleTouchDelay.value;
    zoomStepDistance.value = other.zoomStepDistance.value;
    showJoysticks.value = other.showJoysticks.value;
  }
}

//THEME
const Map<int, ThemeMode> themeTypeIndexMap =
<int, ThemeMode>{
  0:ThemeMode.system,
  1:ThemeMode.light,
  2:ThemeMode.dark,
};

extension ThemeModeLocalization on ThemeMode {
  String themeName(final AppLocalizations l10n) => switch (this) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };
}

Map<ThemeMode, String> themeTypeStringMap(final AppLocalizations l10n)
{
  final Map<ThemeMode, String> map = <ThemeMode, String>{};
  for (final ThemeMode mode in ThemeMode.values)
  {
    map[mode] = mode.themeName(l10n);
  }
  return map;
}


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
  final ValueNotifier<bool> selectionPulsatingOutline;
  final ValueNotifier<bool> showCursorInfo;
  final ValueNotifier<bool> cursorInfoRight;
  final ValueNotifier<int> canvasBorderOpacity;
  final ValueNotifier<ColorNameScheme> colorNameScheme;
  final ValueNotifier<String> language;

  factory GuiPreferenceContent({required final int themeTypeValue, required final int rasterSizeValue, required final int rasterContrast, required final int colorNameSchemeValue, required final int canvasBorderOpacityValue, required final int selectionOpacityValue, required final bool selectionPulsatingValue, required final bool showCursorInfoValue, required final bool cursorInfoRightValue, required final int toolOpacityValue, required final String languageValue})
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
      selectionPulsatingOutline: ValueNotifier<bool>(selectionPulsatingValue),
      showCursorInfo: ValueNotifier<bool>(showCursorInfoValue),
      cursorInfoRight: ValueNotifier<bool>(cursorInfoRightValue),
      toolOpacity: ValueNotifier<int>(toolOpacity),
      language: ValueNotifier<String>(isSupportedLanguage(languageCode: languageValue) ? languageValue : systemLanguageCode),
    );
  }

  GuiPreferenceContent._({required this.themeType, required this.rasterSizeIndex, required this.rasterContrast, required this.colorNameScheme, required this.canvasBorderOpacity, required this.selectionOpacity, required this.selectionPulsatingOutline, required this.showCursorInfo, required this.cursorInfoRight, required this.toolOpacity, required this.language});

  void copyValuesFrom({required final GuiPreferenceContent other})
  {
    themeType.value = other.themeType.value;
    rasterSizeIndex.value = other.rasterSizeIndex.value;
    rasterContrast.value = other.rasterContrast.value;
    colorNameScheme.value = other.colorNameScheme.value;
    canvasBorderOpacity.value = other.canvasBorderOpacity.value;
    selectionOpacity.value = other.selectionOpacity.value;
    selectionPulsatingOutline.value = other.selectionPulsatingOutline.value;
    showCursorInfo.value = other.showCursorInfo.value;
    cursorInfoRight.value = other.cursorInfoRight.value;
    toolOpacity.value = other.toolOpacity.value;
    language.value = other.language.value;
  }
}

enum CursorType
{
  none(0, SystemMouseCursors.none),
  crossHair(1, SystemMouseCursors.precise),
  arrow(2, SystemMouseCursors.basic);

  final int id;
  final SystemMouseCursor systemCursor;

  const CursorType(this.id, this.systemCursor);

  String label(final AppLocalizations l10n) => switch(this)
  {
    none => l10n.cursorNone,
    crossHair => l10n.cursorCrosshair,
    arrow => l10n.cursorArrow,
  };

  static Map<CursorType, String> getNameMap(final AppLocalizations l10n)
  {
    final Map<CursorType, String> map = <CursorType, String>{};
    for (final CursorType curs in CursorType.values) {
      map[curs] = curs.label(l10n);
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

  void copyValuesFrom({required final DesktopPreferenceContent other})
  {
    cursorType.value = other.cursorType.value;
  }
}

class BehaviorPreferenceContent
{
  final RangedPref<int> undoSteps;
  final ValueNotifier<bool> selectShapeAfterInsert;
  final ValueNotifier<bool> selectLayerAfterInsert;
  final ValueNotifier<bool> selectToolAfterPaste;
  final ValueNotifier<bool> showReferenceOutsideCanvas;
  final ValueNotifier<int> shadingStepsMinus;
  final ValueNotifier<int> shadingStepsPlus;
  final ShadingLayerSettingsConstraints shadingConstraints;
  final FrameConstraints frameConstraints;
  final ValueNotifier<int> fps;
  final ValueNotifier<bool> useCustomProjectDirectory;
  final ValueNotifier<String> customProjectDirectory;

  factory BehaviorPreferenceContent({required final RangedPref<int> undoSteps, required final bool selectAfterInsert, required final bool selectLayerAfterInsert, required final bool selectToolAfterPaste, required final ShadingLayerSettingsConstraints shadingConstraints, required final FrameConstraints frameConstraints, required final bool showReferenceOutsideCanvas, required final bool useCustomProjectDirectory, required final String customProjectDirectory})
  {
    return BehaviorPreferenceContent._(
      undoSteps: undoSteps,
      selectShapeAfterInsert: ValueNotifier<bool>(selectAfterInsert),
      selectLayerAfterInsert: ValueNotifier<bool>(selectLayerAfterInsert),
      selectToolAfterPaste: ValueNotifier<bool>(selectToolAfterPaste),
      frameConstraints: frameConstraints,
      fps: ValueNotifier<int>(frameConstraints.defaultFps),
      shadingStepsMinus: ValueNotifier<int>(shadingConstraints.shadingStepsDefaultDarken),
      shadingStepsPlus: ValueNotifier<int>(shadingConstraints.shadingStepsDefaultBrighten),
      shadingConstraints: shadingConstraints,
      showReferenceOutsideCanvas: ValueNotifier<bool>(showReferenceOutsideCanvas),
      useCustomProjectDirectory: ValueNotifier<bool>(useCustomProjectDirectory),
      customProjectDirectory: ValueNotifier<String>(customProjectDirectory),
    );
  }

  BehaviorPreferenceContent._({required this.undoSteps, required this.selectShapeAfterInsert, required this.selectLayerAfterInsert, required this.selectToolAfterPaste, required this.shadingStepsMinus, required this.shadingStepsPlus, required this.shadingConstraints, required this.fps, required this.frameConstraints, required this.showReferenceOutsideCanvas, required this.useCustomProjectDirectory, required this.customProjectDirectory});

  void copyValuesFrom({required final BehaviorPreferenceContent other})
  {
    undoSteps.value = other.undoSteps.value;
    selectShapeAfterInsert.value = other.selectShapeAfterInsert.value;
    selectLayerAfterInsert.value = other.selectLayerAfterInsert.value;
    selectToolAfterPaste.value = other.selectToolAfterPaste.value;
    showReferenceOutsideCanvas.value = other.showReferenceOutsideCanvas.value;
    shadingStepsMinus.value = other.shadingStepsMinus.value;
    shadingStepsPlus.value = other.shadingStepsPlus.value;
    fps.value = other.fps.value;
    useCustomProjectDirectory.value = other.useCustomProjectDirectory.value;
    customProjectDirectory.value = other.customProjectDirectory.value;
  }
}
