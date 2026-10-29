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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_spraycan_constraints.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/painting/spray_can_painter.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
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

DrawingParameters _params({required final LayerState layer, required final CoordinateSetI cursor, required final bool primaryDown, final double? symmetry})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 1,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: const Size(4, 4),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: Offset.zero,
    pixelRatio: 1.0,
    currentLayer: layer,
    symmetryHorizontal: symmetry,
    symmetryVertical: symmetry,
    isPlaying: false,
  );
}

/// Waits for [condition], giving up after about two seconds.
Future<void> _waitFor({required final bool Function() condition}) async
{
  for (int i = 0; i < 80 && !condition(); i++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// A spray can driven by hand: [spray] sprays one blob,
/// and [stopTimer] stops the timer that would otherwise spray on its own.
class _SprayDriver
{
  final IToolPainter painter;
  final void Function() spray;
  final void Function() stopTimer;

  const _SprayDriver({required this.painter, required this.spray, required this.stopTimer});

  factory _SprayDriver.current({required final Random random})
  {
    final SprayCanPainter painter = SprayCanPainter(painterOptions: _painterOptions(), random: random);
    return _SprayDriver(painter: painter, spray: painter.spray, stopTimer: () {if (painter.timerInitialized) painter.timer.cancel();});
  }

  /// One frame with the button held at [cursor].
  void hold({required final LayerState layer, required final CoordinateSetI cursor, final double? symmetry})
  {
    painter.calculate(drawParams: _params(layer: layer, cursor: cursor, primaryDown: true, symmetry: symmetry));
    //no event loop turn has passed since the timer was started
    stopTimer();
  }
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 300, y: 300);

void main()
{
  testWidgets("a spray keeps the color it was sprayed with when the color changes halfway", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final SprayCanOptions options = GetIt.I.get<ToolOptions>().sprayCanOptions;
      options.radius.value = 6;
      options.blobSize.value = 2;
      options.intensity.value = SpraycanConstraints.intensityMin;
      GetIt.I.get<ShaderOptions>().isEnabled.value = false;
      final _SprayDriver driver = _SprayDriver.current(random: Random(5));

      GetIt.I.get<PaletteState>().colorSelected(color: colors[1]);
      driver.hold(layer: layer, cursor: CoordinateSetI(x: 40, y: 40));
      for (int blob = 0; blob < 10; blob++)
      {
        driver.spray();
      }
      driver.hold(layer: layer, cursor: CoordinateSetI(x: 40, y: 40));

      GetIt.I.get<PaletteState>().colorSelected(color: colors[3]);
      driver.hold(layer: layer, cursor: CoordinateSetI(x: 200, y: 200));
      for (int blob = 0; blob < 10; blob++)
      {
        driver.spray();
      }
      driver.hold(layer: layer, cursor: CoordinateSetI(x: 200, y: 200));
      driver.painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 200, y: 200), primaryDown: false));
      await settle();

      final Set<ColorReference?> firstHalf = <ColorReference?>{};
      final Set<ColorReference?> secondHalf = <ColorReference?>{};
      for (int x = 30; x <= 50; x++)
      {
        for (int y = 30; y <= 50; y++)
        {
          firstHalf.add(layer.getDataEntry(coord: CoordinateSetI(x: x, y: y)));
          secondHalf.add(layer.getDataEntry(coord: CoordinateSetI(x: x + 160, y: y + 160)));
        }
      }
      expect(secondHalf, contains(colors[3]), reason: "setup: the second half landed");
      expect(firstHalf.whereType<ColorReference>(), isNotEmpty, reason: "setup: the first half landed");
      expect(firstHalf.whereType<ColorReference>(), everyElement(colors[1]),
          reason: "the first half showed in the first color while it was sprayed, and has to land in it",);
    },);
  });

  testWidgets("switching tools throws the preview of an unfinished spray away", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      GetIt.I.get<ToolOptions>().sprayCanOptions.intensity.value = SpraycanConstraints.intensityMin;
      final _SprayDriver driver = _SprayDriver.current(random: Random(9));
      driver.hold(layer: layer, cursor: CoordinateSetI(x: 50, y: 50));
      for (int blob = 0; blob < 10; blob++)
      {
        driver.spray();
      }
      driver.hold(layer: layer, cursor: CoordinateSetI(x: 50, y: 50));
      await _waitFor(condition: () => driver.painter.contentRasters.isNotEmpty);
      expect(driver.painter.contentRasters, isNotEmpty, reason: "setup: the spray shows");

      driver.painter.reset();

      expect(driver.painter.contentRasters, isEmpty);
    },);
  });
}
