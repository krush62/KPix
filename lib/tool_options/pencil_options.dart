import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum PencilShape
{
  round,
  square
}

const List<PencilShape> pencilShapeList = [ PencilShape.round, PencilShape.square];

const Map<int, PencilShape> pencilShapeIndexMap =
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

  ValueNotifier<int> size = ValueNotifier(1);
  ValueNotifier<PencilShape> shape = ValueNotifier(PencilShape.round);
  ValueNotifier<bool> pixelPerfect = ValueNotifier(true);

  PencilOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.shapeDefault,
    required this.pixelPerfectDefault})
  {
    size.value = sizeDefault;
    shape.value = pencilShapeIndexMap[shapeDefault] ?? PencilShape.round;
    pixelPerfect.value = pixelPerfectDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required PencilOptions pencilOptions,
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
                valueListenable: pencilOptions.size,
                builder: (BuildContext context, int size, child)
                {
                  return Slider(
                    value: size.toDouble(),
                    min: pencilOptions.sizeMin.toDouble(),
                    max: pencilOptions.sizeMax.toDouble(),
                    divisions: pencilOptions.sizeMax - pencilOptions.sizeMin,
                    onChanged: (double newVal) {pencilOptions.size.value = newVal.round();},
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
                  valueListenable: pencilOptions.shape,
                  builder: (BuildContext context, PencilShape shape, child)
                  {
                    return DropdownButton(
                      value: shape,
                      dropdownColor: Theme.of(context).primaryColorDark,
                      focusColor: Theme.of(context).primaryColor,
                      isExpanded: true,
                      onChanged: (PencilShape? pShape) {pencilOptions.shape.value = pShape!;},
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
                child: ValueListenableBuilder<int>(
                  valueListenable: pencilOptions.size,
                  builder: (BuildContext context, int size, child)
                  {
                    return ValueListenableBuilder<bool>(
                      valueListenable: pencilOptions.pixelPerfect,
                      builder: (BuildContext context, bool pp, child)
                      {
                        return Switch(
                          onChanged: size == 1 ? (bool newVal) {pencilOptions.pixelPerfect.value = newVal;} : null,
                          value: pp
                        );
                      },
                    );
                  },
                ),
              )
            ),
          ],
        ),
      ],
    );
  }
}