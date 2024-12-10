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
import 'package:kpix/widgets/controls/kpix_slider.dart';

//THEME
const Map<int, ThemeMode> themeTypeIndexMap =
{
  0:ThemeMode.system,
  1:ThemeMode.light,
  2:ThemeMode.dark
};
const Map<ThemeMode, String> themeTypeStringMap =
{
  ThemeMode.system:"System",
  ThemeMode.light:"Light",
  ThemeMode.dark:"Dark"
};

//RASTER SIZE
const List<int> rasterSizes = [2, 4, 8, 12, 16, 24, 36, 48, 64];

//RASTER CONTRAST
const int rasterContrastMin = 0;
const int rasterContrastMax = 100;
const int rasterContrastDivisions = 20;

const int opacityMin = 0;
const int opacityMax = 100;

//COLOR NAME SCHEME
enum ColorNameScheme
{
  general,
  pms,
  ralClassic,
  ralDsp,
  ralComplete
}
const Map<int, ColorNameScheme> colorNameSchemeIndexMap =
{
  0:ColorNameScheme.general,
  1:ColorNameScheme.pms,
  2:ColorNameScheme.ralClassic,
  3:ColorNameScheme.ralDsp,
  4:ColorNameScheme.ralComplete
};
const Map<ColorNameScheme, String> colorNameSchemeStringMap =
{
  ColorNameScheme.general:"General",
  ColorNameScheme.pms:"PMS",
  ColorNameScheme.ralClassic:"RAL Classic",
  ColorNameScheme.ralDsp:"RAL DSP",
  ColorNameScheme.ralComplete:"RAL Complete"
};



class GuiPreferenceContent
{
  final ValueNotifier<ThemeMode> themeType;
  final ValueNotifier<int> rasterSizeIndex;
  final ValueNotifier<int> rasterContrast;
  final ValueNotifier<int> toolOpacity;
  final ValueNotifier<int> selectionOpacity;
  final ValueNotifier<int> canvasBorderOpacity;
  final ValueNotifier<ColorNameScheme> colorNameScheme;

  GuiPreferenceContent._({required this.themeType, required this.rasterSizeIndex, required this.rasterContrast, required this.colorNameScheme, required this.canvasBorderOpacity, required this.selectionOpacity, required this.toolOpacity});

  factory GuiPreferenceContent({required final int themeTypeValue, required final int rasterSizeValue, required final int rasterContrast, required final int colorNameSchemeValue, required int canvasBorderOpacityValue, required int selectionOpacityValue, required int toolOpacityValue})
  {
    final ThemeMode themeType = themeTypeIndexMap[themeTypeValue]?? ThemeMode.system;
    final int rasterSizeIndex = max(rasterSizes.indexOf(rasterSizeValue), 0);
    final int rasterContrastNormalized = rasterContrast.clamp(rasterContrastMin, rasterContrastMax);
    final ColorNameScheme colorNameScheme = colorNameSchemeIndexMap[colorNameSchemeValue]?? ColorNameScheme.general;
    final int toolOpacity = toolOpacityValue.clamp(opacityMin, opacityMax);
    final int selectionOpacity = selectionOpacityValue.clamp(opacityMin, opacityMax);
    final int canvasBorderOpacity = canvasBorderOpacityValue.clamp(opacityMin, opacityMax);

    return GuiPreferenceContent._(
      themeType: ValueNotifier(themeType),
      rasterSizeIndex: ValueNotifier(rasterSizeIndex),
      rasterContrast: ValueNotifier(rasterContrastNormalized),
      colorNameScheme:ValueNotifier(colorNameScheme),
      canvasBorderOpacity: ValueNotifier(canvasBorderOpacity),
      selectionOpacity: ValueNotifier(selectionOpacity),
      toolOpacity: ValueNotifier(toolOpacity)
    );
  }
}


class GuiPreferences extends StatefulWidget
{
  final GuiPreferenceContent prefs;
  const GuiPreferences({super.key, required this.prefs});
  final double itemPadding = 12;

  @override
  State<GuiPreferences> createState() => _GuiPreferencesState();
}

