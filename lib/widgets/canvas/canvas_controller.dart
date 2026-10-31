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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/infra/stylus_bridge.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_viewport.dart';

abstract final class _ControllerOptions
{
  static const int historyCheckPollRate = 250;
  static const int referenceCommitDelay = 500;
  static const int idleTimerRate = 15;
  static const int cursorTimeout = 100;
  static const int hoverExitDelay = 50;
  static const int reportedHoverTimeout = 1000;
}

class _TouchPointer
{
  final Offset startPos;
  Offset currentPos;
  _TouchPointer({required this.startPos, required this.currentPos});
}

/// Everything behind the canvas that is not layout: the painter, the pointer,
/// stylus and wheel input, and committing what the tools drew to the history.
///
/// It lives exactly as long as the canvas widget, which forwards its pointer
/// events and has to call [dispose].
class CanvasController
{
  final StylusPreferenceContent _stylusPrefs = GetIt.I.get<PreferenceManager>().stylusPreferenceContent;
  final TouchPreferenceContent _touchPrefs = GetIt.I.get<PreferenceManager>().touchPreferenceContent;
  final DesktopPreferenceContent _desktopPrefs = GetIt.I.get<PreferenceManager>().desktopPreferenceContent;
  final ShaderOptions _shaderOptions = GetIt.I.get<ShaderOptions>();
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final ViewState _viewState = GetIt.I.get<ViewState>();
  final ToolState _toolState = GetIt.I.get<ToolState>();
  final PaletteState _paletteState = GetIt.I.get<PaletteState>();
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final StylusBridge _stylusBridge = GetIt.I.get<StylusBridge>();
  final SymmetryState _symmetryState = GetIt.I.get<SymmetryState>();

  late final CanvasViewport viewport = CanvasViewport(viewState: _viewState, canvasState: GetIt.I.get<CanvasState>());

  final ValueNotifier<CoordinateSetD?> _cursorPos = ValueNotifier<CoordinateSetD?>(null);
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusLongMoveStarted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusLongMoveVertical = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusLongMoveHorizontal = ValueNotifier<bool>(false);
  final ValueNotifier<Offset> _pressStartLoc = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _primaryIsDown = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _secondaryIsDown = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _stylusButtonDown = ValueNotifier<bool>(false);

  late Duration _timeoutLongPress;
  late Offset _secondaryStartLoc;
  late Offset _dragStartLoc;
  late ToolType _previousTool;
  int? _primaryPointer;

  int _stylusZoomStartLevel = 100;
  int _stylusToolStartSize = 1;
  Timer? _timerStylusBtnLongPress;
  DateTime _stylusDownTimeStamp = DateTime.now();
  //a stylus button pressed during a stroke only counts after it was released
  bool _stylusButtonSuppressed = false;

  //stylus and touch pointers on the screen keep the cursor visible
  final Set<int> _contactPointers = <int>{};
  //without reported hover exits a stylus cursor has to time out quickly
  Timer? _cursorTimeoutTimer;
  bool _hoverExitReported = false;
  //channel messages overtake pointer events, so hover events from before the exit can still arrive
  Duration _hoverExitTime = Duration.zero;

  final Map<int, _TouchPointer> _touchPointers = <int, _TouchPointer>{};
  double _initialTouchZoomDistance = 0.0;
  int _touchZoomStartLevel = 1;

  late MouseCursor _defaultMouseCursor = _desktopPrefs.cursorType.value.systemCursor;
  late final ValueNotifier<MouseCursor> mouseCursor = ValueNotifier<MouseCursor>(_defaultMouseCursor);

  /// Every periodic timer this controller started, so [dispose] can stop all of them.
  ///
  /// The canvas is mounted only while a project is open, so it really is disposed
  /// and rebuilt; a timer that outlives it keeps acting on the global app state.
  final List<Timer> _timers = <Timer>[];

  //wheel zoom of a reference layer is committed once the wheel rests
  ReferenceLayerState? _pendingReferenceLayer;
  Timer? _referenceCommitTimer;
  bool _disposed = false;

  final ValueNotifier<double> _selectionPulse;

