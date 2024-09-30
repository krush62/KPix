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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class EraserOptions extends IToolOptions
{
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final int shapeDefault;

  final ValueNotifier<int> size = ValueNotifier(1);
  final ValueNotifier<PencilShape> shape = ValueNotifier(PencilShape.round);

  EraserOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.shapeDefault})
  {
    size.value = sizeDefault;
    shape.value = pencilShapeIndexMap[shapeDefault] ?? PencilShape.round;
  }

  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required final EraserOptions eraserOptions,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Size",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: eraserOptions.size,
                builder: (final BuildContext context, final int size, final Widget? child)
                {
                  return Slider(
                    value: size.toDouble(),
                    min: eraserOptions.sizeMin.toDouble(),
                    max: eraserOptions.sizeMax.toDouble(),
                    divisions: eraserOptions.sizeMax - eraserOptions.sizeMin,
                    onChanged: (final double newVal) {eraserOptions.size.value = newVal.round();},
                    label: size.round().toString(),
                  );
                },
              ),
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
                  "Shape",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<PencilShape>(
                valueListenable: eraserOptions.shape,
                builder: (final BuildContext context, final PencilShape shape, final Widget? child)
                {
                  return DropdownButton(
                    value: shape,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (final PencilShape? eShape) {eraserOptions.shape.value = eShape!;},
                    items: pencilShapeList.map<DropdownMenuItem<PencilShape>>((final PencilShape value) {
                      return DropdownMenuItem<PencilShape>(
                        value: value,
                        child: Text(pencilShapeStringMap[value]!),
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
  void changeSize({required final int steps, required final int originalValue})
  {
    size.value = min(max(originalValue + steps, sizeMin), sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }
}