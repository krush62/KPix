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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
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

DrawingParameters _params({
  required final AppState appState,
  required final CoordinateSetI cursor,
  required final bool primaryDown,
})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 1,
    canvasSize: appState.canvasSize,
    drawingSize: const Size(4, 4),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: Offset.zero,
    pixelRatio: 1.0,
    currentLayer: appState.timeline.getCurrentLayer()!,
    symmetryHorizontal: null,
    symmetryVertical: null,
    isPlaying: false,
  );
}

Future<void> _tick({
  required final PencilPainter painter,
  required final AppState appState,
  required final CoordinateSetI cursor,
  required final bool primaryDown,
}) async
{
  painter.calculate(drawParams: _params(appState: appState, cursor: cursor, primaryDown: primaryDown));
  await Future<void>.delayed(const Duration(milliseconds: 40));
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 1);

  testWidgets("the shading preview refreshes after a stroke lands on the same pixel", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference start = GetIt.I.get<PaletteState>().colorRamps.first.references[1];
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: start}));
      await settle(appState: appState);

      final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
      shaderOptions.isEnabled.value = true;
      shaderOptions.shaderDirection.value = ShaderDirection.right;
      shaderOptions.onlyCurrentRampEnabled.value = false;

      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());

      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);
      final ContentRasterSet? beforeStroke = painter.cursorRaster;
      expect(beforeStroke, isNotNull, reason: "setup: the preview was computed for the pixel under the cursor");

      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: true);
      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);
      expect(layer.getDataEntry(coord: pixel), isNot(start), reason: "setup: the stroke shaded the pixel");

      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);

      expect(painter.cursorRaster, isNot(same(beforeStroke)),
          reason: "the pixel under the cursor changed, so the preview has to be computed again",);
    },);
  });

  testWidgets("the preview waits for the stroke to land before refreshing", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference start = GetIt.I.get<PaletteState>().colorRamps.first.references[1];
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: start}));
      await settle(appState: appState);

      final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
      shaderOptions.isEnabled.value = true;
      shaderOptions.shaderDirection.value = ShaderDirection.right;
      shaderOptions.onlyCurrentRampEnabled.value = false;

      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);
      final ContentRasterSet? beforeStroke = painter.cursorRaster;

      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: true);
      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);

      layer.isRasterizing = true;
      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);
      expect(painter.cursorRaster, same(beforeStroke),
          reason: "the stroke is still in flight; swapping the preview now shows the next shade over a stroke that has not landed",);

      layer.isRasterizing = false;
      await settle(appState: appState);
      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);

      expect(painter.cursorRaster, isNot(same(beforeStroke)),
          reason: "once the stroke has landed the preview catches up",);
    },);
  });

  testWidgets("a preview that has nothing to react to is left alone", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference start = GetIt.I.get<PaletteState>().colorRamps.first.references[1];
      final DrawingLayerState layer = layerAt(appState: appState, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: start}));
      await settle(appState: appState);

      final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
      shaderOptions.isEnabled.value = true;
      shaderOptions.shaderDirection.value = ShaderDirection.right;

      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);
      final ContentRasterSet? first = painter.cursorRaster;

      await _tick(painter: painter, appState: appState, cursor: pixel, primaryDown: false);

      expect(painter.cursorRaster, same(first),
          reason: "an idle frame with the cursor unmoved must not rebuild the preview every tick",);
    },);
  });
}
