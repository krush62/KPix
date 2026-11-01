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

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 6);

SelectionState get _state => GetIt.I.get<DocumentState>().selectionState;
SelectOptions get _options => GetIt.I.get<ToolOptions>().selectOptions;
HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();
HistoryManager get _history => GetIt.I.get<HistoryManager>();
List<ColorReference> get _ramp => GetIt.I.get<PaletteState>().colorRamps[0].references;

Set<CoordinateSetI> _selected()
{
  return <CoordinateSetI>{
    for (int x = 0; x < _canvasSize.x; x++)
      for (int y = 0; y < _canvasSize.y; y++)
        if (_state.selection.contains(coord: CoordinateSetI(x: x, y: y))) CoordinateSetI(x: x, y: y),
  };
}

List<String> _selectedPattern() => patternOf(coords: _selected(), size: _canvasSize);

void _select({required final int x0, required final int y0, required final int x1, required final int y1, final SelectShape shape = SelectShape.rectangle})
{
  _state.newSelectionFromShape(start: CoordinateSetI(x: x0, y: y0), end: CoordinateSetI(x: x1, y: y1), selectShape: shape);
}

/// A single pixel: when replacing, a click without a drag only drops the selection.
void _selectPixel({required final int x, required final int y})
{
  _options.mode.value = SelectMode.add;
  _select(x0: x, y0: y, x1: x, y1: y);
  _options.mode.value = SelectMode.replace;
}

