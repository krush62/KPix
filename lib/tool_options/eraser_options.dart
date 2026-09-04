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
import 'package:kpix/models/constraints/tool_eraser_constraints.dart';
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class EraserOptions extends IToolOptions
{
  final ValueNotifier<int> size = ValueNotifier<int>(EraserConstraints.sizeDefault);
  final ValueNotifier<PencilShape> shape = ValueNotifier<PencilShape>(EraserConstraints.shapeDefault);

  static Column getWidget({
    required final BuildContext context,
    required final EraserOptions eraserOptions,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSliderRow<int>(
          label: "Size",
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          notifier: eraserOptions.size,
          minVal: EraserConstraints.sizeMin.toDouble(),
          maxVal: EraserConstraints.sizeMax.toDouble(),
        ),
        ToolDropdownRow<PencilShape>(
          label: "Shape",
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          notifier: eraserOptions.shape,
          valueMap: PencilShape.getLabelMap(),
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    size.value = (originalValue + steps).clamp(EraserConstraints.sizeMin, EraserConstraints.sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }
}
