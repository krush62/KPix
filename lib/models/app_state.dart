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
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_dither_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/util/layer_color_supplier.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/util/update_helper.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/main/symmetry_widget.dart';
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

  final Timeline timeline = Timeline.empty();

  final ValueNotifier<bool> layerSettingsVisibleNotifier = ValueNotifier<bool>(false);


  bool get layerSettingsVisible
  {
      return layerSettingsVisibleNotifier.value;
  }

  set layerSettingsVisible(final bool newVisibility)
  {
    layerSettingsVisibleNotifier.value = newVisibility;
  }

  ColorReference? getColorFromImageAtPosition({required final CoordinateSetI normPos})
  {
    if (timeline.selectedFrame != null)
    {
      return timeline.selectedFrame!.layerList.getColorFromImageAtPosition(normPos: normPos, selectionReference: selectionState.selection.getColorReference(coord: normPos), rawMode: GetIt.I.get<PreferenceManager>().toolOptions.colorPickOptions.rawMode.value);
    }
    else
    {
      return null;
    }
  }


  /*
    int getPixelCountForRamp({required final KPalRampData ramp, final bool includeInvisible = true})
  {
    int pixelCount = 0;
    for (final LayerState layer in _layers)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        if (includeInvisible || drawingLayer.visibilityState.value == LayerVisibilityState.visible)
        {
          pixelCount += drawingLayer.getPixelCountForRamp(ramp: ramp);
        }
      }
    }
    return pixelCount;
  }


   */

  int getPixelCountForRamp({required final KPalRampData ramp, final bool includeInvisible = true})
  {
    int pixelCount = 0;
    final List<Frame> allFrames = timeline.frames.value;
    final LinkedHashSet<LayerState> originalLayerSet = LinkedHashSet<LayerState>();
    for (final Frame f in allFrames)
    {
      final LayerCollection layers = f.layerList;
      for (int i = 0; i < layers.length; i++)
      {
        originalLayerSet.add(layers.getLayer(index: i));
      }
    }

    for (final LayerState layer in originalLayerSet)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = layer as DrawingLayerState;
        if (includeInvisible || drawingLayer.visibilityState.value == LayerVisibilityState.visible)
        {
          pixelCount += drawingLayer.getPixelCountForRamp(ramp: ramp);
        }
      }
    }
    return pixelCount;
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

  final double devicePixelRatio;

  final SymmetryState symmetryState = SymmetryState();


  AppState({required final String exportDir, required final String internalDir, required this.devicePixelRatio}) : _exportDir = ValueNotifier<String>(exportDir), _internalDir = ValueNotifier<String>(internalDir), _hasUpdate = ValueNotifier<bool>(false)
  {
    for (final ToolType toolType in toolList.keys)
    {
      _toolMap[toolType] = false;
    }
    setToolSelection(tool: ToolType.pencil, forceSetting: true);
    statusBarState.setStatusBarZoomFactor(val: _zoomFactor.value * 100);
    timeline.layerChangeNotifier.addListener((){
      layerSettingsVisible = false;
      resetColorSupplier();
    });
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
    hotkeyManager.addListener(func: () {changeLayerVisibility(layerState: timeline.getCurrentLayer());}, action: HotkeyAction.layersSwitchVisibility);
    hotkeyManager.addListener(func: () {changeLayerLockState(layerState: timeline.getCurrentLayer());}, action: HotkeyAction.layersSwitchLock);
    hotkeyManager.addListener(func: addNewDrawingLayer, action: HotkeyAction.layersNewDrawing);
    hotkeyManager.addListener(func: addNewReferenceLayer, action: HotkeyAction.layersNewReference);
    hotkeyManager.addListener(func: addNewShadingLayer, action: HotkeyAction.layersNewShading);
    hotkeyManager.addListener(func: addNewGridLayer, action: HotkeyAction.layersNewGrid);
    hotkeyManager.addListener(func: () {layerDuplicateSelected(duplicateLayer: timeline.getCurrentLayer());}, action: HotkeyAction.layersDuplicate);
    hotkeyManager.addListener(func: () {layerDeletedSelected(deleteLayer: timeline.getCurrentLayer());}, action: HotkeyAction.layersDelete);
    hotkeyManager.addListener(func: () {layerMerged(mergeLayer: timeline.getCurrentLayer());}, action: HotkeyAction.layersMerge);
    hotkeyManager.addListener(func: () {moveUpLayer(layerState: timeline.getCurrentLayer());}, action: HotkeyAction.layersMoveUp);
    hotkeyManager.addListener(func: () {moveDownLayer(layerState: timeline.getCurrentLayer());}, action: HotkeyAction.layersMoveDown);
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
    symmetryState.reset();
    selectionState.deselect(addToHistoryStack: false, notify: false);
    //_layerCollection.clear();
    _setDefaultPalette();
    //addNewDrawingLayer(select: true, addToHistoryStack: false);
    timeline.init(appState: this);
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
    symmetryState.newCanvasDimensions(newSize: _canvasSize);
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
      for (final Frame f in timeline.frames.value)
      {
        f.layerList.deleteRampFromLayers(ramp: ramp, backupColor: rampDataList[0].references[0]);
      }
      rasterLayersAll();
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

    if (ramp.references.length != originalData.references.length)
    {
      final HashMap<int, int> indexMap = remapIndices(oldLength: originalData.references.length, newLength: ramp.references.length);
      _selectedColor.value = ramp.references[indexMap[_selectedColor.value!.colorIndex]!];
      for (final Frame f in timeline.frames.value)
      {
        f.layerList.remapLayers(newData: ramp, map: indexMap);
      }

    }
    rasterLayersAll();
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

  Future<KPalRampData?> addNewRamp({final bool addToHistoryStack = true}) async
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
      return newRamp;
    }
    else
    {
      showMessage(text: "Not more than ${constraints.rampCountMax} color ramps allowed!");
      return null;
    }
  }

  ReferenceLayerState? addNewReferenceLayer({final bool addToHistoryStack = true, final bool select = false})
  {
    if (timeline.selectedFrame != null)
    {
      final ReferenceLayerState? newLayer = timeline.selectedFrame!.layerList.addNewReferenceLayer(select: select);
      if (newLayer != null)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewReference);
        }
        timeline.layerChangeNotifier.reportChange();
        return newLayer;
      }
      else
      {
        return null;
      }
    }
    else
    {
      return null;
    }
  }

  ShadingLayerState? addNewShadingLayer({final bool addToHistoryStack = true, final bool select = false})
  {
    if (timeline.selectedFrame != null)
    {
      final ShadingLayerState? newLayer = timeline.selectedFrame!.layerList.addNewShadingLayer(select: select);
      if (newLayer != null)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewShading);
        }
        timeline.layerChangeNotifier.reportChange();
        return newLayer;
      }
      else
      {
        return null;
      }
    }
    else
    {
      return null;
    }
  }

  DitherLayerState? addNewDitherLayer({final bool addToHistoryStack = true, final bool select = false})
  {
    if (timeline.selectedFrame != null)
    {
      final DitherLayerState? newLayer = timeline.selectedFrame!.layerList.addNewDitherLayer(select: select);
      if (newLayer != null)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewDither);
        }
        timeline.layerChangeNotifier.reportChange();
        return newLayer;
      }
      else
      {
        return null;
      }
    }
    else
    {
      return null;
    }
  }

  GridLayerState? addNewGridLayer({final bool addToHistoryStack = true, final bool select = false})
  {
    if (timeline.selectedFrame != null)
    {
      final GridLayerState? newLayer = timeline.selectedFrame!.layerList.addNewGridLayer(select: select);
      if (newLayer != null)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewGrid);
        }
        timeline.layerChangeNotifier.reportChange();
        return newLayer;
      }
      else
      {
        return null;
      }
    }
    else
    {
      return null;
    }
  }

  DrawingLayerState? addNewDrawingLayer({final bool addToHistoryStack = true, final bool select = false, final CoordinateColorMapNullable? content})
  {
    if (timeline.selectedFrame != null)
    {
      final bool setSelectionStateLayer = timeline.selectedFrame!.layerList.isEmpty;
      final DrawingLayerState? newLayer = timeline.selectedFrame!.layerList.addNewDrawingLayer(canvasSize: _canvasSize, select: select, content: content, ramps: colorRamps);
      if (newLayer != null)
      {
        if (setSelectionStateLayer)
        {
          selectionState.selection.changeLayer(oldLayer: null, newLayer: newLayer);
        }
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerNewDrawing);
        }
        timeline.layerChangeNotifier.reportChange();
        return newLayer;
      }
      else
      {
        return null;
      }
    }
    else
    {
      return null;
    }
  }

  void newFrameAdded({final bool addToHistoryStack = true})
  {
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.timelineFrameAdd);
    }
  }

  void frameDeleted({final bool addToHistoryStack = true})
  {
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.timelineFrameDelete);
    }
  }

  void frameMoved({final bool addToHistoryStack = true})
  {
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.timelineFrameMove);
    }
  }

  void frameTimingChanged({final bool addToHistoryStack = true})
  {
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.timelineFrameTimeChange);
    }
  }

  void loopMarkerChanged({final bool addToHistoryStack = true})
  {
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.timelineLoopMarkerChange);
    }
  }

  void undoPressed()
  {
    if (GetIt.I.get<HistoryManager>().hasUndo.value && !timeline.isPlaying.value)
    {
      showMessage(text: "Undo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
      final HistoryState? currentState = GetIt.I.get<HistoryManager>().getCurrentState();
      final HistoryStateTypeGroup typeGroup = currentState != null ? currentState.type.group : HistoryStateTypeGroup.full;
      _restoreState(historyState: GetIt.I.get<HistoryManager>().undo(), typeGroup: typeGroup);
    }
  }

  void redoPressed()
  {
    if (GetIt.I.get<HistoryManager>().hasRedo.value && !timeline.isPlaying.value)
    {
      final HistoryState? switchState = GetIt.I.get<HistoryManager>().redo();
      final HistoryStateTypeGroup typeGroup = switchState != null ? switchState.type.group : HistoryStateTypeGroup.full;
      _restoreState(historyState: switchState, typeGroup: typeGroup);
      showMessage(text: "Redo: ${GetIt.I.get<HistoryManager>().getCurrentDescription()}");
    }
  }

  void restoreFromFile({required final LoadFileSet loadFileSet, final bool setHasChanges = false})
  {
    if (loadFileSet.historyState != null && loadFileSet.path != null)
    {
      _restoreState(historyState: loadFileSet.historyState, typeGroup: HistoryStateTypeGroup.full).then((final void value)
      {
        final String projectNameExtracted = extractFilenameFromPath(path: loadFileSet.path, keepExtension: false);
        projectName.value = projectNameExtracted == recoverFileName ? null : projectNameExtracted;
        hasChanges.value = setHasChanges;
        hasProjectNotifier.value = true;
        GetIt.I.get<HistoryManager>().clear();
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.initial, setHasChanges: setHasChanges);
        _setCanvasDimensions(width: loadFileSet.historyState!.canvasSize.x , height: loadFileSet.historyState!.canvasSize.y, addToHistoryStack: false);
        symmetryState.reset();
        GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
        if (loadFileSet.status.isNotEmpty)
        {
          showMessage(text: loadFileSet.status);
        }
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
      final LinkedHashSet<LayerState> collectedLayers = LinkedHashSet<LayerState>();
      for (final Frame f in timeline.frames.value)
      {
        final LayerCollection layers = f.layerList;
        for (int i = 0; i < layers.length; i++)
        {
          collectedLayers.add(layers.getLayer(index: i));
        }
      }

      final HashMap<ColorReference, ColorReference> rampMap = getRampMap(rampList1: colorRamps, rampList2: loadPaletteSet.rampData!);

      for (final LayerState layer in collectedLayers)
      {
        if (layer.runtimeType == DrawingLayerState)
        {
          final DrawingLayerState drawingLayer = layer as DrawingLayerState;
          if (paletteReplaceBehavior == PaletteReplaceBehavior.replace)
          {
            for (final KPalRampData kPalRampData in colorRamps)
            {
              drawingLayer.deleteRamp(ramp: kPalRampData);
            }
            drawingLayer.resetLayerEffectColors(newColor: loadPaletteSet.rampData!.first.references.first);
          }
          else
          {
            drawingLayer.remapAllColors(rampMap: rampMap);
            drawingLayer.remapLayerEffectColors(rampMap: rampMap);
          }
          drawingLayer.doManualRaster = true;
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

  void appendPalette({required final LoadPaletteSet loadPaletteSet})
  {
    if (loadPaletteSet.rampData != null && loadPaletteSet.rampData!.isNotEmpty)
    {
      final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
      for (final KPalRampData ramp in loadPaletteSet.rampData!)
      {
        rampDataList.add(ramp);
      }
      _colorRamps.value = rampDataList;
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.kPalAdd);
    }
    else
    {
      showMessage(text: "Appending palette failed (${loadPaletteSet.status})");
    }
  }

  void fileSaved({required final String saveName, required final String path, final bool addKPixExtension = false})
  {
    projectName.value = saveName;
    hasChanges.value = false;

    String displayPath = kIsWeb ? "$path/$saveName" : path;
    if (addKPixExtension)
    {
      displayPath += ".$fileExtensionKpix";
    }
    showMessage(text: "File saved at: $displayPath");
  }


  Future<void> _restoreState({required final HistoryState? historyState, required final HistoryStateTypeGroup typeGroup}) async
  {
    if (historyState != null)
    {
      //COLLECT ORIGINAL LAYERS
      final LinkedHashSet<LayerState> collectedLayers = LinkedHashSet<LayerState>();
      for (final Frame f in timeline.frames.value)
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
          _colorRamps.value = ramps;
        }
        final ColorReference selCol = _colorRamps.value[historyState.selectedColor.rampIndex].references[historyState.selectedColor.colorIndex];
        _selectedColor.value = selCol;
      }

      if (typeGroup == HistoryStateTypeGroup.full || typeGroup == HistoryStateTypeGroup.layerFull)
      {
        //RESTORE LAYERS
        final LinkedHashSet<HistoryLayer> allHistoryLayers = historyState.timeline.allLayers;
        final List<LayerState> allLayers = <LayerState>[];
        int layerCounter = 0;
        for (final HistoryLayer hLayer in allHistoryLayers)
        {
          if (historyState.restoreLayerIndex != null && typeGroup == HistoryStateTypeGroup.layerFull && historyState.restoreLayerIndex != layerCounter && collectedLayers.length == allHistoryLayers.length)
          {
            allLayers.add(collectedLayers.elementAt(layerCounter));
          }
          else
          {
            LayerState? layerState;
            if (hLayer is HistoryDrawingLayer)
            {
              final CoordinateColorMap content = HashMap<CoordinateSetI, ColorReference>();
              for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in hLayer.data.entries)
              {
                KPalRampData? ramp;
                for (int i = 0; i < colorRamps.length; i++)
                {
                  if (colorRamps[i].uuid == historyState.rampList[entry.value.rampIndex].uuid)
                  {
                    ramp = colorRamps[i];
                    break;
                  }
                }
                if (ramp != null)
                {
                  content[CoordinateSetI.from(other: entry.key)] = ColorReference(colorIndex: entry.value.colorIndex, ramp: ramp);
                }
              }
              final DrawingLayerSettings drawingLayerSettings = DrawingLayerSettings(
                constraints: hLayer.settings.constraints,
                outerStrokeStyle: hLayer.settings.outerStrokeStyle,
                outerSelectionMap: hLayer.settings.outerSelectionMap,
                outerColorReference: _colorRamps.value[hLayer.settings.outerColorReference.rampIndex].references[hLayer.settings.outerColorReference.colorIndex],
                outerDarkenBrighten: hLayer.settings.outerDarkenBrighten,
                outerGlowDepth: hLayer.settings.outerGlowDepth,
                outerGlowRecursive: hLayer.settings.outerGlowRecursive,
                innerStrokeStyle: hLayer.settings.innerStrokeStyle,
                innerSelectionMap: hLayer.settings.innerSelectionMap,
                innerColorReference: _colorRamps.value[hLayer.settings.innerColorReference.rampIndex].references[hLayer.settings.innerColorReference.colorIndex],
                innerDarkenBrighten: hLayer.settings.innerDarkenBrighten,
                innerGlowDepth: hLayer.settings.innerGlowDepth,
                innerGlowRecursive: hLayer.settings.innerGlowRecursive,
                bevelDistance: hLayer.settings.bevelDistance,
                bevelStrength: hLayer.settings.bevelStrength,
                dropShadowStyle: hLayer.settings.dropShadowStyle,
                dropShadowColorReference: _colorRamps.value[hLayer.settings.dropShadowColorReference.rampIndex].references[hLayer.settings.dropShadowColorReference.colorIndex],
                dropShadowOffset: hLayer.settings.dropShadowOffset,
                dropShadowDarkenBrighten: hLayer.settings.dropShadowDarkenBrighten,);
              final DrawingLayerState drawingLayer = DrawingLayerState(size: canvSize, content: content, drawingLayerSettings: drawingLayerSettings, ramps: colorRamps);
              drawingLayer.lockState.value = hLayer.lockState;
              layerState = drawingLayer;
            }
            else if (hLayer.runtimeType == HistoryReferenceLayer)
            {
              final HistoryReferenceLayer referenceLayer = hLayer as HistoryReferenceLayer;
              layerState = ReferenceLayerState(zoom: referenceLayer.zoom, opacity: referenceLayer.opacity, offsetX: referenceLayer.offsetX, offsetY: referenceLayer.offsetY, image: await GetIt.I.get<ReferenceImageManager>().loadImageFile(path: referenceLayer.path), aspectRatio: referenceLayer.aspectRatio);
            }
            else if (hLayer.runtimeType == HistoryGridLayer)
            {
              final HistoryGridLayer gridLayer = hLayer as HistoryGridLayer;
              layerState = GridLayerState(opacity: gridLayer.opacity, brightness: gridLayer.brightness, gridType: gridLayer.gridType, intervalX: gridLayer.intervalX, intervalY: gridLayer.intervalY, horizonPosition: gridLayer.horizonPosition, vanishingPoint1: gridLayer.vanishingPoint1, vanishingPoint2: gridLayer.vanishingPoint2, vanishingPoint3: gridLayer.vanishingPoint3 );
            }
            else if (hLayer.runtimeType == HistoryShadingLayer)
            {
              final HistoryShadingLayer shadingLayer = hLayer as HistoryShadingLayer;
              final ShadingLayerSettings shadingLayerSettings = ShadingLayerSettings(constraints: shadingLayer.settings.constraints, shadingLow: shadingLayer.settings.shadingLow, shadingHigh: shadingLayer.settings.shadingHigh,);
              layerState = ShadingLayerState.withData(data: shadingLayer.data, lState: shadingLayer.lockState, newSettings: shadingLayerSettings);
            }
            else if (hLayer.runtimeType == HistoryDitherLayer)
            {
              final HistoryDitherLayer ditherLayer = hLayer as HistoryDitherLayer;
              final ShadingLayerSettings shadingLayerSettings = ShadingLayerSettings(constraints: ditherLayer.settings.constraints, shadingLow: ditherLayer.settings.shadingLow, shadingHigh: ditherLayer.settings.shadingHigh,);
              layerState = DitherLayerState.withData(data: ditherLayer.data, lState: ditherLayer.lockState, newSettings: shadingLayerSettings);
            }

            if (layerState != null)
            {
              layerState.visibilityState.value = hLayer.visibilityState;
              allLayers.add(layerState);
            }
          }

          layerCounter++;
        }

        final List<Frame> frames = <Frame>[];
        for (final HistoryFrame hFrame in historyState.timeline.frames)
        {
          final List<LayerState> layerList = <LayerState>[];
          for (final int hLayerIndex in hFrame.layerIndices)
          {
            layerList.add(allLayers[hLayerIndex]);
          }
          final LayerCollection layerCollection = LayerCollection(layers: layerList, selLayerIdx: hFrame.selectedLayerIndex);
          final Frame frame = Frame(layerList: layerCollection, fps: hFrame.fps);
          frames.add(frame);
        } //end frame loop

        timeline.setData(selectedFrameIndex: historyState.timeline.selectedFrameIndex, frames: frames, loopStartIndex: historyState.timeline.loopStart, loopEndIndex: historyState.timeline.loopEnd);


        //SELECTION
        final CoordinateColorMapNullable selectionContent = HashMap<CoordinateSetI, ColorReference?>();
        for (final MapEntry<CoordinateSetI, HistoryColorReference?> entry in historyState.selectionState.content.entries)
        {
          if (entry.value != null)
          {
            selectionContent[CoordinateSetI.from(other: entry.key)] = _colorRamps.value[entry.value!.rampIndex].references[entry.value!.colorIndex];
          }
          else
          {
            selectionContent[CoordinateSetI.from(other: entry.key)] = null;
          }
        }
        selectionState.selection.delete(keepSelection: false);
        selectionState.selection.addDirectlyAll(list: selectionContent);
        selectionState.createSelectionLines();
        selectionState.notifyRepaint();

        if (canvSize.x != _canvasSize.x || canvSize.y != _canvasSize.y)
        {
          _canvasSize.x = canvSize.x;
          _canvasSize.y = canvSize.y;
        }

        bool aLayerIsRastering = false;
        do
        {
          aLayerIsRastering = false;
          for (final LayerState layer in allLayers)
          {
            if (layer is RasterableLayerState)
            {
              if (layer.isRasterizing)
              {
                aLayerIsRastering = true;
                break;
              }
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        while (aLayerIsRastering);

        timeline.layerChangeNotifier.reportChange();
        if (typeGroup == HistoryStateTypeGroup.layerFull && historyState.restoreLayerIndex != null && historyState.restoreLayerIndex! >= 0 && historyState.restoreLayerIndex! < allLayers.length)
        {
          final LayerState restoreLayer = allLayers[historyState.restoreLayerIndex!];
          if (restoreLayer is RasterableLayerState)
          {
            restoreLayer.doManualRaster = true;
          }
          else
          {
            rasterLayersAll();
          }
        }
        else
        {
          rasterLayersAll();
        }
      }
      else if (typeGroup == HistoryStateTypeGroup.layerSelect)
      {
        timeline.selectFrameByIndex(index: historyState.timeline.selectedFrameIndex, layerIndex: historyState.timeline.frames[historyState.timeline.selectedFrameIndex].selectedLayerIndex, addLayerSelectionToHistory: false);
      }
    }
  }



  void moveUpLayer({required final LayerState? layerState})
  {
    if (layerState != null)
    {
      final Frame? frame = timeline.selectedFrame;
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
      final Frame? frame = timeline.selectedFrame;
      if (frame != null && frame.layerList.contains(layer: layerState))
      {
        final int? sourcePosition = frame.layerList.getLayerPosition(state: layerState);
        if (sourcePosition != null && sourcePosition < (timeline.selectedFrame!.layerList.length - 1))
        {
          changeLayerOrder(state: layerState, newPosition: sourcePosition + 2);
        }
      }
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

  void changeLayerOrder({required final LayerState? state, required final int newPosition, final bool addToHistoryStack = true})
  {
    final Frame? frame = timeline.selectedFrame;
    if (state != null && frame != null)
    {
      final bool orderChanged = frame.layerList.changeLayerOrder(state: state, newPosition: newPosition);
      if (orderChanged)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerOrderChange);
        }
        timeline.layerChangeNotifier.reportChange();
        rasterLayersFrame();
      }
    }
  }

  void copyLayerToOtherFrame({required final LayerState sourceLayer, required final Frame targetFrame, required final int position, final bool addToHistoryStack = true})
  {
      selectionState.deselect(addToHistoryStack: false);
      final LayerState? addLayer = targetFrame.layerList.addLayerWithData(layer: sourceLayer, position: position);
      if (addLayer != null)
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDuplicate);
        }
        newRasterData(layer: addLayer);
        timeline.layerChangeNotifier.reportChange();
        timeline.selectFrame(frame: targetFrame, layerIndex: position);
      }
  }

  void linkLayerToOtherFrame({required final LayerState sourceLayer, required final Frame targetFrame, required final int position, final bool addToHistoryStack = true})
  {
    selectionState.deselect(addToHistoryStack: false);
    targetFrame.layerList.addLinkLayer(layer: sourceLayer, position: position);

    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDuplicate);
    }
    newRasterData(layer: sourceLayer);
    timeline.layerChangeNotifier.reportChange();
    timeline.selectFrame(frame: targetFrame, layerIndex: position);
  }


  void changeColorOrder({required final KPalRampData ramp, required final int newPosition, final bool addToHistoryStack = true})
  {
    final int sourcePosition = _colorRamps.value.indexOf(ramp);
    if (sourcePosition != newPosition && (sourcePosition + 1) != newPosition)
    {
      final List<KPalRampData> newListOfRamps = <KPalRampData>[];
      newListOfRamps.addAll(_colorRamps.value);

      newListOfRamps.removeAt(sourcePosition);
      if (newPosition > sourcePosition)
      {
        newListOfRamps.insert(newPosition - 1, ramp);
      }
      else
      {
        newListOfRamps.insert(newPosition, ramp);
      }
      _colorRamps.value = newListOfRamps;
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.kPalOrderChange);
    }
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
      newRasterData(layer: layerState);
      GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerVisibilityChange, originLayer: layerState);
    }
  }

  void changeLayerLockState({required final LayerState? layerState})
  {
    if (layerState != null)
    {
      bool lockStateChanged = false;
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
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerLockChange, originLayer: layerState);
      }
    }
  }


  void selectLayerAbove()
  {
    if (timeline.selectedFrame != null)
    {
      timeline.selectedFrame!.layerList.selectLayerAbove();
    }
  }

  void selectLayerBelow()
  {
    if (timeline.selectedFrame != null)
    {
      timeline.selectedFrame!.layerList.selectLayerBelow();
    }
  }


  void selectLayer({required final LayerState newLayer, LayerState? oldLayer, final bool addToHistoryStack = true})
  {
    if (timeline.selectedFrame != null)
    {
      final LayerState? previousLayer = timeline.selectedFrame!.layerList.selectLayer(newLayer: newLayer);
      timeline.layerChangeNotifier.reportChange();
      oldLayer ??= previousLayer;
      if (oldLayer != newLayer)
      {
        selectionState.selection.changeLayer(oldLayer: oldLayer, newLayer: newLayer);
      }
      if (addToHistoryStack && oldLayer != null)
      {

        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerChange);
      }
    }
  }

  void layerDeletedSelected({required final LayerState? deleteLayer, final bool addToHistoryStack = true})
  {
    if (deleteLayer != null && timeline.selectedFrame != null)
    {
      if (timeline.selectedFrame!.layerList.deleteLayer(deleteLayer: deleteLayer))
      {
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDelete);
        }
      }
      else
      {
        showMessage(text: "Cannot delete the layer!");
      }
      timeline.layerChangeNotifier.reportChange();
      rasterLayersAll();
    }
  }

  void layerMerged({required final LayerState? mergeLayer, final bool addToHistoryStack = true})
  {
    final Frame? frame = timeline.selectedFrame;
    if (mergeLayer != null && frame != null)
    {
      final String? message = frame.layerList.layerIsMergeable(mergeLayer: mergeLayer);
      if (message == null)
      {
        selectionState.deselect(addToHistoryStack: false);
        frame.layerList.mergeLayer(mergeLayer: mergeLayer, canvasSize: _canvasSize);
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerMerge);
        }
        rasterLayersFrame();
        timeline.layerChangeNotifier.reportChange();
      }
      else
      {
        showMessage(text: message);
      }
    }
  }

  LayerState? layerDuplicateSelected({required final LayerState? duplicateLayer, final bool addToHistoryStack = true})
  {
    LayerState? generatedLayer;
    final Frame? frame = timeline.selectedFrame;
    if (duplicateLayer != null && frame != null)
    {
      selectionState.deselect(addToHistoryStack: false);
      generatedLayer = frame.layerList.duplicateLayer(duplicateLayer: duplicateLayer);
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerDuplicate);
      }
      newRasterData(layer: duplicateLayer);
      timeline.layerChangeNotifier.reportChange();
    }
    return generatedLayer;
  }

  void layerRasterPressed({required final LayerState rasterLayer, final bool addToHistoryStack = true})
  {
    final Frame? frame = timeline.selectedFrame;
    if (frame != null)
    {
      frame.layerList.rasterLayer(rasterLayer: rasterLayer, canvasSize: canvasSize, ramps: colorRamps);
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: this, identifier: HistoryStateTypeIdentifier.layerRaster);
      }
      timeline.layerChangeNotifier.reportChange();
    }
  }

  void rasterLayersFrame()
  {
    timeline.selectedFrame?.layerList.reRasterAllDrawingLayers();
  }

  void rasterLayersAll()
  {
    if (timeline.selectedFrame != null)
    {
      //raster current frame first
      rasterLayersFrame();
      final int currentIndex = timeline.selectedFrameIndex;
      for (int i = 0; i < timeline.frames.value.length; i++)
      {
        if (i != currentIndex)
        {
          timeline.frames.value[i].layerList.reRasterAllDrawingLayers();
        }
      }
    }
  }

  void newRasterData({required final LayerState layer})
  {
    final List<Frame> frames = timeline.findFramesForLayer(layer: layer);
    for (final Frame frame in frames)
    {
      frame.layerList.layerRasterDone(layer: layer);
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
    for (final Frame f in timeline.frames.value)
    {
      f.layerList.transformLayers(transformation: transformation, oldSize: canvasSize);
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
    final LinkedHashSet<RasterableLayerState> layerSet = LinkedHashSet<RasterableLayerState>();
    for (final Frame f in timeline.frames.value)
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
    _setCanvasDimensions(width: newSize.x, height: newSize.y);
    rasterLayersAll();
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
      _setCanvasDimensions(width: importResult.data!.canvasSize.x, height: importResult.data!.canvasSize.y, addToHistoryStack: false);
      _colorRamps.value = importResult.data!.rampDataList;
      _selectedColor.value = _colorRamps.value[0].references[0];
      final List<LayerState> layerList = <LayerState>[];
      layerList.add(drawingLayer);
      if (referenceLayer != null)
      {
        layerList.add(referenceLayer);
      }
      final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
      final Frame f = Frame(layerList: LayerCollection(layers: layerList, selLayerIdx: 0), fps: constraints.defaultFps);
      timeline.setData(selectedFrameIndex: 0, frames: <Frame>[f], loopStartIndex: 0, loopEndIndex: 0);
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
