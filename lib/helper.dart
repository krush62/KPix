import 'package:flutter/material.dart';

enum ToolType
{
  pencil,
  shape,
  gradient,
  fill,
  select,
  pick,
  erase,
  font,
  spraycan,
  line,
  wand,
  stamp,
  curve
}

class Tool
{
  final String title;
  final IconData icon;

  const Tool({required this.title, required this.icon});
}

const Map<ToolType, Tool> toolList =
{
  ToolType.pencil: Tool(icon: Icons.edit, title: "Pencil"),
  ToolType.shape: Tool(icon: Icons.square_outlined, title: "Shapes"),
  ToolType.gradient: Tool(icon: Icons.gradient, title: "Gradient"),
  ToolType.fill: Tool(icon: Icons.format_color_fill, title: "Fill"),
  ToolType.select : Tool(icon: Icons.select_all, title: "Select"),
  ToolType.pick : Tool(icon: Icons.colorize, title: "Color Pick"),
  ToolType.erase : Tool(icon: Icons.delete_outline, title: "Eraser"),
  ToolType.font : Tool(icon: Icons.text_format, title: "Text"),
  ToolType.spraycan : Tool(icon: Icons.blur_on, title: "Spray Can"),
  ToolType.line : Tool(icon: Icons.line_axis, title: "Line"),
  ToolType.wand : Tool(icon: Icons.star_rate_outlined, title: "Wand"),
  ToolType.stamp : Tool(icon: Icons.approval, title: "Stamp"),
  ToolType.curve : Tool(icon: Icons.looks, title: "Curve"),
};

class IdColor
{
  final Color color;
  final String uuid;
  IdColor({required this.color, required this.uuid});
}

class Helper
{

  static String colorToHexString(final Color c) {
    return '#${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  static String colorToRGBString(final Color c) {
    return '${c.red.toString()} | '
        '${c.green.toString()} | '
        '${c.blue.toString()}';
  }

  static String colorToHSVString(final Color c) {
    return hsvColorToHSVString(HSVColor.fromColor(c));
  }

  static String hsvColorToHSVString(final HSVColor c) {
    return "${c.hue.round().toString()}° | "
        "${(c.saturation * 100.0).round().toString()}% | "
        "${(c.value * 100.0).round().toString()}%";
  }
}

