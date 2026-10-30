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

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_image.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_shading_layer.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/ramp_resolver.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_pickers.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/platform_helper.dart';
import 'package:kpix/util/import/import_kpix.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

Future<String?> saveKPixFile({
  required final String path,
}) async
{
  try
  {
    final ByteData byteData = await createKPixData();
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

/// [finishCallback] receives what loading the file came to, or null if loading
/// threw.
void loadFilePressed({final void Function(ProjectLoadResult? result)? finishCallback, final Function()? loadStartCallback})
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

void _loadFileChosen({final FilePickerResult? result, required final void Function(ProjectLoadResult? result)? finishCallback, required final Function()? loadStartCallback,})
{
  if (result != null && result.files.isNotEmpty) 
  {
    final String path = pickedFilePath(file: result.files.first);
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

/// [finishCallback] receives what loading [loadFileSet] came to, or null if
/// loading threw; it is called either way.
void fileLoaded({required final LoadFileSet loadFileSet, required final void Function(ProjectLoadResult? result)? finishCallback,})
{
  ProjectLoadResult? loadResult;
  GetIt.I.get<ProjectSession>().restoreFromFile(loadFileSet: loadFileSet).then((final ProjectLoadResult result)
  {
    loadResult = result;
  }).whenComplete(()
  {
    finishCallback?.call(loadResult);
  });
}

/// [savedCallback] receives the path to show the user once the file is saved;
/// [finishCallback] is called afterwards. If saving failed, only
/// [failedCallback] is called, so nothing that relies on the save goes ahead.
Future<void> saveFilePressed({required final String fileName, final Function()? finishCallback, final void Function(String displayPath)? savedCallback, final Function()? failedCallback, final bool forceSaveAs = false,}) async
{
  final String savePath = kIsWeb ? fileName : p.join(GetIt.I.get<AppPaths>().projectsDir, "$fileName.$fileExtensionKpix");
  final String? path = await saveKPixFile(path: savePath);
  if (path != null)
  {
    await _projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback, savedCallback: savedCallback,);
  }
  else
  {
    failedCallback?.call();
  }
}

Future<void> _projectFileSaved({required final String fileName, required final String path, required final Function()? finishCallback, required final void Function(String displayPath)? savedCallback,}) async
{
  final ProjectSession projectSession = GetIt.I.get<ProjectSession>();
  final DocumentState documentState = GetIt.I.get<DocumentState>();
  final CanvasState canvasState = GetIt.I.get<CanvasState>();
  if (!kIsWeb)
  {
    final String? pngPath = await replaceFileExtension(filePath: path, newExtension: thumbnailExtension,inputFileMustExist: true,);
    if (pngPath != null)
    {
      try
      {
        final Frame frame = documentState.timeline.selectedFrame!;
        final ui.Image img = await getImageFromLayers(canvasSize: canvasState.canvasSize, layerCollection: frame.layerList, selection: documentState.selectionState.selection,frame: frame,);
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

  final String displayPath = projectSession.fileSaved(saveName: fileName, path: path, addKPixExtension: kIsWeb);
  savedCallback?.call(displayPath);
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
        //not File.copy: that keeps a read-only source read-only, e.g. a file picked from a phone on Windows
        final File createdFile = await File(targetPath).writeAsBytes(await projectFile.readAsBytes());
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

Future<ProjectImportResult> importProject({required final String? path}) async
{
  ProjectImportResult result = ProjectImportResult.cancelled;
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
              final bool copied;
              try
              {
                copied = await copyImportFile(inputPath: loadFileSet.path!, image: img, targetPath: projectPath,);
              }
              finally
              {
                img.dispose();
              }
              if (copied)
              {
                notifyProjectFileChanged(path: projectPath);
              }
              result = copied ? ProjectImportResult.success : ProjectImportResult.couldNotOpenFile;
            }
            else
            {
              result = ProjectImportResult.couldNotOpenFile;
            }
          }
          else
          {
            result = ProjectImportResult.projectAlreadyExists;
          }
        }
        else
        {
          result = ProjectImportResult.couldNotOpenFile;
        }
      }
      else
      {
        result = ProjectImportResult.notAKPixFile;
      }
    }
  }
  catch (e, s)
  {
    logger.w("Error importing project.", error: e, stackTrace: s);
    result = ProjectImportResult.couldNotOpenFile;
  }

  return result;
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

  //these layers are in no frame of the open document, so without a stack of
  //their own they would raster nothing; only visible raster layers are drawn
  final List<RasterableLayerState> layers = <RasterableLayerState>[];
  for (final HistoryLayer hLayer in state.timeline.getLayersForFrameIndex(frameIndex: 0))
  {
    if (hLayer.visibilityState == LayerVisibilityState.visible && (hLayer is HistoryDrawingLayer || hLayer is HistoryShadingLayer))
    {
      final RasterableLayerState layer = await hLayer.toLayerState(canvasSize: state.canvasSize, ramps: resolver) as RasterableLayerState;
      layer.layerStack = layers;
      layers.add(layer);
    }
  }

  //shading and effects read the rasters below them, so raster bottom up
  for (final RasterableLayerState layer in layers.reversed)
  {
    layer.forceFullRender();
    bool settled = true;
    await layer.rasterizationComplete.timeout(rasterSettleTimeout, onTimeout: ()
    {
      settled = false;
    },);
    if (!settled)
    {
      GetIt.I.get<Logger>().w("Timed out rasterizing layers for the project thumbnail.");
      break;
    }
  }

  final ui.Image thumbnail = await getImageFromLayers(
    canvasSize: state.canvasSize,
    layerCollection: LayerCollection(layers: layers, selLayerIdx: 0),
    selection: SelectionList(),
  );

  //built only for this thumbnail and never part of a frame, so the sweep in
  //ProjectSession would never see them; the picture is already an image by now
  for (final LayerState layer in layers)
  {
    layer.dispose();
  }
  return thumbnail;
}
