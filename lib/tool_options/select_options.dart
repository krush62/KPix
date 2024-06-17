import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum SelectShape
{
  rectangle,
  ellipse,
  polygon,
  wand

}

const List<SelectShape> selectShapeList = [
  SelectShape.rectangle,
  SelectShape.ellipse,
  SelectShape.polygon,
  SelectShape.wand,
];

const Map<int, SelectShape> _selectShapeIndexMap =
{
  0: SelectShape.rectangle,
  1: SelectShape.ellipse,
  2: SelectShape.polygon,
  3: SelectShape.wand
};

class SelectOptions extends IToolOptions
{
  final int shapeDefault;
  final bool keepAspectRatioDefault;
  final int modeDefault;
  final bool wandContinuousDefault;
  final bool wandWholeRampDefault;

  ValueNotifier<SelectShape> shape = ValueNotifier(SelectShape.rectangle);
  ValueNotifier<SelectionMode> mode = ValueNotifier(SelectionMode.replace);
  ValueNotifier<bool> keepAspectRatio = ValueNotifier(false);
  ValueNotifier<bool> wandContinuous = ValueNotifier(true);
  ValueNotifier<bool> wandWholeRamp = ValueNotifier(false);

  SelectOptions({
  required this.shapeDefault,
  required this.keepAspectRatioDefault,
  required this.modeDefault,
  required this.wandContinuousDefault,
  required this.wandWholeRampDefault
  })
  {
    keepAspectRatio.value = keepAspectRatioDefault;
    shape.value = _selectShapeIndexMap[shapeDefault] ?? SelectShape.rectangle;
    mode.value = selectionModeIndexMap[modeDefault] ?? SelectionMode.replace;
    wandContinuous.value = wandContinuousDefault;
    wandWholeRamp.value = wandWholeRampDefault;
  }


  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required SelectOptions selectOptions,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: toolSettingsWidgetOptions.padding, top: toolSettingsWidgetOptions.padding),
          child: Row(
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
                child: ValueListenableBuilder<SelectionMode>(
                  valueListenable: selectOptions.mode,
                  builder: (BuildContext context, SelectionMode mode, child){
                    return SegmentedButton<SelectionMode>
                      (
                      segments: [
                        ButtonSegment(value: SelectionMode.replace, label: FaIcon(
                          FontAwesomeIcons.rotate,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        )),
                        ButtonSegment(value: SelectionMode.add, label: FaIcon(
                          FontAwesomeIcons.plus,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        )),
                        ButtonSegment(value: SelectionMode.subtract, label: FaIcon(
                          FontAwesomeIcons.minus,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        )),
                        ButtonSegment(value: SelectionMode.intersect, label: FaIcon(
                          FontAwesomeIcons.plusMinus,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        ))
                      ],
                      selected: <SelectionMode>{selectOptions.mode.value},
                      emptySelectionAllowed: false,
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                      onSelectionChanged: (Set<SelectionMode> modes) {selectOptions.mode.value = modes.first;},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: toolSettingsWidgetOptions.padding, top: toolSettingsWidgetOptions.padding),
          child: Row(
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
                child: ValueListenableBuilder<SelectShape>(
                  valueListenable: selectOptions.shape,
                  builder: (BuildContext context, SelectShape shape, child){
                    return SegmentedButton<SelectShape>
                      (
                      segments: [
                        ButtonSegment(value: SelectShape.rectangle, label: FaIcon(
                          FontAwesomeIcons.square,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        )),
                        ButtonSegment(value: SelectShape.ellipse, label: FaIcon(
                          FontAwesomeIcons.circle,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        )),
                        ButtonSegment(value: SelectShape.polygon, label: FaIcon(
                          FontAwesomeIcons.drawPolygon,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        )),
                        ButtonSegment(value: SelectShape.wand, label: FaIcon(
                          FontAwesomeIcons.wandMagicSparkles,
                          size: toolSettingsWidgetOptions.smallIconSize,
                        ))
                      ],
                      selected: <SelectShape>{selectOptions.shape.value},
                      emptySelectionAllowed: false,
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                      onSelectionChanged: (Set<SelectShape> shapes) {selectOptions.shape.value = shapes.first;},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: selectOptions.shape,
          builder: (BuildContext context, SelectShape shape, child){
            return Visibility(
              visible: (shape != SelectShape.polygon),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            (shape == SelectShape.wand) ? "Continuous" : "Keep 1:1",
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                    ),
                  ),
                  Expanded(
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        children: [
                          Visibility(
                              visible: (shape == SelectShape.rectangle || shape == SelectShape.ellipse),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: selectOptions.keepAspectRatio,
                                builder: (BuildContext context, bool keep, child)
                                {
                                  return Switch(
                                      onChanged:  (bool newVal) {selectOptions.keepAspectRatio.value = newVal;},
                                      value: keep
                                  );
                                },
                              )
                          ),
                          Visibility(
                              visible: (shape == SelectShape.wand),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: selectOptions.wandContinuous,
                                builder: (BuildContext context, bool continuous, child){
                                  return Switch(
                                    value: continuous,
                                    onChanged: (bool newVal) {selectOptions.wandContinuous.value = newVal;},
                                  );
                                },
                              )
                          )
                        ],
                      ),
                    )
                  ),
                ],
              ),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: selectOptions.shape,
          builder: (BuildContext context, SelectShape shape, child){
            return Visibility(
              visible: (shape == SelectShape.wand),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Whole Ramp",
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                    ),
                  ),
                  Expanded(
                      flex: toolSettingsWidgetOptions.columnWidthRatio,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: selectOptions.wandWholeRamp,
                          builder: (BuildContext context, bool wholeRamp, child)
                          {
                            return Switch(
                              value: wholeRamp,
                              onChanged: (bool newVal) {selectOptions.wandWholeRamp.value = newVal;},
                            );
                          },
                        ),
                      )
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void changeSize(int steps, int originalValue){}

  @override
  int getSize()
  {
    return 0;
  }

}