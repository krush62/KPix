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

import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/history/history_timeline.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

class HistoryState
{
  final HistoryStateType type;
  final List<HistoryRampData> rampList;
  final HistoryColorReference selectedColor;
  final CoordinateSetI canvasSize;
  final HistorySelectionState selectionState;
  final HistoryTimeline timeline;

  final Set<int> restoreLayerIndices;
  final int selectionRevision;

  HistoryState({required this.timeline, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.type, this.selectionRevision = -1, final Set<int>? restoreLayerIndices}) : restoreLayerIndices = restoreLayerIndices ?? const <int>{};

  factory HistoryState.fromAppState({required final AppState appState, required final HistoryStateTypeIdentifier identifier, final LayerState? originLayer, final LayerState? secondOriginLayer, final HistoryState? previousState})
  {
    final Set<int> restoreLayerIndices = <int>{};
    final Set<LayerState> originLayers = <LayerState>{
      if (originLayer != null) originLayer,
      if (secondOriginLayer != null) secondOriginLayer,
    };

    //TYPE
    final HistoryStateType type = allStateTypeMap[identifier] ?? const HistoryStateType(compressionBehavior: HistoryStateCompressionBehavior.leave, description: "Generic", identifier: HistoryStateTypeIdentifier.generic);

    if (originLayers.isEmpty && type.group == HistoryStateTypeGroup.layerFull)
    {
      throw Exception("LAYER STATE ADDED TO HISTORY, BUT NO LAYER SUPPLIED!!!");
    }

    //RAMP
    List<HistoryRampData> rampList = <HistoryRampData>[];
    HistoryColorReference selectedColor;
    final ColorReference currentColor = GetIt.I.get<PaletteState>().selectedColor!;
    if (type.group == HistoryStateTypeGroup.full || previousState == null)
    {
      rampList = <HistoryRampData>[];
      for (final KPalRampData rampData in GetIt.I.get<PaletteState>().colorRamps)
      {
        rampList.add(HistoryRampData(otherSettings: rampData.settings, uuid: rampData.uuid, notifierShifts: rampData.shifts));
      }
      final int? selectedColorRampIndex = getRampIndex(uuid: currentColor.ramp.uuid, ramps: rampList);
      selectedColor = HistoryColorReference(colorIndex: currentColor.colorIndex, rampIndex: selectedColorRampIndex!);
    }
    else
    {
      rampList = previousState.rampList;
      if (type.group == HistoryStateTypeGroup.colorSelect)
      {
        final int? selectedColorRampIndex = getRampIndex(uuid: currentColor.ramp.uuid, ramps: rampList);
        selectedColor = HistoryColorReference(colorIndex: currentColor.colorIndex, rampIndex: selectedColorRampIndex!);
      }
      else
      {
        selectedColor = previousState.selectedColor;
      }
    }

    //TIMELINE
    List<HistoryFrame> historyFrameList;
    LinkedHashSet<HistoryLayer> historyLayerSet;
    if (type.group == HistoryStateTypeGroup.colorSelect && previousState != null)
    {
      historyFrameList = previousState.timeline.frames;
      historyLayerSet = previousState.timeline.allLayers;
    }
    else
    {
      historyFrameList = <HistoryFrame>[];
      final List<Frame> originalFrameList = appState.timeline.frames.value;

      //COLLECT ORIGINAL LAYERS
      final LinkedHashSet<LayerState> originalLayerSet = LinkedHashSet<LayerState>();
      for (final Frame f in originalFrameList)
      {
        final LayerCollection layers = f.layerList;
        for (int i = 0; i < layers.length; i++)
        {
          final LayerState l = layers.getLayer(index: i);
          final bool wasAdded = originalLayerSet.add(l);
          if (wasAdded && originLayers.contains(l))
          {
            restoreLayerIndices.add(originalLayerSet.length - 1);
          }
        }
      }

      //CREATE HISTORY LAYERS
      historyLayerSet = LinkedHashSet<HistoryLayer>();
      final bool hasPrevious = previousState != null;
      final Map<int, HistoryLayer> previousLayerMap = <int, HistoryLayer>{};
      if (hasPrevious)
      {
        for (final HistoryLayer hl in previousState.timeline.allLayers)
        {
          previousLayerMap[hl.layerIdentity] = hl;
        }
      }

      for (final LayerState l in originalLayerSet)
      {
        final int identity = identityHashCode(l);
        final bool forceFullSnapshot = !hasPrevious || type.group == HistoryStateTypeGroup.full;
        final bool isNewLayer        = !previousLayerMap.containsKey(identity);
        final bool isOriginLayer     = type.group == HistoryStateTypeGroup.layerFull && originLayers.contains(l);

        if (forceFullSnapshot || isNewLayer || isOriginLayer)
        {
          HistoryLayer? previousTypedLayer;
          if (isOriginLayer && !forceFullSnapshot && !isNewLayer)
          {
            previousTypedLayer = previousLayerMap[identity];
          }

          historyLayerSet.add(l.toHistoryLayer(ramps: rampList, previousLayer: previousTypedLayer));
        }
        else
        {
          historyLayerSet.add(previousLayerMap[identity]!);
        }
      }

      //CREATING HISTORY FRAMES
      final List<LayerState> originalLayerList = originalLayerSet.toList();
      for (final Frame frame in originalFrameList)
      {
        final LayerCollection layers = frame.layerList;
        final LinkedHashSet<int> layerIndices = LinkedHashSet<int>();
        for (int i = 0; i < layers.length; i++)
        {
          final int index = originalLayerList.indexOf(layers.getLayer(index: i));
          layerIndices.add(index);
        }
        historyFrameList.add(HistoryFrame(fps: frame.fps.value, layerIndices: layerIndices, selectedLayerIndex: layers.selectedLayerIndex ?? 0));
      }
    }

    final HistoryTimeline historyTimeline = HistoryTimeline(frames: historyFrameList, loopStart: appState.timeline.loopStartIndex.value, loopEnd: appState.timeline.loopEndIndex.value, selectedFrameIndex: appState.timeline.selectedFrameIndex, allLayers: historyLayerSet);

    final CoordinateSetI canvasSize = CoordinateSetI.from(other: GetIt.I.get<CanvasState>().canvasSize);
    final int selectionRevision = appState.selectionState.selection.revision;
    final HistorySelectionState selectionState;
    if (previousState != null &&
        type.group != HistoryStateTypeGroup.full &&
        previousState.selectionRevision == selectionRevision)
    {
      selectionState = previousState.selectionState;
    }
    else
    {
      selectionState = HistorySelectionState.fromSelectionState(sState: appState.selectionState, ramps: rampList, previous: previousState?.selectionState);
    }

    return HistoryState(timeline: historyTimeline, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, type: type, selectionRevision: selectionRevision, restoreLayerIndices: restoreLayerIndices);
  }

  static int? getRampIndex({required final String uuid, required final List<HistoryRampData> ramps})
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
}
