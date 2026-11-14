/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/models/tool_type.dart';
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
