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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/infra/stylus_bridge.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_controller.dart';
import 'package:kpix/widgets/canvas/canvas_viewport.dart';
import 'package:kpix/widgets/canvas/canvas_widget.dart';
import 'package:kpix/widgets/canvas/touch_joystick_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

const Size _drawingArea = Size(800, 600);

ViewState get _view => GetIt.I.get<ViewState>();
ToolState get _tools => GetIt.I.get<ToolState>();
HistoryManager get _history => GetIt.I.get<HistoryManager>();
Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;
SelectionState get _selection => GetIt.I.get<DocumentState>().selectionState;
PaletteState get _palette => GetIt.I.get<PaletteState>();
HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();
ShaderOptions get _shader => GetIt.I.get<ShaderOptions>();
SelectOptions get _selectOptions => GetIt.I.get<ToolOptions>().selectOptions;
LayerManager get _layers => GetIt.I.get<LayerManager>();
StylusPreferenceContent get _stylusPrefs => GetIt.I.get<PreferenceManager>().stylusPreferenceContent;
TouchPreferenceContent get _touchPrefs => GetIt.I.get<PreferenceManager>().touchPreferenceContent;
DrawingLayerState get _drawing => _timeline.getCurrentLayer()! as DrawingLayerState;

const Duration _hoverTime = Duration(seconds: 1);

PointerDownEvent _press({required final Offset at, final PointerDeviceKind kind = PointerDeviceKind.mouse, final int pointer = 1, final int buttons = kPrimaryButton})
{
  return PointerDownEvent(pointer: pointer, kind: kind, buttons: buttons, position: at);
}

PointerMoveEvent _move({required final Offset at, final PointerDeviceKind kind = PointerDeviceKind.mouse, final int pointer = 1, final int buttons = kPrimaryButton})
{
  return PointerMoveEvent(pointer: pointer, kind: kind, buttons: buttons, position: at);
}

PointerUpEvent _lift({required final Offset at, final PointerDeviceKind kind = PointerDeviceKind.mouse, final int pointer = 1})
{
  return PointerUpEvent(pointer: pointer, kind: kind, position: at);
}

PointerCancelEvent _cancel({required final Offset at, final PointerDeviceKind kind = PointerDeviceKind.mouse, final int pointer = 1})
{
  return PointerCancelEvent(pointer: pointer, kind: kind, position: at);
}

PointerHoverEvent _hover({required final Offset at, final PointerDeviceKind kind = PointerDeviceKind.mouse, final bool button = false, final Duration time = _hoverTime})
{
  return PointerHoverEvent(kind: kind, position: at, buttons: button ? kSecondaryButton : 0, timeStamp: time);
}

PointerScrollEvent _scroll({required final double dy, final double dx = 0.0, final Offset at = const Offset(400, 300)})
{
  return PointerScrollEvent(position: at, scrollDelta: Offset(dx, dy));
}

PointerPanZoomUpdateEvent _panZoom({final Offset panDelta = Offset.zero, final double scale = 1.0, final Offset at = const Offset(400, 300)})
{
  return PointerPanZoomUpdateEvent(position: at, panDelta: panDelta, scale: scale);
}

/// What the canvas widget gets the painter to do after every event.
void _frame(final CanvasController controller)
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  controller.painter.paint(Canvas(recorder), _drawingArea);
  recorder.endRecording().dispose();
}

Offset _at({required final CanvasController controller, required final int x, required final int y})
{
  return _screenPosition(viewport: controller.viewport, pixel: CoordinateSetI(x: x, y: y));
}

/// Hovers along to the first of [path], presses there, moves along it and releases.
void _dragAlong({required final CanvasController controller, required final List<Offset> path, final PointerDeviceKind kind = PointerDeviceKind.mouse})
{
  controller.pointerHover(details: _hover(at: path.first, kind: kind));
  _frame(controller);
  controller.pointerDown(details: _press(at: path.first, kind: kind));
  _frame(controller);
  for (final Offset position in path.skip(1))
  {
    controller.pointerMove(details: _move(at: position, kind: kind));
    _frame(controller);
  }
  controller.pointerUp(details: _lift(at: path.last, kind: kind));
  _frame(controller);
}

/// The pixel a tool sees the cursor at, null if the cursor is gone.
CoordinateSetI? _cursorPixel(final CanvasController controller)
{
  _frame(controller);
  final IToolPainter tool = controller.painter.toolPainter!;
  return tool.statusBarData.cursorPos;
}

/// A stylus held still above the canvas keeps sending hover events.
Future<void> _holdStylusButton({required final WidgetTester tester, required final CanvasController controller, required final Offset at, final int milliseconds = 200}) async
{
  for (int elapsed = 0; elapsed < milliseconds; elapsed += 40)
  {
    controller.pointerHover(details: _hover(at: at, kind: PointerDeviceKind.stylus, button: true));
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void _inputTest(final String description, final Future<void> Function(WidgetTester tester, CanvasController controller) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await _boot(tester);
    final CanvasController controller = await _controller(tester);
    await body(tester, controller);
    controller.dispose();
    await _release(tester);
    //what the layers still had planned, like building the composite
    await tester.pump(const Duration(milliseconds: 300));
  });
}

ReferenceLayerState _addReferenceLayer()
{
  return _layers.addNewLayer(layerType: LayerKind.reference, select: true, addToHistoryStack: false).$2! as ReferenceLayerState;
}

Future<void> _undoStep(final WidgetTester tester) async
{
  await tester.runAsync(() async
  {
    await GetIt.I.get<HistoryController>().undoPressed()!.restore;
    await settle();
  });
}

/// Boots a 32x24 project whose layer is filled with a pattern of colors.
Future<void> _boot(final WidgetTester tester) async
{
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 32, y: 24));
    GetIt.I.registerSingleton<StylusBridge>(StylusBridge());
    GetIt.I.registerSingleton<StampManager>(StampManager());
    final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
    final CoordinateColorMapNullable pixels = CoordinateColorMapNullable();
    for (int y = 0; y < 24; y++)
    {
      for (int x = 0; x < 32; x++)
      {
        pixels[CoordinateSetI(x: x, y: y)] = ramps[(x ~/ 4) % ramps.length].references[(y ~/ 3) % 5];
      }
    }
    (GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getLayer(index: 0) as DrawingLayerState).setDataAll(list: pixels);
    await settle();
  });
}

/// Releases the layers of the project, whose raster timer would otherwise still
/// be pending when the test ends.
Future<void> _release(final WidgetTester tester) async
{
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump();
}

/// A controller for a drawing area of [_drawingArea], with the canvas fitted into it.
Future<CanvasController> _controller(final WidgetTester tester) async
{
  final CanvasController controller = CanvasController(selectionPulse: ValueNotifier<double>(1.0));
  controller.viewportSizeChanged(size: _drawingArea);
  await _nextFrame(tester);
  return controller;
}

/// Without a widget tree nothing asks for a frame, and post frame callbacks wait for one.
Future<void> _nextFrame(final WidgetTester tester) async
{
  WidgetsBinding.instance.scheduleFrame();
  await tester.pump();
}

/// The middle of the canvas pixel [pixel] in the drawing area.
Offset _screenPosition({required final CanvasViewport viewport, required final CoordinateSetI pixel})
{
  final ViewState viewState = GetIt.I.get<ViewState>();
  final double pixelSize = viewState.zoomFactor / viewState.devicePixelRatio;
  return viewport.offset.value + Offset((pixel.x + 0.5) * pixelSize, (pixel.y + 0.5) * pixelSize);
}

