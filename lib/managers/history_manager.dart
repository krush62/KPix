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

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/typedefs.dart';
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
  HistoryLayer({required this.visibilityState, required this.lockState, required this.size, required this.data});
  factory HistoryLayer.fromLayerState({required final LayerState layerState, required final List<HistoryRampData> ramps })
  {
    final LayerVisibilityState visState = layerState.visibilityState.value;
    final LayerLockState  lState = layerState.lockState.value;
    final CoordinateSetI sz = CoordinateSetI.from(other: layerState.size);
    final HashMap<CoordinateSetI, HistoryColorReference> dt = HashMap();
    final CoordinateColorMap lData = layerState.getData();
    for (final CoordinateColor entry in lData.entries)
    {
      final int? rampIndex = _getRampIndex(uuid: entry.value.ramp.uuid, ramps: ramps);
      if (rampIndex != null)
      {
        dt[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: entry.value.colorIndex, rampIndex: rampIndex);
      }
    }
    for (final CoordinateColorNullable entry in layerState.rasterQueue.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = _getRampIndex(uuid: entry.value!.ramp.uuid, ramps: ramps);
        if (rampIndex != null)
        {
          dt[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: entry.value!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        dt.remove(entry.key);
      }
    }

    return HistoryLayer(visibilityState: visState, lockState: lState, size: sz, data: dt);
  }
}

class HistorySelectionState
{
  final HashMap<CoordinateSetI, HistoryColorReference?> content;
  final HistoryLayer? currentLayer;

  HistorySelectionState({required this.content, required this.currentLayer});

  factory HistorySelectionState.fromSelectionState({required final SelectionState sState, required final List<HistoryRampData> ramps, required HistoryLayer? historyLayer})
  {
    final CoordinateColorMapNullable otherCnt = sState.selection.selectedPixels;
    HashMap<CoordinateSetI, HistoryColorReference?> cnt = HashMap();
    for (final CoordinateColorNullable entry in otherCnt.entries)
    {
      if (entry.value != null)
      {
        final int? rampIndex = _getRampIndex(uuid: entry.value!.ramp.uuid, ramps: ramps);
        if (rampIndex != null)
        {
          cnt[CoordinateSetI.from(other: entry.key)] = HistoryColorReference(colorIndex: entry.value!.colorIndex, rampIndex: rampIndex);
        }
      }
      else
      {
        cnt[CoordinateSetI.from(other: entry.key)] = null;
      }
    }
    return HistorySelectionState(content: cnt, currentLayer: historyLayer);
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

  HistoryState({required this.layerList, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.selectedLayerIndex, required this.description});

  factory HistoryState.fromAppState({required final AppState appState, required String description})
  {
    List<HistoryRampData> rampList = [];
    for (final KPalRampData rampData in appState.colorRamps)
    {
      rampList.add(HistoryRampData(otherSettings: rampData.settings, uuid: rampData.uuid));
    }
    final int? selectedColorRampIndex = _getRampIndex(uuid: appState.selectedColor!.ramp.uuid, ramps: rampList);
    final HistoryColorReference selectedColor = HistoryColorReference(colorIndex: appState.selectedColor!.colorIndex, rampIndex: selectedColorRampIndex!);
    final List<HistoryLayer> layerList = [];
    int selectedLayerIndex = 0;
    HistoryLayer? selectLayer;
    for (int i = 0; i < appState.layers.length; i++)
    {
      final LayerState layerState = appState.layers[i];
      final HistoryLayer hLayer = HistoryLayer.fromLayerState(layerState: layerState, ramps: rampList);
      layerList.add(hLayer);
      if (layerState.isSelected.value)
      {
        selectedLayerIndex = i;
      }
      if (layerState == appState.currentLayer)
      {
        selectLayer = hLayer;
      }
    }

    final CoordinateSetI canvasSize = CoordinateSetI.from(other: appState.canvasSize);
    final HistorySelectionState selectionState = HistorySelectionState.fromSelectionState(sState: appState.selectionState, ramps: rampList, historyLayer: selectLayer);

    return HistoryState(layerList: layerList, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: selectedLayerIndex, description: description);
  }
}

class HistoryManager
{
  final ValueNotifier<bool> hasUndo = ValueNotifier(false);
  final ValueNotifier<bool> hasRedo = ValueNotifier(false);
  int _maxEntries;
  int _curPos = -1;
  final Queue<HistoryState> _states = Queue();

  HistoryManager({required int maxEntries}) : _maxEntries = maxEntries;

  String getCurrentDescription()
  {
    return _states.elementAt(_curPos).description;
  }

  void changeMaxEntries({required int maxEntries})
  {
    if (maxEntries < _maxEntries && _states.length > maxEntries)
    {
      _removeFutureEntries();
      final int deleteCount = _states.length - maxEntries;
      for (int i = 0; i < deleteCount; i++)
      {
        _states.removeFirst();
      }
      _curPos -= deleteCount;
      if (_curPos < 0)
      {
        _curPos = 0;
      }

    }
    _maxEntries = maxEntries;
    _updateNotifiers();
  }

  void _removeFutureEntries()
  {
    if (_curPos >= 0 && _curPos < _states.length - 1)
    {
      for (int i = 0; i < (_states.length - _curPos); i++)
      {
        _states.removeLast();
      }
      _curPos = _states.length - 1;
    }
  }

  void addState({required final AppState appState, required final String description, final setHasChanges = true})
  {
    _removeFutureEntries();
    _states.add(HistoryState.fromAppState(appState: appState, description: description));
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
    appState.hasChanges.value = setHasChanges;
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