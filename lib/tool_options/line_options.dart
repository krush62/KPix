import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

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
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required LineOptions lineOptions,
  }) {
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
                builder: (BuildContext context, int width, child){
                    return Slider(
                    value: width.toDouble(),
                    min: lineOptions.widthMin.toDouble(),
                    max: lineOptions.widthMax.toDouble(),
                    divisions: lineOptions.widthMax - lineOptions.widthMin,
                    onChanged: (double newVal) {lineOptions.width.value = newVal.round();},
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
                  valueListenable: lineOptions.integerAspectRatio,
                  builder: (BuildContext context, bool keep, child){
                    return Switch(
                      onChanged: (bool newVal) {lineOptions.integerAspectRatio.value = newVal;},
                      value: keep
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
  void changeSize(int steps, int originalValue)
  {
    width.value = min(max(originalValue + steps, widthMin), widthMax);
  }

  @override
  int getSize()
  {
    return width.value;
  }

}