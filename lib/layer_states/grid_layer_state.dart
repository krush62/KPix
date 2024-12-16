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

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';

class GridLayerState extends LayerState
{
  final ValueNotifier<int> opacityNotifier;
  final ValueNotifier<GridType> gridTypeNotifier;
  final ValueNotifier<int> brightnessNotifier;
  final ValueNotifier<int> intervalXNotifier;
  final ValueNotifier<int> intervalYNotifier;
  final ValueNotifier<double> horizonPositionNotifier;
  final ValueNotifier<double> vanishingPoint1Notifier;
  final ValueNotifier<double> vanishingPoint2Notifier;
  final ValueNotifier<double> vanishingPoint3Notifier;
  bool _isRendering = false;
  bool _shouldRender = true;
  ui.Image? raster;

  GridLayerState({
    required final int opacity,
    required final GridType gridType,
    required final int brightness,
    required final int intervalX,
    required final int intervalY,
    required final double horizonPosition,
    required final double vanishingPoint1,
    required final double vanishingPoint2,
    required final double vanishingPoint3,
  }) :
      opacityNotifier = ValueNotifier<int>(opacity),
      gridTypeNotifier = ValueNotifier<GridType>(gridType),
      brightnessNotifier = ValueNotifier<int>(brightness),
      intervalXNotifier = ValueNotifier<int>(intervalX),
      intervalYNotifier = ValueNotifier<int>(intervalY),
      horizonPositionNotifier = ValueNotifier<double>(horizonPosition),
      vanishingPoint1Notifier = ValueNotifier<double>(vanishingPoint1),
      vanishingPoint2Notifier = ValueNotifier<double>(vanishingPoint2),
      vanishingPoint3Notifier = ValueNotifier<double>(vanishingPoint3)
  {
    opacityNotifier.addListener(_valueChanged);
    gridTypeNotifier.addListener(_valueChanged);
    brightnessNotifier.addListener(_valueChanged);
    intervalXNotifier.addListener(_valueChanged);
    intervalYNotifier.addListener(_valueChanged);
    horizonPositionNotifier.addListener(_valueChanged);
    vanishingPoint1Notifier.addListener(_valueChanged);
    vanishingPoint2Notifier.addListener(_valueChanged);
    vanishingPoint3Notifier.addListener(_valueChanged);
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {_updateTimerCallback(timer: t);});
  }

  factory GridLayerState.from({required final GridLayerState other})
  {
    return GridLayerState(
      opacity: other.opacity,
      brightness: other.brightness,
      gridType: other.gridType,
      intervalX: other.intervalX,
      intervalY: other.intervalY,
      horizonPosition: other.horizonPosition,
      vanishingPoint1: other.vanishingPoint1,
      vanishingPoint2: other.vanishingPoint2,
      vanishingPoint3: other.vanishingPoint3,
    );
  }



  int get opacity
  {
    return opacityNotifier.value;
  }

  GridType get gridType
  {
    return gridTypeNotifier.value;
  }

  int get brightness
  {
    return brightnessNotifier.value;
  }

  int get intervalX
  {
    return intervalXNotifier.value;
  }

  int get intervalY
  {
    return intervalYNotifier.value;
  }

  double get horizonPosition
  {
    return horizonPositionNotifier.value;
  }

  double get vanishingPoint1
  {
    return vanishingPoint1Notifier.value;
  }

  double get vanishingPoint2
  {
    return vanishingPoint2Notifier.value;
  }

  double get vanishingPoint3
  {
    return vanishingPoint3Notifier.value;
  }

  void _valueChanged()
  {
    _shouldRender = true;
  }

  void manualRender()
  {
    _shouldRender = true;
  }

  void _updateTimerCallback({required final Timer timer})
  {
    if (_shouldRender && !_isRendering)
    {
      _isRendering = true;
      _createRaster().then((final ui.Image image)
      {
        _rasterCreated(image: image);
      });
    }
  }

  void _rasterCreated({required final ui.Image image})
  {
    raster = image;
    thumbnail.value = image;
    _isRendering = false;
    _shouldRender = false;
  }

  void addCoordListToBytes({required final Set<CoordinateSetI> coords, required final ByteData byteDataImg, required final CoordinateSetI canvasSize, required final int brightness, required final int opacity})
  {
    for (final CoordinateSetI coord in coords)
    {
      addCoordToBytes(x: coord.x, y: coord.y, byteDataImg: byteDataImg, canvasSize: canvasSize, brightness: brightness, opacity: opacity);
    }
  }

  void addCoordToBytes({required final int x, required final int y, required final ByteData byteDataImg, required final CoordinateSetI canvasSize, required final int brightness, required final int opacity})
  {
    if (x >= 0 && x < canvasSize.x && y >= 0 && y < canvasSize.y)
    {
      final int pixelIndex = (y * canvasSize.x + x) * 4;
      byteDataImg.setUint8(pixelIndex + 0, brightness);
      byteDataImg.setUint8(pixelIndex + 1, brightness);
      byteDataImg.setUint8(pixelIndex + 2, brightness);
      byteDataImg.setUint8(pixelIndex + 3, opacity);
    }
  }

  Future<CoordinateColorMap> getHashMap() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final Set<CoordinateSetI> rasterCoords = await getRasterData();
    final CoordinateColorMap theMap = HashMap<CoordinateSetI, ColorReference>();
    final ColorReference color = appState.selectedColor!;
    for (final CoordinateSetI coord in rasterCoords)
    {
       theMap[coord] = color;
    }
    return theMap;
  }

  Future<ui.Image> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final ByteData byteDataImg = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    final int colorOpacity = ((opacity.toDouble() / 100.0) * 255.0).round();
    final int colorBrightness = ((brightness.toDouble() / 100.0) * 255.0).round();
    final int colorBrightnessPremultiplied = (colorBrightness * colorOpacity) ~/ 255;


    final Set<CoordinateSetI> rasterCoords = await getRasterData();
    addCoordListToBytes(coords: rasterCoords, byteDataImg: byteDataImg, canvasSize: appState.canvasSize, brightness: colorBrightnessPremultiplied, opacity: colorOpacity);


    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataImg.buffer.asUint8List(),
      appState.canvasSize.x,
      appState.canvasSize.y,
      ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
      {
        completerImg.complete(convertedImage);
      }
    );
    return completerImg.future;
  }

  Future<Set<CoordinateSetI>> getRasterData() async
  {
    final Set<CoordinateSetI> rasterCoords = <CoordinateSetI>{};
    final AppState appState = GetIt.I.get<AppState>();

    if (gridType == GridType.onePointPerspective || gridType == GridType.twoPointPerspective || gridType == GridType.threePointPerspective)
    {
      final int horizonY = (appState.canvasSize.y.toDouble() * horizonPosition).round();
      rasterCoords.addAll(bresenham(start: CoordinateSetI(x: 0, y: horizonY), end: CoordinateSetI(x: appState.canvasSize.x - 1, y: horizonY)));

      if (gridType == GridType.onePointPerspective)
      {
        final CoordinateSetI vanishingPoint = CoordinateSetI(x: appState.canvasSize.x ~/ 2, y: horizonY);
        for (int i = 1; i <= intervalX; i++)
        {
          final double t = i / (intervalX + 1);
          final double startY = appState.canvasSize.y * t;
          final double startX = appState.canvasSize.x * t;
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: 0, y: startY.round()), end: vanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: appState.canvasSize.x - 1, y: startY.round()), end: vanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: 0), end: vanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: appState.canvasSize.y - 1), end: vanishingPoint));
        }
      }
      else if (gridType == GridType.twoPointPerspective)
      {
        final CoordinateSetI leftVanishingPoint = CoordinateSetI(x: (appState.canvasSize.x * vanishingPoint1).round(), y: horizonY);
        final CoordinateSetI rightVanishingPoint = CoordinateSetI(x: (appState.canvasSize.x * vanishingPoint2).round(), y: horizonY);

        for (int i = 1; i <= intervalX; i++)
        {
          final double t = i / (intervalX + 1);
          final double startY = appState.canvasSize.y * t;
          final double startX = appState.canvasSize.x * t;
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: 0, y: startY.round()), end: leftVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: 0, y: startY.round()), end: rightVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: appState.canvasSize.x - 1, y: startY.round()), end: leftVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: appState.canvasSize.x - 1, y: startY.round()), end: rightVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: 0), end: leftVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: 0), end: rightVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: appState.canvasSize.y - 1), end: leftVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: appState.canvasSize.y - 1), end: rightVanishingPoint));
        }
      }
      else if (gridType == GridType.threePointPerspective)
      {
        final CoordinateSetI verticalVanishingPoint = CoordinateSetI(x: appState.canvasSize.x ~/ 2, y: (appState.canvasSize.x.toDouble() * vanishingPoint3).round());
        final CoordinateSetI leftVanishingPoint = CoordinateSetI(x: (appState.canvasSize.x * vanishingPoint1).round(), y: horizonY);
        final CoordinateSetI rightVanishingPoint = CoordinateSetI(x: (appState.canvasSize.x * vanishingPoint2).round(), y: horizonY);

        for (int i = 1; i <= intervalX; i++)
        {
          final double t = i / (intervalX + 1);
          final double startY = appState.canvasSize.y * t;
          final double startX = appState.canvasSize.x * t;
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: appState.canvasSize.x - 1, y: startY.round()), end: leftVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: 0, y: startY.round()), end: rightVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: 0, y: startY.round()), end: verticalVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: appState.canvasSize.x - 1, y: startY.round()), end: verticalVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: verticalVanishingPoint.y > horizonY ? 0 : appState.canvasSize.y - 1), end: verticalVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: verticalVanishingPoint.y < horizonY ? 0 : appState.canvasSize.y - 1), end: leftVanishingPoint));
          rasterCoords.addAll(bresenham(start: CoordinateSetI(x: startX.round(), y: verticalVanishingPoint.y < horizonY ? 0 : appState.canvasSize.y - 1), end: rightVanishingPoint));
        }

      }
    }
    else
    {
      for (int y = 0; y < appState.canvasSize.y; y++)
      {
        for (int x = 0; x < appState.canvasSize.x; x++)
        {
          bool shouldDraw = false;

          if (gridType == GridType.rectangular)
          {
            if (x % intervalX == 0 || y % intervalY == 0)
            {
              shouldDraw = true;
            }
          }
          else if (gridType == GridType.diagonal)
          {
            if ((x + y) % intervalX == 0 || (x - y).abs() % intervalY == 0)
            {
              shouldDraw = true;
            }
          }
          else if (gridType == GridType.isometric)
          {
            if (((x ~/ 2) + y) % intervalX == 0)
            {
              shouldDraw = true;
            }
            if (((x ~/ 2) - y).abs() % intervalY == 0)
            {
              shouldDraw = true;
            }
          }
          else if (gridType == GridType.hexagonal)
          {
            final int height = intervalY - 1;
            final int tripleInterval = intervalX * 3;
            final bool flip = (y ~/ height).isEven;
            if (y % height == 0)
            {
              if (flip)
              {
                if (x % tripleInterval < intervalX)
                {
                  shouldDraw = true;
                }
              }
              else
              {
                if ((x + (1.5 * intervalX).floor()) % tripleInterval < intervalX)
                {
                  shouldDraw = true;
                }
              }
            }

            final int leftUpper = (x ~/ tripleInterval + 1) * tripleInterval;
            final int rightUpper = (x ~/ tripleInterval) * tripleInterval + intervalX;

            final bool isLeft = (leftUpper - x).abs() < (rightUpper - x).abs();
            final int tx1 = isLeft ? leftUpper : rightUpper;
            final int tx2 = isLeft ? tx1 - (intervalX ~/2) : tx1 + (intervalX ~/2);
            final int ty1 = (y ~/ height) * height;
            final int ty2 = ty1 + height;
            final CoordinateSetI t1 = CoordinateSetI(x: flip ? tx1 : tx2, y: ty1);
            final CoordinateSetI t2 = CoordinateSetI(x: flip ? tx2 : tx1, y: ty2);
            final List<CoordinateSetI> line1 = bresenham(start: t1, end: t2);
            final CoordinateSetI current = CoordinateSetI(x: x, y: y);
            if (line1.contains(current))
            {
              shouldDraw = true;
            }

          }
          else if (gridType == GridType.triangular)
          {
            if (y % intervalY == 0)
            {
              shouldDraw = true;
            }
            else
            {
              final bool flip = (y ~/ intervalY).isEven;
              final int tipX = (x ~/ intervalX) * intervalX + (intervalX ~/ 2);
              final int tipY = flip ? (y ~/ intervalY) * intervalY : (y ~/ intervalY + 1) * intervalY + 1;
              final int bottomY = flip ? tipY + intervalY: tipY - intervalY;
              final int bottomXR = tipX + (intervalX ~/ 2);
              final int bottomXL = bottomXR - intervalX;
              final CoordinateSetI tip = CoordinateSetI(x: tipX, y: tipY);
              final CoordinateSetI bl = CoordinateSetI(x: bottomXL, y: bottomY);
              final CoordinateSetI br = CoordinateSetI(x: bottomXR, y: bottomY);
              final List<CoordinateSetI> lineToLeft = bresenham(start: tip, end: bl);
              final List<CoordinateSetI> lineToRight = bresenham(start: tip, end: br);
              final CoordinateSetI current = CoordinateSetI(x: x, y: y);
              if (lineToLeft.contains(current) || lineToRight.contains(current))
              {
                shouldDraw = true;
              }
            }
          }
          else if (gridType == GridType.brick)
          {
            if (y % intervalY == 0)
            {
              shouldDraw = true;
            }
            else
            {
              int tipX = (x ~/ intervalX) * intervalX;
              if ((y ~/ intervalY).isEven)
              {
                tipX += intervalX ~/2;
              }
              if (x == tipX)
              {
                shouldDraw = true;
              }
            }
          }

          if (shouldDraw)
          {
            rasterCoords.add(CoordinateSetI(x: x, y: y));
          }
        }
      }
    }
    return rasterCoords;
  }

}

