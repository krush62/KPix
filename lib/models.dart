import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';
import 'package:uuid/uuid.dart';

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  final ValueNotifier<List<ColorRampRowWidget>> colorRampWidgetList = ValueNotifier([]);
  late List<List<IdColor>> _colorRamps;
  late ColorEntryWidgetOptions _colorEntryWidgetOptions;
  final ValueNotifier<String> selectedColorId = ValueNotifier("");

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
      colorRampWidgetList.value.add(ColorRampRowWidget(colorList: ramp, appState: this, colorSelectedFn: _colorSelectionChanged, addNewColorFn: _addNew, colorEntryWidgetOptions: _colorEntryWidgetOptions));
    }
    colorRampWidgetList.value.add(ColorRampRowWidget(colorList: null, appState: this, colorSelectedFn: _colorSelectionChanged, addNewColorFn: _addNew, colorEntryWidgetOptions: _colorEntryWidgetOptions));
  }

  void _addNew(List<IdColor>? ramp)
  {
    Uuid uuid = const Uuid();
    if (ramp != null) {
      ramp.add(IdColor(color: Colors.black, uuid: uuid.v1()));
    }
    else
    {
      _colorRamps.add([]);
    }
    _updateColorWidgets();
    _colorSelectionChanged(selectedColorId.value);
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

  final Map<ToolType, bool> _selectionMap =
  {
    ToolType.pencil: false,
    ToolType.brush: false,
    ToolType.shape: false,
    ToolType.gradient: false,
    ToolType.fill: false,
    ToolType.select: false,
    ToolType.pick: false,
    ToolType.erase: false,
    ToolType.font: false,
    ToolType.colorSelect: false,
    ToolType.line: false,
  };
}


enum ToolType
{
  pencil,
  brush,
  shape,
  gradient,
  fill,
  select,
  pick,
  erase,
  font,
  colorSelect,
  line
}

class IdColor
{
  final Color color;
  final String uuid;
  IdColor({required this.color, required this.uuid});
}