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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_reference_layer.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/typedefs.dart';

/// Every operation that adds, removes, reorders or re-rasters a layer.
///
/// Layers live in the timeline, one [LayerCollection] per frame, and a layer can
/// be linked into several frames at once. These operations therefore have to
/// reach across frames, which is why they do not sit on [LayerCollection]
/// itself.
class LayerManager
{
  LayerManager()
  {
    _setHotkeys();
  }

  void _setHotkeys()
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    hotkeyManager.addListener(func: () {changeLayerVisibility(layerState: GetIt.I.get<DocumentState>().timeline.getCurrentLayer());}, action: HotkeyAction.layersSwitchVisibility);
    hotkeyManager.addListener(func: () {changeLayerLockState(layerState: GetIt.I.get<DocumentState>().timeline.getCurrentLayer());}, action: HotkeyAction.layersSwitchLock);
    //adding, duplicating, deleting and merging report a LayerActionResult that
    //needs a localized message, so their hotkeys are handled by the RightBarWidget
    hotkeyManager.addListener(func: () {moveUpLayer(layerState: GetIt.I.get<DocumentState>().timeline.getCurrentLayer());}, action: HotkeyAction.layersMoveUp);
    hotkeyManager.addListener(func: () {moveDownLayer(layerState: GetIt.I.get<DocumentState>().timeline.getCurrentLayer());}, action: HotkeyAction.layersMoveDown);
    hotkeyManager.addListener(func: selectLayerAbove, action: HotkeyAction.layersSelectAbove);
    hotkeyManager.addListener(func: selectLayerBelow, action: HotkeyAction.layersSelectBelow);
  }

  (LayerActionResult, LayerState?) addNewLayer({required final Type layerType, final bool addToHistoryStack = true, final bool select = false, final CoordinateColorMapNullable? content})
  {
    HistoryStateTypeIdentifier? identifier;
    (LayerActionResult, LayerState?) tuple = (LayerActionResult.unknownError, null);
    if (GetIt.I.get<DocumentState>().timeline.selectedFrame != null)
    {

      GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);

      switch (layerType) {
        case const(ReferenceLayerState):
          tuple = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewReferenceLayer(select: select);
          identifier = HistoryStateTypeIdentifier.layerNewReference;
        case const(DitherLayerState):
          tuple = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewDitherLayer(select: select);
          identifier = HistoryStateTypeIdentifier.layerNewDither;
        case const(ShadingLayerState):
          tuple = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewShadingLayer(select: select);
          identifier = HistoryStateTypeIdentifier.layerNewShading;
        case const(GridLayerState):
          tuple = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewGridLayer(select: select);
          identifier = HistoryStateTypeIdentifier.layerNewGrid;
        case const(DrawingLayerState):
          final bool setSelectionStateLayer = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.isEmpty;
          tuple = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewDrawingLayer(canvasSize: GetIt.I.get<CanvasState>().canvasSize, select: select, content: content, ramps: GetIt.I.get<PaletteState>().colorRamps);
          identifier = HistoryStateTypeIdentifier.layerNewDrawing;
          if (tuple.$2 != null && setSelectionStateLayer)
          {
            GetIt.I.get<DocumentState>().selectionState.selection.changeLayer(oldLayer: null, newLayer: tuple.$2!);
          }
      }
      if (tuple.$2 != null && identifier != null)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: identifier);
        }
        GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
      }
    }
    return tuple;
  }

  void moveUpLayer({required final LayerState? layerState})
  {
    if (layerState != null)
    {
      final Frame? frame = GetIt.I.get<DocumentState>().timeline.selectedFrame;
      if (frame != null && frame.layerList.contains(layer: layerState))
      {
        final int? sourcePosition = frame.layerList.getLayerPosition(state: layerState);
        if (sourcePosition != null && sourcePosition > 0)
        {
          changeLayerOrder(state: layerState, newPosition: sourcePosition - 1);
        }
      }
    }
  }

  void moveDownLayer({required final LayerState? layerState})
  {
    if (layerState != null)
    {
      final Frame? frame = GetIt.I.get<DocumentState>().timeline.selectedFrame;
      if (frame != null && frame.layerList.contains(layer: layerState))
      {
        final int? sourcePosition = frame.layerList.getLayerPosition(state: layerState);
        if (sourcePosition != null && sourcePosition < (GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.length - 1))
        {
          changeLayerOrder(state: layerState, newPosition: sourcePosition + 2);
        }
      }
    }
  }


  void changeLayerOrder({required final LayerState? state, required final int newPosition, final bool addToHistoryStack = true})
  {
    final Frame? frame = GetIt.I.get<DocumentState>().timeline.selectedFrame;
    if (state != null && frame != null)
    {
      final bool orderChanged = frame.layerList.changeLayerOrder(state: state, newPosition: newPosition);
      if (orderChanged)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
        }
        rasterLayersFrame();
        GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
      }
    }
  }

  LayerActionResult copyLayerToOtherFrame({required final LayerState sourceLayer, required final Frame targetFrame, required final int position, final bool addToHistoryStack = true})
  {
    GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
    final (LayerActionResult, LayerState?) addLayerResult = targetFrame.layerList.addLayerWithData(layer: sourceLayer, position: position);
    final LayerActionResult result = addLayerResult.$1;
    final LayerState? addLayer = addLayerResult.$2;
    if (addLayer != null && result == LayerActionResult.success)
    {
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerDuplicate);
      }
      newRasterData(layer: addLayer);
      GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
      GetIt.I.get<DocumentState>().timeline.selectFrame(frame: targetFrame, layerIndex: position);
    }
    return result;
  }

  LayerActionResult linkLayerToOtherFrame({required final LayerState sourceLayer, required final Frame targetFrame, required final int position, final bool addToHistoryStack = true})
  {
    GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
    final LayerActionResult result = targetFrame.layerList.addLinkLayer(layer: sourceLayer, position: position);

    if (result == LayerActionResult.success)
    {
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerDuplicate);
      }
      newRasterData(layer: sourceLayer);
      GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
      GetIt.I.get<DocumentState>().timeline.selectFrame(frame: targetFrame, layerIndex: position);
    }
    return result;

  }



  void changeLayerVisibility({required final LayerState? layerState})
  {
    if (layerState != null)
    {
      if (layerState.visibilityState.value == LayerVisibilityState.visible)
      {
        layerState.visibilityState.value = LayerVisibilityState.hidden;
      }
      else if (layerState.visibilityState.value == LayerVisibilityState.hidden)
      {
        layerState.visibilityState.value = LayerVisibilityState.visible;
      }
      final List<Frame> layerFrames = GetIt.I.get<DocumentState>().timeline.findFramesForLayer(layer: layerState);
      for (final Frame frame in layerFrames)
      {
        frame.layerList.onLayerVisibilityChanged(layer: layerState);
      }
      GetIt.I.get<ViewState>().repaintNotifier.repaint();
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerVisibilityChange, originLayer: layerState);
    }
  }

  void changeLayerLockState({required final LayerState? layerState})
  {
    if (layerState != null)
    {
      bool lockStateChanged = false;
      if (layerState is DrawingLayerState)
      {
        if (layerState.lockState.value == LayerLockState.unlocked)
        {
          layerState.lockState.value = LayerLockState.transparency;
        }
        else if (layerState.lockState.value == LayerLockState.transparency)
        {
          layerState.lockState.value = LayerLockState.locked;
        }
        else if (layerState.lockState.value == LayerLockState.locked)
        {
          layerState.lockState.value = LayerLockState.unlocked;
        }
        lockStateChanged = true;
      }
      else if (layerState is ShadingLayerState)
      {
        if (layerState.lockState.value == LayerLockState.unlocked)
        {
          layerState.lockState.value = LayerLockState.locked;
        }
        else if (layerState.lockState.value == LayerLockState.locked)
        {
          layerState.lockState.value = LayerLockState.unlocked;
        }
        lockStateChanged = true;

      }
      if (lockStateChanged)
      {
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerLockChange, originLayer: layerState);
      }
    }
  }


  void commitReferenceLayerChange({required final ReferenceLayerState layer})
  {
    if (layer.isDisposed)
    {
      return;
    }
    final LinkedHashSet<LayerState> liveLayers = LinkedHashSet<LayerState>();
    for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      liveLayers.addAll(frame.layerList.getAllLayers());
    }
    final int layerIndex = liveLayers.toList().indexOf(layer);
    if (layerIndex < 0)
    {
      return;
    }

    final HistoryManager historyManager = GetIt.I.get<HistoryManager>();
    final HistoryState? currentState = historyManager.getCurrentState();
    if (currentState != null && currentState.timeline.allLayers.length == liveLayers.length)
    {
      final HistoryLayer historyLayer = currentState.timeline.allLayers.elementAt(layerIndex);
      if (historyLayer is HistoryReferenceLayer && historyLayer.hasSameProperties(referenceState: layer))
      {
        return;
      }
    }
    historyManager.addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: layer);
  }

  void selectLayerAbove()
  {
    if (GetIt.I.get<DocumentState>().timeline.selectedFrame != null)
    {
      GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.selectLayerAbove();
    }
  }

  void selectLayerBelow()
  {
    if (GetIt.I.get<DocumentState>().timeline.selectedFrame != null)
    {
      GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.selectLayerBelow();
    }
  }


  void selectLayer({required final LayerState newLayer, LayerState? oldLayer, final bool addToHistoryStack = true})
  {
    if (GetIt.I.get<DocumentState>().timeline.selectedFrame != null)
    {
      final LayerState? previousLayer = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.selectLayer(newLayer: newLayer);
      GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
      oldLayer ??= previousLayer;
      final bool handsOverContent = oldLayer != newLayer && !GetIt.I.get<DocumentState>().selectionState.selection.isEmpty;
      if (oldLayer != newLayer)
      {
        GetIt.I.get<DocumentState>().selectionState.selection.changeLayer(oldLayer: oldLayer, newLayer: newLayer);
      }
      GetIt.I.get<ViewState>().repaintNotifier.repaint();
      if (addToHistoryStack && oldLayer != null)
      {
        GetIt.I.get<HistoryManager>().addState(
          identifier: handsOverContent ? HistoryStateTypeIdentifier.layerChangeWithSelection : HistoryStateTypeIdentifier.layerChange,
          originLayer: handsOverContent ? oldLayer : null,
          secondOriginLayer: handsOverContent ? newLayer : null,
        );
      }
    }
  }

  /// Disposes every layer in [candidates] that no longer sits in any frame.
  ///
  /// Called from wherever a layer is dropped, including [LayerCollection], which
  /// knows which layer it removed but not whether other frames still hold it.
  ///
  /// Layers hold a periodic timer that keeps them reachable, so dropping the last
  /// reference is not enough; they have to be told to let go. Membership is
  /// checked against the timeline rather than taken from the caller, because a
  /// layer can be linked into several frames and only dies with the last one.
  void disposeUnusedLayers({required final Iterable<LayerState> candidates})
  {
    final Set<LayerState> stillInUse = <LayerState>{};
    for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      stillInUse.addAll(frame.layerList.getAllLayers());
    }

    for (final LayerState candidate in candidates)
    {
      if (!stillInUse.contains(candidate) && !candidate.isDisposed)
      {
        candidate.dispose();
      }
    }
  }

  LayerActionResult layerDeletedSelected({required final LayerState? deleteLayer, final bool addToHistoryStack = true})
  {
    LayerActionResult result = LayerActionResult.unknownError;
    if (deleteLayer != null && GetIt.I.get<DocumentState>().timeline.selectedFrame != null)
    {
      GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
      if (GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.deleteLayer(deleteLayer: deleteLayer))
      {
        result = LayerActionResult.success;
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerDelete);
        }
      }
      else
      {
        result = LayerActionResult.lastLayerDelete;
      }
      rasterLayersAll();
      GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
    }
    return result;
  }

  LayerActionResult layerMerged({required final LayerState? mergeLayer, final bool addToHistoryStack = true})
  {
    LayerActionResult checkResult = LayerActionResult.unknownError;
    final Frame? frame = GetIt.I.get<DocumentState>().timeline.selectedFrame;
    if (mergeLayer != null && frame != null)
    {
      checkResult = frame.layerList.layerIsMergeable(mergeLayer: mergeLayer);
      if (checkResult == LayerActionResult.success)
      {
        GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
        frame.layerList.mergeLayer(mergeLayer: mergeLayer, canvasSize: GetIt.I.get<CanvasState>().canvasSize);
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerMerge);
        }
        rasterLayersFrame();
        GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
      }
    }
    return checkResult;
  }

  (LayerActionResult, LayerState?) layerDuplicateSelected({required final LayerState? duplicateLayer, final bool addToHistoryStack = true})
  {
    (LayerActionResult, LayerState?) result = (LayerActionResult.unknownError, null);
    final Frame? frame = GetIt.I.get<DocumentState>().timeline.selectedFrame;
    if (duplicateLayer != null && frame != null)
    {
      GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
      result = frame.layerList.duplicateLayer(duplicateLayer: duplicateLayer);
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerDuplicate);
      }
      newRasterData(layer: duplicateLayer);
      GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
    }
    return result;
  }

  void layerRasterPressed({required final LayerState rasterLayer, final bool addToHistoryStack = true})
  {
    final Frame? frame = GetIt.I.get<DocumentState>().timeline.selectedFrame;
    if (frame != null)
    {
      frame.layerList.rasterLayer(rasterLayer: rasterLayer, canvasSize: GetIt.I.get<CanvasState>().canvasSize, ramps: GetIt.I.get<PaletteState>().colorRamps);
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerRaster);
      }
      GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.reportChange();
    }
  }

  void rasterLayersFrame()
  {
    GetIt.I.get<DocumentState>().timeline.selectedFrame?.layerList.reRasterAllDrawingLayers();
  }

  void rasterLayersAll()
  {
    if (GetIt.I.get<DocumentState>().timeline.selectedFrame != null)
    {
      //raster current frame first
      rasterLayersFrame();
      final int currentIndex = GetIt.I.get<DocumentState>().timeline.selectedFrameIndex;
      for (int i = 0; i < GetIt.I.get<DocumentState>().timeline.frames.value.length; i++)
      {
        if (i != currentIndex)
        {
          GetIt.I.get<DocumentState>().timeline.frames.value[i].layerList.reRasterAllDrawingLayers();
        }
      }
    }
  }

  void newRasterData({required final LayerState layer})
  {
    final List<Frame> frames = GetIt.I.get<DocumentState>().timeline.findFramesForLayer(layer: layer);
    for (final Frame frame in frames)
    {
      frame.layerList.layerRasterDone(layer: layer);
    }
    GetIt.I.get<ViewState>().repaintNotifier.repaint();
  }
}
