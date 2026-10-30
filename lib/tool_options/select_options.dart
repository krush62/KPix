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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';



class SelectOptions extends IToolOptions
{
  final ValueNotifier<SelectShape> shape = ValueNotifier<SelectShape>(SelectConstraints.shapeDefault);
  final ValueNotifier<SelectMode> mode = ValueNotifier<SelectMode>(SelectConstraints.modeDefault);
  final ValueNotifier<SelectMode> unModifiedMode = ValueNotifier<SelectMode>(SelectConstraints.modeDefault);
  final ValueNotifier<bool> keepAspectRatio = ValueNotifier<bool>(SelectConstraints.keepAspectRatioDefault);
  final ValueNotifier<bool> wandContinuous = ValueNotifier<bool>(SelectConstraints.wandContinuousDefault);
  final ValueNotifier<bool> wandWholeRamp = ValueNotifier<bool>(SelectConstraints.wandWholeRampDefault);
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  SelectOptions()
  {
    Listenable.merge(<Listenable>[_hotkeyManager.shiftNotifier, _hotkeyManager.altNotifier, _hotkeyManager.controlNotifier, unModifiedMode]).addListener(_updateMode);
  }

  void _updateMode()
  {
    final bool shiftPressed = _hotkeyManager.shiftIsPressed;
    final bool altPressed = _hotkeyManager.altIsPressed;
    final bool controlPressed = _hotkeyManager.controlIsPressed;
    SelectMode newMode = unModifiedMode.value;
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
    mode.value = newMode;
  }

  /// A mode chosen while a modifier is held only lasts until the modifiers change.
  void chooseMode({required final SelectMode newMode})
  {
    if (_hotkeyManager.noModifierIsPressed())
    {
      unModifiedMode.value = newMode;
    }
    mode.value = newMode;
  }

  static Column getWidget({
    required final BuildContext context,
    required final SelectOptions selectOptions,
  })
  {
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
                      AppLocalizations.of(context)!.mode,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                ),
              ),
              Expanded(
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
                child: _getModeSelector(selectOptions: selectOptions),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: ToolSettingsWidgetOptions.padding, top: ToolSettingsWidgetOptions.padding),
          child: ToolSegmentedIconButtonRow<SelectShape>(
            iconData: SelectShape.getLabelIconMap(AppLocalizations.of(context)!),
            label: AppLocalizations.of(context)!.shape,
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
                          (shape == SelectShape.wand) ? AppLocalizations.of(context)!.continuous : AppLocalizations.of(context)!.keep1to1,
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
                            _getSwitch(visible: shape == SelectShape.rectangle || shape == SelectShape.ellipse, notifier: selectOptions.keepAspectRatio),
                            _getSwitch(visible: shape == SelectShape.wand, notifier: selectOptions.wandContinuous),
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
                label: AppLocalizations.of(context)!.wholeRamp,
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
              ),
            );
          },
        ),
      ],
    );
  }

  static Widget _getModeSelector({required final SelectOptions selectOptions})
  {
    return ValueListenableBuilder<SelectMode>(
      valueListenable: selectOptions.mode,
      builder: (final BuildContext context, final SelectMode mode, final Widget? child) {
        final List<ButtonSegment<SelectMode>> segList = <ButtonSegment<SelectMode>>[];
        for (final SelectMode sMode in SelectMode.values)
        {
          segList.add(
              ButtonSegment<SelectMode>(
                value: sMode,
                tooltip: sMode.label(AppLocalizations.of(context)!),
                icon: Icon(
                  sMode.icon,
                  size: ToolSettingsWidgetOptions.smallIconSize,
                ),
              ),
          );
        }

        return SegmentedButton<SelectMode>(
          segments: segList,
          selected: <SelectMode>{mode},
          showSelectedIcon: false,
          onSelectionChanged: (final Set<SelectMode> modes)
          {
            selectOptions.chooseMode(newMode: modes.first);
          },
        );
      },
    );
  }

  static Widget _getSwitch({required final bool visible, required final ValueNotifier<bool> notifier})
  {
    return Visibility(
      visible: visible,
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (final BuildContext context, final bool value, final Widget? child){
          return Switch(
            value: value,
            onChanged: (final bool newVal) {notifier.value = newVal;},
          );
        },
      ),
    );
  }

}
