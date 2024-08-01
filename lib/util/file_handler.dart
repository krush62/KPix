
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert' show utf8;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/export_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:uuid/uuid.dart';

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


const Map<SatCurve, int> _kpixlKpalSatCurveMap =
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

class FileHandler
{
  static const int fileVersion = 1;
  static const String magicNumber = "4B504958";
  static const String fileExtensionKpix = "kpix";
  static const String fileExtensionKpal = "kpal";


  static Future<File> _saveKPixFile({required final String path, required final AppState appState}) async
  {
    //TODO perform sanity checks (max ramps, max layers, etc...)
    final HistoryState saveData = HistoryState.fromAppState(appState: appState, description: "saveData");
    final ByteData byteData = ByteData(_calculateKPixFileSize(saveData: saveData));

    int offset = 0;
    //header
    byteData.setUint32(offset, int.parse(magicNumber, radix: 16));
    offset+=4;
    //file version
    byteData.setUint8(offset++, fileVersion);

    //rampCount
    byteData.setUint8(offset++, saveData.rampList.length);
    //color ramps
    for (int i = 0; i < saveData.rampList.length; i++)
    {
      final KPalRampSettings rampSettings = saveData.rampList[i].settings;
      //color count
      byteData.setUint8(offset++, rampSettings.colorCount);
      //base hue
      byteData.setUint16(offset, rampSettings.baseHue);
      offset+=2;
      //base sat
      byteData.setUint8(offset++, rampSettings.baseSat);
      //hue shift
      byteData.setInt8(offset++, rampSettings.hueShift);
      //hue shift exp
      byteData.setUint8(offset++, (rampSettings.hueShiftExp * 100).round());
      //sat shift
      byteData.setInt8(offset++, rampSettings.satShift);
      //sat shift exp
      byteData.setUint8(offset++, (rampSettings.satShiftExp * 100).round());
      //sat curve
      int satCurveVal = 0;
      for (int j = 0; i < satCurveMap.length; j++)
      {
        if (satCurveMap[j] == rampSettings.satCurve)
        {
          satCurveVal = j;
          break;
        }
      }
      byteData.setUint8(offset++, satCurveVal);
      //val min
      byteData.setUint8(offset++, rampSettings.valueRangeMin);
      //val max
      byteData.setUint8(offset++, rampSettings.valueRangeMax);
      //color shifts
      for (int j = 0; j < rampSettings.colorCount; j++)
      {
         //hue shift
        byteData.setInt8(offset++, 0);
        //sat shift
        byteData.setInt8(offset++, 0);
        //val shift
        byteData.setInt8(offset++, 0);
      }
    }

    //columns
    byteData.setUint16(offset, saveData.canvasSize.x);
    offset+=2;
    //rows
    byteData.setUint16(offset, saveData.canvasSize.y);
    offset+=2;
    //layer count
    byteData.setUint8(offset++, saveData.layerList.length);
    //layers
    for (int i = 0; i < saveData.layerList.length; i++)
    {
      //layer type
      byteData.setUint8(offset++, 1);
      //visibility
      int visVal = 0;
      for (int j = 0; j < layerVisibilityStateValueMap.length; j++)
      {
        if (layerVisibilityStateValueMap[j] == saveData.layerList[i].visibilityState)
        {
          visVal = j;
          break;
        }
      }
      byteData.setUint8(offset++, visVal);
      //lock type
      int lockVal = 0;
      for (int j = 0; j < layerLockStateValueMap.length; j++)
      {
        if (layerLockStateValueMap[j] == saveData.layerList[i].lockState)
        {
          lockVal = j;
          break;
        }
      }
      byteData.setUint8(offset++, lockVal);
      //data count
      final int dataLength = saveData.layerList[i].data.length;
      byteData.setUint32(offset, dataLength);
      offset+=4;
      //image data
      for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in saveData.layerList[i].data.entries)
      {
        //x
        byteData.setUint16(offset, entry.key.x);
        offset+=2;
        //y
        byteData.setUint16(offset, entry.key.y);
        offset+=2;
        //ramp index
        byteData.setUint8(offset++, entry.value.rampIndex);
        //color index
        byteData.setUint8(offset++, entry.value.colorIndex);
      }
    }

