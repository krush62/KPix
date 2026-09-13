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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/fill_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

//deliberately not square, so that mixing up x and y in a flat index shows
final CoordinateSetI _canvasSize = CoordinateSetI(x: 6, y: 4);
//a full-width wall: the side that gets filled then spans whole rows, which a
//wrong row stride in a flat index would fold onto each other
const int _wallY = 2;

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

DrawingParameters _params({required final CoordinateSetI cursor, required final bool primaryDown})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 1,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: Size(_canvasSize.x.toDouble(), _canvasSize.y.toDouble()),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: Offset.zero,
    pixelRatio: 1.0,
    currentLayer: GetIt.I.get<DocumentState>().timeline.getCurrentLayer()!,
    symmetryHorizontal: null,
    symmetryVertical: null,
    isPlaying: false,
  );
}

/// Presses the fill tool once at [start].
Future<void> _fillAt({required final CoordinateSetI start}) async
{
  final FillOptions fillOptions = GetIt.I.get<ToolOptions>().fillOptions;
  fillOptions.fillAdjacent.value = true;
  fillOptions.fillWholeRamp.value = false;
  final FillPainter painter = FillPainter(painterOptions: _painterOptions());
  painter.calculate(drawParams: _params(cursor: start, primaryDown: true));
  painter.drawExtras(drawParams: _params(cursor: start, primaryDown: true));
  await settle();
}

bool _aboveWall(final int y) => y < _wallY;

void main()
{
  final CoordinateSetI start = CoordinateSetI(x: 0, y: 1);

  testWidgets("a fill stops at a wall and leaves the other side alone", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference wall = palette.colorRamps.first.references[0];
      final ColorReference fill = palette.colorRamps.first.references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final CoordinateColorMapNullable wallPixels = CoordinateColorMapNullable();
      for (int x = 0; x < _canvasSize.x; x++)
      {
        wallPixels[CoordinateSetI(x: x, y: _wallY)] = wall;
      }
      layer.setDataAll(list: wallPixels);
      await settle();

      GetIt.I.get<ShaderOptions>().isEnabled.value = false;
      palette.colorSelected(color: fill, addToHistory: false);
      await _fillAt(start: start);

      for (int x = 0; x < _canvasSize.x; x++)
      {
        for (int y = 0; y < _canvasSize.y; y++)
        {
          final ColorReference? expected = _aboveWall(y) ? fill : (y == _wallY ? wall : null);
          expect(layer.getDataEntry(coord: CoordinateSetI(x: x, y: y)), expected, reason: "pixel $x|$y");
        }
      }
    },);
  });

  testWidgets("a shading fill stops at a wall and leaves the other side alone", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, select: true)! as ShadingLayerState;
      await settle();
      final HashMap<CoordinateSetI, int> wallValues = HashMap<CoordinateSetI, int>();
      for (int x = 0; x < _canvasSize.x; x++)
      {
        wallValues[CoordinateSetI(x: x, y: _wallY)] = -1;
      }
      shading.addCoords(coords: wallValues);
      await settle();
      expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(shading), reason: "setup: the fill has to land on the shading layer");

      GetIt.I.get<ShaderOptions>().shaderDirection.value = ShaderDirection.right;
      await _fillAt(start: start);

      for (int x = 0; x < _canvasSize.x; x++)
      {
        for (int y = 0; y < _canvasSize.y; y++)
        {
          final int? expected = _aboveWall(y) ? 1 : (y == _wallY ? -1 : null);
          expect(shading.getRawValueAt(coord: CoordinateSetI(x: x, y: y)), expected, reason: "pixel $x|$y");
        }
      }
    },);
  });

  testWidgets("the continuous wand stops at a wall", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final ColorReference wall = GetIt.I.get<PaletteState>().colorRamps.first.references[0];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final CoordinateColorMapNullable wallPixels = CoordinateColorMapNullable();
      for (int x = 0; x < _canvasSize.x; x++)
      {
        wallPixels[CoordinateSetI(x: x, y: _wallY)] = wall;
      }
      layer.setDataAll(list: wallPixels);
      await settle();

      final SelectionState selectionState = GetIt.I.get<DocumentState>().selectionState;
      GetIt.I.get<ToolOptions>().selectOptions.mode.value = SelectMode.replace;
      selectionState.newSelectionFromWand(coord: start, mode: SelectMode.replace, continuous: true, selectFromWholeRamp: false);
      await settle();

      for (int x = 0; x < _canvasSize.x; x++)
      {
        for (int y = 0; y < _canvasSize.y; y++)
        {
          expect(selectionState.selection.contains(coord: CoordinateSetI(x: x, y: y)), _aboveWall(y), reason: "pixel $x|$y");
        }
      }
    },);
  });
}
