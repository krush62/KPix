import 'package:flutter/material.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class FillOptions
{
  final bool fillAdjacentDefault;
  bool fillAdjacent = true;
  FillOptions({required this.fillAdjacentDefault});

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required FillOptions fillOptions,
    FillAdjacentChanged? fillAdjacentChanged,
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
                  child: Switch(
                      onChanged: fillAdjacentChanged,
                      value: fillOptions.fillAdjacent
                  ),
                )
            ),
          ],
        ),
      ],
    );
  }
}
