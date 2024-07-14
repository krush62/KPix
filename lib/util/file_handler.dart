
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:uuid/uuid.dart';

class LoadFileSet
{
  final String status;
  final HistoryState? historyState;
  final String? path;
  LoadFileSet({required this.status, this.historyState, this.path});
}

class FileHandler
{
  static const int fileVersion = 1;
  static const String magicNumber = "4B504958";
  static const String fileExtension = "kpix";

  static Future<File> saveFile({required final String path, required final AppState appState}) async
  {
    //TODO perform sanity checks (max ramps, max layers, etc...)
    final HistoryState saveData = HistoryState.fromAppState(appState: appState, description: "saveData");
    final ByteData byteData = ByteData(_calculateFileSize(saveData: saveData));

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
      //print("WRITING DATA FOR LAYER $i: $dataLength pixels");
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




  static Future<LoadFileSet> loadFile({required final String path, required final KPalConstraints constraints}) async
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
      if (lockState == null) return LoadFileSet(status: "Invalid lock type for layer $i: $lockStateVal");;
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

  static int _calculateFileSize({required final HistoryState saveData})
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

  static void loadFilePressed()
  {

    //TODO this only works on windows (and macos/linux?) for android/ios us FileType.all and filter by yourself
    FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: [FileHandler.fileExtension],
        initialDirectory: GetIt.I.get<AppState>().appDir
    ).then(_loadFileChosen);
  }

  static void _loadFileChosen(final FilePickerResult? result)
  {
    if (result != null && result.files.single.path != null)
    {
      FileHandler.loadFile(path:  result.files.single.path!, constraints: GetIt.I.get<PreferenceManager>().kPalConstraints).then(_fileLoaded);
    }
  }

  static void _fileLoaded(final LoadFileSet loadFileSet)
  {
    GetIt.I.get<AppState>().restoreFromFile(loadFileSet: loadFileSet);
  }

  static void saveFilePressed()
  {
    //hack
    final Uint8List byteList = Uint8List(1);
    if (GetIt.I.get<AppState>().filePath.value == null)
    {
      FilePicker.platform.saveFile(
          dialogTitle: "Save kpix file",
          type: FileType.custom,
          fileName: GetIt.I.get<AppState>().getFileName(),
          allowedExtensions: [FileHandler.fileExtension],
          initialDirectory: GetIt.I
              .get<AppState>()
              .appDir,
        bytes: byteList
      ).then(_saveFileChosen);
    }
    else
    {
      _saveFileChosen(GetIt.I.get<AppState>().filePath.value);
    }
  }

  static void _saveFileChosen(final String? path)
  {
    print("save file chosen pre");
    if (path != null)
    {
      print("save file chosen: $path");
      final String finalPath = !path.endsWith(".${FileHandler.fileExtension}") ? ("$path.${FileHandler.fileExtension}") : path;
      FileHandler.saveFile(path: finalPath, appState: GetIt.I.get<AppState>()).then(_fileSaved);
    }
  }

  static void _fileSaved(final File file)
  {
    GetIt.I.get<AppState>().fileSaved(path: file.path);
  }
}