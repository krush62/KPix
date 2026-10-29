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
import 'package:flutter/scheduler.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Layout options for [TouchJoystickWidget].
abstract final class _TouchJoystickOptions
{
  static const double extent = 120.0;
  static const double thickness = 56.0;
  static const double knobSize = 48.0;
  static const double borderWidth = 2.0;
  static const double iconSize = 20.0;
  static const double deadZone = 0.15;
  static const int baseAlpha = 96;
  static const int baseActiveAlpha = 160;
  static const int knobAlpha = 200;
  static const double paddingPlusMinus = 8.0;
}

/// The directions a [TouchJoystickWidget] can be deflected in.
enum JoystickAxis
{
  vertical,
  free,
}

typedef JoystickTickFn = void Function({required Offset deflection, required double seconds});

/// An on-screen stick that reports its deflection once per frame while it is held.
///
/// The deflection is relative to where the touch started, has a dead zone applied
/// and is normalized to a length of at most 1.
class TouchJoystickWidget extends StatefulWidget
{
  final JoystickAxis axis;
  final JoystickTickFn onTick;
  final VoidCallback? onRelease;

  const TouchJoystickWidget({
    super.key,
    required this.axis,
    required this.onTick,
    this.onRelease,
  });

  @override
  State<TouchJoystickWidget> createState() => _TouchJoystickWidgetState();
}

class _TouchJoystickWidgetState extends State<TouchJoystickWidget> with SingleTickerProviderStateMixin
{
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<Offset> _knob = ValueNotifier<Offset>(Offset.zero);
  int? _pointer;
  Offset _startPos = Offset.zero;
  Duration _lastElapsed = Duration.zero;

  Size get _size => widget.axis == JoystickAxis.vertical
      ? const Size(_TouchJoystickOptions.thickness, _TouchJoystickOptions.extent)
      : const Size(_TouchJoystickOptions.extent, _TouchJoystickOptions.extent);

  double get _travel => (_TouchJoystickOptions.extent - _TouchJoystickOptions.knobSize) / 2;

  @override
  void dispose()
  {
    _ticker.dispose();
    _knob.dispose();
    super.dispose();
  }

  void _down({required final PointerDownEvent event})
  {
    if (_pointer != null)
    {
      return;
    }
    _pointer = event.pointer;
    _startPos = event.localPosition;
    _knob.value = Offset.zero;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _move({required final PointerMoveEvent event})
  {
    if (event.pointer != _pointer)
    {
      return;
    }
    Offset delta = event.localPosition - _startPos;
    if (widget.axis == JoystickAxis.vertical)
    {
      delta = Offset(0.0, delta.dy);
    }
    if (delta.distance > _travel)
    {
      delta = delta / delta.distance * _travel;
    }
    _knob.value = delta / _travel;
  }

  void _up({required final PointerEvent event})
  {
    if (event.pointer != _pointer)
    {
      return;
    }
    _pointer = null;
    _ticker.stop();
    _knob.value = Offset.zero;
    widget.onRelease?.call();
  }

  void _tick(final Duration elapsed)
  {
    final double seconds = (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    final double length = _knob.value.distance;
    if (seconds <= 0.0 || length < _TouchJoystickOptions.deadZone)
    {
      return;
    }
    final Offset deflection = _knob.value / length * ((length - _TouchJoystickOptions.deadZone) / (1.0 - _TouchJoystickOptions.deadZone));
    widget.onTick(deflection: deflection, seconds: seconds);
  }

  @override
  Widget build(final BuildContext context)
  {
    final ThemeData theme = Theme.of(context);
    final Size size = _size;
    final bool isVertical = widget.axis == JoystickAxis.vertical;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (final PointerDownEvent event) {_down(event: event);},
      onPointerMove: (final PointerMoveEvent event) {_move(event: event);},
      onPointerUp: (final PointerUpEvent event) {_up(event: event);},
      onPointerCancel: (final PointerCancelEvent event) {_up(event: event);},
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _knob,
          builder: (final BuildContext context, final Offset knob, final Widget? child)
          {
            final bool isActive = _pointer != null;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(isActive ? _TouchJoystickOptions.baseActiveAlpha : _TouchJoystickOptions.baseAlpha),
                      border: Border.all(color: theme.primaryColorLight.withAlpha(_TouchJoystickOptions.baseAlpha), width: _TouchJoystickOptions.borderWidth),
                      borderRadius: BorderRadius.circular(size.shortestSide / 2),
                    ),
                  ),
                ),
                if (isVertical) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: _TouchJoystickOptions.paddingPlusMinus),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Icon(TablerIcons.plus, size: _TouchJoystickOptions.iconSize, color: theme.primaryColorLight),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: _TouchJoystickOptions.paddingPlusMinus),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(TablerIcons.minus, size: _TouchJoystickOptions.iconSize, color: theme.primaryColorLight),
                    ),
                  ),
                ],
                Positioned(
                  left: (size.width - _TouchJoystickOptions.knobSize) / 2 + knob.dx * _travel,
                  top: (size.height - _TouchJoystickOptions.knobSize) / 2 + knob.dy * _travel,
                  width: _TouchJoystickOptions.knobSize,
                  height: _TouchJoystickOptions.knobSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.primaryColorLight.withAlpha(_TouchJoystickOptions.knobAlpha),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVertical ? TablerIcons.zoom : TablerIcons.arrows_move,
                      size: _TouchJoystickOptions.iconSize,
                      color: theme.primaryColorDark,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
