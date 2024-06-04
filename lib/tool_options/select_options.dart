import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum SelectShape
{
  rectangle,
  ellipse,
  polygon
}

const List<SelectShape> selectShapeList = [
  SelectShape.rectangle,
  SelectShape.ellipse,
  SelectShape.polygon
];

const Map<int, SelectShape> _selectShapeIndexMap =
{
  0: SelectShape.rectangle,
  1: SelectShape.ellipse,
  2: SelectShape.polygon
};

const Map<SelectShape, String> selectShapeStringMap =
{
  SelectShape.rectangle : "Rectangle",
  SelectShape.ellipse : "Ellipse",
  SelectShape.polygon : "Polygon"
};

class SelectOptions extends IToolOptions
{
  final int shapeDefault;
  final bool keepAspectRatioDefault;
  final int modeDefault;

  SelectShape shape = SelectShape.rectangle;
  SelectionMode mode = SelectionMode.replace;
  bool keepAspectRatio = false;

  SelectOptions({
  required this.shapeDefault,
  required this.keepAspectRatioDefault,
  required this.modeDefault
  })
  {
    keepAspectRatio = keepAspectRatioDefault;
    shape = _selectShapeIndexMap[shapeDefault] ?? SelectShape.rectangle;
    mode = selectionModeIndexMap[modeDefault] ?? SelectionMode.replace;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required SelectOptions selectOptions,
    SelectShapeChanged? selectShapeChanged,
    SelectKeepAspectRatioChanged? selectKeepAspectRatioChanged,
    SelectionModeChanged? selectionModeChanged
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
                    "Shape",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
                flex: toolSettingsWidgetOptions.columnWidthRatio,
                child: DropdownButton(
                  value: selectOptions.shape,
                  dropdownColor: Theme.of(context).primaryColorDark,
                  focusColor: Theme.of(context).primaryColor,
                  isExpanded: true,
                  onChanged: (SelectShape? sShape) {selectShapeChanged!(sShape!);},
                  items: selectShapeList.map<DropdownMenuItem<SelectShape>>((SelectShape value) {
                    return DropdownMenuItem<SelectShape>(
                      value: value,
                      child: Text(selectShapeStringMap[value]!),
                    );
                  }).toList(),
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
                      onChanged: (selectOptions.shape == SelectShape.rectangle || selectOptions.shape == SelectShape.ellipse) ? selectKeepAspectRatioChanged : null,
                      value: selectOptions.keepAspectRatio
                  ),
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
                  "Mode",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: DropdownButton(
                value: selectOptions.mode,
                dropdownColor: Theme.of(context).primaryColorDark,
                focusColor: Theme.of(context).primaryColor,
                isExpanded: true,
                onChanged: (SelectionMode? sMode) {selectionModeChanged!(sMode!);},
                items: selectionModeList.map<DropdownMenuItem<SelectionMode>>((SelectionMode value) {
                  return DropdownMenuItem<SelectionMode>(
                    value: value,
                    child: Text(selectionModeStringMap[value]!),
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