  late final KPixPainter painter = KPixPainter(
    offset: viewport.offset,
    coords: _cursorPos,
    isDragging: _isDragging,
    stylusLongMoveStarted: _stylusLongMoveStarted,
    stylusLongMoveVertical: _stylusLongMoveVertical,
    stylusLongMoveHorizontal: _stylusLongMoveHorizontal,
    primaryDown: _primaryIsDown,
    secondaryDown: _secondaryIsDown,
    primaryPressStart: _pressStartLoc,
    stylusButton1Down: _stylusButtonDown,
    selectionPulse: _selectionPulse,
  );

  late final List<(Listenable, VoidCallback)> _listeners = <(Listenable, VoidCallback)>[
    (_desktopPrefs.cursorType, _setDefaultCursor),
    (_stylusPrefs.stylusLongPressDelay, _stylusLongPressDelayChanged),
    (_shaderOptions.isEnabled, _repaint),
    (_shaderOptions.onlyCurrentRampEnabled, _repaint),
    (_shaderOptions.shaderDirection, _repaint),
    (_paletteState.selectedColorNotifier, _repaint),
    (_documentState.timeline.isPlaying, _setDefaultCursor),
    (_viewState.zoomFactorNotifier, _repaint),
    (viewport.offset, _repaint),
    (_toolState.selectedToolNotifier, _repaint),
    (_documentState.timeline.isPlaying, _repaint),
    (_documentState.timeline.frames, _repaint),
    (_documentState.timeline.selectedFrameIndexNotifier, _repaint),
    (_symmetryState.horizontalActivated, _repaint),
    (_symmetryState.horizontalValue, _repaint),
    (_symmetryState.verticalActivated, _repaint),
    (_symmetryState.verticalValue, _repaint),
  ];

  CanvasController({required final ValueNotifier<double> selectionPulse}) : _selectionPulse = selectionPulse
  {
    for (final (Listenable listenable, VoidCallback listener) in _listeners)
    {
      listenable.addListener(listener);
    }
    _timers.add(Timer.periodic(const Duration(milliseconds: _ControllerOptions.historyCheckPollRate), (final Timer _) {_flushHistoryData();}));
    _timers.add(Timer.periodic(const Duration(milliseconds: _ControllerOptions.idleTimerRate), (final Timer _) {_idleTimeout();}));
    GetIt.I.get<HistoryController>().flushHistoryData = _flushPendingHistory;
    _stylusBridge.onHoverExit = _stylusHoverExit;
    _timeoutLongPress = Duration(milliseconds: _stylusPrefs.stylusLongPressDelay.value);
    WidgetsBinding.instance.addPostFrameCallback((final _)
    {
      _requestOptimalZoom();
    });
    _hotkeyManager.addListener(func: _requestOptimalZoom, action: HotkeyAction.panZoomOptimalZoom);
  }

  void dispose()
  {
    _disposed = true;
    for (final Timer timer in _timers)
    {
      timer.cancel();
    }
    _timers.clear();
    _referenceCommitTimer?.cancel();
    _cursorTimeoutTimer?.cancel();

    _hotkeyManager.removeListener(func: _requestOptimalZoom, action: HotkeyAction.panZoomOptimalZoom);
    for (final (Listenable listenable, VoidCallback listener) in _listeners)
    {
      listenable.removeListener(listener);
    }

    //the global app state holds these callbacks, so it has to let go of them too
    if (GetIt.I.get<HistoryController>().flushHistoryData == _flushPendingHistory)
    {
      GetIt.I.get<HistoryController>().flushHistoryData = null;
    }
    if (_stylusBridge.onHoverExit == _stylusHoverExit)
    {
      _stylusBridge.onHoverExit = null;
    }
    painter.dispose();
  }

  void _repaint()
  {
    _viewState.repaintNotifier.repaint();
  }

  void _setDefaultCursor()
  {
    _defaultMouseCursor = _desktopPrefs.cursorType.value.systemCursor;
    final bool isForbidden = _documentState.timeline.isPlaying.value;
    if (isForbidden && mouseCursor.value == SystemMouseCursors.none)
    {
      mouseCursor.value = SystemMouseCursors.forbidden;
    }
    else
    {
      mouseCursor.value = _defaultMouseCursor;
    }
  }

  void _stylusLongPressDelayChanged()
  {
    _timeoutLongPress = Duration(milliseconds: _stylusPrefs.stylusLongPressDelay.value);
  }

