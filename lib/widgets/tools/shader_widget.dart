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
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/painting/shader_options.dart';

class ShaderWidgetOptions {
  final double outSidePadding;
  const ShaderWidgetOptions({required this.outSidePadding});
}

class ShaderWidget extends StatefulWidget {

  final TextStyle? titleStyle;
  final TextStyle? labelStyle;

  const ShaderWidget(
      {super.key,
        required this.titleStyle,
        required this.labelStyle,
});

  @override
  State<ShaderWidget> createState() => _ShaderWidgetState();
}

class _ShaderWidgetState extends State<ShaderWidget>
{
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final ShaderWidgetOptions _shaderWidgetOptions = GetIt.I.get<PreferenceManager>().shaderWidgetOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  @override
  void initState()
  {
    super.initState();

    _hotkeyManager.addListener(func: () {_shaderOptions.isEnabled.value = !_shaderOptions.isEnabled.value;}, action: HotkeyAction.shadingToggle);
    _hotkeyManager.addListener(func: () {_shaderOptions.onlyCurrentRampEnabled.value = !_shaderOptions.onlyCurrentRampEnabled.value;}, action: HotkeyAction.shadingCurrentRampOnly);
    _hotkeyManager.addListener(func: () {_shaderOptions.shaderDirection.value = (_shaderOptions.shaderDirection.value == ShaderDirection.left) ? ShaderDirection.right : ShaderDirection.left;}, action: HotkeyAction.shadingDirection);
  }

  @override
  Widget build(BuildContext context)
  {
    return Padding (
      padding: EdgeInsets.all(_shaderWidgetOptions.outSidePadding),
      child: ValueListenableBuilder<bool>(
        valueListenable: _shaderOptions.isEnabled,
        builder: (final BuildContext context, final bool isEnabled, final Widget? child){
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () {_shaderOptions.isEnabled.value = !isEnabled;},
                      child: Text("Shading",
                        textAlign: TextAlign.start, style: isEnabled ? widget.titleStyle?.apply(color: Theme.of(context).primaryColorLight) : widget.titleStyle?.apply(color: Theme.of(context).primaryColorDark)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: _shaderWidgetOptions.outSidePadding),
                      child: Text("Enabled",
                        textAlign: TextAlign.end, style: widget.labelStyle),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Tooltip(
                      waitDuration: AppState.toolTipDuration,
                      message:_hotkeyManager.getShortcutString(action: HotkeyAction.shadingToggle, precededNewLine: false),
                      child: Switch(
                        onChanged: (final bool newState) {
                          _shaderOptions.isEnabled.value = newState;
                        },
                        value: isEnabled,
                      ),
                    )
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: _shaderWidgetOptions.outSidePadding),
                      child: Text("Current Ramp Only",
                          textAlign: TextAlign.start, style: widget.labelStyle),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _shaderOptions.onlyCurrentRampEnabled,
                      builder: (final BuildContext context, final bool onlyCurrentRampEnabled, final Widget? child)
                      {
                        return Tooltip(
                          waitDuration: AppState.toolTipDuration,
                          message:_hotkeyManager.getShortcutString(action: HotkeyAction.shadingCurrentRampOnly, precededNewLine: false),
                          child: Switch(
                            onChanged: isEnabled
                              ? (bool newState) { _shaderOptions.onlyCurrentRampEnabled.value = newState;}
                              : null,
                            value: onlyCurrentRampEnabled,
                          ),
                        );
                      },

                    )
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: _shaderWidgetOptions.outSidePadding),
                      child: Text("Direction",
                          textAlign: TextAlign.end, style: widget.labelStyle),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<ShaderDirection>(
                      valueListenable: _shaderOptions.shaderDirection,
                      builder: (final BuildContext context, final ShaderDirection direction, final Widget? child)
                      {
                        return Tooltip(
                          waitDuration: AppState.toolTipDuration,
                          message:_hotkeyManager.getShortcutString(action: HotkeyAction.shadingDirection, precededNewLine: false),
                          child: Switch(
                            onChanged: isEnabled
                              ? (bool newState) {_shaderOptions.shaderDirection.value = newState ? ShaderDirection.right : ShaderDirection.left;}
                              : null,
                            value: direction == ShaderDirection.right,
                          ),
                        );
                      },
                    )
                  ),
                ],
              ),
            ],
          );
        },
      )
    );
  }
}