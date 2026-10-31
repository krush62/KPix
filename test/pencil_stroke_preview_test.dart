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
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/content_raster_set.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/stroke_preview.dart';
import 'package:kpix/tool_options/tool_options.dart';
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

/// Waits for [condition], giving up after about two seconds.
Future<void> _waitFor({required final bool Function() condition}) async
{
  for (int i = 0; i < 80 && !condition(); i++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 300, y: 300);

void main()
{
  group("a stroke preview", () {
    const int red = 0xFF0000FF;
    const int green = 0x00FF00FF;
    const int blue = 0x0000FFFF;

    testWidgets("shows settled pixels across tile borders with the tip on top", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        int updates = 0;
        final StrokePreview preview = StrokePreview(onUpdate: () => updates++);
        final Map<String, int> expected = <String, int>{};
        void settle(final int x, final int y, final int rgba)
        {
          preview.addPixel(x: x, y: y, rgba: rgba);
          expected["$x|$y"] = rgba;
        }
        settle(0, 0, red);
        settle(127, 127, red);
        settle(128, 127, red);
        settle(127, 128, green);
        settle(300, 5, green);
        settle(129, 129, red);
        settle(129, 129, blue);
        preview.setTip(pixels: <CoordinateSetI, int>{CoordinateSetI(x: 128, y: 127): blue, CoordinateSetI(x: 2, y: 3): green});
        expected["128|127"] = blue;
        expected["2|3"] = green;

        await preview.render();

        expect(updates, 1);
        expect(await _composite(rasters: preview.rasters), expected);
      });
    });

    testWidgets("renders only the tiles that changed, and replaces the tip as a whole", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final StrokePreview preview = StrokePreview(onUpdate: () {});
        preview.addPixel(x: 10, y: 10, rgba: red);
        preview.addPixel(x: 200, y: 10, rgba: red);
        preview.setTip(pixels: <CoordinateSetI, int>{CoordinateSetI(x: 20, y: 20): green});
        await preview.render();
        final List<ContentRasterSet> before = preview.rasters;
        expect(before.length, 3, reason: "setup: two tiles and the tip");

        preview.addPixel(x: 11, y: 10, rgba: blue);
        preview.setTip(pixels: <CoordinateSetI, int>{CoordinateSetI(x: 12, y: 10): green});
        await preview.render();
        final List<ContentRasterSet> after = preview.rasters;

        expect(after[1], same(before[1]), reason: "nothing was written to the second tile, so its image stays");
        expect(after[0], isNot(same(before[0])));
        expect(await _composite(rasters: after), <String, int>{"10|10": red, "11|10": blue, "200|10": red, "12|10": green},
            reason: "the tip of the last frame is gone",);

        preview.addPixel(x: 13, y: 10, rgba: red);
        await preview.render();
        expect(preview.rasters.last, same(after.last), reason: "an unchanged tip keeps its image");
      });
    });

    testWidgets("drops what it holds when disposed, also from a render still running", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        int updates = 0;
        final StrokePreview preview = StrokePreview(onUpdate: () => updates++);
        preview.addPixel(x: 1, y: 1, rgba: red);
        preview.setTip(pixels: <CoordinateSetI, int>{CoordinateSetI(x: 2, y: 2): red});
        final Future<void> running = preview.render();
        preview.dispose();
        await running;

        expect(preview.rasters, isEmpty);
        expect(updates, 0);
      });
    });
  });

  testWidgets("a landing stroke leaves the preview of the next stroke alone", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());

      painter.strokePreview.addPixel(x: 5, y: 5, rgba: 0xFF0000FF);
      await painter.strokePreview.render();
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 5, y: 5): color}));
      painter.resetContentRaster(currentLayer: layer);

      painter.strokePreview.addPixel(x: 200, y: 200, rgba: 0x00FF00FF);
      await painter.strokePreview.render();
      expect((await _composite(rasters: painter.contentRasters)).keys, containsAll(<String>["5|5", "200|200"]),
          reason: "setup: the first stroke has not landed yet, so both show",);

      await settle();
      await _waitFor(condition: () => painter.contentRasters.length == 1);

      expect(await _composite(rasters: painter.contentRasters), <String, int>{"200|200": 0x00FF00FF});
    },);
  });

  testWidgets("a landing stroke stays on the canvas until the shading above it has caught up", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      GetIt.I.get<PaletteState>().colorSelected(color: color);
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, addToHistoryStack: false).$2! as ShadingLayerState;
      final HashMap<CoordinateSetI, int> shades = HashMap<CoordinateSetI, int>();
      for (int x = 100; x < 200; x++)
      {
        for (int y = 100; y < 200; y++)
        {
          shades[CoordinateSetI(x: x, y: y)] = 1;
        }
      }
      shading.addCoords(coords: shades);
      await settle();
      await _waitFor(condition: () => !shading.doManualRaster && !shading.isRasterizing);
      expect(GetIt.I.get<DocumentState>().timeline.getCurrentLayer(), same(layer), reason: "setup: the shading went above the drawn layer");

      GetIt.I.get<ToolOptions>().pencilOptions.size.value = 3;
      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
      for (int x = 120; x < 160; x++)
      {
        painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: x, y: 150), primaryDown: true));
      }
      await _waitFor(condition: () => painter.contentRasters.isNotEmpty);
      expect(painter.contentRasters, isNotEmpty, reason: "setup: the stroke shows");

      //the stroke lands: the layer takes the pixels, and the shading above is
      //asked for a raster once the layer has stored its own
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 159, y: 150), primaryDown: false));

      //the content is what shows the stroke shaded while the shading above still
      //shows what it made of the layer as it was, so it may not go before that
      //raster is in; a moment where neither is there is the flicker
      int flickers = 0;
      for (int i = 0; i < 400; i++)
      {
        final bool shadingPending = shading.doManualRaster || shading.isRasterizing;
        final bool contentGone = painter.contentRasters.isEmpty;
        if (contentGone && shadingPending)
        {
          flickers++;
        }
        if (contentGone && !shadingPending && layer.rasterQueue.isEmpty && !layer.doManualRaster && !layer.isRasterizing)
        {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(painter.contentRasters, isEmpty, reason: "the content is taken off the canvas once everything shows the stroke");
      expect(flickers, 0);
    },);
  });

  testWidgets("switching tools throws the preview of an unfinished stroke away", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      GetIt.I.get<ToolOptions>().pencilOptions.size.value = 3;
      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
      for (int x = 10; x < 30; x++)
      {
        painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: x, y: 10), primaryDown: true));
      }
      await _waitFor(condition: () => painter.contentRasters.isNotEmpty);
      expect(painter.contentRasters, isNotEmpty, reason: "setup: the stroke shows");

      painter.reset();

      expect(painter.contentRasters, isEmpty);
    },);
  });
}
