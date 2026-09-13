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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_shading_layer.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

import 'support/selection_harness.dart';

/// A project saved by the version before the pixel storage moved to grids
/// (commit 1a7d045, file version 4). It holds, from the bottom up:
///
/// * a drawing layer with three pixels and a solid outer stroke,
/// * a shading layer with a step up and a step down,
/// * a dither layer with one step,
/// * a drawing layer whose single pixel was floating in a selection when the
///   file was written, so it belongs to the layer in the file.
const String _fixture = "test/assets/pre_grid_v4.kpix";

void main()
{
  testWidgets("a file written before the grids still loads", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 4), body: (final ProjectSession projectSession) async
    {
      final Uint8List bytes = await File(_fixture).readAsBytes();
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final LoadFileSet loaded = await loadKPixFile(
        fileData: bytes,
        path: _fixture,
        drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
        shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
        frameConstraints: prefs.frameConstraints,
      );
      expect(loaded.historyState, isNotNull, reason: loaded.status);

      final List<HistoryLayer> layers = loaded.historyState!.timeline.allLayers.toList();
      expect(loaded.historyState!.canvasSize, CoordinateSetI(x: 8, y: 6));
      expect(layers.length, 4);
      expect(layers.map((final HistoryLayer layer) => layer.runtimeType).toList(),
          <Type>[HistoryDrawingLayer, HistoryDitherLayer, HistoryShadingLayer, HistoryDrawingLayer],
          reason: "top to bottom: drawing, dither, shading, drawing",);

      final HistoryDrawingLayer top = layers[0] as HistoryDrawingLayer;
      expect(top.pixels.get(x: 3, y: 3), PaletteCodec.codeOf(rampIndex: 3, colorIndex: 1), reason: "the pixel that was floating in the selection");
      expect(top.pixels.nonZeroCount, 1);

      final HistoryShadingLayer dither = layers[1] as HistoryShadingLayer;
      expect(dither.pixels.getSigned(x: 5, y: 5), 2);
      expect(dither.pixels.nonZeroCount, 1);

      final HistoryShadingLayer shading = layers[2] as HistoryShadingLayer;
      expect(shading.pixels.getSigned(x: 4, y: 2), 1);
      expect(shading.pixels.getSigned(x: 4, y: 3), -1);
      expect(shading.pixels.nonZeroCount, 2);

      final HistoryDrawingLayer bottom = layers[3] as HistoryDrawingLayer;
      expect(bottom.pixels.get(x: 1, y: 1), PaletteCodec.codeOf(rampIndex: 0, colorIndex: 1));
      expect(bottom.pixels.get(x: 2, y: 1), PaletteCodec.codeOf(rampIndex: 1, colorIndex: 2));
      expect(bottom.pixels.get(x: 6, y: 4), PaletteCodec.codeOf(rampIndex: 2, colorIndex: 3));
      expect(bottom.pixels.nonZeroCount, 3);
      expect(bottom.settings.outerStrokeStyle, OuterStrokeStyle.solid, reason: "the solid outer stroke it was saved with");
    },);
  });
}
