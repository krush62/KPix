import 'package:kpix/tool_options/color_pick_options.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/helper.dart';

enum SelectionMode
{
  replace,
  add,
  subtract,
  intersect
}

const List<SelectionMode> selectionModeList = [
  SelectionMode.replace,
  SelectionMode.add,
  SelectionMode.subtract,
  SelectionMode.intersect
];

const Map<int, SelectionMode> selectionModeIndexMap =
{
  0: SelectionMode.replace,
  1: SelectionMode.add,
  2: SelectionMode.subtract,
  3: SelectionMode.intersect
};

const Map<SelectionMode, String> selectionModeStringMap =
{
  SelectionMode.replace : "Replace",
  SelectionMode.add : "Add",
  SelectionMode.subtract : "Subtract",
  SelectionMode.intersect : "Intersect"
};

abstract class IToolOptions{
  int getSize();
  void changeSize(int steps, int originalValue);
}

class ToolOptions
{
  final Map<ToolType, IToolOptions> toolOptionMap;

  factory ToolOptions({
    required PencilOptions pencilOptions,
    required ShapeOptions shapeOptions,
    required FillOptions fillOptions,
    required SelectOptions selectOptions,
    required ColorPickOptions colorPickOptions,
    required EraserOptions eraserOptions,
    required TextOptions textOptions,
    required SprayCanOptions sprayCanOptions,
    required LineOptions lineOptions,
    required StampOptions stampOptions
})
  {
    Map<ToolType, IToolOptions> toolOptionMap = {
      ToolType.line: lineOptions,
      ToolType.spraycan: sprayCanOptions,
      ToolType.font: textOptions,
      ToolType.erase: eraserOptions,
      ToolType.pick: colorPickOptions,
      ToolType.select: selectOptions,
      ToolType.shape: shapeOptions,
      ToolType.fill: fillOptions,
      ToolType.pencil: pencilOptions,
      ToolType.stamp: stampOptions
    };

    return ToolOptions._(
      lineOptions: lineOptions,
      sprayCanOptions: sprayCanOptions,
      textOptions: textOptions,
      eraserOptions: eraserOptions,
      colorPickOptions: colorPickOptions,
      selectOptions: selectOptions,
      shapeOptions: shapeOptions,
      fillOptions: fillOptions,
      pencilOptions: pencilOptions,
      stampOptions: stampOptions,
      toolOptionMap: toolOptionMap,
    );
  }


  ToolOptions._({
    required this.pencilOptions,
    required this.shapeOptions,
    required this.fillOptions,
    required this.selectOptions,
    required this.colorPickOptions,
    required this.eraserOptions,
    required this.textOptions,
    required this.sprayCanOptions,
    required this.lineOptions,
    required this.stampOptions,
    required this.toolOptionMap});

  final PencilOptions pencilOptions;
  final ShapeOptions shapeOptions;
  final FillOptions fillOptions;
  final SelectOptions selectOptions;
  final ColorPickOptions colorPickOptions;
  final EraserOptions eraserOptions;
  final TextOptions textOptions;
  final SprayCanOptions sprayCanOptions;
  final LineOptions lineOptions;
  final StampOptions stampOptions;

}








