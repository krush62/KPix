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

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/line_painter.dart';
import 'package:kpix/painting/shape_painter.dart';
import 'package:kpix/painting/stamp_painter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

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

Future<void> _tick({required final IToolPainter painter, required final CoordinateSetI cursor, required final bool primaryDown, final CoordinateSetI? pressStart}) async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.calculate(drawParams: DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 1,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: const Size(32, 32),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: pressStart != null ? Offset(pressStart.x.toDouble(), pressStart.y.toDouble()) : Offset.zero,
    pixelRatio: 1.0,
    currentLayer: GetIt.I.get<DocumentState>().timeline.getCurrentLayer()!,
    symmetryHorizontal: null,
    symmetryVertical: null,
    isPlaying: false,
  ),);
  await Future<void>.delayed(const Duration(milliseconds: 40));
}

/// Changes a modifier key and checks that the painter asks for a repaint.
void _setModifier({required final IToolPainter painter, required final ValueNotifier<bool> modifier, required final bool pressed})
{
  painter.hasAsyncUpdate = false;
  modifier.value = pressed;
  expect(painter.hasAsyncUpdate, isTrue, reason: "the canvas only repaints on request, so the key has to ask for one");
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 32, y: 32);

void main()
{
  group("line tool", () {
    Future<LinePainter> lineTo({required final CoordinateSetI start, required final CoordinateSetI end}) async
    {
      final LinePainter painter = LinePainter(painterOptions: _painterOptions());
      await _tick(painter: painter, cursor: start, primaryDown: true);
      await _tick(painter: painter, cursor: start, primaryDown: false);
      await _tick(painter: painter, cursor: end, primaryDown: false);
      return painter;
    }

    testWidgets("shift mirrors the line without moving the cursor", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
        final CoordinateSetI end = CoordinateSetI(x: 12, y: 10);
        final LinePainter painter = await lineTo(start: CoordinateSetI(x: 8, y: 8), end: end);
        expect(painter.cursorRaster?.offset, CoordinateSetI(x: 8, y: 8), reason: "setup: the line runs from the start");

        _setModifier(painter: painter, modifier: hotkeyManager.shiftNotifier, pressed: true);
        await _tick(painter: painter, cursor: end, primaryDown: false);
        expect(painter.cursorRaster?.offset, CoordinateSetI(x: 4, y: 6));
        expect(painter.cursorRaster?.size, CoordinateSetI(x: 9, y: 5));

        _setModifier(painter: painter, modifier: hotkeyManager.shiftNotifier, pressed: false);
        await _tick(painter: painter, cursor: end, primaryDown: false);
        expect(painter.cursorRaster?.offset, CoordinateSetI(x: 8, y: 8), reason: "releasing shift ends the mirroring");
        await settle();
      },);
    });

    testWidgets("control snaps the line without moving the cursor", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final CoordinateSetI end = CoordinateSetI(x: 12, y: 11);
        final LinePainter painter = await lineTo(start: CoordinateSetI(x: 8, y: 8), end: end);
        expect(painter.cursorRaster?.size, CoordinateSetI(x: 5, y: 4), reason: "setup: the line ends at the cursor");

        //the tool options flip the setting while control is held
        GetIt.I.get<ToolOptions>().lineOptions.integerAspectRatio.value = true;
        _setModifier(painter: painter, modifier: GetIt.I.get<HotkeyManager>().controlNotifier, pressed: true);
        await _tick(painter: painter, cursor: end, primaryDown: false);
        expect(painter.cursorRaster?.size.x, painter.cursorRaster?.size.y, reason: "4:3 snaps to the 1:1 pattern");
        await settle();
      },);
    });
  });

  testWidgets("shape tool: shift centers the shape without moving the cursor", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final CoordinateSetI start = CoordinateSetI(x: 4, y: 4);
      final CoordinateSetI end = CoordinateSetI(x: 8, y: 6);
      final ShapePainter painter = ShapePainter(painterOptions: _painterOptions());
      await _tick(painter: painter, cursor: start, primaryDown: true, pressStart: start);
      await _tick(painter: painter, cursor: end, primaryDown: true, pressStart: start);
      expect(painter.cursorRaster?.offset, start, reason: "setup: the shape starts where it was pressed");

      _setModifier(painter: painter, modifier: GetIt.I.get<HotkeyManager>().shiftNotifier, pressed: true);
      await _tick(painter: painter, cursor: end, primaryDown: true, pressStart: start);
      expect(painter.cursorRaster?.offset, CoordinateSetI(x: 0, y: 2));
      expect(painter.cursorRaster?.size, CoordinateSetI(x: 9, y: 5));

      GetIt.I.get<HotkeyManager>().shiftNotifier.value = false;
      await _tick(painter: painter, cursor: end, primaryDown: false, pressStart: start);
      await settle();
    },);
  });

  testWidgets("stamp tool: control aligns the stamp to the grid without moving the cursor", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final StampManager stampManager = StampManager();
      GetIt.I.registerSingleton<StampManager>(stampManager);
      final HashMap<CoordinateSetI, int> square = HashMap<CoordinateSetI, int>();
      for (int x = 0; x < 4; x++)
      {
        for (int y = 0; y < 4; y++)
        {
          square[CoordinateSetI(x: x, y: y)] = 0;
        }
      }
      stampManager.selectedStamp.value = StampManagerEntryData(path: "", thumbnail: null, name: "square", isLocked: true, data: square, width: 4, height: 4);
      final CoordinateSetI cursor = CoordinateSetI(x: 5, y: 5);
      final StampPainter painter = StampPainter(painterOptions: _painterOptions());
      await _tick(painter: painter, cursor: cursor, primaryDown: false);
      expect(painter.cursorRaster?.offset, CoordinateSetI(x: 1, y: 1), reason: "setup: the stamp hangs off the cursor");

      //the tool options flip the setting while control is held
      GetIt.I.get<ToolOptions>().stampOptions.gridAlign.value = true;
      _setModifier(painter: painter, modifier: GetIt.I.get<HotkeyManager>().controlNotifier, pressed: true);
      await _tick(painter: painter, cursor: cursor, primaryDown: false);
      expect(painter.cursorRaster?.offset, CoordinateSetI(x: 0, y: 0), reason: "the stamp snaps to the 4 px grid");
    },);
  });
}
