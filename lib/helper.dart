import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ToolType
{
  pencil,
  shape,
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

class LabColor
{
  static const double AB_MAX_VALUE = 128.0;
  static const double L_MAX_VALUE = 100.0;

  final double L, A, B;

  LabColor({
    required this.L,
    required this.A,
    required this.B,
  });
}

class CoordinateSetD
{
  double x = 0;
  double y = 0;

  CoordinateSetD({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CoordinateSetD &&
              runtimeType == other.runtimeType &&
              x == other.x &&
              y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class CoordinateSetI
{
  int x = 0;
  int y = 0;

  CoordinateSetI({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CoordinateSetI &&
              runtimeType == other.runtimeType &&
              x == other.x &&
              y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return "$x|$y";
  }
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

  static bool isPerfectSquare(final int number) {
    double squareRoot = sqrt(number);
    return squareRoot % 1 == 0;
  }

  static int gcd(final int a, final int b) {
    if (b == 0) return a;
    return gcd(b, a % b);
  }

  static double calculateAngle(int x1, int y1, int x2, int y2) {
    int dx = x2 - x1;
    int dy = y2 - y1;

    double angle = atan2(dy, dx);

    double angleInDegrees = angle * (180.0 / pi);

    return angleInDegrees;
  }



  static LabColor rgb2lab(int red, int green, int blue)
  {
    double r = red.toDouble() / 255.0, g = green.toDouble() / 255.0, b = blue.toDouble() / 255.0, x, y, z;
    r = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4).toDouble() : r / 12.92;
    g = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4).toDouble() : g / 12.92;
    b = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4).toDouble() : b / 12.92;
    x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
    y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.00000;
    z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
    x = (x > 0.008856) ? pow(x, 1.0 / 3.0).toDouble() : (7.787 * x) + 16.0 / 116.0;
    y = (y > 0.008856) ? pow(y, 1.0 / 3.0).toDouble() : (7.787 * y) + 16.0 / 116.0;
    z = (z > 0.008856) ? pow(z, 1.0 / 3.0).toDouble() : (7.787 * z) + 16.0 / 116.0;
    return LabColor(L: (116.0 * y) - 16.0, A: 500.0 * (x - y), B: 200.0 * (y - z));
  }

  static double getDeltaE(int redA, int greenA, int blueA, int redB, int greenB, int blueB)
  {
    LabColor labA = rgb2lab(redA, greenA, blueA);
    LabColor labB = rgb2lab(redB, greenB, blueB);
    double deltaL = labA.L - labB.L;
    double deltaA = labA.A - labB.A;
    double deltaB = labA.B - labB.B;
    double c1 = sqrt(labA.A * labA.A + labA.B * labA.B);
    double c2 = sqrt(labB.A * labB.A + labB.B * labB.B);
    double deltaC = c1 - c2;
    double deltaH = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
    deltaH = deltaH < 0 ? 0 : sqrt(deltaH);
    double sc = 1.0 + 0.045 * c1;
    double sh = 1.0 + 0.015 * c1;
    double deltaLKlsl = deltaL / 1.0;
    double deltaCkcsc = deltaC / sc;
    double deltaHkhsh = deltaH / sh;
    double i = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;
    return i < 0.0 ? 0.0 : sqrt(i);
  }
}

