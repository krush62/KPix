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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  bool isAdjacent({required final CoordinateSetI other, required final bool withDiagonal})
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

  bool isDiagonal({required final CoordinateSetI other})
  {
    return (x - other.x).abs() == 1 && (y - other.y).abs() == 1;
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




  String colorToHexString({required final Color c, final bool withHashTag = true, final bool toUpper = false})
  {
    final String prefix = withHashTag ? "#" : "";
    final String str = '$prefix${(c.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(c.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(c.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
    if (toUpper)
    {
      return  str.toUpperCase();
    }
    else
    {
      return str;
    }
  }

  String colorToRGBString({required final Color c})
  {
    return '${(c.r * 255).toInt()} | '
        '${(c.g * 255).toInt()} | '
        '${(c.b * 255).toInt()}';
  }

  Color getColorFromHash({required final int hash, required final BuildContext context, required final bool selected})
  {
    return HSVColor.fromAHSV(1.0, (hash.abs() % 360).toDouble(), 0.3, selected ? HSVColor.fromColor(Theme.of(context).primaryColor).value : HSVColor.fromColor(Theme.of(context).primaryColorDark).value).toColor();
  }

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

  bool isPerfectSquare({required final int number})
  {
    final double squareRoot = sqrt(number);
    return squareRoot % 1 == 0;
  }

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

  LabColor rgb2lab({required final double r, required final double g, required final double b})
  {
    double x;
    double y;
    double z;
    final double r2 = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4).toDouble() : r / 12.92;
    final double g2 = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4).toDouble() : g / 12.92;
    final double b2 = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4).toDouble() : b / 12.92;
    x = (r2 * 0.4124 + g2 * 0.3576 + b2 * 0.1805) / 0.95047;
    y = (r2 * 0.2126 + g2 * 0.7152 + b2 * 0.0722) / 1.00000;
    z = (r2 * 0.0193 + g2 * 0.1192 + b2 * 0.9505) / 1.08883;
    x = (x > 0.008856) ? pow(x, 1.0 / 3.0).toDouble() : (7.787 * x) + 16.0 / 116.0;
    y = (y > 0.008856) ? pow(y, 1.0 / 3.0).toDouble() : (7.787 * y) + 16.0 / 116.0;
    z = (z > 0.008856) ? pow(z, 1.0 / 3.0).toDouble() : (7.787 * z) + 16.0 / 116.0;
    return LabColor(L: (116.0 * y) - 16.0, A: 500.0 * (x - y), B: 200.0 * (y - z));
  }

  double getDeltaE(
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

         final double dist = getDeltaE(redA: r, greenA: g, blueA: b, redB: r2, greenB: g2, blueB: b2);
         if (dist < closestVal)
         {
            closestColor = kPalRampData.references[i];
            closestVal = dist;
         }
      }
    }
    return closestColor;
  }

  bool isPointOnLineSegment({required final CoordinateSetI p, required final CoordinateSetI a, required final CoordinateSetI b})
  {
    return p.x <= max(a.x, b.x) && p.x >= min(a.x, b.x) &&
        p.y <= max(a.y, b.y) && p.y >= min(a.y, b.y) &&
        (b.x - a.x) * (p.y - a.y) == (p.x - a.x) * (b.y - a.y);
  }

  bool isPointInPolygon({required final CoordinateSetI point, required final List<CoordinateSetI> polygon}) {
    final int n = polygon.length;
    bool inside = false;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      // Check if the point is on the current edge
      if (isPointOnLineSegment(p: point, a: polygon[i], b: polygon[j])) {
        return true;
      }

      if (((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
          (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x)) {
        inside = !inside;
      }
    }
    return inside;
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

  Future<ui.Image> getImageFromLayers({
    required final LayerCollection layerCollection,
    required final CoordinateSetI canvasSize,
    required final SelectionList selection,
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
        if (cLayer.rasterImage.value != null)
        {
          paintImage(
              canvas: canvas,
              rect: ui.Rect.fromLTWH(0, 0,
                  canvasSize.x.toDouble() * scalingFactor,
                  canvasSize.y.toDouble() * scalingFactor,),
              image: cLayer.rasterImage.value!,
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

      final List<HistoryLayer> layerList = state.timeline.frames[0].layers;

      for (int i = layerList.length - 1; i >= 0; i--)
      {
        if (layerList[i].visibilityState == LayerVisibilityState.visible && layerList[i].runtimeType == HistoryDrawingLayer)
        {
          final HistoryDrawingLayer historyDrawingLayer = layerList[i] as HistoryDrawingLayer;
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
    return filePath.replaceAll(RegExp(r'\.[^\.]+$'), '.$newExtension');
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
