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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/infra/stylus_bridge.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_controller.dart';
import 'package:kpix/widgets/canvas/canvas_viewport.dart';

import 'support/selection_harness.dart';

const Size _drawingArea = Size(800, 600);

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
  await tester.pump();
  return controller;
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
}
