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
  AppState appState = GetIt.I.get<AppState>();
  ToolsWidgetOptions toolsWidgetOptions = GetIt.I.get<PreferenceManager>().toolsWidgetOptions;

  @override
  void initState()
  {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.all(toolsWidgetOptions.padding),
      child: ValueListenableBuilder<ToolType>(
        valueListenable: appState.selectedToolNotifier,
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
                onSelectionChanged: (final Set<ToolType> tools) {appState.setToolSelection(tool: tools.first);},
                segments: [
                  ButtonSegment(
                    value: ToolType.pencil,
                    tooltip: toolList[ToolType.pencil]?.title,
                    label: FaIcon(
                      toolList[ToolType.pencil]!.icon,
                      size: toolsWidgetOptions.iconSize,
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.erase,
                    tooltip: toolList[ToolType.erase]?.title,
                    label: FaIcon(
                      toolList[ToolType.erase]!.icon,
                      size: toolsWidgetOptions.iconSize,
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.select,
                    tooltip: toolList[ToolType.select]?.title,
                    label: FaIcon(
                      toolList[ToolType.select]!.icon,
                      size: toolsWidgetOptions.iconSize,
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.fill,
                    tooltip: toolList[ToolType.fill]?.title,
                    label: FaIcon(
                      toolList[ToolType.fill]!.icon,
                      size: toolsWidgetOptions.iconSize,
                    )
                  ),
                  ButtonSegment(
                    value: ToolType.pick,
                    tooltip: toolList[ToolType.pick]?.title,
                    label: FaIcon(
                      toolList[ToolType.pick]!.icon,
                      size: toolsWidgetOptions.iconSize,
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
                onSelectionChanged: (final Set<ToolType> tools) {appState.setToolSelection(tool: tools.first);},
                segments: [
                  ButtonSegment(
                      value: ToolType.line,
                      tooltip: toolList[ToolType.line]?.title,
                      label: FaIcon(
                        toolList[ToolType.line]!.icon,
                        size: toolsWidgetOptions.iconSize,
                      )
                  ),
                  ButtonSegment(
                      value: ToolType.shape,
                      tooltip: toolList[ToolType.shape]?.title,
                      label: FaIcon(
                        toolList[ToolType.shape]!.icon,
                        size: toolsWidgetOptions.iconSize,
                      )
                  ),
                  ButtonSegment(
                      value: ToolType.font,
                      tooltip: toolList[ToolType.font]?.title,
                      label: FaIcon(
                        toolList[ToolType.font]!.icon,
                        size: toolsWidgetOptions.iconSize,
                      )
                  ),
                  ButtonSegment(
                      value: ToolType.spraycan,
                      tooltip: toolList[ToolType.spraycan]?.title,
                      label: FaIcon(
                        toolList[ToolType.spraycan]!.icon,
                        size: toolsWidgetOptions.iconSize,
                      )
                  ),
                  ButtonSegment(
                      value: ToolType.stamp,
                      tooltip: toolList[ToolType.stamp]?.title,
                      label: FaIcon(
                        toolList[ToolType.stamp]!.icon,
                        size: toolsWidgetOptions.iconSize,
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