import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class WandOptions extends IToolOptions
{
  ValueNotifier<SelectionMode> mode = ValueNotifier(SelectionMode.replace);
  ValueNotifier<bool> selectFromWholeRamp = ValueNotifier(false);
  ValueNotifier<bool> continuous = ValueNotifier(true);

  final int modeDefault;
  final bool selectFromWholeRampDefault;
  final bool continuousDefault;

  WandOptions({
    required this.selectFromWholeRampDefault,
    required this.modeDefault,
    required this.continuousDefault,
  })
  {
    selectFromWholeRamp.value = selectFromWholeRampDefault;
    continuous.value = continuousDefault;
    mode.value = selectionModeIndexMap[modeDefault] ?? SelectionMode.replace;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required WandOptions wandOptions,
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
                    "Continuous selection",
                    style: Theme.of(context).textTheme.labelMedium,
                  )
              ),
            ),
            Expanded(
                flex: toolSettingsWidgetOptions.columnWidthRatio,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: wandOptions.continuous,
                    builder: (BuildContext context, bool cont, child)
                    {
                      return Switch(
                          onChanged: (bool newVal) {wandOptions.continuous.value = newVal;},
                          value: cont,
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
                    "Select from whole ramp",
                    style: Theme.of(context).textTheme.labelMedium,
                  )
              ),
            ),
            Expanded(
                flex: toolSettingsWidgetOptions.columnWidthRatio,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: wandOptions.selectFromWholeRamp,
                    builder: (BuildContext context, bool select, child)
                    {
                      return Switch(
                          onChanged: (bool newVal) {wandOptions.selectFromWholeRamp.value = newVal;},
                          value: select
                      );
                    },
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
              child: ValueListenableBuilder<SelectionMode>(
                valueListenable: wandOptions.mode,
                builder: (BuildContext context, SelectionMode mode, child)
                {
                  return DropdownButton(
                    value: mode,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (SelectionMode? sMode) {wandOptions.mode.value = sMode!;},
                    items: selectionModeList.map<DropdownMenuItem<SelectionMode>>((SelectionMode value) {
                      return DropdownMenuItem<SelectionMode>(
                        value: value,
                        child: Text(selectionModeStringMap[value]!),
                      );
                    }).toList(),
                  );
                },
              )
            ),
          ],
        ),
      ],
    );
  }

  @override
  void changeSize(int steps, int originalValue){}

  @override
  int getSize()
  {
    return 0;
  }

}