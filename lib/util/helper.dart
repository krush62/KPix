import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';

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
  stamp,
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
  ToolType.line : Tool(icon: Icons.multiline_chart, title: "Line"),
  ToolType.stamp : Tool(icon: FontAwesomeIcons.stamp, title: "Stamp"),
};

class LabColor
{
  static const double abMax = 128.0;
  static const double lMax = 100.0;

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

  @override
  String toString() {
    return "$x|$y";
  }
}

class CoordinateSetI
{
  int x = 0;
  int y = 0;

  CoordinateSetI({required this.x, required this.y});

  factory CoordinateSetI.from(final CoordinateSetI other)
  {
    return CoordinateSetI(x: other.x, y: other.y);
  }

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

  bool isAdjacent(final CoordinateSetI other, final bool withDiagonal)
  {
    bool adj = true;
    if (withDiagonal)
    {
      if (other.x < x - 1 || other.x > x + 1 || other.y < y - 1 ||other.y > y + 1)
      {
        adj = false;
      }
    }
    else
    {
      if (other.x != x && other.y != y && other.x < x - 1 && other.x > x + 1 && other.y < y - 1 && other.y > y + 1)
      {
        adj = false;
      }
    }
    return adj;
  }

  bool isDiagonal(final CoordinateSetI other)
  {
    return (x - other.x).abs() == 1 && (y - other.y).abs() == 1;
  }
}

class StackCol<T> {
  final _list = <T>[];

  void push(T value) => _list.add(value);

  T pop() => _list.removeLast();

  T get peek => _list.last;

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  int get length => _list.length;
}



class Helper
{