class _GuiPreferencesState extends State<GuiPreferences>
{
  @override
  Widget build(BuildContext context)
  {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Theme Preferences", style: Theme.of(context).textTheme.titleLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Theme", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: widget.prefs.themeType,
                  builder: (final BuildContext context, final ThemeMode theme, final Widget? child)
                  {
                    return SegmentedButton<ThemeMode>(
                      selected: {theme},
                      emptySelectionAllowed: false,
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                      onSelectionChanged: (final Set<ThemeMode> themeList) {widget.prefs.themeType.value = themeList.first;},
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(themeTypeStringMap[ThemeMode.system]!)
                        ),
                        ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(themeTypeStringMap[ThemeMode.light]!)
                        ),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(themeTypeStringMap[ThemeMode.dark]!)
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: widget.itemPadding),
          Text("Raster Preferences", style: Theme.of(context).textTheme.titleLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Raster Size", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.prefs.rasterSizeIndex,
                  builder: (final BuildContext context, final int rasterSizeIndex, final Widget? child)
                  {
                    return KPixSlider(
                      value: rasterSizeIndex.toDouble(),
                      min: 0,
                      max: rasterSizes.length.toDouble() - 1,
                      divisions: rasterSizes.length,
                      label: rasterSizes[rasterSizeIndex].toString(),
                      onChanged: (final double newVal) {widget.prefs.rasterSizeIndex.value = newVal.toInt();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Raster Contrast", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.prefs.rasterContrast,
                  builder: (final BuildContext context, final int rasterContrast, final Widget? child)
                  {
                    return KPixSlider(
                      value: rasterContrast.toDouble(),
                      min: rasterContrastMin.toDouble(),
                      max: rasterContrastMax.toDouble(),
                      divisions: rasterContrastDivisions,
                      onChanged: (final double newVal) {widget.prefs.rasterContrast.value = newVal.toInt();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: widget.itemPadding),
          Text("Palette Preferences", style: Theme.of(context).textTheme.titleLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Color Naming", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<ColorNameScheme>(
                  valueListenable: widget.prefs.colorNameScheme,
                  builder: (final BuildContext context, final ColorNameScheme scheme, final Widget? child)
                  {
                    return SegmentedButton<ColorNameScheme>(
                      selected: {scheme},
                      emptySelectionAllowed: false,
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                      onSelectionChanged: (final Set<ColorNameScheme> schemeList) {widget.prefs.colorNameScheme.value = schemeList.first;},
                      segments: [
                        ButtonSegment(
                            value: ColorNameScheme.general,
                            label: Text(colorNameSchemeStringMap[ColorNameScheme.general]!)
                        ),
                        ButtonSegment(
                            value: ColorNameScheme.pms,
                            label: Text(colorNameSchemeStringMap[ColorNameScheme.pms]!)
                        ),
                        ButtonSegment(
                            value: ColorNameScheme.ralClassic,
                            label: Text(colorNameSchemeStringMap[ColorNameScheme.ralClassic]!)
                        ),
                        ButtonSegment(
                            value: ColorNameScheme.ralDsp,
                            label: Text(colorNameSchemeStringMap[ColorNameScheme.ralDsp]!)
                        ),
                        ButtonSegment(
                            value: ColorNameScheme.ralComplete,
                            label: Text(colorNameSchemeStringMap[ColorNameScheme.ralComplete]!)
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: widget.itemPadding),
          Text("Border Preferences", style: Theme.of(context).textTheme.titleLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Tool Outline Opacity", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.prefs.toolOpacity,
                  builder: (final BuildContext context, final int toolOutlineOpacity, final Widget? child)
                  {
                    return KPixSlider(
                      value: toolOutlineOpacity.toDouble(),
                      min: opacityMin.toDouble(),
                      max: opacityMax.toDouble(),
                      divisions: opacityMax - opacityMin,
                      onChanged: (final double newVal) {widget.prefs.toolOpacity.value = newVal.toInt();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Selection Outline Opacity", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.prefs.selectionOpacity,
                  builder: (final BuildContext context, final int selectionOpacity, final Widget? child)
                  {
                    return KPixSlider(
                      value: selectionOpacity.toDouble(),
                      min: opacityMin.toDouble(),
                      max: opacityMax.toDouble(),
                      divisions: opacityMax - opacityMin,
                      onChanged: (final double newVal) {widget.prefs.selectionOpacity.value = newVal.toInt();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Text("Canvas Border Opacity", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.prefs.canvasBorderOpacity,
                  builder: (final BuildContext context, final int canvasBorderOpacity, final Widget? child)
                  {
                    return KPixSlider(
                      value: canvasBorderOpacity.toDouble(),
                      min: opacityMin.toDouble(),
                      max: opacityMax.toDouble(),
                      divisions: opacityMax - opacityMin,
                      onChanged: (final double newVal) {widget.prefs.canvasBorderOpacity.value = newVal.toInt();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
        ]
      ),
    );
  }
}
