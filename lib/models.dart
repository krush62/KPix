import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:uuid/uuid.dart';

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  final ValueNotifier<List<ColorRampRowWidget>> colorRampWidgetList = ValueNotifier([]);
  late List<KPalRampData> colorRamps = [];
  final Map<ToolType, bool> _selectionMap = {};
  late ColorEntryWidgetOptions _colorEntryWidgetOptions;
  final ValueNotifier<String> selectedColorId = ValueNotifier("");
  final ValueNotifier<Color> selectedColor = ValueNotifier(Colors.black);

  //StatusBar
  final ValueNotifier<String?> statusBarDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarCursorPositionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarUsedColorsString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarZoomFactorString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDiagonalString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAspectRatioString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAngleString = ValueNotifier(null);

  late OverlayEntryAlertDialogOptions _alertDialogOptions;
  late KPalConstraints _kPalConstraints;
  late KPalWidgetOptions _kPalWidgetOptions;

  late ColorNames _colorNames;

  AppState()
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

  void setColors({
    required final ColorEntryWidgetOptions colorEntryWidgetOptions,
    required final KPalConstraints kPalConstraints,
    required final OverlayEntryAlertDialogOptions alertDialogOptions,
    required final KPalWidgetOptions kPalWidgetOptions,
    required final ColorNames colorNames})
  {
    _colorEntryWidgetOptions = colorEntryWidgetOptions;
    _kPalConstraints = kPalConstraints;
    _alertDialogOptions = alertDialogOptions;
    _kPalWidgetOptions = kPalWidgetOptions;
    _colorNames = colorNames;

    colorRamps = [];

    //TODO TEMP
    _addNewRamp();
    _addNewRamp();
    _addNewRamp();

  }

  void _updateColorWidgets()
  {
    colorRampWidgetList.value = [];
    for (KPalRampData rampData in colorRamps)
    {
      colorRampWidgetList.value.add(
        ColorRampRowWidget(
          rampData: rampData,
          colorSelectedFn: _colorSelectionChanged,
          colorsUpdatedFn: _updateRamp,
          deleteRowFn: _deleteRamp,
          colorNames: _colorNames,
          colorEntryWidgetOptions: _colorEntryWidgetOptions,
          appState: this,
          alertDialogOptions: _alertDialogOptions,
          kPalConstraints: _kPalConstraints,
          kPalWidgetOptions: _kPalWidgetOptions,
        )
      );
    }
    colorRampWidgetList.value.add(ColorRampRowWidget(
        addNewRampFn: _addNewRamp,
        colorEntryWidgetOptions: _colorEntryWidgetOptions,
    ));
  }

  void _deleteRamp(final KPalRampData ramp)
  {
    colorRamps.remove(ramp);
    _updateColorWidgets();
  }

  void _updateRamp(final KPalRampData ramp)
  {
    _updateColorWidgets();
  }

  void _addNewRamp()
  {
    const Uuid uuid = Uuid();
    colorRamps.add(KPalRampData(uuid: uuid.v1(), settings: KPalRampSettings(
        constraints: _kPalConstraints
    )
    ));
    _updateColorWidgets();
  }


  void _colorSelectionChanged(final String colorUuid)
  {
    for (int i = 0; i < colorRampWidgetList.value.length; i++)
    {
      for (int j = 0; j < colorRampWidgetList.value[i].widgetList.length; j++)
      {
        Widget currentWidget = colorRampWidgetList.value[i].widgetList[j];
        if (currentWidget is ColorEntryWidget)
        {
          if (currentWidget.colorData.value.uuid == colorUuid)
          {
            selectedColorId.value = colorUuid;
            selectedColor.value = currentWidget.colorData.value.color;
            return;
          }
        }
      }
    }
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


