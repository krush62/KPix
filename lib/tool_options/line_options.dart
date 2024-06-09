import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class LineOptions extends IToolOptions
{
  final int widthMin;
  final int widthMax;
  final int widthDefault;
  final bool integerAspectRatioDefault;

  ValueNotifier<int> width = ValueNotifier(1);
  ValueNotifier<bool> integerAspectRatio = ValueNotifier(false);

  LineOptions({
    required this.widthMin,
    required this.widthMax,
    required this.widthDefault,
    required this.integerAspectRatioDefault
  })
  {
    width.value = widthDefault;
    integerAspectRatio.value = integerAspectRatioDefault;
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
                builder: (BuildContext context, int width, child)
                {
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
                  builder: (BuildContext context, bool keep, child)
                  {
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
}