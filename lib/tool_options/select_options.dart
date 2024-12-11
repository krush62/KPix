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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

enum SelectShape
{
  rectangle,
  ellipse,
  polygon,
  wand

}

const List<SelectShape> selectShapeList =
<SelectShape>[
  SelectShape.rectangle,
  SelectShape.ellipse,
  SelectShape.polygon,
  SelectShape.wand,
];

const Map<int, SelectShape> _selectShapeIndexMap =
<int, SelectShape>{
  0: SelectShape.rectangle,
  1: SelectShape.ellipse,
  2: SelectShape.polygon,
  3: SelectShape.wand,
};

class SelectOptions extends IToolOptions
{
  final int shapeDefault;
  final bool keepAspectRatioDefault;
  final int modeDefault;
  final bool wandContinuousDefault;
  final bool wandWholeRampDefault;

  final ValueNotifier<SelectShape> shape = ValueNotifier<SelectShape>(SelectShape.rectangle);
  final ValueNotifier<SelectionMode> mode = ValueNotifier<SelectionMode>(SelectionMode.replace);
  final ValueNotifier<SelectionMode> unModifiedMode = ValueNotifier<SelectionMode>(SelectionMode.replace);
  final ValueNotifier<bool> keepAspectRatio = ValueNotifier<bool>(false);
  final ValueNotifier<bool> wandContinuous = ValueNotifier<bool>(true);
  final ValueNotifier<bool> wandWholeRamp = ValueNotifier<bool>(false);

