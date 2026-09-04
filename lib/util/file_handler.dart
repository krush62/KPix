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

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer_settings.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_layer_type.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_shading_layer_settings.dart';
import 'package:kpix/managers/history/history_shift_set.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/history/history_timeline.dart';
import 'package:kpix/managers/history/ramp_resolver.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_byte_reader.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/kpal/kpal_constraints.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/tools/constraints/grid_layer_constraints.dart';
import 'package:kpix/widgets/tools/constraints/reference_layer_constraints.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'import/import_kpix.dart';
part 'import/import_palette.dart';
part 'import/import_stamp.dart';

class LoadFileSet
{
  final String status;
  final HistoryState? historyState;
  final String? path;
  LoadFileSet({required this.status, this.historyState, this.path});
}

class LoadProjectFileSet
{
  final String path;
  final DateTime lastModifiedDate;
  final ui.Image? thumbnail;
  LoadProjectFileSet({
    required this.path,
    required this.lastModifiedDate,
    required this.thumbnail,
  });
}

enum PaletteReplaceBehavior { remap, replace }

class LoadPaletteSet
{
  final String status;
  final List<KPalRampData>? rampData;
  LoadPaletteSet({required this.status, this.rampData});
}

enum FileNameStatus
{
  available("Available", TablerIcons.check),
  forbidden("Invalid File Name", TablerIcons.x),
  noRights("Insufficient Permissions", TablerIcons.ban),
  overwrite("Overwriting Existing File", TablerIcons.exclamation_mark);

  const FileNameStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}

const int fileVersion = 4;
const String magicNumber = "4B504958";
const String fileExtensionKpix = "kpix";
const String fileExtensionKpal = "kpal";
const String palettesSubDirName = "palettes";
const String stampsSubDirName = "stamps";
const String projectsSubDirName = "projects";
const String recoverSubDirName = "recover";
const String thumbnailExtension = "png";
const List<String> imageExtensions = <String>["png", "jpg", "jpeg", "gif"];
const String recoverFileName = "___recover___";
const double _floatDelta = 0.01;

Future<String?> saveKPixFile({
  required final String path,
  required final AppState appState,
}) async
{
  try
  {
    final ByteData byteData = await createKPixData(appState: appState);
    if (!kIsWeb)
    {
      await File(path).writeAsBytes(byteData.buffer.asUint8List());
      return path;
    }
    else
    {
      final String newPath = await FileSaver.instance.saveFile(name: path, bytes: byteData.buffer.asUint8List(), fileExtension: fileExtensionKpix,);
      return newPath;
    }
  }
  catch (e, s)
  {
    GetIt.I.get<Logger>().w("Error saving kpix file.", error: e, stackTrace: s);
  }
  return null;
}

Future<String?> getPathForKPixFile() async
{
  FilePickerResult? result;
  final String exportDir = GetIt.I.get<AppPaths>().exportDir;
  if (isDesktop(includingWeb: true))
  {
    result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: <String>[fileExtensionKpix], initialDirectory: exportDir,);
  } 
  else //mobile
  {
    result = await FilePicker.pickFiles(
      initialDirectory: exportDir,
    );
  }
  if (result != null && result.files.isNotEmpty) 
  {
    String path = result.files.first.name;
    if (!kIsWeb && result.files.first.path != null) 
    {
      path = result.files.first.path!;
    }
    return path;
  }
  else
  {
    return null;
  }
}

Future<String?> getPathForKPalFile() async
{
  FilePickerResult? result;
  final String exportDir = GetIt.I.get<AppPaths>().exportDir;
  if (isDesktop(includingWeb: true))
  {
    result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: <String>[fileExtensionKpal], initialDirectory: exportDir,);
  } 
  else //mobile
  {
    result = await FilePicker.pickFiles(
      initialDirectory: exportDir,
    );
  }
  if (result != null && result.files.isNotEmpty) 
  {
    String path = result.files.first.name;
    if (!kIsWeb && result.files.first.path != null) 
    {
      path = result.files.first.path!;
    }
    return path;
  }
  else
  {
    return null;
  }
}

