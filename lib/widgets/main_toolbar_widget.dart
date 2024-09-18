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
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
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
          (Helper.isDesktop()) ?
          Divider(
            color: Theme.of(context).primaryColorDark,
            thickness: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
            height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
          ) : const SizedBox.shrink(),
          ShaderWidget(
            titleStyle: Theme.of(context).textTheme.titleLarge,
            labelStyle: Theme.of(context).textTheme.bodySmall,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: GetIt.I.get<AppState>().hasProjectNotifier,
            builder: (final BuildContext context, final bool hasProject, final Widget? child)
            {
              return hasProject? const PaletteWidget() : Expanded(child: Container(color: Theme.of(context).primaryColorDark));
            },
          ),
          const ToolsWidget(),
          SizedBox(
            width: double.infinity,
            //TODO MAGIC NUMBER
            height: 200,
            child: ValueListenableBuilder<ToolType>(
              valueListenable: GetIt.I.get<AppState>().selectedToolNotifier,
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