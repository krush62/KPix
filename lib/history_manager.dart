
import 'dart:collection';

import 'package:flutter/cupertino.dart';
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
      final int? rampIndex = _getRampIndex(uuid: entry.value.ramp.uuid, ramps: ramps);
      if (rampIndex != null)
      {
        dt[CoordinateSetI.from(entry.key)] = HistoryColorReference(colorIndex: entry.value.colorIndex, rampIndex: rampIndex);
      }
    }
    final Set<(CoordinateSetI, ColorReference?)> rasterSet = layerState.rasterQueue.toSet();
    for (final (CoordinateSetI, ColorReference?) entry in rasterSet)
    {
      if (entry.$2 != null)
      {
        final int? rampIndex = _getRampIndex(uuid: entry.$2!.ramp.uuid, ramps: ramps);
        if (rampIndex != null)
        {
          dt[CoordinateSetI.from(entry.$1)] = HistoryColorReference(colorIndex: entry.$2!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        dt.remove(entry.$1);
      }
    }

    return HistoryLayer._(visibilityState: visState, lockState: lState, size: sz, data: dt);
  }
}

class HistorySelectionState
{
  final HashMap<CoordinateSetI, HistoryColorReference?> content;
  final HistoryLayer? currentLayer;

  HistorySelectionState._({required this.content, required this.currentLayer});

  factory HistorySelectionState({required final SelectionState sState, required final List<HistoryRampData> ramps, required HistoryLayer? historyLayer})
  {
    final HashMap<CoordinateSetI, ColorReference?> otherCnt = sState.selection.getSelectedPixels();
    HashMap<CoordinateSetI, HistoryColorReference?> cnt = HashMap();
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in otherCnt.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = _getRampIndex(uuid: entry.value!.ramp.uuid, ramps: ramps);
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
    return HistorySelectionState._(content: cnt, currentLayer: historyLayer);
  }

}

class HistoryState
{
  final String description;
  final List<HistoryRampData> rampList;
  final HistoryColorReference selectedColor;
  final List<HistoryLayer> layerList;
  final int selectedLayerIndex;
  final CoordinateSetI canvasSize;
  final HistorySelectionState selectionState;

  HistoryState._({required this.layerList, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.selectedLayerIndex, required this.description});

  factory HistoryState({required final AppState appState, required String description})
  {
    List<HistoryRampData> rampList = [];
    for (final KPalRampData rampData in appState.colorRamps.value)
    {
      rampList.add(HistoryRampData(otherSettings: rampData.settings, uuid: rampData.uuid));
    }
    final int? selectedColorRampIndex = _getRampIndex(uuid: appState.selectedColor.value!.ramp.uuid, ramps: rampList);
    final HistoryColorReference selectedColor = HistoryColorReference(colorIndex: appState.selectedColor.value!.colorIndex, rampIndex: selectedColorRampIndex!);
    final List<HistoryLayer> layerList = [];
    int selectedLayerIndex = 0;
    HistoryLayer? selectLayer;
    for (int i = 0; i < appState.layers.value.length; i++)
    {
      final LayerState layerState = appState.layers.value[i];
      final HistoryLayer hLayer = HistoryLayer(layerState: layerState, ramps: rampList);
      layerList.add(hLayer);
      if (layerState.isSelected.value)
      {
        selectedLayerIndex = i;
      }
      if (layerState == appState.selectionState.selection.currentLayer)
      {
        selectLayer = hLayer;
      }
    }

    final CoordinateSetI canvasSize = CoordinateSetI.from(appState.canvasSize);
    final HistorySelectionState selectionState = HistorySelectionState(sState: appState.selectionState, ramps: rampList, historyLayer: selectLayer);

    return HistoryState._(layerList: layerList, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: selectedLayerIndex, description: description);
  }
}

class HistoryManager
{
  final ValueNotifier<bool> hasUndo = ValueNotifier(false);
  final ValueNotifier<bool> hasRedo = ValueNotifier(false);
  //TODO magic number (-> config)
  final int _maxEntries = 10;
  int _curPos = -1;
  final Queue<HistoryState> _states = Queue();

  String getCurrentDescription()
  {
    return _states.elementAt(_curPos).description;
  }

  void addState({required final AppState appState, required final String description})
  {
    print("ADDING STATE: " + description);
    if (_curPos >= 0 && _curPos < _states.length - 1)
    {
      for (int i = 0; i < (_states.length - _curPos); i++)
      {
        _states.removeLast();
      }
      _curPos = _states.length - 1;
    }

    _states.add(HistoryState(appState: appState, description: description));
    _curPos++;
    final int entriesLeft = (_maxEntries - _states.length);

    if (entriesLeft < 0)
    {
      for (int i = 0; i < -entriesLeft; i++)
      {
        _states.removeFirst();
        _curPos--;
      }
    }
    _updateNotifiers();
  }


  HistoryState? undo()
  {
    HistoryState? hState;
    if (_curPos > 0)
    {
      _curPos--;
       hState = _states.elementAt(_curPos);
       _updateNotifiers();
    }
    return hState;
  }


  HistoryState? redo()
  {
    HistoryState? hState;
    if (_curPos < _states.length - 1)
    {
      _curPos++;
      hState = _states.elementAt(_curPos);
      _updateNotifiers();
    }
    return hState;
  }

  void _updateNotifiers()
  {
    hasUndo.value = (_curPos > 0);
    hasRedo.value = (_curPos < _states.length - 1);
  }
}

int? _getRampIndex({required String uuid, required final List<HistoryRampData> ramps})
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