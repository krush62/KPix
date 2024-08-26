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

class StylusPreferenceContent
{
  final ValueNotifier<int> stylusLongPressDelay;
  final ValueNotifier<double> stylusLongPressCancelDistance;
  final ValueNotifier<double> stylusZoomStepDistance;
  final ValueNotifier<double> stylusSizeStepDistance;
  final ValueNotifier<int> stylusPollInterval;
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

  StylusPreferenceContent._({
    required this.stylusLongPressDelay,
    required this.stylusLongPressCancelDistance,
    required this.stylusZoomStepDistance,
    required this.stylusSizeStepDistance,
    required this.stylusPollInterval,
    required this.stylusLongPressDelayMin,
    required this.stylusLongPressDelayMax,
    required this.stylusLongPressCancelDistanceMin,
    required this.stylusLongPressCancelDistanceMax,
    required this.stylusZoomStepDistanceMin,
    required this.stylusZoomStepDistanceMax,
    required this.stylusSizeStepDistanceMin,
    required this.stylusSizeStepDistanceMax,
    required this.stylusPollIntervalMin,
    required this.stylusPollIntervalMax});

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
  })
  {
    return StylusPreferenceContent._(
      stylusLongPressCancelDistance: ValueNotifier(max(min(stylusLongPressCancelDistance, stylusLongPressCancelDistanceMax), stylusLongPressCancelDistanceMin)),
      stylusLongPressCancelDistanceMin: stylusLongPressCancelDistanceMin,
      stylusLongPressCancelDistanceMax: stylusLongPressCancelDistanceMax,
      stylusLongPressDelay: ValueNotifier(max(min(stylusLongPressDelay, stylusLongPressDelayMax), stylusLongPressDelayMin)),
      stylusLongPressDelayMin: stylusLongPressDelayMin,
      stylusLongPressDelayMax: stylusLongPressDelayMax,
      stylusPollInterval: ValueNotifier(max(min(stylusPollInterval, stylusLongPressDelayMax), stylusLongPressDelayMin)),
      stylusPollIntervalMin: stylusLongPressDelayMin,
      stylusPollIntervalMax: stylusLongPressDelayMax,
      stylusSizeStepDistance: ValueNotifier(max(min(stylusSizeStepDistance, stylusSizeStepDistanceMax), stylusSizeStepDistanceMin)),
      stylusSizeStepDistanceMin: stylusSizeStepDistanceMin,
      stylusSizeStepDistanceMax: stylusSizeStepDistanceMax,
      stylusZoomStepDistance: ValueNotifier(max(min(stylusZoomStepDistance, stylusZoomStepDistanceMax), stylusZoomStepDistanceMin)),
      stylusZoomStepDistanceMin: stylusZoomStepDistanceMin,
      stylusZoomStepDistanceMax: stylusZoomStepDistanceMax,
    );
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
  Widget build(BuildContext context)
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Text("Poll Interval", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.prefs.stylusPollInterval,
                builder: (final BuildContext context, final int pollInterval, final Widget? child)
                {
                  return Slider(
                    value: pollInterval.toDouble(),
                    min: widget.prefs.stylusPollIntervalMin.toDouble(),
                    max: widget.prefs.stylusPollIntervalMax.toDouble(),
                    label: "${pollInterval}ms",
                    onChanged: (final double newVal) {widget.prefs.stylusPollInterval.value = newVal.toInt();},
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
            Expanded(flex: 1, child: Text("Long Press Delay", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.prefs.stylusLongPressDelay,
                builder: (final BuildContext context, final int longPressDelay, final Widget? child)
                {
                  return Slider(
                    value: longPressDelay.toDouble(),
                    min: widget.prefs.stylusLongPressDelayMin.toDouble(),
                    max: widget.prefs.stylusLongPressDelayMax.toDouble(),
                    label: "${longPressDelay}ms",
                    onChanged: (final double newVal) {widget.prefs.stylusLongPressDelay.value = newVal.toInt();},
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
            Expanded(flex: 1, child: Text("Long Press Cancel Distance", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.prefs.stylusLongPressCancelDistance,
                builder: (final BuildContext context, final double longPressDistance, final Widget? child)
                {
                  return Slider(
                    value: longPressDistance,
                    min: widget.prefs.stylusLongPressCancelDistanceMin,
                    max: widget.prefs.stylusLongPressCancelDistanceMax,
                    label: "${longPressDistance.round()}px",
                    onChanged: (final double newVal) {widget.prefs.stylusLongPressCancelDistance.value = newVal;},
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
            Expanded(flex: 1, child: Text("Zoom Step Distance", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.prefs.stylusZoomStepDistance,
                builder: (final BuildContext context, final double zoomStepDistance, final Widget? child)
                {
                  return Slider(
                    value: zoomStepDistance,
                    min: widget.prefs.stylusZoomStepDistanceMin,
                    max: widget.prefs.stylusZoomStepDistanceMax,
                    label: "${zoomStepDistance.round()}px",
                    onChanged: (final double newVal) {widget.prefs.stylusZoomStepDistance.value = newVal;},
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
            Expanded(flex: 1, child: Text("Tool Size Step Distance", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.prefs.stylusSizeStepDistance,
                builder: (final BuildContext context, final double sizeStepDistance, final Widget? child)
                {
                  return Slider(
                    value: sizeStepDistance,
                    min: widget.prefs.stylusSizeStepDistanceMin,
                    max: widget.prefs.stylusSizeStepDistanceMax,
                    label: "${sizeStepDistance.round()}px",
                    onChanged: (final double newVal) {widget.prefs.stylusSizeStepDistance.value = newVal;},
                  );
                },
              ),
            ),
          ],
        ),
      ]
    );
  }
}
