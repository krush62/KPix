import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum PencilShape
{
  round,
  square
}

const List<PencilShape> pencilShapeList = [ PencilShape.round, PencilShape.square];

const Map<int, PencilShape> _pencilShapeIndexMap =
{
  0: PencilShape.round,
  1: PencilShape.square
};

const Map<PencilShape, String> pencilShapeStringMap =
{
  PencilShape.round: "Round",
  PencilShape.square: "Square"
};

class PencilOptions extends IToolOptions
{
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final int shapeDefault;
  final bool pixelPerfectDefault;

  int size = 1;
  PencilShape shape = PencilShape.round;
  bool pixelPerfect = true;

  PencilOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.shapeDefault,
    required this.pixelPerfectDefault})
  {
    size = sizeDefault;
    shape = _pencilShapeIndexMap[shapeDefault] ?? PencilShape.round;
    pixelPerfect = pixelPerfectDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required PencilOptions pencilOptions,
    PencilSizeChanged? pencilSizeChanged,
    PencilShapeChanged? pencilShapeChanged,
    PencilPixelPerfectChanged? pencilPixelPerfectChanged
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
                value: pencilOptions.size.toDouble(),
                min: pencilOptions.sizeMin.toDouble(),
                max: pencilOptions.sizeMax.toDouble(),
                divisions: pencilOptions.sizeMax - pencilOptions.sizeMin,
                onChanged: pencilSizeChanged,
                label: pencilOptions.size.round().toString(),
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
                  value: pencilOptions.shape,
                  dropdownColor: Theme.of(context).primaryColorDark,
                  focusColor: Theme.of(context).primaryColor,
                  isExpanded: true,
                  onChanged: (PencilShape? pShape) {pencilShapeChanged!(pShape!);},
                  items: pencilShapeList.map<DropdownMenuItem<PencilShape>>((PencilShape value) {
                    return DropdownMenuItem<PencilShape>(
                      value: value,
                      child: Text(pencilShapeStringMap[value]!),
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
                  "Smooth",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Switch(
                    onChanged: pencilPixelPerfectChanged,
                    value: pencilOptions.pixelPerfect
                ),
              )
            ),
          ],
        ),
      ],
    );
  }
}