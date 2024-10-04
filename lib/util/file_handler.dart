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
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/main/layer_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path/path.dart' as p;
import 'dart:ui' as ui;

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


const Map<SatCurve, int> kpixKpalSatCurveMap =
{
  SatCurve.noFlat:1,
  SatCurve.darkFlat:0,
  SatCurve.brightFlat:3,
  SatCurve.linear:2
};

const Map<int, SatCurve> _kpalKpixSatCurveMap =
{
  1:SatCurve.noFlat,
  0:SatCurve.darkFlat,
  3:SatCurve.brightFlat,
  2: SatCurve.linear
};

enum FileNameStatus
{
  available,
  forbidden,
  noRights,
  overwrite
}

const Map<FileNameStatus, String> fileNameStatusTextMap =
{
  FileNameStatus.available:"Available",
  FileNameStatus.forbidden:"Invalid File Name",
  FileNameStatus.noRights:"Insufficient Permissions",
  FileNameStatus.overwrite:"Overwriting Existing File"
};

const Map<FileNameStatus, IconData> fileNameStatusIconMap =
{
  FileNameStatus.available:FontAwesomeIcons.check,
  FileNameStatus.forbidden:FontAwesomeIcons.xmark,
  FileNameStatus.noRights:FontAwesomeIcons.ban,
  FileNameStatus.overwrite:FontAwesomeIcons.exclamation
};

class FileHandler
{
  static const int fileVersion = 1;
  static const String magicNumber = "4B504958";
  static const String fileExtensionKpix = "kpix";
  static const String fileExtensionKpal = "kpal";
  static const String palettesSubDirName = "palettes";
  static const String projectsSubDirName = "projects";
  static const String thumbnailExtension = "png";


  static Future<String> _saveKPixFile({required final String path, required final AppState appState}) async
  {
    final ByteData byteData = await ExportFunctions.getKPixData(appState: appState);
    if (!kIsWeb)
    {
      await File(path).writeAsBytes(byteData.buffer.asUint8List());
      return path;
    }
    else
    {
      String newPath = await FileSaver.instance.saveFile(
        name: path,
        bytes: byteData.buffer.asUint8List(),
        ext: fileExtensionKpix,
        mimeType: MimeType.other,
      );
      return newPath;
    }
  }