Future<(String?, Uint8List?)> getPathAndDataForImage() async
{
  FilePickerResult? result;
  if (isDesktop())
  {
    result = await FilePicker.pickFiles(type: FileType.image, allowedExtensions: imageExtensions, initialDirectory: GetIt.I.get<AppPaths>().exportDir,);
  } 
  else if (kIsWeb)
  {
    //web has no file system to read from afterwards, so the bytes have to come
    //back with the pick itself
    result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: imageExtensions, withData: true, initialDirectory: GetIt.I.get<AppPaths>().exportDir,);
  } 
  else //mobile
  {
    result = await FilePicker.pickFiles(initialDirectory: GetIt.I.get<AppPaths>().exportDir,);
  }
  if (result != null && result.files.isNotEmpty) 
  {
    String path = result.files.first.name;
    if (!kIsWeb && result.files.first.path != null) 
    {
      path = result.files.first.path!;
    }
    return (path, result.files.first.bytes);
  }
  else
  {
    return (null, null);
  }
}

void loadFilePressed({final Function()? finishCallback, final Function()? loadStartCallback})
{
  final String exportDir = GetIt.I.get<AppPaths>().exportDir;
  if (isDesktop(includingWeb: true))
  {
    //withData is only forced on web, where there is no path to read from later;
    //native keeps loading from disk so a large project is not held twice
    FilePicker.pickFiles(type: FileType.custom, allowedExtensions: <String>[fileExtensionKpix], withData: kIsWeb, initialDirectory: exportDir,).then
      ((final FilePickerResult? result)
        {
          _loadFileChosen(result: result, finishCallback: finishCallback, loadStartCallback: loadStartCallback);
        }
      );
  } 
  else //mobile
  {
    FilePicker.pickFiles(withData: kIsWeb, initialDirectory: exportDir,).then
      ((final FilePickerResult? result)
        {
          _loadFileChosen(result: result, finishCallback: finishCallback, loadStartCallback: loadStartCallback);
        }
      );
  }
}

void _loadFileChosen({final FilePickerResult? result, required final Function()? finishCallback, required final Function()? loadStartCallback,})
{
  if (result != null && result.files.isNotEmpty) 
  {
    String path = result.files.first.name;
    if (!kIsWeb && result.files.first.path != null) 
    {
      path = result.files.first.path!;
    }
    loadStartCallback?.call();
    loadKPixFile(
      fileData: result.files.first.bytes,
      path: path,
      drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
      shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
      frameConstraints: GetIt.I.get<PreferenceManager>().frameConstraints,
    ).then((final LoadFileSet loadFileSet)
    {
      fileLoaded(loadFileSet: loadFileSet, finishCallback: finishCallback);
    });
  }
}

void fileLoaded({required final LoadFileSet loadFileSet, required final Function()? finishCallback,})
{
  GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet).whenComplete(()
  {
    finishCallback?.call();
  });
}

Future<void> saveFilePressed({required final String fileName, final Function()? finishCallback, final bool forceSaveAs = false,}) async
{
  if (!kIsWeb)
  {
    final String finalPath = p.join(GetIt.I.get<AppPaths>().projectsDir, "$fileName.$fileExtensionKpix");
    saveKPixFile(path: finalPath, appState: GetIt.I.get<AppState>()).then((final String? path)
    {
      if (path != null) 
      {
        _projectFileSaved(fileName: fileName, path: path,finishCallback: finishCallback,);
      } 
      else if (finishCallback != null) 
      {
        finishCallback();
      }
    });
  }
  else
  {
    saveKPixFile(path: fileName, appState: GetIt.I.get<AppState>()).then((final String? path)
    {
      if (path != null) 
      {
        _projectFileSaved(
          fileName: fileName,
          path: path,
          finishCallback: finishCallback,
        );
      } 
      else if (finishCallback != null) 
      {
        finishCallback();
      }
    });
  }
}

