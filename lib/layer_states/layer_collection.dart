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

import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/canvas_transformation.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/constraints/reference_layer_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:logger/logger.dart';

enum LayerActionResult {
  success,
  layerLimitReached,
  frameLimitReached,
  invalidIndex,
  alreadyExists,
  noLayerBelow,
  linkedLayerMergeFrom,
  linkedLayerMergeTo,
  invisibleLayerMergeFrom,
  invisibleLayerMergeTo,
  lockedLayerMergeFrom,
  lockedLayerMergeTo,
  onlyMergeDrawingLayers,
  effectLayerMerge,
  lastLayerDelete,

  unknownError,
}

class LayerCollection with ChangeNotifier {
  static const int maxLayers = 256;
  final List<LayerState> _layers = <LayerState>[];
  ui.Image? _rasterImage;
  int _rasterImageGeneration = 0;
  static const int _compositeDelayMs = 150;
  Timer? _compositeTimer;

  ui.Image? get rasterImage => _rasterImage;

  final Map<RasterableLayerState, Set<RasterableLayerState>> _layerDependencies = <RasterableLayerState, Set<RasterableLayerState>>{};
  final Map<RasterableLayerState, Set<RasterableLayerState>> _layerDependents = <RasterableLayerState, Set<RasterableLayerState>>{};

  final Set<RasterableLayerState> _layersCurrentlyRendering = <RasterableLayerState>{};
  final Map<RasterableLayerState, int> _recentInvalidations = <RasterableLayerState, int>{};
  final Map<RasterableLayerState, DateTime> _lastInvalidationTime = <RasterableLayerState, DateTime>{};

  bool get isEmpty
  {
    return _layers.isEmpty;
  }

  bool get isNotEmpty
  {
    return _layers.isNotEmpty;
  }

  int get length
  {
    return _layers.length;
  }

  LayerState get first
  {
    return _layers.first;
  }

  final ValueNotifier<int?> _selectedLayerIndexNotifier = ValueNotifier<int?>(null,);

  int? get selectedLayerIndex
  {
    return _selectedLayerIndexNotifier.value;
  }


  LayerCollection({required final List<LayerState> layers, required final int selLayerIdx,})
  {
    _selectedLayerIndexNotifier.addListener(updateIndividualLayerSelection);
    addListener(updateIndividualLayerSelection);
    _addLayers(layers: layers);
    if (selLayerIdx >= 0 && selLayerIdx < layers.length)
    {
      _selectedLayerIndexNotifier.value = selLayerIdx;
    }
    else if (layers.isNotEmpty)
    {
      _selectedLayerIndexNotifier.value = 0;
    }
    _rebuildDependencies();
  }

  LayerCollection.empty()
  {
    _selectedLayerIndexNotifier.addListener(updateIndividualLayerSelection);
    addListener(updateIndividualLayerSelection);
    _rebuildDependencies();
  }

  void updateIndividualLayerSelection()
  {
    for (int i = 0; i < _layers.length; i++)
    {
      final bool shouldBeSelected = i == selectedLayerIndex;
      if (shouldBeSelected != _layers[i].selectedInCurrentFrameNotifier.value)
      {
        _layers[i].selectedInCurrentFrameNotifier.value = shouldBeSelected;
      }
    }
  }


  void _addLayers({required final List<LayerState> layers})
  {
    bool couldAddAllLayers = true;
    for (final LayerState layer in layers)
    {
      if (_layers.length >= maxLayers)
      {
        couldAddAllLayers = false;
        break;
      }
      else
      {
        _layers.add(layer);
      }
    }
    if (!couldAddAllLayers)
    {
      //no caller hands over more than maxLayers (a frame in a kpix file holds at
      //most 255), so this guards an invariant rather than a user action
      GetIt.I.get<Logger>().w("Dropped ${layers.length - maxLayers} layer(s): a frame holds at most $maxLayers.");
    }
    updateIndividualLayerSelection();
  }

  bool contains({required final LayerState layer})
  {
    return _layers.contains(layer);
  }


  LayerState getLayer({required final int index})
  {
    return _layers[index];
  }

