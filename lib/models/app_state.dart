import 'dart:collection';
import 'dart:math';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:uuid/uuid.dart';


class RepaintNotifier extends ChangeNotifier
{
  void repaint()
  {
    notifyListeners();
  }
}

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  late IToolOptions currentToolOptions;
  final ValueNotifier<List<KPalRampData>> colorRamps = ValueNotifier([]);
  final ValueNotifier<ColorReference?> selectedColor = ValueNotifier(null);
  final Map<ToolType, bool> _selectionMap = {};
  final ValueNotifier<List<LayerState>> layers = ValueNotifier([]);
  final ValueNotifier<LayerState?> currentLayer = ValueNotifier(null);
  final RepaintNotifier repaintNotifier = RepaintNotifier();
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();

  final ValueNotifier<int> zoomFactor = ValueNotifier(1);
  static const int zoomLevelMin = 1;
  static const int zoomLevelMax = 80;

  int canvasWidth = 0;
  int canvasHeight = 0;
  late SelectionState selectionState = SelectionState(repaintNotifier: repaintNotifier);
  final StatusBarState statusBarState = StatusBarState();

  AppState()
  {

    for (ToolType toolType in toolList.keys)
    {
      _selectionMap[toolType] = false;
    }
    setToolSelection(ToolType.pencil);
    statusBarState.setStatusBarZoomFactor(zoomFactor.value * 100);
    currentLayer.addListener(() {
      selectionState.selection.setCurrentLayer(currentLayer.value);
    });
  }

  void setCanvasDimensions({required int width, required int height})
  {
    canvasWidth = width;
    canvasHeight = height;
    statusBarState.setStatusBarDimensions(width, height);
  }

  bool increaseZoomLevel()
  {
    bool changed = false;
    if (zoomFactor.value < zoomLevelMax)
    {
      zoomFactor.value = zoomFactor.value + 1;
      statusBarState.setStatusBarZoomFactor(zoomFactor.value * 100);
      changed = true;
    }
    return changed;
  }

  bool decreaseZoomLevel()
  {
    bool changed = false;
    if (zoomFactor.value > zoomLevelMin)
    {
      zoomFactor.value = zoomFactor.value - 1;
      statusBarState.setStatusBarZoomFactor(zoomFactor.value * 100);
      changed = true;
    }
    return changed;
  }

  bool setZoomLevelByDistance(final int startZoomLevel, final int steps)
  {
    bool change = false;
    if (steps != 0)
    {
      final int endIndex = startZoomLevel + steps;
      if (endIndex <= zoomLevelMax && endIndex >= zoomLevelMin && endIndex != zoomFactor.value)
      {
         zoomFactor.value = endIndex;
         statusBarState.setStatusBarZoomFactor(zoomFactor.value * 100);
         change = true;
      }
    }
    return change;
  }

  bool setZoomLevel(final int val)
  {
    bool change = false;
    if (val <= zoomLevelMax && val >= zoomLevelMin && val != zoomFactor.value)
    {
      zoomFactor.value = val;
      statusBarState.setStatusBarZoomFactor(zoomFactor.value * 100);
      change = true;
    }
    return change;
  }


  int getCurrentToolSize()
  {
    return currentToolOptions.getSize();
  }

  void setToolSize(final int steps, final int originalValue)
  {
    currentToolOptions.changeSize(steps, originalValue);
  }

  void deleteRamp(final KPalRampData ramp)
  {
    if (colorRamps.value.length > 1)
    {
      List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
      rampDataList.remove(ramp);
      selectedColor.value = rampDataList[0].references[0];
      colorRamps.value = rampDataList;
      _deleteRampFromLayers(ramp: ramp);
      _reRaster();
      repaintNotifier.repaint();
    }
    else
    {
      showMessage("Cannot delete the only color ramp!");
    }
  }

  void updateRamp(final KPalRampData ramp, final KPalRampData originalData)
  {
    final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    colorRamps.value = rampDataList;

    if (ramp.colors.length != originalData.colors.length)
    {
      HashMap<int, int> indexMap = _remapIndices(originalData.colors.length, ramp.colors.length);
      selectedColor.value = ramp.references[indexMap[selectedColor.value!.colorIndex]!];
      _remapLayers(newData: ramp, map: indexMap);
    }
    _reRaster();
    repaintNotifier.repaint();
  }

  void addNewRamp()
  {
    const Uuid uuid = Uuid();
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    final KPalRampData newRamp = KPalRampData(
        uuid: uuid.v1(),
        settings: KPalRampSettings(
            constraints: prefs.kPalConstraints
        )
    );
    rampDataList.add(newRamp);
    colorRamps.value = rampDataList;
    selectedColor.value = newRamp.references[0];
  }

  LayerState addNewLayer({bool select = false, HashMap<CoordinateSetI, ColorReference?>? content})
  {
    List<LayerState> layerList = [];
    LayerState newLayer = LayerState(width: canvasWidth, height: canvasHeight, content: content);
    if (layers.value.isEmpty)
    {
      newLayer.isSelected.value = true;
      currentLayer.value = newLayer;
    }
    layerList.add(newLayer);
    layerList.addAll(layers.value);
    layers.value = layerList;
    if (select)
    {
      layerSelected(newLayer);
    }
    return newLayer;
  }

  void changeLayerOrder(final LayerState state, final int newPosition)
  {
    int sourcePosition = -1;
    for (int i = 0; i < layers.value.length; i++)
    {
       if (layers.value[i] == state)
       {
          sourcePosition = i;
          break;
       }
    }

    if (sourcePosition != newPosition && (sourcePosition + 1) != newPosition)
    {
      List<LayerState> stateList = List<LayerState>.from(layers.value);
      stateList.removeAt(sourcePosition);
      if (newPosition > sourcePosition) {
        stateList.insert(newPosition - 1, state);
      }
      else
        {
          stateList.insert(newPosition, state);
        }
      layers.value = stateList;
    }
  }

  void addNewLayerPressed()
  {
    addNewLayer();
  }

  LayerState? getSelectedLayer()
  {
    LayerState? selectedLayer;
    for (final LayerState state in layers.value)
    {
      if (state.isSelected.value)
      {
        selectedLayer = state;
      }
    }
    return selectedLayer;
  }

  void layerSelected(final LayerState newLayer)
  {
    LayerState oldLayer = newLayer;
    for (final LayerState layer in layers.value)
    {
      if (layer.isSelected.value)
      {
        oldLayer = layer;
        break;
      }
    }
    if (oldLayer != newLayer)
    {
      newLayer.isSelected.value = true;
      oldLayer.isSelected.value = false;
      currentLayer.value = newLayer;
      selectionState.selection.changeLayer(oldLayer, newLayer);
    }

  }

  void layerDeleted(final LayerState deleteLayer)
  {
    if (layers.value.length > 1)
    {
      final List<LayerState> layerList = [];
      int foundIndex = 0;
      for (int i = 0; i < layers.value.length; i++)
      {
        if (layers.value[i] != deleteLayer)
        {
          layerList.add(layers.value[i]);
        }
        else
        {
          foundIndex = i;
        }
      }

      if (foundIndex > 0)
      {
        layerSelected(layerList[foundIndex - 1]);
      }
      else
      {
        layerSelected(layerList[0]);
      }

      layers.value = layerList;
    }
    else
    {
      showMessage("Cannot delete the only layer!");
    }
  }

  void layerMerged(final LayerState mergeLayer)
  {
    final int mergeLayerIndex = layers.value.indexOf(mergeLayer);
    if (mergeLayerIndex == layers.value.length - 1)
    {
      showMessage("No layer below!");
    }
    else if (mergeLayer.visibilityState.value == LayerVisibilityState.hidden)
    {
      showMessage("Cannot merge from an invisible layer!");
    }
    else if (layers.value[mergeLayerIndex + 1].visibilityState.value == LayerVisibilityState.hidden)
    {
      showMessage("Cannot merge with an invisible layer!");
    }
    else if (mergeLayer.lockState.value == LayerLockState.locked)
    {
      showMessage("Cannot merge from a locked layer!");
    }
    else if (layers.value[mergeLayerIndex + 1].lockState.value == LayerLockState.locked)
    {
      showMessage("Cannot merge with a locked layer!");
    }
    else
    {
      bool lowLayerWasSelected = false;
      final List<LayerState> layerList = [];
      selectionState.deselect();
      final HashMap<CoordinateSetI, ColorReference?> refs = HashMap();
      for (int i = 0; i < layers.value.length; i++)
      {
        if (i == mergeLayerIndex)
        {
          for (int x = 0; x < canvasWidth; x++)
          {
            for (int y = 0; y < canvasHeight; y++)
            {
              final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);

              //if transparent pixel -> use value from layer below
              if (mergeLayer.getDataEntry(curCoord) == null && layers.value[i+1].getDataEntry(curCoord) != null)
              {
                refs[curCoord] = layers.value[i+1].getDataEntry(curCoord);
              }
            }
          }
          layerList.add(mergeLayer);
          lowLayerWasSelected = layers.value[i+1].isSelected.value;
          i++;
          mergeLayer.setDataAll(refs);
        }
        else
        {
          layerList.add(layers.value[i]);
        }

      }
      if (lowLayerWasSelected)
      {
        layerSelected(mergeLayer);
      }
      layers.value = layerList;
    }
  }

  void layerDuplicated(final LayerState duplicateLayer)
  {
    List<LayerState> layerList = [];
    selectionState.deselect();
    for (int i = 0; i < layers.value.length; i++)
    {
      if (layers.value[i] == duplicateLayer)
      {
        layerList.add(LayerState.from(other: duplicateLayer));
      }
      layerList.add(layers.value[i]);
    }
    layers.value = layerList;
  }

  HashMap<int, int> _remapIndices(final int oldLength, final int newLength)
  {
    final HashMap<int, int> indexMap = HashMap();
    final int centerOld = oldLength ~/ 2;
    final int centerNew = newLength ~/ 2;
    for (int i = 0; i < oldLength; i++)
    {
      final int dist = i - centerOld;
      final int newIndex = min(max(0, centerNew + dist), newLength - 1);
      indexMap[i] = newIndex;
    }

    return indexMap;
  }

  void _deleteRampFromLayers({required final KPalRampData ramp})
  {
    for (final LayerState layer in layers.value)
    {
      layer.deleteRamp(ramp: ramp);
    }
  }

  void _remapLayers({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    for (final LayerState layer in layers.value)
    {
     layer.remapColors(newData: newData, map: map);
    }
  }

  void _reRaster()
  {
    for (final LayerState layer in layers.value)
    {
      layer.doManualRaster = true;
    }
  }

  void colorSelected(final ColorReference color)
  {
    selectedColor.value = color;
  }


  void setToolSelection(final ToolType tool)
  {
    for (final ToolType k in _selectionMap.keys)
    {
      final bool shouldSelect = (k == tool);
      if (_selectionMap[k] != shouldSelect)
      {
        _selectionMap[k] = shouldSelect;
      }

    }
    selectedTool.value = tool;
    currentToolOptions = prefs.toolOptions.toolOptionMap[selectedTool.value]!;
  }

  bool toolIsSelected(final ToolType tool)
  {
    return _selectionMap[tool] ?? false;
  }

  void showMessage(final String text) {
    showStyledToast(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme
                .of(ToastProvider.context)
                .primaryColorDark,
            border: Border(
              left: BorderSide(color: Theme
                  .of(ToastProvider.context)
                  .primaryColor, width: 2.0,),
              right: BorderSide(color: Theme
                  .of(ToastProvider.context)
                  .primaryColor, width: 2.0,),
              top: BorderSide(color: Theme
                  .of(ToastProvider.context)
                  .primaryColor, width: 2.0,),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
          ),

          child: Text(
            text,
            style: Theme
              .of(ToastProvider.context)
              .textTheme
              .titleMedium,),
        ),
        animationBuilder: (context, animation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: const Offset(0, 0),
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
        context: ToastProvider.context);
  }

}