Future<void> _projectFileSaved({required final String fileName, required final String path, required final Function()? finishCallback,}) async
{
  final AppState appState = GetIt.I.get<AppState>();
  if (!kIsWeb)
  {
    final String? pngPath = await replaceFileExtension(filePath: path, newExtension: thumbnailExtension,inputFileMustExist: true,);
    if (pngPath != null)
    {
      try
      {
        final Frame frame = appState.timeline.selectedFrame!;
        final ui.Image img = await getImageFromLayers(canvasSize: appState.canvasSize, layerCollection: frame.layerList, selection: appState.selectionState.selection,frame: frame,);
        try
        {
          final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
          await File(pngPath).writeAsBytes(pngBytes!.buffer.asUint8List());
        }
        finally
        {
          img.dispose();
        }
      }
      catch (e, s)
      {
        GetIt.I.get<Logger>().w("Error creating thumbnail.", error: e, stackTrace: s);
      }
    }
    else
    {
      GetIt.I.get<Logger>().w("Creation of png path unsuccessful.");
    }
    //a watch event would pick this up too, but not before the manager is opened
    notifyProjectFileChanged(path: path);
  }

  appState.fileSaved(saveName: fileName, path: path, addKPixExtension: kIsWeb);
  if (finishCallback != null) 
  {
    finishCallback();
  }
}

Future<bool> copyImportFile({required final String inputPath, required final ui.Image image,required final String targetPath,}) async
{
  final Logger logger = GetIt.I.get<Logger>();
  try
  {
    final String? pngPath = await replaceFileExtension(filePath: targetPath, newExtension: thumbnailExtension, inputFileMustExist: false,);
    final File projectFile = File(inputPath);
    if (pngPath != null && await projectFile.exists()) 
    {
      final ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes != null) 
      {
        await File(pngPath).writeAsBytes(pngBytes.buffer.asUint8List());
        final File createdFile = await projectFile.copy(targetPath);
        if (!await createdFile.exists())
        {
          logger.w("Error copying import file: Created file ${createdFile.path} does not exist.",);
          return false;
        }
      }
      else
      {
        return false;
      }
    }
    else
    {
      return false;
    }
    return true;
  }
  catch (e, s)
  {
    logger.w("Error copying import file.", error: e, stackTrace: s);
    return false;
  }
}

Future<bool> deleteProject({required final String fullProjectPath}) async
{
  try
  {
    final bool success = await deleteFile(path: fullProjectPath);
    final String? pngPath = await replaceFileExtension(filePath: fullProjectPath, newExtension: thumbnailExtension, inputFileMustExist: false,);
    if (pngPath != null)
    {
      await deleteFile(path: pngPath);
    }
    if (success)
    {
      notifyProjectFileChanged(path: fullProjectPath);
    }
    return success;
  }
  catch (e, s)
  {
    GetIt.I.get<Logger>().w("Error deleting project.", error: e, stackTrace: s);
    return false;
  }
}

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

Future<String?> getDirectory({required final String startDir}) async
{
  return await FilePicker.getDirectoryPath(dialogTitle: "Choose Directory", initialDirectory: startDir,);
}

