import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class FillOptions extends IToolOptions
{
  final ValueNotifier<bool> fillAdjacent = ValueNotifier(true);
  final ValueNotifier<bool> fillWholeRamp = ValueNotifier(false);

  final bool fillAdjacentDefault;
  final bool fillWholeRampDefault;

  FillOptions({required this.fillAdjacentDefault, required this.fillWholeRampDefault})
  {
    fillAdjacent.value = fillAdjacentDefault;
    fillWholeRamp.value = fillWholeRampDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required FillOptions fillOptions,
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
                    "Fill Adjacent",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: fillOptions.fillAdjacent,
                  builder: (BuildContext context, bool fill, child)
                  {
                    return Switch(
                      onChanged: (bool newVal) {fillOptions.fillAdjacent.value = newVal;},
                      value: fill
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
                    "Fill whole ramp",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: fillOptions.fillWholeRamp,
                  builder: (BuildContext context, bool fill, child)
                  {
                    return Switch(
                      onChanged: (bool newVal) {fillOptions.fillWholeRamp.value = newVal;},
                      value: fill
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
  void changeSize(int steps, int originalValue) {}

  @override
  int getSize()
  {
    return 0;
  }

}

