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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preferences/preference_gui.dart';

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

  void update({
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
    this.stylusLongPressDelay.value = stylusLongPressDelay.clamp(stylusLongPressDelayMin, stylusLongPressDelayMax);
    this.stylusLongPressCancelDistance.value = stylusLongPressCancelDistance.clamp(stylusLongPressCancelDistanceMin, stylusLongPressCancelDistanceMax);
    this.stylusZoomStepDistance.value = stylusZoomStepDistance.clamp(stylusZoomStepDistanceMin, stylusZoomStepDistanceMax);
    this.stylusSizeStepDistance.value = stylusSizeStepDistance.clamp(stylusSizeStepDistanceMin, stylusSizeStepDistanceMax);
    this.stylusPollInterval.value = stylusPollInterval.clamp(stylusPollIntervalMin, stylusPollIntervalMax);
    this.stylusPickMaxDuration.value = stylusPickMaxDuration.clamp(stylusPickMaxDurationMin, stylusPickMaxDurationMax);
  }
}

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
          waitDuration: AppState.toolTipDuration,
          message: "Polling time to check for presses of stylus buttons.",
          child: PrefSliderRow<int>(
            text: "Poll Interval",
            minVal: widget.prefs.stylusPollIntervalMin.toDouble(),
            maxVal: widget.prefs.stylusPollIntervalMax.toDouble(),
            notifier: widget.prefs.stylusPollInterval,
          ),
        ),
        Tooltip(
          waitDuration: AppState.toolTipDuration,
          message: "Time that needs to be held down for a long press.",
          child: PrefSliderRow<int>(
            text: "Long Press Delay",
            minVal: widget.prefs.stylusLongPressDelayMin.toDouble(),
            maxVal: widget.prefs.stylusLongPressDelayMax.toDouble(),
            notifier: widget.prefs.stylusLongPressDelay,
          ),
        ),
        Tooltip(
          waitDuration: AppState.toolTipDuration,
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
          waitDuration: AppState.toolTipDuration,
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
          waitDuration: AppState.toolTipDuration,
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
          waitDuration: AppState.toolTipDuration,
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
