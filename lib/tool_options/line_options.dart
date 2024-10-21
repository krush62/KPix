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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class AngleData
{
  final int x;
  final int y;
  final double angle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AngleData &&
              runtimeType == other.runtimeType &&
              angle == other.angle;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return "$x|$y|$angle";
  }

  AngleData({required this.x, required this.y}) : angle = atan2(x.toDouble(), y.toDouble());
}


class LineOptions extends IToolOptions
{
  final int widthMin;
  final int widthMax;
  final int widthDefault;
  final bool integerAspectRatioDefault;
  final int bezierCalculationPoints;
  final Set<AngleData> angles = {};

  final ValueNotifier<int> width = ValueNotifier(1);
  final ValueNotifier<bool> integerAspectRatio = ValueNotifier(false);
  final ValueNotifier<bool> unmodifiedIntegerAspectRatio = ValueNotifier(false);

  LineOptions({
    required this.widthMin,
    required this.widthMax,
    required this.widthDefault,
    required this.integerAspectRatioDefault,
    required this.bezierCalculationPoints,
  })
  {
    width.value = widthDefault;
    integerAspectRatio.value = integerAspectRatioDefault;
    unmodifiedIntegerAspectRatio.value = integerAspectRatioDefault;

    for (int i = -1; i <= 1; i+=2)
    {
      for (int j = -1; j <= 1; j+=2)
      {
        angles.add(AngleData(x: i * 1, y: j * 0));
        angles.add(AngleData(x: i * 4, y: j * 1));
        angles.add(AngleData(x: i * 3, y: j * 1));
        angles.add(AngleData(x: i * 2, y: j * 1));
        angles.add(AngleData(x: i * 1, y: j * 1));
        angles.add(AngleData(x: i * 1, y: j * 2));
        angles.add(AngleData(x: i * 1, y: j * 3));
        angles.add(AngleData(x: i * 1, y: j * 4));
        angles.add(AngleData(x: i * 0, y: j * 1));
      }
    }
  }

  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required final LineOptions lineOptions,
  }) {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Width",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: lineOptions.width,
                builder: (final BuildContext context, final int width, final Widget? child){
                    return Slider(
                    value: width.toDouble(),
                    min: lineOptions.widthMin.toDouble(),
                    max: lineOptions.widthMax.toDouble(),
                    divisions: lineOptions.widthMax - lineOptions.widthMin,
                    onChanged: (final double newVal) {lineOptions.width.value = newVal.round();},
                    label: width.round().toString(),
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Integer Aspect Ratio",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: hotkeyManager.controlNotifier,
                  builder: (final BuildContext _, final bool controlPressed, final Widget? __) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: lineOptions.unmodifiedIntegerAspectRatio,
                      builder: (final BuildContext context, final bool unmodifiedAspectRatio, final Widget? child){
                        bool newMode = unmodifiedAspectRatio;
                        if (controlPressed)
                        {
                          newMode = true;
                        }
                        lineOptions.integerAspectRatio.value = newMode;
                        return Switch(
                          onChanged: (final bool newVal) {
                            if (!controlPressed)
                            {
                              lineOptions.unmodifiedIntegerAspectRatio.value = newVal;
                            }
                            lineOptions.integerAspectRatio.value = newVal;
                          },
                          value: lineOptions.integerAspectRatio.value
                        );
                      },
                    );
                  },
                ),
              )
            ),
          ],
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    width.value = (originalValue + steps).clamp(widthMin, widthMax);
  }

  @override
  int getSize()
  {
    return width.value;
  }

}