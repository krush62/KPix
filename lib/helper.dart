import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  ToolType.pencil: Tool(icon: FontAwesomeIcons.pen, title: "Pencil"),
  ToolType.shape: Tool(icon: FontAwesomeIcons.shapes, title: "Shapes"),
  ToolType.gradient: Tool(icon: Icons.gradient, title: "Gradient"),
  ToolType.fill: Tool(icon: FontAwesomeIcons.fillDrip, title: "Fill"),
  ToolType.select : Tool(icon: Icons.select_all, title: "Select"),
  ToolType.pick : Tool(icon: FontAwesomeIcons.eyeDropper, title: "Color Pick"),
  ToolType.erase : Tool(icon: FontAwesomeIcons.eraser, title: "Eraser"),
  ToolType.font : Tool(icon: FontAwesomeIcons.font, title: "Text"),
  ToolType.spraycan : Tool(icon: FontAwesomeIcons.sprayCan, title: "Spray Can"),
  ToolType.line : Tool(icon: FontAwesomeIcons.linesLeaning, title: "Line"),
  ToolType.wand : Tool(icon: FontAwesomeIcons.wandMagicSparkles, title: "Wand"),
  ToolType.stamp : Tool(icon: FontAwesomeIcons.stamp, title: "Stamp"),
  ToolType.curve : Tool(icon: FontAwesomeIcons.bezierCurve, title: "Curve"),
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

