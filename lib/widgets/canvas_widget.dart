import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/selection_bar_widget.dart';


class CanvasOptions
{
  final int stylusPollRate;
  final int longPressDuration;
  final double longPressCancelDistance;
  final double stylusZoomStepDistance;
  final double touchZoomStepDistance;

  CanvasOptions({
    required this.stylusPollRate,
    required this.longPressDuration,
    required this.longPressCancelDistance,
    required this.stylusZoomStepDistance,
    required this.touchZoomStepDistance});
}

class TouchPointerStatus
{
  final Offset startPos;
  Offset currentPos;
  TouchPointerStatus({required this.startPos, required this.currentPos});
}



class CanvasWidget extends StatefulWidget {
  const CanvasWidget(
      {
        super.key
      });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  CanvasOptions options = GetIt.I.get<PreferenceManager>().canvasWidgetOptions;
  AppState appState = GetIt.I.get<AppState>();
  final ValueNotifier<CoordinateSetD?> _cursorPos = ValueNotifier(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  bool _timerRunning = false;
  late Duration _timeoutLongPress;
  late final double _maxLongPressDistance;
  late Timer _timerLongPress;
  final  ValueNotifier<Offset> _pressStartLoc = ValueNotifier(const Offset(0,0));
  late Offset _secondaryStartLoc;
  bool _needSecondaryStartLoc = false;
  final ValueNotifier<bool> _primaryIsDown = ValueNotifier(false);
  bool _secondaryIsDown = false;
  bool _stylusZoomStarted = false;
  int _stylusZoomStartLevel = 100;

  late Timer _timerStylusBtnLongPress;
  bool _timerStylusRunning = false;
  bool _stylusButtonDetected = false;
  bool _stylusHoverDetected = false;
  bool _stylusButtonDown = false;

  late Offset _dragStartLoc;

  final ValueNotifier<Offset> _canvasOffset = ValueNotifier(const Offset(0.0, 0.0));

  final ValueNotifier<MouseCursor> _mouseCursor = ValueNotifier(SystemMouseCursors.none);
  bool _mouseIsInside = false;
  final Map<int, TouchPointerStatus> _touchPointers = {};
  double _initialTouchZoomDistance = 0.0;
  int _touchZoomStartLevel = 100;
  late KPixPainter kPixPainter = KPixPainter(
    appState: appState,
    offset: _canvasOffset,
    checkerboardColor1: Theme.of(context).primaryColor,
    checkerboardColor2: Theme.of(context).primaryColorLight,
    coords: _cursorPos,
    isDragging: _isDragging,
    primaryDown: _primaryIsDown,
    primaryPressStart: _pressStartLoc,
  );

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: options.stylusPollRate), _stylusBtnTimeout);
    _timeoutLongPress = Duration(milliseconds: options.longPressDuration);
    _maxLongPressDistance = options.longPressCancelDistance;

  }


  void handleTimeoutLongPress() {
    _timerRunning = false;
    print("LONG PRESS PRIMARY");
  }

  void _buttonDown(PointerDownEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers[details.pointer] = TouchPointerStatus(startPos: details.localPosition, currentPos: details.localPosition);
      if (_touchPointers.length == 2)
      {
        _dragStartLoc = Offset((_touchPointers.values.elementAt(0).currentPos.dx + _touchPointers.values.elementAt(1).currentPos.dx) / 2, (_touchPointers.values.elementAt(0).currentPos.dy + _touchPointers.values.elementAt(1).currentPos.dy) / 2);
        _isDragging.value = true;
        _initialTouchZoomDistance = (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
        _touchZoomStartLevel = appState.getZoomLevel();
        setMouseCursor(SystemMouseCursors.move);
      }
    }


    if (details.buttons == kPrimaryButton && _touchPointers.length < 2)
    {
      _pressStartLoc.value = details.localPosition;
      _primaryIsDown.value = true;
      if (!_timerRunning) {
        _timerRunning = true;
        _timerLongPress = Timer(_timeoutLongPress, handleTimeoutLongPress);
      }

      //deselect if outside is clicked
      if (_pressStartLoc.value.dx < _canvasOffset.value.dx || _pressStartLoc.value.dx > _canvasOffset.value.dx + (appState.canvasWidth * appState.getZoomFactor()) ||
          _pressStartLoc.value.dy < _canvasOffset.value.dy || _pressStartLoc.value.dy > _canvasOffset.value.dy + (appState.canvasHeight * appState.getZoomFactor()))
      {
        appState.selectionState.deselect();
      }

      print("PRIMARY DOWN");
    }
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
      //NOT USED ATM
      _secondaryIsDown = true;
    }
    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _dragStartLoc = details.localPosition;
      _isDragging.value = true;
      setMouseCursor(SystemMouseCursors.move);
    }

    _updateLocation(details);
  }

  void _buttonUp(PointerEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers.clear();
      _isDragging.value = false;
    }

    if (_primaryIsDown.value)
    {
      print("PRIMARY UP");
      appState.hideStatusBarToolDimension();
      appState.hideStatusBarToolDiagonal();
      appState.hideStatusBarToolAngle();
      appState.hideStatusBarToolAspectRatio();
      _timerLongPress.cancel();
      _primaryIsDown.value = false;
    }
    else if (_secondaryIsDown && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown = false;
    }
    else if (_isDragging.value && details.kind == PointerDeviceKind.mouse)
    {
      _isDragging.value = false;
      setMouseCursor(SystemMouseCursors.none);
    }
    _timerRunning = false;

    if (appState.selectedTool.value == ToolType.select)
    {
      if (kPixPainter.toolPainterMap[ToolType.select] != null && kPixPainter.toolPainterMap[ToolType.select].runtimeType == SelectionPainter)
      {
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select] as SelectionPainter;
        if (selectionPainter.hasNewSelection)
        {
          selectionPainter.hasNewSelection = false;
          appState.selectionState.newSelection(start: selectionPainter.selectionStart, end: selectionPainter.selectionEnd, selectShape: selectionPainter.options.shape);
        }
      }


    }
  }



  void _updateLocation(PointerEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers[details.pointer]?.currentPos = details.localPosition;
    }

    if (details.kind == PointerDeviceKind.touch && _touchPointers.length == 2)
    {
      _cursorPos.value = CoordinateSetD(x: (_touchPointers.values.elementAt(0).currentPos.dx + _touchPointers.values.elementAt(1).currentPos.dx) / 2, y: (_touchPointers.values.elementAt(0).currentPos.dy + _touchPointers.values.elementAt(1).currentPos.dy) / 2);
    }
    else
    {
      _cursorPos.value = CoordinateSetD(x: details.localPosition.dx, y: details.localPosition.dy);
    }

    appState.repaintNotifier.repaint();



    appState.setStatusBarCursorPosition(CoordinateSetI(
        x: (_cursorPos.value!.x - _canvasOffset.value.dx) ~/ appState.getZoomFactor(),
        y: (_cursorPos.value!.y - _canvasOffset.value.dy) ~/ appState.getZoomFactor()));

    //UPDATE OF STATUS BAR
    if (_primaryIsDown.value)
    {
      if (appState.selectedTool.value == ToolType.select)
      {
        if (kPixPainter.toolPainterMap[ToolType.select] != null && kPixPainter.toolPainterMap[ToolType.select].runtimeType == SelectionPainter)
        {
          final SelectionPainter selectionPainter = kPixPainter
              .toolPainterMap[ToolType.select] as SelectionPainter;
          int width = (selectionPainter.selectionStart.x - selectionPainter.selectionEnd.x).abs() + 1;
          int height = (selectionPainter.selectionStart.y - selectionPainter.selectionEnd.y).abs() + 1;

          appState.setStatusBarToolDimension(width, height);
          appState.setStatusBarToolDiagonal(width, height);
          appState.setStatusBarToolAspectRatio(width, height);
          appState.setStatusBarToolAngle(selectionPainter.selectionStart, selectionPainter.selectionEnd);
        }
      }
    }

    if (details.kind == PointerDeviceKind.mouse)
    {
      _mouseIsInside = true;
    }

    if (_needSecondaryStartLoc)
    {
      _secondaryStartLoc = details.localPosition;
      _needSecondaryStartLoc = false;
    }

    final Offset cursorOffset = Offset(_cursorPos.value!.x, _cursorPos.value!.y);

    if (_stylusZoomStarted)
    {
      final Offset cursorPositionBeforeZoom = (cursorOffset - _canvasOffset.value) / appState.getZoomFactor().toDouble();
      double yOffset = _secondaryStartLoc.dy - _cursorPos.value!.y;
      int zoomSteps = (yOffset / options.stylusZoomStepDistance).round();
      if (appState.setZoomLevelByDistance(_stylusZoomStartLevel, zoomSteps))
      {
        _canvasOffset.value = cursorOffset - (cursorPositionBeforeZoom * appState.getZoomFactor().toDouble());
      }
    }

    if (_timerRunning && (_pressStartLoc.value - cursorOffset).distance > _maxLongPressDistance)
    {
      _timerLongPress.cancel();
      _timerRunning = false;
    }
    if (_timerStylusRunning && (_secondaryStartLoc - cursorOffset).distance > _maxLongPressDistance)
    {
      _timerStylusBtnLongPress.cancel();
      _timerStylusRunning = false;
      _isDragging.value = true;
      setMouseCursor(SystemMouseCursors.move);
      _dragStartLoc = cursorOffset;
    }

    if (_isDragging.value)
    {
      _canvasOffset.value  = _canvasOffset.value - (_dragStartLoc - cursorOffset);
      _dragStartLoc = cursorOffset;

      if (details.kind == PointerDeviceKind.touch && _touchPointers.length == 2)
      {
        final double currentDistance = (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
        final int zoomSteps = ((currentDistance - _initialTouchZoomDistance) / options.touchZoomStepDistance).round();
        final Offset cursorPositionBeforeZoom = (cursorOffset - _canvasOffset.value) / appState.getZoomFactor().toDouble();
        if (appState.setZoomLevelByDistance(_touchZoomStartLevel, zoomSteps))
        {
          _canvasOffset.value = cursorOffset - (cursorPositionBeforeZoom * appState.getZoomFactor().toDouble());
        }
      }
    }

  }

  void _hover(PointerHoverEvent details)
  {
    if (details.kind == PointerDeviceKind.stylus)
    {
      if (details.buttons == kSecondaryButton && !_stylusButtonDetected)
      {
        _stylusButtonDetected = true;
      }
      _stylusHoverDetected = true;
    }
    _updateLocation(details);

  }

  void _scroll(PointerSignalEvent ev)
  {
    if (ev is PointerScrollEvent)
    {
      final Offset cursorPositionBeforeZoom = (ev.localPosition - _canvasOffset.value) / appState.getZoomFactor().toDouble();

      if (ev.scrollDelta.dy < 0.0)
      {
        if (appState.increaseZoomLevel())
        {
          _canvasOffset.value = ev.localPosition - (cursorPositionBeforeZoom * appState.getZoomFactor().toDouble());
        }
      }
      else if (ev.scrollDelta.dy > 0.0)
      {
        if (appState.decreaseZoomLevel())
        {
          _canvasOffset.value = ev.localPosition - (cursorPositionBeforeZoom * appState.getZoomFactor().toDouble());
        }
      }
    }
  }

  void _onMouseExit(PointerExitEvent _)
  {
    _cursorPos.value = null;
    appState.repaintNotifier.repaint();
    _mouseIsInside = false;
  }


  void _stylusBtnTimeout(Timer t)
  {
    if (_stylusButtonDetected && !_stylusButtonDown)
    {
      _needSecondaryStartLoc = true;
      _stylusButtonDown = true;
      stylusBtnDown();
      _timerStylusBtnLongPress = Timer(_timeoutLongPress, handleTimeoutStylusBtnLongPress);
      _timerStylusRunning = true;
    }
    else if (!_stylusButtonDetected && _stylusButtonDown)
    {
      _needSecondaryStartLoc = false;
      stylusBtnUp();
      _stylusButtonDown = false;
      _timerStylusBtnLongPress.cancel();
      _timerStylusRunning = false;
      _stylusZoomStarted = false;
      _isDragging.value = false;
      setMouseCursor(SystemMouseCursors.none);
    }
    _stylusButtonDetected = false;

    if (!_stylusHoverDetected && _cursorPos.value != null && !_mouseIsInside)
    {
      _cursorPos.value = null;
      appState.repaintNotifier.repaint();
    }
    else
    {
      _stylusHoverDetected = false;
    }
  }

  void stylusBtnDown()
  {
    print("SECONDARY DOWN");
  }

  void stylusBtnUp()
  {
    print("SECONDARY UP");
  }

  void handleTimeoutStylusBtnLongPress()
  {
    print("STYLUS BTN LONG PRESS");
    _timerStylusRunning = false;
    _stylusZoomStarted = true;
    _stylusZoomStartLevel = appState.getZoomLevel();
  }

  void setMouseCursor(final MouseCursor cursor)
  {
    _mouseCursor.value = cursor;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: _mouseCursor,
        builder: (BuildContext context, MouseCursor cursor, child)
        {
          return Stack(
            children: [
              MouseRegion(
                onExit: _onMouseExit,
                //TODO this should depend on the tool and if user is above canvas => callback function to painter
                cursor: cursor,
                child: Listener(
                  onPointerDown: _buttonDown,
                  onPointerMove: _updateLocation,
                  onPointerUp: _buttonUp,
                  onPointerHover: _hover,
                  onPointerSignal: _scroll,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Theme.of(context).primaryColorDark,
                    child: CustomPaint(
                      painter: kPixPainter
                    )
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: GetIt.I.get<AppState>().selectedTool,
                builder: (BuildContext context, ToolType toolType, child)
                {
                  return AnimatedOpacity(
                    //TODO magic number
                    duration: Duration(milliseconds: GetIt.I.get<PreferenceManager>().selectionBarWidgetOptions.opacityDuration),
                    opacity: toolType == ToolType.select ? 1.0 : 0.0,
                    child: const Align(
                        alignment: Alignment.bottomCenter,
                        child: SelectionBarWidget()
                    ),
                  );
                }
              ),
            ],
          );
        }
      ),
    );
  }
}