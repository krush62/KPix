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

import 'package:flutter/material.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/widgets/preferences/preference_gui.dart';

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
          PrefSwitchRow(
            label: "Pulsating Selection Outline",
            notifier: widget.prefs.selectionPulsatingOutline,
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
