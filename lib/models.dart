import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';
import 'package:uuid/uuid.dart';

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  final ValueNotifier<List<ColorRampRowWidget>> colorRampWidgetList = ValueNotifier([]);
  late List<List<IdColor>> _colorRamps;
  final Map<ToolType, bool> _selectionMap = {};
  late ColorEntryWidgetOptions _colorEntryWidgetOptions;
  final ValueNotifier<String> selectedColorId = ValueNotifier("");
  final ValueNotifier<Color> selectedColor = ValueNotifier(Colors.black);

  AppState()
  {
    for (ToolType tooltype in toolList.keys)
    {
      _selectionMap[tooltype] = false;
    }
    setToolSelection(ToolType.pencil);
  }

  void setColors(final List<List<Color>> inputColors, final ColorEntryWidgetOptions options)
  {
    Uuid uuid = const Uuid();
    _colorRamps = [];
    for (final List<Color> cList in inputColors)
    {
      List<IdColor> colorList = [];
      for (final Color c in cList)
      {
        colorList.add(IdColor(color: c, uuid: uuid.v1()));
      }
      _colorRamps.add(colorList);
    }
    _colorEntryWidgetOptions = options;
    _updateColorWidgets();
  }

  void _updateColorWidgets()
  {
    colorRampWidgetList.value = [];
    for (List<IdColor> ramp in _colorRamps)
    {
      colorRampWidgetList.value.add(ColorRampRowWidget(ramp, _colorSelectionChanged, _addNew, _colorEntryWidgetOptions, this, _colorMoved));
    }
    colorRampWidgetList.value.add(ColorRampRowWidget(null, _colorSelectionChanged, _addNew, _colorEntryWidgetOptions, this, _colorMoved));
  }

  void _colorMoved(final IdColor color, final ColorEntryDropTargetWidget dragTarget)
  {
    int sourceRamp = -1;
    int sourcePos = -1;
    int targetRamp = -1;
    int targetPos = -1;
    for (int i = 0; i < colorRampWidgetList.value.length; i++)
    {
      for (int j = 0; j < colorRampWidgetList.value[i].widgetList.length; j++)
      {
        Widget currentWidget = colorRampWidgetList.value[i].widgetList[j];
        if (currentWidget is ColorEntryWidget) {
          if (currentWidget.colorData.value.color == color) {
            sourceRamp = i;
            sourcePos = j ~/ 2;
          }
        }
        else if (currentWidget is ColorEntryDropTargetWidget)
        {
          if (currentWidget == dragTarget)
          {
            targetRamp = i;
            targetPos = j ~/ 2;
          }
        }
      }
    }

    if (sourceRamp != -1 && sourcePos != -1 && targetRamp != -1 && targetPos != -1)
    {
      if (sourceRamp != targetRamp)
      {
        _colorRamps[sourceRamp].removeAt(sourcePos);
        _colorRamps[targetRamp].insert(targetPos, color);
        _updateColorWidgets();
      }
      else if (sourcePos != targetPos)
      {
        if (targetPos > sourcePos)
        {
          targetPos--;
        }
        _colorRamps[sourceRamp].removeAt(sourcePos);
        _colorRamps[targetRamp].insert(targetPos, color);
        _updateColorWidgets();
      }
    }
  }

  void _addNew(List<IdColor>? ramp)
  {
    Uuid uuid = const Uuid();
    if (ramp != null)
    {
      ramp.add(IdColor(color: Colors.black, uuid: uuid.v1()));
    }
    else
    {
      _colorRamps.add([]);
    }
    _updateColorWidgets();
    //_colorSelectionChanged(selectedColorId.value);
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
          if (currentWidget.colorData.value.color.uuid == colorUuid)
          {
            selectedColorId.value = colorUuid;
            selectedColor.value = currentWidget.colorData.value.color.color;
            return;
          }
        }
      }
    }
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


