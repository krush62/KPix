import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum StampType
{
  stamp0,
  stamp1,
  stamp2,
  stamp3,
  stamp4,
  stamp5,
  stamp6,
  stamp7
}

const List<StampType> stampList =
[
  StampType.stamp0,
  StampType.stamp1,
  StampType.stamp2,
  StampType.stamp3,
  StampType.stamp4,
  StampType.stamp5,
  StampType.stamp6,
  StampType.stamp7,
];

const Map<int, StampType> stampIndexMap =
{
  0:StampType.stamp0,
  1:StampType.stamp1,
  2:StampType.stamp2,
  3:StampType.stamp3,
  4:StampType.stamp4,
  5:StampType.stamp5,
  6:StampType.stamp6,
  7:StampType.stamp7,
};

const Map<StampType, String> stampNames =
{
  StampType.stamp0:"Stamp0",
  StampType.stamp1:"Stamp1",
  StampType.stamp2:"Stamp2",
  StampType.stamp3:"Stamp3",
  StampType.stamp4:"Stamp4",
  StampType.stamp5:"Stamp5",
  StampType.stamp6:"Stamp6",
  StampType.stamp7:"Stamp7",
};

class StampOptions extends IToolOptions
{
  final int scaleMin;
  final int scaleMax;
  final int scaleDefault;
  final int stampDefault;
  final bool flipHDefault;
  final bool flipVDefault;

  final ValueNotifier<int> scale = ValueNotifier(1);
  final ValueNotifier<StampType> stamp = ValueNotifier(StampType.stamp0);
  final ValueNotifier<bool> flipH = ValueNotifier(false);
  final ValueNotifier<bool> flipV = ValueNotifier(false);


  StampOptions({
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
    stamp.value = stampIndexMap[stampDefault] ?? StampType.stamp0;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required StampOptions stampOptions,
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
                    "Stamp",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<StampType>(
                valueListenable: stampOptions.stamp,
                builder: (BuildContext context, StampType stamp, child)
                {
                  return DropdownButton(
                    value: stamp,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (StampType? type) {stampOptions.stamp.value = type!;},
                    items: stampList.map<DropdownMenuItem<StampType>>((StampType value) {
                      return DropdownMenuItem<StampType>(
                        value: value,
                        child: Text(stampNames[value]!),
                      );
                    }).toList(),
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
                    "Scale",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded
            (
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<int>(
                  valueListenable: stampOptions.scale,
                  builder: (BuildContext context, int scale, child)
                  {
                    return Slider(
                      value: scale.toDouble(),
                      min: stampOptions.scaleMin.toDouble(),
                      max: stampOptions.scaleMax.toDouble(),
                      divisions: stampOptions.scaleMax - stampOptions.scaleMin,
                      onChanged: (double newVal) {stampOptions.scale.value = newVal.round();},
                      label: scale.round().toString(),
                    );
                  },
                ),
              )
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
                    "Flip Horizontal",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded
            (
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: stampOptions.flipH,
                  builder: (BuildContext context, bool flipH, child)
                  {
                    return Switch
                    (
                      onChanged: (bool newVal) {stampOptions.flipH.value = newVal;},
                      value: flipH
                    );
                  },
                ),
              )
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded
            (
              flex: 1,
              child: Align
              (
                alignment: Alignment.centerLeft,
                child: Text(
                  "Flip Vertical",
                  style: Theme.of(context).textTheme.labelLarge,
                )
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
                  builder: (BuildContext context, bool flipV, child)
                  {
                    return Switch
                    (
                      onChanged: (bool newVal) {stampOptions.flipV.value = newVal;},
                      value: flipV
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
    scale.value = min(max(originalValue + steps, scaleMin), scaleMax);
  }

  @override
  int getSize()
  {
    return scale.value;
  }

}