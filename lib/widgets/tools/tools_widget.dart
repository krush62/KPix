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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';


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
    super.key,
  });

  @override
  State<ToolsWidget> createState() => _ToolsWidgetState();
}

class _ToolsWidgetState extends State<ToolsWidget>
{
  final AppState _appState = GetIt.I.get<AppState>();
  final ToolsWidgetOptions _toolsWidgetOptions = GetIt.I.get<PreferenceManager>().toolsWidgetOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  @override
  void initState()
  {
    super.initState();
    _appState.timeline.layerChangeNotifier.addListener(currentLayerTypeChanged);    
  }

  @override
  void dispose()
  {
    _appState.timeline.layerChangeNotifier.removeListener(currentLayerTypeChanged);
    super.dispose();
  }

  void currentLayerTypeChanged()
  {
    if (_appState.timeline.getCurrentLayer() is ShadingLayerState &&
        (_appState.selectedTool == ToolType.select || _appState.selectedTool == ToolType.pick))
    {
      _appState.setToolSelection(tool: ToolType.pencil);
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.all(_toolsWidgetOptions.padding),
      child: ListenableBuilder(
        listenable: _appState.timeline.layerChangeNotifier,
        builder: (final BuildContext context, final Widget? child)
        {
          final LayerState? currentLayer = _appState.timeline.getCurrentLayer();
          final bool isShadingLayer = currentLayer is ShadingLayerState;
          return ValueListenableBuilder<ToolType>(
            valueListenable: _appState.selectedToolNotifier,
            builder: (final BuildContext context, final ToolType tool, final Widget? child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<ToolType>(
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    selected: <ToolType>{tool},
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    onSelectionChanged: (final Set<ToolType> tools) {if (tools.isNotEmpty && tool != tools.first) _appState.setToolSelection(tool: tools.first);},
                    segments: <ButtonSegment<ToolType>>[
                      ButtonSegment<ToolType>(
                        value: ToolType.pencil,
                        label: Tooltip(
                          message: toolList[ToolType.pencil]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolPencil),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.pencil]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        value: ToolType.erase,
                        label: Tooltip(
                          message: toolList[ToolType.erase]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolEraser),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.erase]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        enabled: !isShadingLayer,
                        value: ToolType.select,
                        label: Tooltip(
                          message: toolList[ToolType.select]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSelectRectangle) + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSelectCircle) + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSelectWand),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.select]!.icon,
                            color: isShadingLayer ? Theme.of(context).primaryColorDark : null,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        value: ToolType.fill,
                        label: Tooltip(
                          message: toolList[ToolType.fill]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolFill),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.fill]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        enabled: !isShadingLayer,
                        value: ToolType.pick,
                        label: Tooltip(
                          message: toolList[ToolType.pick]?.title,
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.pick]!.icon,
                            color: isShadingLayer ? Theme.of(context).primaryColorDark : null,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SegmentedButton<ToolType>(
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    selected: <ToolType>{tool},
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    onSelectionChanged: (final Set<ToolType> tools) {if (tools.isNotEmpty && tool != tools.first) _appState.setToolSelection(tool: tools.first);},
                    segments: <ButtonSegment<ToolType>>[
                      ButtonSegment<ToolType>(
                        value: ToolType.line,
                        label: Tooltip(
                          message: toolList[ToolType.line]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolLine),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.line]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        value: ToolType.shape,
                        label: Tooltip(
                          message: toolList[ToolType.shape]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolShape),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.shape]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        value: ToolType.font,
                        label: Tooltip(
                          message: toolList[ToolType.font]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolText),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.font]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        value: ToolType.spraycan,
                        label: Tooltip(
                          message: toolList[ToolType.spraycan]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSprayCan),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.spraycan]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                      ButtonSegment<ToolType>(
                        value: ToolType.stamp,
                        label: Tooltip(
                          message: toolList[ToolType.stamp]!.title + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolStamp),
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            toolList[ToolType.stamp]!.icon,
                            size: _toolsWidgetOptions.iconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
