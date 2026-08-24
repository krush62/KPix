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
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/palette/palette_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:kpix/widgets/tools/shader_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';
import 'package:kpix/widgets/tools/tools_widget.dart';

abstract final class _MainToolbarWidgetOptions {
  //static const int paletteFlex = 2;
  //static const int toolSettingsFlex = 1;
  //static const double dividerHeight = 2.0;
  //static const double dividerPadding = 8.0;
  static const int toolHeight = 300;
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
          ExcludeFocus(
            child: ShaderWidget(
              titleStyle: Theme.of(context).textTheme.titleLarge,
              labelStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ExcludeFocus(
            child: ValueListenableBuilder<bool>(
              valueListenable: GetIt.I.get<AppState>().hasProjectNotifier,
              builder: (final BuildContext context, final bool hasProject, final Widget? child)
              {
                return hasProject? const PaletteWidget() : Expanded(child: Container(color: Theme.of(context).primaryColorDark));
              },
            ),
          ),
          ListenableBuilder(
            listenable: GetIt.I.get<AppState>().timeline.layerChangeNotifier,
            builder: (final BuildContext context, final Widget? child) {
              final LayerState? currentLayer = GetIt.I.get<AppState>().timeline.getCurrentLayer();
              if (currentLayer != null)
              {
                Widget contentWidget;
                if (currentLayer.runtimeType == ReferenceLayerState)
                {
                  contentWidget = ExcludeFocus(child: ReferenceLayerOptionsWidget(referenceState: currentLayer as ReferenceLayerState));
                }
                else if (currentLayer.runtimeType == GridLayerState)
                {
                  contentWidget = ExcludeFocus(child: GridLayerOptionsWidget(gridState: currentLayer as GridLayerState));
                }
                else if (currentLayer is RasterableLayerState)
                {
                  contentWidget = const Column(
                    children: <Widget>[
                      ExcludeFocus(child: ToolsWidget()),
                      Expanded(child: ToolSettingsWidget()),
                    ],
                  );
                }
                else
                {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  width: double.infinity,
                  height: _MainToolbarWidgetOptions.toolHeight.toDouble(),
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
