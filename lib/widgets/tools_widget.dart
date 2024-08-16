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
import 'package:kpix/util/helper.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';


class ToolsWidgetOptions
{
  final double padding;
  final double buttonSize;
  final int colCount;
  final double iconSize;
  ToolsWidgetOptions({required this.padding, required this.buttonSize, required this.colCount, required this.iconSize});
}

class ToolsWidget extends StatefulWidget
{
  const ToolsWidget({
    super.key
  });

  @override
  State<ToolsWidget> createState() => _ToolsWidgetState();
}

class _ToolsWidgetState extends State<ToolsWidget>
{
  final AppState _appState = GetIt.I.get<AppState>();
  final ToolsWidgetOptions _toolsWidgetOptions = GetIt.I.get<PreferenceManager>().toolsWidgetOptions;

  @override
  void initState()
  {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.all(_toolsWidgetOptions.padding),
      child: ValueListenableBuilder<ToolType>(
        valueListenable: _appState.selectedToolNotifier,
        builder: (BuildContext context, ToolType tool, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ToolType>(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                selected: <ToolType>{tool},
                emptySelectionAllowed: true,
                multiSelectionEnabled: false,
                showSelectedIcon: false,
                onSelectionChanged: (final Set<ToolType> tools) {_appState.setToolSelection(tool: tools.first);},
                segments: [
                  ButtonSegment(
                    value: ToolType.pencil,
                    label: Tooltip(
                      message: toolList[ToolType.pencil]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.pencil]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.erase,
                    label: Tooltip(
                      message: toolList[ToolType.erase]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.erase]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.select,
                    label: Tooltip(
                      message: toolList[ToolType.select]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.select]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.fill,
                    label: Tooltip(
                      message: toolList[ToolType.fill]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.fill]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.pick,
                    label: Tooltip(
                      message: toolList[ToolType.pick]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.pick]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                ],
              ),
              SegmentedButton<ToolType>(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                selected: <ToolType>{tool},
                emptySelectionAllowed: true,
                multiSelectionEnabled: false,
                showSelectedIcon: false,
                onSelectionChanged: (final Set<ToolType> tools) {_appState.setToolSelection(tool: tools.first);},
                segments: [
                  ButtonSegment(
                    value: ToolType.line,
                    label: Tooltip(
                      message: toolList[ToolType.line]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.line]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.shape,
                    label: Tooltip(
                      message: toolList[ToolType.shape]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.shape]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.font,
                    label: Tooltip(
                      message: toolList[ToolType.font]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.font]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.spraycan,
                    label: Tooltip(
                      message: toolList[ToolType.spraycan]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.spraycan]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.stamp,
                    label: Tooltip(
                      message: toolList[ToolType.stamp]?.title,
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                        toolList[ToolType.stamp]!.icon,
                        size: _toolsWidgetOptions.iconSize,
                      ),
                    )
                  ),
                ],
              ),
            ],
          );
        }
      ),
    );
  }
}