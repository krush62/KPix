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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/painting/stamp_painter.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 12, y: 8);
final CoordinateSetI _cursor = CoordinateSetI(x: 6, y: 5);

StampOptions get _options => GetIt.I.get<ToolOptions>().stampOptions;
List<ColorReference> get _ramp => GetIt.I.get<PaletteState>().colorRamps[0].references;

/// An L of three pixels in a box of two by two. The last one is lighter by one.
///
///     #.
///     ##
void _selectStamp()
{
  GetIt.I.registerSingleton<StampManager>(StampManager());
  GetIt.I.get<StampManager>().selectedStamp.value = StampManagerEntryData(
    path: "",
    thumbnail: null,
    name: "stamp",
    isLocked: false,
    data: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 0, y: 0): 0, CoordinateSetI(x: 0, y: 1): 0, CoordinateSetI(x: 1, y: 1): 1}),
    width: 2,
    height: 2,
  );
}

void _stampTest(final String description, final Future<void> Function(ProjectSession projectSession, DrawingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      _selectStamp();
      GetIt.I.get<PaletteState>().selectedColor = _ramp[1];
      await body(projectSession, layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

StampPainter _painter() => StampPainter(painterOptions: testPainterOptions());

Future<void> _stampAt({required final StampPainter painter, required final DrawingLayerState layer, final CoordinateSetI? at, final double? symmetryHorizontal}) async
{
  dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[at ?? _cursor], symmetryHorizontal: symmetryHorizontal);
  await settle();
}

void main()
{
  _stampTest("lands up and to the left of the cursor, shifted by its own values", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    final StampPainter painter = _painter();

    await _stampAt(painter: painter, layer: layer);

    expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{
      CoordinateSetI(x: 4, y: 3): _ramp[1],
      CoordinateSetI(x: 4, y: 4): _ramp[1],
      CoordinateSetI(x: 5, y: 4): _ramp[2],
    });
    expect(painter.hasHistoryData, isTrue);
    expect(painter.historyIdentifier, HistoryStateTypeIdentifier.toolStamp);
  });

  _stampTest("grows with its scale", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    _options.scale.value = 2;

    await _stampAt(painter: _painter(), layer: layer, at: CoordinateSetI(x: 8, y: 6));

    expect(patternOf(coords: colorsOf(layer: layer).keys, size: _canvasSize), <String>[
      "............",
      "............",
      "....##......",
      "....##......",
      "....####....",
      "....####....",
      "............",
      "............",
    ]);
  });

  _stampTest("flips horizontally", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    _options.flipH.value = true;

    await _stampAt(painter: _painter(), layer: layer);

    expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{
      CoordinateSetI(x: 5, y: 3): _ramp[1],
      CoordinateSetI(x: 5, y: 4): _ramp[1],
      CoordinateSetI(x: 4, y: 4): _ramp[2],
    });
  });

  _stampTest("flips vertically", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    _options.flipV.value = true;

    await _stampAt(painter: _painter(), layer: layer);

    expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{
      CoordinateSetI(x: 4, y: 4): _ramp[1],
      CoordinateSetI(x: 4, y: 3): _ramp[1],
      CoordinateSetI(x: 5, y: 3): _ramp[2],
    });
  });

  _stampTest("snaps to its own grid when asked to", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    _options.gridAlign.value = true;

    await _stampAt(painter: _painter(), layer: layer, at: CoordinateSetI(x: 7, y: 5));

    expect(colorsOf(layer: layer).keys.toSet(), <CoordinateSetI>{CoordinateSetI(x: 6, y: 4), CoordinateSetI(x: 6, y: 5), CoordinateSetI(x: 7, y: 5)});
  });

  _stampTest("moves the grid by its offset", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    _options.gridAlign.value = true;
    _options.gridOffsetX.value = 1;
    _options.gridOffsetY.value = 1;

    await _stampAt(painter: _painter(), layer: layer, at: CoordinateSetI(x: 7, y: 5));

    expect(colorsOf(layer: layer).keys.toSet(), <CoordinateSetI>{CoordinateSetI(x: 7, y: 5), CoordinateSetI(x: 7, y: 6), CoordinateSetI(x: 8, y: 6)});
  });

  _stampTest("is mirrored along the symmetry axis", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    await _stampAt(painter: _painter(), layer: layer, symmetryHorizontal: 6.0);

    expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{
      CoordinateSetI(x: 4, y: 3): _ramp[1],
      CoordinateSetI(x: 4, y: 4): _ramp[1],
      CoordinateSetI(x: 5, y: 4): _ramp[2],
      CoordinateSetI(x: 7, y: 3): _ramp[1],
      CoordinateSetI(x: 7, y: 4): _ramp[1],
      CoordinateSetI(x: 6, y: 4): _ramp[2],
    });
  });

  _stampTest("is cut off at the edge of the canvas", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    await _stampAt(painter: _painter(), layer: layer, at: CoordinateSetI(x: 1, y: 2));

    expect(colorsOf(layer: layer).keys.toSet(), <CoordinateSetI>{CoordinateSetI(x: 0, y: 1), CoordinateSetI(x: 0, y: 0)}.intersection(colorsOf(layer: layer).keys.toSet()));
    expect(colorsOf(layer: layer).keys.every((final CoordinateSetI p) => p.x >= 0 && p.y >= 0), isTrue);
  });

  _stampTest("goes into a floating selection and stays inside of it", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 0, y: 0), end: CoordinateSetI(x: 11, y: 3), selectShape: SelectShape.rectangle);
    await settle();

    await _stampAt(painter: _painter(), layer: layer);

    expect(colorsOf(layer: layer), isEmpty);
    expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 4, y: 3)), _ramp[1]);
    expect(GetIt.I.get<DocumentState>().selectionState.selection.contains(coord: CoordinateSetI(x: 4, y: 4)), isFalse);
  });

  for (final (ShaderDirection direction, int first, int second) shading in <(ShaderDirection, int, int)>[(ShaderDirection.right, 3, 4), (ShaderDirection.left, 1, 0)])
  {
    _stampTest("steps existing pixels ${shading.$1.name} when shading", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): _ramp[2], CoordinateSetI(x: 5, y: 4): _ramp[2]}));
      await settle();
      final ShaderOptions shader = GetIt.I.get<ShaderOptions>();
      shader.isEnabled.value = true;
      shader.shaderDirection.value = shading.$1;
      shader.onlyCurrentRampEnabled.value = false;

      await _stampAt(painter: _painter(), layer: layer);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{CoordinateSetI(x: 4, y: 3): _ramp[shading.$2], CoordinateSetI(x: 5, y: 4): _ramp[shading.$3]});
    });
  }

  _stampTest("only shades the current ramp when bound to it", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    final ColorReference other = GetIt.I.get<PaletteState>().colorRamps[1].references[2];
    layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): other, CoordinateSetI(x: 5, y: 4): _ramp[2]}));
    await settle();
    final ShaderOptions shader = GetIt.I.get<ShaderOptions>();
    shader.isEnabled.value = true;
    shader.shaderDirection.value = ShaderDirection.right;
    shader.onlyCurrentRampEnabled.value = true;

    await _stampAt(painter: _painter(), layer: layer);

    expect(colorsOf(layer: layer)[CoordinateSetI(x: 4, y: 3)], other);
    expect(colorsOf(layer: layer)[CoordinateSetI(x: 5, y: 4)], _ramp[4]);
  });

  for (final (String condition, void Function(DrawingLayerState) apply) refusal in <(String, void Function(DrawingLayerState))>[
    ("locked", (final DrawingLayerState layer) => layer.lockState.value = LayerLockState.locked),
    ("hidden", (final DrawingLayerState layer) => layer.visibilityState.value = LayerVisibilityState.hidden),
  ])
  {
    _stampTest("is not drawn on a ${refusal.$1} layer", (final ProjectSession projectSession, final DrawingLayerState layer) async
    {
      refusal.$2(layer);
      final StampPainter painter = _painter();

      await _stampAt(painter: painter, layer: layer);

      expect(colorsOf(layer: layer), isEmpty);
      expect(painter.hasHistoryData, isFalse);
    });
  }

  _stampTest("only draws over existing pixels on a transparency locked layer", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): _ramp[0]}));
    await settle();
    layer.lockState.value = LayerLockState.transparency;

    await _stampAt(painter: _painter(), layer: layer);

    expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{CoordinateSetI(x: 4, y: 3): _ramp[1]});
  });

  _stampTest("draws nothing without a stamp selected", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    GetIt.I.get<StampManager>().selectedStamp.value = null;

    await _stampAt(painter: _painter(), layer: layer);

    expect(colorsOf(layer: layer), isEmpty);
  });

  _stampTest("shows a preview that goes away with the cursor", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    final StampPainter painter = _painter();
    painter.calculate(drawParams: toolParams(layer: layer, cursor: _cursor));
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(painter.cursorRaster, isNotNull);
    expect(painter.hasAsyncUpdate, isTrue);

    painter.calculate(drawParams: toolParams(layer: layer, cursor: null));
    expect(painter.cursorRaster, isNull);
  });

  _stampTest("the overlays cope with the cursor resting and leaving", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    final StampPainter painter = _painter();

    exerciseToolOverlays(painter: painter, layer: layer, cursor: _cursor);
    expect(painter.statusBarData.cursorPos, _cursor);

    _options.gridAlign.value = true;
    exerciseToolOverlays(painter: painter, layer: layer, cursor: _cursor);

    painter.setStatusBarData(drawParams: toolParams(layer: layer, cursor: null));
    expect(painter.statusBarData.cursorPos, isNull);
  });

  _stampTest("reset forgets a press that has not ended", (final ProjectSession projectSession, final DrawingLayerState layer) async
  {
    final StampPainter painter = _painter();
    painter.calculate(drawParams: toolParams(layer: layer, cursor: _cursor, primaryDown: true));

    painter.reset();
    painter.calculate(drawParams: toolParams(layer: layer, cursor: _cursor));
    await settle();

    expect(colorsOf(layer: layer), isEmpty);
  });
}
