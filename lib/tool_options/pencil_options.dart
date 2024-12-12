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
import 'package:kpix/widgets/controls/kpix_slider.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Size",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: pencilOptions.size,
                builder: (final BuildContext context, final int size, final Widget? child)
                {
                  return KPixSlider(
                    value: size.toDouble(),
                    min: pencilOptions.sizeMin.toDouble(),
                    max: pencilOptions.sizeMax.toDouble(),
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                    divisions: pencilOptions.sizeMax - pencilOptions.sizeMin,
                    onChanged: (final double newVal) {pencilOptions.size.value = newVal.round();},
                  );
                },
              ),
            ),

          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Shape",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<PencilShape>(
                valueListenable: pencilOptions.shape,
                builder: (final BuildContext context, final PencilShape shape, final Widget? child)
                {
                  return DropdownButton<PencilShape>(
                    value: shape,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (final PencilShape? pShape) {pencilOptions.shape.value = pShape!;},
                    items: pencilShapeList.map<DropdownMenuItem<PencilShape>>((final PencilShape value) {
                      return DropdownMenuItem<PencilShape>(
                        value: value,
                        child: Text(pencilShapeStringMap[value]!),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Smooth",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<int>(
                  valueListenable: pencilOptions.size,
                  builder: (final BuildContext context, final int size, final Widget? child)
                  {
                    return ValueListenableBuilder<bool>(
                      valueListenable: pencilOptions.pixelPerfect,
                      builder: (final BuildContext context, final bool isPixelPerfect, final Widget? child)
                      {
                        return Switch(
                          onChanged: (final bool newVal) {pencilOptions.pixelPerfect.value = newVal;},
                          value: isPixelPerfect,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
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
