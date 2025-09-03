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
import 'package:kpix/util/color_names.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

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

const Map<ColorNameScheme, String> colorNameSchemeStringMap =
<ColorNameScheme, String>{
  ColorNameScheme.general:"General",
  ColorNameScheme.pms:"PMS",
  ColorNameScheme.ralClassic:"RAL Classic",
  ColorNameScheme.ralDsp:"RAL DSP",
  ColorNameScheme.ralComplete:"RAL Complete",
  ColorNameScheme.dmc:"DMC",
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

  factory GuiPreferenceContent({required final int themeTypeValue, required final int rasterSizeValue, required final int rasterContrast, required final int colorNameSchemeValue, required final int canvasBorderOpacityValue, required final int selectionOpacityValue, required final int toolOpacityValue})
  {
    final ThemeMode themeType = themeTypeIndexMap[themeTypeValue]?? ThemeMode.system;
    final int rasterSizeIndex = max(rasterSizes.indexOf(rasterSizeValue), 0);
    final int rasterContrastNormalized = rasterContrast.clamp(rasterContrastMin, rasterContrastMax);
    final ColorNameScheme colorNameScheme = colorNameSchemeMap[colorNameSchemeValue]?? ColorNameScheme.general;
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
    colorNameScheme.value = colorNameSchemeMap[colorNameSchemeValue]?? ColorNameScheme.general;
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("Theme", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: widget.prefs.themeType,
                  builder: (final BuildContext context, final ThemeMode theme, final Widget? child)
                  {
                    return SegmentedButton<ThemeMode>(
                      selected: <ThemeMode>{theme},
                      showSelectedIcon: false,
                      onSelectionChanged: (final Set<ThemeMode> themeList) {widget.prefs.themeType.value = themeList.first;},
                      segments: <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text(themeTypeStringMap[ThemeMode.system]!),
                        ),
                        ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text(themeTypeStringMap[ThemeMode.light]!),
                        ),
                        ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text(themeTypeStringMap[ThemeMode.dark]!),
                        ),
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
            children: <Widget>[
              Expanded(child: Text("Raster Size", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.prefs.rasterSizeIndex,
                  builder: (final BuildContext context, final int rasterSizeIndex, final Widget? child)
                  {
                    return KPixSlider(
                      value: rasterSizeIndex.toDouble(),
                      max: rasterSizes.length.toDouble() - 1,
                      //divisions: rasterSizes.length,
                      label: rasterSizes[rasterSizeIndex].toString(),
                      onChanged: (final double newVal) {widget.prefs.rasterSizeIndex.value = newVal.round();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("Raster Contrast", style: Theme.of(context).textTheme.titleSmall)),
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
                      //divisions: rasterContrastDivisions,
                      onChanged: (final double newVal) {widget.prefs.rasterContrast.value = newVal.round();},
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
            children: <Widget>[
              Expanded(child: Text("Color Naming", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<ColorNameScheme>(
                  valueListenable: widget.prefs.colorNameScheme,
                  builder: (final BuildContext context, final ColorNameScheme scheme, final Widget? child)
                  {


                    return SegmentedButton<ColorNameScheme>(
                      selected: <ColorNameScheme>{scheme},
                      showSelectedIcon: false,
                      onSelectionChanged: (final Set<ColorNameScheme> schemeList) {widget.prefs.colorNameScheme.value = schemeList.first;},

                      segments: <ButtonSegment<ColorNameScheme>>[
                        ButtonSegment<ColorNameScheme>(
                            value: ColorNameScheme.general,
                            label: Text(
                              colorNameSchemeStringMap[ColorNameScheme.general]!,
                              style: Theme.of(context).textTheme.bodySmall!.apply(color: scheme == ColorNameScheme.general ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                            ),
                        ),
                        ButtonSegment<ColorNameScheme>(
                          value: ColorNameScheme.pms,
                          label: Text(
                            colorNameSchemeStringMap[ColorNameScheme.pms]!,
                            style: Theme.of(context).textTheme.bodySmall!.apply(color: scheme == ColorNameScheme.pms ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                          ),
                        ),
                        ButtonSegment<ColorNameScheme>(
                          value: ColorNameScheme.ralClassic,
                          label: Text(
                            colorNameSchemeStringMap[ColorNameScheme.ralClassic]!,
                            style: Theme.of(context).textTheme.bodySmall!.apply(color: scheme == ColorNameScheme.ralClassic ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                          ),
                        ),
                        ButtonSegment<ColorNameScheme>(
                          value: ColorNameScheme.ralDsp,
                          label: Text(
                            colorNameSchemeStringMap[ColorNameScheme.ralDsp]!,
                            style: Theme.of(context).textTheme.bodySmall!.apply(color: scheme == ColorNameScheme.ralDsp ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                          ),
                        ),
                        ButtonSegment<ColorNameScheme>(
                          value: ColorNameScheme.ralComplete,
                          label: Text(
                            colorNameSchemeStringMap[ColorNameScheme.ralComplete]!,
                            style: Theme.of(context).textTheme.bodySmall!.apply(color: scheme == ColorNameScheme.ralComplete ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                          ),
                        ),
                        ButtonSegment<ColorNameScheme>(
                          value: ColorNameScheme.dmc,
                          label: Text(
                            colorNameSchemeStringMap[ColorNameScheme.dmc]!,
                            style: Theme.of(context).textTheme.bodySmall!.apply(color: scheme == ColorNameScheme.dmc ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                          ),
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
            children: <Widget>[
              Expanded(child: Text("Tool Outline Opacity", style: Theme.of(context).textTheme.titleSmall)),
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
                      //divisions: opacityMax - opacityMin,
                      onChanged: (final double newVal) {widget.prefs.toolOpacity.value = newVal.round();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("Selection Outline Opacity", style: Theme.of(context).textTheme.titleSmall)),
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
                      //divisions: opacityMax - opacityMin,
                      onChanged: (final double newVal) {widget.prefs.selectionOpacity.value = newVal.round();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("Canvas Border Opacity", style: Theme.of(context).textTheme.titleSmall)),
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
                      //divisions: opacityMax - opacityMin,
                      onChanged: (final double newVal) {widget.prefs.canvasBorderOpacity.value = newVal.round();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
