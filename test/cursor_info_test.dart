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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/status_bar_data.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/line_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/painting/shape_painter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

DrawingParameters _params({required final CoordinateSetI cursor, required final bool primaryDown, final CoordinateSetI? pressStart})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
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
  );
}

CursorInfo? _step({required final IToolPainter painter, required final CoordinateSetI cursor, required final bool primaryDown, final CoordinateSetI? pressStart})
{
  final DrawingParameters params = _params(cursor: cursor, primaryDown: primaryDown, pressStart: pressStart);
  painter.calculate(drawParams: params);
  return painter.getCursorInfo(drawParams: params);
}

void _expectLine({required final CursorInfo? info, required final int width, required final int height, required final double angle})
{
  expect(info, isNotNull);
  expect(info!.dimension, isNull);
  expect(info.length, closeTo(sqrt(width * width + height * height), 1e-9));
  expect(info.angle, closeTo(angle, 1e-9));
}

double _degrees({required final int dx, required final int dy}) => atan2(dy, dx) * 180.0 / pi;

final CoordinateSetI _canvasSize = CoordinateSetI(x: 32, y: 32);
final CoordinateSetI _start = CoordinateSetI(x: 2, y: 2);

void main()
{
  group("measurements", () {
    test("a box counts the pixels it covers", () {
      final CursorInfo info = CursorInfo.box(startPos: CoordinateSetI(x: 9, y: 5), endPos: CoordinateSetI(x: 2, y: 2));
      expect(info.dimension, CoordinateSetI(x: 8, y: 4));
      expect(info.length, isNull);
      expect(info.angle, isNull);
    });

    test("a line is measured like the status bar measures it", () {
      final CursorInfo info = CursorInfo.line(startPos: CoordinateSetI(x: 2, y: 2), endPos: CoordinateSetI(x: 10, y: 6));
      _expectLine(info: info, width: 9, height: 5, angle: _degrees(dx: 8, dy: 4));
    });
  });

  group("line tool", () {
    Future<LinePainter> startedLine() async
    {
      final LinePainter painter = LinePainter(painterOptions: _painterOptions());
      expect(_step(painter: painter, cursor: _start, primaryDown: true), isNull, reason: "the first click only places the start");
      _step(painter: painter, cursor: _start, primaryDown: false);
      await settle();
      return painter;
    }

    testWidgets("shows length and angle while the line follows the cursor", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final LinePainter painter = LinePainter(painterOptions: _painterOptions());
        expect(_step(painter: painter, cursor: _start, primaryDown: false), isNull, reason: "nothing to measure before the line starts");

        final LinePainter started = await startedLine();
        final CursorInfo? info = _step(painter: started, cursor: CoordinateSetI(x: 10, y: 6), primaryDown: false);
        _expectLine(info: info, width: 9, height: 5, angle: _degrees(dx: 8, dy: 4));
        await settle();
      },);
    });

    testWidgets("with shift the line runs through the start, so it is twice as long", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final LinePainter painter = await startedLine();
        GetIt.I.get<HotkeyManager>().shiftNotifier.value = true;
        final CursorInfo? info = _step(painter: painter, cursor: CoordinateSetI(x: 10, y: 6), primaryDown: false);
        _expectLine(info: info, width: 17, height: 9, angle: _degrees(dx: 16, dy: 8));
        GetIt.I.get<HotkeyManager>().shiftNotifier.value = false;
        await settle();
      },);
    });

    testWidgets("with integer aspect ratios the angle is the snapped one", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        GetIt.I.get<ToolOptions>().lineOptions.integerAspectRatio.value = true;
        final LinePainter painter = await startedLine();
        //8:5 snaps to the 2:1 pattern
        final CursorInfo? info = _step(painter: painter, cursor: CoordinateSetI(x: 10, y: 7), primaryDown: false);
        _expectLine(info: info, width: 9, height: 5, angle: _degrees(dx: 2, dy: 1));
        await settle();
      },);
    });

    testWidgets("while bending a curve the chord is shown, and nothing after it is drawn", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final LinePainter painter = await startedLine();
        final CoordinateSetI end = CoordinateSetI(x: 10, y: 6);
        _step(painter: painter, cursor: end, primaryDown: false);
        _step(painter: painter, cursor: end, primaryDown: true);
        final CursorInfo? info = _step(painter: painter, cursor: CoordinateSetI(x: 6, y: 14), primaryDown: true);
        _expectLine(info: info, width: 9, height: 5, angle: _degrees(dx: 8, dy: 4));

        expect(_step(painter: painter, cursor: CoordinateSetI(x: 6, y: 14), primaryDown: false), isNull);
        await settle();
      },);
    });
  });

  group("shape tool", () {
    testWidgets("shows the box only while the shape is dragged", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final ShapePainter painter = ShapePainter(painterOptions: _painterOptions());
        final CoordinateSetI end = CoordinateSetI(x: 9, y: 5);
        expect(_step(painter: painter, cursor: _start, primaryDown: false), isNull);

        final CursorInfo? info = _step(painter: painter, cursor: end, primaryDown: true, pressStart: _start);
        expect(info?.dimension, CoordinateSetI(x: 8, y: 4));

        expect(_step(painter: painter, cursor: end, primaryDown: false, pressStart: _start), isNull);
        await settle();
      },);
    });
  });

  group("selection tool", () {
    for (final SelectShape shape in <SelectShape>[SelectShape.rectangle, SelectShape.ellipse])
    {
      testWidgets("shows the box while a selection is dragged (${shape.name})",(final WidgetTester tester) async {
        await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
          GetIt.I.get<ToolOptions>().selectOptions.shape.value = shape;
          final SelectionPainter painter = SelectionPainter(painterOptions: _painterOptions());
          final CoordinateSetI end = CoordinateSetI(x: 9, y: 5);

          _step(painter: painter, cursor: _start, primaryDown: true, pressStart: _start);
          final CursorInfo? info = _step(painter: painter, cursor: end, primaryDown: true, pressStart: _start);
          expect(info?.dimension, CoordinateSetI(x: 8, y: 4));

          expect(_step(painter: painter, cursor: end, primaryDown: false, pressStart: _start), isNull);
        },);
      });
    }

    testWidgets("shows nothing for a click, which deselects", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        GetIt.I.get<ToolOptions>().selectOptions.shape.value = SelectShape.rectangle;
        GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 10, y: 10), end: CoordinateSetI(x: 20, y: 20), selectShape: SelectShape.rectangle);
        final SelectionPainter painter = SelectionPainter(painterOptions: _painterOptions());

        expect(_step(painter: painter, cursor: _start, primaryDown: true, pressStart: _start), isNull);
        expect(_step(painter: painter, cursor: _start, primaryDown: true, pressStart: _start), isNull);
        _step(painter: painter, cursor: _start, primaryDown: false, pressStart: _start);
      },);
    });

    testWidgets("shows nothing for polygons", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        GetIt.I.get<ToolOptions>().selectOptions.shape.value = SelectShape.polygon;
        final SelectionPainter painter = SelectionPainter(painterOptions: _painterOptions());
        expect(_step(painter: painter, cursor: _start, primaryDown: true, pressStart: _start), isNull);
      },);
    });

    testWidgets("shows nothing while a selection is moved", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        GetIt.I.get<ToolOptions>().selectOptions.shape.value = SelectShape.rectangle;
        GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: _start, end: CoordinateSetI(x: 9, y: 5), selectShape: SelectShape.rectangle);
        final SelectionPainter painter = SelectionPainter(painterOptions: _painterOptions());
        final CoordinateSetI inside = CoordinateSetI(x: 4, y: 4);

        _step(painter: painter, cursor: inside, primaryDown: true, pressStart: inside);
        expect(_step(painter: painter, cursor: CoordinateSetI(x: 7, y: 6), primaryDown: true, pressStart: inside), isNull);
        _step(painter: painter, cursor: CoordinateSetI(x: 7, y: 6), primaryDown: false, pressStart: inside);
        await settle();
      },);
    });
  });

  test("the preference is on by default and survives a save and reload", () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferenceManager manager = PreferenceManager(await SharedPreferences.getInstance());
    expect(manager.guiPreferenceContent.showCursorInfo.value, isTrue);

    manager.guiPreferenceContent.showCursorInfo.value = false;
    await manager.saveUserPrefs();
    await manager.loadPreferences();
    expect(manager.guiPreferenceContent.showCursorInfo.value, isFalse);
  });
}
