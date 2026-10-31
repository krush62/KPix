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

import 'package:get_it/get_it.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/frame_blending_options.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The services the tools and their preferences need. The app and the test
/// harness both start with this, so a new service reaches both.
void registerToolServices({required final FontManager fontManager, required final SharedPreferences sharedPreferences})
{
  GetIt.I.registerSingleton<ToolOptions>(ToolOptions(fontManager: fontManager));
  GetIt.I.registerSingleton<PreferenceManager>(PreferenceManager(sharedPreferences));
  GetIt.I.registerSingleton<FrameBlendingOptions>(FrameBlendingOptions());
  GetIt.I.registerSingleton<ShaderOptions>(ShaderOptions());
}

/// The services behind a document, in the order they depend on each other.
void registerDocumentServices({required final AppPaths appPaths, required final double devicePixelRatio})
{
  GetIt.I.registerSingleton<AppPaths>(appPaths);
  GetIt.I.registerSingleton<UpdateState>(UpdateState());
  GetIt.I.registerSingleton<StatusBarState>(StatusBarState());
  GetIt.I.registerSingleton<SymmetryState>(SymmetryState());
  GetIt.I.registerSingleton<ViewState>(ViewState(devicePixelRatio: devicePixelRatio));
  GetIt.I.registerSingleton<PaletteState>(PaletteState());
  GetIt.I.registerSingleton<CanvasState>(CanvasState());
  GetIt.I.registerSingleton<DocumentState>(DocumentState());
  GetIt.I.registerSingleton<ProjectSession>(ProjectSession());
  GetIt.I.registerSingleton<ToolState>(ToolState());
  GetIt.I.registerSingleton<LayerManager>(LayerManager());
  GetIt.I.registerSingleton<HistoryController>(HistoryController());
}
