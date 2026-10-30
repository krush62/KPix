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

import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_image.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/export_shader_renderer.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

/// Where an export ends up.
///
/// On web there is no file system to write to, so only the file name is known
/// here and the browser decides where the download lands.
String _exportTargetPath({required final String directory, required final String fileName, required final String extension})
{
  final String nameWithExtension = "$fileName.$extension";
  return kIsWeb ? nameWithExtension : p.join(directory, nameWithExtension);
}

/// Writes [data] to `<directory>/<fileName>.<extension>` and returns the path it
/// ended up at.
///
/// On web [directory] is ignored and the bytes are handed to the browser's
/// download flow instead.
Future<String> _writeDataToFile({
  required final Uint8List data,
  required final String directory,
  required final String fileName,
  required final String extension,
}) async
{
  final String nameWithExtension = "$fileName.$extension";
  if (!kIsWeb)
  {
    final String path = p.join(directory, nameWithExtension);
    await File(path).writeAsBytes(data);
    return path;
  }
  else
  {
    final String newPath = await FileSaver.instance.saveFile(name: fileName, bytes: data, fileExtension: extension,);
    return "$newPath/$nameWithExtension";
  }
}

/// Builds export data with [createData] and writes it out.
///
/// Returns the path the file ended up at, or null when either step failed. Both
/// failures are logged rather than thrown, so a broken export never takes the
/// app down with it. [what] names the kind of export in those log messages.
Future<String?> _runExport({
  required final String what,
  required final String directory,
  required final String fileName,
  required final String extension,
  required final Future<Uint8List?> Function() createData,
}) async
{
  final Logger logger = GetIt.I.get<Logger>();
  logger.i("Exporting $what to ${_exportTargetPath(directory: directory, fileName: fileName, extension: extension)}.");

  final Uint8List? data;
  try
  {
    data = await createData();
  }
  catch (e, s)
  {
    logger.w("Error creating $what data.", error: e, stackTrace: s);
    return null;
  }

  if (data == null)
  {
    return null;
  }

  try
  {
    return await _writeDataToFile(data: data, directory: directory, fileName: fileName, extension: extension,);
  }
  catch (e, s)
  {
    logger.w("Error writing $what data.", error: e, stackTrace: s);
    return null;
  }
}

Future<String?> saveCurrentPalette({required final String fileName, required final String directory, required final String extension,}) async
{
  final Uint8List data = await createPaletteKPalData(rampList: GetIt.I.get<PaletteState>().colorRamps);
  return await _writeDataToFile(data: data, directory: directory, fileName: fileName, extension: extension,);
}

Future<Uint8List?> _createPaletteData({required final PaletteExportType paletteType}) async
{
  final List<KPalRampData> rampList = GetIt.I.get<PaletteState>().colorRamps;
  final ColorNames colorNames = GetIt.I.get<PreferenceManager>().colorNames;

  switch (paletteType)
  {
    case PaletteExportType.kpal:
      return await createPaletteKPalData(rampList: rampList);
    case PaletteExportType.png:
      return await getPalettePngData(ramps: rampList);
    case PaletteExportType.aseprite:
      return await getPaletteAsepriteData(rampList: rampList);
    case PaletteExportType.gimp:
      return await getPaletteGimpData(rampList: rampList, colorNames: colorNames,);
    case PaletteExportType.paintNet:
      return await getPalettePaintNetData(rampList: rampList, colorNames: colorNames,);
    case PaletteExportType.adobe:
      return await getPaletteAdobeData(rampList: rampList, colorNames: colorNames,);
    case PaletteExportType.jasc:
      return await getPaletteJascData(rampList: rampList);
    case PaletteExportType.corel:
      return await getPaletteCorelData(rampList: rampList, colorNames: colorNames,);
    case PaletteExportType.openOffice:
      return await getPaletteOpenOfficeData(rampList: rampList, colorNames: colorNames,);
    case PaletteExportType.json:
      return await getPaletteJsonData(rampList: rampList);
  }
}

Future<String?> exportPalettePressed({required final PaletteExportData saveData, required final PaletteExportType paletteType,}) async
{
  return await _runExport(
    what: "palette",
    directory: saveData.directory,
    fileName: saveData.fileName,
    extension: saveData.extension,
    createData: () => _createPaletteData(paletteType: paletteType),
  );
}

Future<Uint8List?> _createImageData({required final ImageExportData exportData, required final ImageExportType exportType,}) async
{
  final DocumentState documentState = GetIt.I.get<DocumentState>();
  final CanvasState canvasState = GetIt.I.get<CanvasState>();
  final CoordinateSetI canvasSize = canvasState.canvasSize;
  final LayerCollection layerList = documentState.timeline.selectedFrame!.layerList;
  final SelectionList selection = documentState.selectionState.selection;
  final List<KPalRampData> colorRamps = GetIt.I.get<PaletteState>().colorRamps;

  switch (exportType)
  {
    case ImageExportType.png:
      return await exportPNG(exportData: exportData, canvasSize: canvasSize, selection: selection, layerList: layerList,);
    case ImageExportType.webp:
      return await exportWebP(exportData: exportData, canvasSize: canvasSize, selection: selection, layerList: layerList,);
    case ImageExportType.aseprite:
      return await getAsepriteData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.photoshop:
      return await getPsdDataRGB(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.gimp:
      return await getGimpData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.pixelorama:
      return await getPixeloramaData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.kpix:
      return (await createKPixData()).buffer.asUint8List();
    case ImageExportType.texturePack:
      return await exportTexturePack();
  }
}

Future<String?> exportImage({required final ImageExportData exportData, required final ImageExportType exportType,}) async
{
  return await _runExport(
    what: "image",
    directory: exportData.directory,
    fileName: exportData.fileName,
    extension: exportData.extension,
    createData: () => _createImageData(exportData: exportData, exportType: exportType),
  );
}

Future<Uint8List?> _createShaderImageData({required final ShaderExportData exportData}) async
{
  final DocumentState documentState = GetIt.I.get<DocumentState>();
  final ui.Image source = await getImageFromLayers(
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    layerCollection: documentState.timeline.selectedFrame!.layerList,
    selection: documentState.selectionState.selection,
  );
  try
  {
    return await renderExportShaderPng(values: exportData.shaderValues, source: source, scaling: exportData.scaling);
  }
  finally
  {
    source.dispose();
  }
}

Future<String?> exportShaderImage({required final ShaderExportData exportData}) async
{
  return await _runExport(
    what: "shader image",
    directory: exportData.directory,
    fileName: exportData.fileName,
    extension: exportData.extension,
    createData: () => _createShaderImageData(exportData: exportData),
  );
}

Future<Uint8List?> _createAnimationData({required final AnimationExportData exportData, required final AnimationExportType exportType,}) async
{

  switch (exportType)
  {
    case AnimationExportType.apng:
      return await exportAPNG(exportData: exportData);
    case AnimationExportType.gif:
      return await exportGIF(exportData: exportData);
    case AnimationExportType.webp:
      return await exportWebPAnimation(exportData: exportData);
    case AnimationExportType.zippedPng:
      return await exportZippedPng(exportData: exportData);
    case AnimationExportType.texturePack:
      return await exportTexturePackAnimation(exportData: exportData);
  }
}

Future<String?> exportAnimation({required final AnimationExportData exportData, required final AnimationExportType exportType,}) async
{
  return await _runExport(
    what: "animation",
    directory: exportData.directory,
    fileName: exportData.fileName,
    extension: exportData.extension,
    createData: () => _createAnimationData(exportData: exportData, exportType: exportType),
  );
}
