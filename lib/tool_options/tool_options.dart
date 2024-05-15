import 'package:kpix/tool_options/color_pick_options.dart';
import 'package:kpix/tool_options/curve_options.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/wand_options.dart';

class ToolOptions
{
  ToolOptions({
    required this.pencilOptions,
    required this.shapeOptions,
    required this.fillOptions,
    required this.selectOptions,
    required this.colorPickOptions,
    required this.eraserOptions,
    required this.textOptions,
    required this.sprayCanOptions,
    required this.lineOptions,
    required this.wandOptions,
    required this.curveOptions});

  final PencilOptions pencilOptions;
  final ShapeOptions shapeOptions;
  final FillOptions fillOptions;
  final SelectOptions selectOptions;
  final ColorPickOptions colorPickOptions;
  final EraserOptions eraserOptions;
  final TextOptions textOptions;
  final SprayCanOptions sprayCanOptions;
  final LineOptions lineOptions;
  final WandOptions wandOptions;
  final CurveOptions curveOptions;
}








