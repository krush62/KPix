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
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';

class LayerCollection with ChangeNotifier
{
  final List<LayerState> _layers = <LayerState>[];
  final ValueNotifier<LayerState?> _currentLayer = ValueNotifier<LayerState?>(null);
  final ValueNotifier<bool> settingsVisible = ValueNotifier<bool>(false);
  LayerState? get currentLayer
  {
    return _currentLayer.value;
  }
  ValueNotifier<LayerState?> get currentLayerNotifier
  {
    return _currentLayer;
  }

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

  LayerState getLayer({required final int index})
  {
    return _layers[index];
  }

  void clear({final bool notify = true})
  {
    _layers.clear();
    _currentLayer.value = null;
    if (notify)
    {
      notifyListeners();
    }
  }

  void replaceLayers({required final List<LayerState> layers, final LayerState? selectedLayer})
  {
    clear(notify: false);
    for (final LayerState layer in layers)
    {
      _layers.add(layer);
    }
    if (_layers.isNotEmpty)
    {
      if (selectedLayer != null && _layers.contains(selectedLayer))
      {
        selectLayer(newLayer: selectedLayer);
      }
      else
      {
        selectLayer(newLayer: _layers.first);
      }
    }
    notifyListeners();
  }


  ReferenceLayerState addNewReferenceLayer({final bool select = false})
  {
    final ReferenceLayerSettings refSettings = GetIt.I.get<PreferenceManager>().referenceLayerSettings;
    final ReferenceLayerState newLayer = ReferenceLayerState(aspectRatio: refSettings.aspectRatioDefault, image: null, offsetX: 0, offsetY: 0, opacity: refSettings.opacityDefault, zoom: refSettings.zoomDefault);
    if (_layers.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      _layers.add(newLayer);
    }
    else
    {
      _layers.insert(getSelectedLayerIndex(), newLayer);
    }

    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    notifyListeners();
    return newLayer;
  }

  ShadingLayerState addNewShadingLayer({final bool select = false})
  {
    final ShadingLayerState newLayer = ShadingLayerState();
    final List<LayerState> layerList = <LayerState>[];
    if (_layers.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      layerList.add(newLayer);
    }
    else
    {
      _layers.insert(getSelectedLayerIndex(), newLayer);
    }
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    notifyListeners();
    return newLayer;
  }

  GridLayerState addNewGridLayer({final bool select = false})
  {
    final GridLayerSettings gridSettings = GetIt.I.get<PreferenceManager>().gridLayerSettings;
    final List<LayerState> layerList = <LayerState>[];
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
    if (_layers.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      layerList.add(newLayer);
    }
    else
    {
      _layers.insert(getSelectedLayerIndex(), newLayer);
    }
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    notifyListeners();
    return newLayer;
  }

  DrawingLayerState addNewDrawingLayer({final bool select = false, final CoordinateColorMapNullable? content, required final CoordinateSetI canvasSize})
  {
    final DrawingLayerState newLayer = DrawingLayerState(size: canvasSize, content: content);
    if (_layers.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      _layers.add(newLayer);
    }
    else
    {
      final int currentLayerIndex = getSelectedLayerIndex();
      _layers.insert(currentLayerIndex, newLayer);
    }
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    notifyListeners();
    return newLayer;
  }

  //returns previous layer
  LayerState selectLayer({required final LayerState newLayer})
  {
    final LayerState? oldLayer = getSelectedLayer();
    if (_currentLayer.value != newLayer || !newLayer.isSelected.value)
    {
      newLayer.isSelected.value = true;
      if (oldLayer != newLayer)
      {
        oldLayer?.isSelected.value = false;
      }
      _currentLayer.value = newLayer;
    }
    notifyListeners();
    return oldLayer?? newLayer;
  }

  int getLayerPosition({required final LayerState state})
  {
    int sourcePosition = -1;
    for (int i = 0; i < _layers.length; i++)
    {
      if (_layers[i] == state)
      {
        sourcePosition = i;
        break;
      }
    }
    return sourcePosition;
  }

  LayerState? getSelectedLayer()
  {
    for (final LayerState state in _layers)
    {
      if (state.isSelected.value)
      {
        return state;
      }
    }
    return null;
  }


