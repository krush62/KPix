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
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/rendering_helper.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/canvas_transformation.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/layer_settings/drawing_layer_settings_widget.dart';
import 'package:logger/logger.dart';

class DrawingLayerState extends RasterableLayerState
{

  //the pixels as color codes of _codec; see docs/dev/pixel_storage_plan.md
  PixelGrid _data;
  //grows by a ramp the first time a color of that ramp is stored, which keeps
  //every existing code valid; palette operations that drop or move colors go
  //through deleteRamp and the remap methods
  PaletteCodec _codec;
  CoordinateColorMap _settingsPixels;
  final Map<CoordinateSetI, ColorReference?> rasterQueue = <CoordinateSetI, ColorReference?>{};

  final DrawingLayerSettings settings;
  Map<Frame, HashMap<CoordinateSetI, int>> settingsShadingPixels = <Frame, HashMap<CoordinateSetI, int>>{};

  bool _isUpdateScheduled = false;

  final List<DirtyRegion> dirtyRegions = <DirtyRegion>[];
  bool _forceFullRender = false;

  @override IconData get icon => TablerIcons.brush;
  @override LayerMenuKind get menuKind => LayerMenuKind.drawing;
  @override bool get thumbnailIsContent => true;

  @override
  DrawingLayerState copy({final List<RasterableLayerState>? layerStack}) =>
      DrawingLayerState.from(other: this, layerStack: layerStack);

  @override
  HistoryDrawingLayer toHistoryLayer({
    required final List<HistoryRampData> ramps,
    final HistoryLayer? previousLayer,
  })
  {
    //a snapshot shares the tiles that did not change, so there is no need for
    //a delta against the previous one
    return HistoryDrawingLayer.fromDrawingLayerState(layerState: this, ramps: ramps);
  }

  factory DrawingLayerState({required final CoordinateSetI size, final CoordinateColorMapNullable? content, final DrawingLayerSettings? drawingLayerSettings, required final List<KPalRampData> ramps})
  {
    final PixelGrid data = PixelGrid(width: size.x, height: size.y);
    PaletteCodec codec = PaletteCodec(ramps: ramps);

    if (content != null)
    {
      for (final CoordinateColorNullable entry in content.entries)
      {
        final ColorReference? color = entry.value;
        //the grid drops pixels outside the canvas
        if (color != null)
        {
          codec = codec.withRamp(ramp: color.ramp);
          data.set(x: entry.key.x, y: entry.key.y, value: codec.encode(color: color));
        }
      }
    }
    final DrawingLayerSettings settings = drawingLayerSettings ?? DrawingLayerSettings.defaultValues(startingColor: ramps[0].references[0], constraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints);
    return DrawingLayerState._(data: data, codec: codec, settingsPixels: CoordinateColorMap(), settings: settings);
  }

  /// A layer holding [pixels], whose codes belong to [codec]. The grid is taken
  /// over, not copied.
  factory DrawingLayerState.fromPixels({required final PixelGrid pixels, required final PaletteCodec codec, required final DrawingLayerSettings drawingLayerSettings})
  {
    return DrawingLayerState._(data: pixels, codec: codec, settingsPixels: CoordinateColorMap(), settings: drawingLayerSettings);
  }

  DrawingLayerState._({required final PixelGrid data, required final PaletteCodec codec, required final CoordinateColorMap settingsPixels, final LayerLockState lState = LayerLockState.unlocked, final LayerVisibilityState vState = LayerVisibilityState.visible, super.layerStack, required this.settings}) :
        _data = data,
        _codec = codec,
        _settingsPixels = settingsPixels,
        super(layerSettings: settings)
  {
    requestRaster();
    isRasterizing = true;
    _createRaster().then((final DualRasterResult result)
    {
      _rasterizingDone(rasterResult: result);
      settleRaster();
    })
        .catchError((final dynamic e, final dynamic s) {
      //without this the flag stays set and anything waiting on this layer waits
      //for good
      GetIt.I.get<Logger>().e("Error during initial drawing layer rasterization", error: e);
      isRasterizing = false;
      doManualRaster = true;
      settleRaster();
    });
    lockState.value = lState;
    visibilityState.value = vState;
    startRasterPolling(scheduler: rasterScheduler);
    settings.addListener(_settingsChanged);
    _settingsChanged();
  }

