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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_drawing_layer_settings.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';

const DrawingLayerSettingsConstraints _drawingConstraints = DrawingLayerSettingsConstraints(
  darkenBrightenMin: -5,
  darkenBrightenDefault: 1,
  darkenBrightenMax: 5,
  glowDepthMin: -5,
  glowDepthDefault: 1,
  glowDepthMax: 5,
  glowRecursiveDefault: false,
  bevelDistanceMin: 1,
  bevelDistanceDefault: 2,
  bevelDistanceMax: 8,
  bevelStrengthMin: 1,
  bevelStrengthDefault: 2,
  bevelStrengthMax: 8,
  dropShadowOffsetMin: -8,
  dropShadowOffsetDefault: 2,
  dropShadowOffsetMax: 8,
);

const ShadingLayerSettingsConstraints _shadingConstraints = ShadingLayerSettingsConstraints(
  shadingStepsMin: 1,
  shadingStepsDefaultBrighten: 1,
  shadingStepsDefaultDarken: 1,
  shadingStepsMax: 5,
  ditherStepsMax: 5,
);

const FrameConstraints _frameConstraints = FrameConstraints(minFps: 1, maxFps: 60, defaultFps: 10);

/// A drawing layer record holding the two map shapes that have to survive the
/// hop: pixels keyed by [CoordinateSetI] and edges keyed by [Alignment].
HistoryDrawingLayer _sampleLayer()
{
  final HashMap<CoordinateSetI, HistoryColorReference> pixels = HashMap<CoordinateSetI, HistoryColorReference>();
  for (int x = 0; x < 4; x++)
  {
    for (int y = 0; y < 4; y++)
    {
      pixels[CoordinateSetI(x: x, y: y)] = HistoryColorReference(colorIndex: (x + y) % 3, rampIndex: 0);
    }
  }

  final HashMap<Alignment, bool> outerMap = HashMap<Alignment, bool>();
  outerMap[Alignment.topLeft] = true;
  outerMap[Alignment.bottomRight] = false;
  final HashMap<Alignment, bool> innerMap = HashMap<Alignment, bool>();
  innerMap[Alignment.centerLeft] = true;

  return HistoryDrawingLayer.full(
    visibilityState: LayerVisibilityState.visible,
    layerIdentity: 42,
    lockState: LayerLockState.unlocked,
    settings: HistoryDrawingLayerSettings(
      constraints: _drawingConstraints,
      outerStrokeStyle: OuterStrokeStyle.solid,
      outerSelectionMap: outerMap,
      outerColorReference: const HistoryColorReference(colorIndex: 1, rampIndex: 0),
      outerDarkenBrighten: 1,
      outerGlowDepth: 1,
      outerGlowRecursive: false,
      innerStrokeStyle: InnerStrokeStyle.bevel,
      innerSelectionMap: innerMap,
      innerColorReference: const HistoryColorReference(colorIndex: 2, rampIndex: 0),
      innerDarkenBrighten: -1,
      innerGlowDepth: 2,
      innerGlowRecursive: true,
      bevelDistance: 3,
      bevelStrength: 4,
      dropShadowStyle: DropShadowStyle.solid,
      dropShadowColorReference: const HistoryColorReference(colorIndex: 0, rampIndex: 0),
      dropShadowOffset: CoordinateSetI(x: 2, y: -2),
      dropShadowDarkenBrighten: 2,
    ),
    fullData: pixels,
  );
}

void main()
{
  test("a malformed file is reported back across the isolate", () async {
    final LoadFileSet result = await loadKPixFile(
      fileData: Uint8List.fromList(<int>[0, 0, 0, 0, 1, 1]),
      path: "broken.kpix",
      drawingLayerSettingsConstraints: _drawingConstraints,
      shadingLayerSettingsConstraints: _shadingConstraints,
      frameConstraints: _frameConstraints,
    );

    //reaching this at all proves the constraints crossed over, the parser ran on
    //the other side and the result came back rather than the isolate dying
    expect(result.historyState, isNull);
    expect(result.status, contains("magic number"));
  });

  test("a drawing layer record survives the isolate hop intact", () async {
    final HistoryDrawingLayer original = _sampleLayer();

    final HistoryDrawingLayer copy = await runOffThread<HistoryDrawingLayer>(
      debugLabel: "test-layer-hop",
      work: () => original,
    );

    expect(copy.data.length, original.data.length);
    expect(copy.visibilityState, LayerVisibilityState.visible);
    expect(copy.lockState, LayerLockState.unlocked);
    expect(copy.layerIdentity, 42);

    //pixels are keyed by a plain class, so identity changes but equality holds
    final HistoryColorReference? pixel = copy.data[CoordinateSetI(x: 2, y: 1)];
    expect(pixel, isNotNull);
    expect(pixel!.colorIndex, 0);

    //Alignment looks like a dart:ui handle but is a value type, so the copied
    //keys still match the constants they were built from
    expect(copy.settings.outerSelectionMap[Alignment.topLeft], isTrue);
    expect(copy.settings.outerSelectionMap[Alignment.bottomRight], isFalse);
    expect(copy.settings.innerSelectionMap[Alignment.centerLeft], isTrue);

    expect(copy.settings.innerStrokeStyle, InnerStrokeStyle.bevel);
    expect(copy.settings.dropShadowOffset.x, 2);
    expect(copy.settings.dropShadowOffset.y, -2);
    expect(copy.settings.constraints.bevelStrengthMax, 8);
  });

  test("the UI isolate keeps running while a file is parsed", () async {
    int ticks = 0;
    bool done = false;

    Future<void> beat() async
    {
      while (!done)
      {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        ticks++;
      }
    }

    final Future<void> heartbeat = beat();
    await loadKPixFile(
      fileData: Uint8List(64),
      path: "broken.kpix",
      drawingLayerSettingsConstraints: _drawingConstraints,
      shadingLayerSettingsConstraints: _shadingConstraints,
      frameConstraints: _frameConstraints,
    );
    done = true;
    await heartbeat;

    expect(ticks, greaterThan(0));
  });
}