    return File(path).writeAsBytes(byteData.buffer.asUint8List());

  }




  static Future<LoadFileSet> _loadKPixFile({required final String path, required final KPalConstraints constraints}) async
  {
    final Uint8List uint8list = await File(path).readAsBytes();
    final ByteData byteData = uint8list.buffer.asByteData();
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

  static int _calculateKPixFileSize({required final HistoryState saveData})
  {
    int size = 0;

    //header
    size += 4;
    //file version
    size += 1;

    //ramp count
    size += 1;
    for (int i = 0; i < saveData.rampList.length; i++)
    {
      //color count
      size += 1;
      //base hue
      size += 2;
      //base sat
      size += 1;
      //hue shift
      size += 1;
      //hue shift exp
      size += 1;
      //sat shift
      size += 1;
      //sat shift exp
      size += 1;
      //sat curve
      size += 1;
      //val min
      size += 1;
      //val max
      size += 1;
      for (int j = 0; j < saveData.rampList[i].settings.colorCount; j++)
      {
       //hue shift
        size += 1;
        //sat shift
        size += 1;
        //val shift
        size += 1;
      }
    }

    //columns
    size += 2;
    //rows
    size += 2;
    //layer count
    size += 1;
    for (int i = 0; i < saveData.layerList.length; i++)
    {
      //type
      size += 1;
      //visibility
      size += 1;
      //lock type
      size += 1;
      //data count
      size += 4;
      for (int j = 0; j < saveData.layerList[i].data.length; j++)
      {
        //x
        size += 2;
        //y
        size += 2;
        //color ramp index
        size += 1;
        //color index
        size += 1;
      }
    }


    return size;
  }

  static int _calculateKPalFileSize({required final List<KPalRampData> rampList})
  {
    int size = 0;

    //option count
    size += 1;

    //ramp count
    size += 1;
    for (int i = 0; i < rampList.length; i++)
    {
      //name
      size += 1;
      //color count
      size += 1;
      //base hue
      size += 2;
      //base sat
      size += 2;
      //hue shift
      size += 1;
      //hue shift exp
      size += 4;
      //sat shift
      size += 1;
      //sat shift exp
      size += 4;
      //val min
      size += 1;
      //val max
      size += 1;
      for (int j = 0; j < rampList[i].settings.colorCount; j++)
      {
        //hue shift
        size += 1;
        //sat shift
        size += 1;
        //val shift
        size += 1;
      }
      //ramp option count
      size += 1;
      //sat curve option type
      size += 1;
      //sat curve option value
      size += 1;
    }

    //link count
    size += 1;

    return size;
  }

  static void loadFilePressed()
  {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS)
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: [fileExtensionKpix],
          initialDirectory: GetIt.I.get<AppState>().appDir
      ).then(_loadFileChosen);
    }
    else //mobile
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.any,
          initialDirectory: GetIt.I.get<AppState>().appDir
      ).then(_loadFileChosen);
    }
  }

  static void _loadFileChosen(final FilePickerResult? result)
  {
    if (result != null && result.files.single.path != null)
    {
      _loadKPixFile(path:  result.files.single.path!, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints).then(_fileLoaded);
    }
  }

  static void _fileLoaded(final LoadFileSet loadFileSet)
  {
    GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet);
  }

  static void saveFilePressed({final Function()? finishCallback, final bool forceSaveAs = false})
  {
    //hack (FilePicker needs bytes on mobile)
    final Uint8List byteList = Uint8List(0);
    final String finalPath = !GetIt.I.get<AppState>().getFileName().endsWith(".$fileExtensionKpix") ? ("${GetIt.I.get<AppState>().getFileName()}.$fileExtensionKpix") : GetIt.I.get<AppState>().getFileName();
    if (GetIt.I.get<AppState>().filePath.value == null || forceSaveAs)
    {
      FilePicker.platform.saveFile(
          dialogTitle: "Save kpix file",
          type: FileType.custom,
          fileName: finalPath,
          allowedExtensions: [fileExtensionKpix],
          initialDirectory: GetIt.I
              .get<AppState>()
              .appDir,
        bytes: byteList
      ).then((final String? path){_saveFileChosen(path, finishCallback);});
    }
    else
    {
      _saveFileChosen(GetIt.I.get<AppState>().filePath.value, finishCallback);
    }
  }

  static void _saveFileChosen(final String? path, final Function()? finishCallback)
  {
    if (path != null)
    {
      final String finalPath = !path.endsWith(".$fileExtensionKpix") ? ("$path.$fileExtensionKpix") : path;
      _saveKPixFile(path: finalPath, appState: GetIt.I.get<AppState>()).then((final File file){_fileSaved(file, finishCallback);});
    }
  }

  static void _fileSaved(final File file, final Function()? finishCallback)
  {
    GetIt.I.get<AppState>().fileSaved(path: file.path);
    if (finishCallback != null)
    {
      finishCallback();
    }
  }


  static void savePalettePressed({final Function()? finishCallback})
  {
    //hack (FilePicker needs bytes on mobile)
    final Uint8List byteList = Uint8List(0);
    final String finalPath = !GetIt.I.get<AppState>().getFileName().endsWith(".$fileExtensionKpix") ? ("$GetIt.I.get<AppState>().getFileName().$fileExtensionKpix") : GetIt.I.get<AppState>().getFileName();
    FilePicker.platform.saveFile(
        dialogTitle: "Save pal file",
        type: FileType.custom,
        fileName: finalPath,
        allowedExtensions: [fileExtensionKpal],
        initialDirectory: GetIt.I
            .get<AppState>()
            .appDir,
        bytes: byteList
    ).then((final String? path){_paletteSavePathChosen(path, finishCallback);});
  }

  static void _paletteSavePathChosen(final String? path, final Function()? finishCallback)
  {
    if (path != null)
    {
      final String finalPath = !path.endsWith(".$fileExtensionKpal") ? ("$path.$fileExtensionKpal") : path;
      _saveKPalFile(rampList: GetIt.I.get<AppState>().colorRamps.value, path: finalPath).then((final File file) {_paletteSaved(file, finishCallback);});
    }
  }


  static Future<File> _saveKPalFile({required final List<KPalRampData> rampList, required String path}) async
  {
    //TODO perform sanity checks (ramp count, color count, ...)
    final ByteData byteData = ByteData(_calculateKPalFileSize(rampList: rampList));
    int offset = 0;

    //options
    byteData.setUint8(offset++, 0);

    //ramp count
    byteData.setUint8(offset++, rampList.length);
    for (final KPalRampData rampData in rampList)
    {
      //name length
      byteData.setUint8(offset++, 0);
      //color count
      byteData.setUint8(offset++, rampData.settings.colorCount);
      //base hue
      byteData.setUint16(offset, rampData.settings.baseHue, Endian.little);
      offset += 2;
      //base sat
      byteData.setUint16(offset, rampData.settings.baseSat, Endian.little);
      offset += 2;
      //hue shift
      byteData.setUint8(offset++, rampData.settings.hueShift);
      //hueShiftExp
      byteData.setFloat32(offset, rampData.settings.hueShiftExp, Endian.little);
      offset += 4;
      //sat shift
      byteData.setUint8(offset++, rampData.settings.satShift);
      //satShiftExp
      byteData.setFloat32(offset, rampData.settings.satShiftExp, Endian.little);
      offset += 4;
      //val min
      byteData.setUint8(offset++, rampData.settings.valueRangeMin);
      //val max
      byteData.setUint8(offset++, rampData.settings.valueRangeMax);
      for (int j = 0; j < rampData.settings.colorCount; j++)
      {
        //hue shift
        byteData.setUint8(offset++, 0);
        //sat shift
        byteData.setUint8(offset++, 0);
        //val shift
        byteData.setUint8(offset++, 0);
      }
      //ramp option count
      byteData.setUint8(offset++, 1);
      //sat curve option
      byteData.setUint8(offset++, 1); //option type sat curve
      //sat curve value
      byteData.setUint8(offset++, _kpixlKpalSatCurveMap[rampData.settings.satCurve]?? 0);
    }

    //link count
    byteData.setUint8(offset++, 0);
    return File(path).writeAsBytes(byteData.buffer.asUint8List());

  }

  static void loadPalettePressed({required PaletteReplaceBehavior paletteReplaceBehavior})
  {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS)
    {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: [fileExtensionKpal],
          initialDirectory: GetIt.I.get<AppState>().appDir
      ).then((final FilePickerResult? result) {
        _loadPaletteChosen(result: result, paletteReplaceBehavior: paletteReplaceBehavior);
      });
    }
    else //mobile
        {
      FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.any,
          initialDirectory: GetIt.I.get<AppState>().appDir
      ).then((final FilePickerResult? result) {
        _loadPaletteChosen(result: result, paletteReplaceBehavior: paletteReplaceBehavior);
      });
    }
  }

  static void _loadPaletteChosen({required final FilePickerResult? result, required final PaletteReplaceBehavior paletteReplaceBehavior})
  {
    if (result != null && result.files.single.path != null)
    {
      _loadKPalFile(path: result.files.single.path!, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints).then((final LoadPaletteSet loadPaletteSet) {
        _paletteLoaded(loadPaletteSet: loadPaletteSet, paletteReplaceBehavior: paletteReplaceBehavior);
      });
    }
  }

  //this method is not necessary, replacePalette can be called directly from _loadPaletteChosen
  static void _paletteLoaded({required final LoadPaletteSet loadPaletteSet, required final PaletteReplaceBehavior paletteReplaceBehavior})
  {
    GetIt.I.get<AppState>().replacePalette(loadPaletteSet: loadPaletteSet, paletteReplaceBehavior: paletteReplaceBehavior);

  }

  static Future<LoadPaletteSet> _loadKPalFile({required final String path, required final KPalConstraints constraints}) async
  {
    final Uint8List uint8list = await File(path).readAsBytes();
    final ByteData byteData = uint8list.buffer.asByteData();
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

  static void _paletteSaved(final File file, final Function()? finishCallback)
  {
    GetIt.I.get<AppState>().showMessage("Palette saved at: ${file.path}");
    if (finishCallback != null)
    {
      finishCallback();
    }
  }

  static Future<File?> exportFile({required final ExportData exportData, required final ExportTypeEnum exportType}) async
  {
    String? path;
    final Uint8List byteList = Uint8List(0);
    path = await FilePicker.platform.saveFile(
      dialogTitle: "Export as ${exportData.name}",
      type: FileType.custom,
      allowedExtensions: [exportData.extension],
      initialDirectory: GetIt.I
          .get<AppState>()
          .appDir,
      bytes: byteList
    );
    if (path != null)
    {
      path = !path.endsWith(".${exportData.extension}") ? ("$path.${exportData.extension}") : path;
    }

    File? file;

    if (path != null)
    {
      switch (exportType)
      {
        case ExportTypeEnum.png:
          file = await _exportPNG(exportData: exportData, exportPath: path);
          break;
        case ExportTypeEnum.aseprite:
          file = await _exportAseprite(exportData: exportData, exportPath: path);
          break;
        case ExportTypeEnum.photoshop:
        // TODO: Handle this case.
          break;
        case ExportTypeEnum.gimp:
          file = await _exportGimp(exportData: exportData, exportPath: path);
          break;
      }
    }


    return file;
  }


  static Future<File?> _exportPNG({required ExportData exportData, required String exportPath}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final ByteData byteData = await _getImageData(
        ramps: appState.colorRamps.value,
        layers: appState.layers.value,
        selectionState: appState.selectionState,
        imageSize: appState.canvasSize,
        scaling: exportData.scaling);

    final Completer<ui.Image> c = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        appState.canvasSize.x * exportData.scaling,
        appState.canvasSize.y * exportData.scaling,
        ui.PixelFormat.rgba8888, (ui.Image convertedImage)
      {
        c.complete(convertedImage);
      }
    );
    final ui. Image img = await c.future;

    ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return File(exportPath)
        .writeAsBytes(pngBytes!.buffer.asInt8List());
  }


  static Future<ByteData> _getImageData({required final List<KPalRampData> ramps, required final List<LayerState> layers, required SelectionState selectionState, required final CoordinateSetI imageSize, required final int scaling}) async
  {
    final ByteData byteData = ByteData((imageSize.x * scaling) * (imageSize.y * scaling) * 4);
    for (int x = 0; x < imageSize.x; x++)
    {
      for (int y = 0; y < imageSize.y; y++)
      {
        final CoordinateSetI currentCoord = CoordinateSetI(x: x, y: y);
        for (int l = 0; l < layers.length; l++)
        {
          if (layers[l].visibilityState.value == LayerVisibilityState.visible)
          {
            ColorReference? col;
            if (selectionState.selection.currentLayer == layers[l])
            {
              col = selectionState.selection.getColorReference(currentCoord);
            }
            col ??= layers[l].getDataEntry(currentCoord);

            if (col != null)
            {
              for (int i = 0; i < scaling; i++)
              {
                for (int j = 0; j < scaling; j++)
                {
                  byteData.setUint32((((y * scaling) + j) * (imageSize.x * scaling) + ((x * scaling) + i)) * 4,
                      Helper.argbToRgba(col.getIdColor().color.value));
                }
              }
              break;
            }
          }
        }
      }
    }
    return byteData;
  }

  static Future<File?> _exportAseprite({required ExportData exportData, required String exportPath}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final List<Color> colorList = [];
    final Map<ColorReference, int> colorMap = {};
    colorList.add(Colors.black);
    int index = 1;
    for (final KPalRampData kPalRampData in appState.colorRamps.value)
    {
      for (int i = 0; i < kPalRampData.colors.length; i++)
      {
        colorList.add(kPalRampData.colors[i].value.color);
        colorMap[kPalRampData.references[i]] = index;
        index++;
      }
    }
    assert(colorList.length < 256);

    const int headerSize = 128;
    const int frameHeaderSize = 16;
    const int colorProfileSize = 22;
    final int paletteNewSize = 26 + (colorList.length * 6);
    final int paletteOldSize = 10 + (colorList.length * 3);

    final List<List<int>> layerEncBytes = [];
    final List<Uint8List> layerNames = [];
    final ZLibCodec zLibCodec = ZLibCodec();
    for (int l = 0; l < appState.layers.value.length; l++)
    {
      final LayerState layerState = appState.layers.value[l];
      final List<int> imgBytes = [];
      for (int y = 0; y < layerState.size.y; y++)
      {
        for (int x = 0; x < layerState.size.x; x++)
        {
          final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
          final ColorReference? colAtPos = layerState.getDataEntry(curCoord);
          if (colAtPos == null)
          {
            imgBytes.add(0);
          }
          else
          {
            imgBytes.add(colorMap[colAtPos]!);
          }
        }
      }
      final List<int> encData = zLibCodec.encode(imgBytes);
      layerEncBytes.add(encData);
      layerNames.add(utf8.encode("Layer$l"));
    }

    //CALCULATE SIZE
    int fileSize = 0;
    fileSize += headerSize;
    fileSize += frameHeaderSize;
    fileSize += colorProfileSize;
    fileSize += paletteNewSize;
    fileSize += paletteOldSize;

    for (int i = 0; i < layerNames.length; i++)
    {
      fileSize += (24 + layerNames[i].length);
    }

    for (int i = 0; i < layerEncBytes.length; i++)
    {
      fileSize += (26 + layerEncBytes[i].length);
    }

    final ByteData outBytes = ByteData(fileSize);
    int offset = 0;

    //WRITE HEADER
    outBytes.setUint32(offset, fileSize, Endian.little); //file size
    offset+=4;
    outBytes.setUint16(offset, 0xA5E0, Endian.little); //magic number
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //frames
    offset+=2;
    outBytes.setUint16(offset, appState.canvasSize.x, Endian.little); //width
    offset+=2;
    outBytes.setUint16(offset, appState.canvasSize.y, Endian.little); //height
    offset+=2;
    outBytes.setUint16(offset, 8, Endian.little); //color depth
    offset+=2;
    outBytes.setUint32(offset, 1, Endian.little); //flags
    offset+=4;
    outBytes.setUint16(offset, 100, Endian.little); //speed
    offset+=2;
    outBytes.setUint32(offset, 0, Endian.little); //empty
    offset+=4;
    outBytes.setUint32(offset, 0, Endian.little); //empty
    offset+=4;
    outBytes.setUint8(offset, 0); //transparent index
    offset++;
    for (int i = 0; i < 3; i++) //ignore bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    outBytes.setUint16(offset, colorList.length, Endian.little); //color count
    offset+=2;
    outBytes.setUint8(offset, 1); //pixel width
    offset++;
    outBytes.setUint8(offset, 1); //pixel height
    offset++;
    outBytes.setInt16(offset, 0, Endian.little); //x pos grid
    offset+=2;
    outBytes.setInt16(offset, 0, Endian.little); //y pos grid
    offset+=2;
    outBytes.setUint16(offset, 16, Endian.little); //grid width
    offset+=2;
    outBytes.setUint16(offset, 16, Endian.little); //grid height
    offset+=2;
    for (int i = 0; i < 84; i++) //future bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }

    //FRAMES HEADER
    outBytes.setUint32(offset, fileSize - headerSize, Endian.little); //frame size
    offset+=4;
    outBytes.setUint16(offset, 0xF1FA, Endian.little); //magic number
    offset+=2;
    outBytes.setUint16(offset, 3 + (layerEncBytes.length * 2), Endian.little); //chunk count
    offset+=2;
    outBytes.setUint16(offset, 100, Endian.little); //duration
    offset+=2;
    for (int i = 0; i < 2; i++) //empty bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    outBytes.setUint32(offset, 3 + (layerEncBytes.length * 2), Endian.little); //chunk count
    offset+=4;

    //COLOR PROFILE
    outBytes.setUint32(offset, colorProfileSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x2007, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //profile type
    offset+=2;
    outBytes.setUint16(offset, 0, Endian.little); //flags
    offset+=2;
    outBytes.setUint32(offset, 0, Endian.little); //gamma
    offset+=4;
    for (int i = 0; i < 8; i++) //reserved
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }

    //PALETTE
    outBytes.setUint32(offset, paletteNewSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x2019, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint32(offset, colorList.length, Endian.little); //color count
    offset+=4;
    outBytes.setUint32(offset, 0, Endian.little); //first color index
    offset+=4;
    outBytes.setUint32(offset, colorList.length - 1, Endian.little); //last color index
    offset+=4;
    for (int i = 0; i < 8; i++) //reserved
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    for (int i = 0; i < colorList.length; i++)
    {
      outBytes.setUint16(offset, 0, Endian.little); //has name
      offset+=2;
      outBytes.setUint8(offset, colorList[i].red); //red
      offset++;
      outBytes.setUint8(offset, colorList[i].green); //green
      offset++;
      outBytes.setUint8(offset, colorList[i].blue); //blue
      offset++;
      outBytes.setUint8(offset, 255); //alpha
      offset++;
    }

    //PALETTE OLD
    outBytes.setUint32(offset, paletteOldSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x0004, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //packet count
    offset+=2;
    outBytes.setUint8(offset, 0); //skip entries
    offset++;
    outBytes.setUint8(offset, colorList.length); //color count
    offset++;
    for (int i = 0; i < colorList.length; i++)
    {
      outBytes.setUint8(offset, colorList[i].red); //red
      offset++;
      outBytes.setUint8(offset, colorList[i].green); //green
      offset++;
      outBytes.setUint8(offset, colorList[i].blue); //blue
      offset++;
    }

    //LAYERS AND CELS
    for (int i = layerEncBytes.length - 1; i >= 0 ; i--)
    {
      //LAYER
      outBytes.setUint32(offset, 24 + layerNames[i].length, Endian.little); //chunk size
      offset+=4;
      outBytes.setUint16(offset, 0x2004, Endian.little); //chunk type
      offset+=2;
      int flagVal = 0;
      if (appState.layers.value[i].visibilityState.value == LayerVisibilityState.visible)
      {
        flagVal += 1;
      }
      if (appState.layers.value[i].lockState.value != LayerLockState.locked)
      {
        flagVal += 2;
      }
      outBytes.setUint16(offset, flagVal, Endian.little); //flags
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //type
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //child level
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //ignored width
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //ignored height
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //blend mode
      offset+=2;
      outBytes.setUint8(offset, 255); //opacity
      offset++;
      for (int j = 0; j < 3; j++) //reserved
      {
        outBytes.setUint8(offset, 0);
        offset++;
      }
      outBytes.setUint16(offset, layerNames[i].length, Endian.little); //name length
      offset+=2;

      for (int j = 0; j < layerNames[i].length; j++) //name
      {
        outBytes.setUint8(offset, layerNames[(layerEncBytes.length - 1) - i][j]);
        offset++;
      }

      //CEL
      outBytes.setUint32(offset, 26 + layerEncBytes[i].length, Endian.little); //chunk size
      offset+=4;
      outBytes.setUint16(offset, 0x2005, Endian.little); //chunk type
      offset+=2;
      outBytes.setUint16(offset, (layerEncBytes.length - 1) - i, Endian.little); //layer index
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //x pos
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //y pos
      offset+=2;
      outBytes.setUint8(offset, 255); //opacity
      offset++;
      outBytes.setUint16(offset, 2, Endian.little); //cel type
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //z index
      offset+=2;
      for (int j = 0; j < 5; j++) //reserved
      {
        outBytes.setUint8(offset, 0);
        offset++;
      }
      outBytes.setUint16(offset, appState.layers.value[i].size.x, Endian.little); //width
      offset+=2;
      outBytes.setUint16(offset, appState.layers.value[i].size.y, Endian.little); //height
      offset+=2;
      for (int j = 0; j < layerEncBytes[i].length; j++)
      {
        outBytes.setUint8(offset, layerEncBytes[i][j]);
        offset++;
      }
    }
    return File(exportPath).writeAsBytes(outBytes.buffer.asInt8List());

  }

  static Future<File?> _exportGimp({required ExportData exportData, required String exportPath}) async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final List<Color> colorList = [];
    final Map<ColorReference, int> colorMap = {};
    int index = 0;
    for (final KPalRampData kPalRampData in appState.colorRamps.value)
    {
      for (int i = 0; i < kPalRampData.colors.length; i++)
      {
        colorList.add(kPalRampData.colors[i].value.color);
        colorMap[kPalRampData.references[i]] = index;
        index++;
      }
    }
    assert(colorList.length < 256);

    final int fullHeaderSize = 30 + //header
        12 + (3 * colorList.length) + //color map
        9 + //compression
        16 + //resolution
        12 + //tattoo
        12 + //unit
        8 + //prop end
        8 + (appState.layers.value.length * 8) + //layer addresses
        8; //channel addresses

    //LAYER (without name and active layer prop)
    const int singleLayerSize =
        8 + //width
        8 + //height
        8 + //type
        12 + //opacity
        12 + //float opacity
        12 + //visible
        12 + //linked
        12 + //color tag
        12 + //lock content
        12 + //lock alpha
        12 + //lock position
        12 + //apply mask
        12 + //edit mask
        12 + //show mask
        16 + //offsets
        12 + //mode
        12 + //blend space
        12 + //composite space
        12 + //composite mode
        12 + //tattoo
        8 + //prop end
        8 + //hierarchy ptr
        8; //layer mask ptr

    //HIERARCHY
    const int hierarchySize = 4 + //width
        4 + //height
        4 + //bpp
        (4 * 8); //level pointers and end

    //LEVEL
    const int basicLevelSize = 4 + //width
        4 + //height
        8; //pointer end

    final List<List<List<int>>> layerEncBytes = [];
    final List<Uint8List> layerNames = [];
    final ZLibCodec zLibCodec = ZLibCodec();
    const int tileSize = 64;
    for (int l = 0; l < appState.layers.value.length; l++)
    {
      final LayerState layerState = appState.layers.value[l];
      int x = 0;
      int y = 0;
      final List<List<int>> tileList = [];
      do //TILING
      {
        final List<int> imgBytes = [];
        int endX = min(x + tileSize, layerState.size.x);
        int endY = min(y + tileSize, layerState.size.y);
        for (int b = y; b < endY; b++)
        {
          for (int a = x; a < endX; a++)
          {
            final CoordinateSetI curCoord = CoordinateSetI(x: a, y: b);
            final ColorReference? colAtPos = layerState.getDataEntry(curCoord);
            if (colAtPos == null)
            {
              imgBytes.add(0);
              imgBytes.add(0);
            }
            else
            {
              imgBytes.add(colorMap[colAtPos]!);
              imgBytes.add(255);
            }

          }

        }
        final List<int> encData = zLibCodec.encode(imgBytes);
        tileList.add(encData);

        x = (endX >= layerState.size.x) ? 0 : endX;
        y = (endX >= layerState.size.x) ? endY : y;
      }
      while (y < layerState.size.y);

      layerNames.add(utf8.encode("Layer$l"));
      layerEncBytes.add(tileList);
    }

    //CALCULATING SIZE
    bool activeLayerSet = false;
    int fileSize = fullHeaderSize;
    for (int i = 0; i < appState.layers.value.length; i++)
    {
      final List<List<int>> tiles = layerEncBytes[i];
      fileSize += singleLayerSize;
      if (!activeLayerSet)
      {
        fileSize += 8; //ACTIVE LAYER
        activeLayerSet = true;
      }
      //name
      fileSize += 4 + layerNames[i].length + 1;
      //hierarchy
      fileSize += hierarchySize;
      //level 1
      fileSize += basicLevelSize;
      //tile data
      for (final List<int> tileData in tiles)
      {
        fileSize += tileData.length;
      }
      fileSize += tiles.length * 8;
      //level 2
      fileSize += (basicLevelSize - 4);
      //level3
      fileSize += (basicLevelSize - 4);
    }


    //WRITING

    final List<int> layerOffsetsInsertPositions = [];

    int tattooIndex = 2;
    final ByteData outBytes = ByteData(fileSize);
    int offset = 0;

    //header
    final Uint8List fileType = utf8.encode("gimp xcf ");
    final Uint8List version = utf8.encode("v011");
    for (int i = 0; i < fileType.length; i++)
    {
      outBytes.setUint8(offset, fileType[i]);
      offset++;
    }

    for (int i = 0; i < version.length; i++)
    {
      outBytes.setUint8(offset, version[i]);
      offset++;
    }

    outBytes.setUint8(offset, 0);
    offset++;
    outBytes.setUint32(offset, appState.canvasSize.x); //width;
    offset+=4;
    outBytes.setUint32(offset, appState.canvasSize.y); //height
    offset+=4;
    outBytes.setUint32(offset, 2); //base type (2=indexed)
    offset+=4;
    outBytes.setUint32(offset, 150); //precision (8-bit gamma)
    offset+=4;

    //prop list

    //PROP_COLORMAP
    outBytes.setUint32(offset, 1);
    offset+=4;
    outBytes.setUint32(offset, (3 * colorList.length) + 4);
    offset+=4;
    outBytes.setUint32(offset, colorList.length);
    offset+=4;
    for (final Color c in colorList)
    {
      outBytes.setUint8(offset, c.red);
      offset++;
      outBytes.setUint8(offset, c.green);
      offset++;
      outBytes.setUint8(offset, c.blue);
      offset++;
    }

    //PROP_COMPRESSION
    outBytes.setUint32(offset, 17);
    offset+=4;
    outBytes.setUint32(offset, 1);

    offset+=4;
    outBytes.setUint8(offset, 2);
    offset++;

    //PROP_RESOLUTION
    outBytes.setUint32(offset, 19);
    offset+=4;
    outBytes.setUint32(offset, 8);
    offset+=4;
    outBytes.setFloat32(offset, 300);
    offset+=4;
    outBytes.setFloat32(offset, 300);
    offset+=4;

    //PROP_TATTOO
    outBytes.setUint32(offset, 20);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, tattooIndex++);
    offset+=4;

    //PROP_UNIT
    outBytes.setUint32(offset, 22);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 1);
    offset+=4;

    //PROP_END
    outBytes.setUint32(offset, 0);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //LAYER POINTERS
    for (int i = 0; i < appState.layers.value.length; i++)
    {
      layerOffsetsInsertPositions.add(offset);
      outBytes.setUint64(offset, 0);
      offset+=8;
    }

    outBytes.setUint64(offset, 0); //end layer pointers
    offset+=8;
    outBytes.setUint64(offset, 0); //start/end channel pointers
    offset+=8;


    //LAYERS
    for (int i = 0; i < appState.layers.value.length; i++)
    {
      outBytes.setUint64(layerOffsetsInsertPositions[i], offset);

      final LayerState currentLayer = appState.layers.value[i];
      outBytes.setUint32(offset, currentLayer.size.x);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y);
      offset+=4;
      outBytes.setUint32(offset, 5);
      offset+=4;
      outBytes.setUint32(offset, layerNames[i].length + 1);
      offset+=4;
      for (int j = 0; j < layerNames[i].length; j++)
      {
        outBytes.setUint8(offset, layerNames[i][j]);
        offset++;
      }
      outBytes.setUint8(offset, 0);
      offset++;

      //PROP_ACTIVE_LAYER
      if (i == 0)
      {
        outBytes.setUint32(offset, 2);
        offset+=4;
        outBytes.setUint32(offset, 0);
        offset+=4;
      }

      //PROP_OPACITY
      outBytes.setUint32(offset, 6);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 255);
      offset+=4;

      //PROP_FLOAT_OPACITY
      outBytes.setUint32(offset, 33);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setFloat32(offset, 1.0);
      offset+=4;

      //PROP_VISIBLE
      outBytes.setUint32(offset, 8);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.visibilityState.value == LayerVisibilityState.visible ? 1 : 0);
      offset+=4;

      //PROP_LINKED
      outBytes.setUint32(offset, 9);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_COLOR_TAG
      outBytes.setUint32(offset, 34);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_LOCK_CONTENT
      outBytes.setUint32(offset, 28);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.lockState.value == LayerLockState.locked ? 1 : 0);
      offset+=4;

      //PROP_LOCK_ALPHA
      outBytes.setUint32(offset, 10);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.lockState.value == LayerLockState.transparency ? 1 : 0);
      offset+=4;

      //PROP_LOCK_POSITION
      outBytes.setUint32(offset, 32);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_APPLY_MASK
      outBytes.setUint32(offset, 11);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_EDIT_MASK
      outBytes.setUint32(offset, 12);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_SHOW_MASK
      outBytes.setUint32(offset, 13);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_OFFSETS
      outBytes.setUint32(offset, 15);
      offset+=4;
      outBytes.setUint32(offset, 8);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_MODE
      outBytes.setUint32(offset, 7);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 28);
      offset+=4;

      //PROP_BLEND_SPACE
      outBytes.setUint32(offset, 37);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //PROP_COMPOSITE_SPACE
      outBytes.setUint32(offset, 36);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setInt32(offset, -1);
      offset+=4;

      //PROP_COMPOSITE_MODE
      outBytes.setUint32(offset, 35);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setInt32(offset, -1);
      offset+=4;

      //PROP_TATTOO
      outBytes.setUint32(offset, 20);
      offset+=4;
      outBytes.setUint32(offset, 4);
      offset+=4;
      outBytes.setUint32(offset, tattooIndex++);
      offset+=4;

      //PROP_END
      outBytes.setUint32(offset, 0);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;

      //HIERARCHY OFFSET
      final int hierarchyOffsetInsertPosition = offset;
      outBytes.setUint64(offset, 0);
      offset+=8;

      //LAYER MASK
      outBytes.setUint64(offset, 0);
      offset+=8;

      //HIERARCHY
      outBytes.setUint64(hierarchyOffsetInsertPosition, offset);
      outBytes.setUint32(offset, currentLayer.size.x);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y);
      offset+=4;
      outBytes.setUint32(offset, 2);
      offset+=4;
      final int pointerInsertToLevel1 = offset;
      outBytes.setUint64(offset, 0);
      offset+=8;
      final int pointerInsertToLevel2 = offset;
      outBytes.setUint64(offset, 0);
      offset+=8;
      final int pointerInsertToLevel3 = offset;
      outBytes.setUint64(offset, 0);
      offset+=8;
      outBytes.setUint64(offset, 0);
      offset+=8;

      //LEVEL1
      outBytes.setUint64(pointerInsertToLevel1, offset);
      outBytes.setUint32(offset, currentLayer.size.x);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y);
      offset+=4;
      final List<int> tileOffsetsLv1 = [];
      final List<List<int>> currentTiles = layerEncBytes[i];
      for (int j = 0; j < currentTiles.length; j++)
      {
        tileOffsetsLv1.add(offset);
        outBytes.setUint64(offset, 0);
        offset+=8;
      }
      outBytes.setUint64(offset, 0);
      offset+=8;

      //TILE DATA FOR LEVEL1
      for (int j = 0; j < currentTiles.length; j++)
      {
        outBytes.setUint64(tileOffsetsLv1[j], offset);
        final List<int> currentTile = currentTiles[j];
        for (int k = 0; k < currentTile.length; k++)
        {
           outBytes.setUint8(offset, currentTile[k]);
           offset++;
        }
      }

      //LEVEL2
      outBytes.setUint64(pointerInsertToLevel2, offset);
      outBytes.setUint32(offset, currentLayer.size.x ~/ 2);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y ~/ 2);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
      //LEVEL3
      outBytes.setUint64(pointerInsertToLevel3, offset);
      outBytes.setUint32(offset, currentLayer.size.x ~/ 4);
      offset+=4;
      outBytes.setUint32(offset, currentLayer.size.y ~/ 4);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
    }

    return File(exportPath).writeAsBytes(outBytes.buffer.asInt8List());
  }
}