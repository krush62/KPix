import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class WandOptions extends IToolOptions
{
  final bool selectFromWholeRampDefault;
  bool selectFromWholeRamp = false;
  WandOptions({required this.selectFromWholeRampDefault})
  {
    selectFromWholeRamp = selectFromWholeRampDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required WandOptions wandOptions,
    WandSelectFromWholeRampChanged? wandSelectFromWholeRampChanged,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select from whole ramp",
                    style: Theme.of(context).textTheme.labelMedium,
                  )
              ),
            ),
            Expanded(
                flex: toolSettingsWidgetOptions.columnWidthRatio,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Switch(
                      onChanged: wandSelectFromWholeRampChanged,
                      value: wandOptions.selectFromWholeRamp
                  ),
                )
            ),
          ],
        ),
      ],
    );
  }
}