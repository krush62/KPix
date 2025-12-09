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

import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_dither_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/history/history_timeline.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class HistoryState
{
  final HistoryStateType type;
  final List<HistoryRampData> rampList;
  final HistoryColorReference selectedColor;
  final CoordinateSetI canvasSize;
  final HistorySelectionState selectionState;
  final HistoryTimeline timeline;
  final int? restoreLayerIndex;

  HistoryState({required this.timeline, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.type, this.restoreLayerIndex});


  factory HistoryState.fromAppState({required final AppState appState, required final HistoryStateTypeIdentifier identifier, final LayerState? originLayer, final HistoryState? previousState})
  {
    int? restoreLayerIndex;

    //TYPE
    final HistoryStateType type = allStateTypeMap[identifier] ?? const HistoryStateType(compressionBehavior: HistoryStateCompressionBehavior.leave, description: "Generic", identifier: HistoryStateTypeIdentifier.generic);

    if (originLayer == null && type.group == HistoryStateTypeGroup.layerFull)
    {
      throw Exception("LAYER STATE ADDED TO HISTORY, BUT NO LAYER SUPPLIED!!!");
    }

    //RAMP
    List<HistoryRampData> rampList = <HistoryRampData>[];
    HistoryColorReference selectedColor;
    if (type.group == HistoryStateTypeGroup.full || previousState == null)
    {
      rampList = <HistoryRampData>[];
      for (final KPalRampData rampData in appState.colorRamps)
      {
        rampList.add(HistoryRampData(otherSettings: rampData.settings, uuid: rampData.uuid, notifierShifts: rampData.shifts));
      }
      final int? selectedColorRampIndex = getRampIndex(uuid: appState.selectedColor!.ramp.uuid, ramps: rampList);
      selectedColor = HistoryColorReference(colorIndex: appState.selectedColor!.colorIndex, rampIndex: selectedColorRampIndex!);
    }
    else
    {
      rampList = previousState.rampList;
      if (type.group == HistoryStateTypeGroup.colorSelect)
      {
        final int? selectedColorRampIndex = getRampIndex(uuid: appState.selectedColor!.ramp.uuid, ramps: rampList);
        selectedColor = HistoryColorReference(colorIndex: appState.selectedColor!.colorIndex, rampIndex: selectedColorRampIndex!);
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
          if (wasAdded && l == originLayer)
          {
            restoreLayerIndex = originalLayerSet.length - 1;
          }
        }
      }

      //CREATE HISTORY LAYERS
      historyLayerSet = LinkedHashSet<HistoryLayer>();

      for (int i = 0; i < originalLayerSet.length; i++)
      {
        final LayerState l = originalLayerSet.elementAt(i);
        final bool hasPrevious = (previousState != null);

        //WHEN TO CREATE A COPY
        final bool option1 = !hasPrevious;
        final bool option2 = hasPrevious && previousState.timeline.allLayers.length != originalLayerSet.length;
        final bool option3 = type.group == HistoryStateTypeGroup.full;
        final bool option4 = type.group == HistoryStateTypeGroup.layerFull &&  l == originLayer;

        if (option1 || option2 || option3 || option4)
        {
          final HistoryLayer hLayer = _createHistoryLayer(layerState: l, rampList: rampList)!;
          historyLayerSet.add(hLayer);
        }
        else //USE PREVIOUS LAYER
        {
          final HistoryLayer hLayer = previousState.timeline.allLayers.elementAt(i);
          historyLayerSet.add(hLayer);
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

    final CoordinateSetI canvasSize = CoordinateSetI.from(other: appState.canvasSize);
    final HistorySelectionState selectionState = HistorySelectionState.fromSelectionState(sState: appState.selectionState, ramps: rampList);

    return HistoryState(timeline: historyTimeline, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, type: type, restoreLayerIndex: restoreLayerIndex);
  }



  static HistoryLayer? _createHistoryLayer({required final LayerState layerState, required final List<HistoryRampData> rampList})
  {
    HistoryLayer? hLayer;
    if (layerState.runtimeType == DrawingLayerState)
    {
      hLayer = HistoryDrawingLayer.fromDrawingLayerState(layerState: layerState as DrawingLayerState, ramps: rampList);
    }
    else if (layerState.runtimeType == ReferenceLayerState)
    {
      hLayer = HistoryReferenceLayer.fromReferenceLayer(referenceState: layerState as ReferenceLayerState);
    }
    else if (layerState.runtimeType == GridLayerState)
    {
      hLayer = HistoryGridLayer.fromGridLayer(gridState: layerState as GridLayerState);
    }
    else if (layerState.runtimeType == ShadingLayerState)
    {
      hLayer = HistoryShadingLayer.fromShadingLayerState(layerState: layerState as ShadingLayerState);
    }
    else if (layerState.runtimeType == DitherLayerState)
    {
      hLayer = HistoryDitherLayer.fromDitherLayerState(layerState: layerState as DitherLayerState);

    }
    return hLayer;
  }
}
