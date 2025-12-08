/*
 * KPix
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

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

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

  static bool isDrawTool({required final ToolType type})
  {
    return
      type == ToolType.pencil ||
      type == ToolType.shape ||
      type == ToolType.fill ||
      type == ToolType.font ||
      type == ToolType.spraycan ||
      type == ToolType.line ||
      type == ToolType.stamp
    ;
  }
}

const Map<ToolType, Tool> toolList =
<ToolType, Tool>{
  ToolType.pencil: Tool(icon: TablerIcons.pencil, title: "Pencil"),
  ToolType.shape: Tool(icon: TablerIcons.triangle_square_circle, title: "Shapes"),
  ToolType.fill: Tool(icon: TablerIcons.droplet, title: "Fill"),
  ToolType.select : Tool(icon: TablerIcons.border_corners, title: "Select"),
  ToolType.pick : Tool(icon: TablerIcons.color_picker, title: "Color Pick"),
  ToolType.erase : Tool(icon: TablerIcons.eraser, title: "Eraser"),
  ToolType.font : Tool(icon: TablerIcons.typography, title: "Text"),
  ToolType.spraycan : Tool(icon: TablerIcons.spray, title: "Spray Can"),
  ToolType.line : Tool(icon: Icons.multiline_chart, title: "Line"),
  ToolType.stamp : Tool(icon: TablerIcons.rubber_stamp, title: "Stamp"),
};



class LabColor
{
  static const double abMax = 128.0;
  static const double lMax = 100.0;

  final double L;
  final double A;
  final double B;

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
  bool operator ==(final Object other) =>
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

  factory CoordinateSetI.from({required final CoordinateSetI other})
  {
    return CoordinateSetI(x: other.x, y: other.y);
  }

  @override
  bool operator ==(final Object other) =>
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

  /// Checks if the current coordinate is adjacent to the other coordinate.
  bool isAdjacent({required final CoordinateSetI other, required final bool withDiagonal})
  {
    bool adj = true;
    if (withDiagonal)
    {
      if (other.x < x - 1 || other.x > x + 1 || other.y < y - 1 || other.y > y + 1)
      {
        adj = false;
      }
    }
    else if
    (((other.x - x).abs() > 1 || other.y != y) && ((other.y - y).abs() > 1 || other.x != x))
    {
      adj = false;
    }
    return adj;
  }

  /// Checks if the current coordinate is diagonal to the other coordinate.
  bool isDiagonal({required final CoordinateSetI other})
  {
    return (x - other.x).abs() == 1 && (y - other.y).abs() == 1;
  }
}

class KHSV
{
  final double h;
  final double s;
  final double v;

  KHSV({required this.h, required this.s, required this.v}) :
    assert(h >= 0.0 && h <= 360.0, 'Hue must be between 0 and 360'),
    assert(s >= 0.0 && s <= 1.0, 'Saturation must be between 0 and 1'),
    assert(v >= 0.0 && v <= 1.0, 'Value must be between 0 and 1');

  KHSV.fromOther({required final KHSV other}) :
    h = other.h,
    s = other.s,
    v = other.v;

  factory KHSV.fromHSV({required final HSVColor hsvColor})
  {
    return KHSV(h: hsvColor.hue, s: hsvColor.saturation, v: hsvColor.value);
  }

  //from other constructor



  HSVColor toHSV({final double alpha = 1.0})
  {
    return HSVColor.fromAHSV(alpha, h, s, v);
  }

  Color toColor() {
    final double chroma = s * v;
    final double secondary = chroma * (1.0 - (((h / 60.0) % 2.0) - 1.0).abs());
    final double match = v - chroma;

    return _colorFromHue(hue: h, chroma: chroma, secondary: secondary, match: match);
  }

  Color _colorFromHue({required final double hue, required final double chroma, required final double secondary, required final double match})
  {
    final (double red, double green, double blue) = switch (hue) {
      < 60.0 => (chroma, secondary, 0.0),
      < 120.0 => (secondary, chroma, 0.0),
      < 180.0 => (0.0, chroma, secondary),
      < 240.0 => (0.0, secondary, chroma),
      < 300.0 => (secondary, 0.0, chroma),
      _ => (chroma, 0.0, secondary),
    };
    return Color.fromARGB(
      0xFF,
      ((red + match) * 0xFF).round(),
      ((green + match) * 0xFF).round(),
      ((blue + match) * 0xFF).round(),
    );
  }
}

class StackCol<T> {
  final List<T> _list = <T>[];

  void push(final T value) => _list.add(value);

  T pop() => _list.removeLast();

  T get peek => _list.last;

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  int get length => _list.length;
}

/// Clamping the color channel values to 0-255.
int _clampChannel(final double value) => value.clamp(0.0, 1.0) * 255 ~/ 1;

/// Converts color to hex string
String colorToHexString({required final Color color, final bool withHashTag = true, final bool toUpper = false})
{
  final String prefix = withHashTag ? "#" : "";
  final String str =
      '$prefix${_clampChannel(color.r).toRadixString(16).padLeft(2, '0')}${_clampChannel(color.g).toRadixString(16).padLeft(2, '0')}${_clampChannel(color.b).toRadixString(16).padLeft(2, '0')}';
  return toUpper ? str.toUpperCase() : str;
}

/// Converts color to RGB string.
String colorToRGBString({required final Color color}) {
  return '${_clampChannel(color.r)} | ${_clampChannel(color.g)} | ${_clampChannel(color.b)}';
}


  /*Color getColorFromHash({required final int hash, required final BuildContext context, required final bool selected})
  {
    return HSVColor.fromAHSV(1.0, (hash.abs() % 360).toDouble(), 0.3, selected ? HSVColor.fromColor(Theme.of(context).primaryColor).value : HSVColor.fromColor(Theme.of(context).primaryColorDark).value).toColor();
  }*/


