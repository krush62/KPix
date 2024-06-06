import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/selection_state.dart';
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
  final Map<ToolType, bool> _selectionMap = {};
  final ValueNotifier<IdColor?> selectedColor = ValueNotifier(IdColor(color: Colors.black, uuid: ""));
  final ValueNotifier<List<LayerState>> layers = ValueNotifier([]);
  final RepaintNotifier repaintNotifier = RepaintNotifier();
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();


  static final List<int> zoomLevels = [100, 200, 300, 400, 600, 800, 1000, 1200, 1400, 1600, 2000, 2400, 2800, 3200, 4800, 6400, 8000];
  int _zoomLevelIndex = 0;
  int _zoomFactor = 1;

  //StatusBar
  final ValueNotifier<String?> statusBarDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarCursorPositionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarZoomFactorString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDiagonalString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAspectRatioString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAngleString = ValueNotifier(null);

  int canvasWidth = 0;
  int canvasHeight = 0;
  late SelectionState selectionState = SelectionState(repaintNotifier: repaintNotifier);

  AppState()
  {
    for (ToolType toolType in toolList.keys)
    {
      _selectionMap[toolType] = false;
    }
    setToolSelection(ToolType.pencil);
    setStatusBarZoomFactor(getZoomLevel());
  }

  void setCanvasDimensions({required int width, required int height})
  {
    canvasWidth = width;
    canvasHeight = height;
    setStatusBarDimensions(width, height);
  }

  int getZoomFactor()
  {
    return _zoomFactor;
  }

  int getZoomLevel()
  {
    return zoomLevels[_zoomLevelIndex];
  }

  bool increaseZoomLevel()
  {
    bool changed = false;
    if (_zoomLevelIndex < zoomLevels.length - 1)
    {
      _zoomLevelIndex++;
      _updateZoomFactor();
      changed = true;
    }
    return changed;
  }

  bool decreaseZoomLevel()
  {
    bool changed = false;
    if (_zoomLevelIndex > 0)
    {
      _zoomLevelIndex--;
      _updateZoomFactor();
      changed = true;
    }
    return changed;
  }

  bool setZoomLevelByDistance(final int startZoomLevel, final int steps)
  {
    bool change = false;
    if (steps != 0)
    {
      int endIndex = zoomLevels.indexOf(startZoomLevel) + steps;
      if (endIndex < zoomLevels.length && endIndex >= 0 && endIndex != _zoomLevelIndex)
      {
         _zoomLevelIndex = endIndex;
         _updateZoomFactor();
         change = true;
      }
    }
    return change;
  }

  bool setZoomLevelIndex(final int index)
  {
    bool change = false;
    if (index >= 0 && index < zoomLevels.length && index != _zoomLevelIndex)
    {
      _zoomLevelIndex = index;
      _updateZoomFactor();
      change = true;
    }
    return change;
  }

  void _updateZoomFactor()
  {
    _zoomFactor = getZoomLevel() ~/ 100;
    setStatusBarZoomFactor(getZoomLevel());
  }

  void deleteRamp(final KPalRampData ramp)
  {
    IdColor? col = getSelectedColorFromRampByUuid(ramp);
    if (col != null)
    {
      selectedColor.value = null;
    }
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    rampDataList.remove(ramp);
    colorRamps.value = rampDataList;
  }

  void updateRamp(final KPalRampData ramp)
  {
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    colorRamps.value = rampDataList;
    IdColor? col = getSelectedColorFromRampByUuid(ramp);
    if (col != null)
    {
      selectedColor.value = col;
    }
    repaintNotifier.repaint();
  }

  IdColor? getSelectedColorFromRampByUuid(final KPalRampData ramp)
  {
    IdColor? col;
    for (int j = 0; j < ramp.colors.length; j++)
    {
      if (selectedColor.value != null && ramp.colors[j].value.uuid == selectedColor.value!.uuid)
      {
        col = ramp.colors[j].value;
        break;
      }
    }
    return col;
  }


  void addNewRamp()
  {
    const Uuid uuid = Uuid();
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    rampDataList.add(
      KPalRampData(
        uuid: uuid.v1(),
        settings: KPalRampSettings(
          constraints: prefs.kPalConstraints
        )
      )
    );
    colorRamps.value = rampDataList;
  }

  LayerState addNewLayer({bool select = false, HashMap<CoordinateSetI, ColorReference?>? content})
  {
    List<LayerState> layerList = [];
    LayerState newLayer = LayerState(width: canvasWidth, height: canvasHeight, content: content, color: Colors.primaries[Random().nextInt(Colors.primaries.length)]);
    if (layers.value.isEmpty)
    {
      newLayer.isSelected.value = true;
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
      selectionState.selection.changeLayer(oldLayer, newLayer);
    }

  }

  void layerDeleted(final LayerState deleteState)
  {
    if (layers.value.length > 1)
    {
      List<LayerState> stateList = [];
      int foundIndex = 0;
      for (int i = 0; i < layers.value.length; i++)
      {
        if (layers.value[i] != deleteState)
        {
          stateList.add(layers.value[i]);
        }
        else
        {
          foundIndex = i;
        }
      }

      if (foundIndex > 0)
      {
        stateList[foundIndex - 1].isSelected.value = true;
      }
      else
      {
        stateList[0].isSelected.value = true;
      }

      layers.value = stateList;
    }
  }

  void layerMerged(final LayerState mergeState)
  {
    //TODO


  }

  void layerDuplicated(final LayerState duplicateState)
  {
    List<LayerState> stateList = [];
    for (int i = 0; i < layers.value.length; i++)
    {
      if (layers.value[i] == duplicateState)
      {
        LayerState layerState = LayerState(width: canvasWidth, height: canvasHeight, color: layers.value[i].color.value);
        layerState.lockState.value = layers.value[i].lockState.value;
        layerState.visibilityState.value = layers.value[i].visibilityState.value;
        stateList.add(layerState);
      }
      stateList.add(layers.value[i]);
    }
    layers.value = stateList;
    //shouldRepaint.value = true;
  }

  void colorSelected(final IdColor color)
  {
    selectedColor.value = color;
  }


  void setStatusBarDimensions(final int width, final int height)
  {
    statusBarDimensionString.value = "$width,$height";
  }

  void hideStatusBarDimension()
  {
    statusBarDimensionString.value = null;
  }

  void setStatusBarCursorPosition(final CoordinateSetI coords)
  {
    statusBarCursorPositionString.value = "${coords.x.toString()},${coords.y.toString()}";
  }

  void hideStatusBarCursorPosition()
  {
    statusBarCursorPositionString.value = null;
  }

  void setStatusBarZoomFactor(final int zoomFactor)
  {
    statusBarZoomFactorString.value = "$zoomFactor%";
  }

  void hideStatusBarZoomFactor()
  {
    statusBarZoomFactorString.value = null;
  }

  void setStatusBarToolDimension(final int width, final int height)
  {
    statusBarToolDimensionString.value = "$width,$height";
  }

  void hideStatusBarToolDimension()
  {
    statusBarToolDimensionString.value = null;
  }

  void setStatusBarToolDiagonal(final int width, final int height)
  {
    final double result = sqrt((width * width).toDouble() + (height * height).toDouble());
    statusBarToolDiagonalString.value = result.toStringAsFixed(1);  }

  void hideStatusBarToolDiagonal()
  {
    statusBarToolDiagonalString.value = null;
  }

  void setStatusBarToolAspectRatio(final int width, final int height)
  {
    final int divisor = Helper.gcd(width, height);
    final int reducedWidth = divisor != 0 ? width ~/ divisor : 0;
    final int reducedHeight = divisor != 0 ? height ~/ divisor : 0;
    statusBarToolAspectRatioString.value = '$reducedWidth:$reducedHeight';
  }

  void hideStatusBarToolAspectRatio()
  {
    statusBarToolAspectRatioString.value = null;
  }

  void setStatusBarToolAngle(final CoordinateSetI startPos, final CoordinateSetI endPos)
  {
    double angle = Helper.calculateAngle(startPos, endPos);
    statusBarToolAngleString.value = "${angle.toStringAsFixed(1)}°";
  }

  void hideStatusBarToolAngle()
  {
    statusBarToolAngleString.value = null;
  }

  //TODO TEMP
  void changeTool(ToolType t)
  {
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
}