  void _settingsChanged()
  {
    forceFullRender();
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);

    for (final Frame frame in frames)
    {
      frame.layerList.rebuildDependencies();
    }

    if (isRasterizing)
    {
      return;
    }

    for (final Frame frame in frames)
    {
      frame.layerList.invalidateDependents(layer: this);
    }
  }


  /// The pixels of [other] with its pending writes applied, sharing tiles with
  /// it until either side writes.
  static (PixelGrid, PaletteCodec) _resolvedData({required final DrawingLayerState other})
  {
    final PixelGrid data = other._data.copy();
    PaletteCodec codec = other._codec;
    for (final CoordinateColorNullable entry in other.rasterQueue.entries)
    {
      final ColorReference? color = entry.value;
      if (color != null)
      {
        codec = codec.withRamp(ramp: color.ramp);
      }
      data.set(x: entry.key.x, y: entry.key.y, value: codec.encode(color: color));
    }
    return (data, codec);
  }

  factory DrawingLayerState.from({required final DrawingLayerState other, final List<RasterableLayerState>? layerStack})
  {
    final (PixelGrid data, PaletteCodec codec) = _resolvedData(other: other);
    final DrawingLayerSettings newSettings = DrawingLayerSettings.fromOther(other: other.settings);
    return DrawingLayerState._(settingsPixels: CoordinateColorMap(), data: data, codec: codec, lState: other.lockState.value, vState: other.visibilityState.value, layerStack: layerStack, settings: newSettings);
  }

  factory DrawingLayerState.deepClone({required final DrawingLayerState other, required final KPalRampData originalRampData, required final KPalRampData rampData})
  {
    final (PixelGrid resolved, PaletteCodec resolvedCodec) = _resolvedData(other: other);
    final PixelGrid data = PixelGrid(width: resolved.width, height: resolved.height);
    PaletteCodec codec = resolvedCodec.withRamp(ramp: rampData);
    resolved.forEachNonZero(action: (final int x, final int y, final int value)
    {
      final ColorReference color = resolvedCodec.decode(code: value)!;
      final ColorReference cloned = (color.ramp == originalRampData) ? rampData.references[color.colorIndex] : color;
      codec = codec.withRamp(ramp: cloned.ramp);
      data.set(x: x, y: y, value: codec.encode(color: cloned));
    },);
    return DrawingLayerState._(data: data, codec: codec, settingsPixels: CoordinateColorMap(), lState: other.lockState.value, vState: other.visibilityState.value, settings: other.settings);
  }

  @override
  void pollRaster()
  {
    unawaited(_pollRaster());
  }

  Future<void> _pollRaster() async
  {
    if (_isUpdateScheduled) {
      return;
    }

    if ((rasterQueue.isNotEmpty || doManualRaster) && !isRasterizing)
    {
      _isUpdateScheduled = true;
      isRasterizing = true;
      //consume the pending request now; requests arriving during rasterization
      //set the flag again and are serviced on the next timer tick
      doManualRaster = false;


      final DocumentState documentState = GetIt.I.get<DocumentState>();

      final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
      for (final Frame frame in frames) {
        frame.layerList.lockLayerAndDependenciesForRendering(layer: this);
      }

      try {
        final DualRasterResult rasterResult = await _createRaster();

        if (_isUpdateScheduled) {
          _rasterizingDone(rasterResult: rasterResult);
        }
        else {
          //the request was dropped while this raster ran, usually by dispose, so
          //nothing is going to store these images
          discardRasterResult(rasterResult: rasterResult);
        }
      } catch (e, s) {
        GetIt.I.get<Logger>().e("Error during drawing layer rasterization", error: e, stackTrace: s);
        doManualRaster = true;
      } finally {
        _isUpdateScheduled = false;
        //this method owns the whole raster cycle, so the flag is released here
        //whichever way the cycle ended
        isRasterizing = false;
        settleRaster();

        for (final Frame frame in frames) {
          frame.layerList.unlockLayerAndDependenciesFromRendering(layer: this);
        }
      }
    }
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    if (isRasterizing) {
      doManualRaster = true;
      return;
    }

    isRasterizing = true;
    final PaletteCodec remaining = _codec.withoutRamp(ramp: ramp);
    if (!identical(remaining, _codec))
    {
      //the ramp's codes have no place in the remaining codec, so they are dropped
      _data.remap(lut: _codec.remapLut(target: remaining));
      _codec = remaining;
    }

    settings.deleteRamp(ramp: ramp);

    isRasterizing = false;
    doManualRaster = true;


    final DocumentState documentState = GetIt.I.get<DocumentState>();

    final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
    for (final Frame frame in frames) {
      frame.layerList.invalidateDependents(layer: this);
    }
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
    if (isRasterizing) {
      forceFullRender();
      return;
    }

    isRasterizing = true;
    PaletteCodec target = _codec;
    for (final ColorReference color in rampMap.values)
    {
      target = target.withRamp(ramp: color.ramp);
    }
    _data.remap(lut: _codec.remapLutByColor(target: target, colorMap: rampMap));
    _codec = target;
    isRasterizing = false;
    forceFullRender();


    final DocumentState documentState = GetIt.I.get<DocumentState>();

    final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
    for (final Frame frame in frames)
    {
      frame.layerList.invalidateDependents(layer: this);
    }
  }

  void remapLayerEffectColors({required final HashMap<ColorReference, ColorReference> rampMap})
  {
    settings.innerColorReference.value = rampMap.containsKey(settings.innerColorReference.value) ? rampMap[settings.innerColorReference.value]! : rampMap.values.first;
    settings.outerColorReference.value = rampMap.containsKey(settings.outerColorReference.value) ? rampMap[settings.outerColorReference.value]! : rampMap.values.first;
    settings.dropShadowColorReference.value = rampMap.containsKey(settings.dropShadowColorReference.value) ? rampMap[settings.dropShadowColorReference.value]! : rampMap.values.first;
  }

  void resetLayerEffectColors({required final ColorReference newColor})
  {
    settings.innerColorReference.value = newColor;
    settings.outerColorReference.value = newColor;
    settings.dropShadowColorReference.value = newColor;
  }

  void remapSingleRamp({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    if (isRasterizing) {
      forceFullRender();
      return;
    }

    isRasterizing = true;
    if (_codec.indexOfRamp(ramp: newData) != null)
    {
      _data.remap(lut: _codec.remapLut(target: _codec, colorIndexMaps: <KPalRampData, Map<int, int>>{newData: map}));
    }
    isRasterizing = false;
    forceFullRender();


    final DocumentState documentState = GetIt.I.get<DocumentState>();

    final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
    for (final Frame frame in frames)
    {
      frame.layerList.invalidateDependents(layer: this);
    }
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


  void _rasterizingDone({required final DualRasterResult rasterResult})
  {
    if (isDisposed)
    {
      discardRasterResult(rasterResult: rasterResult);
      return;
    }
    isRasterizing = false;
    final List<ui.Image?> outgoing = collectHeldImages();

    previousRaster = rasterImage.value;
    rasterImage.value = rasterResult.externalStackImages != null
        ? rasterResult.externalStackImages!.raster
        : (rasterResult.rasterImages.isNotEmpty ? rasterResult.rasterImages.values.first.raster : null);
    thumbnail.value = rasterResult.externalStackImages != null
        ? rasterResult.externalStackImages!.thumbnail
        : (rasterResult.rasterImages.isNotEmpty ? rasterResult.rasterImages.values.first.thumbnail : null);
    rasterImageMap.value = rasterResult.rasterImages;

    releaseSuperseded(outgoing: outgoing);

    if (layerStack == null)
    {
      GetIt.I.get<LayerManager>().newRasterData(layer: this);
    }
  }

  /// The code for [color] in [_codec], which takes in the ramp of a color it
  /// has not seen before.
  int _encode({required final ColorReference? color})
  {
    if (color == null)
    {
      return PaletteCodec.transparent;
    }
    _codec = _codec.withRamp(ramp: color.ramp);
    return _codec.encode(color: color);
  }

  /// [grid] as a coordinate map, for the code that still works on those.
  CoordinateColorMap _colorMapOf({required final PixelGridView grid})
  {
    final CoordinateColorMap colors = CoordinateColorMap();
    final PaletteCodec codec = _codec;
    grid.forEachNonZero(action: (final int x, final int y, final int value)
    {
      colors[CoordinateSetI(x: x, y: y)] = codec.decode(code: value)!;
    },);
    return colors;
  }

  /// Moves the pending writes of [rasterQueue] into the grid.
  void _applyQueue()
  {
    for (final CoordinateColorNullable entry in rasterQueue.entries)
    {
      _data.set(x: entry.key.x, y: entry.key.y, value: _encode(color: entry.value));
    }
    rasterQueue.clear();
  }

  bool get _hasEffects
  {
    return settings.outerStrokeStyle.value != OuterStrokeStyle.off ||
        settings.innerStrokeStyle.value != InnerStrokeStyle.off ||
        settings.dropShadowStyle.value != DropShadowStyle.off;
  }

  /// The layer's pixels with the floating selection on top, in a copy that
  /// shares tiles with [_data] until either side writes.
  PixelGrid _contentWithSelection({required final bool frameIsSelected})
  {
    final PixelGrid content = _data.copy();
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final bool hasSelection = frameIsSelected &&
        layerStack == null &&
        documentState.timeline.getCurrentLayer() == this &&
        documentState.selectionState.selection.hasValues();
    if (hasSelection)
    {
      for (final CoordinateColorNullable entry in documentState.selectionState.selection.selectedPixels.entries)
      {
        //the grid drops floating pixels that are off the canvas
        if (entry.value != null)
        {
          content.set(x: entry.key.x, y: entry.key.y, value: _encode(color: entry.value));
        }
      }
    }
    return content;
  }

  /// What the layer shows in a frame: content, floating selection and layer
  /// effects. Also works out the effect pixels the other layers ask for.
  RasterPixels _composeFrame({required final Frame? frame, required final bool frameIsSelected, required final List<LayerState> layers})
  {
    final PixelGrid composite = _contentWithSelection(frameIsSelected: frameIsSelected);
    if (_hasEffects)
    {
      //the layer effects still work on coordinate maps (phase 5 of docs/dev/pixel_storage_plan.md)
      final CoordinateColorMap content = _colorMapOf(grid: composite);
      //LAYER EFFECT PIXELS OUTSIDE THE CONTENT
      if (frame != null)
      {
        settingsShadingPixels[frame] = settings.getOuterShadingPixels(data: content);
      }
      //LAYER EFFECT PIXELS INSIDE THE CONTENT
      _settingsPixels = settings.getSettingsPixels(data: content, layerState: this, layerList: layers, frameIsSelected: frameIsSelected);
      for (final CoordinateColor entry in _settingsPixels.entries)
      {
        composite.set(x: entry.key.x, y: entry.key.y, value: _encode(color: entry.value));
      }
    }
    else
    {
      _settingsPixels = CoordinateColorMap();
    }
    return RasterPixels(grid: composite, codec: _codec);
  }


  Future<DualRasterResult> _createRaster() async
  {
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final CanvasState canvasState = GetIt.I.get<CanvasState>();
    final Map<Frame, RasterImagePair> rasterImages = <Frame, RasterImagePair>{};
    _applyQueue();

    settingsShadingPixels.clear();

    //consume the render flags now; flags set during rasterization describe
    //changes that are not part of this render and must survive it
    final bool fullRenderForced = _forceFullRender;
    final List<DirtyRegion> renderRegions = List<DirtyRegion>.from(dirtyRegions);
    _forceFullRender = false;
    dirtyRegions.clear();

    if (layerStack != null)
    {
      final ui.Image layerStackImage = await _createRasterFromLayers(canvasSize: canvasState.canvasSize, layers: layerStack!, frameIsSelected: false, fullRenderForced: fullRenderForced, renderRegions: renderRegions);
      return DualRasterResult(rasterImages: rasterImages, externalStackImages: RasterImagePair(thumbnail: layerStackImage, raster: layerStackImage));
    }
    else
    {
      final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
      pruneFramePixels(frames: frames);
      final Frame? selectedFrame = documentState.timeline.selectedFrame;
      if (selectedFrame != null && frames.length > 1 && frames.remove(selectedFrame))
      {
        frames.add(selectedFrame);
      }
      for (final Frame frame in frames)
      {
        final ui.Image rasterImage = await _createRasterFromLayers(canvasSize: canvasState.canvasSize, frame: frame, frameIsSelected: frame == documentState.timeline.selectedFrame, layers: frame.layerList.getAllLayers(), fullRenderForced: fullRenderForced, renderRegions: renderRegions);
        rasterImages[frame] = RasterImagePair(thumbnail: rasterImage, raster: rasterImage);
      }
      return DualRasterResult(rasterImages: rasterImages);
    }
  }

  Future<ui.Image> _createRasterFromLayers({required final CoordinateSetI canvasSize, final Frame? frame, required final bool frameIsSelected, required final List<LayerState> layers, required final bool fullRenderForced, required final List<DirtyRegion> renderRegions,}) async
  {
    final RenderStrategy strategy = determineStrategy(
      dirtyRegions: renderRegions,
      canvasSize: canvasSize,
    );
    final ui.Image img = (strategy == RenderStrategy.full || fullRenderForced || previousRaster == null) ?
      await _fullRender(canvasSize: canvasSize, frame: frame, frameIsSelected: frameIsSelected, layers: layers) :
      await _regionalRender(canvasSize: canvasSize, frame: frame, frameIsSelected: frameIsSelected, layers: layers, renderRegions: renderRegions);

    return img;
  }

  Future<ui.Image> _fullRender({required final CoordinateSetI canvasSize, final Frame? frame, required final bool frameIsSelected, required final List<LayerState> layers}) async
  {
    final ByteData byteDataImg = ByteData(canvasSize.x * canvasSize.y * 4);
    final RasterPixels framePixels = _composeFrame(frame: frame, frameIsSelected: frameIsSelected, layers: layers);
    setRasterPixels(pixels: framePixels, frame: frame);

    final Uint32List rgba = framePixels.codec.rgbaLut();
    framePixels.grid.forEachNonZero(action: (final int x, final int y, final int value)
    {
      //just to make sure
      if (x < canvasSize.x && y < canvasSize.y)
      {
        byteDataImg.setUint32((y * canvasSize.x + x) * 4, rgba[value]);
      }
    },);

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

  Future<ui.Image> _regionalRender({
    required final CoordinateSetI canvasSize,
    required final Frame? frame,
    required final bool frameIsSelected,
    required final List<LayerState> layers,
    required final List<DirtyRegion> renderRegions,
  }) async
  {
    final List<DirtyRegion> expandedRegions = _expandDirtyRegionsForEffects(regions: renderRegions);

    final List<DirtyRegion> mergedRegions = mergeOverlappingRegions(regions: expandedRegions);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();
    //regions must replace the base content 1:1 (including transparent/erased
    //pixels); srcOver would keep deleted pixels from the base image visible
    final Paint regionPaint = Paint()..blendMode = ui.BlendMode.src;

    ui.Image? baseImage;

    if (frame != null && rasterImageMap.value.containsKey(frame))
    {
      baseImage = rasterImageMap.value[frame]!.raster;
    }
    else if (rasterImage.value != null)
    {
      baseImage = rasterImage.value;
    }
    else
    {
      baseImage = previousRaster;
    }

    if (baseImage == null)
    {
      return await _fullRender(canvasSize: canvasSize, frame: frame, frameIsSelected: frameIsSelected, layers: layers);
    }

    canvas.drawImage(baseImage, Offset.zero, paint);

    final RasterPixels framePixels = _composeFrame(frame: frame, frameIsSelected: frameIsSelected, layers: layers);
    setRasterPixels(pixels: framePixels, frame: frame);
    final Uint32List rgba = framePixels.codec.rgbaLut();

    for (final DirtyRegion region in mergedRegions)
    {
      final DirtyRegion clampedRegion = _clampRegion(region: region, canvasSize: canvasSize);

      final ui.Image regionImage = await _renderRegion(
        region: clampedRegion,
        pixels: framePixels.grid,
        rgba: rgba,
      );

      canvas.drawImage(
        regionImage,
        Offset(clampedRegion.x.toDouble(), clampedRegion.y.toDouble()),
        regionPaint,
      );

      regionImage.dispose();
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image result = await picture.toImage(canvasSize.x, canvasSize.y);
    picture.dispose();

    return result;
  }

  Future<ui.Image> _renderRegion({required final DirtyRegion region, required final PixelGridView pixels, required final Uint32List rgba}) async
  {
    final ByteData byteData = ByteData(region.width * region.height * 4);

    for (int y = region.y; y < region.y + region.height; y++)
    {
      for (int x = region.x; x < region.x + region.width; x++)
      {
        final int value = pixels.get(x: x, y: y);
        if (value != PaletteCodec.transparent)
        {
          byteData.setUint32(((y - region.y) * region.width + (x - region.x)) * 4, rgba[value]);
        }
      }
    }

    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteData.buffer.asUint8List(),
      region.width,
      region.height,
      ui.PixelFormat.rgba8888,
          (final ui.Image image) {
        completer.complete(image);
      },
    );

    return await completer.future;
  }

  void rasterOutline({required final List<LayerState> layers})
  {
    final CanvasState canvasState = GetIt.I.get<CanvasState>();
    final CoordinateColorMap outerPixels = settings.getOuterStrokePixels(data: _colorMapOf(grid: _data), layerState: this, canvasSize: canvasState.canvasSize, layers: layers);
    setDataAll(list: outerPixels);
  }

  void rasterInline({required final List<LayerState> layers, required final bool frameIsSelected})
  {
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final CanvasState canvasState = GetIt.I.get<CanvasState>();
    final SelectionList? selectionList = selectedInCurrentFrameNotifier.value && frameIsSelected ? documentState.selectionState.selection : null;
    final CoordinateColorMap innerPixels = settings.getInnerStrokePixels(data: _colorMapOf(grid: _data), layerState: this, canvasSize: canvasState.canvasSize, layers: layers, selectionList: selectionList);
    setDataAll(list: innerPixels);
  }

  void rasterDropShadow({required final List<LayerState> layers})
  {
    final CanvasState canvasState = GetIt.I.get<CanvasState>();
    final CoordinateColorMap dropShadowPixels = settings.getDropShadowPixels(data: _colorMapOf(grid: _data), layerState: this, canvasSize: canvasState.canvasSize, layers: layers);
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
    else if (rasterQueue.containsKey(coord))
    {
      return rasterQueue[coord];
    }
    return _codec.decode(code: _data.get(x: coord.x, y: coord.y));
  }

  /// The pixels with the writes still waiting in [rasterQueue] applied, as codes
  /// whose ramp indices refer to [ramps] (see PaletteCodec). That is what the
  /// history and the file store. Pixels of ramps missing from [ramps] are left
  /// out.
  ///
  /// When the layer's codes already follow that order, the snapshot shares its
  /// tiles with the layer. When they do not, after a palette reorder for
  /// example, the layer first moves its own codes into the palette's order.
  /// The tiles are then copied once, not on every step.
  PixelGridSnapshot historySnapshot({required final List<HistoryRampData> ramps})
  {
    final PaletteCodec palette = GetIt.I.get<DocumentState>().palette.codec;
    if (_listsSameRamps(codec: palette, ramps: ramps))
    {
      _alignCodec(target: palette);
    }

    PixelGrid? pending;
    if (rasterQueue.isNotEmpty)
    {
      //the queue itself stays: painters watch it to see a stroke land
      pending = PixelGrid.fromSnapshot(snapshot: _data.snapshot());
      for (final CoordinateColorNullable entry in rasterQueue.entries)
      {
        pending.set(x: entry.key.x, y: entry.key.y, value: _encode(color: entry.value));
      }
    }

    final Map<String, int> rampIndices = <String, int>{for (int i = 0; i < ramps.length; i++) ramps[i].uuid: i};
    final Uint16List lut = Uint16List(_codec.codeCount);
    bool linesUp = true;
    for (int rampIndex = 0; rampIndex < _codec.ramps.length; rampIndex++)
    {
      final int? targetIndex = rampIndices[_codec.ramps[rampIndex].uuid];
      linesUp = linesUp && targetIndex == rampIndex;
      if (targetIndex != null)
      {
        for (int colorIndex = 0; colorIndex < PaletteCodec.colorsPerRamp; colorIndex++)
        {
          lut[PaletteCodec.codeOf(rampIndex: rampIndex, colorIndex: colorIndex)] = PaletteCodec.codeOf(rampIndex: targetIndex, colorIndex: colorIndex);
        }
      }
    }
    if (linesUp)
    {
      return pending?.snapshot() ?? _data.snapshot();
    }
    final PixelGrid translated = pending ?? PixelGrid.fromSnapshot(snapshot: _data.snapshot());
    translated.remap(lut: lut);
    return translated.snapshot();
  }

  static bool _listsSameRamps({required final PaletteCodec codec, required final List<HistoryRampData> ramps})
  {
    if (codec.ramps.length != ramps.length)
    {
      return false;
    }
    for (int i = 0; i < ramps.length; i++)
    {
      if (codec.ramps[i].uuid != ramps[i].uuid)
      {
        return false;
      }
    }
    return true;
  }

  /// Moves the codes into [target]'s order, so that a code means the same in
  /// this layer and in [target]. Ramps only this layer has pixels of follow
  /// behind [target]'s; ramps without pixels are dropped. Nothing visible
  /// changes.
  void _alignCodec({required final PaletteCodec target})
  {
    final List<KPalRampData> current = _codec.ramps;
    bool inOrder = true;
    for (int i = 0; inOrder && i < current.length && i < target.ramps.length; i++)
    {
      inOrder = identical(current[i], target.ramps[i]);
    }
    if (inOrder)
    {
      return;
    }

    final Set<int> usedRamps = <int>{};
    _data.forEachNonZero(action: (final int x, final int y, final int value) => usedRamps.add(PaletteCodec.rampIndexOf(code: value)));
    final List<KPalRampData> ordered = <KPalRampData>[...target.ramps];
    for (final int rampIndex in usedRamps.toList()..sort())
    {
      if (target.indexOfRamp(ramp: current[rampIndex]) == null)
      {
        ordered.add(current[rampIndex]);
      }
    }
    final PaletteCodec aligned = PaletteCodec(ramps: ordered);
    _data.remap(lut: _codec.remapLut(target: aligned));
    _codec = aligned;
  }

  /// Every color among the stored pixels, without the writes still waiting in
  /// [rasterQueue].
  Set<ColorReference> usedColors()
  {
    final Set<int> codes = <int>{};
    _data.forEachNonZero(action: (final int x, final int y, final int value) => codes.add(value));
    return <ColorReference>{for (final int code in codes) _codec.decode(code: code)!};
  }


  void setDataAll({required final CoordinateColorMapNullable list})
  {
    if (isRasterizing)
    {
      rasterQueue.addAll(list);
      requestRaster();
      doManualRaster = true;
    }
    else
    {
      rasterQueue.addAll(list);
      requestRaster();
      _trackDirtyRegions(changedCoords: list.keys);
      doManualRaster = true;
    }
  }

  void removeDataAll({required final Set<CoordinateSetI> removeCoordList})
  {
    for (final CoordinateSetI coord in removeCoordList)
    {
      rasterQueue[coord] = null;
    }
    requestRaster();
    doManualRaster = true;
  }


  /// Turns or mirrors the layer, pending writes included. For a rotation, width
  /// and height swap.
  void transformLayer({required final CanvasTransformation transformation, required final CoordinateSetI oldSize})
  {
    assert(oldSize.x == _data.width && oldSize.y == _data.height, "the layer is ${_data.width}x${_data.height}, not ${oldSize.x}x${oldSize.y}");
    _applyQueue();
    switch (transformation)
    {
      case CanvasTransformation.rotate:
        _data = _data.rotatedClockwise();
      case CanvasTransformation.flipH:
        _data = _data.flippedHorizontally();
      case CanvasTransformation.flipV:
        _data = _data.flippedVertically();
    }
    forceFullRender();
  }

  @override
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    _applyQueue();
    _data = _data.resized(newWidth: newSize.x, newHeight: newSize.y, offsetX: offset.x, offsetY: offset.y);
    forceFullRender();
  }

  int getPixelCountForRamp({required final KPalRampData ramp})
  {
    final int? rampIndex = _codec.indexOfRamp(ramp: ramp);
    if (rampIndex == null)
    {
      return 0;
    }
    int count = 0;
    _data.forEachNonZero(action: (final int x, final int y, final int value)
    {
      if (PaletteCodec.rampIndexOf(code: value) == rampIndex)
      {
        count++;
      }
    },);
    return count;
  }

  void _trackDirtyRegions({required final Iterable<CoordinateSetI> changedCoords})
  {
    if (changedCoords.isEmpty) return;

    int minX = changedCoords.first.x;
    int minY = changedCoords.first.y;
    int maxX = changedCoords.first.x;
    int maxY = changedCoords.first.y;

    for (final CoordinateSetI coord in changedCoords)
    {
      minX = min(minX, coord.x);
      minY = min(minY, coord.y);
      maxX = max(maxX, coord.x);
      maxY = max(maxY, coord.y);
    }

    dirtyRegions.add(
      DirtyRegion(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1,
      ),
    );
  }

  List<DirtyRegion> _expandDirtyRegionsForEffects({required final List<DirtyRegion> regions})
  {
    final List<DirtyRegion> expanded = <DirtyRegion>[];

    for (final DirtyRegion region in regions) {
      int maxExpansion = 0;


      if (settings.outerStrokeStyle.value != OuterStrokeStyle.off)
      {
        int strokeWidth = 1;
        if (settings.outerStrokeStyle.value == OuterStrokeStyle.glow)
        {
          strokeWidth = settings.outerGlowDepth.value;
        }
        maxExpansion = max(maxExpansion, strokeWidth + 1);
      }
      if (settings.dropShadowStyle.value != DropShadowStyle.off)
      {
        final int shadowExpansion = max(
          settings.dropShadowOffset.value.x.abs(),
          settings.dropShadowOffset.value.y.abs(),
        );
        maxExpansion = max(maxExpansion, shadowExpansion + 1);
      }
      expanded.add(region.expand(padding: maxExpansion));
    }

    return expanded;
  }

  DirtyRegion _clampRegion({required final DirtyRegion region, required final CoordinateSetI canvasSize})
  {
    final int x = max(0, region.x);
    final int y = max(0, region.y);
    final int right = min(canvasSize.x, region.x + region.width);
    final int bottom = min(canvasSize.y, region.y + region.height);

    return DirtyRegion(
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
  }

  @override
  void forceFullRender()
  {
    _forceFullRender = true;
    dirtyRegions.clear();
    doManualRaster = true;
  }

  @override
  bool get hasPendingRaster
  {
    return doManualRaster || rasterQueue.isNotEmpty;
  }

  @override
  LayerSettingsWidget getSettingsWidget()
  {
    return DrawingLayerSettingsWidget(layer: this);
  }

  @override
  void dispose()
  {
    markDisposed();
    settleRaster();
    stopRasterPolling();
    settings.removeListener(_settingsChanged);
    _isUpdateScheduled = false;

    rasterQueue.clear();
    _data.clear();
    _settingsPixels.clear();

    final List<ui.Image?> images = <ui.Image?>[rasterImage.value, thumbnail.value, previousRaster];
    for (final RasterImagePair pair in rasterImageMap.value.values)
    {
      images.add(pair.raster);
      images.add(pair.thumbnail);
    }

    //clear the notifiers first: the layer widget shows the thumbnail, so a rebuild
    //must not find a handle that is about to be released
    rasterImage.value = null;
    thumbnail.value = null;
    previousRaster = null;
    rasterImageMap.value = <Frame, RasterImagePair>{};

    disposeImages(images: images);
  }


}
