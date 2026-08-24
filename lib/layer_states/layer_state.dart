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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';



class LayerWidgetOptions
{
  final double outerPadding;
  final double innerPadding;
  final double borderRadius;
  final double buttonSizeMin;
  final double buttonSizeMax;
  final double iconSize;
  final double height;
  final double dragOpacity;
  final double borderWidth;
  final double dragFeedbackSize;
  final double dragTargetHeight;
  final int dragTargetShowDuration;
  final int thumbUpdateTimerMsec;
  final int addButtonSize;

  LayerWidgetOptions({
    required this.outerPadding,
    required this.innerPadding,
    required this.borderRadius,
    required this.buttonSizeMin,
    required this.buttonSizeMax,
    required this.iconSize,
    required this.height,
    required this.dragOpacity,
    required this.borderWidth,
    required this.dragFeedbackSize,
    required this.dragTargetHeight,
    required this.dragTargetShowDuration,
    required this.thumbUpdateTimerMsec,
    required this.addButtonSize,
  });
}

enum LayerVisibilityState
{
  visible(0, "Visible", TablerIcons.eye),
  hidden(1, "Hidden", TablerIcons.eye_closed);

  const LayerVisibilityState(this.id, this.desc, this.icon);

  final int id;
  final String desc;
  final IconData icon;

  static LayerVisibilityState fromId(final int id) {
    return LayerVisibilityState.values.firstWhere((final LayerVisibilityState lvs) => lvs.id == id);
  }
}

enum LayerLockState
{
  unlocked(0, "Unlocked", TablerIcons.lock_open_2),
  transparency(1, "Transparency locked", TablerIcons.lock_open),
  locked(2, "Locked", TablerIcons.lock);

  const LayerLockState(this.id, this.desc, this.icon);
  final int id;
  final String desc;
  final IconData icon;

  static LayerLockState fromId(final int id) {
    return LayerLockState.values.firstWhere((final LayerLockState lls) => lls.id == id);
  }
}

class ColorReference
{
  final KPalRampData ramp;
  final int colorIndex;
  ColorReference({required this.colorIndex, required this.ramp});
  IdColor getIdColor()
  {
    return ramp.shiftedColors[colorIndex.clamp(0, ramp.shiftedColors.length - 1)].value;
  }

  @override
  bool operator == (final Object other) =>
      identical(this, other) ||
          other is ColorReference &&
              runtimeType == other.runtimeType &&
              ramp == other.ramp &&
              colorIndex == other.colorIndex;

  @override
  int get hashCode => ramp.hashCode ^ colorIndex.hashCode;
}

enum LayerMenuKind
{
  drawing,
  raster,
  reference
}

abstract class LayerState
{
  final ValueNotifier<bool> selectedInCurrentFrameNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<LayerVisibilityState> visibilityState = ValueNotifier<LayerVisibilityState>(LayerVisibilityState.visible);
  final ValueNotifier<ui.Image?> thumbnail = ValueNotifier<ui.Image?>(null);
  IconData get icon;
  LayerMenuKind get menuKind;
  bool get thumbnailIsContent => false;

  LayerState copy({final List<RasterableLayerState>? layerStack});
  HistoryLayer toHistoryLayer({
    required final List<HistoryRampData> ramps,
    final HistoryLayer? previousLayer,
  });
}