  void clear({final bool notify = true})
  {
    final List<LayerState> removed = List<LayerState>.of(_layers);
    _layers.clear();
    _clearDependencies();
    //the composite belongs to a stack that is gone; the raised generation also
    //keeps a composite still being made from being taken on
    _rasterImageGeneration++;
    _compositeTimer?.cancel();
    _compositeTimer = null;
    _retireRasterImage(image: _rasterImage);
    _rasterImage = null;
    GetIt.I.get<LayerManager>().disposeUnusedLayers(candidates: removed);
    _selectedLayerIndexNotifier.value = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _triggerNewLayerRender({required final LayerState layer})
  {
    if (layer is RasterableLayerState)
    {
      //always queue the render: a newly created layer may still be busy with its
      //constructor raster which ran before the layer was attached to any frame
      //(and therefore produced no image)
      layer.doManualRaster = true;
      //shading layers above the insert position composite everything below them,
      //so their raster no longer matches the stack the new layer is part of
      invalidateDependents(layer: layer);
    }
  }



  (LayerActionResult, LayerState?) addLayerWithData({required final LayerState layer, required final int position})
  {
    if (_layers.length >= maxLayers)
    {
      return (LayerActionResult.layerLimitReached, null);
    }
    else if (position < 0 || position > _layers.length)
    {
      return (LayerActionResult.invalidIndex, null);
    }
    else
    {
      final LayerState addLayer = layer.copy();
      _layers.insert(position, addLayer);
      _rebuildDependencies();
      _triggerNewLayerRender(layer: addLayer);
      notifyListeners();
      return (LayerActionResult.success, addLayer);
    }
  }

  LayerActionResult addLinkLayer({required final LayerState layer, required final int position,})
  {
    if (_layers.length >= maxLayers)
    {
      return LayerActionResult.layerLimitReached;
    }
    else if (position < 0 || position > _layers.length)
    {
      return LayerActionResult.invalidIndex;
    }
    else if (_layers.contains(layer))
    {
      return LayerActionResult.alreadyExists;
    }
    else
    {
      _layers.insert(position, layer);
      _rebuildDependencies();
      notifyListeners();
      reRasterAllDrawingLayers();
      return LayerActionResult.success;
    }
  }


  (LayerActionResult, ReferenceLayerState?) addNewReferenceLayer({final bool select = false})
  {
    final ReferenceLayerState newLayer = ReferenceLayerState(
        aspectRatio: ReferenceLayerConstraints.aspectRatioDefault,
        image: null,
        offsetX: 0,
        offsetY: 0,
        opacity: ReferenceLayerConstraints.opacityDefault,
        zoom: ReferenceLayerConstraints.zoomDefault,
        brightness: ReferenceLayerConstraints.brightnessDefault,
        contrast: ReferenceLayerConstraints.contrastDefault,
        warmth: ReferenceLayerConstraints.warmthDefault,
        saturation: ReferenceLayerConstraints.saturationDefault,

    );
    final LayerActionResult result = _addNewLayer(newLayer: newLayer, select: select);
    return (result, result == LayerActionResult.success ? newLayer : null);
  }

  (LayerActionResult, ShadingLayerState?) addNewShadingLayer({final bool select = false})
  {
    final ShadingLayerState newLayer = ShadingLayerState();
    final LayerActionResult result = _addNewLayer(newLayer: newLayer, select: select);
    return (result, result == LayerActionResult.success ? newLayer : null);
  }

  (LayerActionResult, DitherLayerState?) addNewDitherLayer({final bool select = false})
  {
    final DitherLayerState newLayer = DitherLayerState();
    final LayerActionResult result = _addNewLayer(newLayer: newLayer, select: select);
    return (result, result == LayerActionResult.success ? newLayer : null);
  }

  (LayerActionResult, GridLayerState?) addNewGridLayer({final bool select = false})
  {
    final GridLayerState newLayer = GridLayerState(
      brightness: GridLayerConstraints.brightnessDefault,
      gridType: GridLayerConstraints.gridTypeDefault,
      intervalX: GridLayerConstraints.intervalXDefault,
      intervalY: GridLayerConstraints.intervalYDefault,
      opacity: GridLayerConstraints.opacityDefault,
      horizonPosition: GridLayerConstraints.horizonDefault,
      vanishingPoint1: GridLayerConstraints.vanishingPoint1Default,
      vanishingPoint2: GridLayerConstraints.vanishingPoint2Default,
      vanishingPoint3: GridLayerConstraints.vanishingPoint3Default,
    );

    final LayerActionResult result = _addNewLayer(newLayer: newLayer, select: select);
    return (result, result == LayerActionResult.success ? newLayer : null);
  }

  (LayerActionResult, DrawingLayerState?) addNewDrawingLayer({final bool select = false, final CoordinateColorMapNullable? content, required final CoordinateSetI canvasSize, required final List<KPalRampData> ramps,})
  {
    final DrawingLayerState newLayer = DrawingLayerState(size: canvasSize, content: content, ramps: ramps,);
    final LayerActionResult result = _addNewLayer(newLayer: newLayer, select: select);
    return (result, result == LayerActionResult.success ? newLayer : null);
  }

  LayerActionResult _addNewLayer({required final LayerState newLayer, required final bool select,})
  {
    if (_layers.length >= maxLayers)
    {
      return LayerActionResult.layerLimitReached;
    }
    else
    {
      if (_layers.isEmpty || selectedLayerIndex == null)
      {
        _layers.add(newLayer);
        _selectedLayerIndexNotifier.value = 0;
      }
      else
      {
        _layers.insert(selectedLayerIndex!, newLayer);
        _selectedLayerIndexNotifier.value =_selectedLayerIndexNotifier.value! + 1;
      }
      if (select)
      {
        selectLayer(newLayer: newLayer);
      }
      _rebuildDependencies();
      //a new layer has no raster of its own yet; without this it only ever gets
      //one when some other layer happens to re-raster and invalidates it
      _triggerNewLayerRender(layer: newLayer);
      notifyListeners();
      return LayerActionResult.success;
    }
  }

  void replaceLayers({required final List<LayerState> layers, required final int selLayerIdx})
  {
    _layers.clear();
    _layers.addAll(layers);
    if (selLayerIdx >= 0 && selLayerIdx < _layers.length)
    {
      _selectedLayerIndexNotifier.value = selLayerIdx;
    }
    else
    {
      _selectedLayerIndexNotifier.value = _layers.isEmpty ? null : 0;
    }
    _rebuildDependencies();
    updateIndividualLayerSelection();
    notifyListeners();
  }

  LayerState? selectLayer({required final LayerState newLayer})
  {
    if (_layers.contains(newLayer))
    {
      LayerState? previousLayer;
      if (selectedLayerIndex != null)
      {
        previousLayer = _layers[selectedLayerIndex!];
      }
      if (previousLayer != newLayer)
      {
        _selectedLayerIndexNotifier.value = _layers.indexOf(newLayer);
        notifyListeners();
      }

      return previousLayer ?? newLayer;
    }
    else
    {
      return null;
    }
  }

  int? getLayerPosition({required final LayerState state})
  {
    final int sourcePosition = _layers.indexOf(state);
    return sourcePosition == -1 ? null : sourcePosition;
  }

  LayerState? getSelectedLayer()
  {
    if (selectedLayerIndex != null && selectedLayerIndex! >= 0 && selectedLayerIndex! < _layers.length)
    {
      return _layers[selectedLayerIndex!];
    }
    else
    {
      return null;
    }
  }

  void selectLayerAbove()
  {
    if (selectedLayerIndex != null && selectedLayerIndex! > 0)
    {
      selectLayer(newLayer: _layers[selectedLayerIndex! - 1]);
      notifyListeners();
    }
  }

  void selectLayerBelow()
  {
    if (selectedLayerIndex != null && selectedLayerIndex! < _layers.length - 1)
    {
      selectLayer(newLayer: _layers[selectedLayerIndex! + 1]);
      notifyListeners();
    }
  }

  bool deleteLayer({required final LayerState deleteLayer})
  {
    if (_layers.length > 1)
    {
      final int? deleteLayerIndex = getLayerPosition(state: deleteLayer);
      final int? selectedBefore = selectedLayerIndex;
      _layers.remove(deleteLayer);
      int newSelectedIndex = 0;
      if (deleteLayerIndex != null && selectedBefore != null)
      {
        newSelectedIndex = selectedBefore > deleteLayerIndex ? selectedBefore - 1 : selectedBefore;
      }
      _selectedLayerIndexNotifier.value = newSelectedIndex.clamp(0, _layers.length - 1);
      _rebuildDependencies();
      GetIt.I.get<LayerManager>().disposeUnusedLayers(candidates: <LayerState>[deleteLayer]);

      notifyListeners();
      return true;
    }
    else
    {
      return false;
    }
  }

  LayerActionResult layerIsMergeable({required final LayerState mergeLayer})
  {
    LayerActionResult result = LayerActionResult.success;
    if (mergeLayer is DrawingLayerState)
    {
      final DocumentState documentState = GetIt.I.get<DocumentState>();
      final int mergeLayerIndex = _layers.indexOf(mergeLayer);
      if (mergeLayerIndex == _layers.length - 1)
      {
        result = LayerActionResult.noLayerBelow;
      }
      else if (documentState.timeline.isLayerLinked(layer: mergeLayer))
      {
        result = LayerActionResult.linkedLayerMergeFrom;
      }
      else if (mergeLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        result = LayerActionResult.invisibleLayerMergeFrom;
      }
      else if (_layers[mergeLayerIndex + 1].visibilityState.value == LayerVisibilityState.hidden)
      {
        result = LayerActionResult.invisibleLayerMergeTo;
      }
      else if (mergeLayer.lockState.value == LayerLockState.locked)
      {
        result = LayerActionResult.lockedLayerMergeFrom;
      }
      else if (_layers[mergeLayerIndex + 1].runtimeType == DrawingLayerState && (_layers[mergeLayerIndex + 1] as DrawingLayerState).lockState.value == LayerLockState.locked)
      {
        result = LayerActionResult.lockedLayerMergeTo;
      }
      else if (_layers[mergeLayerIndex + 1].runtimeType != DrawingLayerState)
      {
        result = LayerActionResult.onlyMergeDrawingLayers;
      }
      else if (documentState.timeline.isLayerLinked(layer: _layers[mergeLayerIndex + 1],))
      {
        result = LayerActionResult.linkedLayerMergeTo;
      }
      else if (mergeLayer.layerSettings.hasActiveSettings() || _layers[mergeLayerIndex + 1].runtimeType == DrawingLayerState && (_layers[mergeLayerIndex + 1] as DrawingLayerState).layerSettings.hasActiveSettings())
      {
        result = LayerActionResult.effectLayerMerge;
      }
    }
    else
    {
      //SHOULD NEVER HAPPEN
      result = LayerActionResult.onlyMergeDrawingLayers;
    }
    return result;
  }

  LayerActionResult mergeLayer({required final LayerState mergeLayer, required final CoordinateSetI canvasSize,})
  {
    final LayerActionResult result = layerIsMergeable(mergeLayer: mergeLayer);
    if (result == LayerActionResult.success)
    {
      final DrawingLayerState drawingMergeLayer = mergeLayer as DrawingLayerState;
      final int mergeLayerIndex = _layers.indexOf(mergeLayer);
      final int intoLayerIndex = mergeLayerIndex + 1;
      final CoordinateColorMapNullable refs = HashMap<CoordinateSetI, ColorReference?>();

      final DrawingLayerState drawingIntoLayer = _layers[intoLayerIndex] as DrawingLayerState;
      for (int x = 0; x < canvasSize.x; x++)
      {
        for (int y = 0; y < canvasSize.y; y++)
        {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          if (drawingMergeLayer.getDataEntry(coord: curCoord) == null && drawingIntoLayer.getDataEntry(coord: curCoord) != null)
          {
            refs[curCoord] = drawingIntoLayer.getDataEntry(coord: curCoord);
          }
        }
      }
      _layers.remove(drawingIntoLayer);
      _rebuildDependencies();
      GetIt.I.get<LayerManager>().disposeUnusedLayers(candidates: <LayerState>[drawingIntoLayer]);
      drawingMergeLayer.setDataAll(list: refs);
      selectLayer(newLayer: drawingMergeLayer);
      notifyListeners();
    }
    return result;
  }

  (LayerActionResult, LayerState?) duplicateLayer({required final LayerState duplicateLayer, final bool insertAtEnd = false,})
  {
    if (_layers.length >= maxLayers)
    {
      return (LayerActionResult.layerLimitReached, null);
    }
    else
    {
      final LayerState addLayer = duplicateLayer.copy();
      if (insertAtEnd)
      {
        _layers.add(addLayer);
      }
      else
      {
        final int? currentIndex = getLayerPosition(state: duplicateLayer);
        if (currentIndex != null)
        {
          _layers.insert(currentIndex, addLayer);
        }
      }
      _rebuildDependencies();
      _triggerNewLayerRender(layer: addLayer);
      notifyListeners();
      return (LayerActionResult.success, addLayer);
    }
  }

  bool changeLayerOrder({required final LayerState state, required final int newPosition,})
  {
    bool orderChanged = false;
    final int? sourcePosition = getLayerPosition(state: state);
    if (sourcePosition != null && sourcePosition != newPosition &&
        (sourcePosition + 1) != newPosition)
    {
      final int? selectedBefore = selectedLayerIndex;
      final bool movingSelectedLayer = selectedBefore != null &&
          selectedBefore == sourcePosition;
      _layers.removeAt(sourcePosition);
      if (newPosition > sourcePosition)
      {
        _layers.insert(newPosition - 1, state);
        if (movingSelectedLayer)
        {
          _selectedLayerIndexNotifier.value = newPosition - 1;
        }
      }
      else
      {
        _layers.insert(newPosition, state);
        if (movingSelectedLayer) {
          _selectedLayerIndexNotifier.value = newPosition;
        }
      }

      if (!movingSelectedLayer && selectedBefore != null)
      {
        if (newPosition <= selectedBefore && sourcePosition > selectedBefore)
        {
          _selectedLayerIndexNotifier.value = selectedBefore + 1;
        }
        else if (sourcePosition < selectedBefore && newPosition > selectedBefore)
        {
          _selectedLayerIndexNotifier.value = selectedBefore - 1;
        }
      }

      //what lies below a layer changed, so do the layers its effects read
      _rebuildDependencies();
      orderChanged = true;
    }
    notifyListeners();
    return orderChanged;
  }

  void rasterLayer(
      {required final LayerState rasterLayer, required final CoordinateSetI canvasSize, required final List<KPalRampData> ramps,})
  {
    if (rasterLayer is GridLayerState)
    {
      rasterLayer.getHashMap().then((final CoordinateColorMap data)
      {
        _replaceCurrentLayerWithDrawingLayer(data: data,
            originalLayer: rasterLayer,
            canvasSize: canvasSize,
            ramps: ramps,);
      });
    }
    else if (rasterLayer is ShadingLayerState)
    {
      _rasterShadingLayer(shadingLayer: rasterLayer).then((final void _)
      {
        _shadingLayerRastered(shadingLayer: rasterLayer);
      },);
    }
  }

  void _shadingLayerRastered({required final ShadingLayerState shadingLayer})
  {
    deleteLayer(deleteLayer: shadingLayer);
    notifyListeners();
  }

  Future<void> _rasterShadingLayer({required final ShadingLayerState shadingLayer,}) async
  {
    final int? layerIndex = getLayerPosition(state: shadingLayer);
    if (layerIndex != null && layerIndex >= 0 && layerIndex < _layers.length) {
      final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];
      final HashMap<DrawingLayerState,
          CoordinateColorMapNullable> shadeLayerMap = HashMap<
          DrawingLayerState,
          CoordinateColorMapNullable>();

      for (int i = layerIndex; i < _layers.length; i++)
      {
        final LayerState layer = _layers[i];
        if (layer is DrawingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
        {
          drawingLayers.add(layer);
          shadeLayerMap[layer] = HashMap<CoordinateSetI, ColorReference?>();
        }
      }

      shadingLayer.forEachValue(action: (final int x, final int y, final int value)
      {
        final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        for (final DrawingLayerState drawingLayer in drawingLayers)
        {
          final ColorReference? curCol = drawingLayer.getDataEntry(coord: coord, withSettingsPixels: true,);
          if (curCol != null)
          {
            if (shadingLayer.runtimeType == ShadingLayerState)
            {
              final int targetIndex = (curCol.colorIndex + value).clamp(0, curCol.ramp.references.length - 1,);
              shadeLayerMap[drawingLayer]![coord] =
              curCol.ramp.references[targetIndex];
              break;
            }
            else
            {
              final int ditherVal = shadingLayer.getDisplayValueAt(
                  coord: coord,) ?? 0;
              if (ditherVal != 0)
              {
                final int newColorIndex = (curCol.colorIndex + ditherVal).clamp(0, curCol.ramp.references.length - 1,);
                shadeLayerMap[drawingLayer]![coord] =
                curCol.ramp.references[newColorIndex];
                break;
              }
            }
          }
        }
      },);

      //applying shading
      for (final MapEntry<DrawingLayerState, CoordinateColorMapNullable> entry in shadeLayerMap.entries)
      {
        if (entry.value.isNotEmpty)
        {
          entry.key.setDataAll(list: entry.value);
        }
      }
    }
  }

  void _replaceCurrentLayerWithDrawingLayer({required final CoordinateColorMap data, required final LayerState originalLayer, required final CoordinateSetI canvasSize, required final List<KPalRampData> ramps,})
  {
    final DrawingLayerState drawingLayer = DrawingLayerState(size: canvasSize, content: data, ramps: ramps,);
    final int? insertIndex = getLayerPosition(state: originalLayer);
    if (insertIndex != null)
    {
      _layers.remove(originalLayer);
      _layers.insert(insertIndex, drawingLayer);
      drawingLayer.visibilityState.value = originalLayer.visibilityState.value;
      _rebuildDependencies();
      //the rasterized layer is replaced by its flattened result; it survives only
      //if another frame still links it
      GetIt.I.get<LayerManager>().disposeUnusedLayers(candidates: <LayerState>[originalLayer]);
      _triggerNewLayerRender(layer: drawingLayer);
      notifyListeners();
    }
  }

  int getFrameIndex()
  {
    int index = -1;
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    for (int i = 0; i < documentState.timeline.frames.value.length; i++)
    {
      if (documentState.timeline.frames.value[i].layerList == this)
      {
        index = i;
        break;
      }
    }

    return index;
  }

  void reRasterAllDrawingLayers()
  {
    for (int i = _layers.length - 1; i >= 0; i--)
    {
      final LayerState layer = _layers[i];
      if (layer is RasterableLayerState)
      {
        final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
        if (deps.isEmpty)
        {
          //queueing while the layer is rasterizing is safe: the request
          //is serviced after the current raster finishes
          layer.doManualRaster = true;
        }
      }
    }
  }

  void _retireRasterImage({required final ui.Image? image})
  {
    if (image == null)
    {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) => image.dispose());
    SchedulerBinding.instance.scheduleFrame();
  }

