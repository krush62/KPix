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
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/constraints/tool_spraycan_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/content_raster_set.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/painting/spray_can_painter.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/legacy_spray_can_painter.dart';
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

/// What [rasters] show when drawn in order, as RGBA per pixel, leaving out
/// what shows nothing.
Future<Map<String, int>> _composite({required final List<ContentRasterSet> rasters}) async
{
  final Map<String, int> pixels = <String, int>{};
  for (final ContentRasterSet raster in rasters)
  {
    final ByteData bytes = (await raster.image.toByteData())!;
    for (int y = 0; y < raster.image.height; y++)
    {
      for (int x = 0; x < raster.image.width; x++)
      {
        final int rgba = bytes.getUint32((y * raster.image.width + x) * 4);
        if ((rgba & 0xFF) != 0)
        {
          pixels["${raster.offset.x + x}|${raster.offset.y + y}"] = rgba;
        }
      }
    }
  }
  return pixels;
}

/// What [painter] shows once the images it is still making have arrived.
Future<Map<String, int>> _settledComposite({required final IToolPainter painter}) async
{
  Map<String, int> last = await _composite(rasters: painter.contentRasters);
  for (int i = 0; i < 20; i++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final Map<String, int> current = await _composite(rasters: painter.contentRasters);
    if (current.length == last.length && current.entries.every((final MapEntry<String, int> entry) => last[entry.key] == entry.value))
    {
      return current;
    }
    last = current;
  }
  return last;
}

/// Waits for [condition], giving up after about two seconds.
Future<void> _waitFor({required final bool Function() condition}) async
{
  for (int i = 0; i < 80 && !condition(); i++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// A spray can, current or legacy, driven by hand: [spray] sprays one blob,
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

  factory _SprayDriver.legacy({required final Random random})
  {
    final LegacySprayCanPainter painter = LegacySprayCanPainter(painterOptions: _painterOptions(), random: random);
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

enum _Target { layer, selection, shadingLayer }

class _Scenario
{
  final int blobSize;
  final double? symmetry;
  final _Target target;

  const _Scenario({required this.blobSize, this.symmetry, this.target = _Target.layer});

  @override
  String toString() => "blob size $blobSize, symmetry $symmetry, ${target.name}";
}

class _SprayResult
{
  final List<Map<String, int>> previews = <Map<String, int>>[];
  final Map<String, String> canvas = <String, String>{};
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 300, y: 300);

/// Sprays along a path across the tile borders at 128 with [createDriver], and
/// returns what the preview shows every few frames and what the canvas holds
/// once the spray landed.
Future<_SprayResult> _sprayStroke({required final WidgetTester tester, required final _Scenario scenario, required final _SprayDriver Function(Random random) createDriver}) async
{
  final _SprayResult result = _SprayResult();
  await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
    final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
    final ColorReference selected = ramps.first.references[2];
    String name(final ColorReference? color) => color == null ? "-" : "${ramps.indexOf(color.ramp)}:${color.colorIndex}";

    final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
    final CoordinateColorMapNullable content = CoordinateColorMapNullable();
    for (int x = 80; x < 200; x++)
    {
      for (int y = 80; y < 200; y++)
      {
        if ((x + y) % 5 == 0)
        {
          content[CoordinateSetI(x: x, y: y)] = selected;
        }
        else if ((x * y) % 7 == 1)
        {
          content[CoordinateSetI(x: x, y: y)] = ramps.first.references[4];
        }
      }
    }
    layer.setDataAll(list: content);
    await settle();

    GetIt.I.get<PaletteState>().colorSelected(color: selected);
    final SprayCanOptions options = GetIt.I.get<ToolOptions>().sprayCanOptions;
    options.radius.value = 14;
    options.blobSize.value = scenario.blobSize;
    options.intensity.value = SpraycanConstraints.intensityMin;
    GetIt.I.get<ShaderOptions>().isEnabled.value = false;
    GetIt.I.get<ShaderOptions>().shaderDirection.value = ShaderDirection.right;

    RasterableLayerState target = layer;
    switch (scenario.target)
    {
      case _Target.layer:
        break;
      case _Target.selection:
        GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 100, y: 90), end: CoordinateSetI(x: 150, y: 170), selectShape: SelectShape.rectangle);
        await settle();
        expect(GetIt.I.get<DocumentState>().selectionState.selection.isEmpty, isFalse, reason: "setup: the selection floats");
      case _Target.shadingLayer:
        target = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, select: true, addToHistoryStack: false)! as ShadingLayerState;
        await settle();
    }

    final _SprayDriver driver = createDriver(Random(scenario.blobSize * 31 + scenario.target.index));
    for (int step = 0; step < 40; step++)
    {
      final CoordinateSetI cursor = CoordinateSetI(x: 100 + step * 2, y: 110 + step + (step % 3));
      driver.hold(layer: target, cursor: cursor, symmetry: scenario.symmetry);
      for (int blob = 0; blob < 4; blob++)
      {
        driver.spray();
      }
      driver.hold(layer: target, cursor: cursor, symmetry: scenario.symmetry);
      if (step % 10 == 9)
      {
        result.previews.add(await _settledComposite(painter: driver.painter));
      }
    }
    //sprayed after the last frame, so only the dump sees these
    for (int blob = 0; blob < 5; blob++)
    {
      driver.spray();
    }
    driver.painter.calculate(drawParams: _params(layer: target, cursor: CoordinateSetI(x: 180, y: 150), primaryDown: false, symmetry: scenario.symmetry));
    await settle();
    await _waitFor(condition: () => driver.painter.contentRasters.isEmpty);
    result.previews.add(await _composite(rasters: driver.painter.contentRasters));

    for (int x = 60; x < 240; x++)
    {
      for (int y = 60; y < 240; y++)
      {
        final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        result.canvas["layer $x|$y"] = name(layer.getDataEntry(coord: coord));
        result.canvas["selection $x|$y"] = name(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: coord));
        if (target is ShadingLayerState)
        {
          result.canvas["shading $x|$y"] = "${target.getRawValueAt(coord: coord)}";
        }
      }
    }
  },);
  return result;
}

