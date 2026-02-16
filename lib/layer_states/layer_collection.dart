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
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';

class LayerCollection with ChangeNotifier {
  static const int maxLayers = 256;
  final List<LayerState> _layers = <LayerState>[];
  ui.Image? _rasterImage;

  ui.Image? get rasterImage => _rasterImage;

  final Map<RasterableLayerState,
      Set<RasterableLayerState>> _layerDependencies = <RasterableLayerState,
      Set<RasterableLayerState>>{};
  final Map<RasterableLayerState,
      Set<RasterableLayerState>> _layerDependents = <RasterableLayerState,
      Set<RasterableLayerState>>{};

  final Set<RasterableLayerState> _layersCurrentlyRendering = {};
  final Map<RasterableLayerState, int> _recentInvalidations = {};
  final Map<RasterableLayerState, DateTime> _lastInvalidationTime = {};

  bool get isEmpty {
    return _layers.isEmpty;
  }

  bool get isNotEmpty {
    return _layers.isNotEmpty;
  }

  int get length {
    return _layers.length;
  }

  LayerState get first {
    return _layers.first;
  }

  final ValueNotifier<int?> _selectedLayerIndexNotifier = ValueNotifier<int?>(
      null,);

  int? get selectedLayerIndex {
    return _selectedLayerIndexNotifier.value;
  }


