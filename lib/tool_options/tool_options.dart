import 'package:kpix/managers/font_manager.dart';
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
import 'package:kpix/widgets/tools/tool_type.dart';


abstract class IToolOptions{
  int getSize(){return 0;}
  void changeSize({required final int steps, required final int originalValue}){}
}

class ToolOptions
{
  late Map<ToolType, IToolOptions> toolOptionMap;
  final PencilOptions pencilOptions = PencilOptions();
  final ShapeOptions shapeOptions = ShapeOptions();
  final FillOptions fillOptions = FillOptions();
  final SelectOptions selectOptions = SelectOptions();
  final ColorPickOptions colorPickOptions = ColorPickOptions();
  final EraserOptions eraserOptions = EraserOptions();
  final TextOptions textOptions;
  final SprayCanOptions sprayCanOptions = SprayCanOptions();
  final LineOptions lineOptions = LineOptions();
  final StampOptions stampOptions = StampOptions();

  ToolOptions({required final FontManager fontManager}) : textOptions = TextOptions(fontManager: fontManager)
  {
    toolOptionMap = <ToolType, IToolOptions>{
      ToolType.line: lineOptions,
      ToolType.spraycan: sprayCanOptions,
      ToolType.font: textOptions,
      ToolType.erase: eraserOptions,
      ToolType.pick: colorPickOptions,
      ToolType.select: selectOptions,
      ToolType.shape: shapeOptions,
      ToolType.fill: fillOptions,
      ToolType.pencil: pencilOptions,
      ToolType.stamp: stampOptions,
    };
  }
}
