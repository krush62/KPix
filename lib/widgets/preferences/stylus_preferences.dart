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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/preferences/preference_gui.dart';

class StylusPreferences extends StatefulWidget
{
  final StylusPreferenceContent prefs;
  const StylusPreferences({super.key, required this.prefs});

  @override
  State<StylusPreferences> createState() => _StylusPreferencesState();
}

class _StylusPreferencesState extends State<StylusPreferences>
{
  @override
  Widget build(final BuildContext context)
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(
          waitDuration: toolTipDuration,
          message: "Polling time to check for presses of stylus buttons.",
          child: PrefSliderRow<int>(
            text: "Poll Interval",
            minVal: widget.prefs.stylusPollIntervalMin.toDouble(),
            maxVal: widget.prefs.stylusPollIntervalMax.toDouble(),
            notifier: widget.prefs.stylusPollInterval,
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: "Time that needs to be held down for a long press.",
          child: PrefSliderRow<int>(
            text: "Long Press Delay",
            minVal: widget.prefs.stylusLongPressDelayMin.toDouble(),
            maxVal: widget.prefs.stylusLongPressDelayMax.toDouble(),
            notifier: widget.prefs.stylusLongPressDelay,
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: "Distance that must be moved during a long press to cancel it.",
          child: PrefSliderRow<double>(
            text: "Long Press Cancel Distance",
            notifier: widget.prefs.stylusLongPressCancelDistance,
            minVal: widget.prefs.stylusLongPressCancelDistanceMin,
            maxVal: widget.prefs.stylusLongPressCancelDistanceMax,
            divisions: (widget.prefs.stylusLongPressCancelDistanceMax - widget.prefs.stylusLongPressCancelDistanceMin).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: "Distance that needs to be moved vertically to zoom in or out.",
          child: PrefSliderRow<double>(
            text: "Zoom Step Distance",
            notifier: widget.prefs.stylusZoomStepDistance,
            minVal: widget.prefs.stylusZoomStepDistanceMin,
            maxVal: widget.prefs.stylusZoomStepDistanceMax,
            divisions: (widget.prefs.stylusZoomStepDistanceMax - widget.prefs.stylusZoomStepDistanceMin).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: "Distance that needs to be moved horizontally to change the size of the current tool.",
          child: PrefSliderRow<double>(
            text: "Tool Size Step Distance",
            notifier: widget.prefs.stylusSizeStepDistance,
            minVal: widget.prefs.stylusSizeStepDistanceMin,
            maxVal: widget.prefs.stylusSizeStepDistanceMax,
            divisions: (widget.prefs.stylusSizeStepDistanceMax - widget.prefs.stylusSizeStepDistanceMin).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: "Timeout for picking a color.",
          child: PrefSliderRow<int>(
            text: "Color Pick Timeout",
            minVal: widget.prefs.stylusPickMaxDurationMin.toDouble(),
            maxVal: widget.prefs.stylusPickMaxDurationMax.toDouble(),
            notifier: widget.prefs.stylusPickMaxDuration,
          ),
        ),
      ],
    );
  }
}
