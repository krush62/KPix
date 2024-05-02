import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kpix/widgets/color_entry_widget.dart';

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  final ValueNotifier<List<ColorEntryWidget>> colorList = ValueNotifier([]);

  void setColors(final List<Color> inputColors, final ColorEntryWidgetOptions options)
  {
    colorList.value.clear();
    for (Color c in inputColors)
    {
      colorList.value.add(ColorEntryWidget(c, _colorChanged, options));
    }
  }

  void _colorChanged(final ColorEntryWidget colorEntry)
  {
    for (int i = 0; i < colorList.value.length; i++)
    {
      final bool shouldSelect = colorList.value[i] == colorEntry;
      if (shouldSelect != colorList.value[i].isSelected())
      {
        colorList.value[i].setSelected(shouldSelect);
      }
    }
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