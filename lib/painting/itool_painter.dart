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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_data.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/content_raster_set.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/painting/stroke_preview.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/tool_geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:logger/logger.dart';

class DrawingParameters
{
  final Offset offset;
  final Canvas canvas;
  final Paint paint;
  final int pixelSize;
  final CoordinateSetI canvasSize;
  final CoordinateSetI scaledCanvasSize;
  final Size drawingSize;
  final CoordinateSetD? cursorPos;
  final CoordinateSetI? cursorPosNorm;
  final bool primaryDown;
  final bool secondaryDown;
  final bool stylusButtonDown;
  final Offset primaryPressStart;
  final ReferenceLayerState? currentReferenceLayer;
  final GridLayerState? currentGridLayer;
  final RasterableLayerState? currentRasterLayer;
  final double pixelRatio;
  final double? symmetryHorizontal;
  final double? symmetryVertical;
  final bool isPlaying;
  DrawingParameters({
    required this.offset,
    required this.canvas,
    required this.paint,
    required this.pixelSize,
    required this.canvasSize,
    required this.drawingSize,
    required this.cursorPos,
    required this.cursorPosNorm,
    required this.primaryDown,
    required this.stylusButtonDown,
    required this.secondaryDown,
    required this.primaryPressStart,
    required this.pixelRatio,
    required final LayerState currentLayer,
    required this.symmetryHorizontal,
    required this.symmetryVertical,
    required this.isPlaying,
  }) :
        scaledCanvasSize = CoordinateSetI(x: canvasSize.x * pixelSize, y: canvasSize.y * pixelSize),
        currentRasterLayer = currentLayer is RasterableLayerState ? currentLayer : null,
        currentReferenceLayer = currentLayer.kind == LayerKind.reference ? (currentLayer as ReferenceLayerState) : null,
        currentGridLayer = currentLayer.kind == LayerKind.grid ? (currentLayer as GridLayerState) : null;
}

/// The color a pixel drawn on a layer shows on the canvas: the visible layers
/// above it in a frame cover or shade it.
class PreviewColors
{
  final Frame _frame;
  final int _layerPosition;
  final RgbaCache _rgbaCache = RgbaCache();

  PreviewColors._({required final Frame frame, required final int layerPosition}) :
      _frame = frame,
      _layerPosition = layerPosition;

  /// The RGBA value [color] at [coord] shows, as `ui.PixelFormat.rgba8888`
  /// reads it.
  int rgbaAt({required final CoordinateSetI coord, required final ColorReference color})
  {
    ColorReference colRef = color;
    for (int i = _layerPosition - 1; i >= 0; i--)
    {
      final LayerState layer = _frame.layerList.getLayer(index: i);
      if (layer is DrawingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
      {
        final int? shadingVal = layer.outerShadingAt(frame: _frame, coord: coord);
        if (shadingVal != null)
        {
          colRef = colRef.shiftedBy(steps: shadingVal);
        }
        else
        {
          final ColorReference? layerColRef = layer.compositeAt(frame: _frame, coord: coord);
          if (layerColRef != null)
          {
            colRef = layerColRef;
          }
        }
      }
      else if (layer is ShadingLayerState && layer.visibilityState.value == LayerVisibilityState.visible)
      {
        final int? shadingVal = layer.getRawValueAt(coord: coord);
        if (shadingVal != null)
        {
          if (layer.kind == LayerKind.shading)
          {
            colRef = colRef.shiftedBy(steps: shadingVal);
          }
        }
      }
    }
    return _rgbaCache.rgbaOf(reference: colRef);
  }
}

abstract class IToolPainter
{
  final ProjectSession projectSession = GetIt.I.get<ProjectSession>();
  final PaletteState paletteState = GetIt.I.get<PaletteState>();
  final CanvasState canvasState = GetIt.I.get<CanvasState>();
  final DocumentState documentState = GetIt.I.get<DocumentState>();
  final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
  final GuiPreferenceContent guiPrefs = GetIt.I.get<PreferenceManager>().guiPreferenceContent;
  final HotkeyManager _modifierKeys = GetIt.I.get<HotkeyManager>();
  final KPixPainterOptions painterOptions;
  final StatusBarData statusBarData = StatusBarData();
  late Color blackToolAlphaColor;
  late Color whiteToolAlphaColor;
  bool _hasHistoryData = false;
  //the layer the pending history data was drawn on, captured at commit time
  //(the history state itself is added later by a polling timer and the user
  //may have selected a different layer by then)
  LayerState? historyLayer;
  StrokePreview? _strokePreview;
  //previews of strokes that are handed to their layer but not shown by it yet
  final List<StrokePreview> _landingPreviews = <StrokePreview>[];
  ContentRasterSet? cursorRaster;
  bool hasAsyncUpdate = false;

