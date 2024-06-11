import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum ShapeShape
{
  square,
  ellipse,
  triangle,
  pentagon,
  hexagon,
  octagon,
  fiveStar,
  sixStar,
  eightStar,
}

const List<ShapeShape> shapeShapeList =
[
  ShapeShape.square,
  ShapeShape.ellipse,
  ShapeShape.triangle,
  ShapeShape.pentagon,
  ShapeShape.hexagon,
  ShapeShape.octagon,
  ShapeShape.fiveStar,
  ShapeShape.sixStar,
  ShapeShape.eightStar,
];

const Map<int, ShapeShape> _shapeShapeIndexMap =
{
  0: ShapeShape.square,
  1: ShapeShape.ellipse,
  2: ShapeShape.triangle,
  3: ShapeShape.pentagon,
  4: ShapeShape.hexagon,
  5: ShapeShape.octagon,
  6: ShapeShape.fiveStar,
  7: ShapeShape.sixStar,
  8: ShapeShape.eightStar,
};

const Map<ShapeShape, String> shapeShapeStringMap =
{
  ShapeShape.square : "Rectangle",
  ShapeShape.ellipse : "Ellipse",
  ShapeShape.triangle : "Triangle",
  ShapeShape.pentagon : "Pentagon",
  ShapeShape.hexagon : "Hexagon",
  ShapeShape.octagon : "Octagon",
  ShapeShape.fiveStar : "5-Star",
  ShapeShape.sixStar : "6-Star",
  ShapeShape.eightStar : "8-Star",
};

class ShapeOptions extends IToolOptions
{
  final int shapeDefault;
  final bool keepRatioDefault;
  final bool strokeOnlyDefault;
  final int strokeWidthMin;
  final int strokeWidthMax;
  final int strokeWidthDefault;
  final int cornerRadiusMin;
  final int cornerRadiusMax;
  final int cornerRadiusDefault;


  ValueNotifier<ShapeShape> shape = ValueNotifier(ShapeShape.square);
  ValueNotifier<bool> keepRatio = ValueNotifier(false);
  ValueNotifier<bool> strokeOnly = ValueNotifier(false);
  ValueNotifier<int> strokeWidth = ValueNotifier(1);
  ValueNotifier<int> cornerRadius = ValueNotifier(0);

  ShapeOptions({
    required this.shapeDefault,
    required this.keepRatioDefault,
    required this.strokeOnlyDefault,
    required this.strokeWidthMin,
    required this.strokeWidthMax,
    required this.strokeWidthDefault,
    required this.cornerRadiusMin,
    required this.cornerRadiusMax,
    required this.cornerRadiusDefault
  }) {
    shape.value = _shapeShapeIndexMap[shapeDefault] ?? ShapeShape.square;
    keepRatio.value = keepRatioDefault;
    strokeOnly.value = strokeOnlyDefault;
    strokeWidth.value = strokeWidthDefault;
    cornerRadius.value = cornerRadiusDefault;
  }

  static Column getWidget(
  {   required BuildContext context,
      required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
      required ShapeOptions shapeOptions})
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
              child: ValueListenableBuilder<ShapeShape>(
                valueListenable: shapeOptions.shape,
                builder: (BuildContext context, ShapeShape shape, child)
                {
                  return DropdownButton(
                    value: shape,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (ShapeShape? pShape) {shapeOptions.shape.value = pShape!;},
                    items: shapeShapeList.map<DropdownMenuItem<ShapeShape>>((ShapeShape value) {
                      return DropdownMenuItem<ShapeShape>(
                        value: value,
                        child: Text(shapeShapeStringMap[value]!),
                      );
                    }).toList(),
                  );
                },
              ),
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
                  "Keep 1:1",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: shapeOptions.keepRatio,
                  builder: (BuildContext context, bool keep, child)
                  {
                    return Switch(
                      onChanged: (bool newVal) {shapeOptions.keepRatio.value = newVal;},
                      value: keep,
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
                  "Stroke Only",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: shapeOptions.strokeOnly,
                        builder: (BuildContext context, bool strokeOnly, child)
                        {
                          return Switch(
                            onChanged: (bool newVal) {shapeOptions.strokeOnly.value = newVal;},
                            value: strokeOnly,
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ValueListenableBuilder<int>(
                      valueListenable: shapeOptions.strokeWidth,
                      builder: (BuildContext context, int width, child)
                      {
                        return Slider(
                          value: width.toDouble(),
                          min: shapeOptions.strokeWidthMin.toDouble(),
                          max: shapeOptions.strokeWidthMax.toDouble(),
                          divisions: shapeOptions.strokeWidthMax - shapeOptions.strokeWidthMin,
                          onChanged: shapeOptions.strokeOnly.value ? (double newVal) {shapeOptions.strokeWidth.value = newVal.round();} : null,
                          label: width.round().toString(),
                        );
                      },
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: shapeOptions.shape,
          builder: (BuildContext context, ShapeShape shape, child)
          {
            return Visibility(
              visible: shape == ShapeShape.square,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Corner Radius",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: shapeOptions.cornerRadius,
                      builder: (BuildContext context, int cornerRadius, child)
                      {
                        return Slider(
                          value: cornerRadius.toDouble(),
                          min: shapeOptions.cornerRadiusMin.toDouble(),
                          max: shapeOptions.cornerRadiusMax.toDouble(),
                          divisions: shapeOptions.cornerRadiusMax - shapeOptions.cornerRadiusMin,
                          onChanged: (double newVal) {shapeOptions.cornerRadius.value = newVal.round();},
                          label: cornerRadius.round().toString(),
                        );
                      }
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ],
    );
  }
}