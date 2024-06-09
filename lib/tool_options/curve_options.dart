import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class CurveOptions extends IToolOptions
{
  final int widthMin;
  final int widthMax;
  final int widthDefault;

  ValueNotifier<int> width = ValueNotifier(1);

  CurveOptions({
    required this.widthMin,
    required this.widthMax,
    required this.widthDefault,
  })
  {
    width.value = widthDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required CurveOptions curveOptions,
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
              child: ValueListenableBuilder<int>(
                valueListenable: curveOptions.width,
                builder: (BuildContext context, int val, child)
                {
                  return Slider(
                    value: val.toDouble(),
                    min: curveOptions.widthMin.toDouble(),
                    max: curveOptions.widthMax.toDouble(),
                    divisions: curveOptions.widthMax - curveOptions.widthMin,
                    onChanged: (double newVal) {curveOptions.width.value = newVal.round();},
                    label: val.round().toString(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

}