  static Future<LoadFileSet> loadKPixFile({required Uint8List? fileData, required final KPalConstraints constraints, required final String path, required final KPalSliderConstraints sliderConstraints}) async
  {
    try
    {
      fileData ??= await File(path).readAsBytes();
      final ByteData byteData = fileData.buffer.asByteData();
      int offset = 0;
      final int mNumber = byteData.getUint32(offset);
      offset+=4;
      final int fVersion = byteData.getUint8(offset++);

      if (mNumber != int.parse(magicNumber, radix: 16)) return LoadFileSet(status: "Wrong magic number: $mNumber");
      if (fVersion != fileVersion) return LoadFileSet(status: "File Version: $fVersion");

      final int rampCount = byteData.getUint8(offset++);
      if (rampCount < 1) return LoadFileSet(status: "No color ramp found");
      List<HistoryRampData> rampList = [];
      for (int i = 0; i < rampCount; i++)
      {
        final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);

        kPalRampSettings.colorCount = byteData.getUint8(offset++);
        if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return LoadFileSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
        kPalRampSettings.baseHue = byteData.getInt16(offset);
        offset+=2;
        if (kPalRampSettings.baseHue < constraints.baseHueMin || kPalRampSettings.baseHue > constraints.baseHueMax) return LoadFileSet(status: "Invalid base hue value in palette $i: ${kPalRampSettings.baseHue}");
        kPalRampSettings.baseSat = byteData.getUint8(offset++);
        if (kPalRampSettings.baseSat < constraints.baseSatMin || kPalRampSettings.baseSat > constraints.baseSatMax) return LoadFileSet(status: "Invalid base sat value in palette $i: ${kPalRampSettings.baseSat}");
        kPalRampSettings.hueShift = byteData.getInt8(offset++);
        if (kPalRampSettings.hueShift < constraints.hueShiftMin || kPalRampSettings.hueShift > constraints.hueShiftMax) return LoadFileSet(status: "Invalid hue shift value in palette $i: ${kPalRampSettings.hueShift}");
        kPalRampSettings.hueShiftExp =  byteData.getUint8(offset++).toDouble() / 100.0;
        if (kPalRampSettings.hueShiftExp < constraints.hueShiftExpMin || kPalRampSettings.hueShiftExp > constraints.hueShiftExpMax) return LoadFileSet(status: "Invalid hue shift exp value in palette $i: ${kPalRampSettings.hueShiftExp}");
        kPalRampSettings.satShift = byteData.getInt8(offset++);
        if (kPalRampSettings.satShift < constraints.satShiftMin || kPalRampSettings.satShift > constraints.satShiftMax) return LoadFileSet(status: "Invalid sat shift value in palette $i: ${kPalRampSettings.satShift}");
        kPalRampSettings.satShiftExp =  byteData.getUint8(offset++).toDouble() / 100.0;
        if (kPalRampSettings.satShiftExp < constraints.satShiftExpMin || kPalRampSettings.satShiftExp > constraints.satShiftExpMax) return LoadFileSet(status: "Invalid sat shift exp value in palette $i: ${kPalRampSettings.satShiftExp}");
        final int curveVal = byteData.getUint8(offset++);
        final SatCurve? satCurve = satCurveMap[curveVal];
        if (satCurve == null) return LoadFileSet(status: "Invalid sat curve for palette $i: $curveVal");
        kPalRampSettings.satCurve = satCurve;
        kPalRampSettings.valueRangeMin = byteData.getUint8(offset++);
        kPalRampSettings.valueRangeMax = byteData.getUint8(offset++);
        if (kPalRampSettings.valueRangeMin < constraints.valueRangeMin || kPalRampSettings.valueRangeMax > constraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin) return LoadFileSet(status: "Invalid value range in palette $i: ${kPalRampSettings.valueRangeMin}-${kPalRampSettings.valueRangeMax}");
        //not used at the moment (don't forget to check for constraints)
        final List<ShiftSet> shifts = [];
        for (int j = 0; j < kPalRampSettings.colorCount; j++)
        {
          final int hueShift = byteData.getInt8(offset++);
          final int satShift = byteData.getInt8(offset++);
          final int valShift = byteData.getInt8(offset++);
          if (hueShift > sliderConstraints.maxHue || hueShift < sliderConstraints.minHue) return LoadFileSet(status: "Invalid Hue Shift in Ramp $i, color $j: $hueShift");
          if (satShift > sliderConstraints.maxSat || satShift < sliderConstraints.minSat) return LoadFileSet(status: "Invalid Sat Shift in Ramp $i, color $j: $satShift");
          if (valShift > sliderConstraints.maxVal || valShift < sliderConstraints.minVal) return LoadFileSet(status: "Invalid Val Shift in Ramp $i, color $j: $valShift");
          final ShiftSet shiftSet = ShiftSet(hueShiftNotifier: ValueNotifier(hueShift), satShiftNotifier: ValueNotifier(satShift), valShiftNotifier: ValueNotifier(valShift));
          shifts.add(shiftSet);
        }
        rampList.add(HistoryRampData(otherSettings: kPalRampSettings, uuid: const Uuid().v1(), notifierShifts: shifts));
      }

      final int width = byteData.getUint16(offset);
      offset+=2;
      final int height = byteData.getUint16(offset);
      offset+=2;
      final CoordinateSetI canvasSize = CoordinateSetI(x: width, y: height);
      final int layerCount = byteData.getUint8(offset++);
      if (layerCount < 1) return LoadFileSet(status: "No layer found");
      final List<HistoryLayer> layerList = [];
      for (int i = 0; i < layerCount; i++)
      {
        //not used at the moment
        final int layerType = byteData.getUint8(offset++);
        if (layerType != 1) return LoadFileSet(status: "Invalid layer type for layer $i: $layerType");
        final int visibilityStateVal = byteData.getUint8(offset++);
        final LayerVisibilityState? visibilityState = layerVisibilityStateValueMap[visibilityStateVal];
        if (visibilityState == null) return LoadFileSet(status: "Invalid visibility type for layer $i: $visibilityStateVal");
        final int lockStateVal = byteData.getUint8(offset++);
        final LayerLockState? lockState = layerLockStateValueMap[lockStateVal];
        if (lockState == null) return LoadFileSet(status: "Invalid lock type for layer $i: $lockStateVal");
        final int dataCount = byteData.getUint32(offset);
        offset+=4;
        final HashMap<CoordinateSetI, HistoryColorReference> data = HashMap();
        for (int j = 0; j < dataCount; j++)
        {
          final int x = byteData.getUint16(offset);
          offset+=2;
          final int y = byteData.getUint16(offset);
          offset+=2;
          final int colorRampIndex = byteData.getUint8(offset++);
          final int colorIndex = byteData.getUint8(offset++);
          data[CoordinateSetI(x: x, y: y)] = HistoryColorReference(colorIndex: colorIndex, rampIndex: colorRampIndex);
        }
        layerList.add(HistoryLayer(visibilityState: visibilityState, lockState: lockState, size: canvasSize, data: data));
      }
      final HistorySelectionState selectionState = HistorySelectionState(content: HashMap<CoordinateSetI, HistoryColorReference?>(), currentLayer: layerList[0]);
      final HistoryState historyState = HistoryState(layerList: layerList, selectedColor: HistoryColorReference(colorIndex: 0, rampIndex: 0), selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: 0, description: "load data");

      return LoadFileSet(status: "loading okay", historyState: historyState, path: path);
    }
    catch (pnfe)
    {
      return LoadFileSet(status: "Could not load file $path");
    }

  }



  static void loadFilePressed({final Function()? finishCallback})
  {
    if (Helper.isDesktop(includingWeb: true))
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: [fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().exportDir
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
    else //mobile
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.any,
          initialDirectory: GetIt.I.get<AppState>().exportDir
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
  }

  static void _loadFileChosen({final FilePickerResult? result, required final Function()? finishCallback})
  {
    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      loadKPixFile(fileData: result.files.first.bytes, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, path: path, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints).then((final LoadFileSet loadFileSet){fileLoaded(loadFileSet: loadFileSet, finishCallback: finishCallback);});
    }
  }

  static void fileLoaded({required final LoadFileSet loadFileSet, required final Function()? finishCallback})
  {
    GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  static Future<void> saveFilePressed({required final String fileName, final Function()? finishCallback, final bool forceSaveAs = false}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String finalPath = p.join(appState.internalDir, projectsSubDirName, "$fileName.$fileExtensionKpix");
      _saveKPixFile(path: finalPath, appState: GetIt.I.get<AppState>()).then((final String path){_projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback);});
    }
    else
    {
      _saveKPixFile(path: fileName, appState: GetIt.I.get<AppState>()).then((final String path){_projectFileSaved(fileName: fileName, path: path, finishCallback: finishCallback);});
    }
  }

  static Future<void> _projectFileSaved({required final String fileName, required final String path, required final Function()? finishCallback}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String? pngPath = await Helper.replaceFileExtension(filePath: path, newExtension: thumbnailExtension, inputFileMustExist: true);
      if (pngPath != null)
      {
        final ui.Image img = await Helper.getImageFromLayers(canvasSize: appState.canvasSize, layers: appState.layers, size: appState.canvasSize);
        final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(pngPath).writeAsBytes(pngBytes!.buffer.asUint8List());
      }
    }

    appState.fileSaved(saveName: fileName, path: path, addKPixExtension: kIsWeb);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  static Future<bool> deleteProject({required final String fullProjectPath}) async
  {
    final bool success = await deleteFile(path: fullProjectPath);
    final String? pngPath = await Helper.replaceFileExtension(filePath: fullProjectPath, newExtension: thumbnailExtension, inputFileMustExist: false);
    if (pngPath != null)
    {
      await deleteFile(path: pngPath);
    }
    return success;
  }

  static Future<bool> deleteFile({required final String path}) async
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

  static Future<bool> saveCurrentPalette({required String fileName, required String directory, required String extension}) async
  {
    final String finalPath = p.join(directory, fileName);
    final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
    Uint8List data = await ExportFunctions.getPaletteKPalData(rampList: rampList);
    return await _savePaletteDataToFile(data: data, path: finalPath, extension: extension);
  }


  static void exportPalettePressed({required PaletteExportData saveData, required PaletteExportType paletteType})
  {
    final String finalPath = p.join(saveData.directory, saveData.fileName);
    final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
    final ColorNames colorNames = GetIt.I.get<PreferenceManager>().colorNames;

    switch (paletteType)
    {
      case PaletteExportType.kpal:
        ExportFunctions.getPaletteKPalData(rampList: rampList).then((final Uint8List data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.png:
        ExportFunctions.getPalettePngData(ramps: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.aseprite:
        ExportFunctions.getPaletteAsepriteData(rampList: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.gimp:
        ExportFunctions.getPaletteGimpData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.paintNet:
        ExportFunctions.getPalettePaintNetData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.adobe:
        ExportFunctions.getPaletteAdobeData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.jasc:
        ExportFunctions.getPaletteJascData(rampList: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.corel:
        ExportFunctions.getPaletteCorelData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
      case PaletteExportType.openOffice:
        ExportFunctions.getPaletteOpenOfficeData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath, extension: saveData.extension);});
        break;
    }
  }

  static Future<bool> _savePaletteDataToFile({required final Uint8List? data, required String path, required final String extension}) async
  {
    final String pathWithExtension = "$path.$extension";
    if (data != null)
    {
      if (!kIsWeb)
      {
        await File(pathWithExtension).writeAsBytes(data);
        GetIt.I.get<AppState>().showMessage(text: "Palette saved at: $pathWithExtension");
      }
      else
      {
        final String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: data,
          ext: extension,
          mimeType: MimeType.other,
        );
        GetIt.I.get<AppState>().showMessage(text: "Palette saved at: $newPath/$pathWithExtension");
      }
      return true;
    }
    else
    {
      GetIt.I.get<AppState>().showMessage(text: "Palette saving failed");
      return false;
    }
  }

  static Future<LoadPaletteSet> _loadKPalFile({required Uint8List? fileData, required final String path, required final KPalConstraints constraints, required final KPalSliderConstraints sliderConstraints}) async
  {
    fileData ??= await File(path).readAsBytes();
    final ByteData byteData = fileData.buffer.asByteData();
    int offset = 0;

    //skip options
    final int optionCount = byteData.getUint8(offset++);
    offset += (optionCount * 2);

    final int rampCount = byteData.getUint8(offset++);
    if (rampCount <= 0) return LoadPaletteSet(status: "no ramp found");
    final List<KPalRampData> rampList = [];
    for (int i = 0; i < rampCount; i++)
    {
      final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);
      final int nameLength = byteData.getUint8(offset++);
      offset += nameLength;
      kPalRampSettings.colorCount = byteData.getUint8(offset++);
      if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return LoadPaletteSet(status: "Invalid color count in palette $i: ${kPalRampSettings.colorCount}");
      kPalRampSettings.baseHue = byteData.getInt16(offset, Endian.little);
      offset+=2;
      if (kPalRampSettings.baseHue < constraints.baseHueMin || kPalRampSettings.baseHue > constraints.baseHueMax) return LoadPaletteSet(status: "Invalid base hue value in palette $i: ${kPalRampSettings.baseHue}");
      kPalRampSettings.baseSat = byteData.getInt16(offset, Endian.little);
      offset+=2;
      if (kPalRampSettings.baseSat < constraints.baseSatMin || kPalRampSettings.baseSat > constraints.baseSatMax) return LoadPaletteSet(status: "Invalid base sat value in palette $i: ${kPalRampSettings.baseSat}");
      kPalRampSettings.hueShift = byteData.getInt8(offset++);
      if (kPalRampSettings.hueShift < constraints.hueShiftMin || kPalRampSettings.hueShift > constraints.hueShiftMax) return LoadPaletteSet(status: "Invalid hue shift value in palette $i: ${kPalRampSettings.hueShift}");
      kPalRampSettings.hueShiftExp = byteData.getFloat32(offset, Endian.little);
      offset += 4;
      if (kPalRampSettings.hueShiftExp < constraints.hueShiftExpMin || kPalRampSettings.hueShiftExp > constraints.hueShiftExpMax) return LoadPaletteSet(status: "Invalid hue shift exp value in palette $i: ${kPalRampSettings.hueShiftExp}");
      kPalRampSettings.satShift = byteData.getInt8(offset++);
      if (kPalRampSettings.satShift < constraints.satShiftMin || kPalRampSettings.satShift > constraints.satShiftMax) return LoadPaletteSet(status: "Invalid sat shift value in palette $i: ${kPalRampSettings.satShift}");
      kPalRampSettings.satShiftExp = byteData.getFloat32(offset, Endian.little);
      offset += 4;
      if (kPalRampSettings.satShiftExp < constraints.satShiftExpMin || kPalRampSettings.satShiftExp > constraints.satShiftExpMax) return LoadPaletteSet(status: "Invalid sat shift exp value in palette $i: ${kPalRampSettings.satShiftExp}");
      kPalRampSettings.valueRangeMin = byteData.getUint8(offset++);
      kPalRampSettings.valueRangeMax = byteData.getUint8(offset++);
      if (kPalRampSettings.valueRangeMin < constraints.valueRangeMin || kPalRampSettings.valueRangeMax > constraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin) return LoadPaletteSet(status: "Invalid value range in palette $i: ${kPalRampSettings.valueRangeMin}-${kPalRampSettings.valueRangeMax}");

      final List<HistoryShiftSet> shifts = [];
      for (int j = 0; j < kPalRampSettings.colorCount; j++)
      {
        final int hueShift = byteData.getInt8(offset++);
        final int satShift = byteData.getInt8(offset++);
        final int valShift = byteData.getInt8(offset++);
        if (hueShift > sliderConstraints.maxHue || hueShift < sliderConstraints.minHue) return LoadPaletteSet(status: "Invalid Hue Shift in Ramp $i, color $j: $hueShift");
        if (satShift > sliderConstraints.maxSat || satShift < sliderConstraints.minSat) return LoadPaletteSet(status: "Invalid Sat Shift in Ramp $i, color $j: $satShift");
        if (valShift > sliderConstraints.maxVal || valShift < sliderConstraints.minVal) return LoadPaletteSet(status: "Invalid Val Shift in Ramp $i, color $j: $valShift");
        final HistoryShiftSet shiftSet = HistoryShiftSet(hueShift: hueShift, satShift: satShift, valShift: valShift);
        shifts.add(shiftSet);
      }
      final int rampOptionCount = byteData.getInt8(offset++);
      for (int j = 0; j < rampOptionCount; j++)
      {
        final int optionType = byteData.getInt8(offset++);
        if (optionType == 1) //sat curve
        {
          final int satCurveVal = byteData.getInt8(offset);
          kPalRampSettings.satCurve = _kpalKpixSatCurveMap[satCurveVal]?? SatCurve.noFlat;
        }
        offset++;
      }
      rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: kPalRampSettings, historyShifts: shifts));
    }
    return LoadPaletteSet(status: "loading okay", rampData: rampList);

  }

  static Future<String?> getDirectory({required String startDir}) async
  {
    return await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Directory", initialDirectory: startDir);
  }

  static Future<String?> exportFile({required final ExportData exportData, required final FileExportType exportType}) async
  {
    final String path = !kIsWeb ? p.join(exportData.directory, ("${exportData.fileName}.${exportData.extension}")) : exportData.fileName;
    final AppState appState = GetIt.I.get<AppState>();

    Uint8List? data;

    switch (exportType)
    {
      case FileExportType.png:
        data = await ExportFunctions.exportPNG(exportData: exportData, appState: appState);
        break;
      case FileExportType.aseprite:
        data = await ExportFunctions.getAsepriteData(exportData: exportData, appState: appState);
        break;
      //case ExportType.photoshop:
      // TODO: Handle this case.
      //  break;
      case FileExportType.gimp:
        data = await ExportFunctions.getGimpData(exportData: exportData, appState: appState);
        break;
      case FileExportType.kpix:
        data = (await ExportFunctions.getKPixData(appState: appState)).buffer.asUint8List();
        break;
    }

    String? returnPath;
    if (data != null)
    {
      if (!kIsWeb)
      {
        await File(path).writeAsBytes(data);
        returnPath = path;
      }
      else
      {
        String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: data,
          ext: exportData.extension,
          mimeType: MimeType.other,
        );
        returnPath = "$newPath/$path.${exportData.extension}";
      }
    }

    return returnPath;
  }

  static FileNameStatus checkFileName({required String fileName, required String directory, required String extension})
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
      final List<String> reservedFilenames = [
        'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
        'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
      ];
      if (fileName.endsWith(' ') || fileName.endsWith('.') || reservedFilenames.contains(fileName.toUpperCase()))
      {
        return FileNameStatus.forbidden;
      }
    }

    final List<String> invalidCharacters = ['/', '\\', '?', '%', '*', ':', '|', '"', '<', '>'];
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

  static bool hasWriteAccess({required final String directory}) {
    try {
      final tempFile = File('$directory${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.tmp');
      tempFile.createSync();
      tempFile.deleteSync();
      return true;
    }
    catch (e)
    {
      return false;
    }
  }

  static Future<String> findExportDir() async
  {
    if (!kIsWeb)
    {
      if (Helper.isDesktop() || Platform.isIOS)
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

  static Future<String> findInternalDir() async
  {
    if (kIsWeb)
    {
      return "";
    }

      final Directory internalDir = await getApplicationSupportDirectory();
      return internalDir.path;
  }

  static Future<List<PaletteManagerEntryData>> loadPalettesFromAssets() async
  {
    final List<PaletteManagerEntryData> paletteData = [];
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> imageAssetsList = assetManifest.listAssets().where((final String string) => (string.startsWith("palettes/") && string.endsWith(".${FileHandler.fileExtensionKpal}"))).toList();
    for (final String filePath in imageAssetsList)
    {
      Uint8List? byteData;
      if (kIsWeb || !Helper.isDesktop())
      {
          ByteData bytes = await rootBundle.load(filePath);
          byteData = bytes.buffer.asUint8List();
      }

      LoadPaletteSet palSet = await _loadKPalFile(path: filePath, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: byteData, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints);
      if (palSet.rampData != null)
      {
        paletteData.add(PaletteManagerEntryData(name: Helper.extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: true, rampDataList: palSet.rampData!, path: filePath));
      }
    }
    return paletteData;
  }

  static Future<List<PaletteManagerEntryData>> loadPalettesFromInternal() async
  {
    final List<PaletteManagerEntryData> paletteData = [];
    final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, palettesSubDirName));
    final List<String> filesWithExtension = [];
    if (await dir.exists())
    {
      dir.listSync(recursive: false, followLinks: false).forEach((entity)
      {
        if (entity is File && entity.path.endsWith(".$fileExtensionKpal"))
        {
          filesWithExtension.add(entity.absolute.path);
        }
      });
    }
    for (final String filePath in filesWithExtension)
    {
      LoadPaletteSet palSet = await _loadKPalFile(path: filePath, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: null, sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints);
      if (palSet.rampData != null)
      {
         paletteData.add(PaletteManagerEntryData(name: Helper.extractFilenameFromPath(path: filePath, keepExtension: false), isLocked: false, rampDataList: palSet.rampData!, path: filePath));
      }
    }
    return paletteData;
  }

  static Future<List<ProjectManagerEntryData>> loadProjectsFromInternal() async
  {
    final List<ProjectManagerEntryData> projectData = [];
    final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, projectsSubDirName));

    if (await dir.exists())
    {
      await for (FileSystemEntity entity in dir.list(recursive: false, followLinks: false))
      {
        if (entity is File && entity.path.endsWith(".$fileExtensionKpix"))
        {
          final String? pngPath = await Helper.replaceFileExtension(filePath: entity.absolute.path, newExtension: thumbnailExtension, inputFileMustExist: true);
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
          projectData.add(ProjectManagerEntryData(name: Helper.extractFilenameFromPath(path: entity.absolute.path, keepExtension: false), path: entity.absolute.path, thumbnail: thumbnail, dateTime: await entity.lastModified()));
        }
      }
    }
    return projectData;
  }

  static void setUint64({required final ByteData bytes, required final int offset, required final int value, final Endian endian = Endian.big})
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
        bytes.setUint32(offset, high, Endian.big);
        bytes.setUint32(offset + 4, low, Endian.big);
      }
    }
    else
    {
      bytes.setUint64(offset, value);
    }
  }

  static Future<void> createInternalDirectories() async
  {
    final List<Directory> internalDirectories =
    [
      Directory(p.join(GetIt.I.get<AppState>().internalDir, palettesSubDirName)),
      Directory(p.join(GetIt.I.get<AppState>().internalDir, projectsSubDirName))
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

}

