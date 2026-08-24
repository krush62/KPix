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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';


abstract final class _ToolsWidgetOptions
{
  static const double padding = 8.0;
  //static const double buttonSize = 48.0;
  //static const int colCount = 6;
  static const double iconSize = 22.0;
}

class SegmentButtonData
{
  final ToolType toolType;
  final String toolTipExtraText;
  final bool isDisabledDuringShading;
  SegmentButtonData({required this.toolType, this.isDisabledDuringShading = false, this.toolTipExtraText = ""});
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
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  late List<SegmentButtonData> toolDataRow1;
  late List<SegmentButtonData> toolDataRow2;

  @override
  void initState()
  {
    super.initState();
    _appState.timeline.layerChangeNotifier.addListener(currentLayerTypeChanged);
    toolDataRow1 =  <SegmentButtonData>[
      SegmentButtonData(toolType: ToolType.pencil, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolPencil)),
      SegmentButtonData(toolType: ToolType.erase, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolEraser)),
      SegmentButtonData(toolType: ToolType.select, isDisabledDuringShading: true, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSelectRectangle) + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSelectCircle) + _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSelectWand)),
      SegmentButtonData(toolType: ToolType.fill, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolFill)),
      SegmentButtonData(toolType: ToolType.pick, isDisabledDuringShading: true),
      ];

    toolDataRow2 = <SegmentButtonData>[
      SegmentButtonData(toolType: ToolType.line, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolLine)),
      SegmentButtonData(toolType: ToolType.shape, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolShape)),
      SegmentButtonData(toolType: ToolType.font, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolText)),
      SegmentButtonData(toolType: ToolType.spraycan, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolSprayCan)),
      SegmentButtonData(toolType: ToolType.stamp, toolTipExtraText: _hotkeyManager.getShortcutString(action: HotkeyAction.selectToolStamp)),
    ];
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

  SegmentedButton<ToolType> _createSegmentedRow({required final List<SegmentButtonData> buttonDataList, required final bool isShadingLayer, required final ToolType currentTool})
  {
    final List<ButtonSegment<ToolType>> segments = <ButtonSegment<ToolType>>[];
    for (final SegmentButtonData buttonData in buttonDataList)
    {
      final bool shouldBeDisabled = buttonData.isDisabledDuringShading && isShadingLayer;
      final ButtonSegment<ToolType> segment = ButtonSegment<ToolType>(
        value: buttonData.toolType,
        enabled: !shouldBeDisabled,
        label: Tooltip(
          message: buttonData.toolType.title + buttonData.toolTipExtraText,
          waitDuration: AppState.toolTipDuration,
          child: Icon(
            buttonData.toolType.icon,
            color: shouldBeDisabled ? Theme.of(context).primaryColorDark : null,
            size: _ToolsWidgetOptions.iconSize,
          ),
        ),
      );
      segments.add(segment);
    }

    return SegmentedButton<ToolType>(
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        selected: <ToolType>{currentTool},
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        onSelectionChanged: (final Set<ToolType> tools) {if (tools.isNotEmpty && currentTool != tools.first) _appState.setToolSelection(tool: tools.first);},
        segments: segments,
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.all(_ToolsWidgetOptions.padding),
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

                  _createSegmentedRow(
                      buttonDataList: toolDataRow1,
                      isShadingLayer: isShadingLayer,
                      currentTool: tool,
                  ),
                  _createSegmentedRow(
                    buttonDataList: toolDataRow2,
                    isShadingLayer: isShadingLayer,
                    currentTool: tool,
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
