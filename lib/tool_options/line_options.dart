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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/models/constraints/tool_line_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
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
              angle == other.angle;

  @override
  int get hashCode => angle.hashCode;

  @override
  String toString() {
    return "$x|$y|$angle";
  }

  AngleData({required this.x, required this.y}) : angle = atan2(x.toDouble(), y.toDouble());
}

class LineOptions extends IToolOptions
{

  final Set<AngleData> angles = <AngleData>{};

  final ValueNotifier<int> width = ValueNotifier<int>(LineConstraints.widthDefault);
  final ValueNotifier<bool> integerAspectRatio = ValueNotifier<bool>(LineConstraints.integerAspectRatioDefault);
  final ValueNotifier<bool> unmodifiedIntegerAspectRatio = ValueNotifier<bool>(LineConstraints.integerAspectRatioDefault);
  final ValueNotifier<bool> segmentSorting = ValueNotifier<bool>(LineConstraints.segmentSortingDefault);
  final ValueNotifier<SegmentSortStyle> segmentSortStyle = ValueNotifier<SegmentSortStyle>(LineConstraints.segmentSortStyleDefault);

  LineOptions()
  {
    const Set<(int, int)> ratios = <(int, int)>{
      (1, 0),
      (1, 1),
      (2, 1),
      (3, 1),
      (4, 1),
      (5, 1),
      (6, 1),
      (7, 1),
      (8, 1),
    };
    for (int i = -1; i <= 1; i+=2)
    {
      for (int j = -1; j <= 1; j+=2)
      {
        for (final (int, int) ratio in ratios)
        {
          angles.add(AngleData(x: i * ratio.$1, y: j * ratio.$2));
          if (ratio.$1 != ratio.$2)
          {
            angles.add(AngleData(x: i * ratio.$2, y: j * ratio.$1));
          }
        }
      }
    }
  }

  static Column getWidget({
    required final BuildContext context,
    required final LineOptions lineOptions,
  }) {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSliderRow<int>(
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          label: "Width",
          notifier: lineOptions.width,
          minVal: LineConstraints.widthMin.toDouble(),
          maxVal: LineConstraints.widthMax.toDouble(),
          //divisions: lineOptions.widthMax - lineOptions.widthMin,
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
              flex: ToolSettingsWidgetOptions.columnWidthRatio,
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
              flex: ToolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: lineOptions.segmentSorting,
                  builder: (final BuildContext context, final bool segmentSorting, final Widget? child){

                    final List<ButtonSegment<SegmentSortStyle>> segList = <ButtonSegment<SegmentSortStyle>>[];
                    for (final SegmentSortStyle sortStyle in SegmentSortStyle.values)
                    {
                      segList.add(
                        ButtonSegment<SegmentSortStyle>(
                          value: sortStyle,
                          label: Tooltip(
                            message: sortStyle.label,
                            waitDuration: toolTipDuration,
                            child: Text(sortStyle.iconText),
                          ),
                        ),
                      );
                    }

                    return
                      Row(
                      children: <Widget>[
                        Switch(
                          onChanged: (final bool newVal) {
                            lineOptions.segmentSorting.value = newVal;
                          },
                          value: segmentSorting,
                        ),
                        const SizedBox(width: ToolSettingsWidgetOptions.padding),
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
                                  segments: segList,
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
    width.value = (originalValue + steps).clamp(LineConstraints.widthMin, LineConstraints.widthMax);
  }

  @override
  int getSize()
  {
    return width.value;
  }

}
