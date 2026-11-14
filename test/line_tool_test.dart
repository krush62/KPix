/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/constraints/tool_line_constraints.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/line_painter.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/tool_geometry_helper.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 20, y: 16);

LineOptions get _options => GetIt.I.get<ToolOptions>().lineOptions;
HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();

LinePainter _painter() => LinePainter(painterOptions: testPainterOptions());

void _lineTest(final String description, final Future<void> Function(ProjectSession projectSession, DrawingLayerState layer) body, {final bool skip = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await body(projectSession, layerAt(projectSession: projectSession, index: 0));
    },);
  }, skip: skip,);
}

/// A click: the first one sets where the line starts.
void _click({required final LinePainter painter, required final DrawingLayerState layer, required final CoordinateSetI at, final double? symmetryHorizontal})
{
  painter.calculate(drawParams: toolParams(layer: layer, cursor: at, symmetryHorizontal: symmetryHorizontal));
  painter.calculate(drawParams: toolParams(layer: layer, cursor: at, primaryDown: true, symmetryHorizontal: symmetryHorizontal));
  painter.calculate(drawParams: toolParams(layer: layer, cursor: at, symmetryHorizontal: symmetryHorizontal));
}

Future<Set<CoordinateSetI>> _drawLine({required final LinePainter painter, required final DrawingLayerState layer, required final CoordinateSetI start, required final CoordinateSetI end, final double? symmetryHorizontal}) async
{
  _click(painter: painter, layer: layer, at: start, symmetryHorizontal: symmetryHorizontal);
  _click(painter: painter, layer: layer, at: end, symmetryHorizontal: symmetryHorizontal);
  await settle();
  return colorsOf(layer: layer).keys.toSet();
}

/// How many pixels the line stays in each row, or in each column when it is steep,
/// from the start to the end.
List<int> _runLengths({required final Set<CoordinateSetI> points, required final bool perRow, required final int first, required final int last})
{
  final int step = last >= first ? 1 : -1;
  return <int>[
    for (int line = first; line != last + step; line += step) points.where((final CoordinateSetI p) => (perRow ? p.y : p.x) == line).length,
  ];
}

