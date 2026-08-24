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
import 'package:kpix/preferences/preference_gui.dart';
import 'package:kpix/preferences/preference_values.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PrefSliderRow<int>(
          text: "Touch Delay",
          notifier: widget.prefs.singleTouchDelay,
          minVal: widget.prefs.singleTouchDelayMin.toDouble(),
          maxVal: widget.prefs.singleTouchDelayMax.toDouble(),
          labelBuilder: (final int val) => "${val}ms",
        ),
        PrefSliderRow<double>(
          text: "Zoom Step Distance",
          notifier: widget.prefs.zoomStepDistance,
          minVal: widget.prefs.zoomStepDistanceMin,
          maxVal: widget.prefs.zoomStepDistanceMax,
          divisions: (widget.prefs.zoomStepDistanceMax - widget.prefs.zoomStepDistanceMin).round(),
          labelBuilder: (final double val) => "${val.round()}px",
        ),
      ],
    );
  }
}
