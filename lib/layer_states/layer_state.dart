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
  visible,
  hidden,
}

const Map<int, LayerVisibilityState> layerVisibilityStateValueMap =
<int, LayerVisibilityState>{
  0: LayerVisibilityState.visible,
  1: LayerVisibilityState.hidden,
};

enum LayerLockState
{
  unlocked,
  transparency,
  locked,
}

const Map<int, LayerLockState> layerLockStateValueMap =
<int, LayerLockState>{
  0: LayerLockState.unlocked,
  1: LayerLockState.transparency,
  2: LayerLockState.locked,
};

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

abstract class LayerState
{
  final ValueNotifier<LayerVisibilityState> visibilityState = ValueNotifier<LayerVisibilityState>(LayerVisibilityState.visible);
  final ValueNotifier<bool> isSelected = ValueNotifier<bool>(false);
  final ValueNotifier<ui.Image?> thumbnail = ValueNotifier<ui.Image?>(null);
}