  void layerRasterDone({required final LayerState layer})
  {
    if (layer is! RasterableLayerState) return;

    final Set<RasterableLayerState> dependents = _getDependents(layer: layer);
    for (final RasterableLayerState dependent in dependents)
    {
      if (areDependenciesComplete(layer: dependent))
      {
        dependent.forceFullRender();
        dependent.pollRaster();
      }
    }

    bool anyLayerStillPending = false;
    for (final LayerState l in _layers)
    {
      if (l is RasterableLayerState)
      {
        if (l.isRasterizing || l.doManualRaster)
        {
          anyLayerStillPending = true;
          break;
        }
      }
    }

    if (!anyLayerStillPending)
    {
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      _compositeTimer?.cancel();
      //the selected frame's composite only serves playback, so a drag does not
      //rebuild it after every batch; other frames' also serve frame blending
      if (timeline.findFrameForCollection(collection: this) == timeline.selectedFrame && !timeline.isPlaying.value)
      {
        _compositeTimer = Timer(const Duration(milliseconds: _compositeDelayMs), _rebuildComposite);
      }
      else
      {
        _rebuildComposite();
      }
    }
  }

  void _rebuildComposite()
  {
    _compositeTimer = null;
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final CanvasState canvasState = GetIt.I.get<CanvasState>();
    final Frame? frame = documentState.timeline.findFrameForCollection(collection: this,);
    final int generation = ++_rasterImageGeneration;
    getImageFromLayers(
        layerCollection: this,
        canvasSize: canvasState.canvasSize,
        selection: documentState.selectionState.selection,
        frame: frame,
    ).then((final ui.Image img) {
      //only accept the result if no newer composite was requested in the meantime
      if (generation == _rasterImageGeneration)
      {
        _retireRasterImage(image: _rasterImage);
        _rasterImage = img;
      }
      else
      {
        _retireRasterImage(image: img);
      }
    });
  }

