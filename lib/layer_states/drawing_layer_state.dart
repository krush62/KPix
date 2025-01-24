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
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class DrawingLayerState extends LayerState
{
  final ValueNotifier<LayerLockState> lockState = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
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
    return DrawingLayerState._(data: data, settingsPixels: settingsPixels, settings: settings);
  }

  DrawingLayerState._({required final CoordinateColorMap data, required final CoordinateColorMap settingsPixels, final LayerLockState lState = LayerLockState.unlocked, final LayerVisibilityState vState = LayerVisibilityState.visible, this.layerStack, required this.settings}) :
        _data = data,
        _settingsPixels = settingsPixels
  {
    isRasterizing = true;
    _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thumbnailImage: images.$2, startedFromManual: false));
    lockState.value = lState;
    visibilityState.value = vState;
    final LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {updateTimerCallback(timer: t);});
    settings.addListener(()
    {
      _settingsChanged();
    });
    _settingsChanged();
  }

  void _settingsChanged()
  {
    final CoordinateColorMap allColorPixels = _getContentWithSelection();
    _settingsPixels = settings.getSettingsPixels(data: allColorPixels, layerState: this);
    GetIt.I.get<AppState>().rasterDrawingLayers();
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
    return DrawingLayerState._(settingsPixels: settingsPixels, data: data, lState: other.lockState.value, vState: other.visibilityState.value, layerStack: layerStack, settings: newSettings);
  }

  factory DrawingLayerState.deepClone({required final DrawingLayerState other, required final KPalRampData originalRampData, required final KPalRampData rampData})
  {
    final CoordinateColorMap data = HashMap<CoordinateSetI, ColorReference>();
    final CoordinateColorMap settingsPixels = HashMap<CoordinateSetI, ColorReference>();
    for (final CoordinateColor ref in other._data.entries)
    {
      data[ref.key] = (ref.value.ramp == originalRampData) ? rampData.references[ref.value.colorIndex] : ref.value;
    }
    return DrawingLayerState._(data: data, settingsPixels: settingsPixels, lState: other.lockState.value, vState: other.visibilityState.value, settings: other.settings);
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

  CoordinateColorMap _getContentWithSelection()
  {
    final CoordinateColorMap allColorPixels = CoordinateColorMap();
    final AppState appState = GetIt.I.get<AppState>();
    bool hasSelection = appState.currentLayer == this && appState.selectionState.selection.hasValues();
    if (layerStack != null)
    {
      hasSelection = false;
    }
    allColorPixels.addAll(_data);
    if (hasSelection)
    {
      final CoordinateColorMap nonNullMap = CoordinateColorMap.fromEntries(
        appState.selectionState.selection.selectedPixels.entries.where((final MapEntry<CoordinateSetI, ColorReference?> entry) => entry.value != null && entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < appState.canvasSize.x && entry.key.y < appState.canvasSize.y).map(
              (final MapEntry<CoordinateSetI, ColorReference?> entry) => MapEntry<CoordinateSetI, ColorReference>(entry.key, entry.value!),
        ),
      );
      allColorPixels.addAll(nonNullMap);
    }
    return allColorPixels;
  }


  Future<(ui.Image, ui.Image)> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
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

    final ByteData byteDataImg = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);
    final ByteData byteDataThb = ByteData(appState.canvasSize.x * appState.canvasSize.y * 4);

    final CoordinateColorMap allColorPixels = _getContentWithSelection();
    _settingsPixels = settings.getSettingsPixels(data: allColorPixels, layerState: this);
    allColorPixels.addAll(_settingsPixels);

    for (final CoordinateColor entry in allColorPixels.entries)
    {
      //just to make sure
      if (entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < appState.canvasSize.x && entry.key.y < appState.canvasSize.y)
      {
        final ColorReference colRef = ColorReference(colorIndex: entry.value.colorIndex, ramp: entry.value.ramp);
        final Color originalColor = colRef.getIdColor().color;
        final Color shadedColor = _geCurrentColorShading(coord: entry.key, appState: appState, inputColor: colRef);
        final int index = (entry.key.y * appState.canvasSize.x + entry.key.x) * 4;
        if (index >= 0 && index < byteDataImg.lengthInBytes)
        {
          byteDataImg.setUint32(index, argbToRgba(argb: shadedColor.value));
          byteDataThb.setUint32(index, argbToRgba(argb: originalColor.value));
        }
      }
    }

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

    final Completer<ui.Image> completerThb = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataThb.buffer.asUint8List(),
        appState.canvasSize.x,
        appState.canvasSize.y,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      completerThb.complete(convertedImage);
    }
    );

    return (await completerImg.future, await completerThb.future);
  }

  void rasterOutline()
  {
    final AppState appState = GetIt.I.get<AppState>();
    final List<LayerState> layers = <LayerState>[];
    for (int i = 0; i < appState.layerCount; i++)
    {
      layers.add(appState.getLayerAt(index: i));
    }
    final CoordinateColorMap outerPixels = settings.getOuterStrokePixels(data: _data, layerState: this, canvasSize: appState.canvasSize, layers: layers);
    setDataAll(list: outerPixels);
  }

  void rasterInline()
  {
    final AppState appState = GetIt.I.get<AppState>();
    final SelectionList? selectionList = appState.getSelectedLayer() == this ? appState.selectionState.selection : null;
    final List<LayerState> layers = <LayerState>[];
    for (int i = 0; i < appState.layerCount; i++)
    {
      layers.add(appState.getLayerAt(index: i));
    }
    final CoordinateColorMap innerPixels = settings.getInnerStrokePixels(data: _data, layerState: this, canvasSize: appState.canvasSize, layers: layers, selectionList: selectionList);
    setDataAll(list: innerPixels);
  }

  void rasterDropShadow()
  {
    final AppState appState = GetIt.I.get<AppState>();
    final List<LayerState> layers = <LayerState>[];
    for (int i = 0; i < appState.layerCount; i++)
    {
      layers.add(appState.getLayerAt(index: i));
    }
    final CoordinateColorMap dropShadowPixels = settings.getDropShadowPixels(data: _data, layerState: this, canvasSize: appState.canvasSize, layers: layers);
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


  void transformLayer({required final CanvasTransformation transformation, required final CoordinateSetI oldSize})
  {
    final CoordinateColorMapNullable rotatedContent = CoordinateColorMapNullable();
    final Set<CoordinateSetI> removeCoordList = <CoordinateSetI>{};
    final CoordinateSetI newSize = CoordinateSetI.from(other: oldSize);
    if (transformation == CanvasTransformation.rotate)
    {
      newSize.x = oldSize.y;
      newSize.y = oldSize.x;
    }
    for (final CoordinateColor entry in _data.entries)
    {
      final CoordinateSetI rotCoord = CoordinateSetI.from(other: entry.key);
      if (transformation == CanvasTransformation.rotate)
      {
        rotCoord.x = (oldSize.y - 1) - entry.key.y;
        rotCoord.y = entry.key.x;
      }
      else if (transformation == CanvasTransformation.flipH)
      {
        rotCoord.x = (oldSize.x - 1) - entry.key.x;
      }
      else if (transformation == CanvasTransformation.flipV)
      {
        rotCoord.y = (oldSize.y - 1) - entry.key.y;
      }

      removeCoordList.add(entry.key);
      rotatedContent[rotCoord] = entry.value;
    }
    if (rasterQueue.isNotEmpty)
    {
      for (final CoordinateColorNullable entry in rasterQueue.entries)
      {
        final CoordinateSetI rotCoord = CoordinateSetI.from(other: entry.key);
        if (transformation == CanvasTransformation.rotate)
        {
          rotCoord.x = (oldSize.y - 1) - entry.key.y;
          rotCoord.y = entry.key.x;
        }
        else if (transformation == CanvasTransformation.flipH)
        {
          rotCoord.x = (oldSize.x - 1) - entry.key.x;
        }
        else if (transformation == CanvasTransformation.flipV)
        {
          rotCoord.y = (oldSize.y - 1) - entry.key.y;
        }
        removeCoordList.add(entry.key);
        rotatedContent[rotCoord] = entry.value;
      }
    }
    removeDataAll(removeCoordList: removeCoordList);
    setDataAll(list: rotatedContent);
  }

  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
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
    _data.clear();
    rasterQueue.clear();
    _data.addAll(croppedContent);

  }

}
