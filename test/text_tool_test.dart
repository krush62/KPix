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

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/constraints/tool_text_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/font_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 14, y: 8);

TextOptions get _options => GetIt.I.get<ToolOptions>().textOptions;

Glyph _glyph({required final List<String> rows})
{
  final Glyph glyph = Glyph(width: rows.first.length, height: rows.length);
  for (int y = 0; y < rows.length; y++)
  {
    for (int x = 0; x < rows.first.length; x++)
    {
      glyph.setPixel(x: x, y: y, value: rows[y][x] == "#");
    }
  }
  return glyph;
}

/// A small font of known glyphs, which says exactly where each pixel has to land.
FontManager _testFont()
{
  return FontManager(kFontMap: <PixelFontType, KFont>{
    pixelFontIndexMap[TextConstraints.fontIndexDefault]!: KFont(name: "test", height: 3, glyphMap: <int, Glyph>{
      "A".codeUnitAt(0): _glyph(rows: <String>[
        "##",
        "#.",
        "##",
      ],),
      "B".codeUnitAt(0): _glyph(rows: <String>[
        "#",
        "#",
        "#",
      ],),
    },),
  },);
}

FontPainter _painter() => FontPainter(painterOptions: testPainterOptions());

void _textTest(final String description, final Future<void> Function(ProjectSession projectSession, DrawingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, fontManager: _testFont(), body: (final ProjectSession projectSession) async
    {
      await body(projectSession, layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

void main()
{
  group("the text", ()
  {
    _textTest("lands up and to the left of the cursor in the selected color", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "A";
      final FontPainter painter = _painter();

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 5)]);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), <String>[
        "..............",
        "..............",
        "...##.........",
        "...#..........",
        "...##.........",
        "..............",
        "..............",
        "..............",
      ]);
      expect(colorsOf(layer: layer).values.toSet(), <ColorReference>{GetIt.I.get<PaletteState>().selectedColor!});
      expect(painter.hasHistoryData, isTrue);
      expect(painter.historyIdentifier, HistoryStateTypeIdentifier.toolText);
    });

    _textTest("leaves a pixel between its letters and skips what the font does not have", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "A?B";

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 8, y: 5)]);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), <String>[
        "..............",
        "..............",
        "...##.#.......",
        "...#..#.......",
        "...##.#.......",
        "..............",
        "..............",
        "..............",
      ]);
    });

    _textTest("grows with its size", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "A";
      _options.size.value = 2;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 8, y: 7)]);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), <String>[
        "..............",
        "..####........",
        "..####........",
        "..##..........",
        "..##..........",
        "..####........",
        "..####........",
        "..............",
      ]);
    });

    _textTest("is cut off at the edge of the canvas", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "A";

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 1, y: 1)]);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize).first, "..............", reason: "nothing lands on the wrong side");
      expect(colorsOf(layer: layer), isEmpty);
    });

    _textTest("is mirrored along the symmetry axis", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "B";

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 5, y: 3)], symmetryHorizontal: 7.0);
      await settle();

      expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), <String>[
        "...#......#...",
        "...#......#...",
        "...#......#...",
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
      ]);
    });

    _textTest("goes into a floating selection", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "B";
      GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 0, y: 0), end: CoordinateSetI(x: 8, y: 1), selectShape: SelectShape.rectangle);
      await settle();

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 5, y: 3)]);
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 3, y: 1)), GetIt.I.get<PaletteState>().selectedColor);
      expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 3, y: 2)), isNull);
    });

    _textTest("shifts existing pixels when shading", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "B";
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 3, y: 1): ramp[1]}));
      await settle();
      final ShaderOptions shader = GetIt.I.get<ShaderOptions>();
      shader.isEnabled.value = true;
      shader.shaderDirection.value = ShaderDirection.right;
      shader.onlyCurrentRampEnabled.value = false;

      dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 5, y: 3)]);
      await settle();

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{CoordinateSetI(x: 3, y: 1): ramp[2]});
    });

    for (final (String condition, void Function(DrawingLayerState) apply) refusal in <(String, void Function(DrawingLayerState))>[
      ("locked", (final DrawingLayerState layer) => layer.lockState.value = LayerLockState.locked),
      ("hidden", (final DrawingLayerState layer) => layer.visibilityState.value = LayerVisibilityState.hidden),
    ])
    {
      _textTest("is not drawn on a ${refusal.$1} layer", (final ProjectSession projectSession, final DrawingLayerState layer) async
      {
        _options.text.value = "A";
        refusal.$2(layer);
        final FontPainter painter = _painter();

        dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 5)]);
        await settle();

        expect(colorsOf(layer: layer), isEmpty);
        expect(painter.hasHistoryData, isFalse);
      });
    }

    _textTest("made only of letters the font does not have leaves no undo step", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      _options.text.value = "??";
      final FontPainter painter = _painter();

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 5)]);
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
      expect(painter.hasHistoryData, isFalse);
    });
  });

  group("on a shading layer", ()
  {
    _textTest("the letters shade instead of color", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
      await settle();
      _options.text.value = "B";
      GetIt.I.get<ShaderOptions>().shaderDirection.value = ShaderDirection.right;
      final FontPainter painter = _painter();

      dragTool(painter: painter, layer: shading, path: <CoordinateSetI>[CoordinateSetI(x: 5, y: 3)]);
      await settle();

      expect(shadesOf(layer: shading), <CoordinateSetI, int>{for (int y = 0; y < 3; y++) CoordinateSetI(x: 3, y: y): 1});
      expect(painter.hasHistoryData, isTrue);
      expect(colorsOf(layer: layer), isEmpty);
    });
  });

  group("the tool", ()
  {
    _textTest("draws again after the text changed", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final FontPainter painter = _painter();
      final CoordinateSetI at = CoordinateSetI(x: 5, y: 3);
      _options.text.value = "B";
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[at]);
      await settle();
      final int before = colorsOf(layer: layer).length;

      _options.text.value = "A";
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[at]);
      await settle();

      expect(colorsOf(layer: layer).length, greaterThan(before));
    });

    _textTest("shows a preview that goes away with the cursor", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final FontPainter painter = _painter();
      _options.text.value = "A";

      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5)));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(painter.cursorRaster, isNotNull);
      expect(painter.hasAsyncUpdate, isTrue);

      painter.calculate(drawParams: toolParams(layer: layer, cursor: null));
      expect(painter.cursorRaster, isNull);
    });

    _textTest("the overlays cope with the cursor resting", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final FontPainter painter = _painter();
      _options.text.value = "A";

      exerciseToolOverlays(painter: painter, layer: layer, cursor: CoordinateSetI(x: 6, y: 5));

      expect(painter.statusBarData.cursorPos, CoordinateSetI(x: 6, y: 5));
    });

    _textTest("reset forgets a press that has not ended", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      final FontPainter painter = _painter();
      _options.text.value = "A";
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5), primaryDown: true));

      painter.reset();
      painter.calculate(drawParams: toolParams(layer: layer, cursor: CoordinateSetI(x: 6, y: 5)));
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
    });
  });

  group("with the real fonts", ()
  {
    testWidgets("the default text lands inside of the box above and left of the cursor", (final WidgetTester tester) async
    {
      final Map<PixelFontType, KFont> fonts = (await tester.runAsync(FontManager.readFonts))!;
      final CoordinateSetI size = CoordinateSetI(x: 200, y: 40);
      await withProject(tester: tester, canvasSize: size, fontManager: FontManager(kFontMap: fonts), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
        final CoordinateSetI cursor = CoordinateSetI(x: 190, y: 35);
        final PixelFontType type = pixelFontIndexMap[TextConstraints.fontIndexDefault]!;
        _options.text.value = "Ag";

        dragTool(painter: _painter(), layer: layer, path: <CoordinateSetI>[cursor]);
        await settle();

        final Iterable<CoordinateSetI> pixels = colorsOf(layer: layer).keys;
        expect(pixels, isNotEmpty);
        final KFont font = fonts[type]!;
        final int width = font.glyphMap["A".codeUnitAt(0)]!.width + font.glyphMap["g".codeUnitAt(0)]!.width + 2;
        for (final CoordinateSetI p in pixels)
        {
          expect(p.x, inInclusiveRange(cursor.x - width, cursor.x - 1), reason: "$p");
          expect(p.y, inInclusiveRange(cursor.y - font.height, cursor.y - 1), reason: "$p");
        }
      },);
    }, timeout: const Timeout(Duration(minutes: 2)),);

    testWidgets("every font has the letters of the default text", (final WidgetTester tester) async
    {
      final Map<PixelFontType, KFont> fonts = (await tester.runAsync(FontManager.readFonts))!;

      expect(fonts.keys, containsAll(pixelFontIndexMap.values.toSet().intersection(HashSet<PixelFontType>.of(fonts.keys))));
      for (final MapEntry<PixelFontType, KFont> font in fonts.entries)
      {
        expect(font.value.height, greaterThan(0), reason: font.key.name);
        expect(font.value.glyphMap, isNotEmpty, reason: font.key.name);
      }
    }, timeout: const Timeout(Duration(minutes: 2)),);
  });
}