  void onLayerVisibilityChanged({required final LayerState layer})
  {
    _rebuildDependencies();
    if (layer is RasterableLayerState)
    {
      if (layer.visibilityState.value == LayerVisibilityState.visible)
      {
        //queueing while the layer is rasterizing is safe: the request
        //is serviced after the current raster finishes
        layer.doManualRaster = true;
      }
      invalidateDependents(layer: layer);
    }
    notifyListeners();
  }

  void remapLayers({required final KPalRampData newData, required final HashMap<int, int> map,})
  {
    for (final LayerState layer in _layers)
    {
      if (layer is DrawingLayerState)
      {
        layer.remapSingleRamp(newData: newData, map: map);
        layer.remapSingleRampLayerEffects(newData: newData, map: map);
      }
    }
  }

  /// Transforms every drawing, shading and dither layer not in [done] yet, and
  /// adds it there. A layer linked into several frames sits in several
  /// collections, but must only be turned once.
  void transformLayers({required final CanvasTransformation transformation, required final CoordinateSetI oldSize, required final Set<LayerState> done,})
  {
    for (final LayerState layer in _layers)
    {
      if (layer is DrawingLayerState && done.add(layer))
      {
        layer.transformLayer(transformation: transformation, oldSize: oldSize,);
      }
      else if (layer is ShadingLayerState && done.add(layer))
      {
        layer.transformLayer(transformation: transformation, oldSize: oldSize,);
      }
    }
    notifyListeners();
  }

