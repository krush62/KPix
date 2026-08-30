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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kpix/layer_states/layer_settings.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

class RasterImagePair
{
  final ui.Image thumbnail;
  final ui.Image raster;
  RasterImagePair({required this.thumbnail, required this.raster});
}

class DualRasterResult
{
  final Map<Frame, RasterImagePair> rasterImages;
  final RasterImagePair? externalStackImages;
  DualRasterResult({required this.rasterImages, this.externalStackImages});
}

abstract class RasterableLayerState extends LayerState
{
  final ValueNotifier<LayerLockState> lockState = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
  bool isRasterizing = false;
  CoordinateColorMap rasterPixels = CoordinateColorMap();
  final ValueNotifier<ui.Image?> rasterImage = ValueNotifier<ui.Image?>(null);
  final ValueNotifier<Map<Frame, RasterImagePair>> rasterImageMap = ValueNotifier<Map<Frame, RasterImagePair>>(<Frame, RasterImagePair>{});
  ui.Image? previousRaster;
  bool _doManualRaster = false;

  /// Whether a full re-raster has been asked for and not yet served.
  ///
  /// Setting this to true is how most of the app requests a raster, so it is also
  /// where waiters get armed; see [rasterizationComplete].
  bool get doManualRaster
  {
    return _doManualRaster;
  }

  set doManualRaster(final bool value)
  {
    _doManualRaster = value;
    if (value)
    {
      requestRaster();
    }
  }

  @override
  bool get hasPendingRaster
  {
    return _doManualRaster;
  }
  final LayerSettings layerSettings;
  List<RasterableLayerState>? layerStack;

  RasterableLayerState({required this.layerSettings, this.layerStack});
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset});
  LayerSettingsWidget getSettingsWidget();

  //requests a full (non-regional) re-rasterization of this layer;
  //used when the changed area is unknown (e.g. a dependency layer changed)
  void forceFullRender();

  /// Releases the images of a raster whose result will not be stored.
  ///
  /// A raster can finish after the request behind it was cancelled, usually by
  /// disposal. Nothing takes ownership of those images, so they have to be let go
  /// here or they stay allocated for the rest of the session.
  @protected
  void discardRasterResult({required final DualRasterResult rasterResult})
  {
    final List<ui.Image?> orphans = <ui.Image?>[
      rasterResult.externalStackImages?.raster,
      rasterResult.externalStackImages?.thumbnail,
    ];
    for (final RasterImagePair pair in rasterResult.rasterImages.values)
    {
      orphans.add(pair.raster);
      orphans.add(pair.thumbnail);
    }
    disposeImages(images: orphans);
  }

  /// Every image this layer currently points at.
  ///
  /// Capture this before storing a new raster generation, then hand it to
  /// [releaseSuperseded] afterwards.
  @protected
  List<ui.Image?> collectHeldImages()
  {
    final List<ui.Image?> held = <ui.Image?>[previousRaster, rasterImage.value, thumbnail.value];
    for (final RasterImagePair pair in rasterImageMap.value.values)
    {
      held.add(pair.raster);
      held.add(pair.thumbnail);
    }
    return held;
  }

  /// Releases everything in [outgoing] that the layer no longer points at.
  ///
  /// A raster generation shares handles freely - the same image is typically the
  /// raster, the thumbnail and the entry for one frame all at once - and the next
  /// generation carries some of them over, most notably the one that becomes
  /// [previousRaster]. So the two generations have to be diffed; releasing the old
  /// one wholesale would free an image still in use, and dropping it without
  /// releasing anything strands one image per frame on every raster.
  @protected
  void releaseSuperseded({required final Iterable<ui.Image?> outgoing})
  {
    final Set<ui.Image> retained = <ui.Image>{};
    for (final ui.Image? image in collectHeldImages())
    {
      if (image != null)
      {
        retained.add(image);
      }
    }

    final List<ui.Image?> release = <ui.Image?>[];
    for (final ui.Image? image in outgoing)
    {
      if (image != null && !retained.contains(image))
      {
        release.add(image);
      }
    }
    disposeImages(images: release);
  }
}
