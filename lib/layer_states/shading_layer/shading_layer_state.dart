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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/rendering_helper.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/canvas_transformation.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_shading_layer.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/widgets/layer_settings/shading_layer_settings_widget.dart';
import 'package:logger/logger.dart';

class ShadingLayerState extends RasterableLayerState
{
  final ShadingLayerSettings settings;
  @protected
  final HashMap<int, int> thumbnailBrightnessMap = HashMap<int, int>();
  //the shading steps as signed pixels (see SignedPixels), canvas sized
  @protected
  PixelGrid shadingValues;

  bool _isUpdateScheduled = false;
  final List<DirtyRegion> _dirtyRegions = <DirtyRegion>[];
  bool _forceFullRender = false;

  @override IconData get icon => TablerIcons.exposure;
  @override LayerMenuKind get menuKind => LayerMenuKind.raster;

  @override
  ShadingLayerState copy({final List<RasterableLayerState>? layerStack}) =>
      ShadingLayerState.from(other: this, layerStack: layerStack);

  @override
  HistoryShadingLayer toHistoryLayer({
    required final List<HistoryRampData> ramps,
    final HistoryLayer? previousLayer,
  })
  {
    //a snapshot shares the tiles that did not change, so there is no need for
    //a delta against the previous one
    return HistoryShadingLayer.fromShadingLayerState(layerState: this);
  }

  ShadingLayerState() : this._(settings: ShadingLayerSettings.defaultValue(constraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints));

  ShadingLayerState._({required this.settings}) :
        shadingValues = _canvasSizedGrid(),
        super(layerSettings: settings)
  {
    _init();
  }

  /// A layer holding [data], shading steps as signed pixels. The grid is taken
  /// over, not copied.
  ShadingLayerState.withData({required final PixelGrid data, required final LayerLockState lState, required final ShadingLayerSettings newSettings, super.layerStack}) :
        settings = newSettings,
        shadingValues = data,
        super(layerSettings: newSettings)
  {
    _init();
    lockState.value = lState;
  }

  factory ShadingLayerState.from({required final ShadingLayerState other, final List<RasterableLayerState>? layerStack})
  {
    final ShadingLayerSettings settings = ShadingLayerSettings.from(other: other.settings);
    return ShadingLayerState.withData(data: other.shadingValues.copy(), lState: other.lockState.value, newSettings: settings, layerStack: layerStack);
  }

  static PixelGrid _canvasSizedGrid()
  {
    final CoordinateSetI canvasSize = GetIt.I.get<CanvasState>().canvasSize;
    return PixelGrid(width: canvasSize.x, height: canvasSize.y);
  }

  @protected
  void update()
  {
    int counter = 0;
    final int brightnessStep = 255 ~/ (settings.shadingStepsMinus.value + settings.shadingStepsPlus.value + 1);
    for (int i = -settings.shadingStepsMinus.value; i <= settings.shadingStepsPlus.value; i++)
    {
      thumbnailBrightnessMap[i] = counter * brightnessStep;
      counter++;
    }
  }

  void _init()
  {
    update();
    startRasterPolling(scheduler: rasterScheduler);
    settings.addListener(_settingsChanged);
  }

  void _settingsChanged()
  {
    final int low = -settings.shadingStepsMinus.value;
    final int high = settings.shadingStepsPlus.value;
    final List<(int, int, int)> clamped = <(int, int, int)>[];
    shadingValues.forEachSigned(action: (final int x, final int y, final int value)
    {
      final int limited = value.clamp(low, high);
      if (limited != value)
      {
        clamped.add((x, y, limited));
      }
    },);
    for (final (int x, int y, int value) in clamped)
    {
      shadingValues.setSigned(x: x, y: y, value: value);
    }
    if (isRasterizing) {
      forceFullRender();
      return;
    }
    forceFullRender();


    final DocumentState documentState = GetIt.I.get<DocumentState>();

    final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);

