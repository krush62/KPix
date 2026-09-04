/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:kpix/models/constraints/frame_blending_constraints.dart';

class FrameBlendingOptions
{
  final ValueNotifier<bool> enabled;
  final ValueNotifier<int> framesBefore;
  final ValueNotifier<bool> wrapAroundBefore;
  final ValueNotifier<int> framesAfter;
  final ValueNotifier<bool> wrapAroundAfter;
  final ValueNotifier<double> opacity;
  final ValueNotifier<bool> gradualOpacity;
  final ValueNotifier<bool> tinting;
  final ValueNotifier<bool> activeLayerOnly;

  FrameBlendingOptions() :
        enabled = ValueNotifier<bool>(FrameBlendingConstraints.enabledDefault),
        framesBefore = ValueNotifier<int>(FrameBlendingConstraints.framesBeforeDefault),
        wrapAroundBefore = ValueNotifier<bool>(FrameBlendingConstraints.wrapBeforeDefault),
        framesAfter = ValueNotifier<int>(FrameBlendingConstraints.framesAfterDefault),
        wrapAroundAfter = ValueNotifier<bool>(FrameBlendingConstraints.wrapAfterDefault),
        opacity = ValueNotifier<double>(FrameBlendingConstraints.opacityDefault),
        gradualOpacity = ValueNotifier<bool>(FrameBlendingConstraints.gradualOpacityDefault),
        tinting = ValueNotifier<bool>(FrameBlendingConstraints.tintingDefault),
        activeLayerOnly = ValueNotifier<bool>(FrameBlendingConstraints.activeLayerOnlyDefault);
}