  SelectOptions({
    required this.shapeDefault,
    required this.keepAspectRatioDefault,
    required this.modeDefault,
    required this.wandContinuousDefault,
    required this.wandWholeRampDefault,
  })
  {
    keepAspectRatio.value = keepAspectRatioDefault;
    shape.value = _selectShapeIndexMap[shapeDefault] ?? SelectShape.rectangle;
    mode.value = selectionModeIndexMap[modeDefault] ?? SelectionMode.replace;
    unModifiedMode.value = mode.value;
    wandContinuous.value = wandContinuousDefault;
    wandWholeRamp.value = wandWholeRampDefault;
  }


  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required final SelectOptions selectOptions,
  })
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: toolSettingsWidgetOptions.padding, top: toolSettingsWidgetOptions.padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Mode",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                ),
              ),
              Expanded(
                flex: toolSettingsWidgetOptions.columnWidthRatio,
                child: ValueListenableBuilder<bool>(
                  valueListenable: hotkeyManager.shiftNotifier,
                  builder: (final BuildContext _, final bool shiftPressed, final Widget? __) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: hotkeyManager.altNotifier,
                      builder: (final BuildContext ___, final bool altPressed, final Widget? ____) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: hotkeyManager.controlNotifier,
                          builder: (final BuildContext ____, final bool controlPressed, final Widget? _____) {
                            return ValueListenableBuilder<SelectionMode>(
                              valueListenable: selectOptions.unModifiedMode,
                              builder: (final BuildContext _____, final SelectionMode unModifiedMode, final Widget? ______) {
                                SelectionMode newMode = unModifiedMode;
                                if (shiftPressed && !altPressed && !controlPressed)
                                {
                                  newMode = SelectionMode.add;
                                }
                                else if (shiftPressed && altPressed && !controlPressed)
                                {
                                  newMode = SelectionMode.subtract;
                                }
                                else if (shiftPressed && !altPressed && controlPressed)
                                {
                                  newMode = SelectionMode.intersect;
                                }
                                selectOptions.mode.value = newMode;

                                return SegmentedButton<SelectionMode>(
                                  segments: <ButtonSegment<SelectionMode>>[
                                    ButtonSegment<SelectionMode>(value: SelectionMode.replace, label: FaIcon(
                                      FontAwesomeIcons.rotate,
                                      size: toolSettingsWidgetOptions.smallIconSize,
                                    ),),
                                    ButtonSegment<SelectionMode>(value: SelectionMode.add, label: FaIcon(
                                      FontAwesomeIcons.plus,
                                      size: toolSettingsWidgetOptions.smallIconSize,
                                    ),),
                                    ButtonSegment<SelectionMode>(value: SelectionMode.subtract, label: FaIcon(
                                      FontAwesomeIcons.minus,
                                      size: toolSettingsWidgetOptions.smallIconSize,
                                    ),),
                                    ButtonSegment<SelectionMode>(value: SelectionMode.intersect, label: FaIcon(
                                      FontAwesomeIcons.plusMinus,
                                      size: toolSettingsWidgetOptions.smallIconSize,
                                    ),),
                                  ],
                                  selected: <SelectionMode>{selectOptions.mode.value},
                                  showSelectedIcon: false,
                                  onSelectionChanged: (final Set<SelectionMode> modes)
                                  {
                                    if (!shiftPressed && !altPressed && !controlPressed)
                                    {
                                      selectOptions.unModifiedMode.value = modes.first;
                                    }
                                    selectOptions.mode.value = modes.first;
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
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
                child: ValueListenableBuilder<SelectShape>(
                  valueListenable: selectOptions.shape,
                  builder: (final BuildContext context, final SelectShape shape, final Widget? child){
                    return SegmentedButton<SelectShape>
                      (
                      segments: <ButtonSegment<SelectShape>>[
                        ButtonSegment<SelectShape>(
                            value: SelectShape.rectangle,
                            tooltip: "Rectangle",
                            label: FaIcon(
                              FontAwesomeIcons.square,
                              size: toolSettingsWidgetOptions.smallIconSize,
                            ),),
                        ButtonSegment<SelectShape>(
                            value: SelectShape.ellipse,
                            tooltip: "Ellipse",
                            label: FaIcon(
                              FontAwesomeIcons.circle,
                              size: toolSettingsWidgetOptions.smallIconSize,
                            ),),
                        ButtonSegment<SelectShape>(
                            value: SelectShape.polygon,
                            tooltip: "Polygon",
                            label: FaIcon(
                              FontAwesomeIcons.drawPolygon,
                              size: toolSettingsWidgetOptions.smallIconSize,
                            ),),
                        ButtonSegment<SelectShape>(
                            value: SelectShape.wand,
                            tooltip: "Wand",
                            label: FaIcon(
                              FontAwesomeIcons.wandMagicSparkles,
                              size: toolSettingsWidgetOptions.smallIconSize,
                            ),),
                      ],
                      selected: <SelectShape>{shape},
                      showSelectedIcon: false,
                      onSelectionChanged: (final Set<SelectShape> shapes) {selectOptions.shape.value = shapes.first;},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<SelectShape>(
          valueListenable: selectOptions.shape,
          builder: (final BuildContext context, final SelectShape shape, final Widget? child){
            return Visibility(
              visible: shape != SelectShape.polygon,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          (shape == SelectShape.wand) ? "Continuous" : "Keep 1:1",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                    ),
                  ),
                  Expanded(
                      flex: toolSettingsWidgetOptions.columnWidthRatio,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: <Widget>[
                            Visibility(
                                visible: shape == SelectShape.rectangle || shape == SelectShape.ellipse,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: selectOptions.keepAspectRatio,
                                  builder: (final BuildContext context, final bool keep, final Widget? child){
                                    return Switch(
                                        onChanged:  (final bool newVal) {selectOptions.keepAspectRatio.value = newVal;},
                                        value: keep,
                                    );
                                  },
                                ),
                            ),
                            Visibility(
                                visible: shape == SelectShape.wand,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: selectOptions.wandContinuous,
                                  builder: (final BuildContext context, final bool continuous, final Widget? child){
                                    return Switch(
                                      value: continuous,
                                      onChanged: (final bool newVal) {selectOptions.wandContinuous.value = newVal;},
                                    );
                                  },
                                ),
                            ),
                          ],
                        ),
                      ),
                  ),
                ],
              ),
            );
          },
        ),
        ValueListenableBuilder<SelectShape>(
          valueListenable: selectOptions.shape,
          builder: (final BuildContext context, final SelectShape shape, final Widget? child){
            return Visibility(
              visible: shape == SelectShape.wand,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Whole Ramp",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                    ),
                  ),
                  Expanded(
                      flex: toolSettingsWidgetOptions.columnWidthRatio,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: selectOptions.wandWholeRamp,
                          builder: (final BuildContext context, final bool wholeRamp, final Widget? child)
                          {
                            return Switch(
                              value: wholeRamp,
                              onChanged: (final bool newVal) {selectOptions.wandWholeRamp.value = newVal;},
                            );
                          },
                        ),
                      ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

}
