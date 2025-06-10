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
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

abstract class RasterableLayerState extends LayerState
{
  final ValueNotifier<LayerLockState> lockState = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
  bool isRasterizing = false;
  CoordinateColorMap rasterPixels = CoordinateColorMap();
  final ValueNotifier<ui.Image?> rasterImage = ValueNotifier<ui.Image?>(null);
  ui.Image? previousRaster;
  bool doManualRaster = false;
  final LayerSettings layerSettings;

  RasterableLayerState({required this.layerSettings});
  void resizeLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset});
  LayerSettingsWidget getSettingsWidget();


}