  LayerCollection({required final List<
      LayerState> layers, required final int selLayerIdx,}) {
    _selectedLayerIndexNotifier.addListener(updateIndividualLayerSelection);
    addListener(updateIndividualLayerSelection);
    _addLayers(layers: layers);
    if (selLayerIdx >= 0 && selLayerIdx < layers.length) {
      _selectedLayerIndexNotifier.value = selLayerIdx;
    }
    else if (layers.isNotEmpty) {
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

  void updateIndividualLayerSelection() {
    for (int i = 0; i < _layers.length; i++) {
      final bool shouldBeSelected = i == selectedLayerIndex;
      if (shouldBeSelected != _layers[i].selectedInCurrentFrameNotifier.value) {
        _layers[i].selectedInCurrentFrameNotifier.value = shouldBeSelected;
      }
    }
  }


  void _addLayers({required final List<LayerState> layers}) {
    bool couldAddAllLayers = true;
    for (final LayerState layer in layers) {
      if (_layers.length >= maxLayers) {
        couldAddAllLayers = false;
        break;
      }
      else {
        _layers.add(layer);
      }
    }
    if (!couldAddAllLayers) {
      GetIt.I.get<AppState>().showMessage(text: "Could not add all layers.");
    }
    updateIndividualLayerSelection();
  }

  bool contains({required final LayerState layer}) {
    return _layers.contains(layer);
  }


  LayerState getLayer({required final int index}) {
    return _layers[index];
  }

  void clear({final bool notify = true}) {
    _layers.clear();
    _clearDependencies();
    _selectedLayerIndexNotifier.value = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _triggerNewLayerRender({required final LayerState layer}) {
    if (layer is RasterableLayerState &&
        !layer.isRasterizing &&
        !layer.doManualRaster)
    {
      if (areDependenciesComplete(layer: layer)) {
        layer.doManualRaster = true;
      }
    }
  }

  LayerState? addLayerWithData({required final LayerState layer, required final int position})
  {
    if (_layers.length >= maxLayers)
    {
      GetIt.I.get<AppState>().showMessage(text: "Could not add more layers.");
      return null;
    }
    else if (position < 0 || position > _layers.length)
    {
      GetIt.I.get<AppState>().showMessage(text: "Invalid layer insert index.");
      return null;
    }
    else
    {
      final LayerState? addLayer = _createDuplicateLayer(layerToDuplicate: layer);
      if (addLayer != null)
      {
        _layers.insert(position, addLayer);
        _rebuildDependencies();
        _triggerNewLayerRender(layer: addLayer);
        notifyListeners();
        return addLayer;
      }
      else
      {
        GetIt.I.get<AppState>().showMessage(text: "Could not add layer.");
        return null;
      }
    }
  }

  void addLinkLayer(
      {required final LayerState layer, required final int position,}) {
    if (_layers.length >= maxLayers) {
      GetIt.I.get<AppState>().showMessage(text: "Could not add more layers.");
    }
    else if (position < 0 || position > _layers.length) {
      GetIt.I.get<AppState>().showMessage(text: "Invalid layer insert index.");
    }
    else if (_layers.contains(layer)) {
      GetIt.I.get<AppState>().showMessage(
          text: "Layer already exists on that frame.",);
    }
    else {
      _layers.insert(position, layer);
      _rebuildDependencies();
      notifyListeners();
      reRasterAllDrawingLayers();
    }
  }


  ReferenceLayerState? addNewReferenceLayer({final bool select = false}) {
    final ReferenceLayerSettings refSettings = GetIt.I
        .get<PreferenceManager>()
        .referenceLayerSettings;
    final ReferenceLayerState newLayer = ReferenceLayerState(
        aspectRatio: refSettings.aspectRatioDefault,
        image: null,
        offsetX: 0,
        offsetY: 0,
        opacity: refSettings.opacityDefault,
        zoom: refSettings.zoomDefault,);
    if (_addNewLayer(newLayer: newLayer, select: select)) {
      return newLayer;
    }
    else {
      return null;
    }
  }

  ShadingLayerState? addNewShadingLayer({final bool select = false}) {
    final ShadingLayerState newLayer = ShadingLayerState();
    if (_addNewLayer(newLayer: newLayer, select: select)) {
      return newLayer;
    }
    else {
      return null;
    }
  }

  DitherLayerState? addNewDitherLayer({final bool select = false}) {
    final DitherLayerState newLayer = DitherLayerState();
    if (_addNewLayer(newLayer: newLayer, select: select)) {
      return newLayer;
    }
    else {
      return null;
    }
  }

  GridLayerState? addNewGridLayer({final bool select = false}) {
    final GridLayerSettings gridSettings = GetIt.I
        .get<PreferenceManager>()
        .gridLayerSettings;
    final GridLayerState newLayer = GridLayerState(
      brightness: gridSettings.brightnessDefault,
      gridType: gridSettings.gridTypeDefault,
      intervalX: gridSettings.intervalXDefault,
      intervalY: gridSettings.intervalYDefault,
      opacity: gridSettings.opacityDefault,
      horizonPosition: gridSettings.horizonDefault,
      vanishingPoint1: gridSettings.vanishingPoint1Default,
      vanishingPoint2: gridSettings.vanishingPoint2Default,
      vanishingPoint3: gridSettings.vanishingPoint3Default,
    );

    if (_addNewLayer(newLayer: newLayer, select: select)) {
      return newLayer;
    }
    else {
      return null;
    }
  }

  DrawingLayerState? addNewDrawingLayer(
      {final bool select = false, final CoordinateColorMapNullable? content, required final CoordinateSetI canvasSize, required final List<
          KPalRampData> ramps,}) {
    final DrawingLayerState newLayer = DrawingLayerState(
        size: canvasSize, content: content, ramps: ramps,);
    if (_addNewLayer(newLayer: newLayer, select: select)) {
      return newLayer;
    }
    else {
      return null;
    }
  }

  bool _addNewLayer(
      {required final LayerState newLayer, required final bool select,}) {
    if (_layers.length >= maxLayers) {
      GetIt.I.get<AppState>().showMessage(text: "Could not add more layers.");
      return false;
    }
    else {
      if (_layers.isEmpty || selectedLayerIndex == null) {
        _layers.add(newLayer);
        _selectedLayerIndexNotifier.value = 0;
      }
      else {
        _layers.insert(selectedLayerIndex!, newLayer);
        _selectedLayerIndexNotifier.value =
            _selectedLayerIndexNotifier.value! + 1;
      }
      if (select) {
        selectLayer(newLayer: newLayer);
      }
      _rebuildDependencies();
      notifyListeners();
      return true;
    }
  }

  //returns previous layer
  LayerState? selectLayer({required final LayerState newLayer}) {
    if (_layers.contains(newLayer)) {
      LayerState? previousLayer;
      if (selectedLayerIndex != null) {
        previousLayer = _layers[selectedLayerIndex!];
      }
      if (previousLayer != newLayer) {
        _selectedLayerIndexNotifier.value = _layers.indexOf(newLayer);
        notifyListeners();
      }

      return previousLayer ?? newLayer;
    }
    else {
      return null;
    }
  }

  int? getLayerPosition({required final LayerState state}) {
    final int sourcePosition = _layers.indexOf(state);
    return sourcePosition == -1 ? null : sourcePosition;
  }

  LayerState? getSelectedLayer() {
    if (selectedLayerIndex != null && selectedLayerIndex! >= 0 &&
        selectedLayerIndex! < _layers.length) {
      return _layers[selectedLayerIndex!];
    }
    else {
      return null;
    }
  }

  void selectLayerAbove() {
    if (selectedLayerIndex != null && selectedLayerIndex! > 0) {
      selectLayer(newLayer: _layers[selectedLayerIndex! - 1]);
      notifyListeners();
    }
  }

  void selectLayerBelow() {
    if (selectedLayerIndex != null &&
        selectedLayerIndex! < _layers.length - 1) {
      selectLayer(newLayer: _layers[selectedLayerIndex! + 1]);
      notifyListeners();
    }
  }

  bool deleteLayer({required final LayerState deleteLayer}) {
    if (_layers.length > 1) {
      final int? deleteLayerIndex = getLayerPosition(state: deleteLayer);
      if (deleteLayerIndex == 0) {
        _selectedLayerIndexNotifier.value = 1;
      }
      _layers.remove(deleteLayer);
      _selectedLayerIndexNotifier.value = 0;
      _rebuildDependencies();

      notifyListeners();
      return true;
    }
    else {
      return false;
    }
  }

  String? layerIsMergeable({required final LayerState mergeLayer}) {
    String? message;
    if (mergeLayer.runtimeType == DrawingLayerState) {
      final AppState appState = GetIt.I.get<AppState>();
      final DrawingLayerState drawingMergeLayer = mergeLayer as DrawingLayerState;
      final int mergeLayerIndex = _layers.indexOf(mergeLayer);
      if (mergeLayerIndex == _layers.length - 1) {
        message = "No layer below!";
      }
      else if (appState.timeline.isLayerLinked(layer: drawingMergeLayer)) {
        message = "Cannot merge a linked layer!";
      }
      else if (drawingMergeLayer.visibilityState.value ==
          LayerVisibilityState.hidden) {
        message = "Cannot merge from an invisible layer!";
      }
      else if (_layers[mergeLayerIndex + 1].visibilityState.value ==
          LayerVisibilityState.hidden) {
        message = "Cannot merge with an invisible layer!";
      }
      else if (drawingMergeLayer.lockState.value == LayerLockState.locked) {
        message = "Cannot merge from a locked layer!";
      }
      else if (_layers[mergeLayerIndex + 1].runtimeType == DrawingLayerState &&
          (_layers[mergeLayerIndex + 1] as DrawingLayerState).lockState.value ==
              LayerLockState.locked) {
        message = "Cannot merge with a locked layer!";
      }
      else if (_layers[mergeLayerIndex + 1].runtimeType != DrawingLayerState) {
        message = "Can only merge with drawing layers!";
      }
      else if (appState.timeline.isLayerLinked(
          layer: _layers[mergeLayerIndex + 1],)) {
        message = "Cannot merge with a linked layer!";
      }
      else if (drawingMergeLayer.layerSettings.hasActiveSettings() ||
          _layers[mergeLayerIndex + 1].runtimeType == DrawingLayerState &&
              (_layers[mergeLayerIndex + 1] as DrawingLayerState).layerSettings
                  .hasActiveSettings()) {
        message = "Cannot merge layers with active effects!";
      }
    }
    else {
      //SHOULD NEVER HAPPEN
      message = "Can only merge Drawing Layers!";
    }
    return message;
  }

  void mergeLayer(
      {required final LayerState mergeLayer, required final CoordinateSetI canvasSize,}) {
    if (layerIsMergeable(mergeLayer: mergeLayer) == null) {
      final DrawingLayerState drawingMergeLayer = mergeLayer as DrawingLayerState;
      final int mergeLayerIndex = _layers.indexOf(mergeLayer);
      final int intoLayerIndex = mergeLayerIndex + 1;
      final CoordinateColorMapNullable refs = HashMap<
          CoordinateSetI,
          ColorReference?>();

      final DrawingLayerState drawingIntoLayer = _layers[intoLayerIndex] as DrawingLayerState;
      for (int x = 0; x < canvasSize.x; x++) {
        for (int y = 0; y < canvasSize.y; y++) {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          //if transparent pixel -> use value from layer below
          if (drawingMergeLayer.getDataEntry(coord: curCoord) == null &&
              drawingIntoLayer.getDataEntry(coord: curCoord) != null) {
            refs[curCoord] = drawingIntoLayer.getDataEntry(coord: curCoord);
          }
        }
      }
      _layers.remove(drawingIntoLayer);
      drawingMergeLayer.setDataAll(list: refs);
      selectLayer(newLayer: drawingMergeLayer);
      notifyListeners();
    }
  }

  LayerState? _createDuplicateLayer(
      {required final LayerState layerToDuplicate,}) {
    if (layerToDuplicate.runtimeType == DrawingLayerState) {
      final DrawingLayerState drawingLayer = layerToDuplicate as DrawingLayerState;
      return DrawingLayerState.from(other: drawingLayer);
    }
    else if (layerToDuplicate.runtimeType == ReferenceLayerState) {
      final ReferenceLayerState referenceLayer = layerToDuplicate as ReferenceLayerState;
      return ReferenceLayerState.from(other: referenceLayer);
    }
    else if (layerToDuplicate.runtimeType == GridLayerState) {
      final GridLayerState gridLayer = layerToDuplicate as GridLayerState;
      return GridLayerState.from(other: gridLayer);
    }
    else if (layerToDuplicate.runtimeType == ShadingLayerState) {
      final ShadingLayerState shadingLayer = layerToDuplicate as ShadingLayerState;
      return ShadingLayerState.from(other: shadingLayer);
    }
    else if (layerToDuplicate.runtimeType == DitherLayerState) {
      final DitherLayerState ditherLayer = layerToDuplicate as DitherLayerState;
      return DitherLayerState.from(other: ditherLayer);
    }
    else {
      return null;
    }
  }

  LayerState? duplicateLayer(
      {required final LayerState duplicateLayer, final bool insertAtEnd = false,}) {
    if (_layers.length >= maxLayers) {
      GetIt.I.get<AppState>().showMessage(text: "Could not add more layers.");
      return null;
    }
    else {
      final LayerState? addLayer = _createDuplicateLayer(
          layerToDuplicate: duplicateLayer,);

      if (addLayer != null) {
        if (insertAtEnd) {
          _layers.add(addLayer);
        }
        else {
          final int? currentIndex = getLayerPosition(state: duplicateLayer);
          if (currentIndex != null) {
            _layers.insert(currentIndex, addLayer);
          }
        }
        notifyListeners();
      }
      return addLayer;
    }
  }

  bool changeLayerOrder(
      {required final LayerState state, required final int newPosition,}) {
    bool orderChanged = false;
    final int? sourcePosition = getLayerPosition(state: state);
    if (sourcePosition != null && sourcePosition != newPosition &&
        (sourcePosition + 1) != newPosition) {
      final bool movingSelectedLayer = selectedLayerIndex != null &&
          selectedLayerIndex == sourcePosition;
      _layers.removeAt(sourcePosition);
      if (newPosition > sourcePosition) {
        _layers.insert(newPosition - 1, state);
        if (movingSelectedLayer) {
          _selectedLayerIndexNotifier.value = newPosition - 1;
        }
      }
      else {
        _layers.insert(newPosition, state);
        if (movingSelectedLayer) {
          _selectedLayerIndexNotifier.value = newPosition;
        }
      }

      if (!movingSelectedLayer && newPosition <= selectedLayerIndex! &&
          sourcePosition > selectedLayerIndex!) {
        _selectedLayerIndexNotifier.value = selectedLayerIndex! + 1;
      }


      orderChanged = true;
    }
    notifyListeners();
    return orderChanged;
  }

  void rasterLayer(
      {required final LayerState rasterLayer, required final CoordinateSetI canvasSize, required final List<
          KPalRampData> ramps,}) {
    if (rasterLayer.runtimeType == GridLayerState) {
      final GridLayerState gridLayer = rasterLayer as GridLayerState;
      gridLayer.getHashMap().then((final CoordinateColorMap data) {
        _replaceCurrentLayerWithDrawingLayer(data: data,
            originalLayer: rasterLayer,
            canvasSize: canvasSize,
            ramps: ramps,);
      });
    }
    else if (rasterLayer is ShadingLayerState) {
      _rasterShadingLayer(shadingLayer: rasterLayer).then((final void _) {
        _shadingLayerRastered(shadingLayer: rasterLayer);
      },);
    }
  }

  void _shadingLayerRastered({required final ShadingLayerState shadingLayer}) {
    deleteLayer(deleteLayer: shadingLayer);
    notifyListeners();
  }

  Future<void> _rasterShadingLayer(
      {required final ShadingLayerState shadingLayer,}) async
  {
    final int? layerIndex = getLayerPosition(state: shadingLayer);
    if (layerIndex != null && layerIndex >= 0 && layerIndex < _layers.length) {
      final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];
      final HashMap<DrawingLayerState,
          CoordinateColorMapNullable> shadeLayerMap = HashMap<
          DrawingLayerState,
          CoordinateColorMapNullable>();

      //getting all relevant drawing layers
      for (int i = layerIndex; i < _layers.length; i++) {
        if (_layers[i].runtimeType == DrawingLayerState &&
            _layers[i].visibilityState.value == LayerVisibilityState.visible) {
          final DrawingLayerState drawingLayer = _layers[i] as DrawingLayerState;
          drawingLayers.add(drawingLayer);
          shadeLayerMap[drawingLayer] =
              HashMap<CoordinateSetI, ColorReference?>();
        }
      }

      //finding and sorting pixels that need to be shaded
      for (final MapEntry<CoordinateSetI, int> entry in shadingLayer.shadingData
          .entries) {
        for (final DrawingLayerState drawingLayer in drawingLayers) {
          final ColorReference? curCol = drawingLayer.getDataEntry(
              coord: entry.key, withSettingsPixels: true,);
          if (curCol != null) {
            if (shadingLayer.runtimeType == ShadingLayerState) {
              final int targetIndex = (curCol.colorIndex + entry.value).clamp(
                  0, curCol.ramp.references.length - 1,);
              shadeLayerMap[drawingLayer]![entry.key] =
              curCol.ramp.references[targetIndex];
              break;
            }
            else {
              final int ditherVal = shadingLayer.getDisplayValueAt(
                  coord: entry.key,) ?? 0;
              if (ditherVal != 0) {
                final int newColorIndex = (curCol.colorIndex + ditherVal).clamp(
                    0, curCol.ramp.references.length - 1,);
                shadeLayerMap[drawingLayer]![entry.key] =
                curCol.ramp.references[newColorIndex];
                break;
              }
            }
          }
        }
      }

      //applying shading
      for (final MapEntry<DrawingLayerState,
          CoordinateColorMapNullable> entry in shadeLayerMap.entries) {
        if (entry.value.isNotEmpty) {
          entry.key.setDataAll(list: entry.value);
        }
      }
    }
  }

  void _replaceCurrentLayerWithDrawingLayer(
      {required final CoordinateColorMap data, required final LayerState originalLayer, required final CoordinateSetI canvasSize, required final List<
          KPalRampData> ramps,}) {
    final DrawingLayerState drawingLayer = DrawingLayerState(
        size: canvasSize, content: data, ramps: ramps,);
    final int? insertIndex = getLayerPosition(state: originalLayer);
    if (insertIndex != null) {
      _layers.remove(originalLayer);
      _layers.insert(insertIndex, drawingLayer);
      drawingLayer.visibilityState.value = originalLayer.visibilityState.value;
      notifyListeners();
    }
  }

  int getFrameIndex() {
    int index = -1;
    final AppState appState = GetIt.I.get<AppState>();
    for (int i = 0; i < appState.timeline.frames.value.length; i++) {
      if (appState.timeline.frames.value[i].layerList == this) {
        index = i;
        break;
      }
    }

    return index;
  }

  void reRasterAllDrawingLayers() {
    for (int i = _layers.length - 1; i >= 0; i--) {
      final LayerState layer = _layers[i];
      if (layer is RasterableLayerState && !layer.isRasterizing) {
        final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
        if (deps.isEmpty) {
          layer.doManualRaster = true;
        }
      }
    }
  }

  void layerRasterDone({required final LayerState layer}) {
    if (layer is! RasterableLayerState) return;

    final Set<RasterableLayerState> dependents = _getDependents(layer: layer);
    for (final RasterableLayerState dependent in dependents) {
      if (areDependenciesComplete(layer: dependent) &&
          !dependent.doManualRaster) {
        dependent.doManualRaster = true;
      }
    }

    bool anyLayerStillPending = false;
    for (final LayerState l in _layers) {
      if (l is RasterableLayerState) {
        if (l.isRasterizing || l.doManualRaster) {
          anyLayerStillPending = true;
          break;
        }
      }
    }

    if (!anyLayerStillPending) {
      final AppState appState = GetIt.I.get<AppState>();
      final Frame? frame = appState.timeline.findFrameForCollection(
          collection: this,);
      getImageFromLayers(
          layerCollection: this,
          canvasSize: appState.canvasSize,
          selection: appState.selectionState.selection,
          frame: frame,
      ).then((final ui.Image img) {
        _rasterImage = img;
      });
    }
  }

  void onLayerVisibilityChanged({required final LayerState layer}) {
    _rebuildDependencies();
    if (layer is RasterableLayerState)
    {
      if (!layer.isRasterizing && layer.visibilityState.value == LayerVisibilityState.visible)
      {
        layer.doManualRaster = true;
      }
      invalidateDependents(layer: layer);
    }
    notifyListeners();
  }

  void remapLayers({required final KPalRampData newData, required final HashMap<
      int,
      int> map,}) {
    for (final LayerState layer in _layers) {
      if (layer.runtimeType == DrawingLayerState) {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.remapSingleRamp(newData: newData, map: map);
        drawingLayer.remapSingleRampLayerEffects(newData: newData, map: map);
      }
    }
  }

  void transformLayers(
      {required final CanvasTransformation transformation, required final CoordinateSetI oldSize,}) {
    for (final LayerState layer in _layers) {
      if (layer.runtimeType == DrawingLayerState) {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.transformLayer(
            transformation: transformation, oldSize: oldSize,);
      }
    }
    notifyListeners();
  }

  void deleteRampFromLayers(
      {required final KPalRampData ramp, required final ColorReference backupColor,}) {
    for (final LayerState layer in _layers) {
      if (layer.runtimeType == DrawingLayerState) {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.deleteRamp(ramp: ramp);
        drawingLayer.deleteRampFromLayerEffects(
            ramp: ramp, backupColor: backupColor,);
      }
    }
  }

  Iterable<LayerState> getVisibleLayers() {
    return _layers.where((final LayerState x) =>
    x.visibilityState.value == LayerVisibilityState.visible,);
  }

  Iterable<RasterableLayerState> getVisibleRasterLayers() {
    final List<RasterableLayerState> rLayers = <RasterableLayerState>[];
    for (final LayerState layer in _layers) {
      if (layer.visibilityState.value == LayerVisibilityState.visible &&
          layer is RasterableLayerState) {
        rLayers.add(layer);
      }
    }

    return rLayers;
  }

  List<LayerState> getAllLayers() {
    return _layers;
  }

  ColorReference? getColorFromImageAtPosition(
      {required final CoordinateSetI normPos, required final ColorReference? selectionReference, required final bool rawMode,}) {
    ColorReference? colRef;
    int shading = 0;
    for (final LayerState layer in _layers) {
      if (!rawMode &&
          layer.visibilityState.value == LayerVisibilityState.visible &&
          layer is ShadingLayerState) {
        final int valueAtCoord = layer.getDisplayValueAt(coord: normPos) ?? 0;
        shading += valueAtCoord;
      }
      else if (layer.visibilityState.value == LayerVisibilityState.visible &&
          layer.runtimeType == DrawingLayerState) {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        if (selectedLayerIndex != null &&
            _layers[selectedLayerIndex!] == drawingLayer &&
            selectionReference != null) {
          colRef = selectionReference;
          if (!rawMode &&
              drawingLayer.getSettingsPixel(coord: normPos) != null) {
            colRef = drawingLayer.getSettingsPixel(coord: normPos);
          }
          break;
        }
        else {
          final ColorReference? coordAtPos = drawingLayer.getDataEntry(
              coord: normPos, withSettingsPixels: !rawMode,);
          if (coordAtPos != null) {
            colRef = coordAtPos;
            break;
          }
        }
      }
    }
    if (shading != 0 && colRef != null) {
      colRef = colRef.ramp.references[ (colRef.colorIndex + shading).clamp(
          0, colRef.ramp.references.length - 1,)];
    }

    return colRef;
  }

  Set<RasterableLayerState> _getDependencies(
      {required final RasterableLayerState layer,}) {
    return _layerDependencies[layer] ?? <RasterableLayerState>{};
  }

  Set<RasterableLayerState> _getDependents(
      {required final RasterableLayerState layer,}) {
    return _layerDependents[layer] ?? <RasterableLayerState>{};
  }

  void _addDependency(
      {required final RasterableLayerState dependent, required final RasterableLayerState dependency,}) {
    _layerDependencies
        .putIfAbsent(dependent, () => <RasterableLayerState>{})
        .add(dependency);
    _layerDependents
        .putIfAbsent(dependency, () => <RasterableLayerState>{})
        .add(dependent);
  }

  bool areDependenciesComplete({required final RasterableLayerState layer}) {
    final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
    for (final RasterableLayerState dep in deps) {
      if (dep.isRasterizing || dep.doManualRaster) {
        return false;
      }
    }
    return true;
  }

  void invalidateDependents({required final RasterableLayerState layer}) {
    final Set<RasterableLayerState> dependents = _getDependents(layer: layer);

    for (final RasterableLayerState dependent in dependents) {
      if (_layersCurrentlyRendering.contains(dependent)) {
        continue;
      }

      if (dependent.isRasterizing) {
        continue;
      }

      if (!dependent.doManualRaster) {
        final DateTime now = DateTime.now();
        final DateTime? lastTime = _lastInvalidationTime[dependent];

        if (lastTime != null && now.difference(lastTime).inMilliseconds < 100) {
          _recentInvalidations[dependent] = (_recentInvalidations[dependent] ?? 0) + 1;

          if (_recentInvalidations[dependent]! > 10) {
            debugPrint('WARNING: Breaking invalidation loop for ${dependent.runtimeType} at index ${_layers.indexOf(dependent)}');
            _recentInvalidations[dependent] = 0;
            dependent.doManualRaster = true;
            return;
          }
        } else {
          _recentInvalidations[dependent] = 1;
        }

        _lastInvalidationTime[dependent] = now;

        dependent.doManualRaster = true;
        invalidateDependents(layer: dependent);
      }
    }
  }

  void _clearDependencies() {
    _layerDependencies.clear();
    _layerDependents.clear();
    _layersCurrentlyRendering.clear();
    _recentInvalidations.clear();
    _lastInvalidationTime.clear();
  }

  void _rebuildDependencies() {
    _clearDependencies();

    for (int i = 0; i < _layers.length; i++) {
      final LayerState layer = _layers[i];

      if (layer is ShadingLayerState || layer is DitherLayerState) {
        for (int j = i + 1; j < _layers.length; j++) {
          if (_layers[j] is RasterableLayerState) {
            _addDependency(
                dependent: layer as RasterableLayerState,
                dependency: _layers[j] as RasterableLayerState,
            );
          }
        }
      }
    }
  }

  void invalidateLayerInAllFrames({required final RasterableLayerState layer}) {
    layer.doManualRaster = true;
    invalidateDependents(layer: layer);
    final AppState appState = GetIt.I.get<AppState>();
    final List<Frame> framesWithThisLayer = appState.timeline
        .findFramesForLayer(layer: layer);

    for (final Frame frame in framesWithThisLayer) {
      if (frame.layerList != this) {
        frame.layerList.invalidateDependents(layer: layer);
      }
    }
  }

  void lockLayerForRendering({required final RasterableLayerState layer}) {
    _layersCurrentlyRendering.add(layer);
  }

  void unlockLayerFromRendering({required final RasterableLayerState layer}) {
    _layersCurrentlyRendering.remove(layer);
  }

  void lockLayerAndDependenciesForRendering({required final RasterableLayerState layer}) {
    lockLayerForRendering(layer: layer);

    final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
    for (final RasterableLayerState dep in deps) {
      lockLayerForRendering(layer: dep);
    }
  }

  void unlockLayerAndDependenciesFromRendering({required final RasterableLayerState layer}) {
    unlockLayerFromRendering(layer: layer);

    final Set<RasterableLayerState> deps = _getDependencies(layer: layer);
    for (final RasterableLayerState dep in deps) {
      unlockLayerFromRendering(layer: dep);
    }
  }
}
