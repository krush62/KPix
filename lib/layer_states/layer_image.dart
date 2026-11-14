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

import 'dart:ui' as ui;

import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:material_ui/material_ui.dart';

Future<ui.Image> getImageFromLayers({
  required final LayerCollection layerCollection,
  required final CoordinateSetI canvasSize,
  required final SelectionList selection,
  final Frame? frame,
  final List<RasterableLayerState>? layerStack,
  final int scalingFactor = 1,}) async
{
  //a layer linked into several frames has a raster for each of them
  final Frame? rasterFrame = frame ?? GetIt.I.get<DocumentState>().timeline.findFrameForCollection(collection: layerCollection);
  final List<RasterableLayerState> visibleLayers = layerCollection.getVisibleRasterLayers().toList();
  List<RasterableLayerState> layerList;
  if (layerStack != null)
  {
    layerList = layerStack;
  }
  else
  {
    layerList = List<RasterableLayerState>.empty(growable: true);
    layerList.addAll(visibleLayers);
  }

  int selectionLayerIndex = -1;
  if (layerStack != null && selection.hasValues() && layerStack.length == visibleLayers.length)
  {
    final LayerState? selectedLayer = layerCollection.getSelectedLayer();
    if (selectedLayer is RasterableLayerState)
    {
      selectionLayerIndex = visibleLayers.indexOf(selectedLayer);
    }
  }

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  for (int i = layerList.length - 1; i >= 0; i--)
  {
    final LayerState cLayer = layerList[i];
    if (cLayer.visibilityState.value == LayerVisibilityState.visible && cLayer is RasterableLayerState)
    {
      final ui.Image? mapImage = rasterFrame != null ? cLayer.rasterImageMap.value[rasterFrame]?.raster : null;
      final ui.Image? rasterImage = cLayer.rasterImage.value;
      final ui.Image? previousRaster = cLayer.previousRaster;
      final ui.Image? imageToUse = mapImage ?? (rasterImage ?? previousRaster);

      if (imageToUse != null)
      {
        paintImage(
          canvas: canvas,
          rect: ui.Rect.fromLTWH(0, 0,
            canvasSize.x.toDouble() * scalingFactor,
            canvasSize.y.toDouble() * scalingFactor,
          ),
          image: imageToUse,
          fit: BoxFit.none,
          scale: 1.0 / scalingFactor.toDouble(),
          alignment: Alignment.topLeft,
          filterQuality: FilterQuality.none,
        );
        if (i == selectionLayerIndex)
        {
          final Paint paint = Paint();
          selection.forEachSelected(action: (final int x, final int y, final ColorReference? color)
          {
            if (color != null)
            {
              paint.color = color.getIdColor().color;
              canvas.drawRect(
                Rect.fromLTWH(
                  x.toDouble() * scalingFactor,
                  y.toDouble() * scalingFactor,
                  scalingFactor.toDouble(),
                  scalingFactor.toDouble(),
                ),
                paint,
              );
            }
          },);
        }
      }
    }
  }
  final ui.Picture picture = recorder.endRecording();
  try
  {
    return await picture.toImage(canvasSize.x * scalingFactor, canvasSize.y * scalingFactor);
  }
  finally
  {
    picture.dispose();
  }
}
