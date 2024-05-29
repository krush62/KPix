import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class CurveOptions extends IToolOptions
{
  final int widthMin;
  final int widthMax;
  final int widthDefault;

  int width = 1;

  CurveOptions({
    required this.widthMin,
    required this.widthMax,
    required this.widthDefault,
  })
  {
    width = widthDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required CurveOptions curveOptions,
    CurveWidthChanged? curveWidthChanged,

  })
  {
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
                value: curveOptions.width.toDouble(),
                min: curveOptions.widthMin.toDouble(),
                max: curveOptions.widthMax.toDouble(),
                divisions: curveOptions.widthMax - curveOptions.widthMin,
                onChanged: curveWidthChanged,
                label: curveOptions.width.round().toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

}