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
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/timeline/frame_blending_options.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

/// Boots the parts of the service locator that the selection, timeline, history
/// and export code reach into, and hands back a project with one frame holding a
/// single drawing layer.
///
/// The real bootstrap in main.dart also builds stamps, package info and the
/// project manager; none of that is reachable from the code under test.
Future<AppState> bootProject({required final CoordinateSetI canvasSize}) async
{
  SharedPreferences.setMockInitialValues(<String, Object>{});

  await GetIt.I.reset();
  GetIt.I.registerSingleton<Logger>(Logger(level: Level.off));
  GetIt.I.registerSingleton<HotkeyManager>(HotkeyManager());
  GetIt.I.registerSingleton<ToolOptions>(ToolOptions(fontManager: FontManager(kFontMap: <PixelFontType, KFont>{})));
  GetIt.I.registerSingleton<PreferenceManager>(PreferenceManager(await SharedPreferences.getInstance()));
  GetIt.I.registerSingleton<FrameBlendingOptions>(FrameBlendingOptions());
  GetIt.I.registerSingleton<ShaderOptions>(ShaderOptions());

  GetIt.I.registerSingleton<AppPaths>(AppPaths(exportDir: ".", internalDir: ".", projectsDir: "."));
  GetIt.I.registerSingleton<UpdateState>(UpdateState());
  GetIt.I.registerSingleton<StatusBarState>(StatusBarState());
  GetIt.I.registerSingleton<ViewState>(ViewState(devicePixelRatio: 1.0));
  GetIt.I.registerSingleton<PaletteState>(PaletteState());
  final AppState appState = AppState();
  GetIt.I.registerSingleton<AppState>(appState);
  GetIt.I.registerSingleton<ToolState>(ToolState());
  GetIt.I.registerSingleton<HistoryManager>(HistoryManager(maxEntries: 64));

  appState.init(dimensions: canvasSize);
  await settle(appState: appState);
  return appState;
}

/// Runs [body] with a booted project and a live widget tree.
///
/// Undo, redo and the export failure paths announce themselves through a toast,
/// and toastification asserts if no overlay is mounted.
/// [WidgetTester.runAsync] is what lets the real raster timers and
/// `Picture.toImage` run, which fake async would stall.
Future<void> withProject({
  required final WidgetTester tester,
  required final CoordinateSetI canvasSize,
  required final Future<void> Function(AppState appState) body,
}) async
{
  await tester.pumpWidget(const ToastificationWrapper(child: MaterialApp(home: SizedBox.shrink())));
  await tester.runAsync(() async {
    final AppState appState = await bootProject(canvasSize: canvasSize);
    await body(appState);
  });
}

/// Waits until no layer has rasterisation outstanding.
///
/// Pixel writes land in a raster queue and only reach the layer's data map when
/// the shared poll timer next runs a raster, so a read taken before that still
/// sees the state from before the write.
Future<void> settle({required final AppState appState, final int maxTicks = 60}) async
{
  for (int tick = 0; tick < maxTicks; tick++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    bool pending = false;
    for (final Frame frame in appState.timeline.frames.value)
    {
      for (int i = 0; i < frame.layerList.length; i++)
      {
        final LayerState layer = frame.layerList.getLayer(index: i);
        if (layer is DrawingLayerState && (layer.rasterQueue.isNotEmpty || layer.doManualRaster || layer.isRasterizing))
        {
          pending = true;
        }
      }
    }
    if (!pending)
    {
      return;
    }
  }
}

/// The drawing layer at [index] of the currently selected frame.
DrawingLayerState layerAt({required final AppState appState, required final int index})
{
  return appState.timeline.selectedFrame!.layerList.getLayer(index: index) as DrawingLayerState;
}

/// How many of the project's pixel stores hold a colour at [coord].
///
/// A floating selection physically owns the pixels it covers, so a coordinate
/// lives in exactly one place: one layer, or the selection. Any other count
/// means a hand-over between layers dropped a pixel or left a copy behind.
int copiesOf({required final AppState appState, required final CoordinateSetI coord})
{
  int count = 0;
  for (final Frame frame in appState.timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      final LayerState layer = frame.layerList.getLayer(index: i);
      if (layer is DrawingLayerState && layer.getDataEntry(coord: coord) != null)
      {
        count++;
      }
    }
  }
  if (appState.selectionState.selection.getColorReference(coord: coord) != null)
  {
    count++;
  }
  return count;
}