  int getSelectedLayerIndex()
  {
    if (currentLayer != null)
    {
      return _layers.indexOf(currentLayer!);
    }
    else
    {
      return -1;
    }
  }

  void selectLayerAbove()
  {
    final int index = getLayerPosition(state: currentLayer!);
    if (index > 0)
    {
      selectLayer(newLayer: _layers[index - 1]);
    }
    notifyListeners();
  }

  void selectLayerBelow()
  {
    final int index = getLayerPosition(state: currentLayer!);
    if (index < _layers.length - 1)
    {
      selectLayer(newLayer: _layers[index + 1]);
    }
    notifyListeners();
  }

  bool deleteLayer({required final LayerState deleteLayer})
  {
    if (_layers.length > 1)
    {
      _layers.remove(deleteLayer);
      final int deleteLayerIndex = getLayerPosition(state: deleteLayer);
      if (deleteLayerIndex > 0)
      {
        selectLayer(newLayer: _layers[deleteLayerIndex - 1]);
      }
      else
      {
        selectLayer(newLayer: _layers.first);
      }
      notifyListeners();
      return true;
    }
    else
    {
      return false;
    }
  }

  String? layerIsMergeable({required final LayerState mergeLayer})
  {
    String? message;
    if (mergeLayer.runtimeType == DrawingLayerState) {
      final DrawingLayerState drawingMergeLayer = mergeLayer as DrawingLayerState;
      final int mergeLayerIndex = _layers.indexOf(mergeLayer);
      if (mergeLayerIndex == _layers.length - 1)
      {
        message = "No layer below!";
      }
      else if (drawingMergeLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        message = "Cannot merge from an invisible layer!";
      }
      else if (_layers[mergeLayerIndex + 1].visibilityState.value == LayerVisibilityState.hidden)
      {
        message = "Cannot merge with an invisible layer!";
      }
      else if (drawingMergeLayer.lockState.value == LayerLockState.locked)
      {
        message = "Cannot merge from a locked layer!";
      }
      else if (_layers[mergeLayerIndex + 1].runtimeType == DrawingLayerState && (_layers[mergeLayerIndex + 1] as DrawingLayerState).lockState.value == LayerLockState.locked)
      {
        message = "Cannot merge with a locked layer!";
      }
      else if (_layers[mergeLayerIndex + 1].runtimeType != DrawingLayerState) {
        message = "Can only merge with drawing layers!";
      }
    }
    else
    {
      message = "Can only merge Drawing Layers!";
    }
    return message;
  }

  void mergeLayer({required final LayerState mergeLayer, required final CoordinateSetI canvasSize})
  {
    if (layerIsMergeable(mergeLayer: mergeLayer) == null)
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
          //if transparent pixel -> use value from layer below
          if (drawingMergeLayer.getDataEntry(coord: curCoord) == null && drawingIntoLayer.getDataEntry(coord: curCoord) != null)
          {
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

  void duplicateLayer({required final LayerState duplicateLayer})
  {
    LayerState? addLayer;
    if (duplicateLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = duplicateLayer as DrawingLayerState;
      addLayer = DrawingLayerState.from(other: drawingLayer);
    }
    else if (duplicateLayer.runtimeType == ReferenceLayerState)
    {
      final ReferenceLayerState referenceLayer = duplicateLayer as ReferenceLayerState;
      addLayer = ReferenceLayerState.from(other: referenceLayer);
    }
    else if (duplicateLayer.runtimeType == GridLayerState)
    {
      final GridLayerState gridLayer = duplicateLayer as GridLayerState;
      addLayer = GridLayerState.from(other: gridLayer);
    }
    else if (duplicateLayer.runtimeType == ShadingLayerState)
    {
      final ShadingLayerState shadingLayer = duplicateLayer as ShadingLayerState;
      addLayer = ShadingLayerState.from(other: shadingLayer);
    }

    if (addLayer != null)
    {
      final int currentIndex = getLayerPosition(state: duplicateLayer);
      _layers.insert(currentIndex, addLayer);
      notifyListeners();
    }
  }

  void replacePalette({required final LoadPaletteSet loadPaletteSet, required final PaletteReplaceBehavior paletteReplaceBehavior, required final List<KPalRampData> colorRamps})
  {
    if (paletteReplaceBehavior == PaletteReplaceBehavior.replace)
    {
      _deleteAllRampsFromLayers(colorRamps: colorRamps);
    }
    else
    {
      final HashMap<ColorReference, ColorReference> rampMap = getRampMap(rampList1: colorRamps, rampList2: loadPaletteSet.rampData!);
      for (final LayerState layer in _layers)
      {
        if (layer.runtimeType == DrawingLayerState)
        {
          final DrawingLayerState drawingLayer = layer as DrawingLayerState;
          drawingLayer.remapAllColors(rampMap: rampMap);
          drawingLayer.doManualRaster = true;
        }
      }
    }
    //notifyListeners();
  }

  void _deleteAllRampsFromLayers({required final List<KPalRampData> colorRamps})
  {
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        for (final KPalRampData kPalRampData in colorRamps)
        {
          drawingLayer.deleteRamp(ramp: kPalRampData);
        }
        drawingLayer.doManualRaster = true;
      }
    }
  }

