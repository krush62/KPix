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
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

enum PencilShape
{
  round,
  square
}

const List<PencilShape> pencilShapeList = <PencilShape>[ PencilShape.round, PencilShape.square];

const Map<int, PencilShape> pencilShapeIndexMap =
<int, PencilShape>{
  0: PencilShape.round,
  1: PencilShape.square,
};

const Map<PencilShape, String> pencilShapeStringMap =
<PencilShape, String>{
  PencilShape.round: "Round",
  PencilShape.square: "Square",
};

class PencilOptions extends IToolOptions
{
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final int shapeDefault;
  final bool pixelPerfectDefault;

  final ValueNotifier<int> size = ValueNotifier<int>(1);
  final ValueNotifier<PencilShape> shape = ValueNotifier<PencilShape>(PencilShape.round);
  final ValueNotifier<bool> pixelPerfect = ValueNotifier<bool>(true);

  PencilOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.shapeDefault,
    required this.pixelPerfectDefault,})
  {
    size.value = sizeDefault;
    shape.value = pencilShapeIndexMap[shapeDefault] ?? PencilShape.round;
    pixelPerfect.value = pixelPerfectDefault;
  }

  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
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
          flex: toolSettingsWidgetOptions.columnWidthRatio,
          minVal: pencilOptions.sizeMin.toDouble(),
          maxVal: pencilOptions.sizeMax.toDouble(),
          //divisions: pencilOptions.sizeMax - pencilOptions.sizeMin,
        ),
        ToolDropdownRow<PencilShape>(
          label: "Shape",
          notifier: pencilOptions.shape,
          valueMap: pencilShapeStringMap,
          flex: toolSettingsWidgetOptions.columnWidthRatio,
        ),
        ToolSwitchRow(
          notifier: pencilOptions.pixelPerfect,
          label: "Smooth",
          flex: toolSettingsWidgetOptions.columnWidthRatio,
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    size.value = (originalValue + steps).clamp(sizeMin, sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }

}
