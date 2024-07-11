
import 'dart:collection';

import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/widgets/layer_widget.dart';


class HistoryRampData
{
  final String uuid;
  final KPalRampSettings settings;
  HistoryRampData({required KPalRampSettings otherSettings, required this.uuid}) : settings = KPalRampSettings.from(other: otherSettings);
}

class HistoryColorReference
{
  final int colorIndex;
  final int rampIndex;
  HistoryColorReference({required this.colorIndex, required this.rampIndex});
}

class HistoryLayer
{
  final LayerVisibilityState visibilityState;
  final LayerLockState lockState;
  final CoordinateSetI size;
  final HashMap<CoordinateSetI, HistoryColorReference> data;
  HistoryLayer._({required this.visibilityState, required this.lockState, required this.size, required this.data});
  factory HistoryLayer({required final LayerState layerState, required final List<HistoryRampData> ramps })
  {
    final LayerVisibilityState visState = layerState.visibilityState.value;
    final LayerLockState  lState = layerState.lockState.value;
    final CoordinateSetI sz = CoordinateSetI.from(layerState.size);
    final HashMap<CoordinateSetI, HistoryColorReference> dt = HashMap();
    final HashMap<CoordinateSetI, ColorReference> lData = layerState.getData();
    for (final MapEntry<CoordinateSetI, ColorReference> entry in lData.entries)
    {
      final int? rampIndex = getRampIndex(uuid: entry.value.ramp.uuid, ramps: ramps);
      if (rampIndex != null)
      {
        dt[CoordinateSetI.from(entry.key)] = HistoryColorReference(colorIndex: entry.value.colorIndex, rampIndex: rampIndex);
      }
    }
    return HistoryLayer._(visibilityState: visState, lockState: lState, size: sz, data: dt);
  }
}

class HistorySelectionState
{
  final HashMap<CoordinateSetI, HistoryColorReference?> content;

  HistorySelectionState._({required this.content});

  factory HistorySelectionState({required final SelectionState sState, required final List<HistoryRampData> ramps})
  {
    final HashMap<CoordinateSetI, ColorReference?> otherCnt = sState.selection.getSelectedPixels();
    HashMap<CoordinateSetI, HistoryColorReference?> cnt = HashMap();
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in otherCnt.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = getRampIndex(uuid: entry.value!.ramp.uuid, ramps: ramps);
        if (rampIndex != null)
        {
          cnt[CoordinateSetI.from(entry.key)] = HistoryColorReference(colorIndex: entry.value!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        cnt[CoordinateSetI.from(entry.key)] = null;
      }
    }
    return HistorySelectionState._(content: cnt);
  }

}

class HistoryState
{
  final List<HistoryRampData> rampList;
  final HistoryColorReference selectedColor;
  final List<HistoryLayer> layerList;
  final int selectedLayerIndex;
  final CoordinateSetI canvasSize;
  final HistorySelectionState selectionState;

  HistoryState._({required this.layerList, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.selectedLayerIndex});

  factory HistoryState({required final AppState appState})
  {
    List<HistoryRampData> rampList = [];
    for (final KPalRampData rampData in appState.colorRamps.value)
    {
      rampList.add(HistoryRampData(otherSettings: rampData.settings, uuid: rampData.uuid));
    }
    final int? selectedColorRampIndex = getRampIndex(uuid: appState.selectedColor.value!.ramp.uuid, ramps: rampList);
    final HistoryColorReference selectedColor = HistoryColorReference(colorIndex: appState.selectedColor.value!.colorIndex, rampIndex: selectedColorRampIndex!);
    final List<HistoryLayer> layerList = [];
    int selectedLayerIndex = 0;
    for (int i = 0; i < appState.layers.value.length; i++)
    {
      final LayerState layerState = appState.layers.value[i];
      layerList.add(HistoryLayer(layerState: layerState, ramps: rampList));
      if (layerState.isSelected.value)
      {
        selectedLayerIndex = i;
      }
    }

    final CoordinateSetI canvasSize = CoordinateSetI(x: appState.canvasWidth, y: appState.canvasHeight);
    final HistorySelectionState selectionState = HistorySelectionState(sState: appState.selectionState, ramps: rampList);

    return HistoryState._(layerList: layerList, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: selectedLayerIndex);
  }
}

class HistoryManager
{
  final Queue<HistoryState> _states = Queue();
}

int? getRampIndex({required String uuid, required final List<HistoryRampData> ramps})
{
  int? rampIndex;
  for (int i = 0; i < ramps.length; i++)
  {
    if (ramps[i].uuid == uuid)
    {
      rampIndex = i;
      break;
    }
  }
  return rampIndex;
}