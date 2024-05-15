import 'package:flutter/material.dart';
import 'package:kpix/typedefs.dart';
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

class EraserOptions
{
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final int shapeDefault;

  int size = 1;
  EraserShape shape = EraserShape.round;

  EraserOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.shapeDefault})
  {
    size = sizeDefault;
    shape = _eraserShapeIndexMap[shapeDefault] ?? EraserShape.round;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required EraserOptions eraserOptions,
    EraserSizeChanged? eraserSizeChanged,
    EraserShapeChanged? eraserShapeChanged,
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
              child: Slider(
                value: eraserOptions.size.toDouble(),
                min: eraserOptions.sizeMin.toDouble(),
                max: eraserOptions.sizeMax.toDouble(),
                divisions: eraserOptions.sizeMax - eraserOptions.sizeMin,
                onChanged: eraserSizeChanged,
                label: eraserOptions.size.round().toString(),
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
              child: DropdownButton(
                value: eraserOptions.shape,
                dropdownColor: Theme.of(context).primaryColorDark,
                focusColor: Theme.of(context).primaryColor,
                isExpanded: true,
                onChanged: (EraserShape? eShape) {eraserShapeChanged!(eShape!);},
                items: eraserShapeList.map<DropdownMenuItem<EraserShape>>((EraserShape value) {
                  return DropdownMenuItem<EraserShape>(
                    value: value,
                    child: Text(eraserShapeStringMap[value]!),
                  );
                }).toList(),
              )
            ),
          ],
        ),
      ],
    );
  }

}