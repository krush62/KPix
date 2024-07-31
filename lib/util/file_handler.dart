
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
    final String finalPath = !GetIt.I.get<AppState>().getFileName().endsWith(".$fileExtensionKpix") ? ("$GetIt.I.get<AppState>().getFileName().$fileExtensionKpix") : GetIt.I.get<AppState>().getFileName();
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
        // TODO: Handle this case.
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
    const int singleLayerSize = 12 + //opacity
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
    final ZLibCodec zLibCodec = ZLibCodec(strategy: ZLibOption.strategyRle);
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
              imgBytes.add(1);
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
      fileSize += tiles.length * 8;
      //level1
      fileSize += basicLevelSize;
      for (final List<int> tileData in tiles)
      {
        fileSize += tileData.length;
      }
      //level3
      fileSize += basicLevelSize;
      //tile data
    }


    //WRITING

    final List<int> layerOffsets = [];
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
    outBytes.setUint8(offset, 1);
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
    outBytes.setUint32(offset, 20);
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

    for (int i = 0; i < appState.layers.value.length; i++)
    {
      layerOffsetsInsertPositions.add(offset);
      outBytes.setUint64(offset, 0);
      offset+=8;
    }

    outBytes.setUint64(offset, 0); //end layer pointers
    outBytes.setUint64(offset, 0); //start/end channel pointers


    //TODO finish
  }

}


//TODO delete
//GIMP FILE FORMAT