  void deleteRampFromLayers(
      {required final KPalRampData ramp, required final ColorReference backupColor,}) {
    for (final LayerState layer in _layers) {
      if (layer is DrawingLayerState) {
        layer.deleteRamp(ramp: ramp);
        layer.deleteRampFromLayerEffects(
            ramp: ramp, backupColor: backupColor,);
      }
    }
  }

  Iterable<LayerState> getVisibleLayers()
  {
    return _layers.where((final LayerState x) =>
    x.visibilityState.value == LayerVisibilityState.visible,);
  }

  Iterable<RasterableLayerState> getVisibleRasterLayers()
  {
    final List<RasterableLayerState> rLayers = <RasterableLayerState>[];
    for (final LayerState layer in _layers)
    {
      if (layer.visibilityState.value == LayerVisibilityState.visible && layer is RasterableLayerState)
      {
        rLayers.add(layer);
      }
    }

    return rLayers;
  }

  List<LayerState> getAllLayers()
  {
    return _layers;
  }

  ColorReference? getColorFromImageAtPosition({required final CoordinateSetI normPos, required final ColorReference? selectionReference, required final bool rawMode,})
  {
    ColorReference? colRef;
    int shading = 0;
    for (final LayerState layer in _layers)
    {
      if (!rawMode && layer.visibilityState.value == LayerVisibilityState.visible && layer is ShadingLayerState)
      {
        final int valueAtCoord = layer.getDisplayValueAt(coord: normPos) ?? 0;
        shading += valueAtCoord;
      }
      else if (layer.visibilityState.value == LayerVisibilityState.visible && layer is DrawingLayerState)
      {
        if (selectedLayerIndex != null && _layers[selectedLayerIndex!] == layer && selectionReference != null)
        {
          colRef = selectionReference;
          if (!rawMode && layer.getSettingsPixel(coord: normPos) != null)
          {
            colRef = layer.getSettingsPixel(coord: normPos);
          }
          break;
        }
        else
        {
          final ColorReference? coordAtPos = layer.getDataEntry(coord: normPos, withSettingsPixels: !rawMode,);
          if (coordAtPos != null)
          {
            colRef = coordAtPos;
            break;
          }
        }
      }
    }
    if (shading != 0 && colRef != null)
    {
      colRef = colRef.ramp.references[ (colRef.colorIndex + shading).clamp(0, colRef.ramp.references.length - 1,)];
    }

    return colRef;
  }