  static String colorToHexString(final Color c)
  {
    return '#${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  static String colorToRGBString(final Color c)
  {
    return '${c.red.toString()} | '
        '${c.green.toString()} | '
        '${c.blue.toString()}';
  }

  static String colorToHSVString(final Color c)
  {
    return hsvColorToHSVString(HSVColor.fromColor(c));
  }

  static String hsvColorToHSVString(final HSVColor c)
  {
    return "${c.hue.round().toString()}° | "
        "${(c.saturation * 100.0).round().toString()}% | "
        "${(c.value * 100.0).round().toString()}%";
  }

  static bool isPerfectSquare(final int number)
  {
    double squareRoot = sqrt(number);
    return squareRoot % 1 == 0;
  }

  static int gcd(final int a, final int b)
  {
    if (b == 0) return a;
    return gcd(b, a % b);
  }

  static double calculateAngle(final CoordinateSetI startPos, final CoordinateSetI endPos)
  {
    final int dx = endPos.x - startPos.x;
    final int dy = endPos.y - startPos.y;
    final double angle = atan2(dy, dx);
    final double angleInDegrees = angle * (180.0 / pi);
    return angleInDegrees;
  }



  static LabColor rgb2lab(final int red, final int green, final int blue)
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

  static double getDeltaE(final int redA, final int greenA, final int blueA, final int redB, final int greenB, final int blueB)
  {
    final LabColor labA = rgb2lab(redA, greenA, blueA);
    final LabColor labB = rgb2lab(redB, greenB, blueB);
    final double deltaL = labA.L - labB.L;
    final double deltaA = labA.A - labB.A;
    final double deltaB = labA.B - labB.B;
    final double c1 = sqrt(labA.A * labA.A + labA.B * labA.B);
    final double c2 = sqrt(labB.A * labB.A + labB.B * labB.B);
    final double deltaC = c1 - c2;
    double deltaH = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
    deltaH = deltaH < 0 ? 0 : sqrt(deltaH);
    final double sc = 1.0 + 0.045 * c1;
    final double sh = 1.0 + 0.015 * c1;
    final double deltaLKlsl = deltaL / 1.0;
    final double deltaCkcsc = deltaC / sc;
    final double deltaHkhsh = deltaH / sh;
    final double i = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;
    return i < 0.0 ? 0.0 : sqrt(i);
  }

  static HashMap<ColorReference, ColorReference> getRampMap({required final List<KPalRampData> rampList1, required final List<KPalRampData> rampList2})
  {
    final HashMap<ColorReference, ColorReference> rampMap = HashMap();
    for (final KPalRampData kPalRampData in rampList1)
    {
      for (final ColorReference colRef in kPalRampData.references)
      {
        rampMap[colRef] = getClosestColor(inputColor: colRef, rampList: rampList2);
      }
    }
    return rampMap;
  }

  static ColorReference getClosestColor({required final ColorReference inputColor, required final List<KPalRampData> rampList})
  {
    assert(rampList.isNotEmpty);

    final int r = inputColor.getIdColor().color.red;
    final int g = inputColor.getIdColor().color.green;
    final int b = inputColor.getIdColor().color.blue;
    late ColorReference closestColor;
    double closestVal = double.maxFinite;
    for (final KPalRampData kPalRampData in rampList)
    {
      for (int i = 0; i < kPalRampData.settings.colorCount; i++)
      {
         final int r2 = kPalRampData.colors[i].value.color.red;
         final int g2 = kPalRampData.colors[i].value.color.green;
         final int b2 = kPalRampData.colors[i].value.color.blue;
         final double dist = getDeltaE(r, g, b, r2, g2, b2);
         if (dist < closestVal)
         {
            closestColor = kPalRampData.references[i];
            closestVal = dist;
         }
      }
    }
    return closestColor;
  }

  static bool isPointInPolygon(final CoordinateSetI point, final List<CoordinateSetI> polygon)
  {
    final int n = polygon.length;
    bool inside = false;

    for (int i = 0, j = n - 1; i < n; j = i++)
    {
      if (((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
          (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x)) {
        inside = !inside;
      }
    }

    return inside;
  }


  static double getPointToEdgeDistance(final CoordinateSetI point, final List<CoordinateSetI> polygon)
  {
    double minDistance = double.infinity;

    for (int i = 0; i < polygon.length; i++)
    {
      final CoordinateSetI p1 = polygon[i];
      final CoordinateSetI p2 = polygon[(i + 1) % polygon.length];

      final int dx = p2.x - p1.x;
      final int dy = p2.y - p1.y;

      final int edgeLengthSquared = dx * dx + dy * dy;

      final int vx = point.x - p1.x;
      final int vy = point.y - p1.y;

      final int dotProduct = vx * dx + vy * dy;

      final double t = max(0, min(1, (dotProduct / edgeLengthSquared)));

      final double closestX = p1.x + t * dx;
      final double closestY = p1.y + t * dy;

      final double distanceSquared = (point.x - closestX) * (point.x - closestX) + (point.y - closestY) * (point.y - closestY);

      minDistance = min(minDistance, sqrt(distanceSquared));
    }

    return minDistance;
  }



  static CoordinateSetI getMin(final List<CoordinateSetI> coordList)
  {
    final int minX = coordList.reduce((a, b) => a.x < b.x ? a : b).x;
    final int minY = coordList.reduce((a, b) => a.y < b.y ? a : b).y;
    return CoordinateSetI(x: minX, y: minY);
  }

  static CoordinateSetI getMax(final List<CoordinateSetI> coordList)
  {
    final int maxX = coordList.reduce((a, b) => a.x > b.x ? a : b).x;
    final int maxY = coordList.reduce((a, b) => a.y > b.y ? a : b).y;
    return CoordinateSetI(x: maxX, y: maxY);
  }


  static List<CoordinateSetI> bresenham(final CoordinateSetI start, final CoordinateSetI end)
  {
    final List<CoordinateSetI> points = [];
    final CoordinateSetI d = CoordinateSetI(x: (end.x - start.x).abs(), y: (end.y - start.y).abs());
    final CoordinateSetI s = CoordinateSetI(x: start.x < end.x ? 1 : -1, y: start.y < end.y ? 1 : -1);

    int err = d.x - d.y;
    final CoordinateSetI currentPoint = CoordinateSetI.from(start);

    while (true)
    {
      points.add(CoordinateSetI.from(currentPoint));
      if (currentPoint.x == end.x && currentPoint.y == end.y) break;
      final int e2 = err * 2;
      if (e2 > -d.y)
      {
        err -= d.y;
        currentPoint.x += s.x;
      }
      if (e2 < d.x) {
        err += d.x;
        currentPoint.y += s.y;
      }
    }

    return points;
  }



  static int argbToRgba(int argb) {
    int a = (argb & 0xFF000000) >> 24; // Extract alpha component
    int r = (argb & 0x00FF0000) >> 16; // Extract red component
    int g = (argb & 0x0000FF00) >> 8;  // Extract green component
    int b = (argb & 0x000000FF);       // Extract blue component

    // Combine components into RGBA format
    int rgba = (r << 24) | (g << 16) | (b << 8) | a;
    return rgba;
  }

  static const double twoPi = 2 * pi;
  static double normAngle(final double angle)
  {
    return angle - (twoPi * (angle / twoPi).floor());
  }

  static double deg2rad(final double angle)
  {
    return angle * (pi / 180.0);
  }

  static double rad2deg(final double angle)
  {
    return angle * (180.0 / pi);
  }
  
  static double getDistance(final CoordinateSetI a, final CoordinateSetI b)
  {
    return sqrt(((a.x - b.x) * (a.x - b.x)) + ((a.y - b.y) * (a.y - b.y)));
  }
}

