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
import 'package:kpix/layer_states/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class DrawingLayerState extends LayerState
{
  final ValueNotifier<LayerLockState> lockState = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
  final CoordinateSetI size;

  final CoordinateColorMap _data;
  CoordinateColorMap _settingsPixels;
  bool isRasterizing = false;
  bool doManualRaster = false;
  final Map<CoordinateSetI, ColorReference?> rasterQueue = <CoordinateSetI, ColorReference?>{};
  ui.Image? previousRaster;
  final ValueNotifier<ui.Image?> rasterImage = ValueNotifier<ui.Image?>(null);
  List<LayerState>? layerStack;
  final DrawingLayerSettings settings;

  factory DrawingLayerState({required final CoordinateSetI size, final CoordinateColorMapNullable? content, final DrawingLayerSettings? drawingLayerSettings})
  {
    final CoordinateColorMap data = HashMap<CoordinateSetI, ColorReference>();
    final CoordinateColorMap settingsPixels = HashMap<CoordinateSetI, ColorReference>();

    if (content != null)
    {
      for (final CoordinateColorNullable entry in content.entries)
      {
        if (entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < size.x && entry.key.y < size.y && entry.value != null)
        {
          data[entry.key] = entry.value!;
        }
      }
    }
    final DrawingLayerSettings settings = drawingLayerSettings ?? DrawingLayerSettings.defaultValues(startingColor: GetIt.I.get<AppState>().colorRamps[0].references[0], constraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints);
    return DrawingLayerState._(data: data, settingsPixels: settingsPixels, size: size, settings: settings);
  }

  DrawingLayerState._({required final CoordinateColorMap data, required final CoordinateColorMap settingsPixels, required this.size, final LayerLockState lState = LayerLockState.unlocked, final LayerVisibilityState vState = LayerVisibilityState.visible, this.layerStack, required this.settings}) :
        _data = data,
        _settingsPixels = settingsPixels
  {
    isRasterizing = true;
    _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thumbnailImage: images.$2, startedFromManual: false));
    lockState.value = lState;
    visibilityState.value = vState;
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {updateTimerCallback(timer: t);});
    settings.addListener(() {
      doManualRaster = true;
    });
  }

  factory DrawingLayerState.from({required final DrawingLayerState other, final List<LayerState>? layerStack})
  {
    final CoordinateColorMap data = HashMap<CoordinateSetI, ColorReference>();
    final CoordinateColorMap settingsPixels = HashMap<CoordinateSetI, ColorReference>();
    for (final CoordinateColor ref in other._data.entries)
    {
      data[ref.key] = ref.value;
    }
    final DrawingLayerSettings newSettings = DrawingLayerSettings.fromOther(other: other.settings);
    return DrawingLayerState._(size: other.size, settingsPixels: settingsPixels, data: data, lState: other.lockState.value, vState: other.visibilityState.value, layerStack: layerStack, settings: newSettings);
  }

  factory DrawingLayerState.deepClone({required final DrawingLayerState other, required final KPalRampData originalRampData, required final KPalRampData rampData})
  {
    final CoordinateColorMap data = HashMap<CoordinateSetI, ColorReference>();
    final CoordinateColorMap settingsPixels = HashMap<CoordinateSetI, ColorReference>();
    for (final CoordinateColor ref in other._data.entries)
    {
      data[ref.key] = (ref.value.ramp == originalRampData) ? rampData.references[ref.value.colorIndex] : ref.value;
    }
    return DrawingLayerState._(size: other.size, data: data, settingsPixels: settingsPixels, lState: other.lockState.value, vState: other.visibilityState.value, settings: other.settings);
  }

  Future<void> updateTimerCallback({required final Timer timer}) async
  {
    if ((rasterQueue.isNotEmpty || doManualRaster) && !isRasterizing)
    {
      isRasterizing = true;
      _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thumbnailImage: images.$2, startedFromManual: doManualRaster));
    }
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    isRasterizing = true;
    final Set<CoordinateSetI> deleteData = <CoordinateSetI>{};
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

    settings.deleteRamp(ramp: ramp);

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


  void _rasterizingDone({required final ui.Image image, required final ui.Image thumbnailImage, required final bool startedFromManual})
  {
    isRasterizing = false;
    previousRaster = rasterImage.value;
    rasterImage.value = image;
    thumbnail.value = thumbnailImage;
    if (startedFromManual)
    {
      doManualRaster = false;
    }
    GetIt.I.get<AppState>().repaintNotifier.repaint();
  }

  Future<(ui.Image, ui.Image)> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    bool hasSelection = appState.currentLayer == this && appState.selectionState.selection.hasValues();
    if (layerStack != null)
    {
      hasSelection = false;
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
    final ByteData byteDataThb = ByteData(size.x * size.y * 4);
    _settingsPixels = settings.getSettingsPixels(data: _data, layerState: this);
    final CoordinateColorMap dataWithSettingsPixels = CoordinateColorMap();
    dataWithSettingsPixels.addAll(_data);
    dataWithSettingsPixels.addAll(_settingsPixels);

    for (final CoordinateColor entry in dataWithSettingsPixels.entries)
    {
      final ColorReference colRef = ColorReference(colorIndex: entry.value.colorIndex, ramp: entry.value.ramp);
      final Color originalColor = colRef.getIdColor().color;
      final Color shadedColor = _geCurrentColorShading(coord: entry.key, appState: appState, inputColor: colRef);
      final int index = (entry.key.y * size.x + entry.key.x) * 4;
      if (index >= 0 && index < byteDataImg.lengthInBytes)
      {
        byteDataImg.setUint32(index, argbToRgba(argb: shadedColor.value));
        byteDataThb.setUint32(index, argbToRgba(argb: originalColor.value));
      }
    }
    if (hasSelection)
    {
      final Iterable<CoordinateSetI> selectionCoords = appState.selectionState.selection.getCoordinates();
      for (final CoordinateSetI coord in selectionCoords)
      {
        final ColorReference? colRef = appState.selectionState.selection.getColorReference(coord: coord);
        if (colRef != null && coord.x >= 0 && coord.x < appState.canvasSize.x && coord.y >= 0 && coord.y < appState.canvasSize.y)
        {
          final Color originalColor = colRef.getIdColor().color;
          final Color shadedColor = _geCurrentColorShading(coord: coord, appState: appState, inputColor: colRef);
          final int index = (coord.y * size.x + coord.x) * 4;
          if (index >= 0 && index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, argbToRgba(argb: shadedColor.value));
            byteDataThb.setUint32(index, argbToRgba(argb: originalColor.value));
          }
        }
      }
    }

    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataImg.buffer.asUint8List(),
        size.x,
        size.y,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      completerImg.complete(convertedImage);
    }
    );

    final Completer<ui.Image> completerThb = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataThb.buffer.asUint8List(),
        size.x,
        size.y,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      completerThb.complete(convertedImage);
    }
    );

    return (await completerImg.future, await completerThb.future);
  }

  void rasterOutline()
  {
    final CoordinateColorMap outerPixels = settings.getOuterStrokePixels(data: _data, layerState: this, appState: GetIt.I.get<AppState>());
    setDataAll(list: outerPixels);
  }

  void rasterInline()
  {
    final CoordinateColorMap innerPixels = settings.getInnerStrokePixels(data: _data, layerState: this, appState: GetIt.I.get<AppState>());
    setDataAll(list: innerPixels);
  }

  void rasterDropShadow()
  {
    final CoordinateColorMap dropShadowPixels = settings.getDropShadowPixels(data: _data, layerState: this, appState: GetIt.I.get<AppState>());
    setDataAll(list: dropShadowPixels);
  }

  Color _geCurrentColorShading({required final CoordinateSetI coord, required final AppState appState, required final ColorReference inputColor})
  {
    Color retColor = inputColor.getIdColor().color;
    int colorShift = 0;
    int currentIndex = appState.getLayerPosition(state: this);
    if (layerStack != null)
    {
      currentIndex = -1;
      for (int i = 0; i < layerStack!.length; i++)
      {
        if (layerStack![i] == this)
        {
          currentIndex = i;
          break;
        }
      }
    }
    //final List<LayerState> layerList = layerStack ?? appState.layers;
    if (currentIndex != -1)
    {
      for (int i = currentIndex; i >= 0; i--)
      {
        final LayerState layer = layerStack != null ? layerStack![i] : appState.getLayerAt(index: i);
        if (layer.runtimeType == ShadingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
        {
          final ShadingLayerState shadingLayer = layer as ShadingLayerState;
          if (shadingLayer.hasCoord(coord: coord))
          {
            colorShift += shadingLayer.getValueAt(coord: coord)!;
          }
        }
      }
    }
    if (colorShift != 0)
    {
      final int finalIndex = (inputColor.colorIndex + colorShift).clamp(0, inputColor.ramp.shiftedColors.length - 1);

      retColor = inputColor.ramp.shiftedColors[finalIndex].value.color;
    }

    return retColor;
  }

  ColorReference? getSettingsPixel({required final CoordinateSetI coord})
  {
      return _settingsPixels[coord];
  }

  ColorReference? getDataEntry({required final CoordinateSetI coord, final bool withSettingsPixels = false})
  {
    if (withSettingsPixels && _settingsPixels.containsKey(coord))
    {
      return _settingsPixels[coord];
    }
    else if (_data.containsKey(coord))
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
    final CoordinateColorMap rotatedContent = HashMap<CoordinateSetI, ColorReference>();
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
        rotCoord.x = (size.y - 1) - entry.key.y;
        rotCoord.y = entry.key.x;
      }
      else if (transformation == CanvasTransformation.flipH)
      {
        rotCoord.x = (size.x - 1) - entry.key.x;
      }
      else if (transformation == CanvasTransformation.flipV)
      {
        rotCoord.y = (size.y - 1) - entry.key.y;
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
          rotCoord.x = (size.y - 1) - entry.key.y;
          rotCoord.y = entry.key.x;
        }
        else if (transformation == CanvasTransformation.flipH)
        {
          rotCoord.x = (size.x - 1) - entry.key.x;
        }
        else if (transformation == CanvasTransformation.flipV)
        {
          rotCoord.y = (size.y - 1) - entry.key.y;
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
    final CoordinateColorMap croppedContent = HashMap<CoordinateSetI, ColorReference>();
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
