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
import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/palette/palette_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:kpix/widgets/tools/shader_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';
import 'package:kpix/widgets/tools/tools_widget.dart';

class MainToolbarWidgetOptions {
  final int paletteFlex;
  final int toolSettingsFlex;
  final double dividerHeight;
  final double dividerPadding;
  final int toolHeight;

  const MainToolbarWidgetOptions({
    required this.paletteFlex,
    required this.dividerPadding,
    required this.toolSettingsFlex,
    required this.dividerHeight,
    required this.toolHeight,});
}


class MainToolbarWidget extends StatelessWidget
{

  const MainToolbarWidget({
    super.key,
});

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          if (isDesktop()) Divider(
            color: Theme.of(context).primaryColorDark,
            thickness: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
            height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.dividerHeight,
          ) else const SizedBox.shrink(),
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
          ValueListenableBuilder<LayerState?>
          (
            valueListenable: GetIt.I.get<AppState>().currentLayerNotifier,
            builder: (final BuildContext context, final LayerState? layer, final Widget? child) {

              if (layer != null)
              {
                Widget contentWidget;
                if (layer.runtimeType == ReferenceLayerState)
                {
                  contentWidget = ReferenceLayerOptionsWidget(referenceState: layer as ReferenceLayerState);
                }
                else if (layer.runtimeType == GridLayerState)
                {
                  contentWidget = GridLayerOptionsWidget(gridState: layer as GridLayerState);
                }
                else if (layer is RasterableLayerState)
                {
                  contentWidget = Column(
                    children: <Widget>[
                      const ToolsWidget(),
                      ValueListenableBuilder<ToolType>(
                        valueListenable: GetIt.I.get<AppState>().selectedToolNotifier,
                        builder: (final BuildContext context, final ToolType value, final Widget? child) {
                          return const Expanded(child: ToolSettingsWidget());
                        },
                      ),
                    ],
                  );
                }
                else
                {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  width: double.infinity,
                  height: GetIt.I.get<PreferenceManager>().mainToolbarWidgetOptions.toolHeight.toDouble(),
                  child: contentWidget,

                );
              }
              else
              {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
