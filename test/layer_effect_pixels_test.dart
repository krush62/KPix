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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

HashMap<Alignment, bool> _only({required final Alignment direction})
{
  return HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: alignment == direction});
}

Frame _firstFrame()
{
  return GetIt.I.get<DocumentState>().timeline.frames.value.first;
}

/// How a drawing layer keeps and hands out the pixels of its effects. What
/// the effects compute is pinned down by layer_effects_equivalence_test.dart.
void main()
{
  final CoordinateSetI pixel = CoordinateSetI(x: 3, y: 3);
  final CoordinateSetI right = CoordinateSetI(x: 4, y: 3);

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
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
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