void _selectionTest(final String description, final Future<void> Function(ProjectSession projectSession, DrawingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await body(projectSession, layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

SelectionPainter _painter() => SelectionPainter(painterOptions: testPainterOptions());

/// Keeps the outlines a tool draws, which a real canvas does not tell.
class _OutlineCanvas implements Canvas
{
  final List<Rect> rects = <Rect>[];
  final List<Rect> ovals = <Rect>[];

  @override
  void drawRect(final Rect rect, final Paint paint) => rects.add(rect);

  @override
  void drawOval(final Rect rect, final Paint paint) => ovals.add(rect);

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _undo() async
{
  await GetIt.I.get<HistoryController>().undoPressed()!.restore;
  await settle();
}

void main()
{
  group("inverting", ()
  {
    _selectionTest("swaps what is selected, is an undo step, and can be undone", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: 1, y0: 1, x1: 2, y1: 2);
      await settle();
      final List<String> before = _selectedPattern();

      _state.inverse();
      await settle();

      expect(_selectedPattern(), <String>[
        "########",
        "#..#####",
        "#..#####",
        "########",
        "########",
        "########",
      ]);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionInverse);

      await _undo();
      expect(_selectedPattern(), before);
    });

    _selectionTest("picks up the pixels it now covers and lets go of the others", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final CoordinateSetI inside = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI outside = CoordinateSetI(x: 5, y: 4);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{inside: _ramp[1], outside: _ramp[2]}));
      await settle();
      _select(x0: 0, y0: 0, x1: 2, y1: 2);
      await settle();
      expect(_state.selection.getColorReference(coord: inside), _ramp[1], reason: "setup");

      _state.inverse();
      await settle();

      expect(_state.selection.getColorReference(coord: outside), _ramp[2]);
      expect(layer.getDataEntry(coord: outside), isNull, reason: "the pixel floats now");
      expect(layer.getDataEntry(coord: inside), _ramp[1], reason: "the pixel is back on the layer");
      expect(_state.selection.contains(coord: inside), isFalse);
      expect(copiesOf(projectSession: projectSession, coord: inside), 1);
      expect(copiesOf(projectSession: projectSession, coord: outside), 1);
    });

    _selectionTest("selects everything when nothing was, and nothing when everything was", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _state.inverse();
      expect(_selected(), hasLength(_canvasSize.x * _canvasSize.y));

      _state.inverse();
      expect(_selected(), isEmpty);
      expect(_state.selectionLines, isEmpty);
    });

    _selectionTest("can stay out of the history", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final bool hadUndo = _history.hasUndo.value;

      _state.inverse(addToHistoryStack: false);

      expect(_history.hasUndo.value, hadUndo);
    });
  });

  group("combining selections", ()
  {
    Future<void> firstThen({required final SelectMode mode}) async
    {
      _select(x0: 0, y0: 0, x1: 3, y1: 1);
      await settle();
      _options.mode.value = mode;
      _select(x0: 2, y0: 0, x1: 5, y1: 2);
      await settle();
    }

    _selectionTest("replacing drops the old one", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await firstThen(mode: SelectMode.replace);

      expect(_selectedPattern(), <String>[
        "..####..",
        "..####..",
        "..####..",
        "........",
        "........",
        "........",
      ]);
    });

    _selectionTest("adding keeps both", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await firstThen(mode: SelectMode.add);

      expect(_selectedPattern(), <String>[
        "######..",
        "######..",
        "..####..",
        "........",
        "........",
        "........",
      ]);
    });

    _selectionTest("subtracting takes the new one away", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await firstThen(mode: SelectMode.subtract);

      expect(_selectedPattern(), <String>[
        "##......",
        "##......",
        "........",
        "........",
        "........",
        "........",
      ]);
    });

    //what the mode has always done in KPix: what both cover is what goes away
    _selectionTest("intersecting keeps what only one of them covers", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await firstThen(mode: SelectMode.intersect);

      expect(_selectedPattern(), <String>[
        "##..##..",
        "##..##..",
        "..####..",
        "........",
        "........",
        "........",
      ]);
    });

    _selectionTest("a click without a drag drops the selection when replacing", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: 0, y0: 0, x1: 3, y1: 1);
      await settle();

      _select(x0: 2, y0: 2, x1: 2, y1: 2);
      await settle();

      expect(_selected(), isEmpty);
    });

    _selectionTest("a click selects one pixel when adding", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.mode.value = SelectMode.add;

      _select(x0: 2, y0: 2, x1: 2, y1: 2);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 2, y: 2)});
    });

    _selectionTest("is cut off at the edge of the canvas", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: -3, y0: -3, x1: 1, y1: 0);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 1, y: 0)});
    });
  });

  group("the ellipse", ()
  {
    _selectionTest("selects the inside of the box", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: 0, y0: 0, x1: 7, y1: 5, shape: SelectShape.ellipse);

      expect(_selectedPattern(), <String>[
        "..####..",
        ".######.",
        "########",
        "########",
        ".######.",
        "..####..",
      ]);
    });

    _selectionTest("is cut off at the edge of the canvas", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: 5, y0: 3, x1: 10, y1: 8, shape: SelectShape.ellipse);

      expect(_selected().every((final CoordinateSetI p) => p.x < _canvasSize.x && p.y < _canvasSize.y), isTrue);
      expect(_selected(), isNotEmpty);
    });

    _selectionTest("combines like any other shape", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: 0, y0: 0, x1: 7, y1: 5);
      _options.mode.value = SelectMode.subtract;

      _select(x0: 0, y0: 0, x1: 7, y1: 5, shape: SelectShape.ellipse);

      expect(_selectedPattern(), <String>[
        "##....##",
        "#......#",
        "........",
        "........",
        "#......#",
        "##....##",
      ]);
    });
  });

  group("the wand", ()
  {
    Future<void> paint({required final DrawingLayerState layer}) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        CoordinateSetI(x: 0, y: 0): _ramp[1],
        CoordinateSetI(x: 1, y: 0): _ramp[1],
        CoordinateSetI(x: 2, y: 0): _ramp[2],
        CoordinateSetI(x: 5, y: 0): _ramp[1],
      }),);
      await settle();
    }

    _selectionTest("takes what is connected and the same color", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 0, y: 0), mode: SelectMode.replace, continuous: true, selectFromWholeRamp: false);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 1, y: 0)});
    });

    _selectionTest("takes the whole ramp when asked to", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 0, y: 0), mode: SelectMode.replace, continuous: true, selectFromWholeRamp: true);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 1, y: 0), CoordinateSetI(x: 2, y: 0)});
    });

    _selectionTest("takes the same color everywhere when not continuous", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 0, y: 0), mode: SelectMode.replace, continuous: false, selectFromWholeRamp: false);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 1, y: 0), CoordinateSetI(x: 5, y: 0)});
    });

    _selectionTest("takes the whole ramp everywhere when asked to", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 0, y: 0), mode: SelectMode.replace, continuous: false, selectFromWholeRamp: true);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 1, y: 0), CoordinateSetI(x: 2, y: 0), CoordinateSetI(x: 5, y: 0)});
    });

    _selectionTest("takes the emptiness from an empty pixel", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 7, y: 5), mode: SelectMode.replace, continuous: false, selectFromWholeRamp: false);

      expect(_selected(), hasLength(_canvasSize.x * _canvasSize.y - 4));
    });

    _selectionTest("subtracts from what is selected", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);
      _select(x0: 0, y0: 0, x1: 2, y1: 0);
      await settle();
      _options.mode.value = SelectMode.subtract;

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 0, y: 0), mode: SelectMode.subtract, continuous: true, selectFromWholeRamp: false);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 2, y: 0)});
    });

    _selectionTest("adds nothing for a click on what is selected already", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      await paint(layer: layer);
      _select(x0: 0, y0: 0, x1: 0, y1: 1);
      await settle();
      _options.mode.value = SelectMode.add;

      _state.newSelectionFromWand(coord: CoordinateSetI(x: 0, y: 0), mode: SelectMode.add, continuous: true, selectFromWholeRamp: false);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 0, y: 1)});
    });
  });

  group("the polygon", ()
  {
    _selectionTest("selects its points", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final Set<CoordinateSetI> points = <CoordinateSetI>{CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 2, y: 2), CoordinateSetI(x: 40, y: 40)};

      _state.newSelectionFromPolygon(points: points);

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 2, y: 2)}, reason: "and leaves out what is off the canvas");
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionNew);
    });
  });

  group("moving", ()
  {
    _selectionTest("with its content takes the pixels along and leaves none behind", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final CoordinateSetI from = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI to = CoordinateSetI(x: 4, y: 3);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{from: _ramp[1]}));
      await settle();
      _select(x0: 1, y0: 1, x1: 2, y1: 2);
      await settle();

      _state.setOffset(offset: CoordinateSetI(x: 3, y: 2), withContent: true);
      _state.finishMovement();
      await settle();

      expect(_state.selection.getColorReference(coord: to), _ramp[1]);
      expect(_state.selection.contains(coord: from), isFalse);
      expect(copiesOf(projectSession: projectSession, coord: from), 0);
      expect(copiesOf(projectSession: projectSession, coord: to), 1);
    });

    _selectionTest("in steps adds up to the same place", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): _ramp[1]}));
      await settle();
      _selectPixel(x: 1, y: 1);
      await settle();

      _state.setOffset(offset: CoordinateSetI(x: 1, y: 0), withContent: true);
      _state.setOffset(offset: CoordinateSetI(x: 2, y: 1), withContent: true);
      _state.setOffset(offset: CoordinateSetI(x: 2, y: 1), withContent: true);
      _state.finishMovement();
      await settle();

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 3, y: 2)});
    });

    _selectionTest("without its content moves the outline and swaps the pixels it holds", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final CoordinateSetI first = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI second = CoordinateSetI(x: 4, y: 1);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{first: _ramp[1], second: _ramp[2]}));
      await settle();
      _selectPixel(x: 1, y: 1);
      await settle();
      expect(_state.selection.getColorReference(coord: first), _ramp[1], reason: "setup");

      _state.setOffset(offset: CoordinateSetI(x: 3, y: 0), withContent: false);
      _state.finishMovement();
      await settle();

      expect(_selected(), <CoordinateSetI>{second});
      expect(_state.selection.getColorReference(coord: second), _ramp[2]);
      expect(layer.getDataEntry(coord: first), _ramp[1], reason: "the pixel went back to the layer");
      expect(copiesOf(projectSession: projectSession, coord: first), 1);
      expect(copiesOf(projectSession: projectSession, coord: second), 1);
    });

    _selectionTest("without its content loses what leaves the canvas from the outline", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _select(x0: 6, y0: 0, x1: 7, y1: 0);
      await settle();

      _state.setOffset(offset: CoordinateSetI(x: 1, y: 0), withContent: false);
      _state.finishMovement();
      await settle();

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 7, y: 0)});
    });

    _selectionTest("is one undo step and can be undone", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): _ramp[1]}));
      await settle();
      _selectPixel(x: 1, y: 1);
      await settle();
      _state.setOffset(offset: CoordinateSetI(x: 2, y: 0), withContent: true);
      _state.setOffset(offset: CoordinateSetI(x: 3, y: 0), withContent: true);
      _state.finishMovement();
      await settle();

      await _undo();

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 1, y: 1)});
      expect(_state.selection.getColorReference(coord: CoordinateSetI(x: 1, y: 1)), _ramp[1]);
    });
  });

  group("the tool", ()
  {
    _selectionTest("drags out a box from either corner", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 5, y: 4), CoordinateSetI(x: 2, y: 1)]);

      expect(painter.hasNewSelection, isTrue);
      expect(painter.selectionStart, CoordinateSetI(x: 2, y: 1));
      expect(painter.selectionEnd, CoordinateSetI(x: 5, y: 4));
    });

    for (final (String direction, CoordinateSetI start, CoordinateSetI end, CoordinateSetI expectedStart, CoordinateSetI expectedEnd) ratio in <(String, CoordinateSetI, CoordinateSetI, CoordinateSetI, CoordinateSetI)>[
      ("wide, dragged right", CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 6, y: 2), CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 2, y: 2)),
      ("wide, dragged left", CoordinateSetI(x: 6, y: 2), CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 4, y: 0), CoordinateSetI(x: 6, y: 2)),
      ("high, dragged down", CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 2, y: 5), CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 2, y: 2)),
      ("high, dragged up", CoordinateSetI(x: 2, y: 5), CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 0, y: 3), CoordinateSetI(x: 2, y: 5)),
    ])
    {
      _selectionTest("keeps a ratio of one when asked to: ${ratio.$1}", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        final SelectionPainter painter = _painter();
        _options.shape.value = SelectShape.rectangle;
        _options.keepAspectRatio.value = true;

        dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[ratio.$2, ratio.$3]);

        expect(painter.selectionStart, ratio.$4);
        expect(painter.selectionEnd, ratio.$5);
      });
    }

    _selectionTest("moves the box along while alt is held", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;
      final CoordinateSetI start = CoordinateSetI(x: 0, y: 0);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 2, y: 2), primaryDown: true, pressStart: start));
      _hotkeys.altNotifier.value = true;
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 4, y: 3), primaryDown: true, pressStart: start));

      expect(painter.selectionStart, CoordinateSetI(x: 2, y: 1));
      expect(painter.selectionEnd, CoordinateSetI(x: 4, y: 3));
    });

    _selectionTest("the wand remembers where it was used", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.wand;

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 3, y: 2)]);

      expect(painter.hasNewSelection, isTrue);
      expect(painter.selectionEnd, CoordinateSetI(x: 3, y: 2));
    });

    group("the cursor outline", ()
    {
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      final CoordinateSetI cursor = CoordinateSetI(x: 5, y: 4);
      const Rect cursorPixel = Rect.fromLTRB(20, 16, 24, 20);
      const Rect box = Rect.fromLTRB(4, 4, 24, 20);

      for (final SelectShape shape in <SelectShape>[SelectShape.rectangle, SelectShape.ellipse])
      {
        _selectionTest("marks the pixel under the cursor while hovering: ${shape.name}", (final ProjectSession projectSession, final DrawingLayerState layer) async
        {
          final SelectionPainter painter = _painter();
          _options.shape.value = shape;
          final _OutlineCanvas canvas = _OutlineCanvas();

          painter.calculate(drawParams: toolParams(layer: layer, cursor: cursor));
          painter.drawCursorOutline(drawParams: toolParams(layer: layer, cursor: cursor, canvas: canvas));

          expect(canvas.rects, <Rect>[cursorPixel, cursorPixel]);
          expect(canvas.ovals, isEmpty);
        });

        _selectionTest("shows only the box during a drag: ${shape.name}", (final ProjectSession projectSession, final DrawingLayerState layer) async
        {
          final SelectionPainter painter = _painter();
          _options.shape.value = shape;
          final _OutlineCanvas canvas = _OutlineCanvas();

          painter.calculate(drawParams: toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start));
          painter.calculate(drawParams: toolParams(layer: layer, cursor: cursor, primaryDown: true, pressStart: start));
          painter.drawCursorOutline(drawParams: toolParams(layer: layer, cursor: cursor, primaryDown: true, pressStart: start, canvas: canvas));

          expect(canvas.rects, shape == SelectShape.rectangle ? <Rect>[box, box] : isEmpty);
          expect(canvas.ovals, shape == SelectShape.ellipse ? <Rect>[box, box] : isEmpty);
        });
      }
    });

    group("polygon", ()
    {
      void clickPolygon({required final SelectionPainter painter, required final DrawingLayerState layer, required final CoordinateSetI at})
      {
        painter.calculate(drawParams: toolParams(layer: layer, cursor: at, pressStart: at));
        painter.calculate(drawParams: toolParams(layer: layer, cursor: at, primaryDown: true, pressStart: at));
        painter.calculate(drawParams: toolParams(layer: layer, cursor: at, pressStart: at));
      }

      _selectionTest("collects its corners and closes on the first one", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        final SelectionPainter painter = _painter();
        _options.shape.value = SelectShape.polygon;
        final List<CoordinateSetI> corners = <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 5, y: 1), CoordinateSetI(x: 5, y: 4)];

        for (final CoordinateSetI corner in corners)
        {
          clickPolygon(painter: painter, layer: layer, at: corner);
        }
        expect(painter.polygonPoints, corners);
        expect(painter.hasNewSelection, isFalse);

        clickPolygon(painter: painter, layer: layer, at: corners.first);

        expect(painter.hasNewSelection, isTrue);
      });

      _selectionTest("needs three corners to close", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        final SelectionPainter painter = _painter();
        _options.shape.value = SelectShape.polygon;
        final CoordinateSetI first = CoordinateSetI(x: 1, y: 1);

        clickPolygon(painter: painter, layer: layer, at: first);
        clickPolygon(painter: painter, layer: layer, at: CoordinateSetI(x: 5, y: 1));
        clickPolygon(painter: painter, layer: layer, at: first);

        expect(painter.hasNewSelection, isFalse);
        expect(painter.polygonPoints, hasLength(2));
      });

      _selectionTest("snaps a corner to a whole ratio with control", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        final SelectionPainter painter = _painter();
        _options.shape.value = SelectShape.polygon;
        clickPolygon(painter: painter, layer: layer, at: CoordinateSetI(x: 0, y: 0));
        _hotkeys.controlNotifier.value = true;

        clickPolygon(painter: painter, layer: layer, at: CoordinateSetI(x: 7, y: 3));

        expect(painter.polygonPoints.last, isNot(CoordinateSetI(x: 7, y: 3)));
      });

      _selectionTest("draws its corners with and without the cursor", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        final SelectionPainter painter = _painter();
        _options.shape.value = SelectShape.polygon;
        clickPolygon(painter: painter, layer: layer, at: CoordinateSetI(x: 1, y: 1));
        clickPolygon(painter: painter, layer: layer, at: CoordinateSetI(x: 5, y: 1));

        painter.drawExtras(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 5, y: 4)));
        painter.drawExtras(drawParams: toolParams(layer: layer, cursor: null));
        _hotkeys.controlNotifier.value = true;
        painter.drawExtras(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 5, y: 4)));

        expect(painter.polygonPoints, hasLength(2));
      });
    });

    _selectionTest("a press on the selection moves it", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): _ramp[1]}));
      await settle();
      _selectPixel(x: 1, y: 1);
      await settle();
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 2)]);
      await settle();

      expect(painter.movementStarted, isFalse, reason: "the release ended the move");
      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 3, y: 2)});
      expect(painter.hasNewSelection, isFalse);
    });

    _selectionTest("a press on the selection with alt moves only the outline", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 1): _ramp[1]}));
      await settle();
      _selectPixel(x: 1, y: 1);
      await settle();
      _hotkeys.altNotifier.value = true;
      _options.shape.value = SelectShape.rectangle;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 2)]);
      await settle();

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 3, y: 2)});
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 1, y: 1)), _ramp[1], reason: "the pixel stayed behind");
    });

    _selectionTest("a press on a locked layer's selection does not move it", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _selectPixel(x: 1, y: 1);
      await settle();
      layer.lockState.value = LayerLockState.locked;
      _options.shape.value = SelectShape.rectangle;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 2)]);
      await settle();

      expect(_selected(), <CoordinateSetI>{CoordinateSetI(x: 1, y: 1)});
    });

    _selectionTest("the status bar and the cursor info show the size of the box", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start));
      final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 5, y: 3), primaryDown: true, pressStart: start);
      painter.calculate(drawParams: params);

      painter.setStatusBarData(drawParams: params);
      painter.drawCursorOutline(drawParams: params);

      expect(painter.statusBarData.dimension, CoordinateSetI(x: 5, y: 3));
      expect(painter.getCursorInfo(drawParams: params)!.dimension, CoordinateSetI(x: 5, y: 3));
    });

    _selectionTest("a click shows no cursor info", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      final DrawingParameters params = toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start);
      painter.calculate(drawParams: params);

      expect(painter.getCursorInfo(drawParams: params), isNull);
    });

    for (final SelectShape shape in SelectShape.values)
    {
      _selectionTest("the overlays cope with the ${shape.name} resting and in a drag", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        final SelectionPainter painter = _painter();
        _options.shape.value = shape;
        final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);

        exerciseToolOverlays(painter: painter, layer: layer, cursor: start);
        final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 4, y: 3), primaryDown: true, pressStart: start);
        painter.calculate(drawParams: params);
        painter.drawCursorOutline(drawParams: params);
        painter.drawCursorOutline(drawParams: toolParams(layer: layer, cursor: null));

        expect(painter.statusBarData.cursorPos, start);
      });
    }

    _selectionTest("reset forgets everything", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 5, y: 4)]);
      painter.polygonPoints.add(CoordinateSetI(x: 1, y: 1));

      painter.reset();

      expect(painter.hasNewSelection, isFalse);
      expect(painter.polygonPoints, isEmpty);
      expect(painter.selectionStart, CoordinateSetI.zero());
      expect(painter.selectionEnd, CoordinateSetI.zero());
    });

    _selectionTest("does nothing on a layer that holds no pixels of its own", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final SelectionPainter painter = _painter();
      _options.shape.value = SelectShape.rectangle;
      final DrawingParameters params = toolParams(layer: layer, cursor: null, primaryDown: true);

      painter.calculate(drawParams: params);

      expect(painter.hasNewSelection, isFalse);
    });
  });
}
