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

import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_ramp_data.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class HistoryState
{
  final HistoryStateType type;
  final List<HistoryRampData> rampList;
  final HistoryColorReference selectedColor;
  final List<HistoryLayer> layerList;
  final int selectedLayerIndex;
  final CoordinateSetI canvasSize;
  final HistorySelectionState selectionState;

  HistoryState({required this.layerList, required this.selectedColor, required this.selectionState, required this.canvasSize, required this.rampList, required this.selectedLayerIndex, required this.type});

  factory HistoryState.fromAppState({required final AppState appState, required final HistoryStateTypeIdentifier identifier})
  {
    final HistoryStateType type = allStateTypeMap[identifier] ?? HistoryStateType(compressionBehavior: HistoryStateCompressionBehavior.leave, description: "Generic", identifier: HistoryStateTypeIdentifier.generic);

    final List<HistoryRampData> rampList = [];
    for (final KPalRampData rampData in appState.colorRamps)
    {
      rampList.add(HistoryRampData(otherSettings: rampData.settings, uuid: rampData.uuid, notifierShifts: rampData.shifts));
    }
    final int? selectedColorRampIndex = Helper.getRampIndex(uuid: appState.selectedColor!.ramp.uuid, ramps: rampList);
    final HistoryColorReference selectedColor = HistoryColorReference(colorIndex: appState.selectedColor!.colorIndex, rampIndex: selectedColorRampIndex!);
    final List<HistoryLayer> layerList = [];
    int selectedLayerIndex = 0;
    HistoryLayer? selectLayer;
    for (int i = 0; i < appState.layers.length; i++)
    {
      final LayerState layerState = appState.layers[i];
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

      if (hLayer != null)
      {
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
    }

    final CoordinateSetI canvasSize = CoordinateSetI.from(other: appState.canvasSize);
    final HistorySelectionState selectionState = HistorySelectionState.fromSelectionState(sState: appState.selectionState, ramps: rampList, historyLayer: selectLayer);

    return HistoryState(layerList: layerList, selectedColor: selectedColor, selectionState: selectionState, canvasSize: canvasSize, rampList: rampList, selectedLayerIndex: selectedLayerIndex, type: type);
  }
}