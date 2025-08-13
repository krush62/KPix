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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class DrawingLayerState extends RasterableLayerState
{

  final CoordinateColorMap _data;
  CoordinateColorMap _settingsPixels;
  final Map<CoordinateSetI, ColorReference?> rasterQueue = <CoordinateSetI, ColorReference?>{};

  final DrawingLayerSettings settings;
  Map<Frame, HashMap<CoordinateSetI, int>> settingsShadingPixels = <Frame, HashMap<CoordinateSetI, int>>{};

  factory DrawingLayerState({required final CoordinateSetI size, final CoordinateColorMapNullable? content, final DrawingLayerSettings? drawingLayerSettings, required final List<KPalRampData> ramps})
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
    final DrawingLayerSettings settings = drawingLayerSettings ?? DrawingLayerSettings.defaultValues(startingColor: ramps[0].references[0], constraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints);
    return DrawingLayerState._(data: data, settingsPixels: settingsPixels, settings: settings);
  }

  DrawingLayerState._({required final CoordinateColorMap data, required final CoordinateColorMap settingsPixels, final LayerLockState lState = LayerLockState.unlocked, final LayerVisibilityState vState = LayerVisibilityState.visible, super.layerStack, required this.settings}) :
        _data = data,
        _settingsPixels = settingsPixels,
        super(layerSettings: settings)
  {
    isRasterizing = true;
    _createRaster().then((final DualRasterResult result) => _rasterizingDone(rasterResult: result, startedFromManual: false));
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
    //TODO can this stay commented out?
    /*rasterPixels = _getContentWithSelection();
    settingsShadingPixels = settings.getOuterShadingPixels(data: rasterPixels);
    _settingsPixels = settings.getSettingsPixels(data: rasterPixels, layerState: this);*/
    doManualRaster = true;
  }


  factory DrawingLayerState.from({required final DrawingLayerState other, final List<RasterableLayerState>? layerStack})
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
      _createRaster().then((final DualRasterResult rasterResult) => _rasterizingDone(rasterResult: rasterResult, startedFromManual: doManualRaster));
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

  void deleteRampFromLayerEffects({required final KPalRampData ramp, required final ColorReference backupColor})
  {
    if (settings.innerColorReference.value.ramp == ramp)
    {
      settings.innerColorReference.value = backupColor;
    }
    if (settings.outerColorReference.value.ramp == ramp)
    {
      settings.outerColorReference.value = backupColor;
    }
    if (settings.dropShadowColorReference.value.ramp == ramp)
    {
      settings.dropShadowColorReference.value = backupColor;
    }
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

  void remapLayerEffectColors({required final HashMap<ColorReference, ColorReference> rampMap})
  {
    settings.innerColorReference.value = rampMap.containsKey(settings.innerColorReference.value) ? rampMap[settings.innerColorReference.value]! : rampMap.values.first;
    settings.outerColorReference.value = rampMap.containsKey(settings.outerColorReference.value) ? rampMap[settings.outerColorReference.value]! : rampMap.values.first;
    settings.dropShadowColorReference.value = rampMap.containsKey(settings.dropShadowColorReference.value) ? rampMap[settings.dropShadowColorReference.value]! : rampMap.values.first;
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

  void remapSingleRampLayerEffects({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    if (settings.innerColorReference.value.ramp == newData)
    {
      settings.innerColorReference.value = newData.references[map[settings.innerColorReference.value.colorIndex]!];
    }
    if (settings.outerColorReference.value.ramp == newData)
    {
      settings.outerColorReference.value = newData.references[map[settings.outerColorReference.value.colorIndex]!];
    }
    if (settings.dropShadowColorReference.value.ramp == newData)
    {
      settings.dropShadowColorReference.value = newData.references[map[settings.dropShadowColorReference.value.colorIndex]!];
    }
  }


  void _rasterizingDone({required final DualRasterResult rasterResult, required final bool startedFromManual})
  {
    isRasterizing = false;
    previousRaster = rasterImage.value;
    rasterImage.value = rasterResult.externalStackImages != null ? rasterResult.externalStackImages!.raster : (rasterResult.rasterImages.isNotEmpty ? rasterResult.rasterImages.values.first.raster : null);
    thumbnail.value = rasterResult.externalStackImages != null ? rasterResult.externalStackImages!.thumbnail : (rasterResult.rasterImages.isNotEmpty ? rasterResult.rasterImages.values.first.thumbnail : null);
    rasterImageMap.value = rasterResult.rasterImages;
    if (startedFromManual)
    {
      doManualRaster = false;
    }

    if (layerStack == null)
    {
      GetIt.I.get<AppState>().newRasterData(layer: this);
    }


  }

  CoordinateColorMap _getContentWithSelection()
  {
    final CoordinateColorMap allColorPixels = CoordinateColorMap();
    final AppState appState = GetIt.I.get<AppState>();
    bool hasSelection = appState.timeline.getCurrentLayer() == this && appState.selectionState.selection.hasValues();
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


  Future<DualRasterResult> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final Map<Frame, RasterImagePair> rasterImages = <Frame, RasterImagePair>{};
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

    settingsShadingPixels.clear();

    if (layerStack != null)
    {
      final ui.Image layerStackImage = await _createRasterFromLayers(canvasSize: appState.canvasSize, layers: layerStack!, frameIsSelected: false);
      return DualRasterResult(rasterImages: rasterImages, externalStackImages: RasterImagePair(thumbnail: layerStackImage, raster: layerStackImage));
    }
    else
    {
      final List<Frame> frames = appState.timeline.findFramesForLayer(layer: this);
      for (final Frame frame in frames)
      {
        final ui.Image rasterImage = await _createRasterFromLayers(canvasSize: appState.canvasSize, frame: frame, frameIsSelected: frame == appState.timeline.selectedFrame, layers: frame.layerList.getAllLayers());
        rasterImages[frame] = RasterImagePair(thumbnail: rasterImage, raster: rasterImage);
      }
      return DualRasterResult(rasterImages: rasterImages);
    }
  }

  Future<ui.Image> _createRasterFromLayers({required final CoordinateSetI canvasSize, final Frame? frame, required final bool frameIsSelected, required final List<LayerState> layers}) async
  {
    final ByteData byteDataImg = ByteData(canvasSize.x * canvasSize.y * 4);
    //NORMAL OPAQUE PIXELS
    rasterPixels = _getContentWithSelection();
    //LAYER EFFECT PIXELS OUTSIDE THE CONTENT
    if (frame != null)
    {
      settingsShadingPixels[frame] = settings.getOuterShadingPixels(data: rasterPixels);
    }
    //LAYER EFFECT PIXELS INSIDE THE CONTENT
    _settingsPixels = settings.getSettingsPixels(data: rasterPixels, layerState: this, layerList: layers, frameIsSelected: frameIsSelected);
    rasterPixels.addAll(_settingsPixels);

    for (final CoordinateColor entry in rasterPixels.entries)
    {
      //just to make sure
      if (entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < canvasSize.x && entry.key.y < canvasSize.y)
      {
        final Color originalColor = entry.value.getIdColor().color;
        final int index = (entry.key.y * canvasSize.x + entry.key.x) * 4;
        if (index >= 0 && index < byteDataImg.lengthInBytes)
        {
          byteDataImg.setUint32(index, argbToRgba(argb: originalColor.toARGB32()));
        }
      }
    }

    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        byteDataImg.buffer.asUint8List(),
        canvasSize.x,
        canvasSize.y,
        ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
    {
      completerImg.complete(convertedImage);
    }
    );

    return await completerImg.future;
  }

  void rasterOutline({required final List<LayerState> layers})
  {
    final AppState appState = GetIt.I.get<AppState>();
    final CoordinateColorMap outerPixels = settings.getOuterStrokePixels(data: _data, layerState: this, canvasSize: appState.canvasSize, layers: layers);
    setDataAll(list: outerPixels);
  }

  void rasterInline({required final List<LayerState> layers, required final bool frameIsSelected})
  {
    final AppState appState = GetIt.I.get<AppState>();
    final SelectionList? selectionList = selectionNotifier.value && frameIsSelected ? appState.selectionState.selection : null;
    final CoordinateColorMap innerPixels = settings.getInnerStrokePixels(data: _data, layerState: this, canvasSize: appState.canvasSize, layers: layers, selectionList: selectionList);
    setDataAll(list: innerPixels);
  }

  void rasterDropShadow({required final List<LayerState> layers})
  {
    final AppState appState = GetIt.I.get<AppState>();
    final CoordinateColorMap dropShadowPixels = settings.getDropShadowPixels(data: _data, layerState: this, canvasSize: appState.canvasSize, layers: layers);
    setDataAll(list: dropShadowPixels);
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

  @override
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

  int getPixelCountForRamp({required final KPalRampData ramp})
  {
    int count = 0;
    for (final CoordinateColor entry in _data.entries)
    {
      if (entry.value.ramp == ramp)
      {
        count++;
      }
    }
    return count;
  }

  @override
  LayerSettingsWidget getSettingsWidget() {
    return DrawingLayerSettingsWidget(layer: this);
  }
}