  IToolPainter({required this.painterOptions})
  {
    guiPrefs.toolOpacity.addListener(_toolOpacityChanged);
    _setOutlineColors(percentageValue: guiPrefs.toolOpacity.value);
    _modifierKeys.shiftNotifier.addListener(_modifierKeysChanged);
    _modifierKeys.controlNotifier.addListener(_modifierKeysChanged);
  }

  //previews depending on modifier keys can't wait for the cursor to move
  void _modifierKeysChanged()
  {
    modifiersChanged();
    hasAsyncUpdate = true;
  }

  /// Called when shift or control is pressed or released, before the repaint.
  void modifiersChanged() {}

  void _toolOpacityChanged()
  {
    _setOutlineColors(percentageValue: guiPrefs.toolOpacity.value);
    GetIt.I.get<ViewState>().repaintNotifier.repaint();
  }

  void _setOutlineColors({required final int percentageValue})
  {
    final int alignedValue = (percentageValue.toDouble() * 2.55).round();
    blackToolAlphaColor = Colors.black.withAlpha(alignedValue);
    whiteToolAlphaColor = Colors.white.withAlpha(alignedValue);
  }

  @mustCallSuper
  void dispose()
  {
    guiPrefs.toolOpacity.removeListener(_toolOpacityChanged);
    _modifierKeys.shiftNotifier.removeListener(_modifierKeysChanged);
    _modifierKeys.controlNotifier.removeListener(_modifierKeysChanged);
  }

  bool get hasHistoryData
  {
    return _hasHistoryData;
  }

  set hasHistoryData(final bool value)
  {
    _hasHistoryData = value;
    historyLayer = value ? documentState.timeline.getCurrentLayer() : null;
  }

  void calculate({required final DrawingParameters drawParams}){}
  void drawExtras({required final DrawingParameters drawParams}){}
  void drawCursorOutline({required final DrawingParameters drawParams});
  CursorInfo? getCursorInfo({required final DrawingParameters drawParams}) => null;
  void reset() {}
  HistoryStateTypeIdentifier get historyIdentifier => HistoryStateTypeIdentifier.generic;
  void setStatusBarData({required final DrawingParameters drawParams})
  {
    statusBarData.cursorPos = null;
    statusBarData.dimension = null;
    statusBarData.diagonal = null;
    statusBarData.aspectRatio = null;
    statusBarData.angle = null;
  }

  void setLineStatusBarData({required final CoordinateSetI startPos, required final CoordinateSetI endPos})
  {
    final int width = (endPos.x - startPos.x).abs() + 1;
    final int height = (endPos.y - startPos.y).abs() + 1;
    statusBarData.aspectRatio = statusBarData.diagonal = statusBarData.dimension = CoordinateSetI(x: width, y: height);
    statusBarData.angle = startPos;
  }

  /// Writes [pixels] into the floating selection if there is one, into [layer] otherwise.
  void commitPixels({required final DrawingLayerState layer, required final CoordinateColorMap pixels})
  {
    if (!documentState.selectionState.selection.isEmpty)
    {
      documentState.selectionState.selection.addDirectlyAll(list: pixels);
    }
    else
    {
      layer.setDataAll(list: pixels);
    }
  }