  Set<RasterableLayerState> _getDependencies({required final RasterableLayerState layer,})
  {
    return _layerDependencies[layer] ?? <RasterableLayerState>{};
  }

  Set<RasterableLayerState> _getDependents({required final RasterableLayerState layer,})
  {
    return _layerDependents[layer] ?? <RasterableLayerState>{};
  }

  void _addDependency({required final RasterableLayerState dependent, required final RasterableLayerState dependency,})
  {
    _layerDependencies
        .putIfAbsent(dependent, () => <RasterableLayerState>{})
        .add(dependency);
    _layerDependents
        .putIfAbsent(dependency, () => <RasterableLayerState>{})
        .add(dependent);
  }

  bool areDependenciesComplete({required final RasterableLayerState layer})
  {
    final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
    for (final RasterableLayerState dep in deps)
    {
      if (dep.isRasterizing || dep.doManualRaster)
      {
        return false;
      }
    }
    return true;
  }

  List<RasterableLayerState> _pendingDependents({required final RasterableLayerState layer})
  {
    final List<RasterableLayerState> pending = <RasterableLayerState>[];
    for (final RasterableLayerState dependent in _getDependents(layer: layer))
    {
      if (!dependent.isDisposed && (dependent.isRasterizing || dependent.doManualRaster))
      {
        pending.add(dependent);
      }
    }
    return pending;
  }

