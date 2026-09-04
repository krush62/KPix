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

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/history/ramp_resolver.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:logger/logger.dart';

/// Undo, redo, and putting a [HistoryState] back onto the live document.
///
/// The restore is the one place that writes across every part of the document
/// at once - canvas size, palette, layers, frames and selection - which is why
/// it does not belong to any single one of them.
class HistoryController
{
  //set by the canvas widget; commits pending tool changes to the history stack
  //before undo/redo so freshly drawn content cannot be lost to the poll timer
  VoidCallback? flushHistoryData;

  void undoPressed()
  {
    flushHistoryData?.call();
    if (GetIt.I.get<HistoryManager>().hasUndo.value && !GetIt.I.get<DocumentState>().timeline.isPlaying.value)
    {
      showMessage(text: "Undo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
      //the state being undone describes what changed (and on which layer);
      //the target state provides the data to restore
      final HistoryState? currentState = GetIt.I.get<HistoryManager>().getCurrentState();
      final HistoryStateTypeGroup typeGroup = currentState != null ? currentState.type.group : HistoryStateTypeGroup.full;
      restoreState(historyState: GetIt.I.get<HistoryManager>().undo(), typeGroup: typeGroup, restoreLayerIndices: currentState?.restoreLayerIndices);
      GetIt.I.get<ProjectSession>().hasChanges.value = !GetIt.I.get<HistoryManager>().isAtSavedState;
    }
  }

  void redoPressed()
  {
    flushHistoryData?.call();
    if (GetIt.I.get<HistoryManager>().hasRedo.value && !GetIt.I.get<DocumentState>().timeline.isPlaying.value)
    {
      final HistoryState? switchState = GetIt.I.get<HistoryManager>().redo();
      final HistoryStateTypeGroup typeGroup = switchState != null ? switchState.type.group : HistoryStateTypeGroup.full;
      restoreState(historyState: switchState, typeGroup: typeGroup, restoreLayerIndices: switchState?.restoreLayerIndices);
      GetIt.I.get<ProjectSession>().hasChanges.value = !GetIt.I.get<HistoryManager>().isAtSavedState;
      showMessage(text: "Redo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
    }
  }

  Future<void> restoreState({required final HistoryState? historyState, required final HistoryStateTypeGroup typeGroup, final Set<int>? restoreLayerIndices}) async
  {
    final Set<int> restoreIndices = restoreLayerIndices ?? const <int>{};
    const String failMessage = "History restore failed!";

    if (historyState != null)
    {
      try
      {
        //COLLECT ORIGINAL LAYERS
        final LinkedHashSet<LayerState> collectedLayers = LinkedHashSet<LayerState>();
        for (final Frame f in GetIt.I.get<DocumentState>().timeline.frames.value)
        {
          final LayerCollection layers = f.layerList;
          for (int i = 0; i < layers.length; i++)
          {
            collectedLayers.add(layers.getLayer(index: i));
          }
        }

        //CANVAS
        final CoordinateSetI canvSize = CoordinateSetI.from(other: historyState.canvasSize);

        //COLORS
        {
          final List<KPalRampData> ramps = <KPalRampData>[];
          for (final HistoryRampData hRampData in historyState.rampList)
          {
            final KPalRampSettings settings = KPalRampSettings.from(other: hRampData.settings);
            ramps.add(KPalRampData(uuid: hRampData.uuid, settings: settings, historyShifts: hRampData.shiftSets));
          }
          if (typeGroup == HistoryStateTypeGroup.full)
          {
            GetIt.I.get<PaletteState>().colorRamps = ramps;
          }
        }

        final RampResolver rampResolver = RampResolver(
          liveRamps: GetIt.I.get<PaletteState>().colorRamps,
          historyRamps: historyState.rampList,
        );
        GetIt.I.get<PaletteState>().selectedColor = rampResolver.byIndex(ref: historyState.selectedColor);

        if (typeGroup == HistoryStateTypeGroup.full || typeGroup == HistoryStateTypeGroup.layerFull)
        {
          //RESTORE LAYERS
          final LinkedHashSet<HistoryLayer> allHistoryLayers = historyState.timeline.allLayers;
          final List<LayerState> allLayers = <LayerState>[];
          int layerCounter = 0;
          for (final HistoryLayer hLayer in allHistoryLayers)
          {
            if (restoreIndices.isNotEmpty && typeGroup == HistoryStateTypeGroup.layerFull && !restoreIndices.contains(layerCounter) && collectedLayers.length == allHistoryLayers.length)
            {
              final LayerState liveLayer = collectedLayers.elementAt(layerCounter);
              liveLayer.visibilityState.value = hLayer.visibilityState;
              if (hLayer is HistoryDrawingLayer && liveLayer is DrawingLayerState)
              {
                liveLayer.lockState.value = hLayer.lockState;
              }
              else if (hLayer is HistoryShadingLayer && liveLayer is ShadingLayerState) // also matches HistoryDitherLayer
              {
                liveLayer.lockState.value = hLayer.lockState;
              }
              allLayers.add(liveLayer);
            }
            else
            {
              final LayerState layerState = await hLayer.toLayerState(
                canvasSize: canvSize,
                ramps: rampResolver,
              );
              layerState.visibilityState.value = hLayer.visibilityState;
              allLayers.add(layerState);
            }

            layerCounter++;
          }

          final List<Frame> liveFrames = GetIt.I.get<DocumentState>().timeline.frames.value;
          final bool reuseFrames = liveFrames.length == historyState.timeline.frames.length;
          final List<Frame> frames = <Frame>[];
          for (int frameIndex = 0; frameIndex < historyState.timeline.frames.length; frameIndex++)
          {
            final HistoryFrame hFrame = historyState.timeline.frames[frameIndex];
            final List<LayerState> layerList = <LayerState>[];
            for (final int hLayerIndex in hFrame.layerIndices)
            {
              layerList.add(allLayers[hLayerIndex]);
            }
            if (reuseFrames)
            {
              final Frame frame = liveFrames[frameIndex];
              frame.layerList.replaceLayers(layers: layerList, selLayerIdx: hFrame.selectedLayerIndex);
              frame.fps.value = hFrame.fps;
              frames.add(frame);
            }
            else
            {
              final LayerCollection layerCollection = LayerCollection(layers: layerList, selLayerIdx: hFrame.selectedLayerIndex);
              frames.add(Frame(layerList: layerCollection, fps: hFrame.fps));
            }
          }

          GetIt.I.get<DocumentState>().timeline.setData(selectedFrameIndex: historyState.timeline.selectedFrameIndex, frames: frames, loopStartIndex: historyState.timeline.loopStart, loopEndIndex: historyState.timeline.loopEnd);

          //restoring rebuilds most layers, so the replaced ones have to be dropped
          GetIt.I.get<LayerManager>().disposeUnusedLayers(candidates: collectedLayers);


          //SELECTION
          final CoordinateColorMapNullable selectionContent = HashMap<CoordinateSetI, ColorReference?>();
          for (final CoordinateSetI coord in historyState.selectionState.mask)
          {
            final HistoryColorReference? ref = historyState.selectionState.colors[coord];
            selectionContent[CoordinateSetI.from(other: coord)] = ref == null ? null : rampResolver.byIndex(ref: ref);
          }
          GetIt.I.get<DocumentState>().selectionState.selection.delete(keepSelection: false);
          GetIt.I.get<DocumentState>().selectionState.selection.addDirectlyAll(list: selectionContent);
          GetIt.I.get<DocumentState>().selectionState.createSelectionLines();
          GetIt.I.get<DocumentState>().selectionState.notifyRepaint();

          if (canvSize.x != GetIt.I.get<CanvasState>().canvasSize.x || canvSize.y != GetIt.I.get<CanvasState>().canvasSize.y)
          {
            GetIt.I.get<CanvasState>().setCanvasDimensions(width: canvSize.x, height: canvSize.y, addToHistoryStack: false);
          }

          //the timeout is a backstop only: a layer that never settles would
          //otherwise leave the restore hanging with no way out
          await Future.wait<void>(allLayers.map((final LayerState layer) => layer.rasterizationComplete))
              .timeout(rasterSettleTimeout, onTimeout: ()
          {
            GetIt.I.get<Logger>().w("Timed out waiting for layers to finish rasterizing while restoring history.");
            return <void>[];
          },);

          GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
          final List<int> rasterIndices = restoreIndices.where((final int index) => index >= 0 && index < allLayers.length).toList();
          final bool canRasterSelectively = typeGroup == HistoryStateTypeGroup.layerFull &&
              rasterIndices.isNotEmpty &&
              rasterIndices.length == restoreIndices.length &&
              rasterIndices.every((final int index) => allLayers[index] is RasterableLayerState);
          if (canRasterSelectively)
          {
            for (final int index in rasterIndices)
            {
              (allLayers[index] as RasterableLayerState).doManualRaster = true;
            }
          }
          else
          {
            GetIt.I.get<LayerManager>().rasterLayersAll();
          }
        }
        else if (typeGroup == HistoryStateTypeGroup.layerSelect)
        {
          GetIt.I.get<DocumentState>().timeline.selectFrameByIndex(index: historyState.timeline.selectedFrameIndex, layerIndex: historyState.timeline.frames[historyState.timeline.selectedFrameIndex].selectedLayerIndex, addLayerSelectionToHistory: false);
        }

      }
      catch (e, s)
      {
        showMessage(text: failMessage);
        GetIt.I.get<Logger>().w(failMessage, error: e, stackTrace: s);
      }
    }
    else
    {
      showMessage(text: failMessage);
      GetIt.I.get<Logger>().w(failMessage);
    }
  }
}
