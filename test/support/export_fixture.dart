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
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'selection_harness.dart';

/// Not square and no multiple of anything, so that swapped rows and columns show.
final CoordinateSetI exportCanvasSize = CoordinateSetI(x: 7, y: 5);

int rgbOf({required final ColorReference reference})
{
  final ui.Color color = reference.getIdColor().color;
  return ((color.r * 255.0).round() << 16) | ((color.g * 255.0).round() << 8) | (color.b * 255.0).round();
}

/// A project that has everything an export has to deal with, and what every
/// exporter has to make of it.
///
/// Top to bottom: a drawing layer, a grid, a shading layer, a hidden shading layer
/// that must have no effect, a hidden drawing layer, a locked drawing layer, and
/// the selected drawing layer, one of whose pixels floats in a selection.
class ExportFixture
{
  final LayerCollection layers;
  final SelectionList selection;
  final List<KPalRampData> ramps;

  /// The colors of the exported drawing layers, top to bottom, as 0xRRGGBB.
  final List<Map<CoordinateSetI, int>> expectedLayers;

  /// What is visible when all layers are put together, as 0xRRGGBB.
  final Map<CoordinateSetI, int> expectedMerged;

  /// The same as [expectedMerged], as the colors they come from.
  final Map<CoordinateSetI, ColorReference> expectedMergedColors;

  const ExportFixture({required this.layers, required this.selection, required this.ramps, required this.expectedLayers, required this.expectedMerged, required this.expectedMergedColors});
}

Future<ExportFixture> buildExportFixture({required final ProjectSession projectSession}) async
{
  final LayerManager manager = GetIt.I.get<LayerManager>();
  final DocumentState document = GetIt.I.get<DocumentState>();
  final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;

  //each new layer goes above the selected one
  final DrawingLayerState bottom = layerAt(projectSession: projectSession, index: 0);
  final DrawingLayerState locked = manager.addNewLayer(layerType: LayerKind.drawing, select: true).$2! as DrawingLayerState;
  final DrawingLayerState hidden = manager.addNewLayer(layerType: LayerKind.drawing, select: true).$2! as DrawingLayerState;
  final ShadingLayerState hiddenShading = manager.addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
  final ShadingLayerState shading = manager.addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
  manager.addNewLayer(layerType: LayerKind.grid, select: true);
  final DrawingLayerState top = manager.addNewLayer(layerType: LayerKind.drawing, select: true).$2! as DrawingLayerState;

  final CoordinateSetI onTop = CoordinateSetI(x: 6, y: 0);
  final CoordinateSetI onHidden = CoordinateSetI(x: 3, y: 1);
  final CoordinateSetI onLocked = CoordinateSetI(x: 0, y: 4);
  //on the locked and on the bottom layer, under the shading: only the upper one is shaded
  final CoordinateSetI covered = CoordinateSetI(x: 1, y: 1);
  //on the bottom layer only, under both shading layers
  final CoordinateSetI shaded = CoordinateSetI(x: 2, y: 2);
  final CoordinateSetI floating = CoordinateSetI(x: 4, y: 3);

  top.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{onTop: ramps[1].references[1]}));
  hidden.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{onHidden: ramps[2].references[2]}));
  locked.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{onLocked: ramps[3].references[3], covered: ramps[3].references[1]}));
  bottom.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{shaded: ramps[0].references[2], covered: ramps[0].references[1], floating: ramps[0].references[3]}));
  shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{shaded: 1, covered: 1}));
  hiddenShading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{shaded: 2}));
  hiddenShading.visibilityState.value = LayerVisibilityState.hidden;
  hidden.visibilityState.value = LayerVisibilityState.hidden;
  locked.lockState.value = LayerLockState.locked;
  await settle();

  manager.selectLayer(newLayer: bottom, addToHistoryStack: false);
  document.selectionState.newSelectionFromShape(start: floating, end: CoordinateSetI(x: 5, y: 4), selectShape: SelectShape.rectangle);
  await settle();
  expect(document.selectionState.selection.getColorReference(coord: floating), isNotNull, reason: "setup: the pixel floats");
  expect(bottom.getDataEntry(coord: floating), isNull, reason: "setup: the pixel floats");

  final Map<CoordinateSetI, ColorReference> mergedColors = <CoordinateSetI, ColorReference>{
    onTop: ramps[1].references[1],
    onLocked: ramps[3].references[3],
    covered: ramps[3].references[2],
    shaded: ramps[0].references[3],
    floating: ramps[0].references[3],
  };
  return ExportFixture(
    layers: document.timeline.selectedFrame!.layerList,
    selection: document.selectionState.selection,
    ramps: ramps,
    expectedLayers: <Map<CoordinateSetI, int>>[
      <CoordinateSetI, int>{onTop: rgbOf(reference: ramps[1].references[1])},
      <CoordinateSetI, int>{onHidden: rgbOf(reference: ramps[2].references[2])},
      <CoordinateSetI, int>{onLocked: rgbOf(reference: ramps[3].references[3]), covered: rgbOf(reference: ramps[3].references[2])},
      <CoordinateSetI, int>{shaded: rgbOf(reference: ramps[0].references[3]), covered: rgbOf(reference: ramps[0].references[1]), floating: rgbOf(reference: ramps[0].references[3])},
    ],
    expectedMerged: mergedColors.map((final CoordinateSetI coord, final ColorReference reference) => MapEntry<CoordinateSetI, int>(coord, rgbOf(reference: reference))),
    expectedMergedColors: mergedColors,
  );
}
