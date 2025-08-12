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

  HistoryState({required this.timeline, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.type});

  factory HistoryState.fromAppState({required final AppState appState, required final HistoryStateTypeIdentifier identifier, final Frame? frame, final int? layerIndex, final HistoryState? previousState})
  {
    //TYPE
    final HistoryStateType type = allStateTypeMap[identifier] ?? const HistoryStateType(compressionBehavior: HistoryStateCompressionBehavior.leave, description: "Generic", identifier: HistoryStateTypeIdentifier.generic);

    HistoryStateTypeGroup typeGroup = HistoryStateTypeGroup.full;
    if (type.group == HistoryStateTypeGroup.colorSelect || type.group == HistoryStateTypeGroup.layerSelect)
    {
      typeGroup = type.group;
    }
    else if (frame != null && (type.group == HistoryStateTypeGroup.frame || type.group == HistoryStateTypeGroup.layer))
    {
      typeGroup = HistoryStateTypeGroup.frame;
      if (type.group == HistoryStateTypeGroup.layer && layerIndex != null && layerIndex < frame.layerList.length && layerIndex >= 0)
      {
        typeGroup = HistoryStateTypeGroup.layer;
      }
    }

    //RAMP
    List<HistoryRampData> rampList = <HistoryRampData>[];
    HistoryColorReference selectedColor;
    if (typeGroup == HistoryStateTypeGroup.full || previousState == null)
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
      if (typeGroup == HistoryStateTypeGroup.colorSelect)
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
    LinkedHashSet<HistoryLayer> allHLayers;
    HistoryLayer? selectionLayer;
    if (typeGroup == HistoryStateTypeGroup.colorSelect && previousState != null)
    {
      historyFrameList = previousState.timeline.frames;
      allHLayers = previousState.timeline.allLayers;
    }
    else
    {
      historyFrameList = <HistoryFrame>[];
      final List<Frame> originalFrameList = appState.timeline.frames.value;

      //COLLECT ORIGINAL LAYERS
      final LinkedHashSet<LayerState> collectedLayers = LinkedHashSet<LayerState>();
      for (final Frame frame in originalFrameList)
      {
        final LayerCollection layers = frame.layerList;
        for (int i = 0; i < layers.length; i++)
        {
          collectedLayers.add(layers.getLayer(index: i));
        }
      }

      //CREATE HISTORY LAYERS
      allHLayers = LinkedHashSet<HistoryLayer>();
      for (final LayerState l in collectedLayers)
      {
        //TODO HERE NEEDS TO BE THE LOGIC TO REDUCE MEMORY CONSUMPTION
        final HistoryLayer hLayer = _createHistoryLayer(layerState: l, rampList: rampList)!;
        allHLayers.add(hLayer);
      }

      //CREATING HISTORY FRAMES
      for (final Frame frame in originalFrameList)
      {
        final LayerCollection layers = frame.layerList;
        final LinkedHashSet<int> layerIndices = LinkedHashSet<int>();
        for (int i = 0; i < layers.length; i++)
        {
          final int index = collectedLayers.toList().indexOf(layers.getLayer(index: i));
          layerIndices.add(index);
        }
        historyFrameList.add(HistoryFrame(fps: frame.fps.value, layerIndices: layerIndices, selectedLayerIndex: layers.selectedLayerIndex ?? 0));
      }
    }

    final HistoryTimeline historyTimeline = HistoryTimeline(frames: historyFrameList, loopStart: appState.timeline.loopStartIndex.value, loopEnd: appState.timeline.loopEndIndex.value, selectedFrameIndex: appState.timeline.selectedFrameIndex, allLayers: allHLayers);

    final CoordinateSetI canvasSize = CoordinateSetI.from(other: appState.canvasSize);
    final HistorySelectionState selectionState = HistorySelectionState.fromSelectionState(sState: appState.selectionState, ramps: rampList, historyLayer: selectionLayer);

    return HistoryState(timeline: historyTimeline, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, type: type);
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
