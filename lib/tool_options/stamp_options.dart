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
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';


class StampOptions extends IToolOptions
{
  final int scaleMin;
  final int scaleMax;
  final int scaleDefault;
  final int stampDefault;
  final bool flipHDefault;
  final bool flipVDefault;

  final StampManager stampManager;

  final ValueNotifier<int> scale = ValueNotifier<int>(1);
  final ValueNotifier<StampType> stamp = ValueNotifier<StampType>(StampType.stampCircle15);
  final ValueNotifier<bool> flipH = ValueNotifier<bool>(false);
  final ValueNotifier<bool> flipV = ValueNotifier<bool>(false);


  StampOptions({
    required this.stampManager,
    required this.scaleMin,
    required this.scaleMax,
    required this.scaleDefault,
    required this.stampDefault,
    required this.flipHDefault,
    required this.flipVDefault,
  })
  {
    scale.value = scaleDefault;
    flipH.value = flipHDefault;
    flipV.value = flipVDefault;
    stamp.value = stampIndexMap[stampDefault] ?? StampType.stampCircle15;
  }

  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required final StampOptions stampOptions,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Stamp",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<StampType>(
                valueListenable: stampOptions.stamp,
                builder: (final BuildContext context, final StampType stamp, final Widget? child)
                {
                  return DropdownButton<StampType>(
                    value: stamp,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (final StampType? type) {stampOptions.stamp.value = type!;},
                    items: stampIndexMap.values.map<DropdownMenuItem<StampType>>((final StampType value) {
                      return DropdownMenuItem<StampType>(
                        value: value,
                        child: Text(stampNameMap[value]!),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Scale",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded
            (
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<int>(
                  valueListenable: stampOptions.scale,
                  builder: (final BuildContext context, final int scale, final Widget? child)
                  {
                    return KPixSlider(
                      value: scale.toDouble(),
                      min: stampOptions.scaleMin.toDouble(),
                      max: stampOptions.scaleMax.toDouble(),
                      divisions: stampOptions.scaleMax - stampOptions.scaleMin,
                      onChanged: (final double newVal) {stampOptions.scale.value = newVal.round();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Flip Horizontal",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ),
            ),
            Expanded
            (
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: stampOptions.flipH,
                  builder: (final BuildContext context, final bool flipH, final Widget? child){
                    return Switch(
                      onChanged: (final bool newVal) {stampOptions.flipH.value = newVal;},
                      value: flipH,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded
            (
              child: Align
              (
                alignment: Alignment.centerLeft,
                child: Text(
                  "Flip Vertical",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded
            (
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align
              (
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: stampOptions.flipV,
                  builder: (final BuildContext context, final bool flipV, final Widget? child){
                    return Switch(
                      onChanged: (final bool newVal) {stampOptions.flipV.value = newVal;},
                      value: flipV,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    scale.value = (originalValue + steps).clamp(scaleMin, scaleMax);
  }

  @override
  int getSize()
  {
    return scale.value;
  }

}