Iterable<String> _differences<T>({required final Map<String, T> expected, required final Map<String, T> actual})
{
  return <String>{...expected.keys, ...actual.keys}
      .where((final String key) => expected[key] != actual[key])
      .map((final String key) => "$key: ${expected[key]} became ${actual[key]}");
}

void main()
{
  group("a spray lands, and shows while it is sprayed, the same as before only the new pixels were worked out", () {
    const List<_Scenario> scenarios = <_Scenario>[
      _Scenario(blobSize: 1),
      _Scenario(blobSize: 3, symmetry: 150.0),
      _Scenario(blobSize: 2, target: _Target.selection),
      _Scenario(blobSize: 2, target: _Target.shadingLayer),
    ];
    for (final _Scenario scenario in scenarios)
    {
      testWidgets("$scenario", (final WidgetTester tester) async {
        final _SprayResult expected = await _sprayStroke(tester: tester, scenario: scenario, createDriver: (final Random random) => _SprayDriver.legacy(random: random));
        final _SprayResult actual = await _sprayStroke(tester: tester, scenario: scenario, createDriver: (final Random random) => _SprayDriver.current(random: random));

        expect(expected.previews.first, isNotEmpty, reason: "setup: the spray shows");
        expect(expected.previews.last, isEmpty, reason: "setup: the preview is gone once the spray landed");
        expect(actual.previews.length, expected.previews.length);
        for (int i = 0; i < expected.previews.length; i++)
        {
          expect(_differences(expected: expected.previews[i], actual: actual.previews[i]), isEmpty, reason: "preview ${i + 1} of ${expected.previews.length}");
        }
        expect(_differences(expected: expected.canvas, actual: actual.canvas), isEmpty, reason: "what landed");
      });
    }
  });

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