/// Returns true if the application is running as native desktop application.
bool isDesktop({final bool includingWeb = false})
{
  if (kIsWeb && !includingWeb)
  {
    return false;
  }
  else
  {
    return (kIsWeb && includingWeb) || Platform.isMacOS ||
        Platform.isLinux || Platform.isWindows;
  }
}

/// Returns true if the square root of the [number] is an integer.
bool isPerfectSquare({required final int number})
{
  final double squareRoot = sqrt(number);
  return squareRoot % 1 == 0;
}

/// Calculates the greatest common divisor (GCD) of two integers.
int gcd({required final int a, required final int b})
{
  if (b == 0) return a;
  return gcd(a: b, b: a % b);
}

double calculateAngle({required final CoordinateSetI startPos, required final CoordinateSetI endPos})
{
  final int dx = endPos.x - startPos.x;
  final int dy = endPos.y - startPos.y;
  final double angle = atan2(dy, dx);
  final double angleInDegrees = angle * (180.0 / pi);
  return angleInDegrees;
}


/// Converts sRGB (0..1) to CIE Lab (D65).
///
/// Inputs [r], [g], [b] are sRGB components normalized to 0..1.
///
/// Uses the D65 reference white and the standard sRGB transfer function.
/// Throws no exceptions; returns a [LabColor].
LabColor rgb2lab({
  required final double r,
  required final double g,
  required final double b,
}) {
  // --- sRGB transfer function constants ---
  const double srgbThreshold = 0.04045;
  const double srgbA = 0.055;
  const double srgbGamma = 2.4;

  // --- Reference white (D65) ---
  const double d65X = 0.95047;
  const double d65Y = 1.00000;
  const double d65Z = 1.08883;

  // --- CIE Lab pivot constants ---
  const double epsilon = 0.008856; // ≈ (6/29)^3
  const double kappa = 903.3;      // ≈ (29/3)^3

  // sRGB → linear RGB
  double linear(final double c) =>
      (c > srgbThreshold)
          ? pow((c + srgbA) / (1.0 + srgbA), srgbGamma).toDouble()
          : c / 12.92;

  final double rLin = linear(r.clamp(0.0, 1.0));
  final double gLin = linear(g.clamp(0.0, 1.0));
  final double bLin = linear(b.clamp(0.0, 1.0));

  // Linear RGB → XYZ (sRGB primaries, D65)
  final double x = (rLin * 0.4124 + gLin * 0.3576 + bLin * 0.1805) / d65X;
  final double y = (rLin * 0.2126 + gLin * 0.7152 + bLin * 0.0722) / d65Y;
  final double z = (rLin * 0.0193 + gLin * 0.1192 + bLin * 0.9505) / d65Z;

  // Pivot function for Lab
  double f(final double t) =>
      (t > epsilon) ? pow(t, 1.0 / 3.0).toDouble() : (kappa * t + 16.0) / 116.0;

  final double fx = f(x);
  final double fy = f(y);
  final double fz = f(z);

  // XYZ (normalized) → Lab
  final double L = (116.0 * fy) - 16.0;
  final double A = 500.0 * (fx - fy);
  final double B = 200.0 * (fy - fz);

  return LabColor(L: L, A: A, B: B);
}

