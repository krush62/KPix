import 'package:flutter/cupertino.dart';

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.Pencil);

  void setToolSelection(ToolType tool)
  {
    for (var k in _selectionMap.keys) {
    _selectionMap[k] = k == tool;
    }
    selectedTool.value = tool;
}

bool toolIsSelected(ToolType tool)
{
  return _selectionMap[tool] ?? false;
}

  final Map<ToolType, bool> _selectionMap =
  {
    ToolType.Pencil: false,
    ToolType.Brush: false,
    ToolType.Shape: false,
    ToolType.Gradient: false,
    ToolType.Fill: false,
    ToolType.Select: false,
    ToolType.Pick: false,
    ToolType.Erase: false,
    ToolType.Font: false,
    ToolType.ColorSelect: false,
    ToolType.Line: false,
  };
}


enum ToolType
{
  Pencil,
  Brush,
  Shape,
  Gradient,
  Fill,
  Select,
  Pick,
  Erase,
  Font,
  ColorSelect,
  Line
}