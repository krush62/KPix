/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:material_ui/material_ui.dart';

import 'support/selection_harness.dart';

HashMap<Alignment, bool> _only({required final Alignment direction})
{
  return HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: alignment == direction});
}

Frame _firstFrame()
{
  return GetIt.I.get<DocumentState>().timeline.frames.value.first;
}

/// A square of five pixels from 1|1 to 5|5 in the middle of a long ramp, so that the
/// steps of an effect can be read off the color index.
Future<(DrawingLayerState, KPalRampData)> _square({required final ProjectSession projectSession}) async
{
  final KPalRampData ramp = KPalRampData(uuid: "long", settings: KPalRampSettings()..colorCount = 15);
  final PaletteState palette = GetIt.I.get<PaletteState>();
  palette.colorRamps = <KPalRampData>[ramp];
  palette.selectedColor = ramp.references[0];
  final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
  layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
    for (int x = 1; x <= 5; x++)
      for (int y = 1; y <= 5; y++) CoordinateSetI(x: x, y: y): ramp.references[_base],
  }),);
  await settle();
  return (layer, ramp);
}

const int _base = 7;

/// How many steps along the ramp the effects moved the pixel at [x]|[y].
int _stepsAt({required final DrawingLayerState layer, required final int x, required final int y})
{
  return layer.getDataEntry(coord: CoordinateSetI(x: x, y: y), withSettingsPixels: true)!.colorIndex - _base;
}

HashMap<Alignment, bool> _everyDirection()
{
  return HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: true});
}

HashMap<Alignment, bool> _noDirection()
{
  return HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: false});
}

