/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required final FillOptions fillOptions,
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
                  builder: (final BuildContext context, final bool fill, final Widget? child)
                  {
                    return Switch(
                      onChanged: (final bool newVal) {fillOptions.fillAdjacent.value = newVal;},
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
                  builder: (final BuildContext context, final bool fill, final Widget? child)
                  {
                    return Switch(
                      onChanged: (final bool newVal) {fillOptions.fillWholeRamp.value = newVal;},
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

}

