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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

KPixPainterOptions _painterOptions()
{
  return KPixPainterOptions(
    cursorSize: 1.0,
    cursorBorderWidth: 1.0,
    selectionSolidStrokeWidth: 1.0,
    pixelExtension: 0.0,
    selectionPolygonCircleRadius: 1.0,
    selectionStrokeWidthLarge: 1.0,
    selectionStrokeWidthSmall: 1.0,
    backupPainterPollingRateMs: 100,
  );
}

DrawingParameters _params({required final LayerState layer, required final CoordinateSetI cursor, required final bool primaryDown})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 4,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: const Size(64, 64),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: Offset.zero,
    pixelRatio: 1.0,
    currentLayer: layer,
    symmetryHorizontal: null,
    symmetryVertical: null,
    isPlaying: false,
  );
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 16, y: 16);

Future<DrawingLayerState> _filledLayer({required final ProjectSession projectSession}) async
{
  final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
  final CoordinateColorMapNullable content = CoordinateColorMapNullable();
  for (int x = 0; x < _canvasSize.x; x++)
  {
    for (int y = 0; y < _canvasSize.y; y++)
    {
      content[CoordinateSetI(x: x, y: y)] = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
    }
  }
  layer.setDataAll(list: content);
  await settle();
  return layer;
}

void _click({required final EraserPainter painter, required final LayerState layer, required final CoordinateSetI at})
{
  painter.calculate(drawParams: _params(layer: layer, cursor: at, primaryDown: true));
  painter.calculate(drawParams: _params(layer: layer, cursor: at, primaryDown: false));
}

void main()
{
  testWidgets("shift and a click erase a straight line from the last erased pixel", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = await _filledLayer(projectSession: projectSession);
      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 1;
      final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
      final CoordinateSetI start = CoordinateSetI(x: 2, y: 2);
      final CoordinateSetI end = CoordinateSetI(x: 10, y: 6);
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());

      _click(painter: painter, layer: layer, at: start);
      await settle();
      expect(layer.getDataEntry(coord: start), isNull, reason: "setup: the click erased the start");
      painter.hasHistoryData = false;

      hotkeyManager.shiftNotifier.value = true;
      painter.calculate(drawParams: _params(layer: layer, cursor: end, primaryDown: false));
      painter.calculate(drawParams: _params(layer: layer, cursor: end, primaryDown: true));
      await settle();
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 6, y: 4)), isNotNull, reason: "the line is erased on release, not on press");

      painter.calculate(drawParams: _params(layer: layer, cursor: end, primaryDown: false));
      await settle();
      for (final CoordinateSetI coord in bresenham(start: start, end: end))
      {
        expect(layer.getDataEntry(coord: coord), isNull, reason: "$coord is on the line");
      }
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 2, y: 6)), isNotNull, reason: "pixels off the line stay");
      expect(painter.hasHistoryData, isTrue, reason: "the line is an undo step");
    },);
  });

  testWidgets("with nothing erased before, shift and a click erase just that pixel", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = await _filledLayer(projectSession: projectSession);
      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 1;
      GetIt.I.get<HotkeyManager>().shiftNotifier.value = true;
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());
      final CoordinateSetI spot = CoordinateSetI(x: 5, y: 5);

      painter.calculate(drawParams: _params(layer: layer, cursor: spot, primaryDown: false));
      _click(painter: painter, layer: layer, at: spot);
      await settle();

      expect(layer.getDataEntry(coord: spot), isNull);
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 6, y: 5)), isNotNull);
    },);
  });

  testWidgets("shift during a freehand stroke pauses it", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = await _filledLayer(projectSession: projectSession);
      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 1;
      final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());

      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 2, y: 8), primaryDown: false));
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 2, y: 8), primaryDown: true));
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 3, y: 8), primaryDown: true));
      hotkeyManager.shiftNotifier.value = true;
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 6, y: 8), primaryDown: true));
      hotkeyManager.shiftNotifier.value = false;
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 9, y: 8), primaryDown: true));
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 9, y: 8), primaryDown: false));
      await settle();

      for (final int x in <int>[2, 3, 7, 8, 9])
      {
        expect(layer.getDataEntry(coord: CoordinateSetI(x: x, y: 8)), isNull, reason: "$x,8 was erased freehand");
      }
      for (final int x in <int>[4, 5, 6])
      {
        expect(layer.getDataEntry(coord: CoordinateSetI(x: x, y: 8)), isNotNull, reason: "$x,8 was passed while shift paused the stroke");
      }
    },);
  });

  testWidgets("the line preview and the status bar follow shift without the cursor moving", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = await _filledLayer(projectSession: projectSession);
      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 1;
      final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
      final CoordinateSetI start = CoordinateSetI(x: 2, y: 2);
      final CoordinateSetI cursor = CoordinateSetI(x: 10, y: 6);
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());

      _click(painter: painter, layer: layer, at: start);
      painter.calculate(drawParams: _params(layer: layer, cursor: cursor, primaryDown: false));
      expect(painter.linePreviewPoints, isEmpty, reason: "setup: no line without shift");

      painter.hasAsyncUpdate = false;
      hotkeyManager.shiftNotifier.value = true;
      expect(painter.hasAsyncUpdate, isTrue, reason: "the canvas only repaints on request, so pressing shift has to ask for one");

      final DrawingParameters params = _params(layer: layer, cursor: cursor, primaryDown: false);
      painter.calculate(drawParams: params);
      expect(painter.linePreviewPoints, bresenham(start: start, end: cursor).toSet());
      painter.drawCursorOutline(drawParams: params);
      painter.setStatusBarData(drawParams: params);
      expect(painter.statusBarData.dimension, CoordinateSetI(x: 9, y: 5));
      expect(painter.statusBarData.angle, start, reason: "the angle is measured from the last erased pixel");

      hotkeyManager.shiftNotifier.value = false;
      painter.calculate(drawParams: params);
      painter.setStatusBarData(drawParams: params);
      expect(painter.linePreviewPoints, isEmpty, reason: "releasing shift leaves the line mode");
      expect(painter.statusBarData.dimension, isNull, reason: "releasing shift leaves the line mode");
    },);
  });

  testWidgets("a line snapped to an angle continues from where it ended, not from the cursor", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = await _filledLayer(projectSession: projectSession);
      GetIt.I.get<ToolOptions>().eraserOptions.size.value = 1;
      final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
      //8:3 is no allowed ratio, so the line has to snap
      final CoordinateSetI cursor = CoordinateSetI(x: 10, y: 5);
      final EraserPainter painter = EraserPainter(painterOptions: _painterOptions());

      _click(painter: painter, layer: layer, at: CoordinateSetI(x: 2, y: 2));
      hotkeyManager.shiftNotifier.value = true;
      hotkeyManager.controlNotifier.value = true;
      _click(painter: painter, layer: layer, at: cursor);
      await settle();

      final DrawingParameters params = _params(layer: layer, cursor: cursor, primaryDown: false);
      painter.calculate(drawParams: params);
      painter.setStatusBarData(drawParams: params);
      final CoordinateSetI? nextStart = painter.statusBarData.angle;
      expect(nextStart, isNotNull, reason: "setup: still in line mode");
      expect(nextStart, isNot(cursor), reason: "the snapped line does not end at the cursor");
      expect(layer.getDataEntry(coord: nextStart!), isNull, reason: "the next line starts on the last pixel this one erased");
    },);
  });
}
