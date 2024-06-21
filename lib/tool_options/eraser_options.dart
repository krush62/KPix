import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

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
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required EraserOptions eraserOptions,
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
                builder: (BuildContext context, int size, child)
                {
                  return Slider(
                    value: size.toDouble(),
                    min: eraserOptions.sizeMin.toDouble(),
                    max: eraserOptions.sizeMax.toDouble(),
                    divisions: eraserOptions.sizeMax - eraserOptions.sizeMin,
                    onChanged: (double newVal) {eraserOptions.size.value = newVal.round();},
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
                builder: (BuildContext context, PencilShape shape, child)
                {
                  return DropdownButton(
                    value: shape,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (PencilShape? eShape) {eraserOptions.shape.value = eShape!;},
                    items: pencilShapeList.map<DropdownMenuItem<PencilShape>>((PencilShape value) {
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
  void changeSize(int steps, int originalValue)
  {
    size.value = min(max(originalValue + steps, sizeMin), sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }
}