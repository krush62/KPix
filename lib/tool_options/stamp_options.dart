import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class StampOptions extends IToolOptions
{
  final int scaleMin;
  final int scaleMax;
  final int scaleDefault;
  final String nameDefault;

  final ValueNotifier<int> scale = ValueNotifier(1);
  final ValueNotifier<String> name = ValueNotifier("");


  StampOptions({
    required this.scaleMin,
    required this.scaleMax,
    required this.scaleDefault,
    required this.nameDefault,
  })
  {
    scale.value = scaleDefault;
    name.value = nameDefault;
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
                    "Name",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<String>(
                valueListenable: stampOptions.name,
                builder: (BuildContext context, String name, child)
                {
                  return Text(name);
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
            Expanded(
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