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
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/constraints/tool_select_constraints.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';



class SelectOptions extends IToolOptions
{
  final ValueNotifier<SelectShape> shape = ValueNotifier<SelectShape>(SelectConstraints.shapeDefault);
  final ValueNotifier<SelectMode> mode = ValueNotifier<SelectMode>(SelectConstraints.modeDefault);
  final ValueNotifier<SelectMode> unModifiedMode = ValueNotifier<SelectMode>(SelectConstraints.modeDefault);
  final ValueNotifier<bool> keepAspectRatio = ValueNotifier<bool>(SelectConstraints.keepAspectRatioDefault);
  final ValueNotifier<bool> wandContinuous = ValueNotifier<bool>(SelectConstraints.wandContinuousDefault);
  final ValueNotifier<bool> wandWholeRamp = ValueNotifier<bool>(SelectConstraints.wandWholeRampDefault);

  static Column getWidget({
    required final BuildContext context,
    required final SelectOptions selectOptions,
  })
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: ToolSettingsWidgetOptions.padding, top: ToolSettingsWidgetOptions.padding),
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
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
                child: ValueListenableBuilder<bool>(
                  valueListenable: hotkeyManager.shiftNotifier,
                  builder: (final BuildContext _, final bool shiftPressed, final Widget? __) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: hotkeyManager.altNotifier,
                      builder: (final BuildContext ___, final bool altPressed, final Widget? ____) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: hotkeyManager.controlNotifier,
                          builder: (final BuildContext ____, final bool controlPressed, final Widget? _____) {
                            return ValueListenableBuilder<SelectMode>(
                              valueListenable: selectOptions.unModifiedMode,
                              builder: (final BuildContext _____, final SelectMode unModifiedMode, final Widget? ______) {
                                SelectMode newMode = unModifiedMode;
                                if (shiftPressed && !altPressed && !controlPressed)
                                {
                                  newMode = SelectMode.add;
                                }
                                else if (shiftPressed && altPressed && !controlPressed)
                                {
                                  newMode = SelectMode.subtract;
                                }
                                else if (shiftPressed && !altPressed && controlPressed)
                                {
                                  newMode = SelectMode.intersect;
                                }
                                selectOptions.mode.value = newMode;

                                final List<ButtonSegment<SelectMode>> segList = <ButtonSegment<SelectMode>>[];
                                for (final SelectMode sMode in SelectMode.values)
                                {
                                  segList.add(
                                      ButtonSegment<SelectMode>(
                                        value: sMode,
                                        label: Tooltip(
                                          showDuration: toolTipDuration,
                                          message: sMode.label,
                                          child: Icon(
                                              sMode.icon,
                                              size: ToolSettingsWidgetOptions.smallIconSize,
                                          ),
                                        ),
                                      ),
                                  );
                                }

                                return SegmentedButton<SelectMode>(
                                  segments: segList,
                                  selected: <SelectMode>{selectOptions.mode.value},
                                  showSelectedIcon: false,
                                  onSelectionChanged: (final Set<SelectMode> modes)
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
          padding: const EdgeInsets.only(bottom: ToolSettingsWidgetOptions.padding, top: ToolSettingsWidgetOptions.padding),
          child: ToolSegmentedIconButtonRow<SelectShape>(
            iconData: SelectShape.getLabelIconMap(),
            label: "Shape",
            notifier: selectOptions.shape,
            //flex: ToolSettingsWidgetOptions.columnWidthRatio,
            iconSize: ToolSettingsWidgetOptions.smallIconSize,
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
                      flex: ToolSettingsWidgetOptions.columnWidthRatio,
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
              child: ToolSwitchRow(
                notifier: selectOptions.wandWholeRamp,
                label: "Whole Ramp",
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
              ),
            );
          },
        ),
      ],
    );
  }

}
