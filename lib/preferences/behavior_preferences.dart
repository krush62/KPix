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
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

//UNDO STEPS
const int undoStepsMin = 10;
const int undoStepsMax = 256;

class BehaviorPreferenceContent
{
  final ValueNotifier<int> undoSteps;
  final ValueNotifier<bool> selectShapeAfterInsert;
  final ValueNotifier<bool> selectLayerAfterInsert;
  final ValueNotifier<int> shadingStepsMinus;
  final ValueNotifier<int> shadingStepsPlus;
  final int undoStepsMax;
  final int undoStepsMin;
  final ShadingLayerSettingsConstraints shadingConstraints;

  factory BehaviorPreferenceContent({required final int undoSteps, required final bool selectAfterInsert, required final bool selectLayerAfterInsert, required final int undoStepsMax, required final int undoStepsMin, required final ShadingLayerSettingsConstraints shadingConstraints})
  {
      return BehaviorPreferenceContent._(
        undoSteps: ValueNotifier<int>(undoSteps.clamp(undoStepsMin, undoStepsMax)),
        selectShapeAfterInsert: ValueNotifier<bool>(selectAfterInsert),
        selectLayerAfterInsert: ValueNotifier<bool>(selectLayerAfterInsert),
        shadingStepsMinus: ValueNotifier<int>(shadingConstraints.shadingStepsDefaultDarken),
        shadingStepsPlus: ValueNotifier<int>(shadingConstraints.shadingStepsDefaultBrighten),
        shadingConstraints: shadingConstraints,
        undoStepsMax: undoStepsMax,
        undoStepsMin: undoStepsMin,);
  }

  BehaviorPreferenceContent._({required this.undoSteps, required this.selectShapeAfterInsert, required this.selectLayerAfterInsert, required this.undoStepsMax, required this.undoStepsMin, required this.shadingStepsMinus, required this.shadingStepsPlus, required this.shadingConstraints});

}


class BehaviorPreferences extends StatefulWidget
{
  final BehaviorPreferenceContent prefs;
  const BehaviorPreferences({super.key, required this.prefs});

  @override
  State<BehaviorPreferences> createState() => _BehaviorPreferencesState();
}

class _BehaviorPreferencesState extends State<BehaviorPreferences> {


  @override
  Widget build(final BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Text("Undo Steps", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.prefs.undoSteps,
                builder: (final BuildContext context, final int undoSteps, final Widget? child)
                {
                  return KPixSlider(
                    value: undoSteps.toDouble(),
                    min: widget.prefs.undoStepsMin.toDouble(),
                    max: widget.prefs.undoStepsMax.toDouble(),
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                    onChanged: (final double newVal) {widget.prefs.undoSteps.value = newVal.toInt();},
                  );
                },
              ),
            ),
          ],
        ),
        /*Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Text("Select Shape After Insertion", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.prefs.selectShapeAfterInsert,
                builder: (final BuildContext context, final bool select, final Widget? child)
                {
                  return Switch(
                    value: select,
                    onChanged: (final bool newVal){widget.prefs.selectShapeAfterInsert.value = newVal;},
                  );
                },
              ),
            ),
          ],
        ),*/
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Text("Select Inserted Layers", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.prefs.selectLayerAfterInsert,
                builder: (final BuildContext context, final bool select, final Widget? child)
                {
                  return Switch(
                    value: select,
                    onChanged: (final bool newVal){widget.prefs.selectLayerAfterInsert.value = newVal;},
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Text("Default Shading Layer Settings", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.prefs.selectLayerAfterInsert,
                builder: (final BuildContext context, final bool select, final Widget? child)
                {
                  return Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(child: Text("Max Darken")),
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: widget.prefs.shadingStepsMinus,
                              builder: (final BuildContext context1, final int shadingLow, final Widget? child1)
                              {
                                return KPixSlider(
                                  value: shadingLow.toDouble(),
                                  min: widget.prefs.shadingConstraints.shadingStepsMin.toDouble(),
                                  max: widget.prefs.shadingConstraints.shadingStepsMax.toDouble(),
                                  onChanged: (final double value) {
                                    widget.prefs.shadingStepsMinus.value = value.round();
                                  },
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          const Expanded(child: Text("Max Brighten")),
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: widget.prefs.shadingStepsPlus,
                              builder: (final BuildContext context1, final int shadingHigh, final Widget? child1)
                              {
                                return KPixSlider(
                                  value: shadingHigh.toDouble(),
                                  min: widget.prefs.shadingConstraints.shadingStepsMin.toDouble(),
                                  max: widget.prefs.shadingConstraints.shadingStepsMax.toDouble(),
                                  onChanged: (final double value) {
                                    widget.prefs.shadingStepsPlus.value = value.round();
                                  },
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