void main()
{
  group("a straight line", ()
  {
    _lineTest("runs from the first click to the second", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final CoordinateSetI start = CoordinateSetI(x: 2, y: 3);
      final CoordinateSetI end = CoordinateSetI(x: 15, y: 9);

      final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: start, end: end);

      expect(points, bresenham(start: start, end: end).toSet());
      expect(colorsOf(layer: layer).values.toSet(), <ColorReference>{GetIt.I.get<PaletteState>().selectedColor!});
    });

    _lineTest("draws nothing until the second click", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();

      _click(painter: painter, layer: layer, at: CoordinateSetI(x: 2, y: 3));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 8, y: 3)));
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
      expect(painter.hasHistoryData, isFalse);
    });

    _lineTest("is an undo step of the line tool", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();

      await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 2, y: 3), end: CoordinateSetI(x: 5, y: 3));

      expect(painter.hasHistoryData, isTrue);
      expect(painter.historyIdentifier, HistoryStateTypeIdentifier.toolLine);
    });

    _lineTest("can start again after one was drawn", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 1, y: 1), end: CoordinateSetI(x: 5, y: 1));

      final Set<CoordinateSetI> points = await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 1, y: 5), end: CoordinateSetI(x: 5, y: 5));

      expect(points.where((final CoordinateSetI p) => p.y == 5), hasLength(5));
    });

    _lineTest("gets its width from the options", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.width.value = 3;
      final CoordinateSetI start = CoordinateSetI(x: 3, y: 6);
      final CoordinateSetI end = CoordinateSetI(x: 12, y: 6);

      final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: start, end: end);

      expect(points, getLinePoints(startPos: start, endPos: end, size: 3, shape: PencilShape.round));
      expect(points, containsAll(<CoordinateSetI>[CoordinateSetI(x: 7, y: 5), CoordinateSetI(x: 7, y: 6), CoordinateSetI(x: 7, y: 7)]));
    });

    _lineTest("snaps to a whole ratio when asked to", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.integerAspectRatio.value = true;
      final CoordinateSetI start = CoordinateSetI(x: 2, y: 2);
      //8:3 is no allowed ratio, so the line has to snap
      final CoordinateSetI cursor = CoordinateSetI(x: 10, y: 5);

      final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: start, end: cursor);

      expect(points, getIntegerRatioLinePoints(startPos: start, endPos: cursor, size: 1, angles: _options.angles, shape: PencilShape.round));
      expect(points, isNot(contains(cursor)), reason: "the snapped line does not end at the cursor");
    });

    _lineTest("grows both ways from the start with shift", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 10, y: 8);
      _click(painter: painter, layer: layer, at: start);
      _hotkeys.shiftNotifier.value = true;

      final Set<CoordinateSetI> points = await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 14, y: 8), end: CoordinateSetI(x: 14, y: 8));

      expect(points, bresenham(start: CoordinateSetI(x: 6, y: 8), end: CoordinateSetI(x: 14, y: 8)).toSet());
    });

    _lineTest("snapped lines grow both ways too", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.integerAspectRatio.value = true;
      final LinePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 10, y: 8);
      _click(painter: painter, layer: layer, at: start);
      _hotkeys.shiftNotifier.value = true;

      final Set<CoordinateSetI> points = await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 13, y: 8), end: CoordinateSetI(x: 13, y: 8));

      expect(points, containsAll(<CoordinateSetI>[CoordinateSetI(x: 7, y: 8), start, CoordinateSetI(x: 13, y: 8)]));
    });

    _lineTest("moves with the cursor while alt is held", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      _click(painter: painter, layer: layer, at: CoordinateSetI(x: 2, y: 2));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 2)));
      _hotkeys.altNotifier.value = true;
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 8, y: 5)));
      _hotkeys.altNotifier.value = false;

      final Set<CoordinateSetI> points = await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 8, y: 5), end: CoordinateSetI(x: 8, y: 5));

      expect(points, bresenham(start: CoordinateSetI(x: 4, y: 5), end: CoordinateSetI(x: 8, y: 5)).toSet());
    });

    _lineTest("is mirrored along the symmetry axis", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: CoordinateSetI(x: 1, y: 2), end: CoordinateSetI(x: 3, y: 2), symmetryHorizontal: 10.0);

      expect(points, <CoordinateSetI>{
        for (final int x in <int>[1, 2, 3, 16, 17, 18]) CoordinateSetI(x: x, y: 2),
      });
    });

    for (final (String condition, void Function(DrawingLayerState) apply) refusal in <(String, void Function(DrawingLayerState))>[
      ("locked", (final DrawingLayerState layer) => layer.lockState.value = LayerLockState.locked),
      ("hidden", (final DrawingLayerState layer) => layer.visibilityState.value = LayerVisibilityState.hidden),
    ])
    {
      _lineTest("is not drawn on a ${refusal.$1} layer", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        refusal.$2(layer);
        final LinePainter painter = _painter();

        final Set<CoordinateSetI> points = await _drawLine(painter: painter, layer: layer, start: CoordinateSetI(x: 1, y: 2), end: CoordinateSetI(x: 8, y: 2));

        expect(points, isEmpty);
        expect(painter.hasHistoryData, isFalse);
      });
    }
  });

  group("a smoothed line", ()
  {
    /// Whether [runs] only rise and then only fall.
    bool risesThenFalls({required final List<int> runs})
    {
      int i = 0;
      while (i + 1 < runs.length && runs[i + 1] >= runs[i])
      {
        i++;
      }
      while (i + 1 < runs.length && runs[i + 1] <= runs[i])
      {
        i++;
      }
      return i == runs.length - 1;
    }

    for (final (SegmentSortStyle style, bool Function(List<int>) isSorted) sorted in <(SegmentSortStyle, bool Function(List<int>))>[
      (SegmentSortStyle.asc, (final List<int> runs) => listEquals(runs, <int>[...runs]..sort())),
      (SegmentSortStyle.desc, (final List<int> runs) => listEquals(runs.reversed.toList(), <int>[...runs]..sort())),
      (SegmentSortStyle.ascDesc, (final List<int> runs) => risesThenFalls(runs: runs)),
      (SegmentSortStyle.descAsc, (final List<int> runs) => risesThenFalls(runs: runs.map((final int run) => -run).toList())),
    ])
    {
      _lineTest("sorts its steps ${sorted.$1.name}", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        _options.segmentSorting.value = true;
        _options.segmentSortStyle.value = sorted.$1;
        final CoordinateSetI start = CoordinateSetI(x: 2, y: 3);
        final CoordinateSetI end = CoordinateSetI(x: 15, y: 8);

        final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: start, end: end);

        expect(points, containsAll(<CoordinateSetI>[start, end]));
        expect(points, hasLength(14));
        final List<int> runs = _runLengths(points: points, perRow: true, first: start.y, last: end.y);
        expect(sorted.$2(runs), isTrue, reason: "$runs");
      });
    }

    _lineTest("sorts the steps the plain line has", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.segmentSorting.value = true;
      _options.segmentSortStyle.value = SegmentSortStyle.asc;
      final CoordinateSetI start = CoordinateSetI(x: 2, y: 3);
      final CoordinateSetI end = CoordinateSetI(x: 15, y: 8);

      final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: start, end: end);

      final List<int> plainRuns = _runLengths(points: bresenham(start: start, end: end).toSet(), perRow: true, first: start.y, last: end.y);
      expect(_runLengths(points: points, perRow: true, first: start.y, last: end.y), plainRuns..sort());
    });

    for (final (String direction, CoordinateSetI start, CoordinateSetI end) line in <(String, CoordinateSetI, CoordinateSetI)>[
      ("right and down", CoordinateSetI(x: 2, y: 3), CoordinateSetI(x: 15, y: 8)),
      ("left and down", CoordinateSetI(x: 15, y: 3), CoordinateSetI(x: 2, y: 8)),
      ("right and up", CoordinateSetI(x: 2, y: 8), CoordinateSetI(x: 15, y: 3)),
      ("left and up", CoordinateSetI(x: 15, y: 8), CoordinateSetI(x: 2, y: 3)),
      ("steeply down", CoordinateSetI(x: 3, y: 1), CoordinateSetI(x: 8, y: 14)),
      ("steeply left and up", CoordinateSetI(x: 8, y: 14), CoordinateSetI(x: 3, y: 1)),
      ("straight across", CoordinateSetI(x: 2, y: 5), CoordinateSetI(x: 12, y: 5)),
      ("straight down", CoordinateSetI(x: 5, y: 2), CoordinateSetI(x: 5, y: 12)),
      ("with a diagonal last step", CoordinateSetI(x: 2, y: 3), CoordinateSetI(x: 4, y: 4)),
    ])
    {
      _lineTest("reaches both ends going ${line.$1}", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        _options.segmentSorting.value = true;
        _options.segmentSortStyle.value = SegmentSortStyle.asc;

        final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: line.$2, end: line.$3);

        expect(points, containsAll(<CoordinateSetI>[line.$2, line.$3]));
        expect(points, hasLength(bresenham(start: line.$2, end: line.$3).length));
      });
    }

    _lineTest("gets its width from the options", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.segmentSorting.value = true;
      _options.width.value = 3;

      final Set<CoordinateSetI> points = await _drawLine(painter: _painter(), layer: layer, start: CoordinateSetI(x: 2, y: 6), end: CoordinateSetI(x: 10, y: 6));

      expect(points, containsAll(<CoordinateSetI>[CoordinateSetI(x: 6, y: 5), CoordinateSetI(x: 6, y: 6), CoordinateSetI(x: 6, y: 7)]));
    });
  });

  group("a curve", ()
  {
    /// The second click pulled away through [through], releasing at the last of them.
    Future<Set<CoordinateSetI>> drawCurve({required final LinePainter painter, required final DrawingLayerState layer, required final CoordinateSetI start, required final CoordinateSetI end, required final List<CoordinateSetI> through}) async
    {
      _click(painter: painter, layer: layer, at: start);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: end));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: end, primaryDown: true));
      for (final CoordinateSetI coord in through)
      {
        painter.calculate(drawParams: toolParams(layer: layer, cursor: coord, primaryDown: true));
      }
      painter.calculate(drawParams: toolParams(layer: layer, cursor: through.last));
      await settle();
      return colorsOf(layer: layer).keys.toSet();
    }

    //a pull that keeps moving, which is what a real drag sends
    final List<CoordinateSetI> pull = <CoordinateSetI>[
      for (int y = 2; y <= 13; y++) CoordinateSetI(x: 9, y: y),
    ];

    _lineTest("runs from the start to the end and bends towards the pull", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI end = CoordinateSetI(x: 17, y: 1);

      final Set<CoordinateSetI> points = await drawCurve(painter: _painter(), layer: layer, start: start, end: end, through: pull);

      expect(points, containsAll(<CoordinateSetI>[start, end]));
      //halfway along, a quadratic curve is midway between its chord and the pull
      expect(points.where((final CoordinateSetI p) => p.x == 9).single.y, inInclusiveRange(6, 7));
    });

    _lineTest("stays one pixel thin", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final Set<CoordinateSetI> points = await drawCurve(painter: _painter(), layer: layer, start: CoordinateSetI(x: 1, y: 1), end: CoordinateSetI(x: 17, y: 1), through: pull);

      for (final CoordinateSetI p in points)
      {
        final bool hasHorizontal = points.contains(CoordinateSetI(x: p.x + 1, y: p.y)) || points.contains(CoordinateSetI(x: p.x - 1, y: p.y));
        final bool hasVertical = points.contains(CoordinateSetI(x: p.x, y: p.y + 1)) || points.contains(CoordinateSetI(x: p.x, y: p.y - 1));
        expect(hasHorizontal && hasVertical, isFalse, reason: "$p makes a corner");
      }
    });

    _lineTest("gets its width from the options", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.width.value = 3;

      final Set<CoordinateSetI> points = await drawCurve(painter: _painter(), layer: layer, start: CoordinateSetI(x: 1, y: 1), end: CoordinateSetI(x: 17, y: 1), through: pull);

      expect(points.where((final CoordinateSetI p) => p.x == 9), hasLength(greaterThanOrEqualTo(3)));
    });

    _lineTest("bends towards where the pull was released", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI end = CoordinateSetI(x: 17, y: 1);

      final Set<CoordinateSetI> points = await drawCurve(painter: _painter(), layer: layer, start: start, end: end, through: <CoordinateSetI>[CoordinateSetI(x: 9, y: 5), CoordinateSetI(x: 9, y: 13)]);

      expect(points, contains(CoordinateSetI(x: 9, y: 7)));
      expect(points, containsAll(<CoordinateSetI>[start, end]));
    });

    _lineTest("the cursor info shows its chord", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI end = CoordinateSetI(x: 9, y: 1);
      _click(painter: painter, layer: layer, at: start);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: end));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: end, primaryDown: true));
      final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 9, y: 13), primaryDown: true);
      painter.calculate(drawParams: params);

      expect(painter.getCursorInfo(drawParams: params)!.length, closeTo(9.0, 1.0));
    });
  });

  group("while drawing", ()
  {
    _lineTest("the status bar and the cursor info follow the line", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 2, y: 3);
      _click(painter: painter, layer: layer, at: start);
      final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 8, y: 5));
      painter.calculate(drawParams: params);

      painter.setStatusBarData(drawParams: params);
      painter.drawCursorOutline(drawParams: params);

      expect(painter.statusBarData.cursorPos, CoordinateSetI(x: 8, y: 5));
      expect(painter.statusBarData.dimension, CoordinateSetI(x: 7, y: 3));
      expect(painter.statusBarData.angle, start);
      expect(painter.getCursorInfo(drawParams: params)!.length, isNotNull);
    });

    _lineTest("the cursor info knows a snapped line and one from the center", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.integerAspectRatio.value = true;
      final LinePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 10, y: 8);
      _click(painter: painter, layer: layer, at: start);
      _hotkeys.shiftNotifier.value = true;
      final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 13, y: 8));
      painter.calculate(drawParams: params);

      final double? fromTheCenter = painter.getCursorInfo(drawParams: params)!.length;
      _hotkeys.shiftNotifier.value = false;
      painter.calculate(drawParams: params);
      expect(fromTheCenter, greaterThan(painter.getCursorInfo(drawParams: params)!.length!), reason: "with shift the line reaches past the start as well");
    });

    _lineTest("shows no cursor info before it started", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 8, y: 5));

      exerciseToolOverlays(painter: painter, layer: layer, cursor: CoordinateSetI(x: 8, y: 5));

      expect(painter.getCursorInfo(drawParams: params), isNull);
      expect(painter.statusBarData.dimension, isNull);
    });

    _lineTest("reset forgets the start", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      _click(painter: painter, layer: layer, at: CoordinateSetI(x: 2, y: 3));

      painter.reset();
      _click(painter: painter, layer: layer, at: CoordinateSetI(x: 8, y: 3));
      await settle();

      expect(colorsOf(layer: layer), isEmpty, reason: "this click only starts a new line");
    });

    _lineTest("a preview is shown for the line being drawn and goes away afterwards", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final LinePainter painter = _painter();
      _click(painter: painter, layer: layer, at: CoordinateSetI(x: 2, y: 3));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 8, y: 3)));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(painter.cursorRaster, isNotNull);
      expect(painter.hasAsyncUpdate, isTrue);

      painter.calculate(drawParams: toolParams(layer: layer, cursor: null));
      painter.reset();
      painter.calculate(drawParams: toolParams(layer: layer, cursor: null));
      expect(painter.cursorRaster, isNull);
    });
  });
}
