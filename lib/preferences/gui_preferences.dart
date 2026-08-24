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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/preferences/preference_gui.dart';
import 'package:kpix/util/color_names.dart';

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

  void update({required final int themeTypeValue, required final int rasterSizeValue, required final int rasterContrast, required final int colorNameSchemeValue, required final int canvasBorderOpacityValue, required final int selectionOpacityValue, required final int toolOpacityValue})
  {
    themeType.value = themeTypeIndexMap[themeTypeValue]?? ThemeMode.system;
    rasterSizeIndex.value = max(rasterSizes.indexOf(rasterSizeValue), 0);
    this.rasterContrast.value = rasterContrast.clamp(rasterContrastMin, rasterContrastMax);
    colorNameScheme.value = ColorNameScheme.fromId(colorNameSchemeValue);
    canvasBorderOpacity.value = canvasBorderOpacityValue.clamp(opacityMin, opacityMax);
    selectionOpacity.value = selectionOpacityValue.clamp(opacityMin, opacityMax);
    toolOpacity.value = toolOpacityValue.clamp(opacityMin, opacityMax);
  }
}

class GuiPreferences extends StatefulWidget
{
  final GuiPreferenceContent prefs;
  const GuiPreferences({super.key, required this.prefs});
  double get itemPadding => 12.0;

  @override
  State<GuiPreferences> createState() => _GuiPreferencesState();
}

class _GuiPreferencesState extends State<GuiPreferences>
{
  @override
  Widget build(final BuildContext context)
  {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Theme Preferences", style: Theme.of(context).textTheme.titleLarge),
          PrefSegmentedButtonRow<ThemeMode>(
              label: "Theme",
              notifier: widget.prefs.themeType,
              labels: themeTypeStringMap,
          ),

          SizedBox(height: widget.itemPadding),

          Text("Raster Preferences", style: Theme.of(context).textTheme.titleLarge),
          PrefSliderRowIndexed(
              text: "Raster Size",
              valueList: rasterSizes,
              notifier: widget.prefs.rasterSizeIndex,
          ),
          PrefSliderRow<int>(
              text: "Raster Contrast",
              notifier: widget.prefs.rasterContrast,
              minVal: rasterContrastMin.toDouble(),
              maxVal: rasterContrastMax.toDouble(),
          ),

          SizedBox(height: widget.itemPadding),

          Text("Palette Preferences", style: Theme.of(context).textTheme.titleLarge),
          PrefSegmentedButtonRow<ColorNameScheme>(
            label: "Color Naming",
            notifier: widget.prefs.colorNameScheme,
            labels: ColorNameScheme.getNameMap(),
            buttonTextStyle: Theme.of(context).textTheme.bodySmall,
          ),

          SizedBox(height: widget.itemPadding),

          Text("Border Preferences", style: Theme.of(context).textTheme.titleLarge),
          PrefSliderRow<int>(
              text: "Tool Outline Opacity",
              minVal: opacityMin.toDouble(),
              maxVal: opacityMax.toDouble(),
              notifier: widget.prefs.toolOpacity,
          ),
          PrefSliderRow<int>(
              text: "Selection Outline Opacity",
              minVal: opacityMin.toDouble(),
              maxVal: opacityMax.toDouble(),
              notifier: widget.prefs.selectionOpacity,
          ),
          PrefSliderRow<int>(
            text: "Canvas Border Opacity",
            minVal: opacityMin.toDouble(),
            maxVal: opacityMax.toDouble(),
            notifier: widget.prefs.canvasBorderOpacity,
          ),
        ],
      ),
    );
  }
}