  void changeLayerOrder({required final LayerState state, required final int newPosition})
  {
    final int sourcePosition = getLayerPosition(state: state);
    if (sourcePosition != newPosition && (sourcePosition + 1) != newPosition)
    {
      _layers.removeAt(sourcePosition);
      if (newPosition > sourcePosition)
      {
        _layers.insert(newPosition - 1, state);
      }
      else
      {
        _layers.insert(newPosition, state);
      }
    }
    notifyListeners();
  }

  void rasterLayer({required final LayerState rasterLayer, required final CoordinateSetI canvasSize})
  {
    if (rasterLayer.runtimeType == GridLayerState)
    {
      final GridLayerState gridLayer = rasterLayer as GridLayerState;
      gridLayer.getHashMap().then((final CoordinateColorMap data) {
        _replaceCurrentLayerWithDrawingLayer(data: data, originalLayer: rasterLayer, canvasSize: canvasSize);
      });
    }
    else if (rasterLayer.runtimeType == ShadingLayerState)
    {
      final ShadingLayerState shadingLayer = rasterLayer as ShadingLayerState;
      _rasterShadingLayer(shadingLayer: shadingLayer).then((final void _) {
        _shadingLayerRastered(shadingLayer: shadingLayer);
      },);
    }
  }

  void _shadingLayerRastered({required final ShadingLayerState shadingLayer})
  {
    deleteLayer(deleteLayer: shadingLayer);
    notifyListeners();
  }

  Future<void> _rasterShadingLayer({required final ShadingLayerState shadingLayer}) async
  {
    final int layerIndex = getLayerPosition(state: shadingLayer);
    assert(layerIndex >= 0 && layerIndex < _layers.length);
    final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];
    final HashMap<DrawingLayerState, CoordinateColorMapNullable> shadeLayerMap = HashMap<DrawingLayerState, CoordinateColorMapNullable>();

    //getting all relevant drawing layers
    for (int i = layerIndex; i < _layers.length; i++)
    {
      if (_layers[i].runtimeType == DrawingLayerState && _layers[i].visibilityState.value == LayerVisibilityState.visible)
      {
        final DrawingLayerState drawingLayer = _layers[i] as DrawingLayerState;
        drawingLayers.add(drawingLayer);
        shadeLayerMap[drawingLayer] = HashMap<CoordinateSetI, ColorReference?>();
      }
    }

    //finding and sorting pixels that need to be shaded
    for (final MapEntry<CoordinateSetI, int> entry in shadingLayer.shadingData.entries)
    {
      for (final DrawingLayerState drawingLayer in drawingLayers)
      {
        final ColorReference? curCol = drawingLayer.getDataEntry(coord: entry.key, withSettingsPixels: true);
        if (curCol != null)
        {
          final int targetIndex = (curCol.colorIndex + entry.value).clamp(0, curCol.ramp.references.length - 1);
          shadeLayerMap[drawingLayer]![entry.key] = curCol.ramp.references[targetIndex];
          break;
        }
      }
    }

