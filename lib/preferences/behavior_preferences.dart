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

//UNDO STEPS
const int undoStepsMin = 10;
const int undoStepsMax = 256;

class BehaviorPreferenceContent
{
  final ValueNotifier<int> undoSteps;
  final ValueNotifier<bool> selectShapeAfterInsert;
  final ValueNotifier<bool> selectLayerAfterInsert;

  BehaviorPreferenceContent._({required this.undoSteps, required this.selectShapeAfterInsert, required this.selectLayerAfterInsert});

  factory BehaviorPreferenceContent({required final int undoSteps, required final bool selectAfterInsert, required final bool selectLayerAfterInsert})
  {
      final int undoStepsNormalized = max(min(undoSteps, undoStepsMax), undoStepsMin);
      return BehaviorPreferenceContent._(
        undoSteps: ValueNotifier(undoStepsNormalized),
        selectShapeAfterInsert: ValueNotifier(selectAfterInsert),
        selectLayerAfterInsert: ValueNotifier(selectLayerAfterInsert));
  }

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
  Widget build(BuildContext context) {
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
            Expanded(flex: 1, child: Text("Undo Steps", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.prefs.undoSteps,
                builder: (final BuildContext context, final int undoSteps, final Widget? child)
                {
                  return Slider(
                    value: undoSteps.toDouble(),
                    min: undoStepsMin.toDouble(),
                    max: undoStepsMax.toDouble() - 1,
                    label: undoSteps.toString(),
                    onChanged: (final double newVal) {widget.prefs.undoSteps.value = newVal.toInt();},
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
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Text("Select Inserted Layers", style: Theme.of(context).textTheme.titleSmall)),
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
      ]
    );
  }
}