void main()
{
  group("viewport", ()
  {
    testWidgets("zooming around a point keeps the part of the canvas under it in place", (final WidgetTester tester) async
    {
      await _boot(tester);
      final ViewState viewState = GetIt.I.get<ViewState>();
      final CanvasViewport viewport = CanvasViewport(viewState: viewState, canvasState: GetIt.I.get<CanvasState>());
      viewport.resize(newSize: _drawingArea);
      viewState.setZoomLevel(val: 10);
      viewport.setOffset(newOffset: const Offset(100, 50));
      //a point inside the canvas, so the zoom does not run into the clamping
      const Offset focus = Offset(310.5, 205.25);
      final Offset before = (focus - viewport.offset.value) / viewState.zoomFactor.toDouble();
      final int zoomBefore = viewState.zoomFactor;

      viewport.zoomAround(focus: focus, zoom: viewState.increaseZoomLevel);

      expect(viewState.zoomFactor, greaterThan(zoomBefore));
      final Offset after = (focus - viewport.offset.value) / viewState.zoomFactor.toDouble();
      expect(after.dx, closeTo(before.dx, 1e-9));
      expect(after.dy, closeTo(before.dy, 1e-9));
      await _release(tester);
    });

    testWidgets("the canvas cannot be pushed out of the drawing area", (final WidgetTester tester) async
    {
      await _boot(tester);
      final ViewState viewState = GetIt.I.get<ViewState>();
      final CanvasViewport viewport = CanvasViewport(viewState: viewState, canvasState: GetIt.I.get<CanvasState>());
      viewport.resize(newSize: _drawingArea);

      viewport.setOffset(newOffset: const Offset(100000, -100000));

      //a tenth of the drawing area keeps showing the canvas
      expect(viewport.offset.value.dx, _drawingArea.width * 0.9);
      expect(viewport.offset.value.dy, -(24 * viewState.zoomFactor / viewState.devicePixelRatio) + _drawingArea.height * 0.1);
      await _release(tester);
    });

    testWidgets("the optimal zoom is the largest that fits the canvas, centred", (final WidgetTester tester) async
    {
      await _boot(tester);
      final ViewState viewState = GetIt.I.get<ViewState>();
      final CanvasViewport viewport = CanvasViewport(viewState: viewState, canvasState: GetIt.I.get<CanvasState>());
      viewport.resize(newSize: _drawingArea);

      viewport.requestOptimalZoom();

      final int zoom = viewState.zoomFactor;
      expect(32 * zoom < _drawingArea.width && 24 * zoom < _drawingArea.height, isTrue);
      expect(32 * (zoom + 1) < _drawingArea.width && 24 * (zoom + 1) < _drawingArea.height, isFalse);
      expect(viewport.offset.value, Offset((_drawingArea.width - 32 * zoom) / 2, (_drawingArea.height - 24 * zoom) / 2));
      await _release(tester);
    });
  });

  group("controller", ()
  {
    testWidgets("the wheel zooms, and with control held it changes the tool size", (final WidgetTester tester) async
    {
      await _boot(tester);
      final CanvasController controller = await _controller(tester);
      final ViewState viewState = GetIt.I.get<ViewState>();
      final ToolState toolState = GetIt.I.get<ToolState>();
      final int zoom = viewState.zoomFactor;

      controller.pointerSignal(ev: const PointerScrollEvent(position: Offset(400, 300), scrollDelta: Offset(0, -20)));
      expect(viewState.zoomFactor, greaterThan(zoom));

      final int size = toolState.getCurrentToolSize();
      GetIt.I.get<HotkeyManager>().controlNotifier.value = true;
      controller.pointerSignal(ev: const PointerScrollEvent(position: Offset(400, 300), scrollDelta: Offset(0, -20)));
      GetIt.I.get<HotkeyManager>().controlNotifier.value = false;
      expect(toolState.getCurrentToolSize(), size + 1);

      controller.dispose();
      await _release(tester);
    });

    testWidgets("a right click picks the color under the cursor and goes back to the tool", (final WidgetTester tester) async
    {
      await _boot(tester);
      final CanvasController controller = await _controller(tester);
      final ToolState toolState = GetIt.I.get<ToolState>();
      toolState.setToolSelection(tool: ToolType.pencil);
      final CoordinateSetI pixel = CoordinateSetI(x: 10, y: 8);
      final ColorReference? expected = (GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState).getDataEntry(coord: pixel);
      expect(expected, isNotNull, reason: "setup");
      final Offset position = _screenPosition(viewport: controller.viewport, pixel: pixel);

      controller.pointerDown(details: PointerDownEvent(kind: PointerDeviceKind.mouse, buttons: kSecondaryButton, position: position));
      expect(toolState.selectedTool, ToolType.pick);
      controller.pointerUp(details: PointerUpEvent(kind: PointerDeviceKind.mouse, position: position));

      expect(GetIt.I.get<PaletteState>().selectedColor, expected);
      expect(toolState.selectedTool, ToolType.pencil);
      controller.dispose();
      await _release(tester);
    });

    testWidgets("a tap of the stylus button turns the shading direction around while shading", (final WidgetTester tester) async
    {
      await _boot(tester);
      final CanvasController controller = await _controller(tester);
      final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
      shaderOptions.isEnabled.value = true;
      final ShaderDirection direction = shaderOptions.shaderDirection.value;
      const Offset position = Offset(400, 300);

      controller.pointerHover(details: const PointerHoverEvent(kind: PointerDeviceKind.stylus, buttons: kSecondaryButton, position: position, timeStamp: Duration(seconds: 1)));
      controller.pointerHover(details: const PointerHoverEvent(kind: PointerDeviceKind.stylus, position: position, timeStamp: Duration(seconds: 2)));

      expect(shaderOptions.shaderDirection.value, isNot(direction));
      controller.dispose();
      await _release(tester);
    });
  });

  group("a mouse", ()
  {
    _inputTest("draws with the primary button, and the stroke becomes an undo step", (final WidgetTester tester, final CanvasController controller) async
    {
      final ColorReference color = _palette.selectedColor!;

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 10, y: 8), _at(controller: controller, x: 12, y: 8)]);
      await tester.runAsync(settle);

      for (int x = 10; x <= 12; x++)
      {
        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: x, y: 8)), color, reason: "at $x");
      }
      expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 13, y: 8)), isNot(color));

      _frame(controller);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.toolPen);
    });

    _inputTest("gets a stroke into the history right before undoing it", (final WidgetTester tester, final CanvasController controller) async
    {
      final CoordinateSetI pixel = CoordinateSetI(x: 10, y: 8);
      final ColorReference? before = _drawing.getDataEntry(coord: pixel);
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 10, y: 8), _at(controller: controller, x: 11, y: 8)]);
      await tester.runAsync(settle);
      _frame(controller);
      expect(controller.painter.toolPainter!.hasHistoryData, isTrue, reason: "setup: the poll did not run yet");

      await _undoStep(tester);

      expect(controller.painter.toolPainter!.hasHistoryData, isFalse);
      expect(_drawing.getDataEntry(coord: pixel), before);
    });

    _inputTest("ends the stroke when the pointer is cancelled", (final WidgetTester tester, final CanvasController controller) async
    {
      final ColorReference color = _palette.selectedColor!;
      final Offset start = _at(controller: controller, x: 10, y: 8);
      final Offset end = _at(controller: controller, x: 12, y: 8);
      final Offset away = _at(controller: controller, x: 20, y: 20);
      controller.pointerHover(details: _hover(at: start));
      _frame(controller);
      controller.pointerDown(details: _press(at: start));
      _frame(controller);
      controller.pointerMove(details: _move(at: end));
      _frame(controller);

      controller.pointerCancel(details: _cancel(at: end));
      _frame(controller);
      await tester.runAsync(settle);
      controller.pointerHover(details: _hover(at: away));
      _frame(controller);
      await tester.runAsync(settle);

      expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 12, y: 8)), color, reason: "what was drawn stays");
      expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 20, y: 20)), isNot(color), reason: "and nothing is drawn afterwards");
    });

    _inputTest("pans with the middle button and gives the cursor back afterwards", (final WidgetTester tester, final CanvasController controller) async
    {
      final MouseCursor cursor = controller.mouseCursor.value;
      final Offset start = controller.viewport.offset.value;

      controller.pointerDown(details: _press(at: const Offset(400, 300), buttons: kTertiaryButton));
      expect(controller.mouseCursor.value, SystemMouseCursors.move);

      controller.pointerMove(details: _move(at: const Offset(430, 280), buttons: kTertiaryButton));
      expect(controller.viewport.offset.value, start + const Offset(30, -20));

      controller.pointerUp(details: _lift(at: const Offset(430, 280)));
      expect(controller.mouseCursor.value, cursor);

      controller.pointerHover(details: _hover(at: const Offset(500, 300)));
      expect(controller.viewport.offset.value, start + const Offset(30, -20));
    });

    _inputTest("takes the cursor along when it leaves", (final WidgetTester tester, final CanvasController controller) async
    {
      controller.pointerHover(details: _hover(at: _at(controller: controller, x: 3, y: 4)));
      expect(_cursorPixel(controller), CoordinateSetI(x: 3, y: 4));

      controller.mouseExit();

      expect(_cursorPixel(controller), isNull);
    });

    _inputTest("turns the shading around with the secondary button while shading", (final WidgetTester tester, final CanvasController controller) async
    {
      _shader.isEnabled.value = true;
      _tools.setToolSelection(tool: ToolType.pencil);
      final ShaderDirection direction = _shader.shaderDirection.value;
      final ColorReference color = _palette.selectedColor!;
      const Offset position = Offset(400, 300);

      controller.pointerDown(details: _press(at: position, buttons: kSecondaryButton));
      expect(_tools.selectedTool, ToolType.pencil, reason: "shading does not pick");
      controller.pointerUp(details: _lift(at: position));

      expect(_shader.shaderDirection.value, isNot(direction));
      expect(_palette.selectedColor, color);
      expect(_tools.selectedTool, ToolType.pencil);
    });

    _inputTest("picks nothing with the secondary button outside of the canvas", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.pencil);
      final ColorReference color = _palette.selectedColor!;
      controller.viewport.setOffset(newOffset: const Offset(500, 300));
      const Offset outside = Offset(100, 100);

      controller.pointerDown(details: _press(at: outside, buttons: kSecondaryButton));
      controller.pointerUp(details: _lift(at: outside));

      expect(_palette.selectedColor, color);
      expect(_tools.selectedTool, ToolType.pencil);
    });

    _inputTest("survives the shading being turned off while the secondary button is down", (final WidgetTester tester, final CanvasController controller) async
    {
      _shader.isEnabled.value = true;
      _tools.setToolSelection(tool: ToolType.pencil);
      final ShaderDirection direction = _shader.shaderDirection.value;
      final ColorReference color = _palette.selectedColor!;
      const Offset position = Offset(400, 300);
      controller.pointerDown(details: _press(at: position, buttons: kSecondaryButton));

      _shader.isEnabled.value = false;
      controller.pointerUp(details: _lift(at: position));

      expect(_tools.selectedTool, ToolType.pencil);
      expect(_palette.selectedColor, color, reason: "the press was going to shade, not to pick");
      expect(_shader.shaderDirection.value, isNot(direction));
    });

    _inputTest("does not stay on the pick tool when the shading is turned on while the secondary button is down", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.pencil);
      const Offset position = Offset(400, 300);
      controller.pointerDown(details: _press(at: position, buttons: kSecondaryButton));
      expect(_tools.selectedTool, ToolType.pick, reason: "setup");

      _shader.isEnabled.value = true;
      controller.pointerUp(details: _lift(at: position));

      expect(_tools.selectedTool, ToolType.pencil);
    });
  });

  group("the tools that select", ()
  {
    Set<CoordinateSetI> selected()
    {
      return <CoordinateSetI>{
        for (int x = 0; x < 32; x++)
          for (int y = 0; y < 24; y++)
            if (_selection.selection.contains(coord: CoordinateSetI(x: x, y: y))) CoordinateSetI(x: x, y: y),
      };
    }

    _inputTest("drag out a box", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.select);
      _selectOptions.shape.value = SelectShape.rectangle;

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 2, y: 2), _at(controller: controller, x: 4, y: 3)]);

      expect(selected(), <CoordinateSetI>{
        for (int x = 2; x <= 4; x++)
          for (int y = 2; y <= 3; y++) CoordinateSetI(x: x, y: y),
      });
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionNew);
    });

    _inputTest("drag out an ellipse", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.select);
      _selectOptions.shape.value = SelectShape.ellipse;

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 2, y: 2), _at(controller: controller, x: 10, y: 10)]);

      expect(_selection.selection.contains(coord: CoordinateSetI(x: 6, y: 6)), isTrue);
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 2, y: 2)), isFalse, reason: "the corner of the box is outside");
    });

    _inputTest("pick a same-colored area with the wand", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.select);
      _selectOptions.shape.value = SelectShape.wand;

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 5, y: 1)]);

      //the pattern has blocks of four by three pixels
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 4, y: 0)), isTrue);
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 7, y: 2)), isTrue);
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 8, y: 0)), isFalse);
    });

    _inputTest("close a polygon on its first corner", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.select);
      _selectOptions.shape.value = SelectShape.polygon;
      final List<Offset> corners = <Offset>[
        _at(controller: controller, x: 2, y: 2),
        _at(controller: controller, x: 8, y: 2),
        _at(controller: controller, x: 8, y: 8),
        _at(controller: controller, x: 2, y: 2),
      ];

      for (final Offset corner in corners)
      {
        _dragAlong(controller: controller, path: <Offset>[corner]);
      }
      expect(_selection.selection.isEmpty, isTrue, reason: "it is created by the next event after the painter noticed");
      controller.pointerHover(details: _hover(at: corners.first));

      expect(_selection.selection.contains(coord: CoordinateSetI(x: 7, y: 3)), isTrue);
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 3, y: 7)), isFalse);
      final SelectionPainter painter = controller.painter.toolPainterMap[ToolType.select]! as SelectionPainter;
      expect(painter.polygonPoints, isEmpty);
    });
  });

  group("the color pick tool", ()
  {
    _inputTest("takes the color it was used on and goes back to drawing", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.line);
      _tools.setToolSelection(tool: ToolType.pick);
      final ColorReference? expected = _drawing.getDataEntry(coord: CoordinateSetI(x: 13, y: 7));
      final Offset position = _at(controller: controller, x: 13, y: 7);

      _dragAlong(controller: controller, path: <Offset>[position]);
      controller.pointerHover(details: _hover(at: position));

      expect(_palette.selectedColor, expected);
      expect(_tools.selectedTool, ToolType.line);
    });
  });

  group("a stylus", ()
  {
    const PointerDeviceKind stylus = PointerDeviceKind.stylus;

    _inputTest("picks the color under it with a tap of its button", (final WidgetTester tester, final CanvasController controller) async
    {
      final ColorReference? expected = _drawing.getDataEntry(coord: CoordinateSetI(x: 13, y: 7));
      final Offset position = _at(controller: controller, x: 13, y: 7);

      controller.pointerHover(details: _hover(at: position, kind: stylus, button: true));
      controller.pointerHover(details: _hover(at: position, kind: stylus));

      expect(_palette.selectedColor, expected);
    });

    _inputTest("ignores its button during a stroke", (final WidgetTester tester, final CanvasController controller) async
    {
      _shader.isEnabled.value = true;
      final ShaderDirection direction = _shader.shaderDirection.value;
      const Offset position = Offset(400, 300);
      controller.pointerDown(details: _press(at: position, kind: stylus));

      controller.pointerMove(details: _move(at: position, kind: stylus, buttons: kPrimaryButton | kSecondaryButton));
      controller.pointerMove(details: _move(at: position, kind: stylus));
      controller.pointerUp(details: _lift(at: position, kind: stylus));

      expect(_shader.shaderDirection.value, direction);
      await tester.pump(const Duration(milliseconds: 200));
    });

    group("with its button held long", ()
    {
      _inputTest("zooms when moved up and down, from where it started", (final WidgetTester tester, final CanvasController controller) async
      {
        const Offset position = Offset(400, 300);
        await _holdStylusButton(tester: tester, controller: controller, at: position);
        final int zoom = _view.zoomFactor;

        controller.pointerHover(details: _hover(at: position - const Offset(0, 30), kind: stylus, button: true));
        expect(_view.zoomFactor, zoom + 3);

        controller.pointerHover(details: _hover(at: position + const Offset(0, 20), kind: stylus, button: true));
        expect(_view.zoomFactor, zoom - 2);

        controller.pointerHover(details: _hover(at: position, kind: stylus));
        controller.pointerHover(details: _hover(at: position - const Offset(0, 50), kind: stylus));
        expect(_view.zoomFactor, zoom - 2, reason: "over with the button released");
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("changes the tool size when moved sideways, from where it started", (final WidgetTester tester, final CanvasController controller) async
      {
        _tools.setToolSelection(tool: ToolType.pencil);
        _tools.setToolSize(0, 5);
        const Offset position = Offset(400, 300);
        await _holdStylusButton(tester: tester, controller: controller, at: position);

        controller.pointerHover(details: _hover(at: position + const Offset(10, 0), kind: stylus, button: true));
        expect(_tools.getCurrentToolSize(), 7);

        controller.pointerHover(details: _hover(at: position - const Offset(10, 0), kind: stylus, button: true));
        expect(_tools.getCurrentToolSize(), 3);

        controller.pointerHover(details: _hover(at: position, kind: stylus));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("stays with the direction it started in", (final WidgetTester tester, final CanvasController controller) async
      {
        _tools.setToolSelection(tool: ToolType.pencil);
        _tools.setToolSize(0, 5);
        const Offset position = Offset(400, 300);
        await _holdStylusButton(tester: tester, controller: controller, at: position);
        final int zoom = _view.zoomFactor;

        controller.pointerHover(details: _hover(at: position - const Offset(0, 30), kind: stylus, button: true));
        controller.pointerHover(details: _hover(at: position - const Offset(40, 30), kind: stylus, button: true));

        expect(_tools.getCurrentToolSize(), 5);
        expect(_view.zoomFactor, zoom + 3);

        controller.pointerHover(details: _hover(at: position, kind: stylus));
        await tester.pump(const Duration(milliseconds: 200));
      });

      for (final LayerKind kind in <LayerKind>[LayerKind.shading, LayerKind.dither])
      {
        _inputTest("changes the tool size from where it is on a ${kind.name} layer too", (final WidgetTester tester, final CanvasController controller) async
        {
          _layers.addNewLayer(layerType: kind, select: true, addToHistoryStack: false);
          await tester.runAsync(settle);
          _tools.setToolSelection(tool: ToolType.pencil);
          _tools.setToolSize(0, 5);
          const Offset position = Offset(400, 300);
          await _holdStylusButton(tester: tester, controller: controller, at: position);

          controller.pointerHover(details: _hover(at: position + const Offset(10, 0), kind: stylus, button: true));

          expect(_tools.getCurrentToolSize(), 7);
          controller.pointerHover(details: _hover(at: position, kind: stylus));
          await tester.pump(const Duration(milliseconds: 200));
        });
      }

      _inputTest("zooms a reference layer, as one undo step", (final WidgetTester tester, final CanvasController controller) async
      {
        final ReferenceLayerState reference = _addReferenceLayer();
        await tester.runAsync(settle);
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);
        final int slider = reference.zoomSliderValue;
        const Offset position = Offset(400, 300);
        await _holdStylusButton(tester: tester, controller: controller, at: position);

        controller.pointerHover(details: _hover(at: position + const Offset(10, 0), kind: stylus, button: true));
        expect(reference.zoomSliderValue, slider + 2);
        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.generic, reason: "not before it is released");

        controller.pointerHover(details: _hover(at: position + const Offset(10, 0), kind: stylus));
        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerSettingsChange);
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not pick anything once it was held longer than a tap may take", (final WidgetTester tester, final CanvasController controller) async
      {
        _stylusPrefs.stylusPickMaxDuration.value = _stylusPrefs.stylusPickMaxDuration.min;
        final ColorReference color = _palette.selectedColor!;
        final Offset position = _at(controller: controller, x: 13, y: 7);

        controller.pointerHover(details: _hover(at: position, kind: stylus, button: true));
        await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: _stylusPrefs.stylusPickMaxDuration.min + 20)));
        controller.pointerHover(details: _hover(at: position, kind: stylus));

        expect(_palette.selectedColor, color);
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not pick anything after zooming", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final Offset position = _at(controller: controller, x: 13, y: 7);
        await _holdStylusButton(tester: tester, controller: controller, at: position);
        controller.pointerHover(details: _hover(at: position - const Offset(0, 30), kind: stylus, button: true));

        controller.pointerHover(details: _hover(at: position - const Offset(0, 30), kind: stylus));

        expect(_palette.selectedColor, color);
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("still picks when it was not moved and released in time", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference? expected = _drawing.getDataEntry(coord: CoordinateSetI(x: 13, y: 7));
        final Offset position = _at(controller: controller, x: 13, y: 7);
        await _holdStylusButton(tester: tester, controller: controller, at: position);

        controller.pointerHover(details: _hover(at: position, kind: stylus));

        expect(_palette.selectedColor, expected);
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("follows a new delay from the preferences", (final WidgetTester tester, final CanvasController controller) async
      {
        _stylusPrefs.stylusLongPressDelay.value = _stylusPrefs.stylusLongPressDelay.min;
        const Offset position = Offset(400, 300);
        final int zoom = _view.zoomFactor;

        await _holdStylusButton(tester: tester, controller: controller, at: position, milliseconds: 80);
        controller.pointerHover(details: _hover(at: position - const Offset(0, 30), kind: stylus, button: true));

        expect(_view.zoomFactor, zoom + 3);
        controller.pointerHover(details: _hover(at: position, kind: stylus));
        await tester.pump(const Duration(milliseconds: 200));
      });
    });

    group("moved with its button before the long press", ()
    {
      _inputTest("pans and gives the cursor back afterwards", (final WidgetTester tester, final CanvasController controller) async
      {
        final MouseCursor cursor = controller.mouseCursor.value;
        final Offset start = controller.viewport.offset.value;
        const Offset position = Offset(400, 300);

        controller.pointerHover(details: _hover(at: position, kind: stylus, button: true));
        controller.pointerHover(details: _hover(at: position + const Offset(20, 0), kind: stylus, button: true));
        expect(controller.mouseCursor.value, SystemMouseCursors.move);
        expect(controller.viewport.offset.value, start, reason: "the pan starts where the long press was given up");

        controller.pointerHover(details: _hover(at: position + const Offset(30, 10), kind: stylus, button: true));
        expect(controller.viewport.offset.value, start + const Offset(10, 10));

        controller.pointerHover(details: _hover(at: position + const Offset(30, 10), kind: stylus));
        expect(controller.mouseCursor.value, cursor);

        await tester.pump(const Duration(milliseconds: 200));
        controller.pointerHover(details: _hover(at: position + const Offset(60, 10), kind: stylus));
        expect(controller.viewport.offset.value, start + const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not turn the shading around", (final WidgetTester tester, final CanvasController controller) async
      {
        _shader.isEnabled.value = true;
        final ShaderDirection direction = _shader.shaderDirection.value;
        const Offset position = Offset(400, 300);

        controller.pointerHover(details: _hover(at: position, kind: stylus, button: true));
        controller.pointerHover(details: _hover(at: position + const Offset(20, 0), kind: stylus, button: true));
        controller.pointerHover(details: _hover(at: position + const Offset(40, 0), kind: stylus));

        expect(_shader.shaderDirection.value, direction);
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not pick anything", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final Offset position = _at(controller: controller, x: 13, y: 7);

        controller.pointerHover(details: _hover(at: position, kind: stylus, button: true));
        controller.pointerHover(details: _hover(at: position + const Offset(20, 0), kind: stylus, button: true));
        controller.pointerHover(details: _hover(at: position + const Offset(40, 0), kind: stylus));

        expect(_palette.selectedColor, color);
        await tester.pump(const Duration(milliseconds: 200));
      });
    });

    group("and its cursor", ()
    {
      _inputTest("goes away soon after the last hover", (final WidgetTester tester, final CanvasController controller) async
      {
        controller.pointerHover(details: _hover(at: _at(controller: controller, x: 3, y: 4), kind: stylus));
        expect(_cursorPixel(controller), CoordinateSetI(x: 3, y: 4));

        await tester.pump(const Duration(milliseconds: 90));
        expect(_cursorPixel(controller), isNotNull);

        await tester.pump(const Duration(milliseconds: 20));
        expect(_cursorPixel(controller), isNull);
      });

      _inputTest("stays while the stylus touches the screen", (final WidgetTester tester, final CanvasController controller) async
      {
        final Offset position = _at(controller: controller, x: 3, y: 4);
        controller.pointerDown(details: _press(at: position, kind: stylus));

        await tester.pump(const Duration(milliseconds: 500));
        expect(_cursorPixel(controller), isNotNull);

        controller.pointerUp(details: _lift(at: position, kind: stylus));
        await tester.pump(const Duration(milliseconds: 90));
        expect(_cursorPixel(controller), isNotNull);

        await tester.pump(const Duration(milliseconds: 20));
        expect(_cursorPixel(controller), isNull);
      });

      _inputTest("goes away right after a reported hover exit, and stays longer from then on", (final WidgetTester tester, final CanvasController controller) async
      {
        final Offset position = _at(controller: controller, x: 3, y: 4);
        final StylusBridge bridge = GetIt.I.get<StylusBridge>();
        controller.pointerHover(details: _hover(at: position, kind: stylus));

        bridge.onHoverExit!(timeStamp: const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 60));
        expect(_cursorPixel(controller), isNull);

        controller.pointerHover(details: _hover(at: position, kind: stylus, time: const Duration(seconds: 4)));
        expect(_cursorPixel(controller), isNull, reason: "that event was sent before the exit");

        controller.pointerHover(details: _hover(at: position, kind: stylus, time: const Duration(seconds: 6)));
        await tester.pump(const Duration(milliseconds: 900));
        expect(_cursorPixel(controller), isNotNull, reason: "exits are reported now, so no need to hurry");

        await tester.pump(const Duration(milliseconds: 200));
        expect(_cursorPixel(controller), isNull);
      });

      _inputTest("takes a button along that can no longer be released", (final WidgetTester tester, final CanvasController controller) async
      {
        _shader.isEnabled.value = true;
        final ShaderDirection direction = _shader.shaderDirection.value;
        const Offset position = Offset(400, 300);
        controller.pointerHover(details: _hover(at: position, kind: stylus, button: true));

        await tester.pump(const Duration(milliseconds: 300));

        expect(_shader.shaderDirection.value, direction, reason: "going away is not a tap");
        final int zoom = _view.zoomFactor;
        controller.pointerHover(details: _hover(at: position - const Offset(0, 50), kind: stylus));
        expect(_view.zoomFactor, zoom, reason: "and no long press is left behind");
        await tester.pump(const Duration(milliseconds: 200));
      });
    });

    _inputTest("that is cancelled lets go of its button", (final WidgetTester tester, final CanvasController controller) async
    {
      const Offset position = Offset(400, 300);
      controller.pointerDown(details: _press(at: position, kind: stylus, pointer: 5, buttons: kPrimaryButton | kSecondaryButton));

      controller.pointerCancel(details: _cancel(at: position, kind: stylus, pointer: 5));
      await tester.pump(const Duration(milliseconds: 300));

      final int zoom = _view.zoomFactor;
      controller.pointerHover(details: _hover(at: position - const Offset(0, 50), kind: stylus));
      expect(_view.zoomFactor, zoom);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  group("touch", ()
  {
    const PointerDeviceKind touch = PointerDeviceKind.touch;
    const int singleTouchDelay = 60;

    _inputTest("with one finger draws once the delay has passed, from where it started", (final WidgetTester tester, final CanvasController controller) async
    {
      final ColorReference color = _palette.selectedColor!;
      final Offset start = _at(controller: controller, x: 10, y: 8);
      final Offset end = _at(controller: controller, x: 12, y: 8);
      controller.pointerDown(details: _press(at: start, kind: touch));
      _frame(controller);

      await tester.pump(const Duration(milliseconds: singleTouchDelay));
      _frame(controller);
      controller.pointerMove(details: _move(at: end, kind: touch));
      _frame(controller);
      controller.pointerUp(details: _lift(at: end, kind: touch));
      _frame(controller);
      await tester.runAsync(settle);

      for (int x = 10; x <= 12; x++)
      {
        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: x, y: 8)), color, reason: "at $x");
      }
      await tester.pump(const Duration(milliseconds: 200));
    });

    _inputTest("draws nothing when it is over before the delay", (final WidgetTester tester, final CanvasController controller) async
    {
      final CoordinateSetI pixel = CoordinateSetI(x: 10, y: 8);
      final ColorReference? before = _drawing.getDataEntry(coord: pixel);
      final Offset position = _at(controller: controller, x: 10, y: 8);

      controller.pointerDown(details: _press(at: position, kind: touch));
      _frame(controller);
      controller.pointerUp(details: _lift(at: position, kind: touch));
      _frame(controller);
      await tester.pump(const Duration(milliseconds: singleTouchDelay));
      _frame(controller);
      await tester.runAsync(settle);

      expect(_drawing.getDataEntry(coord: pixel), before);
      await tester.pump(const Duration(milliseconds: 200));
    });

    group("with two fingers", ()
    {
      Future<(Offset, Offset)> putDown({required final WidgetTester tester, required final CanvasController controller}) async
      {
        const Offset first = Offset(300, 300);
        const Offset second = Offset(500, 300);
        controller.pointerDown(details: _press(at: first, kind: touch));
        controller.pointerDown(details: _press(at: second, kind: touch, pointer: 2));
        return (first, second);
      }

      _inputTest("draws nothing, however long they stay", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);
        _frame(controller);
        await tester.pump(const Duration(milliseconds: singleTouchDelay));
        _frame(controller);

        controller.pointerUp(details: _lift(at: first, kind: touch));
        _frame(controller);
        controller.pointerUp(details: _lift(at: second, kind: touch, pointer: 2));
        _frame(controller);
        await tester.runAsync(settle);

        final CoordinateSetI under = controller.viewport.pixelAt(position: CoordinateSetD(x: first.dx, y: first.dy));
        expect(_drawing.getDataEntry(coord: under), isNot(color));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("pans with their center", (final WidgetTester tester, final CanvasController controller) async
      {
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);
        final Offset start = controller.viewport.offset.value;
        final int zoom = _view.zoomFactor;
        expect(controller.mouseCursor.value, SystemMouseCursors.move);

        controller.pointerMove(details: _move(at: first + const Offset(10, 0), kind: touch));
        controller.pointerMove(details: _move(at: second + const Offset(10, 0), kind: touch, pointer: 2));

        expect(controller.viewport.offset.value.dx, greaterThan(start.dx));
        expect(_view.zoomFactor, zoom, reason: "they are as far apart as they were");
        controller.pointerUp(details: _lift(at: first, kind: touch));
        controller.pointerUp(details: _lift(at: second, kind: touch, pointer: 2));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("zooms with the distance between them", (final WidgetTester tester, final CanvasController controller) async
      {
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);
        final int zoom = _view.zoomFactor;

        controller.pointerMove(details: _move(at: second + const Offset(50, 0), kind: touch, pointer: 2));
        expect(_view.zoomFactor, zoom + 2);

        controller.pointerMove(details: _move(at: second - const Offset(25, 0), kind: touch, pointer: 2));
        expect(_view.zoomFactor, zoom - 1);
        controller.pointerUp(details: _lift(at: first, kind: touch));
        controller.pointerUp(details: _lift(at: second, kind: touch, pointer: 2));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("stops panning when the first of them is lifted, and the other does not start to draw", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);
        controller.pointerUp(details: _lift(at: first, kind: touch));
        final Offset start = controller.viewport.offset.value;
        _frame(controller);

        await tester.pump(const Duration(milliseconds: singleTouchDelay));
        final Offset moved = second - const Offset(100, 0);
        controller.pointerMove(details: _move(at: moved, kind: touch, pointer: 2));
        _frame(controller);
        controller.pointerUp(details: _lift(at: moved, kind: touch, pointer: 2));
        _frame(controller);
        await tester.runAsync(settle);

        expect(controller.viewport.offset.value, start);
        final CoordinateSetI under = controller.viewport.pixelAt(position: CoordinateSetD(x: moved.dx, y: moved.dy));
        expect(_drawing.getDataEntry(coord: under), isNot(color));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("stops panning when one of them is cancelled", (final WidgetTester tester, final CanvasController controller) async
      {
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);
        controller.pointerCancel(details: _cancel(at: second, kind: touch, pointer: 2));
        final Offset start = controller.viewport.offset.value;

        controller.pointerMove(details: _move(at: first + const Offset(40, 0), kind: touch));

        expect(controller.viewport.offset.value, start);
        controller.pointerUp(details: _lift(at: first + const Offset(40, 0), kind: touch));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("gives the mouse cursor back when one of them is cancelled", (final WidgetTester tester, final CanvasController controller) async
      {
        final MouseCursor cursor = controller.mouseCursor.value;
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);

        controller.pointerCancel(details: _cancel(at: second, kind: touch, pointer: 2));

        expect(controller.mouseCursor.value, cursor);
        controller.pointerUp(details: _lift(at: first, kind: touch));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("gives the mouse cursor back afterwards", (final WidgetTester tester, final CanvasController controller) async
      {
        final MouseCursor cursor = controller.mouseCursor.value;
        final (Offset first, Offset second) = await putDown(tester: tester, controller: controller);

        controller.pointerUp(details: _lift(at: first, kind: touch));
        controller.pointerUp(details: _lift(at: second, kind: touch, pointer: 2));

        expect(controller.mouseCursor.value, cursor);
        await tester.pump(const Duration(milliseconds: 200));
      });
    });

    group("next to a stylus", ()
    {
      const PointerDeviceKind stylus = PointerDeviceKind.stylus;

      _inputTest("does not take over its stroke", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final Offset start = _at(controller: controller, x: 10, y: 8);
        final Offset end = _at(controller: controller, x: 12, y: 8);
        final Offset palm = _at(controller: controller, x: 20, y: 20);
        controller.pointerDown(details: _press(at: start, kind: stylus));
        _frame(controller);

        controller.pointerDown(details: _press(at: palm, kind: touch, pointer: 2));
        await tester.pump(const Duration(milliseconds: singleTouchDelay));
        _frame(controller);

        controller.pointerCancel(details: _cancel(at: palm, kind: touch, pointer: 2));
        controller.pointerMove(details: _move(at: end, kind: stylus));
        _frame(controller);
        controller.pointerUp(details: _lift(at: end, kind: stylus));
        _frame(controller);
        await tester.runAsync(settle);

        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 12, y: 8)), color, reason: "the stroke went on after the palm was rejected");
        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 20, y: 20)), isNot(color));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not end its stroke when it is lifted", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final Offset start = _at(controller: controller, x: 10, y: 8);
        final Offset end = _at(controller: controller, x: 12, y: 8);
        final Offset palm = _at(controller: controller, x: 20, y: 20);
        controller.pointerDown(details: _press(at: start, kind: stylus));
        _frame(controller);
        controller.pointerDown(details: _press(at: palm, kind: touch, pointer: 2));
        _frame(controller);

        controller.pointerUp(details: _lift(at: palm, kind: touch, pointer: 2));
        _frame(controller);
        controller.pointerMove(details: _move(at: end, kind: stylus));
        _frame(controller);
        controller.pointerUp(details: _lift(at: end, kind: stylus));
        _frame(controller);
        await tester.runAsync(settle);

        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 12, y: 8)), color);
        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 20, y: 20)), isNot(color));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not move its stroke, or the canvas, however many fingers there are", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final Offset start = _at(controller: controller, x: 10, y: 8);
        final Offset palm = _at(controller: controller, x: 20, y: 20);
        final Offset view = controller.viewport.offset.value;
        final int zoom = _view.zoomFactor;
        controller.pointerDown(details: _press(at: start, kind: stylus));
        _frame(controller);

        controller.pointerDown(details: _press(at: palm, kind: touch, pointer: 2));
        controller.pointerDown(details: _press(at: palm + const Offset(100, 0), kind: touch, pointer: 3));
        controller.pointerMove(details: _move(at: palm + const Offset(50, 50), kind: touch, pointer: 2));
        _frame(controller);

        expect(controller.viewport.offset.value, view);
        expect(_view.zoomFactor, zoom);
        expect(controller.mouseCursor.value, isNot(SystemMouseCursors.move));

        controller.pointerUp(details: _lift(at: start, kind: stylus));
        _frame(controller);
        await tester.runAsync(settle);

        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 10, y: 8)), color);
        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 20, y: 20)), isNot(color));
        controller.pointerCancel(details: _cancel(at: palm, kind: touch, pointer: 2));
        controller.pointerCancel(details: _cancel(at: palm, kind: touch, pointer: 3));
        await tester.pump(const Duration(milliseconds: 200));
      });

      _inputTest("does not get in the way when it was there first", (final WidgetTester tester, final CanvasController controller) async
      {
        final ColorReference color = _palette.selectedColor!;
        final Offset start = _at(controller: controller, x: 10, y: 8);
        final Offset end = _at(controller: controller, x: 12, y: 8);
        final Offset palm = _at(controller: controller, x: 20, y: 20);
        controller.pointerDown(details: _press(at: palm, kind: touch, pointer: 2));
        controller.pointerDown(details: _press(at: start, kind: stylus));
        _frame(controller);

        await tester.pump(const Duration(milliseconds: singleTouchDelay));
        _frame(controller);
        controller.pointerCancel(details: _cancel(at: palm, kind: touch, pointer: 2));
        controller.pointerMove(details: _move(at: end, kind: stylus));
        _frame(controller);
        controller.pointerUp(details: _lift(at: end, kind: stylus));
        _frame(controller);
        await tester.runAsync(settle);

        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 12, y: 8)), color, reason: "the stylus draws");
        expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 20, y: 20)), isNot(color), reason: "the palm does not");
        await tester.pump(const Duration(milliseconds: 200));
      });
    });
  });

  group("the wheel", ()
  {
    _inputTest("zooms out when turned down", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;

      controller.pointerSignal(ev: _scroll(dy: 20));

      expect(_view.zoomFactor, zoom - 1);
    });

    _inputTest("does not zoom when it goes sideways", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;

      controller.pointerSignal(ev: _scroll(dy: 0, dx: 20));

      expect(_view.zoomFactor, zoom);
    });

    _inputTest("does nothing with other signals", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;

      controller.pointerSignal(ev: const PointerScrollInertiaCancelEvent());

      expect(_view.zoomFactor, zoom);
    });

    _inputTest("makes the tool smaller with control", (final WidgetTester tester, final CanvasController controller) async
    {
      _tools.setToolSelection(tool: ToolType.pencil);
      _tools.setToolSize(0, 5);
      _hotkeys.controlNotifier.value = true;

      controller.pointerSignal(ev: _scroll(dy: 20));

      expect(_tools.getCurrentToolSize(), 4);
    });

    _inputTest("steps through the layers with shift", (final WidgetTester tester, final CanvasController controller) async
    {
      final DrawingLayerState lower = _drawing;
      final LayerState upper = _layers.addNewLayer(layerType: LayerKind.drawing, select: true).$2!;
      await tester.runAsync(settle);
      _hotkeys.shiftNotifier.value = true;

      controller.pointerSignal(ev: _scroll(dy: 20));
      expect(_timeline.getCurrentLayer(), same(lower));

      controller.pointerSignal(ev: _scroll(dy: -20));
      expect(_timeline.getCurrentLayer(), same(upper));
    });

    _inputTest("moves the layer with shift and control", (final WidgetTester tester, final CanvasController controller) async
    {
      final LayerState upper = _layers.addNewLayer(layerType: LayerKind.drawing, select: true).$2!;
      await tester.runAsync(settle);
      _hotkeys.shiftNotifier.value = true;
      _hotkeys.controlNotifier.value = true;

      controller.pointerSignal(ev: _scroll(dy: 20));
      expect(_timeline.selectedFrame!.layerList.getLayerPosition(state: upper), 1);

      controller.pointerSignal(ev: _scroll(dy: -20));
      expect(_timeline.selectedFrame!.layerList.getLayerPosition(state: upper), 0);
    });

    _inputTest("steps through the colors with alt", (final WidgetTester tester, final CanvasController controller) async
    {
      final List<ColorReference> ramp = _palette.colorRamps[0].references;
      _palette.colorSelected(color: ramp[1], addToHistory: false);
      _hotkeys.altNotifier.value = true;

      controller.pointerSignal(ev: _scroll(dy: 20));
      expect(_palette.selectedColor, ramp[2]);

      controller.pointerSignal(ev: _scroll(dy: -20));
      controller.pointerSignal(ev: _scroll(dy: -20));
      expect(_palette.selectedColor, ramp[0]);
    });

    _inputTest("does nothing with a combination it does not know", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;
      final HistoryState? before = _history.getCurrentState();
      final int size = _tools.getCurrentToolSize();
      _hotkeys.altNotifier.value = true;
      _hotkeys.controlNotifier.value = true;

      controller.pointerSignal(ev: _scroll(dy: 20));

      expect(_view.zoomFactor, zoom);
      expect(_tools.getCurrentToolSize(), size);
      expect(_history.getCurrentState(), same(before));
    });

    for (final (String, void Function(), void Function() Function()) modifier in <(String, void Function(), void Function() Function())>[
      ("control", () {_hotkeys.controlNotifier.value = true;}, () {
        final int size = _tools.getCurrentToolSize();
        return () {expect(_tools.getCurrentToolSize(), size);};
      }),
      ("shift", () {_hotkeys.shiftNotifier.value = true;}, () {
        final LayerState? layer = _timeline.getCurrentLayer();
        return () {expect(_timeline.getCurrentLayer(), same(layer));};
      }),
      ("shift and control", () {
        _hotkeys.shiftNotifier.value = true;
        _hotkeys.controlNotifier.value = true;
      }, () {
        final LayerState layer = _timeline.selectedFrame!.layerList.getLayer(index: 0);
        return () {expect(_timeline.selectedFrame!.layerList.getLayer(index: 0), same(layer));};
      }),
      ("alt", () {_hotkeys.altNotifier.value = true;}, () {
        final ColorReference? color = _palette.selectedColor;
        return () {expect(_palette.selectedColor, color);};
      }),
    ])
    {
      _inputTest("does nothing sideways with ${modifier.$1}", (final WidgetTester tester, final CanvasController controller) async
      {
        _tools.setToolSelection(tool: ToolType.pencil);
        _tools.setToolSize(0, 5);
        _layers.addNewLayer(layerType: LayerKind.drawing, select: true, addToHistoryStack: false);
        await tester.runAsync(settle);
        modifier.$2();
        final void Function() check = modifier.$3();

        controller.pointerSignal(ev: _scroll(dy: 0, dx: 20));

        check();
      });
    }

    group("on a reference layer with control", ()
    {
      _inputTest("zooms it and files that once the wheel rests", (final WidgetTester tester, final CanvasController controller) async
      {
        final ReferenceLayerState reference = _addReferenceLayer();
        await tester.runAsync(settle);
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);
        final int slider = reference.zoomSliderValue;
        _hotkeys.controlNotifier.value = true;

        controller.pointerSignal(ev: _scroll(dy: -20));
        await tester.pump(const Duration(milliseconds: 400));
        controller.pointerSignal(ev: _scroll(dy: -20));
        await tester.pump(const Duration(milliseconds: 400));
        expect(reference.zoomSliderValue, slider + 2);
        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.generic, reason: "the wheel did not rest yet");

        controller.pointerSignal(ev: _scroll(dy: 20));
        expect(reference.zoomSliderValue, slider + 1);
        await tester.pump(const Duration(milliseconds: 600));

        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerSettingsChange);
      });

      _inputTest("files a change right before undoing it", (final WidgetTester tester, final CanvasController controller) async
      {
        final ReferenceLayerState reference = _addReferenceLayer();
        await tester.runAsync(settle);
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);
        final int slider = reference.zoomSliderValue;
        _hotkeys.controlNotifier.value = true;

        controller.pointerSignal(ev: _scroll(dy: -20));
        controller.pointerSignal(ev: _scroll(dy: -20));
        await _undoStep(tester);

        expect((_timeline.getCurrentLayer()! as ReferenceLayerState).zoomSliderValue, slider);
      });

      _inputTest("files the change of the last layer when it goes on with another", (final WidgetTester tester, final CanvasController controller) async
      {
        final ReferenceLayerState first = _addReferenceLayer();
        await tester.runAsync(settle);
        _history.addState(identifier: HistoryStateTypeIdentifier.generic);
        _hotkeys.controlNotifier.value = true;
        controller.pointerSignal(ev: _scroll(dy: -20));

        final ReferenceLayerState second = _addReferenceLayer();
        await tester.runAsync(settle);
        expect(_timeline.getCurrentLayer(), same(second), reason: "setup");
        expect(first.isDisposed, isFalse);
        controller.pointerSignal(ev: _scroll(dy: -20));

        expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerSettingsChange);
        await tester.pump(const Duration(milliseconds: 600));
      });
    });

    _inputTest("leaves a grid layer alone with control", (final WidgetTester tester, final CanvasController controller) async
    {
      _layers.addNewLayer(layerType: LayerKind.grid, select: true, addToHistoryStack: false);
      await tester.runAsync(settle);
      final int size = _tools.getCurrentToolSize();
      final HistoryState? before = _history.getCurrentState();
      _hotkeys.controlNotifier.value = true;

      controller.pointerSignal(ev: _scroll(dy: -20));
      await tester.pump(const Duration(milliseconds: 600));

      expect(_tools.getCurrentToolSize(), size);
      expect(_history.getCurrentState(), same(before));
    });
  });

  group("a trackpad", ()
  {
    _inputTest("pans from its second update on, until it ends", (final WidgetTester tester, final CanvasController controller) async
    {
      final Offset start = controller.viewport.offset.value;
      final int zoom = _view.zoomFactor;

      controller.panZoomUpdate(event: _panZoom(panDelta: const Offset(10, 5)));
      expect(controller.viewport.offset.value, start, reason: "the first update only starts the gesture");

      controller.panZoomUpdate(event: _panZoom(panDelta: const Offset(10, 5)));
      expect(controller.viewport.offset.value, start + const Offset(10, 5));

      controller.panZoomEnd();
      controller.panZoomUpdate(event: _panZoom(panDelta: const Offset(10, 5)));
      expect(controller.viewport.offset.value, start + const Offset(10, 5));
      expect(_view.zoomFactor, zoom);
      controller.panZoomEnd();
    });

    _inputTest("zooms with its scale, from where it started", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;
      controller.panZoomUpdate(event: _panZoom());

      controller.panZoomUpdate(event: _panZoom(scale: 3.1));
      expect(_view.zoomFactor, zoom + 2);

      controller.panZoomUpdate(event: _panZoom(scale: 2.1));
      expect(_view.zoomFactor, zoom + 1);

      controller.panZoomUpdate(event: _panZoom(scale: 0.5));
      expect(_view.zoomFactor, zoom - 1);

      controller.panZoomUpdate(event: _panZoom(scale: 0.25));
      expect(_view.zoomFactor, zoom - 3);
      controller.panZoomEnd();
    });

    _inputTest("keeps panning until the pinch makes a whole step, in both directions", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;
      final Offset start = controller.viewport.offset.value;
      controller.panZoomUpdate(event: _panZoom());

      controller.panZoomUpdate(event: _panZoom(scale: 1.9, panDelta: const Offset(4, 0)));
      controller.panZoomUpdate(event: _panZoom(scale: 0.6, panDelta: const Offset(4, 0)));

      expect(_view.zoomFactor, zoom);
      expect(controller.viewport.offset.value, start + const Offset(8, 0));
      controller.panZoomEnd();
    });

    _inputTest("does not zoom out from the slightest pinch", (final WidgetTester tester, final CanvasController controller) async
    {
      final int zoom = _view.zoomFactor;
      final Offset start = controller.viewport.offset.value;
      controller.panZoomUpdate(event: _panZoom());

      controller.panZoomUpdate(event: _panZoom(scale: 0.99, panDelta: const Offset(10, 5)));

      expect(_view.zoomFactor, zoom);
      expect(controller.viewport.offset.value, start + const Offset(10, 5));
      controller.panZoomEnd();
    });

    _inputTest("does not zoom without a pinch, whatever the step distance", (final WidgetTester tester, final CanvasController controller) async
    {
      _touchPrefs.zoomStepDistance.value = _touchPrefs.zoomStepDistance.min;
      final int zoom = _view.zoomFactor;
      final Offset start = controller.viewport.offset.value;
      controller.panZoomUpdate(event: _panZoom());

      controller.panZoomUpdate(event: _panZoom(panDelta: const Offset(10, 5)));

      expect(_view.zoomFactor, zoom);
      expect(controller.viewport.offset.value, start + const Offset(10, 5));
      controller.panZoomEnd();
    });

    _inputTest("keeps the part of the canvas between the fingers in place", (final WidgetTester tester, final CanvasController controller) async
    {
      const Offset focus = Offset(420, 310);
      final Offset before = (focus - controller.viewport.offset.value) / _view.zoomFactor.toDouble();
      controller.panZoomUpdate(event: _panZoom(at: focus));

      controller.panZoomUpdate(event: _panZoom(at: focus, scale: 3.1));

      final Offset after = (focus - controller.viewport.offset.value) / _view.zoomFactor.toDouble();
      expect(after.dx, closeTo(before.dx, 1e-9));
      expect(after.dy, closeTo(before.dy, 1e-9));
      controller.panZoomEnd();
    });
  });

  group("dragging a reference layer", ()
  {
    _inputTest("moves it with the pointer, as one undo step", (final WidgetTester tester, final CanvasController controller) async
    {
      final ReferenceLayerState reference = _addReferenceLayer();
      await tester.runAsync(settle);
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);
      final double x = reference.offsetXNotifier.value;
      final double y = reference.offsetYNotifier.value;
      final Offset start = _at(controller: controller, x: 5, y: 5);

      controller.pointerHover(details: _hover(at: start));
      _frame(controller);
      controller.pointerDown(details: _press(at: start));
      _frame(controller);
      controller.pointerMove(details: _move(at: _at(controller: controller, x: 7, y: 6)));
      _frame(controller);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.generic, reason: "not before it is released");

      controller.pointerUp(details: _lift(at: _at(controller: controller, x: 7, y: 6)));
      _frame(controller);

      expect(reference.offsetXNotifier.value, closeTo(x + 2, 1e-9));
      expect(reference.offsetYNotifier.value, closeTo(y + 1, 1e-9));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.layerSettingsChange);
    });

    _inputTest("adds no undo step without moving it", (final WidgetTester tester, final CanvasController controller) async
    {
      _addReferenceLayer();
      await tester.runAsync(settle);
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);
      final HistoryState? before = _history.getCurrentState();

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 5, y: 5)]);

      expect(_history.getCurrentState(), same(before));
    });

    _inputTest("does not jump when pressed at the same spot after zooming", (final WidgetTester tester, final CanvasController controller) async
    {
      final ReferenceLayerState reference = _addReferenceLayer();
      await tester.runAsync(settle);
      final double x = reference.offsetXNotifier.value;
      final Offset spot = _at(controller: controller, x: 5, y: 5);
      _dragAlong(controller: controller, path: <Offset>[spot, _at(controller: controller, x: 7, y: 5)]);
      expect(reference.offsetXNotifier.value, closeTo(x + 2, 1e-9), reason: "setup");

      controller.pointerSignal(ev: _scroll(dy: 20, at: const Offset(100, 100)));
      _dragAlong(controller: controller, path: <Offset>[spot]);

      expect(reference.offsetXNotifier.value, closeTo(x + 2, 1e-9));
    });

    _inputTest("does not jump after a second drag from the same spot", (final WidgetTester tester, final CanvasController controller) async
    {
      final ReferenceLayerState reference = _addReferenceLayer();
      await tester.runAsync(settle);
      final double x = reference.offsetXNotifier.value;
      final Offset spot = _at(controller: controller, x: 5, y: 5);

      _dragAlong(controller: controller, path: <Offset>[spot, _at(controller: controller, x: 7, y: 5)]);
      expect(reference.offsetXNotifier.value, closeTo(x + 2, 1e-9), reason: "setup");
      _dragAlong(controller: controller, path: <Offset>[spot, _at(controller: controller, x: 6, y: 5)]);
      expect(reference.offsetXNotifier.value, closeTo(x + 3, 1e-9), reason: "setup");

      _dragAlong(controller: controller, path: <Offset>[_at(controller: controller, x: 20, y: 20)]);

      expect(reference.offsetXNotifier.value, closeTo(x + 3, 1e-9));
    });
  });

  group("the controller", ()
  {
    _inputTest("files what a tool has for the history", (final WidgetTester tester, final CanvasController controller) async
    {
      _frame(controller);
      final IToolPainter tool = controller.painter.toolPainter!;
      tool.hasHistoryData = true;

      await tester.pump(const Duration(milliseconds: 300));

      expect(tool.hasHistoryData, isFalse);
      expect(_history.getCurrentIdentifier(), tool.historyIdentifier);
    });

    _inputTest("picks up what a tool has found out on its own", (final WidgetTester tester, final CanvasController controller) async
    {
      _frame(controller);
      final IToolPainter tool = controller.painter.toolPainter!;
      tool.statusBarData.dimension = CoordinateSetI(x: 6, y: 7);
      tool.hasAsyncUpdate = true;

      await tester.pump(const Duration(milliseconds: 30));
      await _nextFrame(tester);

      expect(tool.hasAsyncUpdate, isFalse);
      expect(GetIt.I.get<StatusBarState>().statusBarToolDimensionString.value, isNotNull);
    });

    _inputTest("fits the canvas again when the size changes right after a request", (final WidgetTester tester, final CanvasController controller) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      final int zoom = _view.zoomFactor;

      controller.viewportSizeChanged(size: const Size(400, 300));
      await _nextFrame(tester);

      expect(_view.zoomFactor, lessThan(zoom));
    });

    _inputTest("does not fit the canvas anymore once the view was changed by hand", (final WidgetTester tester, final CanvasController controller) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      controller.pointerSignal(ev: _scroll(dy: -20));
      final int zoom = _view.zoomFactor;

      controller.viewportSizeChanged(size: const Size(400, 300));
      await _nextFrame(tester);

      expect(_view.zoomFactor, zoom);
    });

    _inputTest("follows the cursor type of the preferences", (final WidgetTester tester, final CanvasController controller) async
    {
      final DesktopPreferenceContent prefs = GetIt.I.get<PreferenceManager>().desktopPreferenceContent;

      prefs.cursorType.value = CursorType.arrow;
      expect(controller.mouseCursor.value, CursorType.arrow.systemCursor);

      prefs.cursorType.value = CursorType.crossHair;
      expect(controller.mouseCursor.value, CursorType.crossHair.systemCursor);
    });

    _inputTest("shows a hidden cursor as forbidden during playback", (final WidgetTester tester, final CanvasController controller) async
    {
      GetIt.I.get<PreferenceManager>().desktopPreferenceContent.cursorType.value = CursorType.none;
      expect(controller.mouseCursor.value, SystemMouseCursors.none, reason: "setup");
      _timeline.addNewFrameRight();
      _timeline.loopEndIndex.value = 1;
      await tester.runAsync(settle);

      _timeline.isPlaying.value = true;
      expect(controller.mouseCursor.value, SystemMouseCursors.forbidden);

      _timeline.isPlaying.value = false;
      expect(controller.mouseCursor.value, SystemMouseCursors.none);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets("lets go of everything it holds when it is disposed", (final WidgetTester tester) async
    {
      await _boot(tester);
      final CanvasController controller = await _controller(tester);
      final HistoryController history = GetIt.I.get<HistoryController>();
      final StylusBridge bridge = GetIt.I.get<StylusBridge>();
      expect(history.flushHistoryData, isNotNull);
      expect(bridge.onHoverExit, isNotNull);
      final int zoom = _view.zoomFactor;

      controller.dispose();

      expect(history.flushHistoryData, isNull);
      expect(bridge.onHoverExit, isNull);
      _view.setZoomLevel(val: zoom + 5);
      _hotkeys.triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      expect(_view.zoomFactor, zoom + 5, reason: "nobody listens to the hotkey anymore");
      await _release(tester);
    });
  });

  group("the joystick", ()
  {
    Future<List<(Offset, double)>> pumpStick({required final WidgetTester tester, required final JoystickAxis axis, final VoidCallback? onRelease}) async
    {
      final List<(Offset, double)> ticks = <(Offset, double)>[];
      await tester.pumpWidget(MaterialApp(
        theme: monochromeTheme,
        home: Material(child: Center(child: TouchJoystickWidget(
          axis: axis,
          onRelease: onRelease,
          onTick: ({required final Offset deflection, required final double seconds}) {ticks.add((deflection, seconds));},
        ),),),
      ),);
      return ticks;
    }

    Finder stick() => find.byType(TouchJoystickWidget);

    //a deflection of 18 is half of the way the knob can go
    const double half = (0.5 - 0.15) / 0.85;

    testWidgets("reports its deflection once per frame, beyond the dead zone", (final WidgetTester tester) async
    {
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.free);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(stick()));
      await tester.pump();
      await gesture.moveBy(const Offset(18, 0));
      ticks.clear();

      await tester.pump(const Duration(milliseconds: 16));

      expect(ticks, hasLength(1));
      expect(ticks.single.$1.dx, closeTo(half, 1e-9));
      expect(ticks.single.$1.dy, 0.0);
      expect(ticks.single.$2, closeTo(0.016, 1e-9));
      await gesture.up();
      await tester.pump();
    });

    testWidgets("reports nothing inside of the dead zone", (final WidgetTester tester) async
    {
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.free);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(stick()));
      await tester.pump();
      await gesture.moveBy(const Offset(3, 3));

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(ticks, isEmpty);
      await gesture.up();
      await tester.pump();
    });

    testWidgets("goes no further than its full length", (final WidgetTester tester) async
    {
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.free);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(stick()));
      await tester.pump();
      await gesture.moveBy(const Offset(300, 300));
      ticks.clear();

      await tester.pump(const Duration(milliseconds: 16));

      expect(ticks.single.$1.distance, closeTo(1.0, 1e-9));
      expect(ticks.single.$1.dx, closeTo(ticks.single.$1.dy, 1e-9));
      await gesture.up();
      await tester.pump();
    });

    testWidgets("only goes up and down when it is the vertical one", (final WidgetTester tester) async
    {
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.vertical);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(stick()));
      await tester.pump();
      await gesture.moveBy(const Offset(25, -18));
      ticks.clear();

      await tester.pump(const Duration(milliseconds: 16));

      expect(ticks.single.$1.dx, 0.0);
      expect(ticks.single.$1.dy, closeTo(-half, 1e-9));
      await gesture.up();
      await tester.pump();
    });

    testWidgets("stops and says so when it is released", (final WidgetTester tester) async
    {
      int released = 0;
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.free, onRelease: () {released++;});
      final TestGesture gesture = await tester.startGesture(tester.getCenter(stick()));
      await tester.pump();
      await gesture.moveBy(const Offset(18, 0));

      await gesture.up();
      ticks.clear();
      await tester.pump(const Duration(milliseconds: 16));

      expect(released, 1);
      expect(ticks, isEmpty);
    });

    testWidgets("stops and says so when it is cancelled", (final WidgetTester tester) async
    {
      int released = 0;
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.free, onRelease: () {released++;});
      final TestGesture gesture = await tester.startGesture(tester.getCenter(stick()));
      await tester.pump();
      await gesture.moveBy(const Offset(18, 0));

      await gesture.cancel();
      ticks.clear();
      await tester.pump(const Duration(milliseconds: 16));

      expect(released, 1);
      expect(ticks, isEmpty);
    });

    testWidgets("stays with the finger that took it", (final WidgetTester tester) async
    {
      int released = 0;
      final List<(Offset, double)> ticks = await pumpStick(tester: tester, axis: JoystickAxis.free, onRelease: () {released++;});
      final Offset center = tester.getCenter(stick());
      final TestGesture first = await tester.startGesture(center);
      await tester.pump();
      await first.moveBy(const Offset(18, 0));

      final TestGesture second = await tester.startGesture(center + const Offset(0, 5), pointer: 2);
      await second.moveBy(const Offset(0, 20));
      await second.up();
      expect(released, 0);
      ticks.clear();

      await tester.pump(const Duration(milliseconds: 16));
      expect(ticks.single.$1.dx, closeTo(half, 1e-9));
      expect(ticks.single.$1.dy, 0.0);

      await first.up();
      expect(released, 1);
      await tester.pump();
    });

    group("on the viewport", ()
    {
      Future<CanvasViewport> viewport({required final WidgetTester tester}) async
      {
        await _boot(tester);
        final CanvasViewport viewport = CanvasViewport(viewState: _view, canvasState: GetIt.I.get<CanvasState>());
        viewport.resize(newSize: _drawingArea);
        _view.setZoomLevel(val: 10);
        viewport.setOffset(newOffset: const Offset(100, 100));
        return viewport;
      }

      testWidgets("pans against the deflection, slowly near the middle", (final WidgetTester tester) async
      {
        final CanvasViewport v = await viewport(tester: tester);

        v.joystickPan(deflection: const Offset(0.1, 0), seconds: 0.1);
        expect(v.offset.value.dx, closeTo(100 - 0.01 * 1500 * 0.1, 1e-9));
        expect(v.offset.value.dy, 100);

        v.joystickPan(deflection: const Offset(0, -1), seconds: 0.01);
        expect(v.offset.value.dy, closeTo(115, 1e-9));
        await _release(tester);
      });

      testWidgets("stays put at no deflection at all", (final WidgetTester tester) async
      {
        final CanvasViewport v = await viewport(tester: tester);

        v.joystickPan(deflection: Offset.zero, seconds: 0.016);

        expect(v.offset.value, const Offset(100, 100));
        await _release(tester);
      });

      testWidgets("zooms one step at once, and then with the deflection", (final WidgetTester tester) async
      {
        final CanvasViewport v = await viewport(tester: tester);

        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.01);
        expect(_view.zoomFactor, 11, reason: "a fresh deflection");

        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.05);
        expect(_view.zoomFactor, 11, reason: "12 steps per second at full deflection");

        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.05);
        expect(_view.zoomFactor, 12);
        await _release(tester);
      });

      testWidgets("zooms out when going the other way, at once", (final WidgetTester tester) async
      {
        final CanvasViewport v = await viewport(tester: tester);
        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.01);
        expect(_view.zoomFactor, 11);

        v.joystickZoom(deflection: const Offset(0, 1), seconds: 0.01);

        expect(_view.zoomFactor, 10);
        await _release(tester);
      });

      testWidgets("starts over after it was released", (final WidgetTester tester) async
      {
        final CanvasViewport v = await viewport(tester: tester);
        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.01);
        expect(_view.zoomFactor, 11);

        v.joystickZoomRelease();
        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.01);

        expect(_view.zoomFactor, 12, reason: "a fresh deflection again");
        await _release(tester);
      });

      testWidgets("keeps the middle of the drawing area in place", (final WidgetTester tester) async
      {
        final CanvasViewport v = await viewport(tester: tester);
        final Offset center = _drawingArea.center(Offset.zero);
        v.setOffset(newOffset: const Offset(250, 200));
        final Offset before = (center - v.offset.value) / _view.zoomFactor.toDouble();

        v.joystickZoom(deflection: const Offset(0, -1), seconds: 0.01);

        final Offset after = (center - v.offset.value) / _view.zoomFactor.toDouble();
        expect(after.dx, closeTo(before.dx, 1e-9));
        expect(after.dy, closeTo(before.dy, 1e-9));
        await _release(tester);
      });
    });
  });

  group("the canvas widget", ()
  {
    void widgetTest(final String description, final Future<void> Function(WidgetTester tester) body)
    {
      testWidgets(description, (final WidgetTester tester) async
      {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await _boot(tester);
        await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
          theme: monochromeTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Material(child: CanvasWidget()),
        ),),);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        await body(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await _release(tester);
        await tester.pump(const Duration(seconds: 1));
      });
    }

    /// The canvas is fitted into the widget and centered.
    Offset screenPos({required final CoordinateSetI pixel})
    {
      final double zoom = _view.zoomFactor.toDouble();
      final Offset corner = Offset((1000 - 32 * zoom) / 2, (800 - 24 * zoom) / 2);
      return corner + Offset((pixel.x + 0.5) * zoom, (pixel.y + 0.5) * zoom);
    }

    widgetTest("draws what a mouse does on it", (final WidgetTester tester) async
    {
      final ColorReference color = _palette.selectedColor!;
      final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: screenPos(pixel: CoordinateSetI(x: 10, y: 8)));
      await mouse.moveTo(screenPos(pixel: CoordinateSetI(x: 10, y: 8)));
      await tester.pump();

      await mouse.down(screenPos(pixel: CoordinateSetI(x: 10, y: 8)));
      await tester.pump();
      await mouse.moveTo(screenPos(pixel: CoordinateSetI(x: 12, y: 8)));
      await tester.pump();
      await mouse.up();
      await tester.pump();
      await mouse.removePointer();
      await tester.pump();
      await tester.runAsync(settle);

      expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 11, y: 8)), color);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.toolPen);
    });

    widgetTest("ends a stroke that is cancelled", (final WidgetTester tester) async
    {
      final ColorReference color = _palette.selectedColor!;
      final TestGesture finger = await tester.startGesture(screenPos(pixel: CoordinateSetI(x: 10, y: 8)), kind: PointerDeviceKind.stylus);
      await tester.pump();
      await finger.moveTo(screenPos(pixel: CoordinateSetI(x: 12, y: 8)));
      await tester.pump();

      await finger.cancel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(settle);

      expect(_drawing.getDataEntry(coord: CoordinateSetI(x: 11, y: 8)), color);
    });

    widgetTest("zooms with the wheel", (final WidgetTester tester) async
    {
      final int zoom = _view.zoomFactor;

      await tester.sendEventToBinding(PointerScrollEvent(position: screenPos(pixel: CoordinateSetI(x: 10, y: 8)), scrollDelta: const Offset(0, -20)));
      await tester.pump();

      expect(_view.zoomFactor, zoom + 1);
    });

    widgetTest("zooms with a trackpad, until the gesture ends", (final WidgetTester tester) async
    {
      final int zoom = _view.zoomFactor;
      final TestGesture trackpad = await tester.createGesture(kind: PointerDeviceKind.trackpad);

      await trackpad.panZoomStart(const Offset(500, 400));
      await trackpad.panZoomUpdate(const Offset(500, 400));
      await trackpad.panZoomUpdate(const Offset(500, 400), scale: 3.1);
      await tester.pump();
      expect(_view.zoomFactor, zoom + 2);

      await trackpad.panZoomEnd();
      await tester.pump();
      await trackpad.panZoomStart(const Offset(500, 400));
      await trackpad.panZoomUpdate(const Offset(500, 400), scale: 3.1);
      await tester.pump();
      expect(_view.zoomFactor, zoom + 2, reason: "the next one starts over");
      await trackpad.panZoomEnd();
      await tester.pump();
    });

    widgetTest("shows the joysticks only when asked to, and they reach the view", (final WidgetTester tester) async
    {
      _touchPrefs.showJoysticks.value = false;
      await tester.pump();
      expect(find.byType(TouchJoystickWidget), findsNothing);

      _touchPrefs.showJoysticks.value = true;
      await tester.pump();
      expect(find.byType(TouchJoystickWidget), findsNWidgets(2));

      final int zoom = _view.zoomFactor;
      final Finder zoomStick = find.byWidgetPredicate((final Widget w) => w is TouchJoystickWidget && w.axis == JoystickAxis.vertical);
      final TestGesture finger = await tester.startGesture(tester.getCenter(zoomStick));
      await tester.pump();
      await finger.moveBy(const Offset(0, -36));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_view.zoomFactor, greaterThan(zoom));
      await finger.up();
      await tester.pump();

      _touchPrefs.showJoysticks.value = false;
      await tester.pump();
      expect(find.byType(TouchJoystickWidget), findsNothing);
    });
  });
}
