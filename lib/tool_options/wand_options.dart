import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class WandOptions extends IToolOptions
{
  final int modeDefault;
  SelectionMode mode = SelectionMode.replace;
  final bool selectFromWholeRampDefault;
  bool selectFromWholeRamp = false;
  WandOptions({
    required this.selectFromWholeRampDefault,
    required this.modeDefault
  })
  {
    selectFromWholeRamp = selectFromWholeRampDefault;
    mode = selectionModeIndexMap[modeDefault] ?? SelectionMode.replace;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required WandOptions wandOptions,
    WandSelectFromWholeRampChanged? wandSelectFromWholeRampChanged,
    SelectionModeChanged? selectionModeChanged
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
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Mode",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
                flex: toolSettingsWidgetOptions.columnWidthRatio,
                child: DropdownButton(
                  value: wandOptions.mode,
                  dropdownColor: Theme.of(context).primaryColorDark,
                  focusColor: Theme.of(context).primaryColor,
                  isExpanded: true,
                  onChanged: (SelectionMode? sMode) {selectionModeChanged!(sMode!);},
                  items: selectionModeList.map<DropdownMenuItem<SelectionMode>>((SelectionMode value) {
                    return DropdownMenuItem<SelectionMode>(
                      value: value,
                      child: Text(selectionModeStringMap[value]!),
                    );
                  }).toList(),
                )
            ),
          ],
        ),
      ],
    );
  }
}