import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';
import 'package:kpix/shader_options.dart';

class MainToolbarWidgetOptions {
  final int paletteFlex;
  final int toolSettingsFlex;
  final double dividerHeight;
  final double dividerPadding;

  const MainToolbarWidgetOptions({
    required this.paletteFlex,
    required this.dividerPadding,
    required this.toolSettingsFlex,
    required this.dividerHeight});
}


class MainToolbarWidget extends StatelessWidget
{
  const MainToolbarWidget({
    super.key
});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const PaletteWidget(),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerPadding,
              indent: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerPadding,
              thickness: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
              height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
            ),
            ShaderWidget(
            titleStyle: Theme.of(context).textTheme.titleLarge,
            labelStyle: Theme.of(context).textTheme.bodySmall,
            ),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerPadding,
              indent: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerPadding,
              thickness: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
              height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
            ),
            ValueListenableBuilder<ToolType>(
              valueListenable: GetIt.I.get<AppState>().selectedTool,
              builder: (BuildContext context, ToolType value,
                  child) {
                return ToolsWidget(
                  changeToolFn: GetIt.I.get<AppState>().changeTool,
                );
                //return ColorEntryWidget();
              }
            ),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerPadding,
              indent: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerPadding,
              thickness: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
              height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
            ),
            SizedBox(
              width: double.infinity,
              //TODO MAGIC NUMBER
              height: 200,
              child: ValueListenableBuilder<ToolType>(
                valueListenable: GetIt.I.get<AppState>().selectedTool,
                builder: (BuildContext context, ToolType value,child) {

                  return const ToolSettingsWidget();
                }
             ),
          ),
        ]
      ),
    );
  }
}