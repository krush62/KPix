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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

CoordinateColorMapNullable _fill({required final CoordinateSetI canvasSize, required final ColorReference color})
{
  final CoordinateColorMapNullable pixels = CoordinateColorMapNullable();
  for (int x = 0; x < canvasSize.x; x++)
  {
    for (int y = 0; y < canvasSize.y; y++)
    {
      pixels[CoordinateSetI(x: x, y: y)] = color;
    }
  }
  return pixels;
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI dot = CoordinateSetI(x: 1, y: 1);

  group("a layer whose effects sample downward", () {
    testWidgets("a shaded outer stroke registers a dependency on the layer below", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[3];
        final DrawingLayerState below = layerAt(appState: appState, index: 0);
        below.setDataAll(list: _fill(canvasSize: canvasSize, color: color));

        final DrawingLayerState above = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        above.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: color}));
        await settle(appState: appState);

        expect(above.settings.readsLayersBelow, isFalse, reason: "setup: no shading effect yet");
        above.settings.outerStrokeStyle.value = OuterStrokeStyle.shade;
        await settle(appState: appState);

        expect(above.settings.readsLayersBelow, isTrue,
            reason: "a shaded outer stroke darkens whatever sits underneath it",);
        expect(appState.timeline.selectedFrame!.layerList.dependsOn(dependent: above, dependency: below), isTrue,
            reason: "so the layer below has to be able to invalidate it",);
      },);
    });

    testWidgets("a shaded drop shadow registers the same dependency", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[3];
        final DrawingLayerState below = layerAt(appState: appState, index: 0);
        below.setDataAll(list: _fill(canvasSize: canvasSize, color: color));

        final DrawingLayerState above = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        above.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: color}));
        await settle(appState: appState);

        above.settings.dropShadowStyle.value = DropShadowStyle.shade;
        await settle(appState: appState);

        expect(above.settings.readsLayersBelow, isTrue);
        expect(appState.timeline.selectedFrame!.layerList.dependsOn(dependent: above, dependency: below), isTrue);
      },);
    });

    testWidgets("a glowing outer stroke registers the same dependency", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[3];
        final DrawingLayerState below = layerAt(appState: appState, index: 0);
        below.setDataAll(list: _fill(canvasSize: canvasSize, color: color));

        final DrawingLayerState above = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        above.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: color}));
        await settle(appState: appState);

        above.settings.outerStrokeStyle.value = OuterStrokeStyle.glow;
        await settle(appState: appState);

        expect(above.settings.readsLayersBelow, isTrue);
        expect(appState.timeline.selectedFrame!.layerList.dependsOn(dependent: above, dependency: below), isTrue);
      },);
    });

    testWidgets("changing the layer below marks the effect layer for a redraw", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference first = GetIt.I.get<PaletteState>().colorRamps.first.references[3];
        final ColorReference second = GetIt.I.get<PaletteState>().colorRamps.first.references.last;
        final DrawingLayerState below = layerAt(appState: appState, index: 0);
        below.setDataAll(list: _fill(canvasSize: canvasSize, color: first));

        final DrawingLayerState above = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        above.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: first}));
        above.settings.outerStrokeStyle.value = OuterStrokeStyle.shade;
        await settle(appState: appState);
        expect(above.doManualRaster, isFalse, reason: "setup: everything is drawn and quiet");

        below.setDataAll(list: _fill(canvasSize: canvasSize, color: second));
        appState.timeline.selectedFrame!.layerList.invalidateDependents(layer: below);

        expect(above.doManualRaster, isTrue,
            reason: "the shaded stroke samples the layer below, so a colour change there has to redraw it",);
      },);
    });
  });

  group("layers whose effects do not sample downward", () {
    testWidgets("a solid outer stroke registers no dependency", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[3];
        final DrawingLayerState below = layerAt(appState: appState, index: 0);
        below.setDataAll(list: _fill(canvasSize: canvasSize, color: color));

        final DrawingLayerState above = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        above.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: color}));
        above.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
        await settle(appState: appState);

        expect(above.settings.readsLayersBelow, isFalse, reason: "a solid stroke uses a fixed colour");
        expect(appState.timeline.selectedFrame!.layerList.dependsOn(dependent: above, dependency: below), isFalse,
            reason: "registering it would redraw the layer for no reason",);
      },);
    });

    testWidgets("turning an effect off removes the dependency again", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[3];
        final DrawingLayerState below = layerAt(appState: appState, index: 0);
        below.setDataAll(list: _fill(canvasSize: canvasSize, color: color));

        final DrawingLayerState above = appState.addNewLayer(layerType: DrawingLayerState, select: true)! as DrawingLayerState;
        above.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: color}));
        above.settings.outerStrokeStyle.value = OuterStrokeStyle.shade;
        await settle(appState: appState);
        expect(appState.timeline.selectedFrame!.layerList.dependsOn(dependent: above, dependency: below), isTrue);

        above.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
        await settle(appState: appState);

        expect(appState.timeline.selectedFrame!.layerList.dependsOn(dependent: above, dependency: below), isFalse);
      },);
    });
  });
}
