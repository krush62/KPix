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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';

class PencilOptions extends IToolOptions
{
  final ValueNotifier<int> size = ValueNotifier<int>(PencilConstraints.sizeDefault);
  final ValueNotifier<PencilShape> shape = ValueNotifier<PencilShape>(PencilConstraints.shapeDefault);
  final ValueNotifier<bool> pixelPerfect = ValueNotifier<bool>(PencilConstraints.pixelPerfectDefault);

  static Column getWidget({
    required final BuildContext context,
    required final PencilOptions pencilOptions,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSliderRow<int>(
          label: "Size",
          notifier: pencilOptions.size,
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          minVal: PencilConstraints.sizeMin.toDouble(),
          maxVal: PencilConstraints.sizeMax.toDouble(),
          //divisions: pencilOptions.sizeMax - pencilOptions.sizeMin,
        ),
        ToolDropdownRow<PencilShape>(
          label: "Shape",
          notifier: pencilOptions.shape,
          valueMap: PencilShape.getLabelMap(),
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
        ),
        ToolSwitchRow(
          notifier: pencilOptions.pixelPerfect,
          label: "Smooth",
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    size.value = (originalValue + steps).clamp(PencilConstraints.sizeMin, PencilConstraints.sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }

}
