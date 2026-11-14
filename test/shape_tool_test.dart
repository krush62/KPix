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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/constraints/tool_shape_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/painting/shape_painter.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 13, y: 11);
final CoordinateSetI _boxStart = CoordinateSetI(x: 1, y: 1);
final CoordinateSetI _boxEnd = CoordinateSetI(x: 11, y: 9);

ShapeOptions get _options => GetIt.I.get<ToolOptions>().shapeOptions;
HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();

class _Case
{
  final DrawingShape shape;
  final bool strokeOnly;
  final int strokeWidth;
  final int cornerRadius;
  final List<String> pattern;

  const _Case({required this.shape, required this.pattern, this.strokeOnly = false, this.strokeWidth = 1, this.cornerRadius = 0});

  String get name => "${shape.name}${strokeOnly ? " stroked $strokeWidth wide" : " filled"}${cornerRadius > 0 ? " with corners of $cornerRadius" : ""}";
}

const List<_Case> _cases = <_Case>[
  _Case(shape: DrawingShape.rectangle, pattern: <String>[
    ".............",
    ".###########.",
    ".###########.",
    ".###########.",
    ".###########.",
    ".###########.",
    ".###########.",
    ".###########.",
    ".###########.",
    ".###########.",
    ".............",
  ],),
  _Case(shape: DrawingShape.rectangle, strokeOnly: true, pattern: <String>[
    ".............",
    ".###########.",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    ".###########.",
    ".............",
  ],),
  _Case(shape: DrawingShape.rectangle, strokeOnly: true, strokeWidth: 2, pattern: <String>[
    ".............",
    ".###########.",
    ".###########.",
    ".##.......##.",
    ".##.......##.",
    ".##.......##.",
    ".##.......##.",
    ".##.......##.",
    ".###########.",
    ".###########.",
    ".............",
  ],),
  _Case(shape: DrawingShape.rectangle, cornerRadius: 3, pattern: <String>[
    ".............",
    "....#####....",
    "..#########..",
    "..#########..",
    ".###########.",
    ".###########.",
    ".###########.",
    "..#########..",
    "..#########..",
    "....#####....",
    ".............",
  ],),
  _Case(shape: DrawingShape.rectangle, strokeOnly: true, cornerRadius: 3, pattern: <String>[
    ".............",
    "....#####....",
    "..##.....##..",
    "..#.......#..",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    "..#.......#..",
    "..##.....##..",
    "....#####....",
    ".............",
  ],),
  _Case(shape: DrawingShape.rectangle, strokeOnly: true, strokeWidth: 2, cornerRadius: 3, pattern: <String>[
    ".............",
    "....#####....",
    "..#########..",
    "..#.......#..",
    ".##.......##.",
    ".##.......##.",
    ".##.......##.",
    "..#.......#..",
    "..#########..",
    "....#####....",
    ".............",
  ],),
  _Case(shape: DrawingShape.ellipse, pattern: <String>[
    ".............",
    "....#####....",
    "...#######...",
    "..#########..",
    ".###########.",
    ".###########.",
    ".###########.",
    "..#########..",
    "...#######...",
    "....#####....",
    ".............",
  ],),
  _Case(shape: DrawingShape.ellipse, strokeOnly: true, pattern: <String>[
    ".............",
    "....#####....",
    "...#.....#...",
    "..#.......#..",
    ".#.........#.",
    ".#.........#.",
    ".#.........#.",
    "..#.......#..",
    "...#.....#...",
    "....#####....",
    ".............",
  ],),
  _Case(shape: DrawingShape.ellipse, strokeOnly: true, strokeWidth: 2, pattern: <String>[
    ".............",
    "....#####....",
    "...#######...",
    "..###...###..",
    ".###.....###.",
    ".##.......##.",
    ".###.....###.",
    "..###...###..",
    "...#######...",
    "....#####....",
    ".............",
  ],),
  _Case(shape: DrawingShape.triangle, pattern: <String>[
    ".............",
    "......#......",
    "......#......",
    ".....###.....",
    ".....###.....",
    "....#####....",
    "...#######...",
    "...#######...",
    "..#########..",
    ".###########.",
    ".............",
  ],),
  _Case(shape: DrawingShape.triangle, strokeOnly: true, pattern: <String>[
    ".............",
    "......#......",
    ".....#.#.....",
    ".....#.#.....",
    "....#...#....",
    "...#....#....",
    "...#.....#...",
    "..#.......#..",
    "..#.......#..",
    ".###########.",
    ".............",
  ],),
  _Case(shape: DrawingShape.triangle, strokeOnly: true, strokeWidth: 2, pattern: <String>[
    ".............",
    "......#......",
    "......#......",
    ".....###.....",
    ".....###.....",
    "....##.##....",
    "...###.###...",
    "...##...##...",
    "..#########..",
    ".###########.",
    ".............",
  ],),
  _Case(shape: DrawingShape.diamond, pattern: <String>[
    ".............",
    "......#......",
    ".....###.....",
    "....#####....",
    "...#######...",
    ".###########.",
    "...#######...",
    "....#####....",
    ".....###.....",
    "......#......",
    ".............",
  ],),
  _Case(shape: DrawingShape.diamond, strokeOnly: true, pattern: <String>[
    ".............",
    "......#......",
    ".....#.#.....",
    "...##...##...",
    "..#.......#..",
    ".#.........#.",
    "..#.......#..",
    "...##...##...",
    ".....#.#.....",
    "......#......",
    ".............",
  ],),
  _Case(shape: DrawingShape.diamond, strokeOnly: true, strokeWidth: 2, pattern: <String>[
    ".............",
    "......#......",
    ".....###.....",
    "....#####....",
    "...###.###...",
    ".####...####.",
    "...###.###...",
    "....#####....",
    ".....###.....",
    "......#......",
    ".............",
  ],),
  _Case(shape: DrawingShape.ngon, pattern: <String>[
    ".............",
    "......#......",
    ".....###.....",
    "...#######...",
    ".###########.",
    "..#########..",
    "..#########..",
    "...#######...",
    "...#######...",
    ".............",
    ".............",
  ],),
  _Case(shape: DrawingShape.ngon, strokeOnly: true, pattern: <String>[
    ".............",
    "......#......",
    "....##.##....",
    "..##.....##..",
    ".#.........#.",
    "..#........#.",
    "..#.......#..",
    "...#......#..",
    "...#######...",
    ".............",
    ".............",
  ],),
  _Case(shape: DrawingShape.ngon, strokeOnly: true, strokeWidth: 2, pattern: <String>[
    ".............",
    "......#......",
    ".....###.....",
    "...#######...",
    ".####...####.",
    "..##.....##..",
    "..###...###..",
    "...#######...",
    "...#######...",
    ".............",
    ".............",
  ],),
  _Case(shape: DrawingShape.star, pattern: <String>[
    ".............",
    "......#......",
    "......#......",
    ".....###.....",
    ".###########.",
    "...#######...",
    "....#####....",
    "....#####....",
    "...#.....#...",
    ".............",
    ".............",
  ],),
  _Case(shape: DrawingShape.star, strokeOnly: true, pattern: <String>[
    ".............",
    "......#......",
    ".....##......",
    "....##.###...",
    ".###......##.",
    "..##.....##..",
    "....#...#....",
    "...#.####....",
    "...##...##...",
    ".............",
    ".............",
  ],),
];

