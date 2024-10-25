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
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class DrawingLayerState extends LayerState
{
  final ValueNotifier<LayerLockState> lockState = ValueNotifier(LayerLockState.unlocked);
  final CoordinateSetI size;

  final CoordinateColorMap _data;
  ui.Image? raster;
  bool isRasterizing = false;
  bool doManualRaster = false;
  final Map<CoordinateSetI, ColorReference?> rasterQueue = {};

  DrawingLayerState._({required CoordinateColorMap data, required this.size, LayerLockState lState = LayerLockState.unlocked, LayerVisibilityState vState = LayerVisibilityState.visible}) : _data = data
  {
    isRasterizing = true;
    _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thb: images.$2, startedFromManual: false));
    lockState.value = lState;
    visibilityState.value = vState;
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {updateTimerCallback(timer: t);});

  }

  factory DrawingLayerState.from({required DrawingLayerState other})
  {
    final CoordinateColorMap data = HashMap();
    for (final CoordinateColor ref in other._data.entries)
    {
      data[ref.key] = ref.value;
    }
    return DrawingLayerState._(size: other.size, data: data, lState: other.lockState.value, vState: other.visibilityState.value);
  }

  factory DrawingLayerState.deepClone({required DrawingLayerState other, required final KPalRampData originalRampData, required final KPalRampData rampData})
  {
    final CoordinateColorMap data = HashMap();
    for (final CoordinateColor ref in other._data.entries)
    {
      ColorReference colRef = ref.value;

      if (colRef.ramp == originalRampData)
      {
        colRef = rampData.references[colRef.colorIndex];
      }
      data[ref.key] = colRef;
    }
    return DrawingLayerState._(size: other.size, data: data, lState: other.lockState.value, vState: other.visibilityState.value);
  }



  factory DrawingLayerState({required CoordinateSetI size, final CoordinateColorMapNullable? content})
  {
    CoordinateColorMap data2 = HashMap();

    if (content != null)
    {
      for (final CoordinateColorNullable entry in content.entries)
      {
        if (entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < size.x && entry.key.y < size.y && entry.value != null)
        {
          data2[entry.key] = entry.value!;
        }
      }
    }
    return DrawingLayerState._(data: data2, size: size);
  }

  void updateTimerCallback({required final Timer timer}) async
  {
    if ((rasterQueue.isNotEmpty || doManualRaster) && !isRasterizing)
    {
      isRasterizing = true;
      _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thb: images.$2, startedFromManual: doManualRaster));
    }
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    isRasterizing = true;
    final Set<CoordinateSetI> deleteData = {};
    for (final CoordinateColor entry in _data.entries)
    {
      if (entry.value.ramp == ramp)
      {
        deleteData.add(entry.key);
      }
    }

    for (final CoordinateSetI coord in deleteData)
    {
      _data.remove(coord);
    }

    isRasterizing = false;
  }

  void remapAllColors({required final HashMap<ColorReference, ColorReference> rampMap})
  {
    isRasterizing = true;
    for (final CoordinateColor entry in _data.entries)
    {
      _data[entry.key] = rampMap[entry.value]!;
    }
    isRasterizing = false;
  }

  void remapSingleRamp({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    isRasterizing = true;
    for (final CoordinateColor entry in _data.entries)
    {
      if (entry.value.ramp == newData)
      {
        _data[entry.key] = newData.references[map[entry.value.colorIndex]!];
      }
    }
    isRasterizing = false;
  }


  void _rasterizingDone({required final ui.Image image, required final ui.Image thb, required final bool startedFromManual})
  {
    isRasterizing = false;
    raster = image;
    thumbnail.value = thb;
    if (startedFromManual)
    {
      doManualRaster = false;
    }
    GetIt.I.get<AppState>().repaintNotifier.repaint();
  }

  Future<(ui.Image, ui.Image)> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    bool differentThumb = false;
    if (appState.currentLayer == this && appState.selectionState.selection.hasValues())
    {
      differentThumb = true;
    }

    for (final CoordinateColorNullable entry in rasterQueue.entries)
    {
      if (entry.value == null)
      {
        _data.remove(entry.key);
      }
      else
      {
        _data[entry.key] = entry.value!;
      }
    }
    rasterQueue.clear();

    final ByteData byteDataImg = ByteData(size.x * size.y * 4);
    ByteData? byteDataThumb;
    if (differentThumb)
    {
      byteDataThumb = ByteData(size.x * size.y * 4);
    }
    for (final CoordinateColorNullable entry in _data.entries)
    {
      if (entry.value != null)
      {
        final Color dColor = entry.value!.getIdColor().color;
        final int index = (entry.key.y * size.x + entry.key.x) * 4;
        if (index < byteDataImg.lengthInBytes)
        {
          byteDataImg.setUint32(index, Helper.argbToRgba(argb: dColor.value));
          if (byteDataThumb != null)
          {
            byteDataThumb.setUint32(index, Helper.argbToRgba(argb: dColor.value));
          }
        }
      }
    }
    if (differentThumb)
    {
      final Iterable<CoordinateSetI> selectionCoords = appState.selectionState.selection.getCoordinates();
      for (final CoordinateSetI coord in selectionCoords)
      {
        final ColorReference? colRef = appState.selectionState.selection.getColorReference(coord: coord);
        if (colRef != null)
        {
          final Color dColor = colRef.getIdColor().color;
          final int index = (coord.y * size.x + coord.x) * 4;
          if (index > 0 && index < byteDataThumb!.lengthInBytes)
          {
            byteDataThumb.setUint32(index, Helper.argbToRgba(argb: dColor.value));
          }
        }
      }
    }


    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataImg.buffer.asUint8List(),
        size.x,
        size.y,
        ui.PixelFormat.rgba8888, (ui.Image convertedImage)
    {
      completerImg.complete(convertedImage);
    }
    );

    final ui.Image img = await completerImg.future;

    if (differentThumb)
    {
      final Completer<ui.Image> completerThumb = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          byteDataThumb!.buffer.asUint8List(),
          size.x,
          size.y,
          ui.PixelFormat.rgba8888, (ui.Image convertedImage)
      {
        completerThumb.complete(convertedImage);
      }
      );
      final ui.Image thumb = await completerThumb.future;
      return (img, thumb);
    }
    else
    {
      return (img, img);
    }
  }


  ColorReference? getDataEntry({required final CoordinateSetI coord})
  {
    if (_data.containsKey(coord))
    {
      return _data[coord];
    }
    else if (rasterQueue.isNotEmpty)
    {
      return rasterQueue[coord];
    }
    return null;
  }

  CoordinateColorMap getData()
  {
    return _data;
  }

  void setDataAll({required final CoordinateColorMapNullable list})
  {
    rasterQueue.addAll(list);
  }

  Future <void> removeDataAll({required final Set<CoordinateSetI> removeCoordList}) async
  {
    for (final CoordinateSetI coord in removeCoordList)
    {
      rasterQueue[coord] = null;
    }
  }


  DrawingLayerState getTransformedLayer({required final CanvasTransformation transformation})
  {
    final CoordinateColorMap rotatedContent = HashMap();
    final CoordinateSetI newSize = CoordinateSetI.from(other: size);
    if (transformation == CanvasTransformation.rotate)
    {
      newSize.x = size.y;
      newSize.y = size.x;
    }
    for (final CoordinateColor entry in _data.entries)
    {
      final CoordinateSetI rotCoord = CoordinateSetI.from(other: entry.key);
      if (transformation == CanvasTransformation.rotate)
      {
        rotCoord.x = ((size.y - 1) - entry.key.y).toInt();
        rotCoord.y = entry.key.x;
      }
      else if (transformation == CanvasTransformation.flipH)
      {
        rotCoord.x = ((size.x - 1) - entry.key.x).toInt();
      }
      else if (transformation == CanvasTransformation.flipV)
      {
        rotCoord.y = ((size.y - 1) - entry.key.y).toInt();
      }

      rotatedContent[rotCoord] = entry.value;
    }
    if (rasterQueue.isNotEmpty)
    {
      for (final CoordinateColorNullable entry in rasterQueue.entries)
      {
        final CoordinateSetI rotCoord = CoordinateSetI.from(other: entry.key);
        if (transformation == CanvasTransformation.rotate)
        {
          rotCoord.x = ((size.y - 1) - entry.key.y).toInt();
          rotCoord.y = entry.key.x;
        }
        else if (transformation == CanvasTransformation.flipH)
        {
          rotCoord.x = ((size.x - 1) - entry.key.x).toInt();
        }
        else if (transformation == CanvasTransformation.flipV)
        {
          rotCoord.y = ((size.y - 1) - entry.key.y).toInt();
        }
        if (entry.value != null)
        {
          rotatedContent[rotCoord] = entry.value!;
        }
        else if (rotatedContent.containsKey(rotCoord))
        {
          rotatedContent.remove(rotCoord);
        }
      }
    }
    return DrawingLayerState(size: newSize, content: rotatedContent);
  }

  DrawingLayerState getResizedLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    final CoordinateColorMap croppedContent = HashMap();
    for (final CoordinateColor entry in _data.entries)
    {
      final CoordinateSetI newCoord = CoordinateSetI(x: entry.key.x + offset.x, y: entry.key.y + offset.y);
      if (newCoord.x >= 0 && newCoord.x < newSize.x && newCoord.y >= 0 && newCoord.y < newSize.y)
      {
        croppedContent[newCoord] = entry.value;
      }
    }

    if (rasterQueue.isNotEmpty)
    {
      for (final CoordinateColorNullable entry in rasterQueue.entries)
      {
        final CoordinateSetI newCoord = CoordinateSetI(x: entry.key.x + offset.x, y: entry.key.y + offset.y);
        if (newCoord.x >= 0 && newCoord.x < newSize.x && newCoord.y >= 0 && newCoord.y < newSize.y)
        {
          if (entry.value != null)
          {
            croppedContent[newCoord] = entry.value!;
          }
          else if (croppedContent.containsKey(newCoord))
          {
            croppedContent.remove(newCoord);
          }
        }
      }
    }
    return DrawingLayerState(size: newSize, content: croppedContent);
  }
}