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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

Future<void> _settleShading({required final ShadingLayerState shading}) async
{
  await settle();
  for (int i = 0; i < 80 && (shading.doManualRaster || shading.isRasterizing); i++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// Copy merged takes what the canvas shows, not the raw layer pixels.
void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 8, y: 8);
  final CoordinateSetI pixel = CoordinateSetI(x: 3, y: 3);
  final CoordinateSetI right = CoordinateSetI(x: 4, y: 3);

  testWidgets("copies the pixels of the layer effects", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
      final ColorReference content = palette.colorRamps[0].references[1];
      final ColorReference stroke = palette.colorRamps[1].references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: content}));
      layer.settings.outerColorReference.value = stroke;
      layer.settings.outerSelectionMap.value = HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: alignment == Alignment.centerRight});
      layer.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
      await settle();

      sel.selectAll();
      await settle();
      expect(sel.copyMerged(), SelectionActionResult.success);
      await settle();
      sel.paste();
      await settle();

      expect(sel.selection.getColorReference(coord: pixel), same(content));
      expect(sel.selection.getColorReference(coord: right), same(stroke), reason: "the stroke is visible, so it is copied");
    },);
  });

  testWidgets("copies the colors as the shading layers above shift them", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: palette.colorRamps[0].references[1], right: palette.colorRamps[0].references[1]}));
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, addToHistoryStack: false).$2! as ShadingLayerState;
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{pixel: 1}));
      await _settleShading(shading: shading);

      sel.selectAll();
      await _settleShading(shading: shading);
      expect(sel.copyMerged(), SelectionActionResult.success);
      await _settleShading(shading: shading);
      GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.selectLayer(newLayer: layer);
      sel.paste();
      await _settleShading(shading: shading);

      expect(sel.selection.getColorReference(coord: pixel), same(palette.colorRamps[0].references[2]), reason: "the shaded color is visible");
      expect(sel.selection.getColorReference(coord: right), same(palette.colorRamps[0].references[1]), reason: "outside the shading the color is unchanged");
    },);
  });
}