  bool areDependentsComplete({required final RasterableLayerState layer})
  {
    return _pendingDependents(layer: layer).isEmpty;
  }

  Future<void> waitForDependents({required final RasterableLayerState layer}) async
  {
    for (int round = 0; round <= _layers.length; round++)
    {
      final List<RasterableLayerState> pending = _pendingDependents(layer: layer);
      if (pending.isEmpty)
      {
        return;
      }
      await Future.wait<void>(pending.map((final RasterableLayerState dependent) => dependent.rasterizationComplete));
    }
  }

  void invalidateDependents({required final RasterableLayerState layer})
  {
    final Set<RasterableLayerState> dependents = _getDependents(layer: layer);

    for (final RasterableLayerState dependent in dependents)
    {
      if (_layersCurrentlyRendering.contains(dependent) || dependent.isRasterizing)
      {
        //the layer is busy: queue the request instead of dropping it;
        //it is serviced by the layer's timer after the current raster finishes
        dependent.forceFullRender();
        continue;
      }

      if (dependent.doManualRaster)
      {
        //already pending: upgrade the pending render to a full one so the
        //dependency's changed area is covered, but do not cascade again
        dependent.forceFullRender();
      }
      else
      {
        final DateTime now = DateTime.now();
        final DateTime? lastTime = _lastInvalidationTime[dependent];

        if (lastTime != null && now.difference(lastTime).inMilliseconds < 100)
        {
          _recentInvalidations[dependent] = (_recentInvalidations[dependent] ?? 0) + 1;

          if (_recentInvalidations[dependent]! > 10)
          {
            GetIt.I.get<Logger>().e("WARNING: Breaking invalidation loop for ${dependent.runtimeType} at index ${_layers.indexOf(dependent)}");
            _recentInvalidations[dependent] = 0;
            dependent.forceFullRender();
            return;
          }
        }
        else
        {
          _recentInvalidations[dependent] = 1;
        }

        _lastInvalidationTime[dependent] = now;

        //a dependency changed; the dependent's own dirty regions do not cover
        //the changed area, so a full render is required
        dependent.forceFullRender();
        invalidateDependents(layer: dependent);
      }
    }
  }