Future<Uint8List?> _createImageData({required final ImageExportData exportData, required final ImageExportType exportType,}) async
{
  final AppState appState = GetIt.I.get<AppState>();
  final CoordinateSetI canvasSize = appState.canvasSize;
  final LayerCollection layerList = appState.timeline.selectedFrame!.layerList;
  final SelectionList selection = appState.selectionState.selection;
  final List<KPalRampData> colorRamps = GetIt.I.get<PaletteState>().colorRamps;

  switch (exportType)
  {
    case ImageExportType.png:
      return await exportPNG(exportData: exportData, canvasSize: canvasSize, selection: selection, layerList: layerList,);
    case ImageExportType.aseprite:
      return await getAsepriteData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.photoshop:
      return await getPsdDataRGB(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.gimp:
      return await getGimpData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.pixelorama:
      return await getPixeloramaData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps,);
    case ImageExportType.kpix:
      return (await createKPixData(appState: appState)).buffer.asUint8List();
    case ImageExportType.texturePack:
      return await exportTexturePack(appState: appState);
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

Future<Uint8List?> _createAnimationData({required final AnimationExportData exportData, required final AnimationExportType exportType,}) async
{
  final AppState appState = GetIt.I.get<AppState>();

  switch (exportType)
  {
    case AnimationExportType.apng:
      return await exportAPNG(exportData: exportData, appState: appState);
    case AnimationExportType.gif:
      return await exportGIF(exportData: exportData, appState: appState);
    case AnimationExportType.zippedPng:
      return await exportZippedPng(exportData: exportData, appState: appState);
    case AnimationExportType.texturePack:
      return await exportTexturePackAnimation(exportData: exportData, appState: appState,);
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


FileNameStatus checkFileName({required final String fileName, required final String directory, required final String extension, final bool allowRecoverFile = true,})
{
  final Logger logger = GetIt.I.get<Logger>();
  try
  {
    if (fileName.isEmpty)
    {
      return FileNameStatus.forbidden;
    }

    if (kIsWeb)
    {
      return FileNameStatus.available;
    }

    if (Platform.isWindows)
    {
      final List<String> reservedFilenames = <String>[
        'CON',
        'PRN',
        'AUX',
        'NUL',
        'COM1',
        'COM2',
        'COM3',
        'COM4',
        'COM5',
        'COM6',
        'COM7',
        'COM8',
        'COM9',
        'LPT1',
        'LPT2',
        'LPT3',
        'LPT4',
        'LPT5',
        'LPT6',
        'LPT7',
        'LPT8',
        'LPT9',
      ];
      if (fileName.endsWith(' ') || fileName.endsWith('.') || reservedFilenames.contains(fileName.toUpperCase()))
      {
        return FileNameStatus.forbidden;
      }
    }

    if (fileName == recoverFileName && !allowRecoverFile) 
    {
      return FileNameStatus.forbidden;
    }

    final List<String> invalidCharacters = <String>[
      '/',
      '\\',
      '?',
      '%',
      '*',
      ':',
      '|',
      '"',
      '<',
      '>',
    ];
    for (final String char in invalidCharacters)
    {
      if (fileName.contains(char))
      {
        return FileNameStatus.forbidden;
      }
    }
    if (!hasWriteAccess(directory: directory))
    {
      return FileNameStatus.noRights;
    }

    final String fullPath = p.join(directory, "$fileName.$extension");
    final File file = File(fullPath);
    if (file.existsSync())
    {
      return FileNameStatus.overwrite;
    }

    return FileNameStatus.available;
  }
  catch (e, s)
  {
    logger.w("Error checking file name.", error: e, stackTrace: s);
  }
  return FileNameStatus.forbidden;
}

Future<String> findExportDir() async
{
  if (!kIsWeb)
  {
    if (isDesktop() || Platform.isIOS)
    {
      final Directory? downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) 
      {
        return downloadDir.path;
      }
    } 
    else if (Platform.isAndroid)
    {
      final Directory directoryDL = Directory("/storage/emulated/0/Download/");
      final Directory directoryDLs = Directory("/storage/emulated/0/Downloads/");
      if (await directoryDL.exists())
      {
        return directoryDL.path;
      } 
      else if (await directoryDLs.exists())
      {
        return directoryDLs.path;
      }
      else
      {
        final Directory? directory = await getExternalStorageDirectory();
        if (directory != null && await directory.exists()) {
          return directory.path;
        }
      }
    }
  }
  return "";
}

Future<String> findInternalDir() async
{
  if (kIsWeb)
  {
    return "";
  }

  final Directory internalDir = await getApplicationSupportDirectory();
  return internalDir.path;
}

String getDefaultProjectsDir({required final String internalDir})
{
  return p.join(internalDir, projectsSubDirName);
}

class ProjectDirectoryResolveResult
{
  final String resolvedDir;
  final bool useCustom;
  final bool customValid;
  ProjectDirectoryResolveResult({required this.resolvedDir, required this.useCustom, required this.customValid});
}

Future<ProjectDirectoryResolveResult> resolveProjectsDir({required final String internalDir}) async
{
  String dirToUse = getDefaultProjectsDir(internalDir: internalDir);
  bool customValid = false;
  bool useCustomDir = false;
  if (!kIsWeb)
  {
    useCustomDir = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.useCustomProjectDirectory.value;
    final String customDir = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.customProjectDirectory.value;

    if (customDir.isNotEmpty)
    {
      if (await Directory(customDir).exists() && hasWriteAccess(directory: customDir))
      {
        customValid = true;
      }
    }

    if (useCustomDir)
    {
      if (!customValid)
      {
        GetIt.I.get<Logger>().w("Custom project directory $customDir is not accessible, falling back to the default directory.",);
      }
      else
      {
        dirToUse = customDir;
      }
    }
  }
  return ProjectDirectoryResolveResult(resolvedDir: dirToUse, useCustom: useCustomDir, customValid: customValid);
}

class ProjectDirectoryMoveResult
{
  final bool success;
  final String message;
  final int projectCount;
  
  ProjectDirectoryMoveResult({required this.success, required this.message, this.projectCount = 0,});
}

Future<ProjectDirectoryMoveResult> moveProjectFiles({required final String sourceDir, required final String targetDir,}) async
{
  final Logger logger = GetIt.I.get<Logger>();
  logger.i("Moving project files from $sourceDir to $targetDir.");
  try
  {
    final Directory target = Directory(targetDir);
    if (!await target.exists())
    {
      try
      {
        await target.create(recursive: true);
      }
      catch (e, s)
      {
        logger.w(
          "Could not create target directory $targetDir.",
          error: e,
          stackTrace: s,
        );
        return ProjectDirectoryMoveResult(
          success: false,
          message: "The directory does not exist and could not be created!",
        );
      }
    }
    if (!hasWriteAccess(directory: targetDir))
    {
      return ProjectDirectoryMoveResult(
        success: false,
        message: "Insufficient permissions for the directory!",
      );
    }

    final List<File> filesToMove = <File>[];
    int projectCount = 0;
    final Directory source = Directory(sourceDir);
    if (await source.exists())
    {
      await for (final FileSystemEntity entity in source.list(followLinks: false))
      {
        if (entity is File && entity.path.endsWith(".$fileExtensionKpix"))
        {
          filesToMove.add(entity);
          projectCount++;
          final String? pngPath = await replaceFileExtension(filePath: entity.path, newExtension: thumbnailExtension, inputFileMustExist: true,);
          if (pngPath != null) 
          {
            final File pngFile = File(pngPath);
            if (await pngFile.exists())
            {
              filesToMove.add(pngFile);
            }
          }
        }
      }
    }

    for (final File file in filesToMove)
    {
      final String targetPath = p.join(targetDir, p.basename(file.path));
      if (await File(targetPath).exists())
      {
        return ProjectDirectoryMoveResult(success: false, message: "The directory already contains a file named ${p.basename(file.path)}!",);
      }
    }

    final List<(String, String)> movedFiles = <(String, String)>[];
    for (final File file in filesToMove)
    {
      final String targetPath = p.join(targetDir, p.basename(file.path));
      try
      {
        await moveFile(sourceFile: file, targetPath: targetPath);
        movedFiles.add((file.path, targetPath));
      }
      catch (e, s)
      {
        logger.w(
          "Error moving ${file.path} to $targetPath, rolling back.",
          error: e,
          stackTrace: s,
        );
        for (final (String, String) movedFile in movedFiles)
        {
          try
          {
            await moveFile(
              sourceFile: File(movedFile.$2),
              targetPath: movedFile.$1,
            );
          }
          catch (e2, s2)
          {
            logger.e(
              "Rollback failed for ${movedFile.$2}.",
              error: e2,
              stackTrace: s2,
            );
          }
        }
        return ProjectDirectoryMoveResult(
          success: false,
          message: "Could not move file ${p.basename(file.path)}!",
        );
      }
    }

    logger.i("Moved $projectCount project file(s) to $targetDir.");
    return ProjectDirectoryMoveResult(success: true, message: "", projectCount: projectCount,);
  }
  catch (e, s)
  {
    logger.w("Error moving project files.", error: e, stackTrace: s);
    return ProjectDirectoryMoveResult(success: false, message: "An unexpected error occurred while moving project files!",);
  }
}

/// Collects the file system state of every project in [dir].
///
/// This only stats files, so it holds no `dart:ui` handles and reaches nothing
/// in the service locator: [ProjectManager] runs it on a background isolate.
/// It does not log for the same reason, and lets errors surface to the caller.
Future<List<ProjectFileStat>> scanProjectDirectory({required final String dir}) async
{
  final List<ProjectFileStat> stats = <ProjectFileStat>[];
  final Directory directory = Directory(dir);
  if (!await directory.exists())
  {
    return stats;
  }

  await for (final FileSystemEntity entity in directory.list(followLinks: false))
  {
    if (entity is! File || p.extension(entity.path).toLowerCase() != ".$fileExtensionKpix")
    {
      continue;
    }
    final String kpixPath = entity.absolute.path;
    //FileStat.stat never throws, it reports a missing file as a not found type,
    //which is what a file deleted between listing and stating looks like here
    final FileStat kpixStat = await FileStat.stat(kpixPath);
    if (kpixStat.type != FileSystemEntityType.file)
    {
      continue;
    }
    final String thumbnailPath = p.setExtension(kpixPath, ".$thumbnailExtension");
    final FileStat thumbnailStat = await FileStat.stat(thumbnailPath);
    final bool hasThumbnail = thumbnailStat.type == FileSystemEntityType.file;
    stats.add(
      ProjectFileStat(
        kpixPath: kpixPath,
        lastModified: kpixStat.modified,
        thumbnailPath: thumbnailPath,
        thumbnailModified: hasThumbnail ? thumbnailStat.modified : null,
        thumbnailSize: hasThumbnail ? thumbnailStat.size : null,
      ),
    );
  }
  return stats;
}

/// Collects the file system state of the single project at [kpixPath].
///
/// Returns null when the project file is gone, which is how [ProjectManager]
/// detects a deletion.
Future<ProjectFileStat?> statProjectFile({required final String kpixPath}) async
{
  final FileStat kpixStat = await FileStat.stat(kpixPath);
  if (kpixStat.type != FileSystemEntityType.file)
  {
    return null;
  }
  final String thumbnailPath = p.setExtension(kpixPath, ".$thumbnailExtension");
  final FileStat thumbnailStat = await FileStat.stat(thumbnailPath);
  final bool hasThumbnail = thumbnailStat.type == FileSystemEntityType.file;
  return ProjectFileStat(
    kpixPath: kpixPath,
    lastModified: kpixStat.modified,
    thumbnailPath: thumbnailPath,
    thumbnailModified: hasThumbnail ? thumbnailStat.modified : null,
    thumbnailSize: hasThumbnail ? thumbnailStat.size : null,
  );
}

/// Decodes the project thumbnail at [thumbnailPath].
///
/// Returns null when the file is missing or cannot be decoded. The latter
/// happens while a sync tool is still writing it, so a failure here is expected
/// and not worth a log entry: the cache retries a missing thumbnail on the next
/// scan.
Future<ui.Image?> loadThumbnail({required final String thumbnailPath}) async
{
  try
  {
    //instantiateImageCodecWithSize takes ownership of the buffer and disposes it
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(thumbnailPath);
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(buffer);
    try
    {
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    }
    finally
    {
      codec.dispose();
    }
  }
  catch (_)
  {
    return null;
  }
}

void setUint64({required final ByteData bytes, required final int offset, required final int value, final Endian endian = Endian.big,})
{
  if (kIsWeb)
  {
    final int low = value & 0xFFFFFFFF;
    final int high = (value >> 32) & 0xFFFFFFFF;

    if (endian == Endian.little) 
    {
      bytes.setUint32(offset, low, Endian.little);
      bytes.setUint32(offset + 4, high, Endian.little);
    }
    else
    {
      bytes.setUint32(offset, high);
      bytes.setUint32(offset + 4, low);
    }
  }
  else
  {
    bytes.setUint64(offset, value);
  }
}

Future<void> createInternalDirectories() async
{
  final String internalDir = GetIt.I.get<AppPaths>().internalDir;
  final List<Directory> internalDirectories = <Directory>[
    Directory(p.join(internalDir, palettesSubDirName)),
    Directory(p.join(internalDir, projectsSubDirName)),
    Directory(p.join(internalDir, recoverSubDirName)),
    Directory(p.join(internalDir, stampsSubDirName)),
  ];

  for (final Directory dir in internalDirectories)
  {
    final bool dirExists = await dir.exists();
    if (!dirExists)
    {
      await dir.create();
    }
  }
}

Future<void> clearRecoverDir() async
{
  if (!kIsWeb)
  {
    final Logger logger = GetIt.I.get<Logger>();
    try
    {
      final Directory recoverDir = Directory(
        p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName),
      );
      final List<FileSystemEntity> files = await recoverDir.list().toList();
      for (final FileSystemEntity file in files)
      {
        await file.delete(recursive: true);
      }
    }
    catch (e, s)
    {
      logger.w("Error clearing recovery directory.", error: e, stackTrace: s);
    }
  }
}

Future<String?> getRecoveryFile() async
{
  final Logger logger = GetIt.I.get<Logger>();
  try
  {
    final Directory recoverDir = Directory(
      p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName),
    );
    final List<FileSystemEntity> files = await recoverDir.list().toList();
    if (files.length == 1) {
      logger.i("Found recovery file ${files[0].path}.");
      return files[0].path;
    }
  }
  catch (e, s)
  {
    logger.w("Error getting recovery file.", error: e, stackTrace: s);
  }
  return null;
}

Future<bool> importProject({required final String? path, final bool showMessages = true,}) async
{
  bool success = false;
  final Logger logger = GetIt.I.get<Logger>();

  try
  {
    if (path != null && path.isNotEmpty)
    {
      if (path.endsWith(fileExtensionKpix))
      {
        final LoadFileSet loadFileSet = await loadKPixFile(
          fileData: null,
          path: path,
          drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
          shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
      frameConstraints: GetIt.I.get<PreferenceManager>().frameConstraints,
        );
        if (loadFileSet.historyState != null && loadFileSet.path != null)
        {
          final String fileName = extractFilenameFromPath(path: loadFileSet.path);
          final String projectPath = p.join(GetIt.I.get<AppPaths>().projectsDir, fileName);
          if (!File(projectPath).existsSync())
          {
            final ui.Image? img = await getImageFromLoadFileSet(loadFileSet: loadFileSet);
            if (img != null)
            {
              success = await copyImportFile(inputPath: loadFileSet.path!, image: img, targetPath: projectPath,);
              if (success)
              {
                notifyProjectFileChanged(path: projectPath);
              }
            }
            else
            {
              if (showMessages)
              {
                showMessage(text: "Could not open file!");
              }
            }
          }
          else
          {
            if (showMessages)
            {
              showMessage(text: "Project with the same name already exists!",);
            }
          }
        }
        else
        {
          if (showMessages) showMessage(text: "Could not open file!");
        }
      }
      else
      {
        showMessage(text: "Please select a KPix file!");
      }
    }
  }
  catch (e, s)
  {
    logger.w("Error importing project.", error: e, stackTrace: s);
  }

  return success;
}

/// Renders the first frame of [loadFileSet] into an image.
///
/// Used for the project manager thumbnail. It rebuilds the layers from the
/// history state and hands them to [getImageFromLayers], so a thumbnail shows the
/// same layer types a png export would.
Future<ui.Image?> getImageFromLoadFileSet({required final LoadFileSet loadFileSet}) async
{
  final HistoryState? state = loadFileSet.historyState;
  if (state == null)
  {
    return null;
  }

  final List<KPalRampData> ramps = <KPalRampData>[];
  for (final HistoryRampData hRampData in state.rampList)
  {
    final KPalRampSettings settings = KPalRampSettings.from(other: hRampData.settings);
    ramps.add(KPalRampData(uuid: hRampData.uuid, settings: settings, historyShifts: hRampData.shiftSets));
  }
  final RampResolver resolver = RampResolver(liveRamps: ramps, historyRamps: state.rampList);

  final List<LayerState> layers = <LayerState>[];
  for (final HistoryLayer hLayer in state.timeline.getLayersForFrameIndex(frameIndex: 0))
  {
    final LayerState layer = await hLayer.toLayerState(canvasSize: state.canvasSize, ramps: resolver);
    layer.visibilityState.value = hLayer.visibilityState;
    layers.add(layer);
  }

  //the compositor reads the rasters straight off the layers, so they have to have
  //settled first; only the rasterable ones are drawn, so only those are waited for
  await Future.wait<void>(layers.whereType<RasterableLayerState>().map((final RasterableLayerState layer) => layer.rasterizationComplete))
      .timeout(rasterSettleTimeout, onTimeout: ()
  {
    GetIt.I.get<Logger>().w("Timed out rasterizing layers for the project thumbnail.");
    return <void>[];
  },);

  final ui.Image thumbnail = await getImageFromLayers(
    canvasSize: state.canvasSize,
    layerCollection: LayerCollection(layers: layers, selLayerIdx: 0),
    selection: SelectionList(),
  );

  //built only for this thumbnail and never part of a frame, so the sweep in
  //AppState would never see them; the picture is already an image by now
  for (final LayerState layer in layers)
  {
    layer.dispose();
  }
  return thumbnail;
}

Future<ui.Image> getImageFromLayers({
  required final LayerCollection layerCollection,
  required final CoordinateSetI canvasSize,
  required final SelectionList selection,
  final Frame? frame,
  final List<RasterableLayerState>? layerStack,
  final int scalingFactor = 1,}) async
{
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
      final ui.Image? mapImage = frame != null ? cLayer.rasterImageMap.value[frame]?.raster : null;
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
          for (final MapEntry<CoordinateSetI, ColorReference?> entry in selection.selectedPixels.entries)
          {
            if (entry.value != null)
            {
              paint.color = entry.value!.getIdColor().color;
              canvas.drawRect(
                Rect.fromLTWH(
                  entry.key.x.toDouble() * scalingFactor,
                  entry.key.y.toDouble() * scalingFactor,
                  scalingFactor.toDouble(),
                  scalingFactor.toDouble(),
                ),
                paint,
              );
            }
          }
        }
      }
    }
  }
  return recorder.endRecording().toImage(canvasSize.x * scalingFactor, canvasSize.y * scalingFactor);
}

/// Returns true if the application is running as native desktop application.
bool isDesktop({final bool includingWeb = false})
{
  if (kIsWeb && !includingWeb)
  {
    return false;
  }
  else
  {
    return (kIsWeb && includingWeb) || Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }
}
