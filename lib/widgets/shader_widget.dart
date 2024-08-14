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
import 'package:kpix/managers/preference_manager.dart';
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

class _ShaderWidgetState extends State<ShaderWidget> {
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final ShaderWidgetOptions _shaderWidgetOptions = GetIt.I.get<PreferenceManager>().shaderWidgetOptions;

  @override
  Widget build(BuildContext context) {
    return Padding (
      padding: EdgeInsets.all(_shaderWidgetOptions.outSidePadding),
      child: ValueListenableBuilder<bool>(
        valueListenable: _shaderOptions.isEnabled,
        builder: (BuildContext context, bool isEnabled, child)
        {
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
                    child: Switch(
                      onChanged: (bool newState) {
                        _shaderOptions.isEnabled.value = newState;
                      },
                      value: isEnabled,
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
                      builder: (BuildContext context, bool onlyCurrentRampEnabled, child)
                      {
                        return Switch(
                          onChanged: isEnabled
                              ? (bool newState) { _shaderOptions.onlyCurrentRampEnabled.value = newState;}
                              : null,
                          value: onlyCurrentRampEnabled,
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
                      builder: (BuildContext context, ShaderDirection direction, child)
                      {
                        return Switch(
                          onChanged: isEnabled
                              ? (bool newState) {_shaderOptions.shaderDirection.value = newState ? ShaderDirection.right : ShaderDirection.left;}
                              : null,
                          value: direction == ShaderDirection.right,
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