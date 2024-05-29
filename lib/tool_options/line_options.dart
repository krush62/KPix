import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class LineOptions extends IToolOptions
{
  final int widthMin;
  final int widthMax;
  final int widthDefault;
  final bool integerAspectRatioDefault;

  int width = 1;
  bool integerAspectRatio = false;

  LineOptions({
    required this.widthMin,
    required this.widthMax,
    required this.widthDefault,
    required this.integerAspectRatioDefault
  })
  {
    width = widthDefault;
    integerAspectRatio = integerAspectRatioDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required LineOptions lineOptions,
    LineWidthChanged? lineWidthChanged,
    LineIntegerAspectRatioChanged? lineIntegerAspectRatioChanged
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
              child: Slider(
                value: lineOptions.width.toDouble(),
                min: lineOptions.widthMin.toDouble(),
                max: lineOptions.widthMax.toDouble(),
                divisions: lineOptions.widthMax - lineOptions.widthMin,
                onChanged: lineWidthChanged,
                label: lineOptions.width.round().toString(),
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
                  child: Switch(
                      onChanged: lineIntegerAspectRatioChanged,
                      value: lineOptions.integerAspectRatio
                  ),
                )
            ),
          ],
        ),
      ],
    );
  }
}