    for (final Frame frame in frames) {
      frame.layerList.invalidateDependents(layer: this);
    }
  }

  /// Calls [action] for every pixel that carries a shading step.
  void forEachValue({required final void Function(int x, int y, int value) action})
  {
    shadingValues.forEachSigned(action: action);
  }

  /// The shading steps as they are now, for the history and the file.
  PixelGridSnapshot historySnapshot()
  {
    return shadingValues.snapshot();
  }

  bool hasCoord({required final CoordinateSetI coord})
  {
    return shadingValues.getSigned(x: coord.x, y: coord.y) != null;
  }

  int? getDisplayValueAt({required final CoordinateSetI coord, final int shift = 0})
  {
    final int? value = shadingValues.getSigned(x: coord.x, y: coord.y);
    if (value != null)
    {
      return value + shift;
    }
    //a shift on a pixel that carries no shading yet is what drawing there would
    //store, so it has to read as that value instead of as no shading at all
    //(DitherLayerState resolves the same case the same way)
    else if (shift != 0)
    {
      return shift;
    }
    else
    {
      return null;
    }
  }

  int? getRawValueAt({required final CoordinateSetI coord})
  {
    return getDisplayValueAt(coord: coord);
  }


  void removeCoords({required final Iterable<CoordinateSetI> coords})
  {
    if (lockState.value == LayerLockState.unlocked)
    {
      for (final CoordinateSetI coord in coords)
      {
        shadingValues.setSigned(x: coord.x, y: coord.y, value: null);
      }
      _trackDirtyRegions(changedCoords: coords);
      doManualRaster = true;




      final DocumentState documentState = GetIt.I.get<DocumentState>();


      final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
      for (final Frame frame in frames) {
        frame.layerList.invalidateDependents(layer: this);
      }
    }
  }

  void addCoords({required final HashMap<CoordinateSetI, int> coords})
  {
    if (lockState.value == LayerLockState.unlocked)
    {
      for (final MapEntry<CoordinateSetI, int> entry in coords.entries)
      {
        //the grid drops pixels off the canvas
        shadingValues.setSigned(x: entry.key.x, y: entry.key.y, value: entry.value.clamp(-settings.shadingStepsMinus.value, settings.shadingStepsPlus.value));
      }
      _trackDirtyRegions(changedCoords: coords.keys);
      doManualRaster = true;




      final DocumentState documentState = GetIt.I.get<DocumentState>();


      final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
      for (final Frame frame in frames) {
        frame.layerList.invalidateDependents(layer: this);
      }
    }
  }

  @protected
  Future<DualRasterResult> createRasters() async
  {
    final DocumentState documentState = GetIt.I.get<DocumentState>();
    final CanvasState canvasState = GetIt.I.get<CanvasState>();
    final Map<Frame, RasterImagePair> rasterImages = <Frame, RasterImagePair>{};

    //consume the render flags now; flags set during rasterization describe
    //changes that are not part of this render and must survive it
    final bool fullRenderForced = _forceFullRender;
    final List<DirtyRegion> renderRegions = List<DirtyRegion>.from(_dirtyRegions);
    _forceFullRender = false;
    _dirtyRegions.clear();

    int? currentIndex;
    if (layerStack != null)
    {
      for (int i = 0; i < layerStack!.length; i++)
      {
        if (layerStack![i] == this)
        {
          currentIndex = i;
          break;
        }
      }
      if (currentIndex != null)
      {
        final RasterImagePair externalStackImages = await _createRasterFromLayers(canvasSize: canvasState.canvasSize, rasterLayers: layerStack!, currentIndex: currentIndex, fullRenderForced: fullRenderForced, renderRegions: renderRegions, frame: null);
        return DualRasterResult(rasterImages: rasterImages, externalStackImages: externalStackImages);
      }
      else
      {
        return DualRasterResult(rasterImages: rasterImages);
      }
    }
    else
    {
      final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);
      pruneFramePixels(frames: frames);
      for (final Frame frame in frames)
      {
        final List<RasterableLayerState> rasterLayers = frame.layerList.getVisibleRasterLayers().toList(growable: false);
        int? frameLayerIndex;
        for (int i = 0; i < rasterLayers.length; i++)
        {
          if (rasterLayers[i] == this)
          {
            frameLayerIndex = i;
            break;
          }
        }
        if (frameLayerIndex != null)
        {
          final RasterImagePair rasterImagePair = await _createRasterFromLayers(canvasSize: canvasState.canvasSize, rasterLayers: rasterLayers, currentIndex: frameLayerIndex, fullRenderForced: fullRenderForced, renderRegions: renderRegions, frame: frame);
          rasterImages[frame] = rasterImagePair;
        }
      }
      return DualRasterResult(rasterImages: rasterImages);
    }
  }

  Future<RasterImagePair> _createRasterFromLayers({
    required final CoordinateSetI canvasSize,
    required final List<RasterableLayerState> rasterLayers,
    required final int currentIndex,
    required final bool fullRenderForced,
    required final List<DirtyRegion> renderRegions,
    required final Frame? frame,
  }) async
  {
    final List<DirtyRegion> combined = _getCombinedDirtyRegions(
      ownRegions: renderRegions,
      rasterLayers: rasterLayers,
      currentIndex: currentIndex,
    );

    final RenderStrategy strategy = determineStrategy(
      dirtyRegions: combined,
      canvasSize: canvasSize,
    );

    if (strategy == RenderStrategy.full || fullRenderForced || previousRaster == null)
    {
      return await _fullRender(
        canvasSize: canvasSize,
        rasterLayers: rasterLayers,
        currentIndex: currentIndex,
        frame: frame,
      );
    }
    else
    {
      return await _regionalRender(
        canvasSize: canvasSize,
        rasterLayers: rasterLayers,
        currentIndex: currentIndex,
        dirtyRegions: combined,
        frame: frame,
      );
    }
  }

  Future<RasterImagePair> _fullRender({
    required final CoordinateSetI canvasSize,
    required final List<RasterableLayerState> rasterLayers,
    required final int currentIndex,
    required final Frame? frame,
  }) async
  {
    final ByteData byteDataThb = ByteData(canvasSize.x * canvasSize.y * 4);
    final ByteData byteDataImg = ByteData(canvasSize.x * canvasSize.y * 4);
    final RasterPixels allColorPixels = RasterPixels.empty(width: canvasSize.x, height: canvasSize.y);
    final List<RasterPixels> below = pixelsBelow(rasterLayers: rasterLayers, currentIndex: currentIndex, frame: frame);

    for (int x = 0; x < canvasSize.x; x++)
    {
      for (int y = 0; y < canvasSize.y; y++)
      {
        final int? valAt = shadingValues.getSigned(x: x, y: y);
        int brightVal = thumbnailBrightnessMap[0]!;

        if (valAt != null)
        {
          brightVal = thumbnailBrightnessMap[valAt] ?? 0;
          final ColorReference? refCol = colorAmong(pixels: below, x: x, y: y);
          if (refCol != null)
          {
            final int currentColorIndex = refCol.colorIndex;
            final int targetColorIndex = (currentColorIndex + valAt).clamp(0, refCol.ramp.references.length - 1);
            final ColorReference targetColor = refCol.ramp.references[targetColorIndex];
            allColorPixels.setColorAt(x: x, y: y, color: targetColor);
          }
        }

        final int pixelIndex = (y * canvasSize.x + x) * 4;
        byteDataThb.setUint8(pixelIndex + 0, brightVal);
        byteDataThb.setUint8(pixelIndex + 1, brightVal);
        byteDataThb.setUint8(pixelIndex + 2, brightVal);
        byteDataThb.setUint8(pixelIndex + 3, 255);
      }
    }

    allColorPixels.writeRgba(target: byteDataImg, width: canvasSize.x, height: canvasSize.y);
    setRasterPixels(pixels: allColorPixels, frame: frame);

    final Completer<ui.Image> completerThb = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataThb.buffer.asUint8List(),
      canvasSize.x,
      canvasSize.y,
      ui.PixelFormat.rgba8888,
          (final ui.Image convertedImage) {
        completerThb.complete(convertedImage);
      },
    );
    final ui.Image thbImg = await completerThb.future;

    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataImg.buffer.asUint8List(),
      canvasSize.x,
      canvasSize.y,
      ui.PixelFormat.rgba8888,
          (final ui.Image convertedImage) {
        completerImg.complete(convertedImage);
      },
    );
    final ui.Image rasterImg = await completerImg.future;

    return RasterImagePair(raster: rasterImg, thumbnail: thbImg);
  }

  Future<RasterImagePair> _regionalRender({
    required final CoordinateSetI canvasSize,
    required final List<RasterableLayerState> rasterLayers,
    required final int currentIndex,
    required final List<DirtyRegion> dirtyRegions,
    required final Frame? frame,
  }) async
  {
    final List<DirtyRegion> mergedRegions = mergeOverlappingRegions(regions: dirtyRegions);

    final ui.Image? baseRaster = rasterImage.value;
    final ui.Image? baseThumbnail = thumbnail.value;

    //the regions are patched into the frame's pixels, so those have to exist
    final RasterPixels? framePixels = pixelsForFrame(frame: frame);
    if (baseRaster == null || baseThumbnail == null || framePixels == null)
    {
      return await _fullRender(
        canvasSize: canvasSize,
        rasterLayers: rasterLayers,
        currentIndex: currentIndex,
        frame: frame,
      );
    }

    final ui.PictureRecorder rasterRecorder = ui.PictureRecorder();
    final Canvas rasterCanvas = Canvas(rasterRecorder);
    final Paint paint = Paint();
    //regions must replace the base content 1:1 (including pixels that are no
    //longer shaded); srcOver would keep stale shaded pixels from the base visible
    final Paint regionPaint = Paint()..blendMode = ui.BlendMode.src;
    rasterCanvas.drawImage(baseRaster, Offset.zero, paint);

    final ui.PictureRecorder thumbRecorder = ui.PictureRecorder();
    final Canvas thumbCanvas = Canvas(thumbRecorder);
    thumbCanvas.drawImage(baseThumbnail, Offset.zero, paint);

    for (final DirtyRegion region in mergedRegions)
    {
      final DirtyRegion clampedRegion = _clampRegion(region: region, canvasSize: canvasSize);

      final RasterImagePair regionImages = await _renderRegion(
        region: clampedRegion,
        rasterLayers: rasterLayers,
        currentIndex: currentIndex,
        frame: frame,
        own: framePixels,
      );

      final Offset offset = Offset(clampedRegion.x.toDouble(), clampedRegion.y.toDouble());
      rasterCanvas.drawImage(regionImages.raster, offset, regionPaint);
      thumbCanvas.drawImage(regionImages.thumbnail, offset, regionPaint);

      regionImages.raster.dispose();
      regionImages.thumbnail.dispose();
    }

    final ui.Picture rasterPicture = rasterRecorder.endRecording();
    final ui.Image finalRaster = await rasterPicture.toImage(canvasSize.x, canvasSize.y);
    rasterPicture.dispose();

    final ui.Picture thumbPicture = thumbRecorder.endRecording();
    final ui.Image finalThumb = await thumbPicture.toImage(canvasSize.x, canvasSize.y);
    thumbPicture.dispose();

    return RasterImagePair(raster: finalRaster, thumbnail: finalThumb);
  }

  Future<RasterImagePair> _renderRegion({
    required final DirtyRegion region,
    required final List<RasterableLayerState> rasterLayers,
    required final int currentIndex,
    required final Frame? frame,
    required final RasterPixels own,
  }) async
  {
    final ByteData byteDataThb = ByteData(region.width * region.height * 4);
    final ByteData byteDataImg = ByteData(region.width * region.height * 4);
    final List<RasterPixels> below = pixelsBelow(rasterLayers: rasterLayers, currentIndex: currentIndex, frame: frame);

    for (int y = region.y; y < region.y + region.height; y++)
    {
      for (int x = region.x; x < region.x + region.width; x++)
      {
        final int? valAt = shadingValues.getSigned(x: x, y: y);
        int brightVal = thumbnailBrightnessMap[0]!;
        ColorReference? shaded;

        if (valAt != null)
        {
          brightVal = thumbnailBrightnessMap[valAt] ?? 0;
          final ColorReference? refCol = colorAmong(pixels: below, x: x, y: y);
          if (refCol != null)
          {
            final int targetColorIndex = (refCol.colorIndex + valAt).clamp(0, refCol.ramp.references.length - 1);
            shaded = refCol.ramp.references[targetColorIndex];
          }
        }
        //the region replaces what the frame showed here, a pixel that shows
        //nothing any more included
        own.setColorAt(x: x, y: y, color: shaded);

        final int pixelIndex = ((y - region.y) * region.width + (x - region.x)) * 4;
        byteDataThb.setUint8(pixelIndex + 0, brightVal);
        byteDataThb.setUint8(pixelIndex + 1, brightVal);
        byteDataThb.setUint8(pixelIndex + 2, brightVal);
        byteDataThb.setUint8(pixelIndex + 3, 255);
      }
    }

    own.writeRgba(target: byteDataImg, left: region.x, top: region.y, width: region.width, height: region.height);

    final Completer<ui.Image> completerThb = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataThb.buffer.asUint8List(),
      region.width,
      region.height,
      ui.PixelFormat.rgba8888,
          (final ui.Image convertedImage) {
        completerThb.complete(convertedImage);
      },
    );
    final ui.Image thbImg = await completerThb.future;

    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataImg.buffer.asUint8List(),
      region.width,
      region.height,
      ui.PixelFormat.rgba8888,
          (final ui.Image convertedImage) {
        completerImg.complete(convertedImage);
      },
    );
    final ui.Image rasterImg = await completerImg.future;

    return RasterImagePair(raster: rasterImg, thumbnail: thbImg);
  }




  void _rasterCreated({required final DualRasterResult rasterResult})
  {
    final List<ui.Image?> outgoing = collectHeldImages();

    thumbnail.value = rasterResult.externalStackImages != null
        ? rasterResult.externalStackImages!.thumbnail
        : (rasterResult.rasterImages.isNotEmpty ? rasterResult.rasterImages.values.first.thumbnail : null);
    previousRaster = rasterImage.value;
    rasterImage.value = rasterResult.externalStackImages != null
        ? rasterResult.externalStackImages!.raster
        : (rasterResult.rasterImages.isNotEmpty ? rasterResult.rasterImages.values.first.raster : null);
    rasterImageMap.value = rasterResult.rasterImages;

    releaseSuperseded(outgoing: outgoing);

    isRasterizing = false;
    _isUpdateScheduled = false;

    if (layerStack == null)
    {
      GetIt.I.get<LayerManager>().newRasterData(layer: this);
    }
  }

  @override
  void pollRaster()
  {
    if (_isUpdateScheduled || !doManualRaster || isRasterizing) {
      return;
    }

    _isUpdateScheduled = true;
    isRasterizing = true;


    final DocumentState documentState = GetIt.I.get<DocumentState>();

    final List<Frame> frames = documentState.timeline.findFramesForLayer(layer: this);

    for (final Frame frame in frames) {
      frame.layerList.lockLayerAndDependenciesForRendering(layer: this);
    }

    bool allDepsComplete = true;
    for (final Frame frame in frames) {
      if (!frame.layerList.areDependenciesComplete(layer: this)) {
        allDepsComplete = false;
        break;
      }
    }

    if (!allDepsComplete) {
      isRasterizing = false;
      _isUpdateScheduled = false;
      doManualRaster = true;
      for (final Frame frame in frames) {
        frame.layerList.unlockLayerAndDependenciesFromRendering(layer: this);
      }
      return;
    }

    //consume the pending request now; requests arriving during rasterization
    //set the flag again and are serviced on the next timer tick
    doManualRaster = false;

    createRasters().then((final DualRasterResult rasterResult)
    {
      if (isDisposed)
      {
        //dropped while this raster was running: nothing owns these images now
        discardRasterResult(rasterResult: rasterResult);
        return;
      }
      if (_isUpdateScheduled) {
        _rasterCreated(rasterResult: rasterResult);
      }
      else {
        //the request was dropped while this raster ran, so nothing is going to
        //store these images
        discardRasterResult(rasterResult: rasterResult);
      }
    }).catchError((final dynamic e, final dynamic s) {
      GetIt.I.get<Logger>().e("Error during shading layer rasterization", error: e);
      doManualRaster = true;
    }).whenComplete(() {
      //this chain owns the whole raster cycle, so the flag is released here
      //whichever way the cycle ended
      isRasterizing = false;
      _isUpdateScheduled = false;
      settleRaster();

      for (final Frame frame in frames) {
        frame.layerList.unlockLayerAndDependenciesFromRendering(layer: this);
      }
    });
  }


  @override
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    shadingValues = shadingValues.resized(newWidth: newSize.x, newHeight: newSize.y, offsetX: offset.x, offsetY: offset.y);
    forceFullRender();
  }

  /// Turns or mirrors the shading with the canvas. For a rotation, width and
  /// height swap.
  void transformLayer({required final CanvasTransformation transformation, required final CoordinateSetI oldSize})
  {
    assert(oldSize.x == shadingValues.width && oldSize.y == shadingValues.height, "the layer is ${shadingValues.width}x${shadingValues.height}, not ${oldSize.x}x${oldSize.y}");
    switch (transformation)
    {
      case CanvasTransformation.rotate:
        shadingValues = shadingValues.rotatedClockwise();
      case CanvasTransformation.flipH:
        shadingValues = shadingValues.flippedHorizontally();
      case CanvasTransformation.flipV:
        shadingValues = shadingValues.flippedVertically();
    }
    forceFullRender();
  }

  /// What the visible layers below this one in [rasterLayers] showed in
  /// [frame] when they were last rastered, nearest first.
  @protected
  List<RasterPixels> pixelsBelow({required final List<RasterableLayerState> rasterLayers, required final int currentIndex, required final Frame? frame})
  {
    final List<RasterPixels> below = <RasterPixels>[];
    for (int i = currentIndex + 1; i < rasterLayers.length; i++)
    {
      final RasterableLayerState layer = rasterLayers[i];
      final RasterPixels? pixels = layer.visibilityState.value == LayerVisibilityState.visible ? layer.pixelsForFrame(frame: frame) : null;
      if (pixels != null)
      {
        below.add(pixels);
      }
    }
    return below;
  }

  /// The color of the first of [pixels] that has one at [x]|[y].
  static ColorReference? colorAmong({required final List<RasterPixels> pixels, required final int x, required final int y})
  {
    for (final RasterPixels layerPixels in pixels)
    {
      final int code = layerPixels.grid.get(x: x, y: y);
      if (code != PaletteCodec.transparent)
      {
        return layerPixels.codec.decode(code: code);
      }
    }
    return null;
  }

  @override
  LayerSettingsWidget getSettingsWidget() {
    return ShadingLayerSettingsWidget(settings: settings, isForDithering: false);
  }

  @override
  void forceFullRender()
  {
    _forceFullRender = true;
    _dirtyRegions.clear();
    doManualRaster = true;
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

    _dirtyRegions.add(
      DirtyRegion(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1,
      ),
    );
  }

  List<DirtyRegion> _getCombinedDirtyRegions({
    required final List<DirtyRegion> ownRegions,
    required final List<RasterableLayerState> rasterLayers,
    required final int currentIndex,
  })
  {
    final List<DirtyRegion> combined = List<DirtyRegion>.from(ownRegions);

    for (int i = currentIndex + 1; i < rasterLayers.length; i++)
    {
      final RasterableLayerState layer = rasterLayers[i];
      if (layer is DrawingLayerState)
      {
        combined.addAll(layer.dirtyRegions);
      }
    }

    return combined;
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
  void dispose()
  {
    markDisposed();
    settleRaster();
    stopRasterPolling();
    settings.removeListener(_settingsChanged);
    _isUpdateScheduled = false;
    shadingValues.clear();
    thumbnailBrightnessMap.clear();

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
