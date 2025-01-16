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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class AngleData
{
  final int x;
  final int y;
  final double angle;

  @override
  bool operator ==(final Object other) =>
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

enum SegmentSortStyle
{
  asc,
  ascDesc,
  descAsc,
  desc,
}

const Map<int, SegmentSortStyle> segmentSortStyleValueMap =
<int, SegmentSortStyle>{
  0:SegmentSortStyle.asc,
  1:SegmentSortStyle.ascDesc,
  2:SegmentSortStyle.descAsc,
  3:SegmentSortStyle.desc,
};

class LineOptions extends IToolOptions
{
  final int widthMin;
  final int widthMax;
  final int widthDefault;
  final bool integerAspectRatioDefault;
  final bool segmentSortingDefault;
  final int segmentSortStyleDefault;
  final int bezierCalculationPoints;
  final Set<AngleData> angles = <AngleData>{};

  final ValueNotifier<int> width;
  final ValueNotifier<bool> integerAspectRatio;
  final ValueNotifier<bool> unmodifiedIntegerAspectRatio;
  final ValueNotifier<bool> segmentSorting;
  final ValueNotifier<SegmentSortStyle> segmentSortStyle;

  LineOptions({
    required this.widthMin,
    required this.widthMax,
    required this.widthDefault,
    required this.integerAspectRatioDefault,
    required this.bezierCalculationPoints,
    required this.segmentSortingDefault,
    required this.segmentSortStyleDefault,
  }) :
    segmentSorting = ValueNotifier<bool>(segmentSortingDefault),
    segmentSortStyle = ValueNotifier<SegmentSortStyle>(segmentSortStyleValueMap[segmentSortStyleDefault] ?? SegmentSortStyle.ascDesc),
    width = ValueNotifier<int>(widthDefault),
    integerAspectRatio = ValueNotifier<bool>(integerAspectRatioDefault),
    unmodifiedIntegerAspectRatio = ValueNotifier<bool>(integerAspectRatioDefault)
  {

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Width",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: lineOptions.width,
                builder: (final BuildContext context, final int width, final Widget? child){
                    return KPixSlider(
                    value: width.toDouble(),
                    min: lineOptions.widthMin.toDouble(),
                    max: lineOptions.widthMax.toDouble(),
                    divisions: lineOptions.widthMax - lineOptions.widthMin,
                    onChanged: (final double newVal) {lineOptions.width.value = newVal.round();},
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
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
                  "Integer Aspect Ratio",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
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
                          value: lineOptions.integerAspectRatio.value,
                        );
                      },
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
                  "Segment Sorting",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: lineOptions.segmentSorting,
                  builder: (final BuildContext context, final bool segmentSorting, final Widget? child){
                    return Row(
                      children: <Widget>[
                        Switch(
                          onChanged: (final bool newVal) {
                            lineOptions.segmentSorting.value = newVal;
                          },
                          value: segmentSorting,
                        ),
                        SizedBox(width: toolSettingsWidgetOptions.padding),
                        if (segmentSorting)
                          ValueListenableBuilder<SegmentSortStyle>(
                            valueListenable: lineOptions.segmentSortStyle,
                            builder: (final BuildContext context, final SegmentSortStyle sortStyle, final Widget? child) {
                              return Expanded(
                                child: SegmentedButton<SegmentSortStyle>(
                                  selected: <SegmentSortStyle>{sortStyle},
                                  onSelectionChanged: (final Set<SegmentSortStyle> p0) {
                                    lineOptions.segmentSortStyle.value = p0.first;
                                  },
                                  segments: const <ButtonSegment<SegmentSortStyle>>[
                                    ButtonSegment<SegmentSortStyle>(
                                      value: SegmentSortStyle.asc,
                                      label: Tooltip(
                                        message: "Ascending segment order",
                                        waitDuration: AppState.toolTipDuration,
                                        child: Text("<"),
                                      ),
                                    ),
                                    ButtonSegment<SegmentSortStyle>(
                                      value: SegmentSortStyle.ascDesc,
                                      label: Tooltip(
                                        message: "Ascending/Descending segment order",
                                        waitDuration: AppState.toolTipDuration,
                                        child: Text("<>"),
                                      ),
                                    ),
                                    ButtonSegment<SegmentSortStyle>(
                                      value: SegmentSortStyle.descAsc,
                                      label: Tooltip(
                                        message: "Descending/Ascending segment order",
                                        waitDuration: AppState.toolTipDuration,
                                        child: Text("><"),
                                      ),
                                    ),
                                    ButtonSegment<SegmentSortStyle>(
                                      value: SegmentSortStyle.desc,
                                      label: Tooltip(
                                        message: "Descending segment order",
                                        waitDuration: AppState.toolTipDuration,
                                        child: Text(">"),
                                      ),
                                    ),
                                  ],
                                  showSelectedIcon: false,
                                ),
                              );
                            },
                          ),
                      ],
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
    width.value = (originalValue + steps).clamp(widthMin, widthMax);
  }

  @override
  int getSize()
  {
    return width.value;
  }

}