  void _requestOptimalZoom()
  {
    if (!_disposed)
    {
      viewport.requestOptimalZoom();
    }
  }

  /// Takes the size of the drawing area from layout; the app state is only
  /// touched once the current frame has been completed.
  void viewportSizeChanged({required final Size size})
  {
    if (viewport.resize(newSize: size))
    {
      WidgetsBinding.instance.addPostFrameCallback((final _)
      {
        if (!_disposed)
        {
          viewport.applyOptimalZoom();
        }
      });
    }
  }

  void _scheduleReferenceLayerCommit({required final ReferenceLayerState layer})
  {
    if (_pendingReferenceLayer != null && _pendingReferenceLayer != layer)
    {
      _commitPendingReferenceLayer();
    }
    _pendingReferenceLayer = layer;
    _referenceCommitTimer?.cancel();
    _referenceCommitTimer = Timer(const Duration(milliseconds: _ControllerOptions.referenceCommitDelay), _commitPendingReferenceLayer);
  }

  void _commitPendingReferenceLayer()
  {
    _referenceCommitTimer?.cancel();
    _referenceCommitTimer = null;
    final ReferenceLayerState? layer = _pendingReferenceLayer;
    _pendingReferenceLayer = null;
    if (layer != null)
    {
      GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: layer);
    }
  }

  //runs before undo/redo, so pending changes become their own step first
  void _flushPendingHistory()
  {
    _commitPendingReferenceLayer();
    _flushHistoryData();
  }

  void _flushHistoryData()
  {
    final IToolPainter? toolPainter = painter.toolPainter;
    if (toolPainter != null && toolPainter.hasHistoryData)
    {
      final LayerState? originLayer = toolPainter.historyLayer ?? _documentState.timeline.getCurrentLayer();
      GetIt.I.get<HistoryManager>().addState(identifier: toolPainter.historyIdentifier, originLayer: originLayer);
      toolPainter.hasHistoryData = false;
    }
  }

  void _idleTimeout()
  {
    if (painter.toolPainter != null && painter.toolPainter!.hasAsyncUpdate)
    {
      _viewState.repaintNotifier.repaint();
      painter.toolPainter!.hasAsyncUpdate = false;
      //the tool data can change without the cursor moving (e.g. a modifier key)
      WidgetsBinding.instance.addPostFrameCallback((final _)
      {
        if (!_disposed && painter.toolPainter != null)
        {
          GetIt.I.get<StatusBarState>().updateFromPaint(statusBarData: painter.toolPainter!.statusBarData);
        }
      });
    }
  }

  void pointerDown({required final PointerDownEvent details})
  {
    viewport.cancelOptimalZoom();
    if (details.kind != PointerDeviceKind.mouse)
    {
      _contactPointers.add(details.pointer);
      _cursorTimeoutTimer?.cancel();
    }
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers[details.pointer] = _TouchPointer(startPos: details.localPosition, currentPos: details.localPosition);
      if (_touchPointers.length == 1)
      {
        Timer(Duration(milliseconds: _touchPrefs.singleTouchDelay.value), _checkTouchDraw);
      }
      else if (_touchPointers.length == 2)
      {
        _dragStartLoc = _touchCenter();
        _isDragging.value = true;
        _initialTouchZoomDistance = _touchDistance();
        _touchZoomStartLevel = _viewState.zoomFactor;
        mouseCursor.value = SystemMouseCursors.move;
      }
    }

    if (details.buttons == kPrimaryButton && _touchPointers.isEmpty)
    {
      _startDown(position: details.localPosition, pointer: details.pointer);
    }
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = true;
      if (!_shadesOnSecondary())
      {
        _previousTool = _toolState.selectedTool;
        _toolState.setToolSelection(tool: ToolType.pick);
      }
    }
    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      _dragStartLoc = details.localPosition;
      _isDragging.value = true;
      mouseCursor.value = SystemMouseCursors.move;
    }

    pointerMove(details: details);
  }

  Offset _touchCenter()
  {
    return Offset((_touchPointers.values.elementAt(0).currentPos.dx + _touchPointers.values.elementAt(1).currentPos.dx) / 2, (_touchPointers.values.elementAt(0).currentPos.dy + _touchPointers.values.elementAt(1).currentPos.dy) / 2);
  }

  double _touchDistance()
  {
    return (_touchPointers.values.elementAt(0).currentPos - _touchPointers.values.elementAt(1).currentPos).distance;
  }

  void _startDown({required final Offset position, required final int pointer})
  {
    _pressStartLoc.value = position;
    _primaryPointer = pointer;
    _primaryIsDown.value = true;
  }

  void _checkTouchDraw()
  {
    //a touch while the stylus draws (e.g. a palm) must not take over the stroke
    if (_touchPointers.length == 1 && !_primaryIsDown.value)
    {
      final MapEntry<int, _TouchPointer> touch = _touchPointers.entries.first;
      _startDown(position: touch.value.startPos, pointer: touch.key);
    }
  }

  /// Whether the secondary button and the stylus button shade instead of picking a color.
  bool _shadesOnSecondary()
  {
    return _shaderOptions.isEnabled.value || _documentState.timeline.getCurrentLayer() is ShadingLayerState;
  }

  /// A tap of the secondary button or the stylus button: turns the shading
  /// direction around while shading, picks the color under the cursor otherwise.
  void _secondaryTap()
  {
    if (_shadesOnSecondary())
    {
      _shaderOptions.toggleDirection();
    }
    else
    {
      final ColorReference? colRef = _getColorAtCursor();
      if (colRef != null)
      {
        _paletteState.colorSelected(color: colRef);
      }
    }
  }

  void pointerUp({required final PointerEvent details})
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers.clear();
      _isDragging.value = false;
    }

    if (_primaryIsDown.value)
    {
      _primaryPointer = null;
      _primaryIsDown.value = false;
      final LayerState? currentLayer = _documentState.timeline.getCurrentLayer();
      if (currentLayer is ReferenceLayerState)
      {
        GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: currentLayer);
      }
    }
    else if (_secondaryIsDown.value && details.kind == PointerDeviceKind.mouse)
    {
      _secondaryIsDown.value = false;
      final bool shades = _shadesOnSecondary();
      _secondaryTap();
      if (!shades)
      {
        _toolState.setToolSelection(tool: _previousTool);
      }
    }
    else if (_isDragging.value && details.kind == PointerDeviceKind.mouse)
    {
      _isDragging.value = false;
      _setDefaultCursor();
    }

    if (_toolState.selectedTool == ToolType.select)
    {
      if (painter.toolPainter == painter.toolPainterMap[ToolType.select])
      {
        final SelectionPainter selectionPainter = painter.toolPainterMap[ToolType.select]! as SelectionPainter;
        if (selectionPainter.hasNewSelection)
        {
          selectionPainter.hasNewSelection = false;
          if (selectionPainter.options.shape.value == SelectShape.ellipse || selectionPainter.options.shape.value == SelectShape.rectangle) {
            _documentState.selectionState.newSelectionFromShape(
                start: selectionPainter.selectionStart,
                end: selectionPainter.selectionEnd,
                selectShape: selectionPainter.options.shape.value,);
          }
          else if (selectionPainter.options.shape.value == SelectShape.wand)
          {
            _documentState.selectionState.newSelectionFromWand(
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
    pointerMove(details: details);
    _releaseContact(details: details);
  }

  void pointerCancel({required final PointerCancelEvent details})
  {
    //a cancelled touch (e.g. a rejected palm) must not end the stroke of another pointer
    if (details.kind != PointerDeviceKind.mouse && details.pointer != _primaryPointer)
    {
      if (_touchPointers.remove(details.pointer) != null && _touchPointers.length == 1)
      {
        _isDragging.value = false;
      }
      if (details.kind == PointerDeviceKind.stylus)
      {
        _setStylusButton(pressed: false);
      }
      _releaseContact(details: details);
      _viewState.repaintNotifier.repaint();
    }
    else
    {
      pointerUp(details: details);
    }
  }

  void _releaseContact({required final PointerEvent details})
  {
    if (_contactPointers.remove(details.pointer) && _contactPointers.isEmpty)
    {
      _restartCursorTimeout();
    }
  }

  //the delay after lifting also leaves the tools time to process the release
  void _restartCursorTimeout({final int milliseconds = _ControllerOptions.cursorTimeout})
  {
    _cursorTimeoutTimer?.cancel();
    _cursorTimeoutTimer = Timer(Duration(milliseconds: milliseconds), _cursorTimeout);
  }

  void _cursorTimeout()
  {
    _cursorTimeoutTimer = null;
    if (_contactPointers.isEmpty)
    {
      if (_cursorPos.value != null)
      {
        _cursorPos.value = null;
        _viewState.repaintNotifier.repaint();
      }
      //the stylus is gone, its button cannot be released anymore (no pick without a cursor)
      _setStylusButton(pressed: false);
    }
  }

  void _stylusHoverExit({required final Duration timeStamp})
  {
    _hoverExitReported = true;
    _hoverExitTime = timeStamp;
    //the delay lets a following touch down of the stylus keep the cursor
    _restartCursorTimeout(milliseconds: _ControllerOptions.hoverExitDelay);
  }

  //every stylus event carries the button state; Android drops the button events while hovering
  void _sampleStylusButton({required final PointerEvent details})
  {
    final bool pressed = (details.buttons & kSecondaryButton) != 0;
    if (!pressed)
    {
      _stylusButtonSuppressed = false;
    }
    else if (_primaryIsDown.value && !_stylusButtonDown.value)
    {
      _stylusButtonSuppressed = true;
    }
    if (!_stylusButtonSuppressed)
    {
      _setStylusButton(pressed: pressed);
    }
  }

  void pointerMove({required final PointerEvent details})
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      _touchPointers[details.pointer]?.currentPos = details.localPosition;
    }

    if (details.kind == PointerDeviceKind.touch && _touchPointers.length == 2)
    {
      final Offset center = _touchCenter();
      _cursorPos.value = CoordinateSetD(x: center.dx, y: center.dy);
    }
    else
    {
      _cursorPos.value = CoordinateSetD(x: details.localPosition.dx, y: details.localPosition.dy);
    }
    if (painter.toolPainter != null)
    {
      GetIt.I.get<StatusBarState>().updateFromPaint(statusBarData: painter.toolPainter!.statusBarData);
    }

    //the mouse cursor is hidden when the mouse leaves the canvas instead
    if (details.kind == PointerDeviceKind.mouse)
    {
      _cursorTimeoutTimer?.cancel();
    }
    else if (details.kind == PointerDeviceKind.stylus)
    {
      _sampleStylusButton(details: details);
    }

    final Offset cursorOffset = Offset(_cursorPos.value!.x, _cursorPos.value!.y);

    if (_stylusLongMoveStarted.value)
    {
      _stylusLongMove(cursorOffset: cursorOffset);
    }

    if (_timerStylusBtnLongPress != null && (_secondaryStartLoc - cursorOffset).distance > _stylusPrefs.stylusLongPressCancelDistance.value)
    {
      _timerStylusBtnLongPress!.cancel();
      _timerStylusBtnLongPress = null;
      _isDragging.value = true;
      mouseCursor.value = SystemMouseCursors.move;
      _dragStartLoc = cursorOffset;
    }

    if (_isDragging.value)
    {
      viewport.setOffset(newOffset: viewport.offset.value - (_dragStartLoc - cursorOffset));
      _dragStartLoc = cursorOffset;

      if (details.kind == PointerDeviceKind.touch && _touchPointers.length == 2)
      {
        final int zoomSteps = ((_touchDistance() - _initialTouchZoomDistance) / _touchPrefs.zoomStepDistance.value).round();
        viewport.zoomAround(focus: cursorOffset, zoom: () => _viewState.setZoomLevelByDistance(startZoomLevel: _touchZoomStartLevel, steps: zoomSteps));
      }
    }

    _checkSelectedToolData();
    _viewState.repaintNotifier.repaint();
  }

  /// Moving with the stylus button held down long: up and down zoom, left and
  /// right change the tool size (or the zoom of a reference layer).
  void _stylusLongMove({required final Offset cursorOffset})
  {
    final double yOffset = _secondaryStartLoc.dy - cursorOffset.dy;
    final double xOffset = _secondaryStartLoc.dx - cursorOffset.dx;
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

    final LayerState? currentLayer = _documentState.timeline.getCurrentLayer();
    if (_stylusLongMoveHorizontal.value)
    {
      if (currentLayer is RasterableLayerState)
      {
        _toolState.setToolSize(-toolSizeSteps, _stylusToolStartSize);
      }
      else if (currentLayer is ReferenceLayerState)
      {
        currentLayer.setZoomSliderValue(newVal: -toolSizeSteps + _stylusToolStartSize);
      }
    }

    if (_stylusLongMoveVertical.value)
    {
      viewport.zoomAround(focus: cursorOffset, zoom: () => _viewState.setZoomLevelByDistance(startZoomLevel: _stylusZoomStartLevel, steps: zoomSteps));
    }
  }

  void _checkSelectedToolData()
  {
    if (_toolState.selectedTool == ToolType.select)
    {
      if (painter.toolPainterMap[ToolType.select] != null && painter.toolPainterMap[ToolType.select].runtimeType == SelectionPainter)
      {
        final SelectionPainter selectionPainter = painter.toolPainterMap[ToolType.select]! as SelectionPainter;
        if (selectionPainter.hasNewSelection && selectionPainter.options.shape.value == SelectShape.polygon)
        {
          selectionPainter.hasNewSelection = false;
          final CoordinateSetI min = CoordinateSetI.getMin(coordList: selectionPainter.polygonPoints);
          final CoordinateSetI max = CoordinateSetI.getMax(coordList: selectionPainter.polygonPoints);
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
          _documentState.selectionState.newSelectionFromPolygon(points: selection);
          selectionPainter.polygonPoints.clear();
          selectionPainter.polygonDown = false;
        }
      }
    }
    else if (_toolState.selectedTool == ToolType.pick && !_secondaryIsDown.value)
    {
      if (painter.toolPainterMap[ToolType.pick] != null && painter.toolPainterMap[ToolType.pick].runtimeType == ColorPickPainter)
      {
        final ColorPickPainter colorPickPainter = painter.toolPainterMap[ToolType.pick]! as ColorPickPainter;
        final ColorReference? pickedColor = colorPickPainter.selectedColor;
        colorPickPainter.selectedColor = null;
        if (pickedColor != null)
        {
          _paletteState.colorSelected(color: pickedColor);
        }
      }
    }
  }

  void pointerHover({required final PointerHoverEvent details})
  {
    if (details.kind != PointerDeviceKind.mouse)
    {
      if (details.timeStamp <= _hoverExitTime)
      {
        return;
      }
      _restartCursorTimeout(milliseconds: _hoverExitReported ? _ControllerOptions.reportedHoverTimeout : _ControllerOptions.cursorTimeout);
    }
    pointerMove(details: details);
  }

  /// The scroll wheel zooms; with modifiers it changes the tool size, the
  /// current layer, the layer order or the selected color.
  void pointerSignal({required final PointerSignalEvent ev})
  {
    viewport.cancelOptimalZoom();
    if (ev is! PointerScrollEvent)
    {
      return;
    }
    final bool up = ev.scrollDelta.dy < 0.0;
    final bool shift = _hotkeyManager.shiftIsPressed;
    final bool alt = _hotkeyManager.altIsPressed;
    final bool control = _hotkeyManager.controlIsPressed;
    if (!shift && !alt && !control)
    {
      if (up)
      {
        viewport.zoomAround(focus: ev.localPosition, zoom: _viewState.increaseZoomLevel);
      }
      else if (ev.scrollDelta.dy > 0.0)
      {
        viewport.zoomAround(focus: ev.localPosition, zoom: _viewState.decreaseZoomLevel);
      }
    }
    else if (!shift && !alt && control)
    {
      _stepToolSize(steps: up ? 1 : -1);
      _viewState.repaintNotifier.repaint();
    }
    else if (shift && !alt && !control)
    {
      final LayerManager layerManager = GetIt.I.get<LayerManager>();
      if (up)
      {
        layerManager.selectLayerAbove();
      }
      else
      {
        layerManager.selectLayerBelow();
      }
    }
    else if (shift && !alt && control)
    {
      final LayerManager layerManager = GetIt.I.get<LayerManager>();
      if (up)
      {
        layerManager.moveUpLayer(layerState: _documentState.timeline.getCurrentLayer());
      }
      else
      {
        layerManager.moveDownLayer(layerState: _documentState.timeline.getCurrentLayer());
      }
    }
    else if (!shift && alt && !control)
    {
      if (up)
      {
        _paletteState.decrementColorSelection();
      }
      else
      {
        _paletteState.incrementColorSelection();
      }
    }
  }

  /// Makes the tool one size step bigger or smaller, or zooms a reference layer.
  void _stepToolSize({required final int steps})
  {
    final LayerState? currentLayer = _documentState.timeline.getCurrentLayer();
    if (currentLayer is RasterableLayerState)
    {
      _toolState.setToolSize(steps, _toolState.getCurrentToolSize());
    }
    else if (currentLayer is ReferenceLayerState)
    {
      if (steps > 0)
      {
        currentLayer.increaseZoom();
      }
      else
      {
        currentLayer.decreaseZoom();
      }
      _scheduleReferenceLayerCommit(layer: currentLayer);
    }
  }

  void mouseExit()
  {
    _cursorPos.value = null;
    _viewState.repaintNotifier.repaint();
  }

  ColorReference? _getColorAtCursor()
  {
    if (_cursorPos.value == null)
    {
      return null;
    }
    return _documentState.getColorFromImageAtPosition(normPos: viewport.pixelAt(position: _cursorPos.value!));
  }

  void _setStylusButton({required final bool pressed})
  {
    //only a press over the canvas starts picking, panning or zooming
    if (pressed && !_stylusButtonDown.value && _cursorPos.value != null)
    {
      _secondaryStartLoc = Offset(_cursorPos.value!.x, _cursorPos.value!.y);
      _stylusButtonDown.value = true;
      _stylusDownTimeStamp = DateTime.now();
      _timerStylusBtnLongPress = Timer(_timeoutLongPress, _stylusButtonLongPress);
    }
    else if (!pressed && _stylusButtonDown.value)
    {
      final int diffMs = DateTime.now().difference(_stylusDownTimeStamp).inMilliseconds;
      if (diffMs <= _stylusPrefs.stylusPickMaxDuration.value && _cursorPos.value != null)
      {
        _secondaryTap();
      }

      _stylusButtonDown.value = false;
      _timerStylusBtnLongPress?.cancel();
      _timerStylusBtnLongPress = null;
      final LayerState? currentLayer = _documentState.timeline.getCurrentLayer();
      if (_stylusLongMoveHorizontal.value && currentLayer is ReferenceLayerState)
      {
        GetIt.I.get<LayerManager>().commitReferenceLayerChange(layer: currentLayer);
      }
      _stylusLongMoveStarted.value = false;
      _stylusLongMoveVertical.value = false;
      _stylusLongMoveHorizontal.value = false;
      _isDragging.value = false;
      _setDefaultCursor();
    }
  }

  void _stylusButtonLongPress()
  {
    _timerStylusBtnLongPress = null;
    _stylusLongMoveStarted.value = true;
    _stylusZoomStartLevel = _viewState.zoomFactor;
    final LayerState? currentLayer = _documentState.timeline.getCurrentLayer();
    if (currentLayer?.kind == LayerKind.drawing)
    {
      _stylusToolStartSize = _toolState.getCurrentToolSize();
    }
    else if (currentLayer is ReferenceLayerState)
    {
      _stylusToolStartSize = currentLayer.zoomSliderValue;
    }
  }

  void panZoomEnd()
  {
    _isDragging.value = false;
  }

  void panZoomUpdate({required final PointerPanZoomUpdateEvent event})
  {
    viewport.cancelOptimalZoom();
    if (!_isDragging.value)
    {
      _isDragging.value = true;
      _touchZoomStartLevel = _viewState.zoomFactor;
      _dragStartLoc = event.position;
      _initialTouchZoomDistance = 0.0;
    }
    else
    {
      const double factor = 25.0;
      final double currentDistance = event.scale >= 1.0 ? event.scale * factor - 1 : -(1.0 / event.scale) * factor;
      final double zoomSteps = (currentDistance - _initialTouchZoomDistance) / _touchPrefs.zoomStepDistance.value;
      _viewState.setZoomLevelByDistance(startZoomLevel: _touchZoomStartLevel, steps: zoomSteps.toInt());
      if (zoomSteps > -1.0 && zoomSteps < 1.0)
      {
        viewport.setOffset(newOffset: viewport.offset.value + event.panDelta);
      }
      _viewState.repaintNotifier.repaint();
    }
  }
}