  void _clearDependencies()
  {
    _layerDependencies.clear();
    _layerDependents.clear();
    _layersCurrentlyRendering.clear();
    _recentInvalidations.clear();
    _lastInvalidationTime.clear();
  }

  void rebuildDependencies()
  {
    _rebuildDependencies();
  }

  bool dependsOn({required final RasterableLayerState dependent, required final RasterableLayerState dependency})
  {
    return _layerDependencies[dependent]?.contains(dependency) ?? false;
  }

  void _rebuildDependencies()
  {
    _clearDependencies();

    for (int i = 0; i < _layers.length; i++)
    {
      final LayerState layer = _layers[i];

      if (layer is ShadingLayerState || layer is DitherLayerState || (layer is DrawingLayerState && layer.settings.readsLayersBelow))
      {
        for (int j = i + 1; j < _layers.length; j++)
        {
          if (_layers[j] is RasterableLayerState)
          {
            _addDependency(dependent: layer as RasterableLayerState, dependency: _layers[j] as RasterableLayerState,);
          }
        }
      }
    }
  }

  void invalidateLayerInAllFrames({required final RasterableLayerState layer})
  {
    layer.doManualRaster = true;
    invalidateDependents(layer: layer);
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final List<Frame> framesWithThisLayer = documentState.timeline
        .findFramesForLayer(layer: layer);

    for (final Frame frame in framesWithThisLayer)
    {
      if (frame.layerList != this)
      {
        frame.layerList.invalidateDependents(layer: layer);
      }
    }
  }

  void lockLayerForRendering({required final RasterableLayerState layer})
  {
    _layersCurrentlyRendering.add(layer);
  }

  void unlockLayerFromRendering({required final RasterableLayerState layer})
  {
    _layersCurrentlyRendering.remove(layer);
  }

  void lockLayerAndDependenciesForRendering({required final RasterableLayerState layer})
  {
    lockLayerForRendering(layer: layer);

    final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
    for (final RasterableLayerState dep in deps) {
      lockLayerForRendering(layer: dep);
    }
  }

  void unlockLayerAndDependenciesFromRendering({required final RasterableLayerState layer})
  {
    unlockLayerFromRendering(layer: layer);

    final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
    for (final RasterableLayerState dep in deps)
    {
      unlockLayerFromRendering(layer: dep);
    }
  }
}
