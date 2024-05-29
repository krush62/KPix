import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
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


  ShapeShape shape = ShapeShape.square;
  bool keepRatio = false;
  bool strokeOnly = false;
  int strokeWidth = 1;
  int cornerRadius = 0;

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
    shape = _shapeShapeIndexMap[shapeDefault] ?? ShapeShape.square;
    keepRatio = keepRatioDefault;
    strokeOnly = strokeOnlyDefault;
    strokeWidth = strokeWidthDefault;
    cornerRadius = cornerRadiusDefault;
  }

  static Column getWidget(
  {   required BuildContext context,
      required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
      required ShapeOptions shapeOptions,
      ShapeShapeChanged? shapeShapeChanged,
      ShapeKeepAspectRatioChanged? shapeKeepAspectRatioChanged,
      ShapeStrokeOnlyChanged? shapeStrokeOnlyChanged,
      ShapeStrokeSizeChanged? shapeStrokeSizeChanged,
      ShapeCornerRadiusChanged? shapeCornerRadiusChanged})
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
              child: DropdownButton(
                value: shapeOptions.shape,
                dropdownColor: Theme.of(context).primaryColorDark,
                focusColor: Theme.of(context).primaryColor,
                isExpanded: true,
                onChanged: (ShapeShape? pShape) {shapeShapeChanged!(pShape!);},
                items: shapeShapeList.map<DropdownMenuItem<ShapeShape>>((ShapeShape value) {
                  return DropdownMenuItem<ShapeShape>(
                    value: value,
                    child: Text(shapeShapeStringMap[value]!),
                  );
                }).toList(),

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
                child: Switch(
                  onChanged: shapeKeepAspectRatioChanged,
                  value: shapeOptions.keepRatio,
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
                      child: Switch(
                        onChanged: shapeStrokeOnlyChanged,
                        value: shapeOptions.strokeOnly,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: shapeOptions.strokeWidth.toDouble(),
                      min: shapeOptions.strokeWidthMin.toDouble(),
                      max: shapeOptions.strokeWidthMax.toDouble(),
                      divisions: shapeOptions.strokeWidthMax - shapeOptions.strokeWidthMin,
                      onChanged: shapeOptions.strokeOnly ? shapeStrokeSizeChanged : null,
                      label: shapeOptions.strokeWidth.round().toString(),
                    ),
                  ),
                ],
              )
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
                  "Corner Radius",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Slider(
                value: shapeOptions.cornerRadius.toDouble(),
                min: shapeOptions.cornerRadiusMin.toDouble(),
                max: shapeOptions.cornerRadiusMax.toDouble(),
                divisions: shapeOptions.cornerRadiusMax - shapeOptions.cornerRadiusMin,
                onChanged: shapeCornerRadiusChanged,
                label: shapeOptions.cornerRadius.round().toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}