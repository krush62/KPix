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
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';

class GridLayerState extends LayerState
{
  final ValueNotifier<int> opacityNotifier;
  final ValueNotifier<GridType> gridTypeNotifier;
  final ValueNotifier<int> brightnessNotifier;
  final ValueNotifier<int> intervalXNotifier;
  final ValueNotifier<int> intervalYNotifier;
  bool _isRendering = false;
  bool _shouldRender = true;
  ui.Image? raster;

  GridLayerState({
    required final int opacity,
    required final GridType gridType,
    required final int brightness,
    required final int intervalX,
    required final int intervalY}) :
      opacityNotifier = ValueNotifier(opacity),
      gridTypeNotifier = ValueNotifier(gridType),
      brightnessNotifier = ValueNotifier(brightness),
      intervalXNotifier = ValueNotifier(intervalX),
      intervalYNotifier = ValueNotifier(intervalY)
  {
    opacityNotifier.addListener(_valueChanged);
    gridTypeNotifier.addListener(_valueChanged);
    brightnessNotifier.addListener(_valueChanged);
    intervalXNotifier.addListener(_valueChanged);
    intervalYNotifier.addListener(_valueChanged);
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {_updateTimerCallback(timer: t);});
  }

  factory GridLayerState.from({required GridLayerState other})
  {
    return GridLayerState(
      opacity: other.opacity,
      brightness: other.brightness,
      gridType: other.gridType,
      intervalX: other.intervalX,
      intervalY: other.intervalY
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

  Future<ui.Image> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final ByteData byteDataImg = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    final int colorOpacity = ((opacity.toDouble() / 100.0) * 255.0).round();
    final int colorBrightness = ((brightness.toDouble() / 100.0) * 255.0).round();
    final int colorBrightnessPremultiplied = (colorBrightness * colorOpacity) ~/ 255;

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
          final height = intervalY - 1;
          final int tripleInterval = (intervalX * 3);
          final bool flip = (y ~/ height) % 2 == 0;
          if (y % (height) == 0)
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
          final int rightUpper = ((x ~/ tripleInterval) * tripleInterval + intervalX);

          final bool isLeft = (leftUpper - x).abs() < (rightUpper - x).abs();
          final int tx1 = (isLeft) ? leftUpper : rightUpper;
          final int tx2 = (isLeft) ? tx1 - (intervalX ~/2) : tx1 + (intervalX ~/2);
          int ty1 = (y ~/ height) * height;
          int ty2 = ty1 + height;
          CoordinateSetI t1 = CoordinateSetI(x: flip ? tx1 : tx2, y: flip ? ty1 - 1 : ty1);
          CoordinateSetI t2 = CoordinateSetI(x: flip ? tx2 : tx1, y: flip ? ty2 : ty2 + 1);
          List<CoordinateSetI> line1 = Helper.bresenham(start: t1, end: t2);
          final CoordinateSetI current = CoordinateSetI(x: x, y: y);
          if (line1.contains(current))
          {
            shouldDraw = true;
          }

        }
        else if (gridType == GridType.triangular)
        {
          if (y % (intervalY) == 0)
          {
            shouldDraw = true;
          }
          else
          {
            final bool flip = (y ~/ intervalY) % 2 == 0;
            final int tipX = (x ~/ intervalX) * intervalX + (intervalX ~/ 2);
            final int tipY = flip ? (y ~/ intervalY) * intervalY : (y ~/ intervalY + 1) * intervalY + 1;
            final int bottomY = flip ? tipY + intervalY: tipY - intervalY;
            final int bottomXR = tipX + (intervalX ~/ 2);
            final int bottomXL = bottomXR - intervalX;
            final CoordinateSetI tip = CoordinateSetI(x: tipX, y: tipY);
            final CoordinateSetI bl = CoordinateSetI(x: bottomXL, y: bottomY);
            final CoordinateSetI br = CoordinateSetI(x: bottomXR, y: bottomY);
            final List<CoordinateSetI> lineToLeft = Helper.bresenham(start: tip, end: bl);
            final List<CoordinateSetI> lineToRight = Helper.bresenham(start: tip, end: br);
            final CoordinateSetI current = CoordinateSetI(x: x, y: y);
            if (lineToLeft.contains(current) || lineToRight.contains(current))
            {
              shouldDraw = true;
            }
          }
        }
        else if (gridType == GridType.brick)
        {
          if (y % (intervalY) == 0)
          {
            shouldDraw = true;
          }
          else
          {
            int tipX = (x ~/ intervalX) * intervalX;
            if ((y ~/ intervalY) % 2 == 0)
            {
              tipX += (intervalX ~/2);
            }
            if (x == tipX)
            {
              shouldDraw = true;
            }
          }
        }

        if (shouldDraw)
        {
          if (x >= 0 && x < appState.canvasSize.x && y >= 0 && y < appState.canvasSize.y)
          {
            int pixelIndex = (y * appState.canvasSize.x + x) * 4;
            byteDataImg.setUint8(pixelIndex + 0, colorBrightnessPremultiplied);
            byteDataImg.setUint8(pixelIndex + 1, colorBrightnessPremultiplied);
            byteDataImg.setUint8(pixelIndex + 2, colorBrightnessPremultiplied);
            byteDataImg.setUint8(pixelIndex + 3, colorOpacity);
          }
        }
      }
    }

    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataImg.buffer.asUint8List(),
      appState.canvasSize.x,
      appState.canvasSize.y,
      ui.PixelFormat.rgba8888, (ui.Image convertedImage)
      {
        completerImg.complete(convertedImage);
      }
    );
    return completerImg.future;
  }
}