/// How a drawing layer keeps and hands out the pixels of its effects.
void main()
{
  final CoordinateSetI pixel = CoordinateSetI(x: 3, y: 3);
  final CoordinateSetI right = CoordinateSetI(x: 4, y: 3);

  group("the inner glow", ()
  {
    Future<DrawingLayerState> glow({required final ProjectSession projectSession, required final int depth, final bool recursive = false, final HashMap<Alignment, bool>? directions}) async
    {
      final (DrawingLayerState layer, KPalRampData _) = await _square(projectSession: projectSession);
      layer.settings.innerSelectionMap.value = directions ?? _everyDirection();
      layer.settings.innerGlowDepth.value = depth;
      layer.settings.innerGlowRecursive.value = recursive;
      layer.settings.innerStrokeStyle.value = InnerStrokeStyle.glow;
      await settle();
      return layer;
    }

    testWidgets("fades from the edge inwards", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await glow(projectSession: projectSession, depth: 2);

        expect(_stepsAt(layer: layer, x: 1, y: 3), 2, reason: "the outer ring");
        expect(_stepsAt(layer: layer, x: 1, y: 1), 2, reason: "a corner of it");
        expect(_stepsAt(layer: layer, x: 2, y: 3), 1, reason: "the next ring");
        expect(_stepsAt(layer: layer, x: 3, y: 3), 0, reason: "deeper than the glow");
      },);
    });

    testWidgets("darkens with a negative depth", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await glow(projectSession: projectSession, depth: -2);

        expect(_stepsAt(layer: layer, x: 1, y: 3), -2);
        expect(_stepsAt(layer: layer, x: 2, y: 3), -1);
        expect(_stepsAt(layer: layer, x: 3, y: 3), 0);
      },);
    });

    testWidgets("only comes from the chosen direction", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await glow(projectSession: projectSession, depth: 2, directions: _only(direction: Alignment.centerRight));

        expect(_stepsAt(layer: layer, x: 5, y: 3), 2);
        expect(_stepsAt(layer: layer, x: 4, y: 3), 1);
        expect(_stepsAt(layer: layer, x: 3, y: 3), 0);
        expect(_stepsAt(layer: layer, x: 1, y: 3), 0);
      },);
    });

    testWidgets("adds a step for every further open side when recursive", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await glow(projectSession: projectSession, depth: 2, recursive: true);

        expect(_stepsAt(layer: layer, x: 1, y: 3), 4, reason: "three open neighbours on the edge");
        expect(_stepsAt(layer: layer, x: 1, y: 1), 6, reason: "five open neighbours in the corner");
        expect(_stepsAt(layer: layer, x: 2, y: 3), 3, reason: "the next ring, three open again");
        expect(_stepsAt(layer: layer, x: 2, y: 2), 5, reason: "its corner, five open again");
        expect(_stepsAt(layer: layer, x: 3, y: 3), 0);
      },);
    });

    testWidgets("goes the other way when recursive with a negative depth", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await glow(projectSession: projectSession, depth: -2, recursive: true);

        expect(_stepsAt(layer: layer, x: 1, y: 3), -4);
        expect(_stepsAt(layer: layer, x: 2, y: 3), -3);
      },);
    });

    testWidgets("stops once there is nothing left to peel", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await glow(projectSession: projectSession, depth: 6);

        expect(_stepsAt(layer: layer, x: 1, y: 3), 6);
        expect(_stepsAt(layer: layer, x: 2, y: 3), 5);
        expect(_stepsAt(layer: layer, x: 3, y: 3), 4);
      },);
    });
  });

  group("the bevel", ()
  {
    Future<DrawingLayerState> bevel({required final ProjectSession projectSession, required final HashMap<Alignment, bool> directions, final int distance = 1, final int strength = 1}) async
    {
      final (DrawingLayerState layer, KPalRampData _) = await _square(projectSession: projectSession);
      layer.settings.innerSelectionMap.value = directions;
      layer.settings.bevelDistance.value = distance;
      layer.settings.bevelStrength.value = strength;
      layer.settings.innerStrokeStyle.value = InnerStrokeStyle.bevel;
      await settle();
      return layer;
    }

    for (final (Alignment direction, int left, int top, int right, int bottom) edges in <(Alignment, int, int, int, int)>[
      (Alignment.centerRight, -1, 0, 1, 0),
      (Alignment.centerLeft, 1, 0, -1, 0),
      (Alignment.topCenter, 0, 1, 0, -1),
      (Alignment.bottomCenter, 0, -1, 0, 1),
      (Alignment.topLeft, 1, 1, -1, -1),
      (Alignment.topRight, -1, 1, 1, -1),
      (Alignment.bottomRight, -1, -1, 1, 1),
      (Alignment.bottomLeft, 1, -1, -1, 1),
    ])
    {
      testWidgets("lights the edges facing ${edges.$1} and darkens the others", (final WidgetTester tester) async
      {
        await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
        {
          final DrawingLayerState layer = await bevel(projectSession: projectSession, directions: _only(direction: edges.$1));

          expect(_stepsAt(layer: layer, x: 1, y: 3), edges.$2, reason: "left edge");
          expect(_stepsAt(layer: layer, x: 3, y: 1), edges.$3, reason: "top edge");
          expect(_stepsAt(layer: layer, x: 5, y: 3), edges.$4, reason: "right edge");
          expect(_stepsAt(layer: layer, x: 3, y: 5), edges.$5, reason: "bottom edge");
          expect(_stepsAt(layer: layer, x: 3, y: 3), 0, reason: "the middle");
        },);
      });
    }

    testWidgets("moves its edges inwards with the distance", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await bevel(projectSession: projectSession, directions: _only(direction: Alignment.centerRight), distance: 2);

        expect(_stepsAt(layer: layer, x: 5, y: 3), 0, reason: "the peeled ring");
        expect(_stepsAt(layer: layer, x: 4, y: 3), 1);
        expect(_stepsAt(layer: layer, x: 2, y: 3), -1);
        expect(_stepsAt(layer: layer, x: 3, y: 3), 0);
      },);
    });

    testWidgets("moves further along the ramp with its strength", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await bevel(projectSession: projectSession, directions: _only(direction: Alignment.centerRight), strength: 3);

        expect(_stepsAt(layer: layer, x: 5, y: 3), 3);
        expect(_stepsAt(layer: layer, x: 1, y: 3), -3);
      },);
    });

    testWidgets("does nothing without a direction", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = await bevel(projectSession: projectSession, directions: _noDirection());

        expect(_stepsAt(layer: layer, x: 5, y: 3), 0);
        expect(_stepsAt(layer: layer, x: 1, y: 3), 0);
      },);
    });
  });

  testWidgets("an outer shading of zero is told apart from none, and goes with the effect", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: GetIt.I.get<PaletteState>().colorRamps[0].references[1]}));
      layer.settings.outerSelectionMap.value = _only(direction: Alignment.centerRight);
      layer.settings.outerDarkenBrighten.value = 0;
      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.shade;
      await settle();

      expect(layer.outerShadingAt(frame: _firstFrame(), coord: right), 0, reason: "a shade of zero still marks the pixel");
      expect(layer.outerShadingAt(frame: _firstFrame(), coord: CoordinateSetI(x: 0, y: 0)), isNull);

      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settle();
      expect(layer.outerShadingAt(frame: _firstFrame(), coord: right), isNull);
    },);
  });

  testWidgets("turning the effects off drops their pixels", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: palette.colorRamps[0].references[1]}));
      layer.settings.outerColorReference.value = palette.colorRamps[1].references[2];
      layer.settings.outerSelectionMap.value = _only(direction: Alignment.centerRight);
      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await settle();
      expect(layer.getSettingsPixel(coord: right), same(palette.colorRamps[1].references[2]));
      expect(layer.getDataEntry(coord: right, withSettingsPixels: true), same(palette.colorRamps[1].references[2]));
      expect(layer.getDataEntry(coord: right), isNull, reason: "an effect pixel is not a pixel of the layer");

      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
      await settle();
      expect(layer.getSettingsPixel(coord: right), isNull);
      expect(layer.compositeAt(frame: _firstFrame(), coord: right), isNull);
    },);
  });

  testWidgets("rastering the outline writes the stroke into the layer", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference stroke = palette.colorRamps[1].references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: palette.colorRamps[0].references[1]}));
      layer.settings.outerColorReference.value = stroke;
      layer.settings.outerSelectionMap.value = _only(direction: Alignment.centerRight);
      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await settle();

      layer.rasterOutline(layers: _firstFrame().layerList.getAllLayers());
      await settle();
      expect(layer.getDataEntry(coord: right), same(stroke));
    },);
  });

  testWidgets("an outer stroke covers a drop shadow on the same pixel", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.drawing);
      await settle();
      final DrawingLayerState top = layerAt(projectSession: projectSession, index: 0);
      final DrawingLayerState below = layerAt(projectSession: projectSession, index: 1);
      final ColorReference ground = palette.colorRamps[0].references[2];
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{right: ground}));
      top.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: palette.colorRamps[1].references[1]}));

      //both land on the pixel to the right
      top.settings.dropShadowColorReference.value = palette.colorRamps[2].references[0];
      top.settings.dropShadowOffset.value = CoordinateSetI(x: 1, y: 0);
      top.settings.dropShadowStyle.value = DropShadowStyle.solid;
      top.settings.outerSelectionMap.value = _only(direction: Alignment.centerRight);
      top.settings.outerDarkenBrighten.value = 1;
      top.settings.outerStrokeStyle.value = OuterStrokeStyle.shade;
      await settle();

      expect(top.getSettingsPixel(coord: right), same(ground.ramp.references[ground.colorIndex + 1]), reason: "the shaded stroke is drawn over the shadow");
    },);
  });

  testWidgets("an inner stroke on a floating selection shades the selection's colors", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{
        for (int x = 2; x < 5; x++)
          for (int y = 2; y < 5; y++) CoordinateSetI(x: x, y: y): color,
      },),);
      await settle();
      GetIt.I.get<DocumentState>().selectionState.selectAll();
      await settle();
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 4, y: 4)), isNull, reason: "setup: the pixels float in the selection now");

      layer.settings.innerSelectionMap.value = _only(direction: Alignment.bottomRight);
      layer.settings.innerDarkenBrighten.value = 1;
      layer.settings.innerStrokeStyle.value = InnerStrokeStyle.shade;
      await settle();

      final ColorReference shaded = color.ramp.references[color.colorIndex + 1];
      expect(layer.compositeAt(frame: _firstFrame(), coord: CoordinateSetI(x: 4, y: 4)), same(shaded), reason: "the edge pixel of the selection is shaded");
      expect(layer.compositeAt(frame: _firstFrame(), coord: CoordinateSetI(x: 3, y: 3)), same(color), reason: "the inside is not");
    },);
  });
}
