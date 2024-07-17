
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
        // TODO: Handle this case.
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

    final Completer<Image> c = Completer<Image>();
      decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        appState.canvasSize.x * exportData.scaling,
        appState.canvasSize.y * exportData.scaling,
        PixelFormat.rgba8888, (Image convertedImage)
      {
        c.complete(convertedImage);
      }
    );
    final Image img = await c.future;

    ByteData? pngBytes = await img.toByteData(format: ImageByteFormat.png);

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

}