void _useShape({required final DrawingShape shape, final bool strokeOnly = false, final int strokeWidth = 1, final int cornerRadius = 0})
{
  _options.shape.value = shape;
  _options.strokeOnly.value = strokeOnly;
  _options.strokeWidth.value = strokeWidth;
  _options.cornerRadius.value = cornerRadius;
}

ShapePainter _painter() => ShapePainter(painterOptions: testPainterOptions());

/// The box [coords] fill, as its top left and bottom right pixel.
(CoordinateSetI, CoordinateSetI) _boundsOf({required final Iterable<CoordinateSetI> coords})
{
  return (CoordinateSetI.getMin(coordList: coords.toList()), CoordinateSetI.getMax(coordList: coords.toList()));
}

void _shapeTest(final String description, final Future<void> Function(ProjectSession projectSession, DrawingLayerState layer) body, {final bool skip = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await body(projectSession, layerAt(projectSession: projectSession, index: 0));
    },);
  }, skip: skip,);
}

/// Checks every ellipse up to [limit] in both directions, which is sync because of
/// how hot the loop is.
List<String> _ellipseProblems({required final int limit})
{
  final List<String> problems = <String>[];
  for (int w = 1; w <= limit; w++)
  {
    for (int h = 1; h <= limit; h++)
    {
      final CoordinateSetI start = CoordinateSetI(x: 30, y: 40);
      final CoordinateSetI end = CoordinateSetI(x: 30 + w - 1, y: 40 + h - 1);
      final Set<CoordinateSetI> filled = drawFilledEllipse(start: start, end: end);
      final (CoordinateSetI min, CoordinateSetI max) = _boundsOf(coords: filled);
      if (min != start || max != end)
      {
        problems.add("$w x $h fills $min to $max");
      }
      for (final CoordinateSetI p in filled)
      {
        if (!filled.contains(CoordinateSetI(x: start.x + end.x - p.x, y: p.y)) || !filled.contains(CoordinateSetI(x: p.x, y: start.y + end.y - p.y)))
        {
          problems.add("$w x $h is not symmetric at $p");
          break;
        }
      }
      for (int y = start.y; y <= end.y; y++)
      {
        final List<int> xs = filled.where((final CoordinateSetI p) => p.y == y).map((final CoordinateSetI p) => p.x).toList();
        if (xs.isEmpty || xs.length != xs.reduce((final int a, final int b) => a > b ? a : b) - xs.reduce((final int a, final int b) => a < b ? a : b) + 1)
        {
          problems.add("$w x $h has a gap in row ${y - start.y}");
        }
      }
      final Set<CoordinateSetI> stroked = drawStrokedEllipse(start: start, end: end, strokeWidth: 1);
      if (!filled.containsAll(stroked))
      {
        problems.add("$w x $h strokes outside of its fill");
      }
    }
  }
  return problems;
}

