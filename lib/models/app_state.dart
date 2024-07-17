import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/managers/preference_manager.dart';
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
  final Map<ToolType, bool> _toolMap = {};
  final ValueNotifier<List<LayerState>> layers = ValueNotifier([]);
  final ValueNotifier<LayerState?> currentLayer = ValueNotifier(null);
  final RepaintNotifier repaintNotifier = RepaintNotifier();
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();

  final ValueNotifier<int> zoomFactor = ValueNotifier(1);
  static const int zoomLevelMin = 1;
  static const int zoomLevelMax = 80;

  final CoordinateSetI canvasSize = CoordinateSetI(x: 1, y: 1);
  late SelectionState selectionState = SelectionState(repaintNotifier: repaintNotifier);
  final StatusBarState statusBarState = StatusBarState();
  final String appDir;
  final String tempDir;
  final String cacheDir;
  final ValueNotifier<String?> filePath = ValueNotifier(null);
  final ValueNotifier<bool> hasChanges = ValueNotifier(false);


  AppState({required this.appDir, required this.tempDir, required this.cacheDir})
  {

    for (ToolType toolType in toolList.keys)
    {
      _toolMap[toolType] = false;
    }
    setToolSelection(ToolType.pencil);
    statusBarState.setStatusBarZoomFactor(zoomFactor.value * 100);
    currentLayer.addListener(() {
      selectionState.selection.setCurrentLayer(currentLayer.value);
    });
  }

  String getTitle()
  {
    return "KPix ${filePath.value != null ? getFileName() : ""}${hasChanges.value ? "*" : ""}";
  }

  void setCanvasDimensions({required int width, required int height, final bool addToHistoryStack = true})
  {
    canvasSize.x = width;
    canvasSize.y = height;
    statusBarState.setStatusBarDimensions(width, height);
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, description: "change canvas size");
    }
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

  void deleteRamp({required final KPalRampData ramp, final bool addToHistoryStack = true})
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
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, description: "delete ramp");
      }
    }
    else
    {
      showMessage("Cannot delete the only color ramp!");
    }
  }

  void updateRamp({required final KPalRampData ramp, required final KPalRampData originalData, final bool addToHistoryStack = true})
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
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, description: "update ramp");
    }
  }

  void addNewRamp({bool addToHistoryStack = true})
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
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, description: "add new ramp");
    }

  }

  LayerState addNewLayer({final bool addToHistoryStack = true, final bool select = false, final HashMap<CoordinateSetI, ColorReference?>? content})
  {
    final List<LayerState> layerList = [];
    final LayerState newLayer = LayerState(size: canvasSize, content: content);
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
      layerSelected(newLayer: newLayer);
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, description: "add new layer");
    }
    return newLayer;
  }

  void undoPressed()
  {
    if (GetIt.I.get<HistoryManager>().hasUndo.value)
    {
      showMessage("Undo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
      _restoreState(historyState: GetIt.I.get<HistoryManager>().undo());
    }
  }

  void redoPressed()
  {
    if (GetIt.I.get<HistoryManager>().hasRedo.value)
    {
      _restoreState(historyState: GetIt.I.get<HistoryManager>().redo());
      showMessage("Redo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
    }
  }

  void restoreFromFile({required final LoadFileSet loadFileSet})
  {
    if (loadFileSet.historyState != null && loadFileSet.path != null)
    {
      _restoreState(historyState: loadFileSet.historyState);
      filePath.value = loadFileSet.path;
      hasChanges.value = false;
    }
    else
    {
      showMessage("Loading failed (${loadFileSet.status})");
    }
  }

  void replacePalette({required final LoadPaletteSet loadPaletteSet, required final PaletteReplaceBehavior paletteReplaceBehavior})
  {
    if (loadPaletteSet.rampData != null && loadPaletteSet.rampData!.isNotEmpty)
    {
      if (paletteReplaceBehavior == PaletteReplaceBehavior.replace)
      {
        _deleteAllRampsFromLayers();
      }
      else
      {
        final HashMap<ColorReference, ColorReference> rampMap = Helper.getRampMap(rampList1: colorRamps.value, rampList2: loadPaletteSet.rampData!);
        for (final LayerState layerState in layers.value)
        {
          layerState.remapAllColors(rampMap: rampMap);
          layerState.doManualRaster = true;
        }
      }
      selectedColor.value = loadPaletteSet.rampData![0].references[0];
      colorRamps.value = loadPaletteSet.rampData!;
      GetIt.I.get<HistoryManager>().addState(appState: this, description: "replace color ramp");
    }
    else
    {
      showMessage("Loading palette failed (${loadPaletteSet.status})");
    }
  }



  String getFileName()
  {
    String fileName = "";
    if (filePath.value != null)
    {
      fileName = File(filePath.value!).uri.pathSegments.last;
    }
    return fileName;
  }

  void fileSaved({required String path})
  {
    filePath.value = path;
    hasChanges.value = false;
    showMessage("File saved at: $path");
  }

  void _restoreState({required final HistoryState? historyState})
  {
    if (historyState != null)
    {
      //CANVAS
      final CoordinateSetI canvSize = CoordinateSetI.from(historyState.canvasSize);

      //COLORS
      final List<KPalRampData> ramps = [];
      for (final HistoryRampData hRampData in historyState.rampList)
      {
        final KPalRampSettings settings = KPalRampSettings.from(other: hRampData.settings);
        ramps.add(KPalRampData(uuid: hRampData.uuid, settings: settings));
      }
      ColorReference selCol = ramps[historyState.selectedColor.rampIndex].references[historyState.selectedColor.colorIndex];


      //LAYERS
      final List<LayerState> stateList = [];
      LayerState? curSelLayer;
      int layerIndex = 0;
      for (final HistoryLayer historyLayer in historyState.layerList)
      {
        final HashMap<CoordinateSetI, ColorReference> content = HashMap();
        for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in historyLayer.data.entries)
        {
          KPalRampData? ramp;
          for (int i = 0; i < ramps.length; i++)
          {
            if (ramps[i].uuid == historyState.rampList[entry.value.rampIndex].uuid)
            {
              ramp = ramps[i];
              break;
            }
          }
          if (ramp != null)
          {
            content[CoordinateSetI.from(entry.key)] = ColorReference(colorIndex: entry.value.colorIndex, ramp: ramp);
          }
        }
        final LayerState layerState = LayerState(size: canvSize, content: content);
        layerState.lockState.value = historyLayer.lockState;
        layerState.visibilityState.value = historyLayer.visibilityState;
        final bool currentLayerIsSelected = (layerIndex == historyState.selectedLayerIndex);
        layerState.isSelected.value = currentLayerIsSelected;
        stateList.add(layerState);
        if (historyLayer == historyState.selectionState.currentLayer)
        {
          curSelLayer = layerState;
        }
        layerIndex++;
      }

      //SELECTION
      final HashMap<CoordinateSetI, ColorReference?> selectionContent = HashMap();
      for (final MapEntry<CoordinateSetI, HistoryColorReference?> entry in historyState.selectionState.content.entries)
      {
        if (entry.value != null)
        {
          selectionContent[CoordinateSetI.from(entry.key)] = ramps[entry.value!.rampIndex].references[entry.value!.colorIndex];
        }
        else
        {
          selectionContent[CoordinateSetI.from(entry.key)] = null;
        }
      }

      // SET VALUES
      // ramps
      colorRamps.value = ramps;
      // selected color
      selectedColor.value = selCol;
      //canvas
      canvasSize.x = canvSize.x;
      canvasSize.y = canvSize.y;
      // layers
      layers.value = stateList;
      currentLayer.value = curSelLayer?? getSelectedLayer();
      // selection state (incl layer)
      selectionState.selection.delete(false);
      selectionState.selection.addDirectlyAll(selectionContent);
      selectionState.selection.currentLayer = curSelLayer?? getSelectedLayer();
      selectionState.createSelectionLines();
      selectionState.notifyRepaint();
    }
  }

  void changeLayerOrder({required final LayerState state, required final int newPosition, final bool addToHistoryStack = true})
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
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, description: "change layer order");
      }
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

  void layerSelected({required final LayerState newLayer, final bool addToHistoryStack = false})
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
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, description: "select layer");
      }
    }

  }

  void layerDeleted({required final LayerState deleteLayer, final bool addToHistoryStack = true})
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
        layerSelected(newLayer: layerList[foundIndex - 1], addToHistoryStack: false);
      }
      else
      {
        layerSelected(newLayer: layerList[0], addToHistoryStack: false);
      }

      layers.value = layerList;
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, description: "delete layer");
      }
    }
    else
    {
      showMessage("Cannot delete the only layer!");
    }
  }

  void layerMerged({required final LayerState mergeLayer, final bool addToHistoryStack = true})
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
      selectionState.deselect(addToHistoryStack: false);
      final HashMap<CoordinateSetI, ColorReference?> refs = HashMap();
      for (int i = 0; i < layers.value.length; i++)
      {
        if (i == mergeLayerIndex)
        {
          for (int x = 0; x < canvasSize.x; x++)
          {
            for (int y = 0; y < canvasSize.y; y++)
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
        layerSelected(newLayer: mergeLayer, addToHistoryStack: false);
      }
      layers.value = layerList;
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, description: "merge layer");
      }
    }
  }

  void layerDuplicated({required final LayerState duplicateLayer, final bool addToHistoryStack = true})
  {
    List<LayerState> layerList = [];
    selectionState.deselect(addToHistoryStack: false);
    for (int i = 0; i < layers.value.length; i++)
    {
      if (layers.value[i] == duplicateLayer)
      {
        layerList.add(LayerState.from(other: duplicateLayer));
      }
      layerList.add(layers.value[i]);
    }
    layers.value = layerList;
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, description: "duplicate layer");
    }
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

  void _deleteAllRampsFromLayers()
  {
    for (final LayerState layerState in layers.value)
    {
      for (final KPalRampData kPalRampData in colorRamps.value)
      {
        layerState.deleteRamp(ramp: kPalRampData);
      }
      layerState.doManualRaster = true;
    }
  }

  void _remapLayers({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    for (final LayerState layer in layers.value)
    {
     layer.remapSingleRamp(newData: newData, map: map);
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
    for (final ToolType k in _toolMap.keys)
    {
      final bool shouldSelect = (k == tool);
      if (_toolMap[k] != shouldSelect)
      {
        _toolMap[k] = shouldSelect;
      }

    }
    selectedTool.value = tool;
    currentToolOptions = prefs.toolOptions.toolOptionMap[selectedTool.value]!;
  }

  bool toolIsSelected(final ToolType tool)
  {
    return _toolMap[tool] ?? false;
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