    //applying shading
    for (final MapEntry<DrawingLayerState, CoordinateColorMapNullable> entry in shadeLayerMap.entries)
    {
      if (entry.value.isNotEmpty)
      {
        entry.key.setDataAll(list: entry.value);
      }
    }
  }

  void _replaceCurrentLayerWithDrawingLayer({required final CoordinateColorMap data, required final LayerState originalLayer, required final CoordinateSetI canvasSize})
  {
    final DrawingLayerState drawingLayer = DrawingLayerState(size: canvasSize, content: data);
    final int insertIndex = getLayerPosition(state: originalLayer);
    _layers.remove(originalLayer);
    _layers.insert(insertIndex, drawingLayer);
    if (originalLayer.isSelected.value)
    {
      selectLayer(newLayer: drawingLayer);
    }
    drawingLayer.visibilityState.value = originalLayer.visibilityState.value;
    notifyListeners();
  }

  void rasterDrawingLayersBelow({required final LayerState layer})
  {
    //shade all layers below
    final int currentLayerindex = getLayerPosition(state: layer);
    for (int i = _layers.length - 1; i > currentLayerindex; i--)
    {
      if (_layers[i].runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = _layers[i] as DrawingLayerState;
        drawingLayer.doManualRaster = true;
      }
    }
  }

  void reRasterDrawingLayers()
  {
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.doManualRaster = true;
      }
    }
  }

  void remapLayers({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.remapSingleRamp(newData: newData, map: map);
      }
    }
  }

  DrawingLayerState? transformLayers({required final CanvasTransformation transformation})
  {
    DrawingLayerState? currentTransformLayer;
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer = drawingLayer.getTransformedLayer(transformation: transformation);

        if (layer == currentLayer)
        {
          currentTransformLayer = drawingLayer;
          currentTransformLayer.isSelected.value = true;
        }
      }
    }
    _currentLayer.value = currentTransformLayer;
    notifyListeners();
    return currentTransformLayer;
  }

  void changeLayerSizes({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == ShadingLayerState)
      {
        final ShadingLayerState shadingLayerState = layer as ShadingLayerState;
        shadingLayerState.resizeLayer(newSize: newSize, offset: offset);
        shadingLayerState.manualRender();
      }
      else if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.resizeLayer(newSize: newSize, offset: offset);
        drawingLayer.doManualRaster = true;
      }
      else if (layer.runtimeType == GridLayerState)
      {
        final GridLayerState gridLayer = layer as GridLayerState;
        gridLayer.manualRender();
      }
    }
  }

  void deleteRampFromLayers({required final KPalRampData ramp})
  {
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.deleteRamp(ramp: ramp);
      }

    }
  }

  Iterable<LayerState> getVisibleLayers()
  {
     return _layers.where((final LayerState x) => x.visibilityState.value == LayerVisibilityState.visible);
  }

  Iterable<LayerState> getVisibleDrawingAndShadingLayers()
  {
    return _layers.where((final LayerState l) => l.visibilityState.value == LayerVisibilityState.visible && (l.runtimeType == DrawingLayerState || l.runtimeType == ShadingLayerState));
  }

  List<LayerState> getAllLayers()
  {
    return _layers;
  }

  ColorReference? getColorFromImageAtPosition({required final CoordinateSetI normPos, required final ColorReference? selectionReference, required final bool rawMode})
  {
    ColorReference? colRef;
    int shading = 0;
    for (final LayerState layer in _layers)
    {
      if (!rawMode && layer.visibilityState.value == LayerVisibilityState.visible && layer.runtimeType == ShadingLayerState)
      {
        final ShadingLayerState shadingLayer = layer as ShadingLayerState;
        final int valueAtCoord = shadingLayer.getValueAt(coord: normPos) ?? 0;
        shading += valueAtCoord;
      }
      else if (layer.visibilityState.value == LayerVisibilityState.visible && layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        if (currentLayer == drawingLayer && selectionReference != null)
        {
          colRef = selectionReference;
          if (!rawMode && drawingLayer.getSettingsPixel(coord: normPos) != null)
          {
            colRef = drawingLayer.getSettingsPixel(coord: normPos);
          }
          break;
        }
        else
        {
          final ColorReference? coordAtPos = drawingLayer.getDataEntry(coord: normPos, withSettingsPixels: !rawMode);
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
      colRef = colRef.ramp.references[ (colRef.colorIndex + shading).clamp(0, colRef.ramp.references.length - 1)];
    }

    return colRef;
  }

}
