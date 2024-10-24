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

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
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
      intervalYNotifier = ValueNotifier(intervalY);

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

  Future<ui.Image> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final ByteData byteDataImg = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    final int colorBrightness = ((brightness.toDouble() / 100.0) * 255.0).round();
    final int colorOpacity = ((opacity.toDouble() / 100.0) * 255.0).round();
    final int colorValue = Helper.argbToRgba(argb: ui.Color.fromARGB(colorOpacity, colorBrightness, colorBrightness, colorBrightness).value);

    if (gridType == GridType.rectangular)
    {
      for (int y = 0; y < appState.canvasSize.y; y+=intervalY)
      {
        for (int x = 0; x < appState.canvasSize.x; x++)
        {
          final int index = (y * appState.canvasSize.x + x) * 4;
          if (index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, colorValue);
          }
        }
      }

      for (int x = 0; x < appState.canvasSize.x; x+=intervalX)
      {
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          final int index = (y * appState.canvasSize.x + x) * 4;
          if (index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, colorValue);
          }
        }
      }
    }
    else if (gridType == GridType.diagonal)
    {
      //top-left to bottom-right
      for (int y = 0; y < appState.canvasSize.y; y+=intervalY)
      {
        int x = 0;
        int y2 = y;
        while (y2 < appState.canvasSize.y && x < appState.canvasSize.x)
        {
          final int index = (y * appState.canvasSize.x + x) * 4;
          if (index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, colorValue);
          }
          x++;
          y2++;
        }
      }
      for (int x = intervalY; x < appState.canvasSize.x; x+=intervalY)
      {
        int y = 0;
        int x2 = x;
        while (x2 < appState.canvasSize.x && y < appState.canvasSize.y)
        {
          final int index = (y * appState.canvasSize.x + x) * 4;
          if (index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, colorValue);
          }
          x2++;
          y++;
        }
      }
      //top-right to bottom-left
      //TODO

    }
    else if (gridType == GridType.isometric)
    {
      //TODO
    }
  }
}