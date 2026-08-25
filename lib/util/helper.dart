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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/color_helper.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

const int _halfCircle = 180;

class CoordinateSetD
{
  double x = 0;
  double y = 0;

  CoordinateSetD({required this.x, required this.y});

  factory CoordinateSetD.zero()
  {
    return CoordinateSetD(x: 0.0, y: 0.0);
  }

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

  factory CoordinateSetI.zero()
  {
    return CoordinateSetI(x: 0, y: 0);
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

  /// Checks if the given coordinates are between 0 and the current value.
  bool contains({required final CoordinateSetI coord})
  {
    return coord.x >= 0 && coord.y >= 0 && coord.x < x && coord.y < y;
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

/// Returns true if the application can see files created by other applications
/// in shared storage (Android "All files access" permission).
/// Always returns true on platforms other than Android.
Future<bool> hasAllFilesAccess() async
{
  if (kIsWeb || !Platform.isAndroid)
  {
    return true;
  }
  try
  {
    const MethodChannel channel = MethodChannel('app.channel.shared.data');
    final bool? result = await channel.invokeMethod<bool>('hasAllFilesAccess');
    return result ?? false;
  }
  on PlatformException
  {
    return false;
  }
}

/// Opens the Android system settings page for the "All files access" permission.
/// Does nothing on platforms other than Android.
Future<void> openAllFilesAccessSettings() async
{
  if (!kIsWeb && Platform.isAndroid)
  {
    try
    {
      const MethodChannel channel = MethodChannel('app.channel.shared.data');
      await channel.invokeMethod<bool>('openAllFilesAccessSettings');
    }
    on PlatformException
    {
      //the settings page could not be opened, nothing to do here
    }
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

/// Calculates the angle between two points.
double calculateAngle({required final CoordinateSetI startPos, required final CoordinateSetI endPos})
{
  final int dx = endPos.x - startPos.x;
  final int dy = endPos.y - startPos.y;
  final double angle = atan2(dy, dx);
  final double angleInDegrees = angle * (_halfCircle / pi);
  return angleInDegrees;
}






/// Returns true if the point is on the line segment.
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


/// Returns true if the polygon contains the point.
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


/// Returns the distance between the point and the closest edge of the polygon.
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


/// Returns a coordinate set with the minimum values of x and y.
CoordinateSetI getMin({required final List<CoordinateSetI> coordList})
{
  final int minX = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x < b.x ? a : b).x;
  final int minY = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y < b.y ? a : b).y;
  return CoordinateSetI(x: minX, y: minY);
}

/// Returns a coordinate set with the maximum values of x and y.
CoordinateSetI getMax({required final List<CoordinateSetI> coordList})
{
  final int maxX = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x > b.x ? a : b).x;
  final int maxY = coordList.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y > b.y ? a : b).y;
  return CoordinateSetI(x: maxX, y: maxY);
}

/// Implementation of Bresenham's line algorithm.
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


/// Draws a stroked ellipse inside the given bounds and stroke width.
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

/// Draws a filled ellipse inside the given bounds.
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

/// Returns a list of neighbors of the given pixel coordinate.
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



const double twoPi = 2 * pi;
/// Normalizes an angle to the range [0, 2pi).
double normAngle({required final double angle})
{
  return angle - (twoPi * (angle / twoPi).floor());
}

/// Converts an angle in degrees to radians.
double deg2rad({required final double angle})
{
  return angle * (pi / _halfCircle);
}

/// Converts an angle in radians to degrees.
double rad2deg({required final double angle})
{
  return angle * (_halfCircle / pi);
}

/// Returns the distance between two coordinate sets.
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

/// Returns the filename from the given path.
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

/// Returns the base directory of the given path.
String getBaseDir({required final String fullPath})
{
  return p.dirname(fullPath);
}

/// Converts a double to a list of bytes.
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

/// Converts a double to a list of bytes.
List<int> float32ToBytes({required final double value, final bool reverse = false})
{
  final ByteData bytes = ByteData(4)..setFloat32(0, value, Endian.little);
  return reverse ? bytes.buffer.asUint8List().reversed.toList() : bytes.buffer.asUint8List();
}

/// Converts a string to a list of bytes.
List<int> stringToBytes({required final String value})
{
  return utf8.encode(value);
}

/// Returns a string with escaped XML characters.
String escapeXml({required final String input})
{
  return input.replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

/// Replaces the extension of the file path with the new extension.
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

/// Returns a string representation of the date and time.
String formatDateTime({required final DateTime dateTime})
{
  final String year = dateTime.year.toString();
  final String month = dateTime.month.toString().padLeft(2, '0'); // Pad with zero if needed
  final String day = dateTime.day.toString().padLeft(2, '0');
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}

/// Returns a map from old indices to new indices.
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

/// Returns the index of the ramp with the given UUID.
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

/// Returns true if all ramps have the same number of colors.
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

/// Exits the application and clears the recovery directory.
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

/// Converts a string to a version object.
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

/// Launches a URL in the default browser.
Future<void> launchURL({required final String url}) async
{
  if (!await launchUrl(Uri.parse(url)))
  {
    throw Exception("Could not launch");
  }
}
