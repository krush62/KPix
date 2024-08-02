import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/selection_bar_widget.dart';


class CanvasOptions
{
  final int stylusPollRate;
  final int historyCHeckPollRate;
  final int longPressDuration;
  final double longPressCancelDistance;
  final double stylusZoomStepDistance;
  final double stylusToolSizeDistance;
  final double touchZoomStepDistance;
  final double minVisibilityFactor;
  final int singleTouchDelay;
  final int idleTimerRate;

  CanvasOptions({
    required this.stylusPollRate,
    required this.historyCHeckPollRate,
    required this.longPressDuration,
    required this.longPressCancelDistance,
    required this.stylusZoomStepDistance,
    required this.stylusToolSizeDistance,
    required this.minVisibilityFactor,
    required this.singleTouchDelay,
    required this.idleTimerRate,
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
  final ValueNotifier<bool> _stylusLongMoveStarted = ValueNotifier(false);
  final ValueNotifier<bool> _stylusLongMoveVertical = ValueNotifier(false);
  final ValueNotifier<bool> _stylusLongMoveHorizontal = ValueNotifier(false);
  bool _timerRunning = false;
  late Duration _timeoutLongPress;
  late final double _maxLongPressDistance;
  late Timer _timerLongPress;
  final  ValueNotifier<Offset> _pressStartLoc = ValueNotifier(const Offset(0,0));
  late Offset _secondaryStartLoc;
  bool _needSecondaryStartLoc = false;
  final ValueNotifier<bool> _primaryIsDown = ValueNotifier(false);
  final ValueNotifier<bool> _secondaryIsDown = ValueNotifier(false);
  int _stylusZoomStartLevel = 100;
  int _stylusToolStartSize = 1;


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
  int _touchZoomStartLevel = 1;

  late Timer _idleTimer;
  bool _idleTimerInitialized = false;

  late KPixPainter kPixPainter = KPixPainter(
    appState: appState,
    offset: _canvasOffset,
    checkerboardColor1: Theme.of(context).primaryColor,
    checkerboardColor2: Theme.of(context).primaryColorLight,
    coords: _cursorPos,
    isDragging: _isDragging,
    stylusLongMoveStarted: _stylusLongMoveStarted,
    stylusLongMoveVertical: _stylusLongMoveVertical,
    stylusLongMoveHorizontal: _stylusLongMoveHorizontal,
    primaryDown: _primaryIsDown,
    secondaryDown: _secondaryIsDown,
    primaryPressStart: _pressStartLoc,
  );

  late ToolType _previousTool;

  @override
  void initState()
  {
    super.initState();
    Timer.periodic(Duration(milliseconds: options.stylusPollRate), _stylusBtnTimeout);
    Timer.periodic(Duration(milliseconds: options.historyCHeckPollRate), _checkHistoryData);
    _timeoutLongPress = Duration(milliseconds: options.longPressDuration);
    _maxLongPressDistance = options.longPressCancelDistance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int bestZoomLevel = AppState.zoomLevelMin;
      for (int i = AppState.zoomLevelMin; i <= AppState.zoomLevelMax; i++)
      {
        if (appState.canvasSize.x * i < kPixPainter.latestSize.width && appState.canvasSize.y * i < kPixPainter.latestSize.height)
        {
          bestZoomLevel = i;
        }
        else
        {
          break;
        }
      }
      appState.setZoomLevel(bestZoomLevel);
      _setOffset(Offset((kPixPainter.latestSize.width - (appState.canvasSize.x * appState.zoomFactor.value)) / 2, (kPixPainter.latestSize.height - (appState.canvasSize.y * appState.zoomFactor.value)) / 2));
    });
  }

