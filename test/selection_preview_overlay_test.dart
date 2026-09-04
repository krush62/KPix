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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Whether the rendered image has anything opaque at [coord].
Future<bool> _isPainted({required final ui.Image image, required final CoordinateSetI coord}) async
{
  final ByteData? bytes = await image.toByteData();
  final int index = (coord.y * image.width + coord.x) * 4;
  return bytes!.getUint8(index + 3) != 0;
}

/// Builds the preview stack the palette ramp dialog builds: a copy of every
/// visible raster layer, each pointing at the stack it belongs to.
///
/// Carrying a layer stack is what makes a copy leave the floating selection out
/// of its own raster, so the preview has to draw the selection on top itself -
/// which is the code path under test.
List<RasterableLayerState> _previewStack({required final LayerCollection collection})
{
  final List<RasterableLayerState> stack = <RasterableLayerState>[];
  for (final RasterableLayerState layer in collection.getVisibleRasterLayers())
  {
    stack.add(layer.copy(layerStack: stack) as RasterableLayerState);
  }
  return stack;
}

Future<void> _disposeStack({required final List<RasterableLayerState> stack, required final AppState appState}) async
{
  for (final RasterableLayerState layer in stack)
  {
    layer.dispose();
  }
  await settle(appState: appState);
}

/// Waits for the preview copies to produce their first raster.
Future<void> _settleStack({required final List<RasterableLayerState> stack}) async
{
  for (int tick = 0; tick < 60; tick++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    if (stack.every((final RasterableLayerState l) => l.rasterImage.value != null || l.previousRaster != null))
    {
      return;
    }
  }
}

void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI origin = CoordinateSetI(x: 0, y: 0);
  final CoordinateSetI moved = CoordinateSetI(x: 2, y: 0);

  /// Lifts the pixel at [origin] into the selection and drags it to [moved],
  /// then renders the palette preview and reports whether it shows the content.
  Future<bool> previewShowsSelection({required final AppState appState}) async
  {
    appState.selectionState.selectAll();
    appState.selectionState.setOffset(offset: CoordinateSetI(x: 2, y: 0), withContent: true);
    appState.selectionState.finishMovement();
    await settle(appState: appState);

    final LayerCollection collection = appState.timeline.selectedFrame!.layerList;
    final List<RasterableLayerState> stack = _previewStack(collection: collection);
    await _settleStack(stack: stack);

    final ui.Image preview = await getImageFromLayers(
      canvasSize: canvasSize,
      layerCollection: collection,
      selection: appState.selectionState.selection,
      layerStack: stack,
    );
    final bool painted = await _isPainted(image: preview, coord: moved);
    preview.dispose();
    await _disposeStack(stack: stack, appState: appState);
    return painted;
  }

  testWidgets("the preview shows the floating selection with a reference layer above", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState artwork = layerAt(appState: appState, index: 0);
      artwork.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));

      //a reference layer is not a raster layer, so it counts in the collection's
      //indices but not in the visible raster layers the preview stack mirrors
      appState.addNewLayer(layerType: ReferenceLayerState);
      appState.selectLayer(newLayer: artwork);
      await settle(appState: appState);

      expect(appState.timeline.selectedFrame!.layerList.selectedLayerIndex, 1, reason: "setup: second in the collection");
      expect(appState.timeline.selectedFrame!.layerList.getVisibleRasterLayers().length, 1, reason: "setup: but first and only in the raster stack");

      expect(await previewShowsSelection(appState: appState), isTrue,
          reason: "the overlay has to find the selected layer by its place in the stack, not in the collection",);
    },);
  });

  testWidgets("the preview shows the floating selection with a hidden layer above", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState artwork = layerAt(appState: appState, index: 0);
      artwork.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));

      final DrawingLayerState hidden = appState.addNewLayer(layerType: DrawingLayerState)! as DrawingLayerState;
      appState.changeLayerVisibility(layerState: hidden);
      appState.selectLayer(newLayer: artwork);
      await settle(appState: appState);

      expect(appState.timeline.selectedFrame!.layerList.selectedLayerIndex, 1);
      expect(appState.timeline.selectedFrame!.layerList.getVisibleRasterLayers().length, 1);

      expect(await previewShowsSelection(appState: appState), isTrue,
          reason: "a hidden layer shifts the collection index but not the stack index",);
    },);
  });

  testWidgets("the preview still shows it when the indices happen to agree", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final AppState appState) async {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references.first;
      final DrawingLayerState artwork = layerAt(appState: appState, index: 0);
      artwork.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{origin: color}));
      await settle(appState: appState);

      expect(appState.timeline.selectedFrame!.layerList.selectedLayerIndex, 0, reason: "setup: nothing to shift the indices apart");

      expect(await previewShowsSelection(appState: appState), isTrue,
          reason: "the simple case worked before and has to keep working",);
    },);
  });
}
