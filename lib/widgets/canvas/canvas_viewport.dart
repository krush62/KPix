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

import 'package:flutter/material.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

abstract final class _ViewportOptions
{
  static const double minVisibilityFactor = 0.1;
  static const int optimalZoomSettleTime = 1500;
  static const double joystickPanSpeed = 1500.0;
  static const double joystickZoomRateMin = 2.0;
  static const double joystickZoomRateMax = 12.0;
}

/// Where the canvas lies in the drawing area, and the zooming and panning that
/// move it there.
class CanvasViewport
{
  CanvasViewport({required this.viewState, required this.canvasState});

  final ViewState viewState;
  final CanvasState canvasState;

  /// The top left corner of the canvas in the drawing area.
  final ValueNotifier<Offset> offset = ValueNotifier<Offset>(Offset.zero);

  /// Size of the drawing area, taken from layout.
  ///
  /// [KPixPainter.latestSize] is only written while painting, so it is not
  /// available before the first paint and it is stale whenever the viewport has
  /// just changed. Everything that positions the canvas uses this value instead.
  Size size = Size.zero;

  /// Time of the currently pending optimal zoom request, `null` if there is none.
  DateTime? _optimalZoomRequestTime;

  /// Whether the pending optimal zoom request has been applied at least once.
  bool _optimalZoomApplied = false;

  double _joystickZoomProgress = 0.0;
  int _joystickZoomDirection = 0;

  /// Moves the canvas to [newOffset], keeping a part of it inside the drawing area.
  void setOffset({required final Offset newOffset})
  {
    final CoordinateSetD coords = CoordinateSetD(x: newOffset.dx, y: newOffset.dy);
    final CoordinateSetD scaledCanvas = CoordinateSetD(x: canvasState.canvasSize.x.toDouble() * viewState.zoomFactor / viewState.devicePixelRatio, y: canvasState.canvasSize.y.toDouble() * viewState.zoomFactor / viewState.devicePixelRatio);
    final CoordinateSetD minVisibility = CoordinateSetD(x: size.width * _ViewportOptions.minVisibilityFactor, y: size.height * _ViewportOptions.minVisibilityFactor);

    coords.x = coords.x.clamp(-scaledCanvas.x + minVisibility.x, size.width - minVisibility.x);
    coords.y = coords.y.clamp(-scaledCanvas.y + minVisibility.y, size.height - minVisibility.y);

    offset.value = Offset(coords.x, coords.y);
  }

  /// Runs [zoom] and, if it changed the zoom level, keeps the part of the canvas
  /// under [focus] where it was.
  void zoomAround({required final Offset focus, required final bool Function() zoom})
  {
    final Offset focusBeforeZoom = (focus - offset.value) / viewState.zoomFactor.toDouble();
    if (zoom())
    {
      setOffset(newOffset: focus - (focusBeforeZoom * viewState.zoomFactor.toDouble()));
    }
  }

  /// The canvas pixel at [position] in the drawing area.
  CoordinateSetI pixelAt({required final CoordinateSetD position})
  {
    final double effPixelSize = viewState.zoomFactor.toDouble() / viewState.devicePixelRatio;
    return CoordinateSetI(
      x: _closestPixel(value: position.x - offset.value.dx, pixelSize: effPixelSize),
      y: _closestPixel(value: position.y - offset.value.dy, pixelSize: effPixelSize),);
  }

  static int _closestPixel({required final double value, required final double pixelSize})
  {
    final double remainder = value % pixelSize;
    final double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }

  /// Requests the canvas to be fitted into the drawing area.
  ///
  /// The calculation needs a valid size, which does not exist before the first
  /// layout and which can still change right after a project was opened (the
  /// window is maximized on desktop startup, the system bars are hidden on
  /// mobile, ...). The request is therefore remembered and re-evaluated on every
  /// resize until it settles, see [_ViewportOptions.optimalZoomSettleTime].
  void requestOptimalZoom()
  {
    _optimalZoomRequestTime = DateTime.now();
    _optimalZoomApplied = false;
    applyOptimalZoom();
  }

  /// Performs the calculation for a pending request from [requestOptimalZoom].
  void applyOptimalZoom()
  {
    if (_optimalZoomRequestTime == null)
    {
      return;
    }

    //no usable layout yet, the request stays pending
    if (size.isEmpty || !size.isFinite)
    {
      return;
    }

    if (_optimalZoomApplied && DateTime.now().difference(_optimalZoomRequestTime!).inMilliseconds > _ViewportOptions.optimalZoomSettleTime)
    {
      _optimalZoomRequestTime = null;
      return;
    }

    int bestZoomLevel = ViewState.zoomLevelMin;
    for (int i = ViewState.zoomLevelMin; i <= ViewState.zoomLevelMax; i++)
    {
      if (canvasState.canvasSize.x * i / viewState.devicePixelRatio < size.width && canvasState.canvasSize.y * i / viewState.devicePixelRatio < size.height)
      {
        bestZoomLevel = i;
      }
      else
      {
        break;
      }
    }
    viewState.setZoomLevel(val: bestZoomLevel);
    setOffset(newOffset: Offset((size.width - (canvasState.canvasSize.x * viewState.zoomFactor / viewState.devicePixelRatio)) / 2, (size.height - (canvasState.canvasSize.y * viewState.zoomFactor / viewState.devicePixelRatio)) / 2));
    _optimalZoomApplied = true;
    viewState.repaintNotifier.repaint();
  }

  /// Stores [newSize] and tells whether a pending optimal zoom has to be
  /// evaluated again.
  bool resize({required final Size newSize})
  {
    if (newSize == size)
    {
      return false;
    }
    size = newSize;
    return _optimalZoomRequestTime != null;
  }

  /// Drops a pending optimal zoom request when the user adjusts the view manually.
  void cancelOptimalZoom()
  {
    _optimalZoomRequestTime = null;
  }

  void joystickPan({required final Offset deflection, required final double seconds})
  {
    cancelOptimalZoom();
    //squared for finer control near the center
    final double speed = deflection.distanceSquared * _ViewportOptions.joystickPanSpeed;
    setOffset(newOffset: offset.value - (deflection / deflection.distance) * speed * seconds);
  }

  void joystickZoom({required final Offset deflection, required final double seconds})
  {
    cancelOptimalZoom();
    final int direction = deflection.dy < 0.0 ? 1 : (deflection.dy > 0.0 ? -1 : 0);
    if (direction != _joystickZoomDirection)
    {
      //a fresh deflection zooms one step at once
      _joystickZoomDirection = direction;
      _joystickZoomProgress = direction.toDouble();
    }
    final double rate = _ViewportOptions.joystickZoomRateMin + (_ViewportOptions.joystickZoomRateMax - _ViewportOptions.joystickZoomRateMin) * deflection.dy.abs();
    _joystickZoomProgress += direction * rate * seconds;
    final int steps = _joystickZoomProgress.truncate();
    if (steps != 0)
    {
      _joystickZoomProgress -= steps;
      zoomAround(focus: size.center(Offset.zero), zoom: () => viewState.setZoomLevelByDistance(startZoomLevel: viewState.zoomFactor, steps: steps));
    }
  }

  void joystickZoomRelease()
  {
    _joystickZoomDirection = 0;
    _joystickZoomProgress = 0.0;
  }
}
