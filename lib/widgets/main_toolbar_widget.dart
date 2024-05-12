import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/tool_options.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';
import 'package:kpix/shader_options.dart';

class MainToolbarWidgetOptions {
  final int paletteFlex;
  final int toolSettingsFlex;
  final double dividerHeight;

  const MainToolbarWidgetOptions({
    required this.paletteFlex,
    required this.toolSettingsFlex,
    required this.dividerHeight});
}


class MainToolbarWidget extends StatelessWidget
{
  final AppState appState;
  final PaletteWidgetOptions paletteWidgetOptions;
  final ToolsWidgetOptions toolsWidgetOptions;
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions;
  final ToolOptions toolOptions;
  final MainToolbarWidgetOptions mainToolbarWidgetOptions;
  final ShaderWidgetOptions shaderWidgetOptions;
  final ShaderOptions shaderOptions;

  const MainToolbarWidget({
    required this.appState,
    required this.paletteWidgetOptions,
    required this.toolsWidgetOptions,
    required this.toolSettingsWidgetOptions,
    required this.toolOptions,
    required this.mainToolbarWidgetOptions,
    required this.shaderWidgetOptions,
    required this.shaderOptions,
    super.key
});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          //PALETTE WIDGET
          Expanded(
            flex: mainToolbarWidgetOptions.paletteFlex,
            child: ValueListenableBuilder<ToolType>(
                valueListenable: appState.selectedTool,
                builder: (BuildContext context, ToolType value,
                    child) {
                  return PaletteWidget(
                    options: paletteWidgetOptions,
                    appState: appState,
                  );
                }),
          ),
          Divider(
            color: Theme.of(context).primaryColorDark,
            thickness: mainToolbarWidgetOptions.dividerHeight,
            height: mainToolbarWidgetOptions.dividerHeight,
          ),

          Material(
            color: Theme.of(context).primaryColor,
              child: ShaderWidget(
                titleStyle: Theme.of(context).textTheme.titleLarge,
                labelStyle: Theme.of(context).textTheme.bodySmall,
                shaderWidgetOptions: shaderWidgetOptions,
                shaderOptions: shaderOptions),
            ),
          Divider(
            color: Theme.of(context).primaryColorDark,
            thickness: mainToolbarWidgetOptions.dividerHeight,
            height: mainToolbarWidgetOptions.dividerHeight,
          ),
          //TOOLS WIDGET
          ValueListenableBuilder<ToolType>(
              valueListenable: appState.selectedTool,
              builder: (BuildContext context, ToolType value,
                  child) {
                return ToolsWidget(
                  options: toolsWidgetOptions,
                  changeToolFn: appState.changeTool,
                  appState: appState,
                );
                //return ColorEntryWidget();
              }),
          Divider(
            color: Theme.of(context).primaryColorDark,
            thickness: mainToolbarWidgetOptions.dividerHeight,
            height: mainToolbarWidgetOptions.dividerHeight,
          ),

          //TOOL OPTIONS
          Expanded(
              flex: mainToolbarWidgetOptions.toolSettingsFlex,
              child: ValueListenableBuilder<ToolType>(
                  valueListenable: appState.selectedTool,
                  builder: (BuildContext context, ToolType value,
                      child) {
                    return ToolSettingsWidget(appState: appState, toolSettingsWidgetOptions: toolSettingsWidgetOptions, toolOptions: toolOptions,);
                  }
              )
          )
        ]
    );
  }

}