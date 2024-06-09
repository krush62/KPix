import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum EraserShape
{
  round,
  square
}

const List<EraserShape> eraserShapeList = [ EraserShape.round, EraserShape.square];

const Map<int, EraserShape> _eraserShapeIndexMap =
{
  0: EraserShape.round,
  1: EraserShape.square
};

const Map<EraserShape, String> eraserShapeStringMap =
{
  EraserShape.round: "Round",
  EraserShape.square: "Square"
};

class EraserOptions extends IToolOptions
{
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final int shapeDefault;

  ValueNotifier<int> size = ValueNotifier(1);
  ValueNotifier<EraserShape> shape = ValueNotifier(EraserShape.round);

  EraserOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.shapeDefault})
  {
    size.value = sizeDefault;
    shape.value = _eraserShapeIndexMap[shapeDefault] ?? EraserShape.round;
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
              child: ValueListenableBuilder<EraserShape>(
                valueListenable: eraserOptions.shape,
                builder: (BuildContext context, EraserShape shape, child)
                {
                  return DropdownButton(
                    value: shape,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (EraserShape? eShape) {eraserOptions.shape.value = eShape!;},
                    items: eraserShapeList.map<DropdownMenuItem<EraserShape>>((EraserShape value) {
                      return DropdownMenuItem<EraserShape>(
                        value: value,
                        child: Text(eraserShapeStringMap[value]!),
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

}