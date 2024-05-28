import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:uuid/uuid.dart';


class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  final ValueNotifier<List<KPalRampData>> colorRamps = ValueNotifier([]);
  final Map<ToolType, bool> _selectionMap = {};
  final ValueNotifier<String> selectedColorId = ValueNotifier("");
  final ValueNotifier<List<LayerState>> layers = ValueNotifier([]);

  static final List<int> _zoomLevels = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 2000, 2400, 3200];
  int _zoomLevelIndex = 0;

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
  //ValueNotifier<bool> shouldRepaint = ValueNotifier(false);

  final KPalConstraints kPalConstraints;

  AppState({required this.kPalConstraints})
  {
    for (ToolType toolType in toolList.keys)
    {
      _selectionMap[toolType] = false;
    }
    setToolSelection(ToolType.pencil);
    setStatusBarZoomFactor(getZoomLevel());

    //TODO TEMP
    setStatusBarDimensions(200, 400);

  }

  void setCanvasDimensions({required int width, required int height})
  {
    canvasWidth = width;
    canvasHeight = height;
    //shouldRepaint.value = true;
  }

  int getZoomLevel()
  {
    return _zoomLevels[_zoomLevelIndex];
  }

  void increaseZoomLevel()
  {
    if (_zoomLevelIndex < _zoomLevels.length - 1)
    {
      _zoomLevelIndex++;
      setStatusBarZoomFactor(getZoomLevel());
      //shouldRepaint.value = true;
    }
  }

  void decreaseZoomLevel()
  {
    if (_zoomLevelIndex > 0)
    {
      _zoomLevelIndex--;
      setStatusBarZoomFactor(getZoomLevel());
      //shouldRepaint.value = true;
    }
  }

  void setZoomLevelByDistance(final int startZoomLevel, final int steps)
  {
    if (steps != 0)
    {
      int endIndex = _zoomLevels.indexOf(startZoomLevel) + steps;
      if (endIndex < _zoomLevels.length && endIndex >= 0 && endIndex != _zoomLevelIndex)
      {
         _zoomLevelIndex = endIndex;
         setStatusBarZoomFactor(getZoomLevel());
         //shouldRepaint.value = true;
      }
    }
  }

  void deleteRamp(final KPalRampData ramp)
  {
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    rampDataList.remove(ramp);
    colorRamps.value = rampDataList;
  }

  void updateRamp(final KPalRampData ramp)
  {
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    colorRamps.value = rampDataList;
  }


  void addNewRamp()
  {
    const Uuid uuid = Uuid();
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    rampDataList.add(
      KPalRampData(
        uuid: uuid.v1(),
        settings: KPalRampSettings(
          constraints: kPalConstraints
        )
      )
    );
    colorRamps.value = rampDataList;
  }

  void addNewLayer()
  {
    List<LayerState> layerList = [];
    layerList.add(LayerState(width: canvasWidth, height: canvasHeight, color: Colors.primaries[Random().nextInt(Colors.primaries.length)], appState: this));
    layerList.addAll(layers.value);
    layers.value = layerList;
    //shouldRepaint.value = true;
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
    //shouldRepaint.value = true;
  }

  void addNewLayerPressed()
  {
    addNewLayer();
  }

  void layerSelected(final LayerState selectedState)
  {
    for (final LayerState state in layers.value)
    {
      state.isSelected.value = state == selectedState;
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
    //shouldRepaint.value = true;
  }

  void layerMerged(final LayerState mergeState)
  {
    //TODO
    print("MERGE ME");

    //shouldRepaint.value= true;
  }

  void layerDuplicated(final LayerState duplicateState)
  {
    List<LayerState> stateList = [];
    for (int i = 0; i < layers.value.length; i++)
    {
      if (layers.value[i] == duplicateState)
      {
        LayerState layerState = LayerState(width: canvasWidth, height: canvasHeight, color: layers.value[i].color.value, appState: this);
        layerState.lockState.value = layers.value[i].lockState.value;
        layerState.visibilityState.value = layers.value[i].visibilityState.value;
        stateList.add(layerState);
      }
      stateList.add(layers.value[i]);
    }
    layers.value = stateList;
    //shouldRepaint.value = true;
  }

  void colorSelected(final String uuid)
  {
    selectedColorId.value = uuid;
  }


  void setStatusBarDimensions(final int width, final int height)
  {
    statusBarDimensionString.value = "$width,$height";
  }

  void hideStatusBarDimension()
  {
    statusBarDimensionString.value = null;
  }

  void setStatusBarCursorPosition(final double x, final double y)
  {
    statusBarCursorPositionString.value = "${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}";
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

  void setStatusBarToolDimension(final int x1, final int y1, final int x2, int y2)
  {
    final int width = (x1 - x2).abs();
    final int height = (y1 - y2).abs();
    statusBarToolDimensionString.value = "$width,$height";
  }

  void hideStatusBarToolDimension()
  {
    statusBarToolDimensionString.value = null;
  }

  void setStatusBarToolDiagonal(final int x1, final int y1, final int x2, int y2)
  {
    final int width = (x1 - x2).abs();
    final int height = (y1 - y2).abs();
    final double result = sqrt((width * width).toDouble() + (height * height).toDouble());
    statusBarToolDiagonalString.value = result.toStringAsFixed(1);  }

  void hideStatusBarToolDiagonal()
  {
    statusBarToolDiagonalString.value = null;
  }

  void setStatusBarToolAspectRatio(final int x1, final int y1, final int x2, int y2)
  {
    final int width = (x1 - x2).abs();
    final int height = (y1 - y2).abs();
    final int divisor = Helper.gcd(width, height);
    final int reducedWidth = divisor != 0 ? width ~/ divisor : 0;
    final int reducedHeight = divisor != 0 ? height ~/ divisor : 0;
    statusBarToolAspectRatioString.value = '$reducedWidth:$reducedHeight';
  }

  void hideStatusBarToolAspectRatio()
  {
    statusBarToolAspectRatioString.value = null;
  }

  void setStatusBarToolAngle(final int x1, final int y1, final int x2, final int y2)
  {
    double angle = Helper.calculateAngle(x1, y1, x2, y2);
    statusBarToolAngleString.value = "${angle.toStringAsFixed(1)}°";
  }

  void hideStatusBarToolAngle()
  {
    statusBarToolAngleString.value = null;
  }

  //TEMP
  void changeTool(ToolType t)
  {
    print("ChangeTool");
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
  }

  bool toolIsSelected(final ToolType tool)
  {
    return _selectionMap[tool] ?? false;
  }
}


