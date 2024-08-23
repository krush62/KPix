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

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/preferences/stylus_preferences.dart';
import 'package:kpix/preferences/touch_preferences.dart';
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
  final int historyCheckPollRate;
  final double minVisibilityFactor;
  final int idleTimerRate;

  CanvasOptions({
    required this.historyCheckPollRate,
    required this.minVisibilityFactor,
    required this.idleTimerRate});
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
  final CanvasOptions _options = GetIt.I.get<PreferenceManager>().canvasWidgetOptions;
  final StylusPreferenceContent _stylusPrefs = GetIt.I.get<PreferenceManager>().stylusPreferenceContent;
  final TouchPreferenceContent _touchPrefs = GetIt.I.get<PreferenceManager>().touchPreferenceContent;
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<CoordinateSetD?> _cursorPos = ValueNotifier(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  final ValueNotifier<bool> _stylusLongMoveStarted = ValueNotifier(false);
  final ValueNotifier<bool> _stylusLongMoveVertical = ValueNotifier(false);
  final ValueNotifier<bool> _stylusLongMoveHorizontal = ValueNotifier(false);
  bool _timerRunning = false;
  late Duration _timeoutLongPress;
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

  bool _hasNewStylusPollValue = false;

  late KPixPainter kPixPainter = KPixPainter(
    appState: _appState,
    offset: _canvasOffset,
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

    Timer.periodic(Duration(milliseconds: _stylusPrefs.stylusPollInterval.value), (final Timer t) {_stylusBtnTimeout(t: t);});
    Timer.periodic(Duration(milliseconds: _options.historyCheckPollRate), (final Timer t) {_checkHistoryData(t: t);});
    _timeoutLongPress = Duration(milliseconds: _stylusPrefs.stylusLongPressDelay.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOptimalZoom();
    });

    _stylusPrefs.stylusLongPressDelay.addListener(() {
      _timeoutLongPress = Duration(milliseconds: _stylusPrefs.stylusLongPressDelay.value);
    });
    _stylusPrefs.stylusPollInterval.addListener(() {
      _hasNewStylusPollValue = true;
    });

    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    hotkeyManager.addListener(func: _setOptimalZoom, action: HotkeyAction.panZoomOptimalZoom);
  }

  void _setOptimalZoom()
  {
    int bestZoomLevel = AppState.zoomLevelMin;
    for (int i = AppState.zoomLevelMin; i <= AppState.zoomLevelMax; i++)
    {
      if (_appState.canvasSize.x * i < kPixPainter.latestSize.width && _appState.canvasSize.y * i < kPixPainter.latestSize.height)
      {
        bestZoomLevel = i;
      }
      else
      {
        break;
      }
    }
    _appState.setZoomLevel(val: bestZoomLevel);
    _setOffset(newOffset: Offset((kPixPainter.latestSize.width - (_appState.canvasSize.x * _appState.zoomFactor)) / 2, (kPixPainter.latestSize.height - (_appState.canvasSize.y * _appState.zoomFactor)) / 2));
  }


  void _checkHistoryData({required final Timer t})
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
      GetIt.I.get<HistoryManager>().addState(appState: _appState, description: description);
      kPixPainter.toolPainter!.hasHistoryData = false;
    }

  }


  void handleTimeoutLongPress()
  {
    _timerRunning = false;
    //print("LONG PRESS PRIMARY");
  }

  void _buttonDown({required final PointerDownEvent details})
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers[details.pointer] = TouchPointerStatus(startPos: details.localPosition, currentPos: details.localPosition);
      if (_touchPointers.length == 1)
      {
        Timer(Duration(milliseconds: _touchPrefs.singleTouchDelay.value), checkTouchDraw);
      }
      else if (_touchPointers.length == 2)
      {
        _dragStartLoc = Offset((_touchPointers.values.elementAt(0).currentPos.dx + _touchPointers.values.elementAt(1).currentPos.dx) / 2, (_touchPointers.values.elementAt(0).currentPos.dy + _touchPointers.values.elementAt(1).currentPos.dy) / 2);
        _isDragging.value = true;
        _initialTouchZoomDistance = (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
        _touchZoomStartLevel = _appState.zoomFactor;
        setMouseCursor(cursor: SystemMouseCursors.move);
      }
    }


    if (details.buttons == kPrimaryButton && _touchPointers.isEmpty)
    {
      _startDown(details.localPosition);
      if (_appState.selectedTool == ToolType.spraycan)
      {
        _idleTimer = Timer.periodic(Duration(milliseconds: _options.idleTimerRate), (final Timer t) {_idleTimeout(t: t);});
        _idleTimerInitialized = true;
      }
    }
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = true;
      _previousTool = _appState.selectedTool;
      _appState.setToolSelection(tool: ToolType.pick);
    }
    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _dragStartLoc = details.localPosition;
      _isDragging.value = true;
      setMouseCursor(cursor: SystemMouseCursors.move);
    }

    _updateLocation(details: details);
  }

  void _idleTimeout({required final Timer t})
  {
    _appState.repaintNotifier.repaint();
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
    if (_pressStartLoc.value.dx < _canvasOffset.value.dx || _pressStartLoc.value.dx > _canvasOffset.value.dx + (_appState.canvasSize.x * _appState.zoomFactor) ||
        _pressStartLoc.value.dy < _canvasOffset.value.dy || _pressStartLoc.value.dy > _canvasOffset.value.dy + (_appState.canvasSize.y * _appState.zoomFactor))
    {
      _appState.selectionState.deselect(addToHistoryStack: true);
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

  void _buttonUp({required final PointerEvent details})
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
      if (colorPickPainter.selectedColor != null)
      {
        _appState.colorSelected(color: colorPickPainter.selectedColor!);
      }
      _appState.setToolSelection(tool: _previousTool);
    }
    else if (_isDragging.value && details.kind == PointerDeviceKind.mouse)
    {
      _isDragging.value = false;
      setMouseCursor(cursor: SystemMouseCursors.none);
    }
    _timerRunning = false;

    if (_appState.selectedTool == ToolType.select)
    {
      if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.select])
      {
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select] as SelectionPainter;
        if (selectionPainter.hasNewSelection)
        {
          selectionPainter.hasNewSelection = false;
          if (selectionPainter.options.shape.value == SelectShape.ellipse || selectionPainter.options.shape.value == SelectShape.rectangle) {
            _appState.selectionState.newSelectionFromShape(
                start: selectionPainter.selectionStart,
                end: selectionPainter.selectionEnd,
                selectShape: selectionPainter.options.shape.value);
          }
          else if (selectionPainter.options.shape.value == SelectShape.wand)
          {
            _appState.selectionState.newSelectionFromWand(
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
    _updateLocation(details: details);
  }


  void _updateLocation({required final PointerEvent details})
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
      _appState.statusBarState.updateFromPaint(statusBarData: kPixPainter.toolPainter!.statusBarData);

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
      final Offset cursorPositionBeforeZoom = (cursorOffset - _canvasOffset.value) / _appState.zoomFactor.toDouble();
      final double yOffset = _secondaryStartLoc.dy - _cursorPos.value!.y;
      final double xOffset = _secondaryStartLoc.dx - _cursorPos.value!.x;
      final int zoomSteps = (yOffset / _stylusPrefs.stylusZoomStepDistance.value).round();
      final int toolSizeSteps = (xOffset / _stylusPrefs.stylusSizeStepDistance.value).round();
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
        _appState.setToolSize(-toolSizeSteps, _stylusToolStartSize);
      }

      if (_stylusLongMoveVertical.value && _appState.setZoomLevelByDistance(startZoomLevel: _stylusZoomStartLevel, steps: zoomSteps))
      {
        _setOffset(newOffset: cursorOffset - (cursorPositionBeforeZoom * _appState.zoomFactor.toDouble()));
      }
    }

    if (_timerRunning && (_pressStartLoc.value - cursorOffset).distance > _stylusPrefs.stylusLongPressCancelDistance.value)
    {
      _timerLongPress.cancel();
      _timerRunning = false;
    }
    if (_timerStylusRunning && (_secondaryStartLoc - cursorOffset).distance > _stylusPrefs.stylusLongPressCancelDistance.value)
    {
      _timerStylusBtnLongPress.cancel();
      _timerStylusRunning = false;
      _isDragging.value = true;
      setMouseCursor(cursor: SystemMouseCursors.move);
      _dragStartLoc = cursorOffset;
    }

    if (_isDragging.value)
    {
      _setOffset(newOffset: _canvasOffset.value - (_dragStartLoc - cursorOffset));
      _dragStartLoc = cursorOffset;

      if (details.kind == PointerDeviceKind.touch && _touchPointers.length == 2)
      {
        final double currentDistance = (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
        final int zoomSteps = ((currentDistance - _initialTouchZoomDistance) / _touchPrefs.zoomStepDistance.value).round();
        final Offset cursorPositionBeforeZoom = (cursorOffset - _canvasOffset.value) / _appState.zoomFactor.toDouble();
        if (_appState.setZoomLevelByDistance(startZoomLevel: _touchZoomStartLevel, steps: zoomSteps))
        {
          _setOffset(newOffset: cursorOffset - (cursorPositionBeforeZoom * _appState.zoomFactor.toDouble()));
        }
      }
    }

    _checkSelectedToolData();
    _appState.repaintNotifier.repaint();
  }

  void _checkSelectedToolData()
  {
    if (_appState.selectedTool == ToolType.select)
    {
      if (kPixPainter.toolPainterMap[ToolType.select] != null && kPixPainter.toolPainterMap[ToolType.select].runtimeType == SelectionPainter)
      {
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select] as SelectionPainter;
        if (selectionPainter.hasNewSelection && selectionPainter.options.shape.value == SelectShape.polygon)
        {
          selectionPainter.hasNewSelection = false;
          final CoordinateSetI min = Helper.getMin(coordList: selectionPainter.polygonPoints);
          final CoordinateSetI max = Helper.getMax(coordList: selectionPainter.polygonPoints);
          Set<CoordinateSetI> selection = {};
          for (int x = min.x; x < max.x; x++)
          {
            for (int y = min.y; y < max.y; y++)
            {
              final CoordinateSetI checkPoint = CoordinateSetI(x: x, y: y);
              if (Helper.isPointInPolygon(point: checkPoint, polygon: selectionPainter.polygonPoints))
              {
                selection.add(checkPoint);
              }
            }
          }
          _appState.selectionState.newSelectionFromPolygon(points: selection);
          selectionPainter.polygonPoints.clear();
          selectionPainter.polygonDown = false;
        }
      }
    }
    else if (_appState.selectedTool == ToolType.pick)
    {
      if (kPixPainter.toolPainterMap[ToolType.pick] != null && kPixPainter.toolPainterMap[ToolType.pick].runtimeType == ColorPickPainter)
      {
        final ColorPickPainter colorPickPainter = kPixPainter.toolPainterMap[ToolType.pick] as ColorPickPainter;
        if (colorPickPainter.selectedColor != null)
        {
          _appState.colorSelected(color: colorPickPainter.selectedColor!);
        }
      }
    }
  }

  void _hover({required final PointerHoverEvent details})
  {
    if (details.kind == PointerDeviceKind.stylus)
    {
      if (details.buttons == kSecondaryButton && !_stylusButtonDetected)
      {
        _stylusButtonDetected = true;
      }
      _stylusHoverDetected = true;
    }
    _updateLocation(details: details);

  }

  void _scroll({required final PointerSignalEvent ev})
  {
    if (ev is PointerScrollEvent)
    {
      final Offset cursorPositionBeforeZoom = (ev.localPosition - _canvasOffset.value) / _appState.zoomFactor.toDouble();

      if (ev.scrollDelta.dy < 0.0 && _appState.increaseZoomLevel())
      {
        _setOffset(newOffset: ev.localPosition - (cursorPositionBeforeZoom * _appState.zoomFactor.toDouble()));
      }
      else if (ev.scrollDelta.dy > 0.0 && _appState.decreaseZoomLevel())
      {
        _setOffset(newOffset: ev.localPosition - (cursorPositionBeforeZoom * _appState.zoomFactor.toDouble()));
      }
    }
  }

  void _onMouseExit({required final PointerExitEvent pee})
  {
    _cursorPos.value = null;
    _appState.repaintNotifier.repaint();
    _mouseIsInside = false;
  }


  void _stylusBtnTimeout({required final Timer t})
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
      if (!_stylusLongMoveStarted.value && !_isDragging.value && _cursorPos.value != null)
      {
        final CoordinateSetI normPos = CoordinateSetI(
            x: KPixPainter.getClosestPixel(
                value: _cursorPos.value!.x - _canvasOffset.value.dx,
                pixelSize: _appState.zoomFactor.toDouble())
                .round(),
            y: KPixPainter.getClosestPixel(
                value: _cursorPos.value!.y - _canvasOffset.value.dy,
                pixelSize: _appState.zoomFactor.toDouble())
                .round());
        ColorReference? colRef = ColorPickPainter.getColorFromImageAtPosition(appState: _appState, normPos: normPos);
        if (colRef != null && colRef != _appState.selectedColor)
        {
           _appState.colorSelected(color: colRef);
        }
      }

      _needSecondaryStartLoc = false;
      stylusBtnUp();
      _stylusButtonDown = false;
      _timerStylusBtnLongPress.cancel();
      _timerStylusRunning = false;
      _stylusLongMoveStarted.value = false;
      _stylusLongMoveVertical.value = false;
      _stylusLongMoveHorizontal.value = false;
      _isDragging.value = false;
      setMouseCursor(cursor: SystemMouseCursors.none);
    }
    _stylusButtonDetected = false;

    if (!_stylusHoverDetected && _cursorPos.value != null && !_mouseIsInside)
    {
      _cursorPos.value = null;
      _appState.repaintNotifier.repaint();
    }
    else
    {
      _stylusHoverDetected = false;
    }
    if (_hasNewStylusPollValue)
    {
      t.cancel();
      Timer.periodic(Duration(milliseconds: _stylusPrefs.stylusPollInterval.value), (final Timer t) {_stylusBtnTimeout(t: t);});
      _hasNewStylusPollValue = false;
    }
  }

  //TODO delete me
  void stylusBtnDown()
  {
    //print("SECONDARY DOWN");
  }

  //TODO delete me
  void stylusBtnUp()
  {
    //print("SECONDARY UP");
  }

  void handleTimeoutStylusBtnLongPress()
  {
    //print("STYLUS BTN LONG PRESS");
    _timerStylusRunning = false;
    _stylusLongMoveStarted.value = true;
    _stylusZoomStartLevel = _appState.zoomFactor;
    _stylusToolStartSize = _appState.getCurrentToolSize();
  }

  void setMouseCursor({required final MouseCursor cursor})
  {
    _mouseCursor.value = cursor;
  }

  void _setOffset({required final Offset newOffset})
  {
    final CoordinateSetD coords = CoordinateSetD(x: newOffset.dx, y: newOffset.dy);
    final CoordinateSetD scaledCanvas = CoordinateSetD(x: _appState.canvasSize.x.toDouble() * _appState.zoomFactor, y: _appState.canvasSize.y.toDouble() * _appState.zoomFactor);
    final CoordinateSetD minVisibility = CoordinateSetD(x: kPixPainter.latestSize.width * _options.minVisibilityFactor, y: kPixPainter.latestSize.height * _options.minVisibilityFactor);

    coords.x = max(coords.x, -scaledCanvas.x + minVisibility.x);
    coords.y = max(coords.y, -scaledCanvas.y + minVisibility.y);
    coords.x = min(coords.x, kPixPainter.latestSize.width - minVisibility.x);
    coords.y = min(coords.y, kPixPainter.latestSize.height - minVisibility.y);
    _canvasOffset.value = Offset(coords.x, coords.y);
  }

  @override
  Widget build(final BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: _mouseCursor,
        builder: (BuildContext context, MouseCursor cursor, child)
        {
          return Stack(
            children: [
              MouseRegion(
                onExit: (final PointerExitEvent pee) {_onMouseExit(pee: pee);},
                cursor: cursor,
                child: Listener(
                  onPointerDown: (final PointerDownEvent pde) {_buttonDown(details: pde);},
                  onPointerMove: (final PointerEvent pe) {_updateLocation(details: pe);},
                  onPointerUp: (final PointerEvent pe) {_buttonUp(details: pe);},
                  onPointerHover: (final PointerHoverEvent phe) {_hover(details: phe);},
                  onPointerSignal: (final PointerSignalEvent pse) {_scroll(ev: pse);},
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
                valueListenable: GetIt.I.get<AppState>().selectedToolNotifier,
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