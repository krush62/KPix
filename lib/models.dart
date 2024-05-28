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

  //StatusBar
  final ValueNotifier<String?> statusBarDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarCursorPositionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarUsedColorsString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarZoomFactorString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDiagonalString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAspectRatioString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAngleString = ValueNotifier(null);



  final KPalConstraints kPalConstraints;

  AppState({required this.kPalConstraints})
  {
    for (ToolType toolType in toolList.keys)
    {
      _selectionMap[toolType] = false;
    }
    setToolSelection(ToolType.pencil);
    //TODO TEMP
    setStatusBarColorCount(123);
    setStatusBarCursorPosition(123, 456);
    setStatusBarDimensions(200, 400);
    setStatusBarZoomFactor(200);
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

  void addNewLayer(final LayerState newState)
  {
    List<LayerState> layerList = [];
    layerList.add(newState);
    layerList.addAll(layers.value);
    layers.value = layerList;
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
    addNewLayer(LayerState());
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
  }

  void layerMerged(final LayerState mergeState)
  {
    //TODO
    print("MERGE ME");
  }

  void layerDuplicated(final LayerState duplicateState)
  {
    List<LayerState> stateList = [];
    for (int i = 0; i < layers.value.length; i++)
    {
      if (layers.value[i] == duplicateState)
      {
        LayerState layerState = LayerState();
        layerState.content.value = layers.value[i].content.value;
        layerState.lockState.value = layers.value[i].lockState.value;
        layerState.visibilityState.value = layers.value[i].visibilityState.value;
        stateList.add(layerState);
      }
      stateList.add(layers.value[i]);
    }
    layers.value = stateList;
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

  void setStatusBarColorCount(final int colorCount)
  {
    statusBarUsedColorsString.value = "$colorCount colors";
  }

  void hideStatusBarColorCount()
  {
    statusBarUsedColorsString.value = null;
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


