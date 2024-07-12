
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:uuid/uuid.dart';

class FileHandler
{
  static const int fileVersion = 1;
  static const String magicNumber = "4B504958";

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
      byteData.setUint8(offset++, saveData.layerList[i].data.length);
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
  
  static Future<HistoryState?> loadFile({required final String path, required final KPalConstraints constraints}) async
  {
    final Uint8List uint8list = await File(path).readAsBytes();
    final ByteData byteData = uint8list.buffer.asByteData();
    int offset = 0;
    final int mNumber = byteData.getUint32(offset);
    offset+=4;
    final int fVersion = byteData.getUint8(offset++);

    if (mNumber != int.parse(magicNumber, radix: 16) || fVersion != fileVersion) return null;

    final int rampCount = byteData.getUint8(offset++);
    if (rampCount <= 0) return null;
    List<HistoryRampData> rampList = [];
    for (int i = 0; i < rampCount; i++)
    {
      final KPalRampSettings kPalRampSettings = KPalRampSettings(constraints: constraints);

      kPalRampSettings.colorCount = byteData.getUint8(offset++);
      if (kPalRampSettings.colorCount < constraints.colorCountMin || kPalRampSettings.colorCount > constraints.colorCountMax) return null;
      kPalRampSettings.baseHue = byteData.getInt16(offset);
      offset+=2;
      if (kPalRampSettings.baseHue < constraints.baseHueMin || kPalRampSettings.baseHue > constraints.baseHueMax) return null;
      kPalRampSettings.baseSat = byteData.getUint8(offset++);
      if (kPalRampSettings.baseSat < constraints.baseSatMin || kPalRampSettings.baseSat > constraints.baseSatMax) return null;
      kPalRampSettings.hueShift = byteData.getInt8(offset++);
      if (kPalRampSettings.hueShift < constraints.hueShiftMin || kPalRampSettings.hueShift > constraints.hueShiftMax) return null;
      kPalRampSettings.hueShiftExp =  byteData.getUint8(offset++).toDouble() / 100.0;
      if (kPalRampSettings.hueShiftExp < constraints.hueShiftExpMin || kPalRampSettings.hueShiftExp > constraints.hueShiftExpMax) return null;
      kPalRampSettings.satShift = byteData.getInt8(offset++);
      if (kPalRampSettings.satShift < constraints.satShiftMin || kPalRampSettings.satShift > constraints.satShiftMax) return null;
      kPalRampSettings.satShiftExp =  byteData.getUint8(offset++).toDouble() / 100.0;
      if (kPalRampSettings.satShiftExp < constraints.satShiftExpMin || kPalRampSettings.satShiftExp > constraints.satShiftExpMax) return null;
      final int curveVal = byteData.getUint8(offset++);
      final SatCurve? satCurve = satCurveMap[curveVal];
      if (satCurve == null) return null;
      kPalRampSettings.satCurve = satCurve;
      kPalRampSettings.valueRangeMin = byteData.getUint8(offset++);
      kPalRampSettings.valueRangeMax = byteData.getUint8(offset++);
      if (kPalRampSettings.valueRangeMin < constraints.valueRangeMin || kPalRampSettings.valueRangeMax > constraints.valueRangeMax || kPalRampSettings.valueRangeMax < kPalRampSettings.valueRangeMin) return null;
      //not used at the moment
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
    if (layerCount < 1) return null;
    final List<HistoryLayer> layerList = [];
    for (int i = 0; i < layerCount; i++)
    {
      //not used at the moment
      final int layerType = byteData.getUint8(offset++);
      if (layerType != 1) return null;
      final int visibilityStateVal = byteData.getUint8(offset++);
      final LayerVisibilityState? visibilityState = layerVisibilityStateValueMap[visibilityStateVal];
      if (visibilityState == null) return null;
      final int lockStateVal = byteData.getUint8(offset++);
      final LayerLockState? lockState = layerLockStateValueMap[lockStateVal];
      if (lockState == null) return null;
      final int dataCount = byteData.getUint8(offset++);
      final HashMap<CoordinateSetI, HistoryColorReference> data = HashMap();
      for (int j = 0; j < dataCount; j++)
      {
        final int x = byteData.getUint8(offset++);
        final int y = byteData.getUint8(offset++);
        final int colorRampIndex = byteData.getUint8(offset++);
        final int colorIndex = byteData.getUint8(offset++);
        data[CoordinateSetI(x: x, y: y)] = HistoryColorReference(colorIndex: colorIndex, rampIndex: colorRampIndex);
      }
      layerList.add(HistoryLayer(visibilityState: visibilityState, lockState: lockState, size: canvasSize, data: data));
    }
    final HistorySelectionState selectionState = HistorySelectionState(content: HashMap<CoordinateSetI, HistoryColorReference?>(), currentLayer: layerList[0]);
    return HistoryState(layerList: layerList, selectedColor: HistoryColorReference(colorIndex: 0, rampIndex: 0), selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: 0, description: "load data");
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
      size += 1;
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
}