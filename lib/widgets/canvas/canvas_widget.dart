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

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/preferences/desktop_preferences.dart';
import 'package:kpix/preferences/stylus_preferences.dart';
import 'package:kpix/preferences/touch_preferences.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/canvas/selection_bar_widget.dart';


class CanvasOptions
{
  final int historyCheckPollRate;
  final double minVisibilityFactor;
  final int idleTimerRate;

  CanvasOptions({
    required this.historyCheckPollRate,
    required this.minVisibilityFactor,
    required this.idleTimerRate,});
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
        super.key,
      });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> with SingleTickerProviderStateMixin
{
  final CanvasOptions _options = GetIt.I.get<PreferenceManager>().canvasWidgetOptions;
  final StylusPreferenceContent _stylusPrefs = GetIt.I.get<PreferenceManager>().stylusPreferenceContent;
  final TouchPreferenceContent _touchPrefs = GetIt.I.get<PreferenceManager>().touchPreferenceContent;
  final DesktopPreferenceContent _desktopPrefs = GetIt.I.get<PreferenceManager>().desktopPreferenceContent;
  final ShaderOptions _shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<CoordinateSetD?> _cursorPos = ValueNotifier<CoordinateSetD?>(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusLongMoveStarted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusLongMoveVertical = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusLongMoveHorizontal = ValueNotifier<bool>(false);
  bool _timerRunning = false;
  late Duration _timeoutLongPress;
  late Timer _timerLongPress;
  final  ValueNotifier<Offset> _pressStartLoc = ValueNotifier<Offset>(Offset.zero);
  late Offset _secondaryStartLoc;
  bool _needSecondaryStartLoc = false;
  final ValueNotifier<bool> _primaryIsDown = ValueNotifier<bool> (false);
  final ValueNotifier<bool> _secondaryIsDown = ValueNotifier<bool> (false);
  int _stylusZoomStartLevel = 100;
  int _stylusToolStartSize = 1;

  late Timer _timerStylusBtnLongPress;
  bool _timerStylusRunning = false;
  bool _stylusButtonDetected = false;
  bool _stylusHoverDetected = false;
  final ValueNotifier<bool> _stylusButtonDown = ValueNotifier<bool>(false);
  DateTime _stylusDownTimeStamp = DateTime.now();
  DateTime _stylusHoverTimeStamp = DateTime.now();

  late Offset _dragStartLoc;

  final ValueNotifier<Offset> _canvasOffset = ValueNotifier<Offset>(Offset.zero);
  late MouseCursor _defaultMouseCursor = cursorTypeCursorMap[_desktopPrefs.cursorType.value]!;
  late final ValueNotifier<MouseCursor> _mouseCursor = ValueNotifier<MouseCursor>(_defaultMouseCursor);
  bool _mouseIsInside = false;
  final Map<int, TouchPointerStatus> _touchPointers = <int, TouchPointerStatus>{};
  double _initialTouchZoomDistance = 0.0;
  int _touchZoomStartLevel = 1;

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
    stylusButton1Down: _stylusButtonDown,
  );

  late ToolType _previousTool;

  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  late AnimationController _selectionBarAnimationController;
  late Animation<double> _selectionBarAnimation;

  void _setDefaultCursor()
  {
    _defaultMouseCursor = cursorTypeCursorMap[_desktopPrefs.cursorType.value]!;
    _mouseCursor.value = _defaultMouseCursor;
  }

  @override
  void initState()
  {
    super.initState();
    _desktopPrefs.cursorType.addListener(() {
      _setDefaultCursor();
    });
    Timer.periodic(Duration(milliseconds: _stylusPrefs.stylusPollInterval.value), (final Timer t) {_stylusBtnTimeout(t: t);});
    Timer.periodic(Duration(milliseconds: _options.historyCheckPollRate), (final Timer t) {_checkHistoryData(t: t);});
    Timer.periodic(Duration(milliseconds: _options.idleTimerRate), (final Timer t) {_idleTimeout(t: t);});
    _timeoutLongPress = Duration(milliseconds: _stylusPrefs.stylusLongPressDelay.value);
    WidgetsBinding.instance.addPostFrameCallback((final _)
    {
      _setOptimalZoom();
    });

    _stylusPrefs.stylusLongPressDelay.addListener(() {
      _timeoutLongPress = Duration(milliseconds: _stylusPrefs.stylusLongPressDelay.value);
    });
    _stylusPrefs.stylusPollInterval.addListener(() {
      _hasNewStylusPollValue = true;
    });

    _hotkeyManager.addListener(func: _setOptimalZoom, action: HotkeyAction.panZoomOptimalZoom);
    _shaderOptions.isEnabled.addListener(_updateFromChange);
    _shaderOptions.onlyCurrentRampEnabled.addListener(_updateFromChange);
    _shaderOptions.shaderDirection.addListener(_updateFromChange);
    _appState.selectedColorNotifier.addListener(_updateFromChange);

    _selectionBarAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: GetIt.I.get<PreferenceManager>().selectionBarWidgetOptions.opacityDuration),
    );
    _selectionBarAnimation = CurvedAnimation(
      parent: _selectionBarAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _updateFromChange()
  {
    _appState.repaintNotifier.repaint();
  }

  void _setOptimalZoom()
  {
    int bestZoomLevel = AppState.zoomLevelMin;
    for (int i = AppState.zoomLevelMin; i <= AppState.zoomLevelMax; i++)
    {
      if (_appState.canvasSize.x * i / _appState.devicePixelRatio < kPixPainter.latestSize.width && _appState.canvasSize.y * i / _appState.devicePixelRatio < kPixPainter.latestSize.height)
      {
        bestZoomLevel = i;
      }
      else
      {
        break;
      }
    }
    _appState.setZoomLevel(val: bestZoomLevel);
    _setOffset(newOffset: Offset((kPixPainter.latestSize.width - (_appState.canvasSize.x * _appState.zoomFactor / _appState.devicePixelRatio)) / 2, (kPixPainter.latestSize.height - (_appState.canvasSize.y * _appState.zoomFactor / _appState.devicePixelRatio)) / 2));
    _appState.repaintNotifier.repaint();
  }


  void _checkHistoryData({required final Timer t})
  {
    if (kPixPainter.toolPainter != null && kPixPainter.toolPainter!.hasHistoryData)
    {
      HistoryStateTypeIdentifier identifier = HistoryStateTypeIdentifier.generic;
      if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.pencil])
      {
        identifier = HistoryStateTypeIdentifier.toolPen;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.shape])
      {
        identifier = HistoryStateTypeIdentifier.toolShape;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.stamp])
      {
        identifier = HistoryStateTypeIdentifier.toolStamp;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.line])
      {
        identifier = HistoryStateTypeIdentifier.toolLine;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.spraycan])
      {
        identifier = HistoryStateTypeIdentifier.toolSprayCan;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.font])
      {
        identifier = HistoryStateTypeIdentifier.toolText;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.erase])
      {
        identifier = HistoryStateTypeIdentifier.toolEraser;
      }
      else if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.fill])
      {
        identifier = HistoryStateTypeIdentifier.toolFill;
      }

      GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: identifier);
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
        _mouseCursor.value = SystemMouseCursors.move;
      }
    }

    if (details.buttons == kPrimaryButton && _touchPointers.isEmpty)
    {
      _startDown(details.localPosition);
    }
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = true;
      if (!_shaderOptions.isEnabled.value && !(_appState.timeline.getCurrentLayer() != null && _appState.timeline.getCurrentLayer() is ShadingLayerState))
      {
        _previousTool = _appState.selectedTool;
        _appState.setToolSelection(tool: ToolType.pick);
      }
    }

    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _dragStartLoc = details.localPosition;
      _isDragging.value = true;
      _mouseCursor.value = SystemMouseCursors.move;
    }

    _updateLocation(details: details);
  }

  void _idleTimeout({required final Timer t})
  {
    if (kPixPainter.toolPainter != null && kPixPainter.toolPainter!.hasAsyncUpdate)
    {
      _appState.repaintNotifier.repaint();
      kPixPainter.toolPainter!.hasAsyncUpdate = false;
    }

  }

  void _startDown(final Offset position)
  {
    _pressStartLoc.value = position;
    _primaryIsDown.value = true;
    if (!_timerRunning) {
      _timerRunning = true;
      _timerLongPress = Timer(_timeoutLongPress, handleTimeoutLongPress);
    }
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
    }
    else if (_secondaryIsDown.value && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = false;
      if (_shaderOptions.isEnabled.value || (_appState.timeline.getCurrentLayer() != null && _appState.timeline.getCurrentLayer() is ShadingLayerState))
      {
        final ShaderDirection currentDirection = _shaderOptions.shaderDirection.value;
        if (currentDirection == ShaderDirection.left)
        {
          _shaderOptions.shaderDirection.value = ShaderDirection.right;
        }
        else
        {
          _shaderOptions.shaderDirection.value = ShaderDirection.left;
        }
      }
      else
      {
        final ColorPickPainter colorPickPainter = kPixPainter.toolPainterMap[ToolType.pick]! as ColorPickPainter;
        if (colorPickPainter.selectedColor != null)
        {
          _appState.colorSelected(color: colorPickPainter.selectedColor);
        }
        _appState.setToolSelection(tool: _previousTool);
      }
    }
    else if (_isDragging.value && details.kind == PointerDeviceKind.mouse)
    {
      _isDragging.value = false;
      _setDefaultCursor();
    }
    _timerRunning = false;

    if (_appState.selectedTool == ToolType.select)
    {
      if (kPixPainter.toolPainter == kPixPainter.toolPainterMap[ToolType.select])
      {
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select]! as SelectionPainter;
        if (selectionPainter.hasNewSelection)
        {
          selectionPainter.hasNewSelection = false;
          if (selectionPainter.options.shape.value == SelectShape.ellipse || selectionPainter.options.shape.value == SelectShape.rectangle) {
            _appState.selectionState.newSelectionFromShape(
                start: selectionPainter.selectionStart,
                end: selectionPainter.selectionEnd,
                selectShape: selectionPainter.options.shape.value,);
          }
          else if (selectionPainter.options.shape.value == SelectShape.wand)
          {
            _appState.selectionState.newSelectionFromWand(
                coord: selectionPainter.selectionEnd,
                mode: selectionPainter.options.mode.value,
                selectFromWholeRamp: selectionPainter.options.wandWholeRamp.value,
                continuous: selectionPainter.options.wandContinuous.value,);
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

      if (_stylusLongMoveHorizontal.value && _appState.timeline.getCurrentLayer() != null)
      {
        if (_appState.timeline.getCurrentLayer() is RasterableLayerState)
        {
          _appState.setToolSize(-toolSizeSteps, _stylusToolStartSize);
        }
        else if (_appState.timeline.getCurrentLayer().runtimeType == ReferenceLayerState)
        {
           final ReferenceLayerState refLayer = _appState.timeline.getCurrentLayer()! as ReferenceLayerState;
           refLayer.setZoomSliderValue(newVal: -toolSizeSteps + _stylusToolStartSize);
        }

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
      _mouseCursor.value = SystemMouseCursors.move;
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
        final SelectionPainter selectionPainter = kPixPainter.toolPainterMap[ToolType.select]! as SelectionPainter;
        if (selectionPainter.hasNewSelection && selectionPainter.options.shape.value == SelectShape.polygon)
        {
          selectionPainter.hasNewSelection = false;
          final CoordinateSetI min = getMin(coordList: selectionPainter.polygonPoints);
          final CoordinateSetI max = getMax(coordList: selectionPainter.polygonPoints);
          final Set<CoordinateSetI> selection = <CoordinateSetI>{};
          for (int x = min.x; x <= max.x; x++)
          {
            for (int y = min.y; y <= max.y; y++)
            {
              final CoordinateSetI checkPoint = CoordinateSetI(x: x, y: y);
              if (isPointInPolygon(point: checkPoint, polygon: selectionPainter.polygonPoints))
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
        final ColorPickPainter colorPickPainter = kPixPainter.toolPainterMap[ToolType.pick]! as ColorPickPainter;
        if (colorPickPainter.selectedColor != null)
        {
          _appState.colorSelected(color: colorPickPainter.selectedColor);
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
      _stylusHoverTimeStamp = DateTime.now();

    }
    _updateLocation(details: details);

  }

  void _scroll({required final PointerSignalEvent ev})
  {
    if (ev is PointerScrollEvent)
    {
      //ZOOM
      if (!_hotkeyManager.shiftIsPressed && !_hotkeyManager.altIsPressed && !_hotkeyManager.controlIsPressed)
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
      //CHANGE TOOL SIZE
      else if (!_hotkeyManager.shiftIsPressed && !_hotkeyManager.altIsPressed && _hotkeyManager.controlIsPressed)
      {
        if (ev.scrollDelta.dy < 0.0)
        {
          if (_appState.timeline.getCurrentLayer() != null)
          {
            if (_appState.timeline.getCurrentLayer() is RasterableLayerState)
            {
              _appState.setToolSize(1, _appState.getCurrentToolSize());
            }
            else if (_appState.timeline.getCurrentLayer().runtimeType == ReferenceLayerState)
            {
              final ReferenceLayerState refLayer = _appState.timeline.getCurrentLayer()! as ReferenceLayerState;
              refLayer.increaseZoom();
            }
          }
        }
        else
        {
          if (_appState.timeline.getCurrentLayer() != null)
          {
            if (_appState.timeline.getCurrentLayer() is RasterableLayerState)
            {
              _appState.setToolSize(-1, _appState.getCurrentToolSize());
            }
            else if (_appState.timeline.getCurrentLayer().runtimeType == ReferenceLayerState)
            {
              final ReferenceLayerState refLayer = _appState.timeline.getCurrentLayer()! as ReferenceLayerState;
              refLayer.decreaseZoom();
            }
          }
        }
        _appState.repaintNotifier.repaint();
      }
      //CHANGE CURRENT LAYER
      else if (_hotkeyManager.shiftIsPressed && !_hotkeyManager.altIsPressed && !_hotkeyManager.controlIsPressed)
      {
        if (ev.scrollDelta.dy < 0.0)
        {
          _appState.selectLayerAbove();
        }
        else
        {
          _appState.selectLayerBelow();
        }
      }
      //MOVE LAYER
      else if (_hotkeyManager.shiftIsPressed && !_hotkeyManager.altIsPressed && _hotkeyManager.controlIsPressed)
      {
        if (ev.scrollDelta.dy < 0.0)
        {
          _appState.moveUpLayer(layerState: _appState.timeline.getCurrentLayer());
        }
        else
        {
          _appState.moveDownLayer(layerState: _appState.timeline.getCurrentLayer());
        }
      }
      //CHANGE COLOR SELECTION
      else if (!_hotkeyManager.shiftIsPressed && _hotkeyManager.altIsPressed && !_hotkeyManager.controlIsPressed)
      {
        if (ev.scrollDelta.dy < 0.0)
        {
          _appState.decrementColorSelection();
        }
        else
        {
          _appState.incrementColorSelection();
        }
      }
    }
  }

  void _onMouseExit({required final PointerExitEvent pee})
  {
    _cursorPos.value = null;
    _appState.repaintNotifier.repaint();
    _mouseIsInside = false;
  }

  int _getClosestPixel({required final double value, required final double pixelSize})
  {
    final double remainder = value % pixelSize;
    final double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }


  void _stylusBtnTimeout({required final Timer t})
  {
    if (_stylusButtonDetected && !_stylusButtonDown.value)
    {
      _needSecondaryStartLoc = true;
      _stylusButtonDown.value = true;
      _stylusDownTimeStamp = DateTime.now();
      //stylusBtnDown();
      _timerStylusBtnLongPress = Timer(_timeoutLongPress, handleTimeoutStylusBtnLongPress);
      _timerStylusRunning = true;
    }
    else if (!_stylusButtonDetected && _stylusButtonDown.value)
    {
      final int diffMs = DateTime.now().difference(_stylusDownTimeStamp).inMilliseconds;
      //if (!_stylusLongMoveStarted.value && !_isDragging.value && _cursorPos.value != null)
      if (diffMs <= _stylusPrefs.stylusPickMaxDuration.value && _cursorPos.value != null)
      {
        if (_shaderOptions.isEnabled.value || (_appState.timeline.getCurrentLayer() != null && _appState.timeline.getCurrentLayer() is ShadingLayerState))
        {
          final ShaderDirection currentDirection = _shaderOptions.shaderDirection.value;
          if (currentDirection == ShaderDirection.left)
          {
            _shaderOptions.shaderDirection.value = ShaderDirection.right;
          }
          else
          {
            _shaderOptions.shaderDirection.value = ShaderDirection.left;
          }
        }
        else
        {
          final CoordinateSetI normPos = CoordinateSetI(
            x: _getClosestPixel(
              value: _cursorPos.value!.x - _canvasOffset.value.dx,
              pixelSize: _appState.zoomFactor.toDouble() / _appState.devicePixelRatio,)
            ,
            y: _getClosestPixel(
              value: _cursorPos.value!.y - _canvasOffset.value.dy,
              pixelSize: _appState.zoomFactor.toDouble() / _appState.devicePixelRatio,)
            ,);
          final ColorReference? colRef = _appState.getColorFromImageAtPosition(normPos: normPos);
          if (colRef != null && colRef != _appState.selectedColor)
          {
            _appState.colorSelected(color: colRef);
          }
        }
      }

      _needSecondaryStartLoc = false;
      //stylusBtnUp();
      _stylusButtonDown.value = false;
      _timerStylusBtnLongPress.cancel();
      _timerStylusRunning = false;
      _stylusLongMoveStarted.value = false;
      _stylusLongMoveVertical.value = false;
      _stylusLongMoveHorizontal.value = false;
      _isDragging.value = false;
      _setDefaultCursor();
    }
    _stylusButtonDetected = false;

    if (!_stylusHoverDetected && _cursorPos.value != null && !_mouseIsInside)
    {
      _cursorPos.value = null;
      _appState.repaintNotifier.repaint();
    }
    else if (DateTime.now().difference(_stylusHoverTimeStamp).inMilliseconds > _stylusPrefs.stylusPollInterval.value)
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

 /*
  void stylusBtnDown()
  {
    //print("SECONDARY DOWN");
  }


  void stylusBtnUp()
  {
    //print("SECONDARY UP");
  }
*/

  void handleTimeoutStylusBtnLongPress()
  {
    //print("STYLUS BTN LONG PRESS");
    _timerStylusRunning = false;
    _stylusLongMoveStarted.value = true;
    _stylusZoomStartLevel = _appState.zoomFactor;
    if (_appState.timeline.getCurrentLayer().runtimeType == DrawingLayerState)
    {
      _stylusToolStartSize = _appState.getCurrentToolSize();
    }
    else if (_appState.timeline.getCurrentLayer().runtimeType == ReferenceLayerState)
    {
      _stylusToolStartSize = (_appState.timeline.getCurrentLayer()! as ReferenceLayerState).zoomSliderValue;
    }

  }



  void _setOffset({required final Offset newOffset})
  {
    final CoordinateSetD coords = CoordinateSetD(x: newOffset.dx, y: newOffset.dy);
    final CoordinateSetD scaledCanvas = CoordinateSetD(x: _appState.canvasSize.x.toDouble() * _appState.zoomFactor / _appState.devicePixelRatio, y: _appState.canvasSize.y.toDouble() * _appState.zoomFactor / _appState.devicePixelRatio);
    final CoordinateSetD minVisibility = CoordinateSetD(x: kPixPainter.latestSize.width * _options.minVisibilityFactor, y: kPixPainter.latestSize.height * _options.minVisibilityFactor);

    coords.x = coords.x.clamp(-scaledCanvas.x + minVisibility.x, kPixPainter.latestSize.width - minVisibility.x);
    coords.y = coords.y.clamp(-scaledCanvas.y + minVisibility.y, kPixPainter.latestSize.height - minVisibility.y);

    _canvasOffset.value = Offset(coords.x, coords.y);
  }

  void _panZoomEnd({required final PointerPanZoomEndEvent event})
  {
    _isDragging.value = false;

  }

  void _panZoomUpdate({required final PointerPanZoomUpdateEvent event})
  {
    if (!_isDragging.value)
    {
      _isDragging.value = true;
      _touchZoomStartLevel = _appState.zoomFactor;
      _dragStartLoc = event.position;
      _initialTouchZoomDistance = 0.0;
    }
    else
    {
      const double factor = 25.0;
      final double currentDistance = event.scale >= 1.0 ? event.scale * factor - 1 : -(1.0 / event.scale) * factor;
      final double zoomSteps = (currentDistance - _initialTouchZoomDistance) / _touchPrefs.zoomStepDistance.value;
      _appState.setZoomLevelByDistance(startZoomLevel: _touchZoomStartLevel, steps: zoomSteps.toInt());
      if (zoomSteps > -1.0 && zoomSteps < 1.0)
      {
        _setOffset(newOffset: _canvasOffset.value + event.panDelta);
      }
      _appState.repaintNotifier.repaint();
    }
  }


  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<MouseCursor>(
      valueListenable: _mouseCursor,
      builder: (final BuildContext context, final MouseCursor cursor, final Widget? child)
      {
        return Stack(
          children: <Widget>[
            MouseRegion(
              onExit: (final PointerExitEvent pee) {_onMouseExit(pee: pee);},
              cursor: cursor,
              child: Listener(
                onPointerDown: (final PointerDownEvent pde) {_buttonDown(details: pde);},
                onPointerMove: (final PointerEvent pe) {_updateLocation(details: pe);},
                onPointerUp: (final PointerEvent pe) {_buttonUp(details: pe);},
                onPointerHover: (final PointerHoverEvent phe) {_hover(details: phe);},
                onPointerSignal: (final PointerSignalEvent pse) {_scroll(ev: pse);},
                onPointerPanZoomEnd: (final PointerPanZoomEndEvent event) {_panZoomEnd(event: event);},
                onPointerPanZoomUpdate: (final PointerPanZoomUpdateEvent event) {_panZoomUpdate(event: event);},
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).primaryColorDark,
                  child: CustomPaint(
                    painter: kPixPainter,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<ToolType>(
              valueListenable: GetIt.I.get<AppState>().selectedToolNotifier,
              builder: (final BuildContext contextS, final ToolType toolType, final Widget? childS) {
                return ValueListenableBuilder<bool>(
                  valueListenable: GetIt.I.get<AppState>().selectionState.selection.isEmptyNotifer,
                  builder: (final BuildContext contextT, final bool hasNoSelection, final Widget? childT) {
                    final bool shouldShow = toolType == ToolType.select || !hasNoSelection;
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
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizeTransition(
                          sizeFactor: _selectionBarAnimation,
                          child: const SelectionBarWidget(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