/// Computes the CIEDE94 color difference ΔE94 between two sRGB colors.
///
/// Inputs will be normalized sRGB components in [0, 1]. If your values are
/// 0..255, divide each by 255.0 before calling.
///
/// Returns a non-negative ΔE94 (double).
double getDeltaE94(
    {required final double redA,
      required final double greenA,
      required final double blueA,
      required final double redB,
      required final double greenB,
      required final double blueB,})
{
  final LabColor labA = rgb2lab(r: redA, g: greenA, b: blueA);
  final LabColor labB = rgb2lab(r: redB, g: greenB, b: blueB);
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


/// Computes the CIEDE2000 color difference ΔE00 between two sRGB colors.
///
/// Inputs will be normalized sRGB components in [0, 1]. If your values are
/// 0..255, divide each by 255.0 before calling.
///
/// The calculation expects Lab values using the D65 reference white.
/// If your `rgb2lab` uses D65 (as in your earlier code), you are good.
///
/// You can adjust the weighting factors [kL], [kC], [kH] (normally 1.0).
///
/// Returns a non-negative ΔE00 (double).
double getDeltaE00({
  required final double redA,
  required final double greenA,
  required final double blueA,
  required final double redB,
  required final double greenB,
  required final double blueB,
  final double kL = 1.0,
  final double kC = 1.0,
  final double kH = 1.0,
})
{
  // Convert to Lab
  final LabColor labA = rgb2lab(r: redA, g: greenA, b: blueA);
  final LabColor labB = rgb2lab(r: redB, g: greenB, b: blueB);

  // Unpack
  final double l1 = labA.L;
  final double a1 = labA.A;
  final double b1 = labA.B;

  final double l2 = labB.L;
  final double a2 = labB.A;
  final double b2 = labB.B;

  // 1) Compute chroma
  final double c1 = sqrt(a1 * a1 + b1 * b1);
  final double c2 = sqrt(a2 * a2 + b2 * b2);
  final double cBar = 0.5 * (c1 + c2);

  // 2) G factor to adjust a*
  final double cBar7 = pow(cBar, 7).toDouble();
  const double k25_7 = 6103515625.0; // 25^7
  final double G = 0.5 * (1.0 - sqrt(cBar7 / (cBar7 + k25_7)));

  // 3) Adjusted a' and chroma C'
  final double a1p = (1.0 + G) * a1;
  final double a2p = (1.0 + G) * a2;
  final double c1p = sqrt(a1p * a1p + b1 * b1);
  final double c2p = sqrt(a2p * a2p + b2 * b2);

  // 4) Hue angles h' (in degrees, 0..360)
  double hPrime(final double ap, final double b)
  {
    if (ap == 0.0 && b == 0.0) return 0.0;
    final double ang = atan2(b, ap) * 180.0 / pi;
    return (ang >= 0.0) ? ang : (ang + 360.0);
  }

  final double h1p = hPrime(a1p, b1);
  final double h2p = hPrime(a2p, b2);

  // 5) Differences
  final double dLp = l2 - l1;
  final double dCp = c2p - c1p;

  double dhp;
  if (c1p * c2p == 0.0)
  {
    dhp = 0.0;
  } else {
    dhp = h2p - h1p;
    if (dhp > 180.0) {
      dhp -= 360.0;
    } else if (dhp < -180.0) {
      dhp += 360.0;
    }
  }

  final double dHp = 2.0 * sqrt(c1p * c2p) * sin((dhp * pi / 180.0) / 2.0);

  // 6) Means
  final double lbarp = (l1 + l2) / 2.0;
  final double cbarp = (c1p + c2p) / 2.0;

  double hbarp;
  if (c1p * c2p == 0.0)
  {
    hbarp = h1p + h2p; // irrelevant when chroma is zero
  }
  else
  {
    final double hsum = h1p + h2p;
    if ((h1p - h2p).abs() > 180.0)
    {
      hbarp = (hsum < 360.0) ? (hsum + 360.0) / 2.0 : (hsum - 360.0) / 2.0;
    }
    else
    {
      hbarp = hsum / 2.0;
    }
  }

  // 7) T term
  final double T = 1.0
      - 0.17 * cos((hbarp - 30.0) * pi / 180.0)
      + 0.24 * cos((2.0 * hbarp) * pi / 180.0)
      + 0.32 * cos((3.0 * hbarp + 6.0) * pi / 180.0)
      - 0.20 * cos((4.0 * hbarp - 63.0) * pi / 180.0);

  // 8) Δθ and rc
  final double dTheta = 30.0 * exp(-pow((hbarp - 275.0) / 25.0, 2).toDouble());
  final double rc = 2.0 * sqrt(pow(cbarp, 7).toDouble() / (pow(cbarp, 7).toDouble() + k25_7));

  // 9) sl, sc, sh
  final double sl = 1.0 + (0.015 * pow(lbarp - 50.0, 2).toDouble()) /
      sqrt(20.0 + pow(lbarp - 50.0, 2).toDouble());
  final double sc = 1.0 + 0.045 * cbarp;
  final double sh = 1.0 + 0.015 * cbarp * T;

  // 10) rt
  final double rt = -sin(2.0 * dTheta * pi / 180.0) * rc;

  // 11) Final ΔE00
  final double dLterm = dLp / (kL * sl);
  final double dCterm = dCp / (kC * sc);
  final double dHterm = dHp / (kH * sh);

  final double sum = dLterm * dLterm +
      dCterm * dCterm +
      dHterm * dHterm +
      rt * dCterm * dHterm;

  // Guard against tiny negative due to floating point
  return sqrt(sum < 0.0 ? 0.0 : sum);
}


HashMap<ColorReference, ColorReference> getRampMap({required final List<KPalRampData> rampList1, required final List<KPalRampData> rampList2})
{
  final HashMap<ColorReference, ColorReference> rampMap = HashMap<ColorReference, ColorReference>();
  for (final KPalRampData kPalRampData in rampList1)
  {
    for (final ColorReference colRef in kPalRampData.references)
    {
      rampMap[colRef] = getClosestColor(inputColor: colRef, rampList: rampList2);
    }
  }
  return rampMap;
}

ColorReference getClosestColor({required final ColorReference inputColor, required final List<KPalRampData> rampList})
{
  assert(rampList.isNotEmpty);

  final double r = inputColor.getIdColor().color.r;
  final double g = inputColor.getIdColor().color.g;
  final double b = inputColor.getIdColor().color.b;
  late ColorReference closestColor;
  double closestVal = double.maxFinite;
  for (final KPalRampData kPalRampData in rampList)
  {
    for (int i = 0; i < kPalRampData.settings.colorCount; i++)
    {
       final double r2 = kPalRampData.shiftedColors[i].value.color.r;
       final double g2 = kPalRampData.shiftedColors[i].value.color.g;
       final double b2 = kPalRampData.shiftedColors[i].value.color.b;

       final double dist = getDeltaE00(redA: r, greenA: g, blueA: b, redB: r2, greenB: g2, blueB: b2);
       if (dist < closestVal)
       {
          closestColor = kPalRampData.references[i];
          closestVal = dist;
       }
    }
  }
  return closestColor;
}

bool _isPointOnLineSegment({required final CoordinateSetI p, required final CoordinateSetI a, required final CoordinateSetI b, final double epsilon = 1e-6})
{
  final int cross = (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
  if (cross.abs() > epsilon)
  {
    return false;
  }
  final double minX = min(a.x, b.x) - epsilon;
  final double maxX = max(a.x, b.x) + epsilon;
  final double minY = min(a.y, b.y) - epsilon;
  final double maxY = max(a.y, b.y) + epsilon;

  return p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY;
}

int _isLeft({required final CoordinateSetI a, required final CoordinateSetI b, required final CoordinateSetI p})
{
  return (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
}

bool isPointInPolygon({required final CoordinateSetI point, required final List<CoordinateSetI> polygon, final double epsilon = 1e-6}) {
  final int n = polygon.length;
  int windingNumber = 0;

  for (int i = 0, j = n - 1; i < n; j = i++)
  {
    final CoordinateSetI pi = polygon[i];
    final CoordinateSetI pj = polygon[j];
    if (_isPointOnLineSegment(p: point, a: pi, b: pj, epsilon: epsilon)) {
      return true;
    }

    if (pi.y <= point.y) {
      if (pj.y > point.y) {
        if (_isLeft(a: pi, b: pj, p: point) > 0) {
          windingNumber++;
        }
      }
    } else { // Edge crosses downward
      if (pj.y <= point.y) {
        if (_isLeft(a: pi, b: pj, p: point) < 0) {
          windingNumber--;
        }
      }
    }
  }

  return windingNumber != 0;
}


double getPointToEdgeDistance({required final CoordinateSetI point, required final List<CoordinateSetI> polygon})
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

    final double t = max(0, min(1, dotProduct / edgeLengthSquared));

    final double closestX = p1.x + t * dx;
    final double closestY = p1.y + t * dy;

    final double distanceSquared = (point.x - closestX) * (point.x - closestX) + (point.y - closestY) * (point.y - closestY);

    minDistance = min(minDistance, sqrt(distanceSquared));
  }

  return minDistance;
}



CoordinateSetI getMin({required final List<CoordinateSetI> coordList})
{
  final int minX = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x < b.x ? a : b).x;
  final int minY = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y < b.y ? a : b).y;
  return CoordinateSetI(x: minX, y: minY);
}

