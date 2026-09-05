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

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// The mirror guides, and where they sit on the canvas.
///
/// Session state: reset when a project is opened, never written to the file and
/// never restored by undo.
class SymmetryState
{
  final ValueNotifier<bool> horizontalActivated = ValueNotifier<bool>(false);
  final ValueNotifier<double> horizontalValue = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> verticalActivated = ValueNotifier<bool>(false);
  final ValueNotifier<double> verticalValue = ValueNotifier<double>(1.0);

  void reset()
  {
    horizontalActivated.value = false;
    horizontalValue.value = GetIt.I.get<CanvasState>().canvasSize.x.toDouble() / 2.0;
    verticalActivated.value = false;
    verticalValue.value = GetIt.I.get<CanvasState>().canvasSize.y.toDouble() / 2.0;
  }

  void newCanvasDimensions({required final CoordinateSetI newSize})
  {
    horizontalValue.value = horizontalValue.value.clamp(1.0, newSize.x - 1).toDouble();
    verticalValue.value = verticalValue.value.clamp(1.0, newSize.y - 1).toDouble();
  }
}
