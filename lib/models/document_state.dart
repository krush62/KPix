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
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// The project itself: everything that is written to a `.kpix` file and
/// everything undo restores.
///
/// The four parts are exactly what a [HistoryState] snapshots. Session state -
/// the zoom level, the active tool, the window's install directories - is
/// deliberately not reachable from here.
///
/// [canvas] and [palette] stay separate singletons because most of their users
/// want only one of them; this class is where the document is assembled as a
/// whole, for the history stack and the exporters.
class DocumentState
{
  final Timeline timeline = Timeline.empty();

  /// Lazy on purpose: [SelectionState]'s own field initializers resolve this
  /// class out of the service locator, so building it eagerly here would reach
  /// back into a half-constructed singleton.
  late final SelectionState selectionState = SelectionState(repaintNotifier: GetIt.I.get<ViewState>().repaintNotifier);

  CanvasState get canvas => GetIt.I.get<CanvasState>();

  PaletteState get palette => GetIt.I.get<PaletteState>();

  ColorReference? getColorFromImageAtPosition({required final CoordinateSetI normPos})
  {
    if (timeline.selectedFrame != null)
    {
      return timeline.selectedFrame!.layerList.getColorFromImageAtPosition(normPos: normPos, selectionReference: selectionState.selection.getColorReference(coord: normPos), rawMode: GetIt.I.get<ToolOptions>().colorPickOptions.rawMode.value);
    }
    else
    {
      return null;
    }
  }
}
