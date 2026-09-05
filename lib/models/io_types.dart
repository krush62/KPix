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

import 'dart:ui' as ui;
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

/// Results handed back by loading and importing.
///
/// The state layer acts on these, so they cannot live in the I/O functions that
/// produce them - that would make the document depend on the file layer.
enum PaletteReplaceBehavior { remap, replace }
class LoadPaletteSet
{
  final String status;
  final List<KPalRampData>? rampData;
  LoadPaletteSet({required this.status, this.rampData});
}
class LoadFileSet
{
  final String status;
  final HistoryState? historyState;
  final String? path;
  LoadFileSet({required this.status, this.historyState, this.path});
}
class ImportResult
{
  final ImportDataSet? data;
  final String message;
  ImportResult({this.data, required this.message});
}

class ImportDataSet
{
  final ReferenceLayerState? referenceLayer;
  final DrawingLayerState drawingLayer;
  final CoordinateSetI canvasSize;
  final List<KPalRampData> rampDataList;

  ImportDataSet({required this.referenceLayer, required this.rampDataList, required this.drawingLayer, required this.canvasSize});
}

class ImportData
{
  final int maxClusters;
  final int maxRamps;
  final int maxColors;
  final bool includeReference;
  final bool createNewPalette;
  final ui.Image image;
  final ui.Image scaledImage;
  final String filePath;
  const ImportData({required this.filePath, required this.maxRamps, required this.maxColors, required this.image, required this.includeReference, required this.maxClusters, required this.createNewPalette, required this.scaledImage});
}

/// Screen for importing raster images into the application.
