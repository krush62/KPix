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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 16, y: 16);

LayerCollection _layers()
{
  return GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList;
}

CoordinateColorMapNullable _square({required final int from, required final int to, required final ColorReference color})
{
  final CoordinateColorMapNullable pixels = CoordinateColorMapNullable();
  for (int x = from; x <= to; x++)
  {
    for (int y = from; y <= to; y++)
    {
      pixels[CoordinateSetI(x: x, y: y)] = color;
    }
  }
  return pixels;
}

/// The effect pixels of [layer] on the whole canvas.
Map<String, ColorReference?> _effectPixels({required final DrawingLayerState layer})
{
  final Map<String, ColorReference?> pixels = <String, ColorReference?>{};
  for (int x = 0; x < _canvasSize.x; x++)
  {
    for (int y = 0; y < _canvasSize.y; y++)
    {
      final ColorReference? color = layer.getSettingsPixel(coord: CoordinateSetI(x: x, y: y));
      if (color != null)
      {
        pixels["$x|$y"] = color;
      }
    }
  }
  return pixels;
}

void main()
{
  for (final OuterStrokeStyle style in <OuterStrokeStyle>[OuterStrokeStyle.glow, OuterStrokeStyle.shade])
  {
    testWidgets("a layer moved below one with a ${style.name} outer stroke makes that stroke follow what is drawn on it", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
        final LayerManager layerManager = GetIt.I.get<LayerManager>();
        final DrawingLayerState a = layerAt(projectSession: projectSession, index: 0);
        a.setDataAll(list: _square(from: 6, to: 9, color: colors[1]));
        await settle();
        a.settings.outerStrokeStyle.value = style;
        await settle();

        final DrawingLayerState b = layerManager.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        await settle();
        expect(_layers().getLayerPosition(state: b), 0, reason: "setup: the new layer went on top");

        layerManager.changeLayerOrder(state: b, newPosition: 2);
        await settle();
        expect(_layers().getLayerPosition(state: b), 1, reason: "setup: the new layer is below the one with the effect now");
        expect(_effectPixels(layer: a), isEmpty, reason: "setup: nothing below to shade yet");

        b.setDataAll(list: _square(from: 0, to: _canvasSize.x - 1, color: colors[3]));
        await settle();
        final Map<String, ColorReference?> afterFill = _effectPixels(layer: a);

        a.forceFullRender();
        await settle();
        final Map<String, ColorReference?> rendered = _effectPixels(layer: a);
        expect(rendered, isNotEmpty, reason: "setup: the ${style.name} shades the filled layer");

        expect(afterFill, rendered,
            reason: "filling the layer below has to show in the ${style.name} without anything else making it render again",);
        expect(_layers().dependsOn(dependent: a, dependency: b), isTrue,
            reason: "the layer with the effect reads the layer that is below it now",);
      },);
    });
  }

  testWidgets("a layer moved above one with an effect no longer shows in that effect", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
      final LayerManager layerManager = GetIt.I.get<LayerManager>();
      final DrawingLayerState a = layerAt(projectSession: projectSession, index: 0);
      a.setDataAll(list: _square(from: 6, to: 9, color: colors[1]));
      a.settings.outerStrokeStyle.value = OuterStrokeStyle.glow;
      final DrawingLayerState b = layerManager.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
      layerManager.changeLayerOrder(state: b, newPosition: 2);
      await settle();
      b.setDataAll(list: _square(from: 0, to: _canvasSize.x - 1, color: colors[3]));
      await settle();
      expect(_effectPixels(layer: a), isNotEmpty, reason: "setup: the glow shades the layer below");

      layerManager.changeLayerOrder(state: b, newPosition: 0);
      await settle();

      expect(_layers().getLayerPosition(state: b), 0, reason: "setup: back on top");
      expect(_effectPixels(layer: a), isEmpty, reason: "nothing lies below the glow any more");
      expect(_layers().dependsOn(dependent: a, dependency: b), isFalse);
    },);
  });

  testWidgets("merging a layer drops the merged away layer from the dependencies", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final List<ColorReference> colors = GetIt.I.get<PaletteState>().colorRamps.first.references;
      final LayerManager layerManager = GetIt.I.get<LayerManager>();
      final DrawingLayerState bottom = layerAt(projectSession: projectSession, index: 0);
      bottom.setDataAll(list: _square(from: 0, to: 3, color: colors[2]));
      final DrawingLayerState middle = layerManager.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
      middle.setDataAll(list: _square(from: 4, to: 7, color: colors[2]));
      final DrawingLayerState top = layerManager.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
      top.setDataAll(list: _square(from: 8, to: 11, color: colors[1]));
      top.settings.outerStrokeStyle.value = OuterStrokeStyle.glow;
      await settle();
      expect(_layers().dependsOn(dependent: top, dependency: bottom), isTrue, reason: "setup: the effect reads every layer below");

      _layers().mergeLayer(mergeLayer: middle, canvasSize: GetIt.I.get<CanvasState>().canvasSize);
      await settle();

      expect(_layers().contains(layer: bottom), isFalse, reason: "setup: the bottom layer was merged into the middle one");
      expect(_layers().dependsOn(dependent: top, dependency: bottom), isFalse);
      expect(_layers().dependsOn(dependent: top, dependency: middle), isTrue);
    },);
  });
}
