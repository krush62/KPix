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
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/preferences/preference_gui.dart';

class TouchPreferences extends StatefulWidget
{
  final TouchPreferenceContent prefs;
  const TouchPreferences({super.key, required this.prefs});

  @override
  State<TouchPreferences> createState() => _TouchPreferencesState();
}

class _TouchPreferencesState extends State<TouchPreferences>
{
  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PrefSliderRow<int>(
          text: l10n.touchDelay,
          notifier: widget.prefs.singleTouchDelay,
          minVal: widget.prefs.singleTouchDelay.min.toDouble(),
          maxVal: widget.prefs.singleTouchDelay.max.toDouble(),
          labelBuilder: (final int val) => "${val}ms",
        ),
        PrefSliderRow<double>(
          text: l10n.zoomStepDistance,
          notifier: widget.prefs.zoomStepDistance,
          minVal: widget.prefs.zoomStepDistance.min,
          maxVal: widget.prefs.zoomStepDistance.max,
          divisions: (widget.prefs.zoomStepDistance.max - widget.prefs.zoomStepDistance.min).round(),
          labelBuilder: (final double val) => "${val.round()}px",
        ),
        PrefSwitchRow(
          label: l10n.showNavigationJoysticks,
          notifier: widget.prefs.showJoysticks,
        ),
      ],
    );
  }
}