void main()
{
  for (final _Case shapeCase in _cases)
  {
    _shapeTest("draws a ${shapeCase.name}", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: shapeCase.shape, strokeOnly: shapeCase.strokeOnly, strokeWidth: shapeCase.strokeWidth, cornerRadius: shapeCase.cornerRadius);

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[_boxStart, _boxEnd]);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), shapeCase.pattern);
    });
  }

  group("every ellipse", ()
  {
    test("fills its box, stays symmetric, has no gaps and strokes inside its fill", ()
    {
      expect(_ellipseProblems(limit: 24), isEmpty);
    });

    //the sizes past the limit above where the outermost rows have two pixels at most
    for (final (int w, int h) size in <(int, int)>[(6, 14), (6, 40), (10, 40), (14, 78), (14, 90)])
    {
      test("keeps its top and bottom row at ${size.$1} x ${size.$2}", ()
      {
        final CoordinateSetI start = CoordinateSetI.zero();
        final CoordinateSetI end = CoordinateSetI(x: size.$1 - 1, y: size.$2 - 1);

        final Set<CoordinateSetI> filled = drawFilledEllipse(start: start, end: end);
        final Set<CoordinateSetI> thick = drawStrokedEllipse(start: start, end: end, strokeWidth: 2);

        expect(CoordinateSetI.getMin(coordList: filled.toList()), start);
        expect(CoordinateSetI.getMax(coordList: filled.toList()), end);
        expect(filled, containsAll(drawStrokedEllipse(start: start, end: end, strokeWidth: 1)));
        expect(CoordinateSetI.getMin(coordList: thick.toList()), start);
        expect(CoordinateSetI.getMax(coordList: thick.toList()), end);
      });
    }

    test("does not care which corner it is given first", ()
    {
      final CoordinateSetI a = CoordinateSetI(x: 2, y: 3);
      final CoordinateSetI b = CoordinateSetI(x: 12, y: 9);

      expect(drawFilledEllipse(start: b, end: a), drawFilledEllipse(start: a, end: b));
    });

    test("is solid when the stroke is too wide to leave a hole", ()
    {
      final CoordinateSetI a = CoordinateSetI(x: 0, y: 0);
      final CoordinateSetI b = CoordinateSetI(x: 6, y: 6);

      expect(drawStrokedEllipse(start: a, end: b, strokeWidth: 4), drawFilledEllipse(start: a, end: b));
    });
  });

  group("the box", ()
  {
    _shapeTest("is the same dragged from either corner", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[_boxEnd, _boxStart]);
      await settle();

      expect(_boundsOf(coords: colorsOf(layer: layer).keys), (_boxStart, _boxEnd));
    });

    _shapeTest("is cut off at the edge of the canvas", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 10, y: 8), CoordinateSetI(x: 40, y: 40)]);
      await settle();

      expect(_boundsOf(coords: colorsOf(layer: layer).keys), (CoordinateSetI(x: 10, y: 8), CoordinateSetI(x: 12, y: 10)));
    });

    for (final (String direction, CoordinateSetI start, CoordinateSetI end, CoordinateSetI expectedMin, CoordinateSetI expectedMax) ratio in <(String, CoordinateSetI, CoordinateSetI, CoordinateSetI, CoordinateSetI)>[
      ("wide, dragged right", CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 9, y: 5), CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 5, y: 5)),
      ("wide, dragged left", CoordinateSetI(x: 9, y: 5), CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 5, y: 1), CoordinateSetI(x: 9, y: 5)),
      ("high, dragged down", CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 5, y: 9), CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 5, y: 5)),
      ("high, dragged up", CoordinateSetI(x: 5, y: 9), CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 1, y: 5), CoordinateSetI(x: 5, y: 9)),
    ])
    {
      _shapeTest("keeps a ratio of one when asked to: ${ratio.$1}", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        _useShape(shape: DrawingShape.rectangle);
        _options.keepRatio.value = true;

        dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[ratio.$2, ratio.$3]);
        await settle();

        expect(_boundsOf(coords: colorsOf(layer: layer).keys), (ratio.$4, ratio.$5));
      });
    }

    _shapeTest("grows from the center with shift", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      _hotkeys.shiftNotifier.value = true;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 5), CoordinateSetI(x: 9, y: 7)]);
      await settle();

      expect(_boundsOf(coords: colorsOf(layer: layer).keys), (CoordinateSetI(x: 3, y: 3), CoordinateSetI(x: 9, y: 7)));
    });

    _shapeTest("keeps a ratio of one from the center too", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      _options.keepRatio.value = true;
      _hotkeys.shiftNotifier.value = true;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 5), CoordinateSetI(x: 10, y: 7)]);
      await settle();

      final (CoordinateSetI min, CoordinateSetI max) = _boundsOf(coords: colorsOf(layer: layer).keys);
      expect(max.x - min.x, max.y - min.y);
    });

    _shapeTest("moves along with the cursor while alt is held", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 3, y: 3), primaryDown: true, pressStart: start));
      _hotkeys.altNotifier.value = true;
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5), primaryDown: true, pressStart: start));
      _hotkeys.altNotifier.value = false;
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5), pressStart: start));
      await settle();

      expect(_boundsOf(coords: colorsOf(layer: layer).keys), (CoordinateSetI(x: 4, y: 3), CoordinateSetI(x: 6, y: 5)));
    });

    _shapeTest("moves along with the cursor while the stylus button is held", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 1);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 3, y: 3), primaryDown: true, pressStart: start));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5), primaryDown: true, pressStart: start, stylusButtonDown: true));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5), pressStart: start));
      await settle();

      expect(_boundsOf(coords: colorsOf(layer: layer).keys), (CoordinateSetI(x: 4, y: 3), CoordinateSetI(x: 6, y: 5)));
    });
  });

  group("what gets drawn", ()
  {
    _shapeTest("uses the selected color and is an undo step of the shape tool", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[2].references[1];
      GetIt.I.get<PaletteState>().selectedColor = color;
      final ShapePainter painter = _painter();

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 2, y: 2)]);
      await settle();

      expect(colorsOf(layer: layer).values.toSet(), <ColorReference>{color});
      expect(painter.hasHistoryData, isTrue);
      expect(painter.historyIdentifier, HistoryStateTypeIdentifier.toolShape);
    });

    _shapeTest("is mirrored along the symmetry axes", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 2, y: 2)], symmetryHorizontal: 6.5, symmetryVertical: 5.5);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), <String>[
        ".............",
        ".##.......##.",
        ".##.......##.",
        ".............",
        ".............",
        ".............",
        ".............",
        ".............",
        ".##.......##.",
        ".##.......##.",
        ".............",
      ]);
    });

    _shapeTest("stays inside a floating selection and goes into it", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ColorReference color = GetIt.I.get<PaletteState>().selectedColor!;
      GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 2, y: 2), end: CoordinateSetI(x: 3, y: 3), selectShape: SelectShape.rectangle);
      await settle();

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 8, y: 8)]);
      await settle();

      expect(colorsOf(layer: layer), isEmpty, reason: "nothing lands on the layer while the selection floats");
      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 3, y: 3)), color);
      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 4, y: 4)), isNull);
    });

    _shapeTest("floats as a new selection when the preference asks for it", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.selectShapeAfterInsert.value = true;
      final ShapePainter painter = _painter();

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 2, y: 2)]);
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 2, y: 2)), GetIt.I.get<PaletteState>().selectedColor);
      expect(painter.hasHistoryData, isTrue);
    });

    _shapeTest("shifts existing pixels and leaves the empty ones when shading", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 2, y: 2): ramp[1], CoordinateSetI(x: 8, y: 8): ramp[1]}));
      await settle();
      final ShaderOptions shader = GetIt.I.get<ShaderOptions>();
      shader.isEnabled.value = true;
      shader.shaderDirection.value = ShaderDirection.right;
      shader.onlyCurrentRampEnabled.value = false;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 3)]);
      await settle();

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{CoordinateSetI(x: 2, y: 2): ramp[2], CoordinateSetI(x: 8, y: 8): ramp[1]});
    });

    for (final (String condition, void Function(DrawingLayerState) apply) refusal in <(String, void Function(DrawingLayerState))>[
      ("locked", (final DrawingLayerState layer) => layer.lockState.value = LayerLockState.locked),
      ("hidden", (final DrawingLayerState layer) => layer.visibilityState.value = LayerVisibilityState.hidden),
    ])
    {
      _shapeTest("draws nothing on a ${refusal.$1} layer", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        _useShape(shape: DrawingShape.rectangle);
        refusal.$2(layer);
        final ShapePainter painter = _painter();

        dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[_boxStart, _boxEnd]);
        await settle();

        expect(colorsOf(layer: layer), isEmpty);
        expect(painter.hasHistoryData, isFalse);
      });
    }

    _shapeTest("only draws over existing pixels on a transparency locked layer", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[1].references;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 2, y: 2): ramp[3]}));
      await settle();
      layer.lockState.value = LayerLockState.transparency;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 3)]);
      await settle();

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{CoordinateSetI(x: 2, y: 2): GetIt.I.get<PaletteState>().selectedColor!});
    });

    _shapeTest("keeps working after a drag that drew nothing", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      layer.lockState.value = LayerLockState.transparency;
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 3)]);
      await settle();
      expect(colorsOf(layer: layer), isEmpty, reason: "setup");
      expect(painter.hasHistoryData, isFalse);

      layer.lockState.value = LayerLockState.unlocked;
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: 3, y: 3)]);
      await settle();

      expect(colorsOf(layer: layer), hasLength(9));
    });

    _shapeTest("starts where it was pressed, with the last shape moved from there", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      final CoordinateSetI press = CoordinateSetI(x: 2, y: 2);
      final CoordinateSetI grown = CoordinateSetI(x: 4, y: 4);
      final CoordinateSetI moved = CoordinateSetI(x: 8, y: 4);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: press));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: press, primaryDown: true, pressStart: press));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: grown, primaryDown: true, pressStart: press));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: moved, primaryDown: true, pressStart: press, stylusButtonDown: true));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: moved, pressStart: press));
      await settle();
      painter.calculate(drawParams: toolParams(layer: layer, cursor: moved, pressStart: press));
      expect(colorsOf(layer: layer), contains(CoordinateSetI(x: 8, y: 2)), reason: "setup: the shape moved along");
      expect(colorsOf(layer: layer), isNot(contains(press)), reason: "setup: the shape moved along");
      layer.removeDataAll(removeCoordList: colorsOf(layer: layer).keys.toSet());
      await settle();

      //the canvas keeps the press position between presses
      painter.calculate(drawParams: toolParams(layer: layer, cursor: press, pressStart: press));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: press, primaryDown: true, pressStart: press));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 3, y: 3), primaryDown: true, pressStart: press));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 3, y: 3), pressStart: press));
      await settle();

      expect(colorsOf(layer: layer).keys.toSet(), <CoordinateSetI>{
        CoordinateSetI(x: 2, y: 2), CoordinateSetI(x: 3, y: 2),
        CoordinateSetI(x: 2, y: 3), CoordinateSetI(x: 3, y: 3),
      },);
    });

    _shapeTest("does not jump when the press starts with the move held", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      final CoordinateSetI spot = CoordinateSetI(x: 5, y: 5);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: spot));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: spot, primaryDown: true, pressStart: spot, stylusButtonDown: true));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: spot, pressStart: spot));
      await settle();

      expect(colorsOf(layer: layer).keys.toSet(), <CoordinateSetI>{spot});
    });

    _shapeTest("draws again on a click in the same place", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[1].references;
      final ShapePainter painter = _painter();
      final CoordinateSetI spot = CoordinateSetI(x: 4, y: 4);
      GetIt.I.get<PaletteState>().selectedColor = ramp[1];
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[spot]);
      await settle();
      painter.calculate(drawParams: toolParams(layer: layer, cursor: spot));
      expect(colorsOf(layer: layer)[spot], ramp[1], reason: "setup");

      GetIt.I.get<PaletteState>().selectedColor = ramp[2];
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[spot]);
      await settle();

      expect(colorsOf(layer: layer)[spot], ramp[2]);
    });
  });

  group("while dragging", ()
  {
    _shapeTest("the status bar and the cursor info show the size of the box", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 2);
      final CoordinateSetI end = CoordinateSetI(x: 5, y: 4);
      painter.calculate(drawParams: toolParams(layer: layer, cursor: start, primaryDown: true, pressStart: start));
      final DrawingParameters params = toolParams(layer: layer, cursor: end, primaryDown: true, pressStart: start);
      painter.calculate(drawParams: params);

      painter.setStatusBarData(drawParams: params);
      painter.drawCursorOutline(drawParams: params);

      expect(painter.statusBarData.cursorPos, end);
      expect(painter.statusBarData.dimension, CoordinateSetI(x: 5, y: 3));
      expect(painter.getCursorInfo(drawParams: params)!.dimension, CoordinateSetI(x: 5, y: 3));
    });

    _shapeTest("reset drops what was being drawn", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _useShape(shape: DrawingShape.rectangle);
      final ShapePainter painter = _painter();
      final CoordinateSetI start = CoordinateSetI(x: 1, y: 2);
      final DrawingParameters params = toolParams(layer: layer, cursor: CoordinateSetI(x: 5, y: 4), primaryDown: true, pressStart: start);
      painter.calculate(drawParams: params);

      painter.reset();
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 5, y: 4), pressStart: start));
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
      expect(painter.getCursorInfo(drawParams: params), isNull);
    });

    _shapeTest("the overlays cope with the cursor resting", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final ShapePainter painter = _painter();

      exerciseToolOverlays(painter: painter, layer: layer, cursor: CoordinateSetI(x: 5, y: 4));

      expect(painter.statusBarData.cursorPos, CoordinateSetI(x: 5, y: 4));
      expect(painter.statusBarData.dimension, isNull);
    });
  });
}
