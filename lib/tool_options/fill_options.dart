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
import 'package:kpix/models/constraints/tool_fill_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';

class FillOptions extends IToolOptions
{
  final ValueNotifier<bool> fillAdjacent = ValueNotifier<bool>(FillConstraints.fillAdjacentDefault);
  final ValueNotifier<bool> fillWholeRamp = ValueNotifier<bool>(FillConstraints.fillWholeRampDefault);

  static Column getWidget({
    required final BuildContext context,
    required final FillOptions fillOptions,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSwitchRow(
          //flex: toolSettingsWidgetOptions.columnWidthRatio,
          notifier: fillOptions.fillAdjacent,
          label: "Fill Adjacent",
        ),
        ToolSwitchRow(
          //flex: toolSettingsWidgetOptions.columnWidthRatio,
          notifier: fillOptions.fillWholeRamp,
          label: "Fill whole ramp",
        ),
      ],
    );
  }

}
