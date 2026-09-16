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
import 'package:kpix/kpix_language.dart';
import 'package:kpix/l10n/app_localizations.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.languagePreferences, style: Theme.of(context).textTheme.titleLarge),
          PrefDropdownRow<String>(
            label: l10n.language,
            notifier: widget.prefs.language,
            valueMap: getLanguageLabelMap(l10n: l10n),
          ),

          SizedBox(height: widget.itemPadding),

          Text(l10n.themePreferences, style: Theme.of(context).textTheme.titleLarge),
          PrefSegmentedButtonRow<ThemeMode>(
              label: l10n.theme,
              notifier: widget.prefs.themeType,
              labels: themeTypeStringMap(l10n),
          ),

          SizedBox(height: widget.itemPadding),

          Text(l10n.checkerboardPreferences, style: Theme.of(context).textTheme.titleLarge),
          PrefSliderRowIndexed(
              text: l10n.checkerboardSize,
              valueList: rasterSizes,
              notifier: widget.prefs.rasterSizeIndex,
          ),
          PrefSliderRow<int>(
              text: l10n.checkerboardContrast,
              notifier: widget.prefs.rasterContrast,
              minVal: rasterContrastMin.toDouble(),
              maxVal: rasterContrastMax.toDouble(),
          ),

          SizedBox(height: widget.itemPadding),

          Text(l10n.palettePreferences, style: Theme.of(context).textTheme.titleLarge),
          PrefSegmentedButtonRow<ColorNameScheme>(
            label: l10n.colorNaming,
            notifier: widget.prefs.colorNameScheme,
            labels: ColorNameScheme.getNameMap(),
            buttonTextStyle: Theme.of(context).textTheme.bodySmall,
          ),

          SizedBox(height: widget.itemPadding),

          Text(l10n.borderPreferences, style: Theme.of(context).textTheme.titleLarge),
          PrefSliderRow<int>(
              text: l10n.toolOutlineOpacity,
              minVal: opacityMin.toDouble(),
              maxVal: opacityMax.toDouble(),
              notifier: widget.prefs.toolOpacity,
          ),
          PrefSliderRow<int>(
              text: l10n.selectionOutlineOpacity,
              minVal: opacityMin.toDouble(),
              maxVal: opacityMax.toDouble(),
              notifier: widget.prefs.selectionOpacity,
          ),
          PrefSwitchRow(
            label: l10n.pulsatingSelectionOutline,
            notifier: widget.prefs.selectionPulsatingOutline,
          ),
          PrefSliderRow<int>(
            text: l10n.canvasBorerOpacity,
            minVal: opacityMin.toDouble(),
            maxVal: opacityMax.toDouble(),
            notifier: widget.prefs.canvasBorderOpacity,
          ),
        ],
      ),
    );
  }
}
