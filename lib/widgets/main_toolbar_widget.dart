import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';

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
            (!kIsWeb &&
                (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ?
            Divider(
              color: Theme.of(context).primaryColorDark,
              thickness: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
              height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
            ) : const SizedBox.shrink(),
            ShaderWidget(
              titleStyle: Theme.of(context).textTheme.titleLarge,
              labelStyle: Theme.of(context).textTheme.bodySmall,
            ),
            const PaletteWidget(),
            const ToolsWidget(),

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