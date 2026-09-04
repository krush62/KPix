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


import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/frame_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/layer_color_supplier.dart';
import 'package:kpix/util/messages.dart';
import 'package:logger/logger.dart';



class ProjectSession
{
  final ValueNotifier<bool> _hasProject = ValueNotifier<bool>(false);
  bool get hasProject
  {
    return _hasProject.value;
  }
  ValueNotifier<bool> get hasProjectNotifier
  {
    return _hasProject;
  }




  final ValueNotifier<String?> projectName = ValueNotifier<String?>(null);
  final ValueNotifier<bool> hasChanges = ValueNotifier<bool>(false);





  ProjectSession()
  {
    GetIt.I.get<DocumentState>().timeline.layerChangeNotifier.addListener((){
      GetIt.I.get<ViewState>().layerSettingsVisible = false;
      resetColorSupplier();
    });
  }


  void init({required final CoordinateSetI dimensions})
  {
    GetIt.I.get<Logger>().i("Creating new image: ${dimensions.x} x ${dimensions.y}.");
    GetIt.I.get<CanvasState>().setCanvasDimensions(width: dimensions.x, height: dimensions.y, addToHistoryStack: false);
    GetIt.I.get<SymmetryState>().reset();
    GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false, notify: false);
    //_layerCollection.clear();
    GetIt.I.get<PaletteState>().setDefaultPalette();
    //addNewDrawingLayer(select: true, addToHistoryStack: false);
    GetIt.I.get<DocumentState>().timeline.init();
    GetIt.I.get<HistoryManager>().clear();
    GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.initial, setHasChanges: false);
    GetIt.I.get<HistoryManager>().markSaved();
    projectName.value = null;
    hasChanges.value = false;
    hasProjectNotifier.value = true;
    GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
  }

  String getTitle()
  {
    return "KPix ${projectName.value ?? ""}${hasChanges.value ? "*" : ""}";
  }

  Future<void> restoreFromFile({required final LoadFileSet loadFileSet, final bool setHasChanges = false}) async
  {
    if (loadFileSet.historyState != null && loadFileSet.path != null)
    {
      await GetIt.I.get<HistoryController>().restoreState(historyState: loadFileSet.historyState, typeGroup: HistoryStateTypeGroup.full);
      final String projectNameExtracted = extractFilenameFromPath(path: loadFileSet.path, keepExtension: false);
      projectName.value = projectNameExtracted == recoverFileName ? null : projectNameExtracted;
      hasChanges.value = setHasChanges;
      hasProjectNotifier.value = true;
      GetIt.I.get<HistoryManager>().clear();
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.initial, setHasChanges: setHasChanges);
      GetIt.I.get<HistoryManager>().markSaved();
      GetIt.I.get<CanvasState>().setCanvasDimensions(width: loadFileSet.historyState!.canvasSize.x , height: loadFileSet.historyState!.canvasSize.y, addToHistoryStack: false);
      GetIt.I.get<SymmetryState>().reset();
      GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      if (loadFileSet.status.isNotEmpty)
      {
        showMessage(text: loadFileSet.status);
      }
    }
    else
    {
      showMessage(text: "Loading failed (${loadFileSet.status})");
    }
  }



  void fileSaved({required final String saveName, required final String path, final bool addKPixExtension = false})
  {
    projectName.value = saveName;
    GetIt.I.get<HistoryManager>().markSaved();
    hasChanges.value = false;

    String displayPath = kIsWeb ? "$path/$saveName" : path;
    if (addKPixExtension)
    {
      displayPath += ".$fileExtensionKpix";
    }
    showMessage(text: "File saved at: $displayPath");
  }


  void importFile({required final ImportResult importResult})
  {
    if (importResult.data != null)
    {
      final DrawingLayerState drawingLayer = importResult.data!.drawingLayer;
      final ReferenceLayerState? referenceLayer = importResult.data!.referenceLayer;
      GetIt.I.get<CanvasState>().setCanvasDimensions(width: importResult.data!.canvasSize.x, height: importResult.data!.canvasSize.y, addToHistoryStack: false);
      final PaletteState paletteState = GetIt.I.get<PaletteState>();
      paletteState.colorRamps = importResult.data!.rampDataList;
      paletteState.selectedColor = paletteState.colorRamps[0].references[0];
      final List<LayerState> layerList = <LayerState>[];
      layerList.add(drawingLayer);
      if (referenceLayer != null)
      {
        layerList.add(referenceLayer);
      }
      final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
      final Frame f = Frame(layerList: LayerCollection(layers: layerList, selLayerIdx: 0), fps: constraints.defaultFps);
      GetIt.I.get<DocumentState>().timeline.setData(selectedFrameIndex: 0, frames: <Frame>[f], loopStartIndex: 0, loopEndIndex: 0);
      GetIt.I.get<HistoryManager>().clear();
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.initial, setHasChanges: false);
      projectName.value = null;
      hasChanges.value = false;
      hasProjectNotifier.value = true;
      GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
    }
    showMessage(text: importResult.message);
  }

}
