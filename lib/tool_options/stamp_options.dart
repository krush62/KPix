import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kpix/stamp_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';


class StampOptions extends IToolOptions
{
  final int scaleMin;
  final int scaleMax;
  final int scaleDefault;
  final int stampDefault;
  final bool flipHDefault;
  final bool flipVDefault;

  final StampManager stampManager;

  final ValueNotifier<int> scale = ValueNotifier(1);
  final ValueNotifier<StampType> stamp = ValueNotifier(StampType.stampCircle15);
  final ValueNotifier<bool> flipH = ValueNotifier(false);
  final ValueNotifier<bool> flipV = ValueNotifier(false);


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
                    items: stampIndexMap.values.map<DropdownMenuItem<StampType>>((StampType value) {
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