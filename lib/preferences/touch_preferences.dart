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

class TouchPreferenceContent
{
  final ValueNotifier<double> zoomStepDistance;
  final ValueNotifier<int> singleTouchDelay;

  final double zoomStepDistanceMin;
  final double zoomStepDistanceMax;
  final int singleTouchDelayMin;
  final int singleTouchDelayMax;

  TouchPreferenceContent._({
    required this.singleTouchDelay,
    required this.singleTouchDelayMin,
    required this.singleTouchDelayMax,
    required this.zoomStepDistance,
    required this.zoomStepDistanceMin,
    required this.zoomStepDistanceMax
  });

  factory TouchPreferenceContent({
    required final int singleTouchDelay,
    required final int singleTouchDelayMin,
    required final int singleTouchDelayMax,
    required final double zoomStepDistance,
    required final double zoomStepDistanceMin,
    required final double zoomStepDistanceMax
  })
  {
    return TouchPreferenceContent._(
      singleTouchDelay: ValueNotifier(singleTouchDelay.clamp(singleTouchDelayMin, singleTouchDelayMax)),
      singleTouchDelayMin: singleTouchDelayMin,
      singleTouchDelayMax: singleTouchDelayMax,
      zoomStepDistance: ValueNotifier(zoomStepDistance.clamp(zoomStepDistanceMin, zoomStepDistanceMax)),
      zoomStepDistanceMin: zoomStepDistanceMin,
      zoomStepDistanceMax: zoomStepDistanceMax
    );
  }
}

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
            Expanded(flex: 1, child: Text("Touch Delay", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.prefs.singleTouchDelay,
                builder: (final BuildContext context, final int singleTouchDelay, final Widget? child)
                {
                  return Slider(
                    value: singleTouchDelay.toDouble(),
                    min: widget.prefs.singleTouchDelayMin.toDouble(),
                    max: widget.prefs.singleTouchDelayMax.toDouble(),
                    label: "${singleTouchDelay}ms",
                    onChanged: (final double newVal) {widget.prefs.singleTouchDelay.value = newVal.toInt();},
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
                valueListenable: widget.prefs.zoomStepDistance,
                builder: (final BuildContext context, final double zoomDistance, final Widget? child)
                {
                  return Slider(
                    value: zoomDistance,
                    min: widget.prefs.zoomStepDistanceMin,
                    max: widget.prefs.zoomStepDistanceMax,
                    label: "${zoomDistance.round()}px",
                    onChanged: (final double newVal) {widget.prefs.zoomStepDistance.value = newVal;},
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
