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
import 'package:flutter/scheduler.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';

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



enum LayerMenuKind
{
  drawing,
  raster,
  reference
}

abstract class LayerState
{
  bool _disposed = false;

  /// Whether [dispose] has already run.
  ///
  /// Rasterization is asynchronous, so a raster started before disposal can still
  /// complete afterwards; anything that would write back into the layer has to
  /// check this first and drop the result instead.
  bool get isDisposed
  {
    return _disposed;
  }

  /// Marks this layer disposed. Call from [dispose] before releasing anything.
  @protected
  void markDisposed()
  {
    _disposed = true;
  }

  /// Releases [images] once the current frame has been drawn.
  ///
  /// Duplicates are dropped first: the same handle is stored as the raster, as the
  /// thumbnail and inside the per frame map, and releasing one twice trips an
  /// assertion in dart:ui.
  ///
  /// The release is deferred because widgets built during this frame may still
  /// hold the handle, and cloning an already released image throws. Clear the
  /// notifiers pointing at these images before calling this.
  @protected
  void disposeImages({required final Iterable<ui.Image?> images})
  {
    final Set<ui.Image> unique = <ui.Image>{};
    for (final ui.Image? image in images)
    {
      if (image != null)
      {
        unique.add(image);
      }
    }
    if (unique.isEmpty)
    {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((final Duration _)
    {
      for (final ui.Image image in unique)
      {
        image.dispose();
      }
    });
    //disposal can be triggered from a microtask, where no frame is pending and the
    //callback would otherwise sit until something else asks for one
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Releases everything this layer holds that the garbage collector cannot.
  ///
  /// Layers start periodic timers and register listeners, both of which keep the
  /// layer reachable for the rest of the session, and hold `ui.Image` handles that
  /// need to be released explicitly. Call this once a layer is no longer part of
  /// any frame; using the layer afterwards is not supported.
  void dispose();

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