  /// The outline of the pixels [coords] on screen.
  Path pixelOutlinePath({required final DrawingParameters drawParams, required final Set<CoordinateSetI> coords})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    final List<CoordinateSetI> pathPoints = getBoundaryPath(coords: coords);
    final Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * effPxlSize) + drawParams.offset.dx, (pathPoints[i].y * effPxlSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * effPxlSize) + drawParams.offset.dx, (pathPoints[i + 1].y * effPxlSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * effPxlSize) + drawParams.offset.dx, (pathPoints[0].y * effPxlSize) + drawParams.offset.dy);
      }
    }
    return path;
  }

  /// Strokes [path] wide in dark and then narrow in light, as the tools outline their cursors.
  void strokeOutline({required final DrawingParameters drawParams, required final Path path, final bool opaque = false})
  {
    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = opaque ? Colors.black : blackToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = opaque ? Colors.white : whiteToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }

  /// The images of the content being drawn, in the order they are drawn.
  List<ContentRasterSet> get contentRasters
  {
    return <ContentRasterSet>[
      for (final StrokePreview preview in _landingPreviews) ...preview.rasters,
      ...?_strokePreview?.rasters,
    ];
  }

  /// The preview of the stroke being drawn, started on first use.
  StrokePreview get strokePreview
  {
    return _strokePreview ??= StrokePreview(onUpdate: () => hasAsyncUpdate = true);
  }

  /// Whether a stroke being drawn has a preview yet.
  bool get hasStrokePreview => _strokePreview != null;

  /// Adds [settledPixels] to the preview of the stroke being drawn and, if
  /// given, shows [tipPixels] on top of it in place of the last tip. Only these
  /// pixels are looked at, so an update costs the same however much the stroke
  /// already holds.
  void updateStrokePreview({required final CoordinateColorMap settledPixels, final CoordinateColorMap? tipPixels, required final LayerState currentLayer})
  {
    final PreviewColors? previewColors = getPreviewColors(currentLayer: currentLayer);
    if (previewColors == null || (settledPixels.isEmpty && (tipPixels == null || tipPixels.isEmpty) && !hasStrokePreview))
    {
      return;
    }
    final StrokePreview preview = strokePreview;
    for (final CoordinateColor entry in settledPixels.entries)
    {
      preview.addPixel(x: entry.key.x, y: entry.key.y, rgba: previewColors.rgbaAt(coord: entry.key, color: entry.value));
    }
    if (tipPixels != null)
    {
      final HashMap<CoordinateSetI, int> tip = HashMap<CoordinateSetI, int>();
      for (final CoordinateColor entry in tipPixels.entries)
      {
        tip[entry.key] = previewColors.rgbaAt(coord: entry.key, color: entry.value);
      }
      preview.setTip(pixels: tip);
    }
    unawaited(preview.render());
  }

  bool isLayerStackSettled({required final RasterableLayerState? layer})
  {
    if (layer == null)
    {
      return true;
    }
    if (layer.doManualRaster || layer.isRasterizing || (layer is DrawingLayerState && layer.rasterQueue.isNotEmpty))
    {
      return false;
    }
    //only the selected frame is on the canvas, so only its layers can flicker
    final Frame? frame = documentState.timeline.selectedFrame;
    return frame == null || !frame.layerList.contains(layer: layer) || frame.layerList.areDependentsComplete(layer: layer);
  }

  /// Throws away the preview of the stroke being drawn, which never lands.
  void discardStrokePreview()
  {
    _strokePreview?.dispose();
    _strokePreview = null;
  }

  /// Takes the content off the canvas once [currentLayer] shows it.
  ///
  /// The stroke preview is handed over at once, so a stroke started in the
  /// meantime gets a preview of its own.
  void resetContentRaster({required final LayerState currentLayer})
  {
    final StrokePreview? landingPreview = _strokePreview;
    if (landingPreview == null)
    {
      return;
    }
    _strokePreview = null;
    _landingPreviews.add(landingPreview);
    _waitForLayerToFinishRasterizing(currentLayer: currentLayer).then((final void _) {
      _landingPreviews.remove(landingPreview);
      landingPreview.dispose();
      hasAsyncUpdate = true;
    });
  }

  Future<void> _waitForLayerToFinishRasterizing({required final LayerState currentLayer}) async
  {
    //the layer arms its waiter when the raster is requested rather than when it
    //starts, so there is no window here to sleep through
    await currentLayer.rasterizationComplete.timeout(rasterSettleTimeout, onTimeout: ()
    {
      GetIt.I.get<Logger>().w("Timed out waiting for a layer to finish rasterizing.");
    },);

    final Frame? frame = documentState.timeline.selectedFrame;
    if (currentLayer is RasterableLayerState && frame != null && frame.layerList.contains(layer: currentLayer))
    {
      //only the selected frame is on the canvas, so only its layers can flicker
      await frame.layerList.waitForDependents(layer: currentLayer).timeout(rasterSettleTimeout, onTimeout: ()
      {
        GetIt.I.get<Logger>().w("Timed out waiting for the layers above to finish rasterizing.");
      },);
    }
  }

  /// How pixels drawn on [currentLayer] show through the layers above it in
  /// the selected frame, or null if that frame does not hold the layer.
  PreviewColors? getPreviewColors({required final LayerState currentLayer})
  {
    final Frame? frame = documentState.timeline.selectedFrame;
    final int? layerPosition = frame?.layerList.getLayerPosition(state: currentLayer);
    return frame == null || layerPosition == null ? null : PreviewColors._(frame: frame, layerPosition: layerPosition);
  }

  Future<ContentRasterSet?> rasterizePixels({required final CoordinateColorMap drawingPixels, required final LayerState currentLayer}) async
  {
    final Frame? frame = documentState.timeline.selectedFrame;
    if (drawingPixels.isNotEmpty && frame != null && frame.layerList.contains(layer: currentLayer))
    {
      final CoordinateSetI min = CoordinateSetI.getMin(coordList: drawingPixels.keys.toList());
      final CoordinateSetI max = CoordinateSetI.getMax(coordList: drawingPixels.keys.toList());
      final CoordinateSetI offset = CoordinateSetI(x: min.x, y: min.y);
      final CoordinateSetI size = CoordinateSetI(x: max.x - min.x + 1, y: max.y - min.y + 1);
      final ByteData byteDataImg = ByteData(size.x * size.y * 4);
      final PreviewColors? previewColors = getPreviewColors(currentLayer: currentLayer);

      if (previewColors != null)
      {
        for (final CoordinateColor entry in drawingPixels.entries)
        {
          final int index = ((entry.key.y - offset.y) * size.x + (entry.key.x - offset.x)) * 4;
          if (index < byteDataImg.lengthInBytes)
          {
            byteDataImg.setUint32(index, previewColors.rgbaAt(coord: entry.key, color: entry.value));
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
      return ContentRasterSet(image: await completerImg.future, offset: offset, size: size);
    }
    else
    {
      return null;
    }
  }

  CoordinateColorMap getPixelsToDraw({required final CoordinateSetI canvasSize, required final DrawingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    for (final CoordinateSetI coord in coords)
    {
      if (canvasSize.contains(coord: coord))
      {
        if (!shaderOptions.isEnabled.value)
        {
          if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord, withSettingsPixels: true,) != selectedColor) ||
              (!selection.selection.isEmpty && selection.selection.contains(coord: coord) && selection.selection.getColorReference(coord: coord) !=selectedColor))
          {
            if (_lockAllowsPaint(coord: coord, layer: currentLayer))
            {
              pixelMap[coord] = selectedColor;
            }
          }
        }
        else
        {
          final ColorReference? layerRef = _getLayerOrSelectionRef(coord: coord, currentLayer: currentLayer, selection: selection,);
          if (layerRef != null && (layerRef.ramp.uuid == selectedColor.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value))
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              if (layerRef.colorIndex + 1 < layerRef.ramp.references.length)
              {
                pixelMap[coord] = layerRef.ramp.references[layerRef.colorIndex + 1];
              }
            }
            else
            {
              if (layerRef.colorIndex > 0)
              {
                pixelMap[coord] = layerRef.ramp.references[layerRef.colorIndex - 1];
              }
            }
          }
        }
      }
    }
    return pixelMap;
  }

  bool _lockAllowsPaint({required final CoordinateSetI coord, required final DrawingLayerState layer,})
  {
    return layer.lockState.value == LayerLockState.unlocked || (layer.lockState.value == LayerLockState.transparency && layer.getDataEntry(coord: coord) != null);
  }

  ColorReference? _getLayerOrSelectionRef({required final CoordinateSetI coord, required final DrawingLayerState currentLayer, required final SelectionState selection,})
  {
    if (selection.selection.isEmpty)
    {
      return currentLayer.getDataEntry(coord: coord);
    }
    if (selection.selection.contains(coord: coord))
    {
      return selection.selection.getColorReference(coord: coord);
    }
    return null;
  }

  /// The color a coord ends up with once the stack from the bottom up to
  /// [toIndex] has been composed.
  ///
  /// [shiftLayer] and [layerShift] preview a pending shading change: the shift is
  /// applied where that layer sits in the stack, so it passes through the same
  /// clamping a real draw would. Applying it to the returned color instead would
  /// move pixels whose ramp is already exhausted, which the draw leaves alone.
  ColorReference? _resolveComposedColorAtCoord({required final CoordinateSetI coord, required final Frame frame, required final int toIndex, required final bool requireVisibility, final LayerState? shiftLayer, final int layerShift = 0,})
  {
    ColorReference? currentColor;
    for (int i = frame.layerList.length - 1; i >= toIndex; i--)
    {
      final LayerState layer = frame.layerList.getLayer(index: i);
      if (!requireVisibility || layer.visibilityState.value == LayerVisibilityState.visible)
      {
        if (layer is DrawingLayerState)
        {
          final ColorReference? col = layer.getDataEntry(coord: coord, withSettingsPixels: true);
          if (col != null)
          {
            currentColor = col;
          }
        }
        else if (currentColor != null && layer is ShadingLayerState)
        {
          final int? displayVal = layer.getDisplayValueAt(coord: coord, shift: layer == shiftLayer ? layerShift : 0,);
          if (displayVal != null)
          {
            currentColor = currentColor.shiftedBy(steps: displayVal);
          }
        }
      }
    }
    return currentColor;
  }

  CoordinateColorMap getPixelsToDrawForShading({required final CoordinateSetI canvasSize, required final ShadingLayerState currentLayer, required final Set<CoordinateSetI> coords, required final ShaderOptions shaderOptions,})
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    final Frame? frame = documentState.timeline.selectedFrame;
    if (currentLayer.lockState.value == LayerLockState.unlocked && frame != null && frame.layerList.contains(layer: currentLayer))
    {
      final int? currentLayerPos = frame.layerList.getLayerPosition(state: currentLayer);
      if (currentLayerPos != null && currentLayerPos >= 0)
      {
        for (final CoordinateSetI coord in coords)
        {
          if (canvasSize.contains(coord: coord))
          {
            int shift = shaderOptions.shaderDirection.value == ShaderDirection.right ? 1 : -1;
            final int currentVal = currentLayer.getRawValueAt(coord: coord) ?? 0;
            if (currentVal + shift < -currentLayer.settings.shadingStepsMinus.value || currentVal + shift > currentLayer.settings.shadingStepsPlus.value)
            {
              shift = 0;
            }
            //stop at this layer: rasterizePixels applies everything above it, so
            //composing past it here would apply those layers a second time
            final ColorReference? shiftedColor = _resolveComposedColorAtCoord(coord: coord, frame: frame, toIndex: currentLayerPos, requireVisibility: true, shiftLayer: currentLayer, layerShift: shift,);
            if (shiftedColor != null)
            {
              if (currentLayer.kind == LayerKind.shading)
              {
                pixelMap[coord] = shiftedColor;
              }
              else if (currentLayer is DitherLayerState)
              {
                final int currentDitherVal = currentLayer.getDisplayValueAt(coord: coord);
                final int ditherVal = currentLayer.getDisplayValueAt(coord: coord, shift: shift);
                if (currentDitherVal != ditherVal)
                {
                  pixelMap[coord] = shiftedColor;
                }
              }
            }
          }
        }
      }
    }
    return pixelMap;
  }

  CoordinateColorMap getStampPixelsToDraw({
    required final CoordinateSetI canvasSize,
    required final DrawingLayerState currentLayer,
    required final HashMap<CoordinateSetI, int> stampData,
    required final SelectionState selection,
    required final ShaderOptions shaderOptions,
    required final ColorReference selectedColor,
  })
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    for (final MapEntry<CoordinateSetI, int> stampEntry in stampData.entries)
    {
      final CoordinateSetI coord = stampEntry.key;
      if (canvasSize.contains(coord: coord))
      {
        if (!shaderOptions.isEnabled.value)
        {
          final ColorReference drawColor = selectedColor.shiftedBy(steps: stampEntry.value);
          if ((selection.selection.isEmpty && currentLayer.getDataEntry(coord: coord) != drawColor) ||
              (!selection.selection.isEmpty && selection.selection.contains(coord: coord) && selection.selection.getColorReference(coord: coord) != drawColor))
          {
            if (_lockAllowsPaint(coord: coord, layer: currentLayer))
            {
              pixelMap[coord] = drawColor;
            }
          }
        }
        else
        {
          final ColorReference? layerRef = _getLayerOrSelectionRef(coord: coord, currentLayer: currentLayer, selection: selection,);
          if (layerRef != null && (layerRef.ramp.uuid == selectedColor.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value))
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              pixelMap[coord] = layerRef.shiftedBy(steps: stampEntry.value + 1);
            }
            else
            {
              pixelMap[coord] = layerRef.shiftedBy(steps: -stampEntry.value - 1);
            }
          }
        }
      }
    }
    return pixelMap;
  }

  CoordinateColorMap getStampPixelsToDrawForShading({
    required final CoordinateSetI canvasSize,
    required final ShadingLayerState currentLayer,
    required final HashMap<CoordinateSetI, int> stampData,
    required final ShaderOptions shaderOptions,
  })
  {
    final CoordinateColorMap pixelMap = HashMap<CoordinateSetI, ColorReference>();
    final Frame? frame = documentState.timeline.selectedFrame;
    if (frame != null && frame.layerList.contains(layer: currentLayer))
    {
      final int? currentLayerPos = frame.layerList.getLayerPosition(state: currentLayer);
      if (currentLayerPos != null && currentLayerPos >= 0)
      {
        for (final MapEntry<CoordinateSetI, int> stampEntry in stampData.entries)
        {
          final CoordinateSetI coord = stampEntry.key;
          if (canvasSize.contains(coord: coord))
          {
            final int shadingDirection = shaderOptions.shaderDirection.value == ShaderDirection.left ? -1 : 1;
            //the value dumpStampShading would store, so the preview and the draw
            //cannot disagree at the ends of the ramp
            final int currentVal = currentLayer.getRawValueAt(coord: coord) ?? 0;
            final int targetVal = (shadingDirection + currentVal + (stampEntry.value * shadingDirection)).clamp(-currentLayer.settings.shadingStepsMinus.value, currentLayer.settings.shadingStepsPlus.value,);
            final int shadingAmount = targetVal - currentVal;
            final ColorReference? shiftedColor = _resolveComposedColorAtCoord(coord: coord, frame: frame, toIndex: currentLayerPos, requireVisibility: false, shiftLayer: currentLayer, layerShift: shadingAmount,);
            if (shiftedColor != null)
            {
              if (currentLayer.kind == LayerKind.shading)
              {
                pixelMap[coord] = shiftedColor;
              }
              else if (currentLayer is DitherLayerState)
              {
                final int currentDitherVal = currentLayer.getDisplayValueAt(coord: coord);
                final int ditherVal = currentLayer.getDisplayValueAt(coord: coord, shift: shadingAmount,);
                if (currentDitherVal != ditherVal)
                {
                  pixelMap[coord] = shiftedColor;
                }
              }
            }
          }
        }
      }
    }
    return pixelMap;
  }

  void dumpStampShading({required final ShadingLayerState shadingLayer, required final HashMap<CoordinateSetI, int> stampData, required final ShaderOptions shaderOptions})
  {
    final List<CoordinateSetI> removeCoords = <CoordinateSetI>[];
    final HashMap<CoordinateSetI, int> changeCoords = HashMap<CoordinateSetI, int>();
    for (final MapEntry<CoordinateSetI, int> entry in stampData.entries)
    {
      final int shadingDirection = shaderOptions.shaderDirection.value == ShaderDirection.left ? -1 : 1;
      final int currentShift = shadingLayer.hasCoord(coord: entry.key) ? shadingLayer.getRawValueAt(coord: entry.key)! : 0;
      final int targetShift = (shadingDirection + currentShift + (entry.value * shadingDirection)).clamp(-shadingLayer.settings.shadingStepsMinus.value, shadingLayer.settings.shadingStepsPlus.value);
      if (targetShift == 0)
      {
        removeCoords.add(entry.key);
      }
      else
      {
        changeCoords[entry.key] = targetShift;
      }
    }
    shadingLayer.removeCoords(coords: removeCoords);
    shadingLayer.addCoords(coords: changeCoords);


    hasHistoryData = true;
    resetContentRaster(currentLayer: shadingLayer);
  }

  void dumpShading({required final ShadingLayerState shadingLayer, required final Set<CoordinateSetI> coordinates, required final ShaderOptions shaderOptions})
  {
    final List<CoordinateSetI> removeCoords = <CoordinateSetI>[];
    final HashMap<CoordinateSetI, int> changeCoords = HashMap<CoordinateSetI, int>();
    for (final CoordinateSetI coord in coordinates)
    {
      final int currentShift = shaderOptions.shaderDirection.value == ShaderDirection.left ? -1 : 1;
      final int targetShift = (shadingLayer.hasCoord(coord: coord) ? shadingLayer.getRawValueAt(coord: coord)! + currentShift : currentShift).clamp(-shadingLayer.settings.shadingStepsMinus.value, shadingLayer.settings.shadingStepsPlus.value);
      if (targetShift == 0)
      {
        removeCoords.add(coord);
      }
      else
      {
        changeCoords[coord] = targetShift;
      }
    }
    shadingLayer.removeCoords(coords: removeCoords);
    shadingLayer.addCoords(coords: changeCoords);


    hasHistoryData = true;
    resetContentRaster(currentLayer: shadingLayer);
  }

  ui.Path getPathFromList({required final List<MapEntry<int, int>> pointList, required final CoordinateSetD offsetPos, required final double scaling})
  {
    final ui.Path path = ui.Path();
    bool firstHandled = false;
    for (final MapEntry<int, int> entry in pointList)
    {
      if (!firstHandled)
      {
        path.moveTo(offsetPos.x + (entry.key * scaling), offsetPos.y + (entry.value * scaling));
        firstHandled = true;
      }
      else
      {
        path.lineTo(offsetPos.x + (entry.key * scaling),offsetPos.y + (entry.value * scaling));
      }
    }
    return path;
  }
}
