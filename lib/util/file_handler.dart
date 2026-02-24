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
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer_settings.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_shading_layer_settings.dart';
import 'package:kpix/managers/history/history_shift_set.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/history/history_timeline.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'import/import_stamp.dart';
part 'import/import_palette.dart';
part 'import/import_kpix.dart';

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
  LoadProjectFileSet({required this.path, required this.lastModifiedDate, required this.thumbnail});
}


enum PaletteReplaceBehavior
{
  remap,
  replace
}

class LoadPaletteSet
{
  final String status;
  final List<KPalRampData>? rampData;
  LoadPaletteSet({required this.status, this.rampData});
}







enum FileNameStatus
{
  available,
  forbidden,
  noRights,
  overwrite
}

const Map<FileNameStatus, String> fileNameStatusTextMap =
<FileNameStatus, String>{
  FileNameStatus.available:"Available",
  FileNameStatus.forbidden:"Invalid File Name",
  FileNameStatus.noRights:"Insufficient Permissions",
  FileNameStatus.overwrite:"Overwriting Existing File",
};

const Map<FileNameStatus, IconData> fileNameStatusIconMap =
<FileNameStatus, IconData>{
  FileNameStatus.available: TablerIcons.check,
  FileNameStatus.forbidden: TablerIcons.x,
  FileNameStatus.noRights:TablerIcons.ban,
  FileNameStatus.overwrite:TablerIcons.exclamation_mark,
};


  const int fileVersion = 3;
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


  Future<String?> saveKPixFile({required final String path, required final AppState appState}) async
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
        final String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: byteData.buffer.asUint8List(),
          fileExtension: fileExtensionKpix,
        );
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
    if (isDesktop(includingWeb: true))
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else //mobile
    {
      result = await FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
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
    if (isDesktop(includingWeb: true))
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[fileExtensionKpal],
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else //mobile
        {
      result = await FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
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
      result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowedExtensions: imageExtensions,
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else if (kIsWeb)
    {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: imageExtensions,
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
    }
    else //mobile
    {
      result = await FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      );
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

  void loadFilePressed({final Function()? finishCallback})
  {
    if (isDesktop(includingWeb: true))
    {
      FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: <String>[fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
    else //mobile
    {
      FilePicker.platform.pickFiles(
          initialDirectory: GetIt.I.get<AppState>().exportDir,
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
  }

  void _loadFileChosen({final FilePickerResult? result, required final Function()? finishCallback})
  {
    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      loadKPixFile(
        fileData: result.files.first.bytes,
        constraints: GetIt.I.get<PreferenceManager>().kPalConstraints,
        path: path,
        sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints,
        referenceLayerSettings: GetIt.I.get<PreferenceManager>().referenceLayerSettings,
        gridLayerSettings: GetIt.I.get<PreferenceManager>().gridLayerSettings,
        drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
        shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
      ).then((final LoadFileSet loadFileSet){fileLoaded(loadFileSet: loadFileSet, finishCallback: finishCallback);});
    }
  }

  void fileLoaded({required final LoadFileSet loadFileSet, required final Function()? finishCallback})
  {
    GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  Future<void> saveFilePressed({required final String fileName, final Function()? finishCallback, final bool forceSaveAs = false}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String finalPath = p.join(appState.internalDir, projectsSubDirName, "$fileName.$fileExtensionKpix");
      saveKPixFile(path: finalPath, appState: GetIt.I.get<AppState>()).then((final String? path)
      {
        if (path != null)
        {
          _projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback);
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
          _projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback);
        }
        else if (finishCallback != null)
        {
          finishCallback();
        }
      });
    }
  }

  Future<void> _projectFileSaved({required final String fileName, required final String path, required final Function()? finishCallback}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String? pngPath = await replaceFileExtension(filePath: path, newExtension: thumbnailExtension, inputFileMustExist: true);
      if (pngPath != null)
      {
        try
        {
          final Frame frame = appState.timeline.selectedFrame!;
          final ui.Image img = await getImageFromLayers(canvasSize: appState.canvasSize, layerCollection: frame.layerList, selection: appState.selectionState.selection, frame: frame);
          final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
          await File(pngPath).writeAsBytes(pngBytes!.buffer.asUint8List());
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
    }

    appState.fileSaved(saveName: fileName, path: path, addKPixExtension: kIsWeb);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  Future<bool> copyImportFile({required final String inputPath, required final ui.Image image, required final String targetPath}) async
  {
    final Logger logger = GetIt.I.get<Logger>();
    try
    {
      final String? pngPath = await replaceFileExtension(filePath: targetPath, newExtension: thumbnailExtension, inputFileMustExist: false);
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
            logger.w("Error copying import file: Created file ${createdFile.path} does not exist.");
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
      final String? pngPath = await replaceFileExtension(filePath: fullProjectPath, newExtension: thumbnailExtension, inputFileMustExist: false);
      if (pngPath != null)
      {
        await deleteFile(path: pngPath);
      }
      return success;
    }
    catch (e, s)
    {
      GetIt.I.get<Logger>().w("Error deleting project.", error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> deleteFile({required final String path}) async
  {
    final File file = File(path);
    if (await file.exists())
    {
      await file.delete();
    }
    else
    {
      return false;
    }
    return true;
  }

  Future<String?> saveCurrentPalette({required final String fileName, required final String directory, required final String extension}) async
  {
    final String finalPath = p.join(directory, fileName);
    final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
    final Uint8List data = await createPaletteKPalData(rampList: rampList);
    return await _savePaletteDataToFile(data: data, path: finalPath, extension: extension);
  }


  Future<String?> exportPalettePressed({required final PaletteExportData saveData, required final PaletteExportType paletteType}) async
  {
    final Logger logger = GetIt.I.get<Logger>();
    final String finalPath = p.join(saveData.directory, saveData.fileName);
    logger.i("Exporting palette to $finalPath.");

    Uint8List? data;

    try
    {
      final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
      final ColorNames colorNames = GetIt.I.get<PreferenceManager>().colorNames;

      switch (paletteType)
      {
        case PaletteExportType.kpal:
          data = await createPaletteKPalData(rampList: rampList);
      //break;
        case PaletteExportType.png:
          data = await getPalettePngData(ramps: rampList);
      //break;
        case PaletteExportType.aseprite:
          data = await getPaletteAsepriteData(rampList: rampList);
      //break;
        case PaletteExportType.gimp:
          data = await getPaletteGimpData(rampList: rampList, colorNames: colorNames);
      //break;
        case PaletteExportType.paintNet:
          data = await getPalettePaintNetData(rampList: rampList, colorNames: colorNames);
      //break;
        case PaletteExportType.adobe:
          data = await getPaletteAdobeData(rampList: rampList, colorNames: colorNames);
      //break;
        case PaletteExportType.jasc:
          data = await getPaletteJascData(rampList: rampList);
      //break;
        case PaletteExportType.corel:
          data = await getPaletteCorelData(rampList: rampList, colorNames: colorNames);
      //break;
        case PaletteExportType.openOffice:
          data = await getPaletteOpenOfficeData(rampList: rampList, colorNames: colorNames);
      //break;
        case PaletteExportType.json:
          data = await getPaletteJsonData(rampList: rampList);
      //break;
      }
    }
    catch(e, s)
    {
      logger.w("Error creating palette data.", error: e, stackTrace: s);
    }

    if (data != null)
    {
      try
      {
        return await _savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);

      }
      catch (e, s)
      {
        logger.w("Error writing palette data.", error: e, stackTrace: s);
        return null;
      }
    }
    else
    {
      return null;
    }

  }

  Future<String?> _savePaletteDataToFile({required final Uint8List data, required final String path, required final String extension}) async
  {
    final String pathWithExtension = "$path.$extension";
    if (!kIsWeb)
    {
      await File(pathWithExtension).writeAsBytes(data);
      return pathWithExtension;
    }
    else
    {
      final String newPath = await FileSaver.instance.saveFile(
        name: path,
        bytes: data,
        fileExtension: extension,
      );
      return "$newPath/$pathWithExtension";
    }
  }



  Future<String?> getDirectory({required final String startDir}) async
  {
    return await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Directory", initialDirectory: startDir);
  }

  Future<String?> exportImage({required final ImageExportData exportData, required final ImageExportType exportType}) async
  {
    final Logger logger = GetIt.I.get<Logger>();
    final String path = !kIsWeb ? p.join(exportData.directory, "${exportData.fileName}.${exportData.extension}") : exportData.fileName;
    logger.i("Exporting image to $path.");

    Uint8List? data;

    try
    {
      final AppState appState = GetIt.I.get<AppState>();
      final CoordinateSetI canvasSize = appState.canvasSize;
      final LayerCollection layerList = appState.timeline.selectedFrame!.layerList;
      final SelectionList selection = appState.selectionState.selection;
      final List<KPalRampData> colorRamps = appState.colorRamps;

      switch (exportType)
      {
        case ImageExportType.png:
          data = await exportPNG(exportData: exportData, canvasSize: canvasSize, selection: selection, layerList: layerList);
      //break;
        case ImageExportType.aseprite:
          data = await getAsepriteData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps);
      //break;
        case ImageExportType.photoshop:
          data = await getPsdDataRGB(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps);
      //  break;
        case ImageExportType.gimp:
          data = await getGimpData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps);
      //break;
        case ImageExportType.pixelorama:
          data = await getPixeloramaData(canvasSize: canvasSize, selection: selection, layerCollection: layerList, colorRamps: colorRamps);
      //break;
        case ImageExportType.kpix:
          data = (await createKPixData(appState: appState)).buffer.asUint8List();
      //break;
        case ImageExportType.texturePack:
          data = await exportTexturePack(appState: appState);
      //break;
      }
    }
    catch (e, s)
    {
      logger.w("Error creating image data.", error: e, stackTrace: s);
    }

    String? returnPath;
    if (data != null)
    {
      try
      {
        if (!kIsWeb)
        {
          await File(path).writeAsBytes(data);
          returnPath = path;
        }
        else
        {
          final String newPath = await FileSaver.instance.saveFile(
            name: path,
            bytes: data,
            fileExtension: exportData.extension,
          );
          returnPath = "$newPath/$path.${exportData.extension}";
        }
      }
      catch (e, s)
      {
        logger.w("Error writing image data.", error: e, stackTrace: s);
      }
    }

    return returnPath;
  }

Future<String?> exportAnimation({required final AnimationExportData exportData, required final AnimationExportType exportType}) async
{
  final Logger logger = GetIt.I.get<Logger>();
  final String path = !kIsWeb ? p.join(exportData.directory, "${exportData.fileName}.${exportData.extension}") : exportData.fileName;
  final AppState appState = GetIt.I.get<AppState>();

  logger.i("Exporting animation to $path.");

  Uint8List? data;

  try
  {
    switch (exportType)
    {
      case AnimationExportType.apng:
        data = await exportAPNG(exportData: exportData, appState: appState);
    //break;
      case AnimationExportType.gif:
        data = await exportGIF(exportData: exportData, appState: appState);
    //break;
      case AnimationExportType.zippedPng:
        data = await exportZippedPng(exportData: exportData, appState: appState);
    //break;
    //case ExportType.aseprite:
    // TODO: Handle this case.
    //  break;
    //case ExportType.pixelorama:
    // TODO: Handle this case.
    //  break;
      case AnimationExportType.texturePack:
        data = await exportTexturePackAnimation(exportData: exportData, appState: appState);
    //break;


    }
  }
  catch (e, s)
  {
    logger.w("Error creating animation data.", error: e, stackTrace: s);
  }


  String? returnPath;
  if (data != null)
  {
    try
    {
      if (!kIsWeb)
      {
        await File(path).writeAsBytes(data);
        returnPath = path;
      }
      else
      {
        final String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: data,
          fileExtension: exportData.extension,
        );
        returnPath = "$newPath/$path.${exportData.extension}";
      }
    }
    catch (e, s)
    {
      logger.w("Error writing animation data.", error: e, stackTrace: s);
    }
  }

  return returnPath;
}




  FileNameStatus checkFileName({required final String fileName, required final String directory, required final String extension, final bool allowRecoverFile = true})
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
          'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
          'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
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

      final List<String> invalidCharacters = <String>['/', '\\', '?', '%', '*', ':', '|', '"', '<', '>'];
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

  bool hasWriteAccess({required final String directory}) {
    try {
      final File tempFile = File('$directory${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.tmp');
      tempFile.createSync();
      tempFile.deleteSync();
      return true;
    }
    catch (e)
    {
      return false;
    }
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
          if (directory != null && await directory.exists())
          {
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




  Future<List<ProjectManagerEntryData>> loadProjectsFromInternal() async
  {
    final Logger logger = GetIt.I.get<Logger>();
    logger.i("Loading projects from internal directory: ${GetIt.I.get<AppState>().internalDir}.");

    final List<ProjectManagerEntryData> projectData = <ProjectManagerEntryData>[];
    final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, projectsSubDirName));

    if (await dir.exists())
    {
      try
      {
        await for (final FileSystemEntity entity in dir.list(followLinks: false))
        {
          if (entity is File && entity.path.endsWith(".$fileExtensionKpix"))
          {
            final String? pngPath = await replaceFileExtension(filePath: entity.absolute.path, newExtension: thumbnailExtension, inputFileMustExist: true);
            ui.Image? thumbnail;
            if (pngPath != null)
            {
              final File pngFile = File(pngPath);
              if (await pngFile.exists())
              {
                final Uint8List imageBytes = await pngFile.readAsBytes();
                final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
                final ui.FrameInfo frame = await codec.getNextFrame();
                thumbnail = frame.image;
              }
            }
            projectData.add(ProjectManagerEntryData(name: extractFilenameFromPath(path: entity.absolute.path, keepExtension: false), path: entity.absolute.path, thumbnail: thumbnail, dateTime: await entity.lastModified()));
          }
        }
      }
      catch (e, s)
      {
       logger.w("Error loading projects from internal directory.", error: e, stackTrace: s);
      }
    }
    else
    {
      logger.w("Internal directory ${GetIt.I.get<AppState>().internalDir} does not exist.");
    }
    return projectData;
  }

  void setUint64({required final ByteData bytes, required final int offset, required final int value, final Endian endian = Endian.big})
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
    final List<Directory> internalDirectories =
    <Directory>[
      Directory(p.join(GetIt.I.get<AppState>().internalDir, palettesSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, projectsSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, recoverSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, stampsSubDirName)),
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
        final Directory recoverDir = Directory(p.join(GetIt.I.get<AppState>().internalDir, recoverSubDirName));
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
      final Directory recoverDir = Directory(p.join(GetIt.I.get<AppState>().internalDir, recoverSubDirName));
      final List<FileSystemEntity> files = await recoverDir.list().toList();
      if (files.length == 1)
      {
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

  Future<bool> importProject({required final String? path, final bool showMessages = true}) async
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
            constraints: GetIt.I.get<PreferenceManager>().kPalConstraints,
            path: path,
            sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints,
            referenceLayerSettings: GetIt.I.get<PreferenceManager>().referenceLayerSettings,
            gridLayerSettings: GetIt.I.get<PreferenceManager>().gridLayerSettings,
            drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
            shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
          );
          final AppState appState = GetIt.I.get<AppState>();
          if (loadFileSet.historyState != null && loadFileSet.path != null)
          {
            final String fileName = extractFilenameFromPath(path: loadFileSet.path);
            final String projectPath = p.join(appState.internalDir, projectsSubDirName, fileName);
            if (!File(projectPath).existsSync())
            {
              final ui.Image? img = await getImageFromLoadFileSet(loadFileSet: loadFileSet, size: loadFileSet.historyState!.canvasSize);
              if (img != null)
              {
                success = await copyImportFile(inputPath: loadFileSet.path!, image: img, targetPath: projectPath);
              }
              else
              {
                if (showMessages) appState.showMessage(text: "Could not open file!");
              }
            }
            else
            {
              if (showMessages) appState.showMessage(text: "Project with the same name already exists!");
            }
          }
          else
          {
            if (showMessages) appState.showMessage(text: "Could not open file!");
          }
        }
        else
        {
          GetIt.I.get<AppState>().showMessage(text: "Please select a KPix file!");
        }
      }
    }
    catch (e, s)
    {
      logger.w("Error importing project.", error: e, stackTrace: s);
    }

    return success;
  }
