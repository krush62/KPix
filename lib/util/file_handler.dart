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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/export_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/save_palette_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path/path.dart' as p;

class LoadFileSet
{
  final String status;
  final HistoryState? historyState;
  final String? path;
  LoadFileSet({required this.status, this.historyState, this.path});
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
  FileNameStatus.available:FontAwesomeIcons.thumbsUp,
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
  static const String webFileName = "KPixExport";
  static const String webPaletteFileName = "KPixPalette";


  static Future<String> _saveKPixFile({required final String path, required final AppState appState}) async
  {
    final ByteData byteData = await ExportFunctions.getKPixData(path: path, appState: appState);
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


  static Future<LoadFileSet> loadKPixFile({required Uint8List? fileData, required final KPalConstraints constraints, required final String path}) async
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
        for (int j = 0; j < kPalRampSettings.colorCount; j++)
        {
          byteData.getInt8(offset++);
          byteData.getInt8(offset++);
          byteData.getInt8(offset++);
        }
        rampList.add(HistoryRampData(otherSettings: kPalRampSettings, uuid: const Uuid().v1()));
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
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS)
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: [fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().saveDir
      ).then((final FilePickerResult? result) {_loadFileChosen(result: result, finishCallback: finishCallback);});
    }
    else //mobile
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.any,
          initialDirectory: GetIt.I.get<AppState>().saveDir
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
      loadKPixFile(fileData: result.files.first.bytes, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, path: path).then((final LoadFileSet loadFileSet){_fileLoaded(loadFileSet: loadFileSet, finishCallback: finishCallback);});
    }
  }

  static void _fileLoaded({required final LoadFileSet loadFileSet, required final Function()? finishCallback})
  {
    GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  static void saveFilePressed({required final String fileName, final Function()? finishCallback, final bool forceSaveAs = false})
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (!kIsWeb)
    {
      final String finalPath = p.join(appState.saveDir, "$fileName.$fileExtensionKpix");
      _saveKPixFile(path: finalPath, appState: GetIt.I.get<AppState>()).then((final String path){_fileSaved(fileName: fileName, path: path, finishCallback: finishCallback);});
    }
    else
    {
      _saveKPixFile(path: webFileName, appState: GetIt.I.get<AppState>()).then((final String path){_fileSaved(fileName: webFileName, path: path, finishCallback: finishCallback);});
    }
  }

  static void _fileSaved({required final String fileName, required final String path, required final Function()? finishCallback})
  {
    GetIt.I.get<AppState>().fileSaved(saveName: fileName, path: path);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }


  static void savePalettePressed({required PaletteSaveData saveData, required PaletteType paletteType})
  {
    final String finalPath = p.join(saveData.directory, "${saveData.fileName}.${saveData.extension}");
    final List<KPalRampData> rampList = GetIt.I.get<AppState>().colorRamps;
    final ColorNames colorNames = GetIt.I.get<PreferenceManager>().colorNames;

    switch (paletteType)
    {
      case PaletteType.kpal:
        ExportFunctions.getPaletteKPalData(rampList: rampList).then((final Uint8List data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.png:
        ExportFunctions.getPalettePngData(ramps: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.aseprite:
        ExportFunctions.getPaletteAsepriteData(rampList: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.gimp:
        ExportFunctions.getPaletteGimpData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.paintNet:
        ExportFunctions.getPalettePaintNetData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.adobe:
        ExportFunctions.getPaletteAdobeData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.jasc:
        ExportFunctions.getPaletteJascData(rampList: rampList).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.corel:
        ExportFunctions.getPaletteCorelData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
      case PaletteType.openOffice:
        ExportFunctions.getPaletteOpenOfficeData(rampList: rampList, colorNames: colorNames).then((final Uint8List? data) {_savePaletteDataToFile(data: data, path: finalPath);});
        break;
    }
  }

  static Future<void> _savePaletteDataToFile({required final Uint8List? data, required String path}) async
  {
    if (data != null)
    {
      if (!kIsWeb)
      {
        await File(path).writeAsBytes(data);
        GetIt.I.get<AppState>().showMessage(text: "Palette saved at: $path");
      }
      else
      {
        String newPath = await FileSaver.instance.saveFile(
          name: path,
          bytes: data,
          ext: fileExtensionKpal,
          mimeType: MimeType.other,
        );
        GetIt.I.get<AppState>().showMessage(text: "Palette saved at: $newPath/$path");
      }

    }
    else
    {
      GetIt.I.get<AppState>().showMessage(text: "Palette saving failed");
    }
  }


  static void loadPalettePressed({required PaletteReplaceBehavior paletteReplaceBehavior})
  {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS)
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: [fileExtensionKpal],
          initialDirectory: GetIt.I.get<AppState>().saveDir
      ).then((final FilePickerResult? result) {
        _loadPaletteChosen(result: result, paletteReplaceBehavior: paletteReplaceBehavior);
      });
    }
    else //mobile
        {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.any,
          initialDirectory: GetIt.I.get<AppState>().saveDir
      ).then((final FilePickerResult? result) {
        _loadPaletteChosen(result: result, paletteReplaceBehavior: paletteReplaceBehavior);
      });
    }
  }

  static void _loadPaletteChosen({required final FilePickerResult? result, required final PaletteReplaceBehavior paletteReplaceBehavior})
  {

    if (result != null && result.files.isNotEmpty)
    {
      String path = result.files.first.name;
      if (!kIsWeb && result.files.first.path != null)
      {
        path = result.files.first.path!;
      }
      _loadKPalFile(path: path, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints, fileData: result.files.first.bytes).then((final LoadPaletteSet loadPaletteSet) {
        _paletteLoaded(loadPaletteSet: loadPaletteSet, paletteReplaceBehavior: paletteReplaceBehavior);
      });
    }
  }

  //this method is not necessary, replacePalette can be called directly from _loadPaletteChosen
  static void _paletteLoaded({required final LoadPaletteSet loadPaletteSet, required final PaletteReplaceBehavior paletteReplaceBehavior})
  {
    GetIt.I.get<AppState>().replacePalette(loadPaletteSet: loadPaletteSet, paletteReplaceBehavior: paletteReplaceBehavior);
  }

  static Future<LoadPaletteSet> _loadKPalFile({required Uint8List? fileData, required final String path, required final KPalConstraints constraints}) async
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
      //not used at the moment (don't forget to check for constraints)
      for (int j = 0; j < kPalRampSettings.colorCount; j++)
      {
        byteData.getInt8(offset++);
        byteData.getInt8(offset++);
        byteData.getInt8(offset++);
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
      rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: kPalRampSettings));
    }
    return LoadPaletteSet(status: "loading okay", rampData: rampList);

  }

  static Future<String?> getDirectory({required String startDir}) async
  {
    return await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Directory", initialDirectory: startDir);
  }

  static Future<String?> exportFile({required final ExportData exportData, required final ExportType exportType}) async
  {
    final String path = !kIsWeb ? p.join(exportData.directory, ("${exportData.fileName}.${exportData.extension}")) : webFileName;
    final AppState appState = GetIt.I.get<AppState>();

    Uint8List? data;

    switch (exportType)
    {
      case ExportType.png:
        data = await ExportFunctions.exportPNG(exportData: exportData, appState: appState);
        break;
      case ExportType.aseprite:
        data = await ExportFunctions.getAsepriteData(exportData: exportData, appState: appState);
        break;
      //case ExportType.photoshop:
      // TODO: Handle this case.
      //  break;
      case ExportType.gimp:
        data = await ExportFunctions.getGimpData(exportData: exportData, appState: appState);
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
          name: webFileName,
          bytes: data,
          ext: exportData.extension,
          mimeType: MimeType.other,
        );
        returnPath = "$newPath/$path";
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
      if (Platform.isWindows || Platform.isMacOS || Platform.isWindows || Platform.isIOS)
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

  static Future<String> findSaveDir() async
  {
    if (!kIsWeb)
    {
      if (Platform.isWindows || Platform.isMacOS || Platform.isWindows || Platform.isIOS)
      {
        final Directory docDir = await getApplicationDocumentsDirectory();
        if (await docDir.exists())
        {
          final Directory kPixDir = Directory(p.join(docDir.path, "KPix"));
          if (!(await kPixDir.exists()))
          {
            final Directory kPixDir2 = await kPixDir.create();
            if (await kPixDir2.exists())
            {
              return kPixDir2.path;
            }
            else
            {
              return docDir.path;
            }
          }
          else
          {
            return kPixDir.path;
          }
        }
      }
      else if (Platform.isAndroid)
      {
        final Directory docDir = Directory("/storage/emulated/0/Documents/");
        if (await docDir.exists())
        {
          final Directory kPixDir = Directory(p.join(docDir.path, "KPix"));
          if (!(await kPixDir.exists()))
          {
            final Directory kPixDir2 = await kPixDir.create();
            if (await kPixDir2.exists())
            {
              return kPixDir2.path;
            }
            else
            {
              return docDir.path;
            }
          }
          else
          {
            return kPixDir.path;
          }
        }
        else
        {
          final Directory directory = await getApplicationDocumentsDirectory();
          if (await directory.exists())
          {
            return directory.path;
          }
        }
      }
    }
    return "";
  }
}