/*
//HEADER (30 bytes)
byte[9]     "gimp xcf " File type identification (with space at the end)
byte[4]     version     XCF version (use v011)
byte        0            Zero marks the end of the version tag.
uint32      width        Width of canvas
uint32      height       Height of canvas
uint32      base_type    Color mode of the image; one of
						 0: RGB color
						 1: Grayscale
						 2: Indexed color (THIS IS THE ONE)
uint32      precision    Image precision; this field is only present for
						 100: 8-bit linear integer
						 150: 8-bit gamma integer (preferred)

//PROP LIST

uint32  1        Type identification (PROP_COLORMAP)
uint32  3*n+4    Payload length in bytes
uint32  n        Number of colors in the color map (should be <256)
,------------    Repeat n times:
| byte  r        Red component of a color map color
| byte  g        Green component of a color map color
| byte  b        Blue component of a color map color
`--


uint32  17       Type identification (PROP_COMPRESSION)
uint32  1        One byte of payload
byte    comp     Compression indicator; one of
				 0: No compression
				 1: RLE encoding (default)
				 2: zlib compression (worth a try)
				 3: (Never used, but reserved for some fractal compression)

uint32  19       Type identification (PROP_RESOLUTION)
uint32  8        Eight bytes of payload
float   hres     Horizontal resolution in pixels per inch (ppi) =300
float   vres     Vertical resolution in pixels per inch (ppi) =300

uint32  20         Type identification (PROP_TATTOO)
uint32  4          Four bytes of payload
uint32  tattoo     Nonzero unsigned integer identifier

uint32  22       Type identification (PROP_UNIT)
uint32  4        Four bytes of payload
uint32  uid      Unit identifier; one of
				 1: Inches (25.4 mm) (should be default)
				 2: Millimeters (1 mm)
				 3: Points (127/360 mm)
				 4: Picas (127/30 mm)

//SKIP PARASITE (21)

uint32  0          Type identification (PROP_END)
uint32  0          `PROP_END` has no payload.

//layer pointers for each layer:
uint64	address of layer

uint64  0           Zero marks the end of the array of layer pointers.

uint64  0           Zero marks the end of the array of channel pointers. (no channels)



//Layers
uint32     width  Width of the layer
uint32     height Height of the layer
uint32     type   Color mode of the layer: one of
				  0: RGB color without alpha
				  1: RGB color with alpha
				  2: Grayscale without alpha
				  3: Grayscale with alpha
				  4: Indexed without alpha
				  5: Indexed with alpha (THIS SHOULD BE THE MODE)
string     name   Name of the layer

//only for the first layer
uint32  2        Type identification (PROP_ACTIVE_LAYER)
uint32  0        `PROP_ACTIVE_LAYER` has no payload

uint32  6          Type identification (PROP_OPACITY)
uint32  4          Four bytes of payload
uint32  opacity    Opacity on a scale from 0 (fully transparent) to
				 255 (fully opaque) (ALWAYS 255)

uint32  33         Type identification (PROP_FLOAT_OPACITY)
uint32  4          Four bytes of payload
float   opacity    Opacity on a scale from 0.0 (fully transparent) to
				 1.0 (fully opaque) (ALWAYS 1.0)

uint32  8          Type identification (PROP_VISIBLE)
uint32  4          Four bytes of payload
uint32  visible    1 if the layer/channel is visible; 0 if not

uint32  9          Type identification (PROP_LINKED)
uint32  4          Four bytes of payload
uint32  linked     1 if the layer is linked; 0 if not (ALWAYS 0)

uint32  34         Type identification (PROP_COLOR_TAG)
uint32  4          Four bytes of payload
uint32  tag        Color tag of the layer; (ALWAYS 0)

uint32  28         Type identification (PROP_LOCK_CONTENT)
uint32  4          Four bytes of payload
uint32  locked     1 if the content is locked; 0 if not

uint32  10           Type identification (PROP_LOCK_ALPHA)
uint32  4            Four bytes of payload
uint32  lock_alpha   1 if alpha is locked; 0 if not

uint32  32         Type identification (PROP_LOCK_POSITION)
uint32  4          Four bytes of payload
uint32  locked     1 if the position is locked; 0 if not (ALWAYS 0)

uint32  11       Type identification (PROP_APPLY_MASK)
uint32  4        Four bytes of payload
uint32  apply    1 if the layer mask should be applied, 0 if not (ALWAYS 0)

uint32  12       Type identification (PROP_EDIT_MASK)
uint32  4        Four bytes of payload
uint32  editing  1 if the layer mask is currently being edited, 0 if not (ALWAYS 0)

uint32  13       Type identification (PROP_SHOW_MASK)
uint32  4        Four bytes of payload
uint32  visible  1 if the layer mask is visible, 0 if not (ALWAYS 0)

uint32  15       Type identification (PROP_OFFSETS)
uint32  8        Eight bytes of payload
int32   xoffset  Horizontal offset (ALWAYS 0)
int32   yoffset  Vertical offset (ALWAYS 0)

uint32  7        Type identification (PROP_MODE)
uint32  4        Four bytes of payload
unit32  mode     Layer mode; (ALWAYS 28)

uint32  37         Type identification (PROP_BLEND_SPACE)
uint32  4          Four bytes of payload
int32   space      Composite space of the layer; ALWAYS 0

uint32  36         Type identification (PROP_COMPOSITE_SPACE)
uint32  4          Four bytes of payload
int32   space      (ALWAYS -1 -> INT32!!!!)

uint32  35         Type identification (PROP_COMPOSITE_MODE)
uint32  4          Four bytes of payload
int32   mode       (ALWAYS -1 -> INT32!!!!)

uint32  20         Type identification (PROP TATTOO)
uint32  4          Four bytes of payload
uint32  tattoo     Nonzero unsigned integer identifier

uint32  0          Type identification (PROP_END)
uint32  0          `PROP_END` has no payload.

uint64    hptr   Pointer to the hierarchy structure with the pixels
uint64    mptr   Pointer to the layer mask (a channel structure), or 0 (ALWAYS 0)
//hierarchy (comes directly after the layer)
uint32      width   Width of the pixel array
uint32      height  Height of the pixel array
uint32      bpp     Number of bytes per pixel; (ALWAYS 2 [indexed with alpha])
uint64		lptr    Pointer to the "level" structure
uint64     0       Zero marks the end of the list of level pointers.

//Levels (comes directly after the hierarchy)
uint32      width  Width of the pixel array
uint32      height Height of the pixel array
,----------------- Repeat for each of the ceil(width/64)*ceil(height/64) tiles
| pointer   tptr   Pointer to tile data
`--
pointer     0      Zero marks the end of the array of tile pointers.

	TILE DATA (directly after each level)




//STRUCTURE

HEADER
GENERAL PROPS
LAYER1
HIERARCHY1
LEVEL1_1
TILE DATA
LEVEL1_2 (DUMMY)
EMPTY TILE DATA
LEVEL1_3 (DUMMY)
EMPTY TILE DATA
LAYER2
HIERARCHY2
LEVEL2_1
TILE DATA
LEVEL2_2 (DUMMY)
EMPTY TILE DATA
LEVEL2_3 (DUMMY)
EMPTY TILE DATA



 */


