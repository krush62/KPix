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

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/canvas/canvas_controller.dart';
import 'package:kpix/widgets/canvas/selection_bar_widget.dart';
import 'package:kpix/widgets/canvas/touch_joystick_widget.dart';

/// Layout options for [CanvasWidget].
abstract final class _CanvasOptions
{
  static const int opacityDuration = 150;
  static const int selectionPulseDuration = 1500;
  static const double selectionPulseMinFactor = 0.5;
  static const double joystickPadding = 16.0;
}

/// Main Canvas widget for all drawing/displaying purposes.
///
/// It shows the [CanvasController]'s painter and forwards all input to it.
class CanvasWidget extends StatefulWidget {
  const CanvasWidget(
      {
        super.key,
      });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> with TickerProviderStateMixin
{
  final TouchPreferenceContent _touchPrefs = GetIt.I.get<PreferenceManager>().touchPreferenceContent;
  final GuiPreferenceContent _guiPrefs = GetIt.I.get<PreferenceManager>().guiPreferenceContent;
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final ValueNotifier<double> _selectionPulse = ValueNotifier<double>(1.0);
  late final CanvasController _controller;

  late AnimationController _selectionBarAnimationController;
  late Animation<double> _selectionBarAnimation;
  late AnimationController _selectionPulseController;

  late final List<Listenable> _pulseTriggers = <Listenable>[
    _guiPrefs.selectionPulsatingOutline,
    _guiPrefs.selectionOpacity,
    _documentState.selectionState.selection.isEmptyNotifer,
    _documentState.timeline.isPlaying,
    _documentState.timeline.layerChangeNotifier,
    _documentState.timeline.selectedFrameIndexNotifier,
  ];

  @override
  void initState()
  {
    super.initState();
    _controller = CanvasController(selectionPulse: _selectionPulse);

    _selectionBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _CanvasOptions.opacityDuration),
    );
    _selectionBarAnimation = CurvedAnimation(
      parent: _selectionBarAnimationController,
      curve: Curves.easeInOut,
    );

    _selectionPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _CanvasOptions.selectionPulseDuration),
    )..addListener(_selectionPulseTick);
    for (final Listenable trigger in _pulseTriggers)
    {
      trigger.addListener(_updateSelectionPulse);
    }
    _updateSelectionPulse();
  }

  @override
  void dispose()
  {
    _controller.dispose();
    for (final Listenable trigger in _pulseTriggers)
    {
      trigger.removeListener(_updateSelectionPulse);
    }
    _selectionBarAnimationController.dispose();
    _selectionPulseController.dispose();
    _selectionPulse.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies()
  {
    super.didChangeDependencies();
    _controller.painter.setCursorInfoTheme(theme: Theme.of(context));
  }

  void _selectionPulseTick()
  {
    final double wave = (1.0 - cos(2 * pi * _selectionPulseController.value)) / 2.0;
    _selectionPulse.value = _CanvasOptions.selectionPulseMinFactor +
        ((1.0 - _CanvasOptions.selectionPulseMinFactor) * wave);
  }

  void _updateSelectionPulse()
  {
    final bool shouldPulse = _guiPrefs.selectionPulsatingOutline.value &&
        _guiPrefs.selectionOpacity.value > 0 &&
        !_documentState.selectionState.selection.isEmpty &&
        !_documentState.timeline.isPlaying.value &&
        _documentState.timeline.getCurrentLayer() is DrawingLayerState;

    if (shouldPulse)
    {
      if (!_selectionPulseController.isAnimating)
      {
        _selectionPulseController.repeat();
      }
    }
    else
    {
      if (_selectionPulseController.isAnimating)
      {
        _selectionPulseController.stop();
      }
      if (_selectionPulse.value != 1.0)
      {
        _selectionPulse.value = 1.0;
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Stack(
      children: <Widget>[
        ValueListenableBuilder<MouseCursor>(
          valueListenable: _controller.mouseCursor,
          builder: (final BuildContext context, final MouseCursor cursor, final Widget? child)
          {
            return MouseRegion(
              onExit: (final PointerExitEvent _) {_controller.mouseExit();},
              cursor: cursor,
              child: child,
            );
          },
          child: Listener(
            onPointerDown: (final PointerDownEvent pde) {_controller.pointerDown(details: pde);},
            onPointerMove: (final PointerEvent pe) {_controller.pointerMove(details: pe);},
            onPointerUp: (final PointerEvent pe) {_controller.pointerUp(details: pe);},
            onPointerCancel: (final PointerCancelEvent pce) {_controller.pointerCancel(details: pce);},
            onPointerHover: (final PointerHoverEvent phe) {_controller.pointerHover(details: phe);},
            onPointerSignal: (final PointerSignalEvent pse) {_controller.pointerSignal(ev: pse);},
            onPointerPanZoomEnd: (final PointerPanZoomEndEvent _) {_controller.panZoomEnd();},
            onPointerPanZoomUpdate: (final PointerPanZoomUpdateEvent event) {_controller.panZoomUpdate(event: event);},
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Theme.of(context).primaryColorDark,
              child: LayoutBuilder(
                builder: (final BuildContext context, final BoxConstraints constraints)
                {
                  _controller.viewportSizeChanged(size: constraints.biggest);
                  return RepaintBoundary(
                    child: CustomPaint(
                      willChange: true,
                      painter: _controller.painter,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        //the joysticks end where the selection bar begins, so the bar never covers them
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _touchPrefs.showJoysticks,
                builder: (final BuildContext context, final bool showJoysticks, final Widget? child)
                {
                  if (!showJoysticks)
                  {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        left: _CanvasOptions.joystickPadding,
                        bottom: _CanvasOptions.joystickPadding,
                        child: TouchJoystickWidget(
                          axis: JoystickAxis.vertical,
                          onTick: _controller.viewport.joystickZoom,
                          onRelease: _controller.viewport.joystickZoomRelease,
                        ),
                      ),
                      Positioned(
                        right: _CanvasOptions.joystickPadding,
                        bottom: _CanvasOptions.joystickPadding,
                        child: TouchJoystickWidget(
                          axis: JoystickAxis.free,
                          onTick: _controller.viewport.joystickPan,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[GetIt.I.get<ToolState>().selectedToolNotifier, _documentState.selectionState.selection.isEmptyNotifer]),
              builder: (final BuildContext context, final Widget? child) {
                final bool shouldShow = GetIt.I.get<ToolState>().selectedToolNotifier.value == ToolType.select || !_documentState.selectionState.selection.isEmptyNotifer.value;
                if (shouldShow)
                {
                  _selectionBarAnimationController.forward();
                }
                else
                {
                  _selectionBarAnimationController.reverse();
                }
                return IgnorePointer(
                  ignoring: !shouldShow,
                  child: child,
                );
              },
              child: SizeTransition(
                sizeFactor: _selectionBarAnimation,
                child: const SelectionBarWidget(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
