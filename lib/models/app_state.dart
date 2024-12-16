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
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/util/update_helper.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:toastification/toastification.dart';
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
  final ValueNotifier<bool> _hasProject = ValueNotifier<bool>(false);
  bool get hasProject
  {
    return _hasProject.value;
  }
  ValueNotifier<bool> get hasProjectNotifier
  {
    return _hasProject;
  }

  final ValueNotifier<ToolType> _selectedTool = ValueNotifier<ToolType>(ToolType.pencil);
  ToolType get selectedTool
  {
    return _selectedTool.value;
  }
  ValueNotifier<ToolType> get selectedToolNotifier
  {
    return _selectedTool;
  }
  ToolType _previousDrawTool = ToolType.pencil;
  late IToolOptions _currentToolOptions;
  final ValueNotifier<List<KPalRampData>> _colorRamps = ValueNotifier<List<KPalRampData>>(<KPalRampData>[]);
  List<KPalRampData> get colorRamps
  {
    return _colorRamps.value;
  }
  ValueNotifier<List<KPalRampData>> get colorRampNotifier
  {
    return _colorRamps;
  }
  final ValueNotifier<ColorReference?> _selectedColor = ValueNotifier<ColorReference?>(null);
  ColorReference? get selectedColor
  {
    return _selectedColor.value;
  }
  ValueNotifier<ColorReference?> get selectedColorNotifier
  {
    return _selectedColor;
  }
  final Map<ToolType, bool> _toolMap = <ToolType, bool>{};
  final ValueNotifier<List<LayerState>> _layers = ValueNotifier<List<LayerState>>(<LayerState>[]);
  List<LayerState> get layers
  {
    return _layers.value;
  }
  ValueNotifier<List<LayerState>> get layerListNotifier
  {
    return _layers;
  }
  final ValueNotifier<LayerState?> _currentLayer = ValueNotifier<LayerState?>(null);
  LayerState? get currentLayer
  {
    return _currentLayer.value;
  }
  ValueNotifier<LayerState?> get currentLayerNotifier
  {
    return _currentLayer;
  }

  final RepaintNotifier repaintNotifier = RepaintNotifier();
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();

  final ValueNotifier<int> _zoomFactor = ValueNotifier<int>(1);
  int get zoomFactor
  {
    return _zoomFactor.value;
  }
  static const int zoomLevelMin = 1;
  static const int zoomLevelMax = 80;

  final CoordinateSetI _canvasSize = CoordinateSetI(x: 1, y: 1);
  CoordinateSetI get canvasSize
  {
    return CoordinateSetI.from(other: _canvasSize);
  }
  late SelectionState selectionState = SelectionState(repaintNotifier: repaintNotifier);
  final StatusBarState statusBarState = StatusBarState();

  final ValueNotifier<String> _exportDir;
  String get exportDir
  {
    return _exportDir.value;
  }
  ValueNotifier<String> get exportDirNotifier
  {
    return _exportDir;
  }
  set exportDir(final String dir)
  {
    _exportDir.value = dir;
  }

  final ValueNotifier<String> _internalDir;
  String get internalDir
  {
    return _internalDir.value;
  }
  ValueNotifier<String> get internalDirNotifier
  {
    return _internalDir;
  }
  set internalDir(final String dir)
  {
    _internalDir.value = dir;
  }

  final ValueNotifier<bool> _hasUpdate;
  bool get hasUpdate
  {
    return _hasUpdate.value;
  }
  ValueNotifier<bool> get hasUpdateNotifier
  {
    return _hasUpdate;
  }

  UpdateInfoPackage? updatePackage;

  final ValueNotifier<String?> projectName = ValueNotifier<String?>(null);
  final ValueNotifier<bool> hasChanges = ValueNotifier<bool>(false);

  static const Duration toolTipDuration = Duration(seconds: 1);


  AppState({required final String exportDir, required final String internalDir}) : _exportDir = ValueNotifier<String>(exportDir), _internalDir = ValueNotifier<String>(internalDir), _hasUpdate = ValueNotifier<bool>(false)
  {
    for (final ToolType toolType in toolList.keys)
    {
      _toolMap[toolType] = false;
    }
    setToolSelection(tool: ToolType.pencil, forceSetting: true);
    statusBarState.setStatusBarZoomFactor(val: _zoomFactor.value * 100);
    _setHotkeys();
  }

  void _setHotkeys()
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.pencil);}, action: HotkeyAction.selectToolPencil);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.fill);}, action: HotkeyAction.selectToolFill);
    hotkeyManager.addListener(func: () {_setSelectionToolSelection(shape: SelectShape.rectangle);}, action: HotkeyAction.selectToolSelectRectangle);
    hotkeyManager.addListener(func: () {_setSelectionToolSelection(shape: SelectShape.ellipse);}, action: HotkeyAction.selectToolSelectCircle);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.shape);}, action: HotkeyAction.selectToolShape);
    hotkeyManager.addListener(func: () {_setSelectionToolSelection(shape: SelectShape.wand);}, action: HotkeyAction.selectToolSelectWand);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.erase);}, action: HotkeyAction.selectToolEraser);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.font);}, action: HotkeyAction.selectToolText);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.spraycan);}, action: HotkeyAction.selectToolSprayCan);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.line);}, action: HotkeyAction.selectToolLine);
    hotkeyManager.addListener(func: () {setToolSelection(tool: ToolType.stamp);}, action: HotkeyAction.selectToolStamp);
    hotkeyManager.addListener(func: () {changeLayerVisibility(layerState: currentLayer!);}, action: HotkeyAction.layersSwitchVisibility);
    hotkeyManager.addListener(func: () {changeLayerLockState(layerState: currentLayer!);}, action: HotkeyAction.layersSwitchLock);
    hotkeyManager.addListener(func: addNewDrawingLayer, action: HotkeyAction.layersNewDrawing);
    hotkeyManager.addListener(func: addNewReferenceLayer, action: HotkeyAction.layersNewReference);
    hotkeyManager.addListener(func: addNewShadingLayer, action: HotkeyAction.layersNewShading);
    hotkeyManager.addListener(func: addNewGridLayer, action: HotkeyAction.layersNewGrid);
    hotkeyManager.addListener(func: () {layerDuplicated(duplicateLayer: currentLayer!);}, action: HotkeyAction.layersDuplicate);
    hotkeyManager.addListener(func: () {layerDeleted(deleteLayer: currentLayer!);}, action: HotkeyAction.layersDelete);
    hotkeyManager.addListener(func: () {layerMerged(mergeLayer: currentLayer!);}, action: HotkeyAction.layersMerge);
    hotkeyManager.addListener(func: () {moveUpLayer(state: currentLayer!);}, action: HotkeyAction.layersMoveUp);
    hotkeyManager.addListener(func: () {moveDownLayer(state: currentLayer!);}, action: HotkeyAction.layersMoveDown);
    hotkeyManager.addListener(func: selectLayerAbove, action: HotkeyAction.layersSelectAbove);
    hotkeyManager.addListener(func: selectLayerBelow, action: HotkeyAction.layersSelectBelow);
    hotkeyManager.addListener(func: increaseZoomLevel, action: HotkeyAction.panZoomZoomIn);
    hotkeyManager.addListener(func: decreaseZoomLevel, action: HotkeyAction.panZoomZoomOut);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 1);}, action: HotkeyAction.panZoomSetZoom100);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 2);}, action: HotkeyAction.panZoomSetZoom200);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 4);}, action: HotkeyAction.panZoomSetZoom400);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 8);}, action: HotkeyAction.panZoomSetZoom800);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 16);}, action: HotkeyAction.panZoomSetZoom1600);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 32);}, action: HotkeyAction.panZoomSetZoom3200);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 48);}, action: HotkeyAction.panZoomSetZoom4800);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 64);}, action: HotkeyAction.panZoomSetZoom6400);
    hotkeyManager.addListener(func: () {setZoomLevel(val: 80);}, action: HotkeyAction.panZoomSetZoom8000);



  }

  void init({required final CoordinateSetI dimensions})
  {
    _setCanvasDimensions(width: dimensions.x, height: dimensions.y, addToHistoryStack: false);
    final List<LayerState> layerList = <LayerState>[];
    selectionState.deselect(addToHistoryStack: false, notify: false);
    _layers.value = layerList;
    addNewDrawingLayer(select: true, addToHistoryStack: false);
    _setDefaultPalette();
    GetIt.I.get<HistoryManager>().clear();
    GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.initial, setHasChanges: false);
    projectName.value = null;
    hasChanges.value = false;
    hasProjectNotifier.value = true;
  }

  String getTitle()
  {
    return "KPix ${projectName.value ?? ""}${hasChanges.value ? "*" : ""}";
  }

  void _setCanvasDimensions({required final int width, required final int height, final bool addToHistoryStack = true})
  {
    _canvasSize.x = width;
    _canvasSize.y = height;
    statusBarState.setStatusBarDimensions(width: width, height: height);
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.canvasSizeChange);
    }
  }

  bool increaseZoomLevel()
  {
    bool changed = false;
    if (_zoomFactor.value < zoomLevelMax)
    {
      _zoomFactor.value = _zoomFactor.value + 1;
      statusBarState.setStatusBarZoomFactor(val: _zoomFactor.value * 100);
      changed = true;
    }
    return changed;
  }

  bool decreaseZoomLevel()
  {
    bool changed = false;
    if (_zoomFactor.value > zoomLevelMin)
    {
      _zoomFactor.value = _zoomFactor.value - 1;
      statusBarState.setStatusBarZoomFactor(val: _zoomFactor.value * 100);
      changed = true;
    }
    return changed;
  }

  bool setZoomLevelByDistance({required final int startZoomLevel, required final int steps})
  {
    bool change = false;
    if (steps != 0)
    {
      final int endIndex = startZoomLevel + steps;
      if (endIndex <= zoomLevelMax && endIndex >= zoomLevelMin && endIndex != _zoomFactor.value)
      {
         _zoomFactor.value = endIndex;
         statusBarState.setStatusBarZoomFactor(val: _zoomFactor.value * 100);
         change = true;
      }
    }
    return change;
  }

  bool setZoomLevel({required final int val})
  {
    bool change = false;
    if (val <= zoomLevelMax && val >= zoomLevelMin && val != _zoomFactor.value)
    {
      _zoomFactor.value = val;
      statusBarState.setStatusBarZoomFactor(val: _zoomFactor.value * 100);
      change = true;
    }
    return change;
  }


  int getCurrentToolSize()
  {
    return _currentToolOptions.getSize();
  }

  void setToolSize(final int steps, final int originalValue)
  {
    _currentToolOptions.changeSize(steps: steps, originalValue: originalValue);
  }

  void deleteRamp({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
    if (colorRamps.length > constraints.rampCountMin)
    {
      final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
      rampDataList.remove(ramp);
      _selectedColor.value = rampDataList[0].references[0];
      _colorRamps.value = rampDataList;
      _deleteRampFromLayers(ramp: ramp);
      _reRaster();
      repaintNotifier.repaint();
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.kPalDelete);
      }
    }
    else
    {
      showMessage(text: "Need at least ${constraints.rampCountMin} color ramp(s)!");
    }
  }

  void updateRamp({required final KPalRampData ramp, required final KPalRampData originalData, final bool addToHistoryStack = true})
  {
    final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
    _colorRamps.value = rampDataList;

    if (ramp.shiftedColors.length != originalData.shiftedColors.length)
    {
      final HashMap<int, int> indexMap = remapIndices(oldLength: originalData.shiftedColors.length, newLength: ramp.shiftedColors.length);
      _selectedColor.value = ramp.references[indexMap[_selectedColor.value!.colorIndex]!];
      _remapLayers(newData: ramp, map: indexMap);
    }
    _reRaster();
    repaintNotifier.repaint();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.kPalChange);
    }
  }

  void _setDefaultPalette()
  {
    _colorRamps.value = KPalRampData.getDefaultPalette(constraints: GetIt.I.get<PreferenceManager>().kPalConstraints);
    _selectedColor.value = _colorRamps.value[0].references[0];
  }

  void addNewRamp({final bool addToHistoryStack = true})
  {
    final KPalConstraints constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
    if (colorRamps.length < constraints.rampCountMax)
    {

      const Uuid uuid = Uuid();
      final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
      final KPalRampData newRamp = KPalRampData(
          uuid: uuid.v1(),
          settings: KPalRampSettings(
              constraints: prefs.kPalConstraints,
          ),
      );
      rampDataList.add(newRamp);
      _colorRamps.value = rampDataList;
      _selectedColor.value = newRamp.references[0];
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.kPalAdd);
      }
    }
    else
    {
      showMessage(text: "Not more than ${constraints.rampCountMax} color ramps allowed!");
    }
  }

  ReferenceLayerState addNewReferenceLayer({final bool addToHistoryStack = true, final bool select = false})
  {
    final ReferenceLayerSettings refSettings = GetIt.I.get<PreferenceManager>().referenceLayerSettings;
    final List<LayerState> layerList = <LayerState>[];
    final ReferenceLayerState newLayer = ReferenceLayerState(aspectRatio: refSettings.aspectRatioDefault, image: null, offsetX: 0, offsetY: 0, opacity: refSettings.opacityDefault, zoom: refSettings.zoomDefault);
    if (_layers.value.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      selectionState.selection.changeLayer(oldLayer: null, newLayer: newLayer);
      layerList.add(newLayer);
    }
    else
    {
      for (int i = 0; i < _layers.value.length; i++)
      {
        if (_layers.value[i].isSelected.value)
        {
          layerList.add(newLayer);
        }
        layerList.add(_layers.value[i]);
      }
    }
    _layers.value = layerList;
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewReference);
    }
    return newLayer;
  }

  ShadingLayerState addNewShadingLayer({final bool addToHistoryStack = true, final bool select = false})
  {
    final ShadingLayerState newLayer = ShadingLayerState();
    final List<LayerState> layerList = <LayerState>[];
    if (_layers.value.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      selectionState.selection.changeLayer(oldLayer: null, newLayer: newLayer);
      layerList.add(newLayer);
    }
    else
    {
      for (int i = 0; i < _layers.value.length; i++)
      {
        if (_layers.value[i].isSelected.value)
        {
          layerList.add(newLayer);
        }
        layerList.add(_layers.value[i]);
      }
    }
    _layers.value = layerList;
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewGrid);
    }
    return newLayer;
  }

  GridLayerState addNewGridLayer({final bool addToHistoryStack = true, final bool select = false})
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
    if (_layers.value.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      selectionState.selection.changeLayer(oldLayer: null, newLayer: newLayer);
      layerList.add(newLayer);
    }
    else
    {
      for (int i = 0; i < _layers.value.length; i++)
      {
        if (_layers.value[i].isSelected.value)
        {
          layerList.add(newLayer);
        }
        layerList.add(_layers.value[i]);
      }
    }
    _layers.value = layerList;
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewGrid);
    }
    return newLayer;
  }

  DrawingLayerState addNewDrawingLayer({final bool addToHistoryStack = true, final bool select = false, final CoordinateColorMapNullable? content})
  {
    final List<LayerState> layerList = <LayerState>[];
    final DrawingLayerState newLayer = DrawingLayerState(size: _canvasSize, content: content);
    if (_layers.value.isEmpty)
    {
      newLayer.isSelected.value = true;
      _currentLayer.value = newLayer;
      selectionState.selection.changeLayer(oldLayer: null, newLayer: newLayer);
      layerList.add(newLayer);
    }
    else
    {
      for (int i = 0; i < _layers.value.length; i++)
      {
        if (_layers.value[i].isSelected.value)
        {
          layerList.add(newLayer);
        }
        layerList.add(_layers.value[i]);
      }
    }
    _layers.value = layerList;
    if (select)
    {
      selectLayer(newLayer: newLayer);
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewDrawing);
    }
    return newLayer;
  }

  void undoPressed()
  {
    if (GetIt.I.get<HistoryManager>().hasUndo.value)
    {
      showMessage(text: "Undo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
      _restoreState(historyState: GetIt.I.get<HistoryManager>().undo());
    }
  }

  void redoPressed()
  {
    if (GetIt.I.get<HistoryManager>().hasRedo.value)
    {
      _restoreState(historyState: GetIt.I.get<HistoryManager>().redo());
      showMessage(text: "Redo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
    }
  }

  void restoreFromFile({required final LoadFileSet loadFileSet, final bool setHasChanges = false})
  {
    if (loadFileSet.historyState != null && loadFileSet.path != null)
    {
      _restoreState(historyState: loadFileSet.historyState).then((final void value)
      {
        final String projectNameExtracted = extractFilenameFromPath(path: loadFileSet.path, keepExtension: false);
        projectName.value = projectNameExtracted == recoverFileName ? null : projectNameExtracted;
        hasChanges.value = setHasChanges;
        hasProjectNotifier.value = true;
        GetIt.I.get<HistoryManager>().clear();
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.initial, setHasChanges: setHasChanges);
        _setCanvasDimensions(width: loadFileSet.historyState!.canvasSize.x , height: loadFileSet.historyState!.canvasSize.y, addToHistoryStack: false);
        GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);

      });
    }
    else
    {
      showMessage(text: "Loading failed (${loadFileSet.status})");
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
        final HashMap<ColorReference, ColorReference> rampMap = getRampMap(rampList1: _colorRamps.value, rampList2: loadPaletteSet.rampData!);
        for (final LayerState layer in _layers.value)
        {
          if (layer.runtimeType == DrawingLayerState)
          {
            final DrawingLayerState drawingLayer = layer as DrawingLayerState;
            drawingLayer.remapAllColors(rampMap: rampMap);
            drawingLayer.doManualRaster = true;
          }
        }
      }
      _selectedColor.value = loadPaletteSet.rampData![0].references[0];
      _colorRamps.value = loadPaletteSet.rampData!;
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.kPalAdd);
    }
    else
    {
      showMessage(text: "Loading palette failed (${loadPaletteSet.status})");
    }
  }

  void fileSaved({required final String saveName, required final String path, final bool addKPixExtension = false})
  {
    projectName.value = saveName;
    hasChanges.value = false;

    String displayPath = kIsWeb ? ("$path/$saveName") : path;
    if (addKPixExtension)
    {
      displayPath += ".$fileExtensionKpix";
    }
    showMessage(text: "File saved at: $displayPath");
  }

  Future<void> _restoreState({required final HistoryState? historyState}) async
  {
    if (historyState != null)
    {
      //CANVAS
      final CoordinateSetI canvSize = CoordinateSetI.from(other: historyState.canvasSize);

      //COLORS
      final List<KPalRampData> ramps = <KPalRampData>[];
      for (final HistoryRampData hRampData in historyState.rampList)
      {
        final KPalRampSettings settings = KPalRampSettings.from(other: hRampData.settings);
        ramps.add(KPalRampData(uuid: hRampData.uuid, settings: settings, historyShifts: hRampData.shiftSets));
      }
      final ColorReference selCol = ramps[historyState.selectedColor.rampIndex].references[historyState.selectedColor.colorIndex];


      //LAYERS
      final List<LayerState> layerList = <LayerState>[];
      LayerState? curSelLayer;
      int layerIndex = 0;
      for (final HistoryLayer historyLayer in historyState.layerList)
      {
        LayerState? layerState;
        if (historyLayer.runtimeType == HistoryDrawingLayer)
        {
          final HistoryDrawingLayer historyDrawingLayer = historyLayer as HistoryDrawingLayer;
          final CoordinateColorMap content = HashMap<CoordinateSetI, ColorReference>();
          for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in historyDrawingLayer.data.entries)
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
              content[CoordinateSetI.from(other: entry.key)] = ColorReference(colorIndex: entry.value.colorIndex, ramp: ramp);
            }
          }
          final DrawingLayerState drawingLayer = DrawingLayerState(size: canvSize, content: content);
          drawingLayer.lockState.value = historyLayer.lockState;
          layerState = drawingLayer;
        }
        else if (historyLayer.runtimeType == HistoryReferenceLayer)
        {
          final HistoryReferenceLayer referenceLayer = historyLayer as HistoryReferenceLayer;
          layerState = ReferenceLayerState(zoom: referenceLayer.zoom, opacity: referenceLayer.opacity, offsetX: referenceLayer.offsetX, offsetY: referenceLayer.offsetY, image: await GetIt.I.get<ReferenceImageManager>().loadImageFile(path: referenceLayer.path), aspectRatio: referenceLayer.aspectRatio);
        }
        else if (historyLayer.runtimeType == HistoryGridLayer)
        {
          final HistoryGridLayer gridLayer = historyLayer as HistoryGridLayer;
          layerState = GridLayerState(opacity: gridLayer.opacity, brightness: gridLayer.brightness, gridType: gridLayer.gridType, intervalX: gridLayer.intervalX, intervalY: gridLayer.intervalY, horizonPosition: gridLayer.horizonPosition, vanishingPoint1: gridLayer.vanishingPoint1, vanishingPoint2: gridLayer.vanishingPoint2, vanishingPoint3: gridLayer.vanishingPoint3 );
        }

        if (layerState != null)
        {
          layerState.visibilityState.value = historyLayer.visibilityState;
          final bool currentLayerIsSelected = (layerIndex == historyState.selectedLayerIndex);
          layerState.isSelected.value = currentLayerIsSelected;
          layerList.add(layerState);
          if (historyLayer == historyState.selectionState.currentLayer)
          {
            curSelLayer = layerState;
          }
          layerIndex++;
        }
      }

      //SELECTION
      final CoordinateColorMapNullable selectionContent = HashMap<CoordinateSetI, ColorReference?>();
      for (final MapEntry<CoordinateSetI, HistoryColorReference?> entry in historyState.selectionState.content.entries)
      {
        if (entry.value != null)
        {
          selectionContent[CoordinateSetI.from(other: entry.key)] = ramps[entry.value!.rampIndex].references[entry.value!.colorIndex];
        }
        else
        {
          selectionContent[CoordinateSetI.from(other: entry.key)] = null;
        }
      }

      // SET VALUES
      // ramps
      _colorRamps.value = ramps;
      // selected color
      _selectedColor.value = selCol;
      //canvas
      _canvasSize.x = canvSize.x;
      _canvasSize.y = canvSize.y;
      // layers
      _layers.value = layerList;
      _currentLayer.value = curSelLayer?? getSelectedLayer();
      // selection state (incl layer)
      selectionState.selection.delete(keepSelection: false);
      selectionState.selection.addDirectlyAll(list: selectionContent);
      selectionState.createSelectionLines();
      selectionState.notifyRepaint();
    }
  }

  int _getLayerPosition({required final LayerState state})
  {
    int sourcePosition = -1;
    for (int i = 0; i < _layers.value.length; i++)
    {
      if (_layers.value[i] == state)
      {
        sourcePosition = i;
        break;
      }
    }
    return sourcePosition;
  }

  void moveUpLayer({required final LayerState state})
  {
    final int sourcePosition = _getLayerPosition(state: state);
    if (sourcePosition > 0)
    {
      changeLayerOrder(state: state, newPosition: sourcePosition - 1);
    }
  }

  void moveDownLayer({required final LayerState state})
  {
    final int sourcePosition = _getLayerPosition(state: state);
    if (sourcePosition < (layers.length - 1))
    {
      changeLayerOrder(state: state, newPosition: sourcePosition + 2);
    }
  }

  void incrementColorSelection()
  {
    final (int, int) indices = _getRampAndColorIndex(color: selectedColor!);
    if (indices.$1 >= 0 && indices.$1 < colorRamps.length && indices.$2 >= 0 && indices.$2 < colorRamps[indices.$1].references.length)
    {
      if ((indices.$2 + 1) < colorRamps[indices.$1].references.length)
      {
         colorSelected(color: colorRamps[indices.$1].references[indices.$2 + 1]);
      }
      else if ((indices.$1 + 1) < colorRamps.length)
      {
        colorSelected(color: colorRamps[indices.$1 + 1].references.first);
      }
      else
      {
        colorSelected(color: colorRamps.first.references.first);
      }
    }
  }

  void decrementColorSelection()
  {
    final (int, int) indices = _getRampAndColorIndex(color: selectedColor!);
    if (indices.$1 >= 0 && indices.$1 < colorRamps.length && indices.$2 >= 0 && indices.$2 < colorRamps[indices.$1].references.length)
    {
      if ((indices.$2 - 1) >= 0)
      {
        colorSelected(color: colorRamps[indices.$1].references[indices.$2 - 1]);
      }
      else if ((indices.$1 - 1) >= 0)
      {
        colorSelected(color: colorRamps[indices.$1 - 1].references.last);
      }
      else
      {
        colorSelected(color: colorRamps.last.references.last);
      }
    }
  }

  (int, int) _getRampAndColorIndex({required final ColorReference color})
  {
    int rampIndex = -1;
    int colorIndex = -1;
    for (int i = 0; i < colorRamps.length; i++)
    {
      for (int j = 0; j < colorRamps[i].references.length; j++)
      {
        if (colorRamps[i].references[j] == color)
        {
          rampIndex = i;
          colorIndex = j;
        }
      }
    }

    return (rampIndex, colorIndex);
  }

  void changeLayerOrder({required final LayerState state, required final int newPosition, final bool addToHistoryStack = true})
  {
    final int sourcePosition = _getLayerPosition(state: state);

    if (sourcePosition != newPosition && (sourcePosition + 1) != newPosition)
    {
      final List<LayerState> stateList = List<LayerState>.from(_layers.value);
      stateList.removeAt(sourcePosition);
      if (newPosition > sourcePosition) {
        stateList.insert(newPosition - 1, state);
      }
      else
        {
          stateList.insert(newPosition, state);
        }
      _layers.value = stateList;
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerOrderChange);
      }
      repaintNotifier.repaint();
    }
  }

  void changeLayerVisibility({required final LayerState layerState})
  {
    if (layerState.visibilityState.value == LayerVisibilityState.visible)
    {
      layerState.visibilityState.value = LayerVisibilityState.hidden;
    }
    else if (layerState.visibilityState.value == LayerVisibilityState.hidden)
    {
      layerState.visibilityState.value = LayerVisibilityState.visible;
    }
    GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerVisibilityChange);
  }

  void changeLayerLockState({required final LayerState layerState})
  {
    if (layerState.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayerState = layerState as DrawingLayerState;
      if (drawingLayerState.lockState.value == LayerLockState.unlocked)
      {
        drawingLayerState.lockState.value = LayerLockState.transparency;
      }
      else if (drawingLayerState.lockState.value == LayerLockState.transparency)
      {
        drawingLayerState.lockState.value = LayerLockState.locked;
      }
      else if (drawingLayerState.lockState.value == LayerLockState.locked)
      {
        drawingLayerState.lockState.value = LayerLockState.unlocked;
      }
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerLockChange);
    }
  }


  LayerState? getSelectedLayer()
  {
    LayerState? selectedLayer;
    for (final LayerState state in _layers.value)
    {
      if (state.isSelected.value)
      {
        selectedLayer = state;
      }
    }
    return selectedLayer;
  }

  int getSelectedLayerIndex()
  {
    if (currentLayer != null)
    {
      return _layers.value.indexOf(currentLayer!);
    }
    else
    {
      return -1;
    }
  }

  void selectLayerAbove()
  {
    final int index = _getLayerPosition(state: currentLayer!);
    if (index > 0)
    {
      selectLayer(newLayer: layers[index - 1]);
    }
  }

  void selectLayerBelow()
  {
    final int index = _getLayerPosition(state: currentLayer!);
    if (index < layers.length - 1)
    {
      selectLayer(newLayer: layers[index + 1]);
    }
  }


  void selectLayer({required final LayerState newLayer, final bool addToHistoryStack = false})
  {
    LayerState oldLayer = newLayer;
    for (final LayerState layer in _layers.value)
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
      _currentLayer.value = newLayer;
      selectionState.selection.changeLayer(oldLayer: oldLayer, newLayer: newLayer);
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerChange);
      }
    }

  }

  void layerDeleted({required final LayerState deleteLayer, final bool addToHistoryStack = true})
  {
    if (_layers.value.length > 1)
    {
      final List<LayerState> layerList = <LayerState>[];
      int foundIndex = 0;
      for (int i = 0; i < _layers.value.length; i++)
      {
        if (_layers.value[i] != deleteLayer)
        {
          layerList.add(_layers.value[i]);
        }
        else
        {
          foundIndex = i;
        }
      }

      if (foundIndex > 0)
      {
        selectLayer(newLayer: layerList[foundIndex - 1]);
      }
      else
      {
        selectLayer(newLayer: layerList[0]);
      }

      _layers.value = layerList;
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDelete);
      }
    }
    else
    {
      showMessage(text: "Cannot delete the only layer!");
    }
  }

  void layerMerged({required final LayerState mergeLayer, final bool addToHistoryStack = true})
  {
    if (mergeLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingMergeLayer = mergeLayer as DrawingLayerState;
      final int mergeLayerIndex = _layers.value.indexOf(mergeLayer);
      if (mergeLayerIndex == _layers.value.length - 1)
      {
        showMessage(text: "No layer below!");
      }
      else if (drawingMergeLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot merge from an invisible layer!");
      }
      else if (_layers.value[mergeLayerIndex + 1].visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot merge with an invisible layer!");
      }
      else if (drawingMergeLayer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot merge from a locked layer!");
      }
      else if (_layers.value[mergeLayerIndex + 1].runtimeType == DrawingLayerState && (_layers.value[mergeLayerIndex + 1] as DrawingLayerState).lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot merge with a locked layer!");
      }
      else if (_layers.value[mergeLayerIndex + 1].runtimeType != DrawingLayerState)
      {
        showMessage(text: "Can only merge with drawing layers!");
      }
      else
      {
        bool lowLayerWasSelected = false;
        final List<LayerState> layerList = List<LayerState>.empty(growable: true);
        selectionState.deselect(addToHistoryStack: false);
        final CoordinateColorMapNullable refs = HashMap<CoordinateSetI, ColorReference?>();
        for (int i = 0; i < _layers.value.length; i++)
        {
          if (i == mergeLayerIndex && _layers.value[i+1].runtimeType == DrawingLayerState)
          {
            final DrawingLayerState drawingLayer = _layers.value[i+1] as DrawingLayerState;
            for (int x = 0; x < _canvasSize.x; x++)
            {
              for (int y = 0; y < _canvasSize.y; y++)
              {
                final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);

                //if transparent pixel -> use value from layer below
                if (drawingMergeLayer.getDataEntry(coord: curCoord) == null && drawingLayer.getDataEntry(coord: curCoord) != null)
                {
                  refs[curCoord] = drawingLayer.getDataEntry(coord: curCoord);
                }
              }
            }
            layerList.add(drawingMergeLayer);
            lowLayerWasSelected = drawingLayer.isSelected.value;
            i++;
            drawingMergeLayer.setDataAll(list: refs);
          }
          else
          {
            layerList.add(_layers.value[i]);
          }

        }
        if (lowLayerWasSelected)
        {
          selectLayer(newLayer: drawingMergeLayer);
        }
        _layers.value = layerList;
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerMerge);
        }
      }
    }
    else
    {
      showMessage(text: "Can only merge Drawing Layers!");
    }
  }

  void layerDuplicated({required final LayerState duplicateLayer, final bool addToHistoryStack = true})
  {
    final List<LayerState> layerList = <LayerState>[];
    selectionState.deselect(addToHistoryStack: false);
    for (int i = 0; i < _layers.value.length; i++)
    {
      if (_layers.value[i] == duplicateLayer)
      {
        if (duplicateLayer.runtimeType == DrawingLayerState)
        {
          final DrawingLayerState drawingLayer = duplicateLayer as DrawingLayerState;
          layerList.add(DrawingLayerState.from(other: drawingLayer));
        }
        else if (duplicateLayer.runtimeType == ReferenceLayerState)
        {
          final ReferenceLayerState referenceLayer = duplicateLayer as ReferenceLayerState;
          layerList.add(ReferenceLayerState.from(other: referenceLayer));
        }
        else if (duplicateLayer.runtimeType == GridLayerState)
        {
          final GridLayerState gridLayer = duplicateLayer as GridLayerState;
          layerList.add(GridLayerState.from(other: gridLayer));
        }
      }
      layerList.add(_layers.value[i]);
    }
    _layers.value = layerList;
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDuplicate);
    }
  }

  void layerRastered({required final LayerState rasterLayer, final bool addToHistoryStack = true})
  {
    if (rasterLayer.runtimeType == GridLayerState)
    {
      final GridLayerState gridLayer = rasterLayer as GridLayerState;
      gridLayer.getHashMap().then((final CoordinateColorMap data) {
        _replaceCurrentLayerWithDrawingLayer(data: data, originalLayer: rasterLayer);
      });
    }
    else if (rasterLayer.runtimeType == ShadingLayerState)
    {
      //TODO
    }
  }

  void _replaceCurrentLayerWithDrawingLayer({required final CoordinateColorMap data, required final LayerState originalLayer, final bool addToHistoryStack = true})
  {
    final List<LayerState> layerList = <LayerState>[];
    final DrawingLayerState drawingLayer = DrawingLayerState(size: canvasSize, content: data);
    for (final LayerState layer in _layers.value)
    {
       if (layer != originalLayer)
       {
          layerList.add(layer);
       }
       else
       {
         layerList.add(drawingLayer);

       }
    }
    if (originalLayer.isSelected.value)
    {
      selectLayer(newLayer: drawingLayer);
    }
    drawingLayer.visibilityState.value = originalLayer.visibilityState.value;
    _layers.value = layerList;
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDelete);
    }
  }

  void _deleteRampFromLayers({required final KPalRampData ramp})
  {
    for (final LayerState layer in _layers.value)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.deleteRamp(ramp: ramp);
      }

    }
  }

  void _deleteAllRampsFromLayers()
  {
    for (final LayerState layer in _layers.value)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        for (final KPalRampData kPalRampData in _colorRamps.value)
        {
          drawingLayer.deleteRamp(ramp: kPalRampData);
        }
        drawingLayer.doManualRaster = true;
      }
    }
  }

  void _remapLayers({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    for (final LayerState layer in _layers.value)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.remapSingleRamp(newData: newData, map: map);
      }
    }
  }

  void _reRaster()
  {
    for (final LayerState layer in _layers.value)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        drawingLayer.doManualRaster = true;
      }
    }
  }

  void colorSelected({required final ColorReference? color, final bool addToHistory = true})
  {
    if (_selectedColor.value != color)
    {
      _selectedColor.value = color;
      if (addToHistory)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.colorChange);
      }

      if (!Tool.isDrawTool(type: _selectedTool.value))
      {
        setToolSelection(tool: _previousDrawTool);
      }
    }
  }


  void setToolSelection({required final ToolType tool, final bool forceSetting = false})
  {
    if (tool != _selectedTool.value || forceSetting)
    {
      for (final ToolType k in _toolMap.keys)
      {
        final bool shouldSelect = (k == tool);
        if (_toolMap[k] != shouldSelect)
        {
          _toolMap[k] = shouldSelect;
        }
      }
      if (Tool.isDrawTool(type: tool))
      {
        _previousDrawTool = tool;
      }
      _selectedTool.value = tool;
      _currentToolOptions = prefs.toolOptions.toolOptionMap[_selectedTool.value]!;
    }
  }

  void _setSelectionToolSelection({required final SelectShape shape})
  {
    setToolSelection(tool: ToolType.select);
    //should always be the case
    if (_currentToolOptions is SelectOptions)
    {
      final SelectOptions selectOptions = _currentToolOptions as SelectOptions;
      selectOptions.shape.value = shape;
    }
  }

  void canvasTransform({required final CanvasTransformation transformation})
  {
    selectionState.deselect(addToHistoryStack: false, notify: false);
    final List<LayerState> layerList = <LayerState>[];
    DrawingLayerState? currentTransformLayer;
    for (final LayerState layer in _layers.value)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        final DrawingLayerState transformLayer = drawingLayer.getTransformedLayer(transformation: transformation);
        layerList.add(transformLayer);
        if (layer == currentLayer)
        {
          currentTransformLayer = transformLayer;
        }
      }
      else
      {
        layerList.add(layer);
      }
    }
    _layers.value = layerList;
    _currentLayer.value = currentTransformLayer;
    if (currentTransformLayer != null)
    {
      currentTransformLayer.isSelected.value = true;
      selectionState.selection.changeLayer(oldLayer: null, newLayer: currentTransformLayer);
    }
    if (transformation == CanvasTransformation.rotate)
    {
      _setCanvasDimensions(width: _canvasSize.y, height: _canvasSize.x);
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.canvasRotate);
    }
    else if (transformation == CanvasTransformation.flipH)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.canvasFlipH);
    }
    else if (transformation == CanvasTransformation.flipV)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.canvasFlipV);
    }
  }

  void cropToSelection()
  {
    CoordinateSetI? topLeft;
    CoordinateSetI? bottomRight;
    (topLeft, bottomRight) = selectionState.selection.getBoundingBox(canvasSize: _canvasSize);
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
    selectionState.deselect(addToHistoryStack: false, notify: false);
    final List<LayerState> layerList = <LayerState>[];
    LayerState? currentCropLayer;
    for (final LayerState layer in _layers.value)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        final DrawingLayerState cropLayer = drawingLayer.getResizedLayer(newSize: newSize, offset: offset);
        layerList.add(cropLayer);
        if (layer == currentLayer)
        {
          currentCropLayer = cropLayer;
        }
      }
      else
      {
        if (layer.runtimeType == GridLayerState)
        {
          final GridLayerState gridLayer = layer as GridLayerState;
          gridLayer.manualRender();
        }
        layerList.add(layer);
        if (layer == currentLayer)
        {
          currentCropLayer = layer;
        }
      }

    }
    _layers.value = layerList;
    _currentLayer.value = currentCropLayer;
    if (currentCropLayer != null)
    {
      currentCropLayer.isSelected.value = true;
      selectionState.selection.changeLayer(oldLayer: null, newLayer: currentCropLayer);
    }
    _setCanvasDimensions(width: newSize.x, height: newSize.y);
  }


  void showMessage({required final String text})
  {
    toastification.showCustom(
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 3),
        builder: (final BuildContext context, final ToastificationItem holder) {
          const double padding = 8.0;
          return Container(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.only(left: padding, right: padding, top: padding, bottom: padding * 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
              border: Border(
                left: BorderSide(color: Theme.of(context).primaryColor, width: 2.0,),
                right: BorderSide(color: Theme.of(context).primaryColor, width: 2.0,),
                top: BorderSide(color: Theme.of(context).primaryColor, width: 2.0,),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
            ),
            child: Text(
              text,
              softWrap: true,
              style: Theme.of(context).textTheme.titleMedium,),
          );
        },
      animationBuilder: (final BuildContext context, final Animation<double> animation, final Alignment alignment, final Widget? child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: const Offset(0, 0.25), //this is hacky
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),),
          child: child,
        );
      },
    );
  }

  void importFile({required final ImportResult importResult})
  {
    if (importResult.data != null)
    {
      final DrawingLayerState drawingLayer = importResult.data!.drawingLayer;
      final ReferenceLayerState? referenceLayer = importResult.data!.referenceLayer;
      _setCanvasDimensions(width: drawingLayer.size.x, height: drawingLayer.size.y, addToHistoryStack: false);
      drawingLayer.isSelected.value = true;
      final List<LayerState> layerList = <LayerState>[];
      layerList.add(drawingLayer);
      if (referenceLayer != null)
      {
        layerList.add(referenceLayer);
      }
      _layers.value = layerList;
      selectLayer(newLayer: drawingLayer);
      _colorRamps.value = importResult.data!.rampDataList;
      _selectedColor.value = _colorRamps.value[0].references[0];
      GetIt.I.get<HistoryManager>().clear();
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.initial, setHasChanges: false);
      projectName.value = null;
      hasChanges.value = false;
      hasProjectNotifier.value = true;
      GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
    }
    showMessage(text: importResult.message);
  }

}
