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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/tool_options/color_pick_options.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';


class ToolSettingsWidgetOptions
{
  final int columnWidthRatio;
  final double padding;
  final double smallButtonSize;
  final double smallIconSize;

  const ToolSettingsWidgetOptions({
    required this.columnWidthRatio,
    required this.padding,
    required this.smallButtonSize,
    required this.smallIconSize,});
}


class ToolSettingsWidget extends StatefulWidget
{
  const
  ToolSettingsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ToolSettingsWidgetState();
  
}

class _ToolSettingsWidgetState extends State<ToolSettingsWidget>
{
  final AppState appState = GetIt.I.get<AppState>();
  final ToolOptions toolOptions = GetIt.I.get<PreferenceManager>().toolOptions;
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions = GetIt.I.get<PreferenceManager>().toolSettingsWidgetOptions;
  late KPixOverlay _stampManagerDialog;

  @override
  void initState() {
    super.initState();
    _stampManagerDialog = getStampManagerDialog(onDismiss: _hideStampManagerDialog, onLoad: _newStampLoaded);
  }

  void _hideStampManagerDialog()
  {
    _stampManagerDialog.hide();
  }

  void _newStampLoaded({required final StampManagerEntryData data})
  {
    GetIt.I.get<StampManager>().selectedStamp.value = data;
    _hideStampManagerDialog();
  }

  void _showStampManagerDialog()
  {
    _stampManagerDialog.show(context: context);
  }


  @override
  Widget build(final BuildContext context)
  {
    return ValueListenableBuilder<ToolType>(
      valueListenable: appState.selectedToolNotifier,
      builder: (final BuildContext context, final ToolType type, final Widget? child){
        Widget toolWidget;
        switch(type)
        {
          case ToolType.shape:
            toolWidget = ExcludeFocus(
              child: ShapeOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  shapeOptions: toolOptions.shapeOptions,),
            );
            //break;
          case ToolType.pencil:
            toolWidget = ExcludeFocus(
              child: PencilOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  pencilOptions: toolOptions.pencilOptions,),
            );
            //break;
          case ToolType.fill:
            toolWidget = ExcludeFocus(
              child: FillOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  fillOptions: toolOptions.fillOptions,),
            );
            //break;
          case ToolType.select:
            toolWidget = ExcludeFocus(
              child: SelectOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  selectOptions: toolOptions.selectOptions,),
            );
            //break;
          case ToolType.pick:
            toolWidget = ExcludeFocus(
              child: ColorPickOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  colorPickOptions: toolOptions.colorPickOptions,),
            );
            //break;
          case ToolType.erase:
            toolWidget = ExcludeFocus(
              child: EraserOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  eraserOptions: toolOptions.eraserOptions,),
            );
            //break;
          case ToolType.font:
            toolWidget = TextOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                textOptions: toolOptions.textOptions,);
            //break;
          case ToolType.spraycan:
            toolWidget = ExcludeFocus(
              child: SprayCanOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  sprayCanOptions: toolOptions.sprayCanOptions,),
            );
            //break;
          case ToolType.line:
            toolWidget = ExcludeFocus(
              child: LineOptions.getWidget(
                  context: context,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  lineOptions: toolOptions.lineOptions,),
            );
            //break;
          case ToolType.stamp:
            toolWidget = ExcludeFocus(
              child: StampOptions.getWidget(
                  context: context,
                  showStampManager: _showStampManagerDialog,
                  toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                  stampOptions: toolOptions.stampOptions,),
            );
            //break;

          //default: toolWidget = const SizedBox(width: double.infinity, child: Text("Not Implemented"));
        }
        return Material
        (
          color: Theme.of(context).primaryColor,
          child: Padding(
            padding: EdgeInsets.all(toolSettingsWidgetOptions.padding),
            child: SingleChildScrollView(
              child: toolWidget,
            ),
          ),
        );
      },
    );
  }
}