  void _checkHistoryData(final Timer _)
  {
    if (kPixPainter.toolPainter != null && kPixPainter.toolPainter!.hasHistoryData)
    {
      String description = "drawing";
      if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.pencil])
      {
        description = "pencil drawing";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.shape])
      {
        description = "shape drawing";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.stamp])
      {
        description = "stamp drawing";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.line])
      {
        description = "line drawing";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.spraycan])
      {
        description = "spray can drawing";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.font])
      {
        description = "font drawing";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.erase])
      {
        description = "erase";
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.fill])
      {
        description = "fill";
      }
      GetIt.I.get<HistoryManager>().addState(appState: appState, description: description);
      kPixPainter.toolPainter!.hasHistoryData = false;
    }

  }


  void handleTimeoutLongPress()
  {
    _timerRunning = false;
    //print("LONG PRESS PRIMARY");
  }

  void _buttonDown(PointerDownEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers[details.pointer] = TouchPointerStatus(startPos: details.localPosition, currentPos: details.localPosition);
      if (_touchPointers.length == 1)
      {
        Timer(Duration(milliseconds: options.singleTouchDelay), checkTouchDraw);
      }
      else if (_touchPointers.length == 2)
      {
        _dragStartLoc = Offset((_touchPointers.values.elementAt(0).currentPos.dx + _touchPointers.values.elementAt(1).currentPos.dx) / 2, (_touchPointers.values.elementAt(0).currentPos.dy + _touchPointers.values.elementAt(1).currentPos.dy) / 2);
        _isDragging.value = true;
        _initialTouchZoomDistance = (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
        _touchZoomStartLevel = appState.zoomFactor.value;
        setMouseCursor(SystemMouseCursors.move);
      }
    }


    if (details.buttons == kPrimaryButton && _touchPointers.isEmpty)
    {
      _startDown(details.localPosition);
      if (appState.getSelectedTool() == ToolType.spraycan)
      {
        _idleTimer = Timer.periodic(Duration(milliseconds: options.idleTimerRate), _idleTimeout);
        _idleTimerInitialized = true;
      }
    }
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = true;
      _previousTool = appState.getSelectedTool();
      appState.setToolSelection(tool: ToolType.pick);
    }
    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _dragStartLoc = details.localPosition;
      _isDragging.value = true;
      setMouseCursor(SystemMouseCursors.move);
    }

    _updateLocation(details);
  }

  void _idleTimeout(final Timer _)
  {
    appState.repaintNotifier.repaint();
  }

  void _startDown(final Offset position)
  {
    _pressStartLoc.value = position;
    _primaryIsDown.value = true;
    if (!_timerRunning) {
      _timerRunning = true;
      _timerLongPress = Timer(_timeoutLongPress, handleTimeoutLongPress);
    }

    //deselect if outside is clicked
    if (_pressStartLoc.value.dx < _canvasOffset.value.dx || _pressStartLoc.value.dx > _canvasOffset.value.dx + (appState.canvasSize.x * appState.zoomFactor.value) ||
        _pressStartLoc.value.dy < _canvasOffset.value.dy || _pressStartLoc.value.dy > _canvasOffset.value.dy + (appState.canvasSize.y * appState.zoomFactor.value))
    {
      appState.selectionState.deselect(addToHistoryStack: true);
    }

    //print("PRIMARY DOWN");
  }

  void checkTouchDraw()
  {
    if (_touchPointers.length == 1)
    {
      _startDown(_touchPointers.values.toList().first.startPos);
    }
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
      //print("PRIMARY UP");
      _timerLongPress.cancel();
      _primaryIsDown.value = false;
      if (_idleTimerInitialized)
      {
        _idleTimer.cancel();
      }
    }
    else if (_secondaryIsDown.value && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = false;
      final ColorPickPainter colorPickPainter = kPixPainter.toolPainterMap[ToolType.pick] as ColorPickPainter;
      appState.colorSelected(colorPickPainter.selectedColor!);
      appState.setToolSelection(tool: _previousTool);
    }
    else if (_isDragging.value && details.kind == PointerDeviceKind.mouse)
    {
      _isDragging.value = false;
      setMouseCursor(SystemMouseCursors.none);
    }
    _timerRunning = false;

    if (appState.getSelectedTool() == ToolType.select)
    {
      if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.select])
      {
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select] as SelectionPainter;
        if (selectionPainter.hasNewSelection)
        {
          selectionPainter.hasNewSelection = false;
          if (selectionPainter.options.shape.value == SelectShape.ellipse || selectionPainter.options.shape.value == SelectShape.rectangle) {
            appState.selectionState.newSelectionFromShape(
                start: selectionPainter.selectionStart,
                end: selectionPainter.selectionEnd,
                selectShape: selectionPainter.options.shape.value);
          }
          else if (selectionPainter.options.shape.value == SelectShape.wand)
          {
            appState.selectionState.newSelectionFromWand(
                coord: selectionPainter.selectionEnd,
                mode: selectionPainter.options.mode.value,
                selectFromWholeRamp: selectionPainter.options.wandWholeRamp.value,
                continuous: selectionPainter.options.wandContinuous.value);
          }
          else //if polygon selection
          {
            selectionPainter.polygonPoints.clear();
          }
        }
      }
    }
    _updateLocation(details);
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

    if (kPixPainter.toolPainter != null)
    {
      appState.statusBarState.updateFromPaint(kPixPainter.toolPainter!.statusBarData);

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

    if (_stylusLongMoveStarted.value)
    {
      final Offset cursorPositionBeforeZoom = (cursorOffset - _canvasOffset.value) / appState.zoomFactor.value.toDouble();
      double yOffset = _secondaryStartLoc.dy - _cursorPos.value!.y;
      double xOffset = _secondaryStartLoc.dx - _cursorPos.value!.x;
      int zoomSteps = (yOffset / options.stylusZoomStepDistance).round();
      final int toolSizeSteps = (xOffset / options.stylusToolSizeDistance).round();
      if (!_stylusLongMoveVertical.value && !_stylusLongMoveHorizontal.value)
      {
        if (zoomSteps != 0)
        {
          _stylusLongMoveVertical.value = true;
        }
        else if (toolSizeSteps != 0)
        {
          _stylusLongMoveHorizontal.value = true;
        }
      }


      if (_stylusLongMoveHorizontal.value)
      {
        appState.setToolSize(-toolSizeSteps, _stylusToolStartSize);
      }

      if (_stylusLongMoveVertical.value && appState.setZoomLevelByDistance(_stylusZoomStartLevel, zoomSteps))
      {
        _setOffset(cursorOffset - (cursorPositionBeforeZoom * appState.zoomFactor.value.toDouble()));
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
      _setOffset(_canvasOffset.value - (_dragStartLoc - cursorOffset));
      _dragStartLoc = cursorOffset;

      if (details.kind == PointerDeviceKind.touch && _touchPointers.length == 2)
      {
        final double currentDistance = (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
        final int zoomSteps = ((currentDistance - _initialTouchZoomDistance) / options.touchZoomStepDistance).round();
        final Offset cursorPositionBeforeZoom = (cursorOffset - _canvasOffset.value) / appState.zoomFactor.value.toDouble();
        if (appState.setZoomLevelByDistance(_touchZoomStartLevel, zoomSteps))
        {
          _setOffset(cursorOffset - (cursorPositionBeforeZoom * appState.zoomFactor.value.toDouble()));
        }
      }
    }

    _checkSelectedToolData();
    appState.repaintNotifier.repaint();
  }

  void _checkSelectedToolData()
  {
    if (appState.getSelectedTool() == ToolType.select)
    {
      if (kPixPainter.toolPainterMap[ToolType.select] != null && kPixPainter.toolPainterMap[ToolType.select].runtimeType == SelectionPainter)
      {
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select] as SelectionPainter;
        if (selectionPainter.hasNewSelection && selectionPainter.options.shape.value == SelectShape.polygon)
        {
          selectionPainter.hasNewSelection = false;
          final CoordinateSetI min = Helper.getMin(selectionPainter.polygonPoints);
          final CoordinateSetI max = Helper.getMax(selectionPainter.polygonPoints);
          Set<CoordinateSetI> selection = {};
          for (int x = min.x; x < max.x; x++)
          {
            for (int y = min.y; y < max.y; y++)
            {
              final CoordinateSetI checkPoint = CoordinateSetI(x: x, y: y);
              if (Helper.isPointInPolygon(checkPoint, selectionPainter.polygonPoints))
              {
                selection.add(checkPoint);
              }
            }
          }
          appState.selectionState.newSelectionFromPolygon(points: selection);
          selectionPainter.polygonPoints.clear();
          selectionPainter.polygonDown = false;
        }
      }
    }
    else if (appState.getSelectedTool() == ToolType.pick)
    {
      if (kPixPainter.toolPainterMap[ToolType.pick] != null && kPixPainter.toolPainterMap[ToolType.pick].runtimeType == ColorPickPainter)
      {
        final ColorPickPainter colorPickPainter = kPixPainter.toolPainterMap[ToolType.pick] as ColorPickPainter;
        if (colorPickPainter.selectedColor != null)
        {
          appState.colorSelected(colorPickPainter.selectedColor!);
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
      final Offset cursorPositionBeforeZoom = (ev.localPosition - _canvasOffset.value) / appState.zoomFactor.value.toDouble();

      if (ev.scrollDelta.dy < 0.0 && appState.increaseZoomLevel())
      {
        _setOffset(ev.localPosition - (cursorPositionBeforeZoom * appState.zoomFactor.value.toDouble()));
      }
      else if (ev.scrollDelta.dy > 0.0 && appState.decreaseZoomLevel())
      {
        _setOffset(ev.localPosition - (cursorPositionBeforeZoom * appState.zoomFactor.value.toDouble()));
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
      _stylusLongMoveStarted.value = false;
      _stylusLongMoveVertical.value = false;
      _stylusLongMoveHorizontal.value = false;
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
    //print("SECONDARY DOWN");
  }

  void stylusBtnUp()
  {
    //print("SECONDARY UP");
  }

  void handleTimeoutStylusBtnLongPress()
  {
    //print("STYLUS BTN LONG PRESS");
    _timerStylusRunning = false;
    _stylusLongMoveStarted.value = true;
    _stylusZoomStartLevel = appState.zoomFactor.value;
    _stylusToolStartSize = appState.getCurrentToolSize();
  }

  void setMouseCursor(final MouseCursor cursor)
  {
    _mouseCursor.value = cursor;
  }

  void _setOffset(final Offset newOffset)
  {
    final CoordinateSetD coords = CoordinateSetD(x: newOffset.dx, y: newOffset.dy);
    final CoordinateSetD scaledCanvas = CoordinateSetD(x: appState.canvasSize.x.toDouble() * appState.zoomFactor.value, y: appState.canvasSize.y.toDouble() * appState.zoomFactor.value);
    final CoordinateSetD minVisibility = CoordinateSetD(x: kPixPainter.latestSize.width * options.minVisibilityFactor, y: kPixPainter.latestSize.height * options.minVisibilityFactor);

    coords.x = max(coords.x, -scaledCanvas.x + minVisibility.x);
    coords.y = max(coords.y, -scaledCanvas.y + minVisibility.y);
    coords.x = min(coords.x, kPixPainter.latestSize.width - minVisibility.x);
    coords.y = min(coords.y, kPixPainter.latestSize.height - minVisibility.y);


    _canvasOffset.value = Offset(coords.x, coords.y);
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
                valueListenable: GetIt.I.get<AppState>().getSelectedToolNotifier(),
                builder: (BuildContext context, ToolType toolType, child)
                {
                  return IgnorePointer(
                    ignoring: toolType != ToolType.select,
                    child: AnimatedScale(
                      duration: Duration(milliseconds: GetIt.I.get<PreferenceManager>().selectionBarWidgetOptions.opacityDuration),
                      scale: toolType == ToolType.select ? 1.0 : 0.0,
                      alignment: Alignment.bottomCenter,
                      //opacity: toolType == ToolType.select ? 1.0 : 0.0,
                      child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: SelectionBarWidget()
                      ),
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