CoordinateSetI getMax({required final List<CoordinateSetI> coordList})
{
  final int maxX = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x > b.x ? a : b).x;
  final int maxY = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y > b.y ? a : b).y;
  return CoordinateSetI(x: maxX, y: maxY);
}


List<CoordinateSetI> bresenham({required final CoordinateSetI start, required final CoordinateSetI end})
{
  final List<CoordinateSetI> points = <CoordinateSetI>[];
  final CoordinateSetI d = CoordinateSetI(x: (end.x - start.x).abs(), y: (end.y - start.y).abs());
  final CoordinateSetI s = CoordinateSetI(x: start.x < end.x ? 1 : -1, y: start.y < end.y ? 1 : -1);

  int err = d.x - d.y;
  final CoordinateSetI currentPoint = CoordinateSetI.from(other: start);

  while (true)
  {
    points.add(CoordinateSetI.from(other: currentPoint));
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

Set<CoordinateSetI> _drawEllipse({required final CoordinateSetI start, required final CoordinateSetI end,
  required final void Function(int x0, int y0, int x1, int y1, int vPixels, Set<CoordinateSetI> pixels) plot,})
{
  final Set<CoordinateSetI> pixels = <CoordinateSetI>{};

  int x0 = start.x;
  int y0 = start.y;
  int x1 = end.x;
  int y1 = end.y;

  int hPixels = 0;
  int vPixels = 0;

  if (x0 > x1) [x0, x1] = <int>[x1, x0];
  if (y0 > y1) [y0, y1] = <int>[y1, y0];

  final int w = x1 - x0 + 1;
  final int h = y1 - y0 + 1;

  final int hDiameter = w - hPixels;
  final int vDiameter = h - vPixels;

  if (<int>[8, 12, 22].contains(w)) hPixels++;
  if (<int>[8, 12, 22].contains(h)) vPixels++;

  hPixels = (hDiameter > 5 ? hPixels : 0);
  vPixels = (vDiameter > 5 ? vPixels : 0);

  if (hDiameter.isEven && hDiameter > 5) hPixels--;
  if (vDiameter.isEven && vDiameter > 5) vPixels--;

  x1 -= hPixels;
  y1 -= vPixels;

  int a = (x1 - x0).abs();
  final int b = (y1 - y0).abs();
  int b1 = b & 1;

  double dx = 4 * (1 - a) * b * b.toDouble();
  double dy = 4 * (b1 + 1) * a * a.toDouble();
  double err = dx + dy + b1 * a * a.toDouble();
  double e2;

  y0 += (b + 1) ~/ 2;
  y1 = y0 - b1;
  a = 8 * a * a;
  b1 = 8 * b * b;

  final int initialY0 = y0;
  final int initialY1 = y1;
  final int initialX0 = x0;
  final int initialX1 = x1 + hPixels;

  // Main loop
  do
  {
    plot(x0, y0 + vPixels, x1 + hPixels, y1, vPixels, pixels);

    e2 = 2 * err;
    if (e2 <= dy)
    {
      y0++;
      y1--;
      err += dy += a.toDouble();
    }
    if (e2 >= dx || 2 * err > dy)
    {
      x0++;
      x1--;
      err += dx += b1.toDouble();
    }
  }
  while (x0 <= x1);

  // Flat ellipse correction
  while (y0 + vPixels - y1 + 1 <= h)
  {
    plot(x0 - 1, y0 + vPixels, x1 + 1 + hPixels, y1, vPixels, pixels);
    y0++;
    y1--;
  }

  // Extra horizontal/vertical midsection pixels
  if (hPixels > 0)
  {
    for (int y = y1 + 1; y <= y0 + vPixels - 1; y++)
    {
      plot(x0, y, x1 + hPixels, y, 0, pixels);
    }
  }
  if (vPixels > 0)
  {
    for (int y = initialY1 + 1; y < initialY0 + vPixels; y++) {
      pixels.add(CoordinateSetI(x: initialX0, y: y));
      pixels.add(CoordinateSetI(x: initialX1, y: y));
    }
  }

  return pixels;
}



Set<CoordinateSetI> drawStrokedEllipse({required final CoordinateSetI start, required final CoordinateSetI end, required final int strokeWidth})
{
final int width = end.x - start.x + 1;
final int height = end.y - start.y + 1;

if (strokeWidth == 1)
{
  return _drawEllipse(
    start: start,
    end: end,
    plot: (final int x0, final int y0, final int x1, final int y1, final int vPixels, final Set<CoordinateSetI> pixels)
    {
      pixels.add(CoordinateSetI(x: x0, y: y0));       // Quadrant II
      pixels.add(CoordinateSetI(x: x1, y: y0));       // Quadrant I
      pixels.add(CoordinateSetI(x: x0, y: y1));       // Quadrant III
      pixels.add(CoordinateSetI(x: x1, y: y1));       // Quadrant IV
    },
  );
}
else
{
  final Set<CoordinateSetI> pixels = _drawEllipse(
    start: start,
    end: end,
    plot: (final int x0, final int y0, final int x1, final int y1, final int vPixels, final Set<CoordinateSetI> pixels)
    {
      for (int x = x0; x <= x1; x++)
      {
        pixels.add(CoordinateSetI(x: x, y: y0)); // top half
        pixels.add(CoordinateSetI(x: x, y: y1)); // bottom half
      }
    },
  );

  if (width > strokeWidth * 2 && height > strokeWidth * 2)
  {
    final CoordinateSetI innerSelectionStart = CoordinateSetI(x: start.x + strokeWidth, y: start.y + strokeWidth);
    final CoordinateSetI innerSelectionEnd = CoordinateSetI(x: end.x - strokeWidth, y: end.y - strokeWidth);
    final Set<CoordinateSetI> innerCircleContent = drawFilledEllipse(start: innerSelectionStart, end: innerSelectionEnd);
    pixels.removeAll(innerCircleContent);
  }
  return pixels;
}
}


Set<CoordinateSetI> drawFilledEllipse({required final CoordinateSetI start, required final CoordinateSetI end})
{
  return _drawEllipse(
    start: start,
    end: end,
    plot: (final int x0, final int y0, final int x1, final int y1, final int vPixels, final Set<CoordinateSetI> pixels)
    {
      for (int x = x0; x <= x1; x++)
      {
        pixels.add(CoordinateSetI(x: x, y: y0)); // top half
        pixels.add(CoordinateSetI(x: x, y: y1)); // bottom half
      }
    },
  );
}

List<CoordinateSetI> getCoordinateNeighbors({required final CoordinateSetI pixel, required final bool withDiagonals})
{
  final List<CoordinateSetI> neighbors =  <CoordinateSetI>[
    CoordinateSetI(x: pixel.x + 1, y: pixel.y),
    CoordinateSetI(x: pixel.x - 1, y: pixel.y),
    CoordinateSetI(x: pixel.x, y: pixel.y + 1),
    CoordinateSetI(x: pixel.x, y: pixel.y - 1),
  ];

  if (withDiagonals)
  {
    neighbors.add(CoordinateSetI(x: pixel.x + 1, y: pixel.y + 1));
    neighbors.add(CoordinateSetI(x: pixel.x - 1, y: pixel.y - 1));
    neighbors.add(CoordinateSetI(x: pixel.x + 1, y: pixel.y - 1));
    neighbors.add(CoordinateSetI(x: pixel.x - 1, y: pixel.y + 1));
  }

  return neighbors;
}

int argbToRgba({required final int argb}) {
  final int a = (argb & 0xFF000000) >> 24; // Extract alpha component
  final int r = (argb & 0x00FF0000) >> 16; // Extract red component
  final int g = (argb & 0x0000FF00) >> 8;  // Extract green component
  final int b = argb & 0x000000FF;       // Extract blue component

  // Combine components into RGBA format
  final int rgba = (r << 24) | (g << 16) | (b << 8) | a;
  return rgba;
}

const double twoPi = 2 * pi;

double normAngle({required final double angle})
{
  return angle - (twoPi * (angle / twoPi).floor());
}

double deg2rad({required final double angle})
{
  return angle * (pi / 180.0);
}

double rad2deg({required final double angle})
{
  return angle * (180.0 / pi);
}

double getDistance({required final CoordinateSetI a, required final CoordinateSetI b})
{
  return sqrt(((a.x - b.x) * (a.x - b.x)) + ((a.y - b.y) * (a.y - b.y)));
}

Future<CoordinateColorMapNullable> getMergedColors({required final Frame frame, required final CoordinateSetI canvasSize}) async
{
  final CoordinateColorMapNullable colorData = CoordinateColorMapNullable();
  final Iterable<RasterableLayerState> layerList = frame.layerList.getVisibleRasterLayers();
  for (int x = 0; x < canvasSize.x; x++)
  {
    for (int y = 0; y < canvasSize.y; y++)
    {
      for (final RasterableLayerState layer in layerList)
      {
        final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        final ColorReference? colAtPos = layer.rasterPixels[coord];
        if (colAtPos != null)
        {
          colorData[coord] = colAtPos;
          break;
        }
      }
    }
  }
  return colorData;
}

Future<ui.Image> getImageFromLayers({
  required final LayerCollection layerCollection,
  required final CoordinateSetI canvasSize,
  required final SelectionList selection,
  final Frame? frame,
  final List<RasterableLayerState>? layerStack,
  final int scalingFactor = 1,}) async
{
  List<RasterableLayerState> layerList;
  if (layerStack != null)
  {
    layerList = layerStack;
  }
  else
  {
    layerList = List<RasterableLayerState>.empty(growable: true);
    layerList.addAll(layerCollection.getVisibleRasterLayers());
  }

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  for (int i = layerList.length - 1; i >= 0; i--)
  {
    final LayerState cLayer = layerList[i];
    if (cLayer.visibilityState.value == LayerVisibilityState.visible && cLayer is RasterableLayerState)
    {
      final ui.Image? mapImage = frame != null ? cLayer.rasterImageMap.value[frame]?.raster : null;
      final ui.Image? rasterImage = cLayer.rasterImage.value;
      final ui.Image? previousRaster = cLayer.previousRaster;
      final ui.Image? imageToUse = mapImage ?? (rasterImage ?? previousRaster);

      if (imageToUse != null)
      {
        paintImage(
            canvas: canvas,
            rect: ui.Rect.fromLTWH(0, 0,
                canvasSize.x.toDouble() * scalingFactor,
                canvasSize.y.toDouble() * scalingFactor,),
            image: imageToUse,
            fit: BoxFit.none,
            scale: 1.0 / scalingFactor.toDouble(),
            alignment: Alignment.topLeft,
            filterQuality: FilterQuality.none,);
        if (layerStack != null && selection.hasValues() && i == layerCollection.selectedLayerIndex)
        {
          final Paint paint = Paint();
          for (final MapEntry<CoordinateSetI, ColorReference?> entry in selection.selectedPixels.entries)
          {
            if (entry.value != null)
            {
              paint.color = entry.value!.getIdColor().color;
              canvas.drawRect(Rect.fromLTWH(
                  entry.key.x.toDouble() * scalingFactor,
                  entry.key.y.toDouble() * scalingFactor,
                  scalingFactor.toDouble(),
                  scalingFactor.toDouble(),),
                  paint,);
            }
          }
        }
      }
    }
  }
  return recorder.endRecording().toImage(canvasSize.x * scalingFactor, canvasSize.y * scalingFactor);
}


//TODO this definitely needs some work
Future<ui.Image?> getImageFromLoadFileSet({required final LoadFileSet loadFileSet, required final CoordinateSetI size}) async
{
  if (loadFileSet.historyState != null)
  {
    final HistoryState state = loadFileSet.historyState!;

    final List<KPalRampData> ramps = <KPalRampData>[];
    for (final HistoryRampData hRampData in state.rampList)
    {
      final KPalRampSettings settings = KPalRampSettings.from(other: hRampData.settings);
      ramps.add(KPalRampData(uuid: hRampData.uuid, settings: settings, historyShifts: hRampData.shiftSets));
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final LinkedHashSet<HistoryLayer> layerList = state.timeline.getLayersForFrameIndex(frameIndex: 0);

    for (int i = layerList.length - 1; i >= 0; i--)
    {
      final HistoryLayer cLayer = layerList.elementAt(i);
      if (cLayer.visibilityState == LayerVisibilityState.visible && cLayer.runtimeType == HistoryDrawingLayer)
      {
        final HistoryDrawingLayer historyDrawingLayer = cLayer as HistoryDrawingLayer;
        final CoordinateColorMap content = HashMap<CoordinateSetI, ColorReference>();
        for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in historyDrawingLayer.data.entries)
        {
          KPalRampData? ramp;
          for (int i = 0; i < ramps.length; i++)
          {
            if (ramps[i].uuid == state.rampList[entry.value.rampIndex].uuid)
            {
              ramp = ramps[i];
              break;
            }
          }
          if (ramp != null)
          {
            content[CoordinateSetI.from(other: entry.key)] = ColorReference(colorIndex: entry.value.colorIndex, ramp: ramp);
          }
        }
        final DrawingLayerState drawingLayer = DrawingLayerState(size: state.canvasSize, content: content, ramps: ramps);
        drawingLayer.doManualRaster = true;
        while (drawingLayer.isRasterizing)
        {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        if (drawingLayer.rasterImage.value != null)
        {
          paintImage(
              canvas: canvas,
              rect: ui.Rect.fromLTWH(0, 0,
                  state.canvasSize.x.toDouble(),
                  state.canvasSize.y.toDouble(),),
              image: drawingLayer.rasterImage.value!,
              fit: BoxFit.none,
              alignment: Alignment.topLeft,
              filterQuality: FilterQuality.none,);
        }
      }
    }
    return recorder.endRecording().toImage(size.x, size.y);
  }
  else
  {
    return null;
  }
}

String extractFilenameFromPath({required final String? path, final bool keepExtension = true})
{
  if (path != null && path.isNotEmpty)
  {
    return keepExtension ? p.basename(path) : p.basenameWithoutExtension(path);
  }
  else
  {
    return "";
  }
}

String getBaseDir({required final String fullPath})
{
  return p.dirname(fullPath);
}

List<int> intToBytes({required final int value, required final int length, final bool reverse = false})
{
  final ByteData bytes = ByteData(length);
  if (length == 1)
  {
    bytes.setInt8(0, value);
  } else if (length == 2)
  {
    bytes.setInt16(0, value, Endian.little);
  } else if (length == 4)
  {
    bytes.setInt32(0, value, Endian.little);
  }
  else
  {
    throw ArgumentError('Invalid byte length: $length. Supported lengths are 1, 2, or 4 bytes.');
  }

  // Convert to Uint8List and reverse if necessary
  return reverse ? bytes.buffer.asUint8List().reversed.toList() : bytes.buffer.asUint8List();
}

List<int> float32ToBytes({required final double value, final bool reverse = false})
{
  final ByteData bytes = ByteData(4)..setFloat32(0, value, Endian.little);
  return reverse ? bytes.buffer.asUint8List().reversed.toList() : bytes.buffer.asUint8List();
}

List<int> stringToBytes({required final String value})
{
  return utf8.encode(value);
}

String escapeXml({required final String input})
{
  return input.replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

Future<String?> replaceFileExtension({required final String filePath, required final String newExtension, required final bool inputFileMustExist}) async
{
  if ((!await File(filePath).exists()) && inputFileMustExist)
  {
    return null;
  }

  final String currentExtension = p.extension(filePath);
  if (currentExtension.isEmpty)
  {
    return null;
  }
  return filePath.replaceAll(RegExp(r'\.[^.]+$'), '.$newExtension');
}

String formatDateTime({required final DateTime dateTime})
{
  final String year = dateTime.year.toString();
  final String month = dateTime.month.toString().padLeft(2, '0'); // Pad with zero if needed
  final String day = dateTime.day.toString().padLeft(2, '0');
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}

HashMap<int, int> remapIndices({required final int oldLength, required final int newLength})
{
  final HashMap<int, int> indexMap = HashMap<int, int>();
  final int centerOld = oldLength ~/ 2;
  final int centerNew = newLength ~/ 2;
  for (int i = 0; i < oldLength; i++)
  {
    final int dist = i - centerOld;
    final int newIndex = (centerNew + dist).clamp(0, newLength - 1);
    indexMap[i] = newIndex;
  }

  return indexMap;
}

int? getRampIndex({required final String uuid, required final List<HistoryRampData> ramps})
{
  int? rampIndex;
  for (int i = 0; i < ramps.length; i++)
  {
    if (ramps[i].uuid == uuid)
    {
      rampIndex = i;
      break;
    }
  }
  return rampIndex;
}

bool rampsHaveEqualLengths({required final List<KPalRampData> ramps})
{
  for (int i = 1; i < ramps.length; i++)
  {
    if (ramps[i].settings.colorCount != ramps[i - 1].settings.colorCount)
    {
      return false;
    }
  }
  return true;
}

void exitApplication({final int exitCode = 0})
{
  clearRecoverDir().then((final void value)
  {
    if (Platform.isAndroid)
    {
      SystemNavigator.pop();
    }
    else
    {
      exit(exitCode);
    }
  },);
}

Version? convertStringToVersion({required final String version})
{
  final RegExp versionRegex = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?$');
  final RegExpMatch? match = versionRegex.firstMatch(version);
  if (match != null)
  {
    final List<int> numbers = match.groups(<int>[1, 2, 3, 4])
        .whereType<String>() // Filter out null values
        .map((final String str) => int.parse(str)) // Parse remaining strings to integers
        .toList();
    return Version(numbers[0], numbers[1], numbers[2]);
  }
  else
  {
    return null;
  }
}

Future<void> launchURL({required final String url}) async
{
  if (!await launchUrl(Uri.parse(url)))
  {
    throw Exception("Could not launch");
  }
}
