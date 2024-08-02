import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
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
    required this.smallIconSize});
}


class ToolSettingsWidget extends StatefulWidget
{
  const ToolSettingsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ToolSettingsWidgetState();
  
}

class _ToolSettingsWidgetState extends State<ToolSettingsWidget>
{
  final AppState appState = GetIt.I.get<AppState>();
  final ToolOptions toolOptions = GetIt.I.get<PreferenceManager>().toolOptions;
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions = GetIt.I.get<PreferenceManager>().toolSettingsWidgetOptions;




  @override
  Widget build(BuildContext context)
  {
    return ValueListenableBuilder<ToolType>(
      valueListenable: appState.getSelectedToolNotifier(),
      builder: (BuildContext context, ToolType type, child){
        Widget toolWidget;

        switch(type)
        {
          case ToolType.shape:
            toolWidget = ShapeOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                shapeOptions: toolOptions.shapeOptions,);
            break;
          case ToolType.pencil:
            toolWidget = PencilOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                pencilOptions: toolOptions.pencilOptions,);
            break;
          case ToolType.fill:
            toolWidget = FillOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                fillOptions: toolOptions.fillOptions,);
            break;
          case ToolType.select:
            toolWidget = SelectOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                selectOptions: toolOptions.selectOptions,);
            break;
          case ToolType.pick:
            toolWidget = ColorPickOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                colorPickOptions: toolOptions.colorPickOptions);
            break;
          case ToolType.erase:
            toolWidget = EraserOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                eraserOptions: toolOptions.eraserOptions);
            break;
          case ToolType.font:
            toolWidget = TextOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                textOptions: toolOptions.textOptions,);
            break;
          case ToolType.spraycan:
            toolWidget = SprayCanOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                sprayCanOptions: toolOptions.sprayCanOptions,);
            break;
          case ToolType.line:
            toolWidget = LineOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                lineOptions: toolOptions.lineOptions,);
            break;
          case ToolType.stamp:
            toolWidget = StampOptions.getWidget(
                context: context,
                toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                stampOptions: toolOptions.stampOptions);
            break;

          default: toolWidget = const SizedBox(width: double.infinity, child: Text("Not Implemented"));
        }


        return Material
        (
          color: Theme.of(context).primaryColor,
          child: Padding(
            padding: EdgeInsets.all(toolSettingsWidgetOptions.padding),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: toolWidget,
            ),
          )
        );
      }
    );






  }
  
}