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

import 'dart:collection';

import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';

/// The size of the drawing area, and the operations that change it.
///
/// The dimensions are document state - saved with the project and restored by
/// undo. Resizing has to reach every layer in every frame, so the operations
/// live here rather than on a single layer collection.
class CanvasState
{
  AppState get _appState => GetIt.I.get<AppState>();

  final CoordinateSetI _canvasSize = CoordinateSetI(x: 1, y: 1);
  CoordinateSetI get canvasSize
  {
    return CoordinateSetI.from(other: _canvasSize);
  }
  void setCanvasDimensions({required final int width, required final int height, final bool addToHistoryStack = true})
  {
    _canvasSize.x = width;
    _canvasSize.y = height;
    GetIt.I.get<StatusBarState>().setStatusBarDimensions(width: width, height: height);
    _appState.symmetryState.newCanvasDimensions(newSize: _canvasSize);
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.canvasSizeChange);
    }
  }





  void canvasTransform({required final CanvasTransformation transformation})
  {
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final HistoryManager historyManager = GetIt.I.get<HistoryManager>();

    documentState.selectionState.deselect(addToHistoryStack: false, notify: false);
    for (final Frame f in documentState.timeline.frames.value)
    {
      f.layerList.transformLayers(transformation: transformation, oldSize: canvasSize);
    }
    if (transformation == CanvasTransformation.rotate)
    {
      setCanvasDimensions(width: _canvasSize.y, height: _canvasSize.x);
      historyManager.addState(identifier: HistoryStateTypeIdentifier.canvasRotate);
    }
    else if (transformation == CanvasTransformation.flipH)
    {
      historyManager.addState(identifier: HistoryStateTypeIdentifier.canvasFlipH);
    }
    else if (transformation == CanvasTransformation.flipV)
    {
      historyManager.addState(identifier: HistoryStateTypeIdentifier.canvasFlipV);
    }

  }

  void cropToSelection()
  {
    CoordinateSetI? topLeft;
    CoordinateSetI? bottomRight;
    (topLeft, bottomRight) = GetIt.I.get<DocumentState>().selectionState.selection.getBoundingBox(canvasSize: _canvasSize);
    if (topLeft != null && bottomRight != null)
    {
      final CoordinateSetI newSize = CoordinateSetI(x: bottomRight.x - topLeft.x + 1, y: bottomRight.y - topLeft.y + 1);
      changeCanvasSize(newSize: newSize, offset: CoordinateSetI(x: -topLeft.x, y: -topLeft.y));
    }
    else
    {
      //This should never happen
      showMessage(text: "Could not crop!");
    }
  }

  void changeCanvasSize({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false, notify: false);
    final LinkedHashSet<RasterableLayerState> layerSet = LinkedHashSet<RasterableLayerState>();
    for (final Frame f in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      final LayerCollection layers = f.layerList;
      for (int i = 0; i < layers.length; i++)
      {
        final LayerState l = layers.getLayer(index: i);
        if (l is RasterableLayerState)
        {
          layerSet.add(l);
        }
      }
    }
    for (final RasterableLayerState l in layerSet)
    {
      l.resizeLayer(newSize: newSize, offset: offset);
    }
    setCanvasDimensions(width: newSize.x, height: newSize.y);
    for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      final LayerCollection layers = frame.layerList;
      for (int i = 0; i < layers.length; i++)
      {
        final LayerState layer = layers.getLayer(index: i);
        if (layer is GridLayerState)
        {
          layer.manualRender();
        }
      }
    }
    GetIt.I.get<LayerManager>().rasterLayersAll();
  }
}
