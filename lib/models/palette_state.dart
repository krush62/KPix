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

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/widgets/kpal/kpal_constraints.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

/// The project's color ramps and the color currently being drawn with.
///
/// This is document state: it is written to the file, and undo restores it.
class PaletteState
{
  //resolved on demand, the palette outlives no boot order this way
  AppState get _appState => GetIt.I.get<AppState>();

  final ValueNotifier<List<KPalRampData>> _colorRamps = ValueNotifier<List<KPalRampData>>(<KPalRampData>[]);
  List<KPalRampData> get colorRamps
  {
    return _colorRamps.value;
  }
  ValueNotifier<List<KPalRampData>> get colorRampNotifier
  {
    return _colorRamps;
  }

  /// Replaces the ramp list outright, **without** a history entry.
  ///
  /// For the history restore and the image importer, which arrive with a
  /// complete palette of their own. Everything a user does goes through the
  /// methods below instead, so that it can be undone.
  set colorRamps(final List<KPalRampData> ramps)
  {
    _colorRamps.value = ramps;
  }

  final ValueNotifier<ColorReference?> _selectedColor = ValueNotifier<ColorReference?>(null);
  ColorReference? get selectedColor
  {
    return _selectedColor.value;
  }
  ValueNotifier<ColorReference?> get selectedColorNotifier
  {
    return _selectedColor;
  }

  /// Sets the drawing color **without** a history entry and without restoring a
  /// draw tool. See [colorSelected] for the interactive path.
  set selectedColor(final ColorReference? color)
  {
    _selectedColor.value = color;
  }

  void setDefaultPalette()
  {
    _colorRamps.value = KPalRampData.getDefaultPalette();
    _selectedColor.value = _colorRamps.value[0].references[0];
  }

  int getPixelCountForRamp({required final KPalRampData ramp, final bool includeInvisible = true})
  {
    int pixelCount = 0;
    final List<Frame> allFrames = _appState.timeline.frames.value;
    final LinkedHashSet<LayerState> originalLayerSet = LinkedHashSet<LayerState>();
    for (final Frame f in allFrames)
    {
      final LayerCollection layers = f.layerList;
      for (int i = 0; i < layers.length; i++)
      {
        originalLayerSet.add(layers.getLayer(index: i));
      }
    }

    for (final LayerState layer in originalLayerSet)
    {
      if (layer is DrawingLayerState && (includeInvisible || layer.visibilityState.value == LayerVisibilityState.visible))
      {
        pixelCount += layer.getPixelCountForRamp(ramp: ramp);
      }
    }
    return pixelCount;
  }

  void deleteRamp({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    if (colorRamps.length > KPalConstraints.rampCountMin)
    {
      final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
      rampDataList.remove(ramp);
      _selectedColor.value = rampDataList[0].references[0];
      _colorRamps.value = rampDataList;
      for (final Frame f in _appState.timeline.frames.value)
      {
        f.layerList.deleteRampFromLayers(ramp: ramp, backupColor: rampDataList[0].references[0]);
      }
      GetIt.I.get<LayerManager>().rasterLayersAll();
      GetIt.I.get<ViewState>().repaintNotifier.repaint();
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.kPalDelete);
      }
    }
    else
    {
      showMessage(text: "Need at least ${KPalConstraints.rampCountMin} color ramp(s)!");
    }
  }

  void updateRamp({required final KPalRampData ramp, required final KPalRampData originalData, final bool addToHistoryStack = true})
  {
    final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
    _colorRamps.value = rampDataList;

    if (ramp.references.length != originalData.references.length)
    {
      final HashMap<int, int> indexMap = remapIndices(oldLength: originalData.references.length, newLength: ramp.references.length);
      _selectedColor.value = ramp.references[indexMap[_selectedColor.value!.colorIndex]!];
      for (final Frame f in _appState.timeline.frames.value)
      {
        f.layerList.remapLayers(newData: ramp, map: indexMap);
      }

    }
    GetIt.I.get<LayerManager>().rasterLayersAll();
    GetIt.I.get<ViewState>().repaintNotifier.repaint();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.kPalChange);
    }
  }

  Future<KPalRampData?> addNewRamp({final bool addToHistoryStack = true}) async
  {
    if (colorRamps.length < KPalConstraints.rampCountMax)
    {
      const Uuid uuid = Uuid();
      final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
      final KPalRampData newRamp = KPalRampData(
        uuid: uuid.v1(),
        settings: KPalRampSettings(),
      );
      rampDataList.add(newRamp);
      _colorRamps.value = rampDataList;
      _selectedColor.value = newRamp.references[0];
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.kPalAdd);
      }
      return newRamp;
    }
    else
    {
      showMessage(text: "Not more than ${KPalConstraints.rampCountMax} color ramps allowed!");
      return null;
    }
  }

  void changeColorOrder({required final KPalRampData ramp, required final int newPosition, final bool addToHistoryStack = true})
  {
    final int sourcePosition = _colorRamps.value.indexOf(ramp);
    if (sourcePosition != newPosition && (sourcePosition + 1) != newPosition)
    {
      final List<KPalRampData> newListOfRamps = <KPalRampData>[];
      newListOfRamps.addAll(_colorRamps.value);

      newListOfRamps.removeAt(sourcePosition);
      if (newPosition > sourcePosition)
      {
        newListOfRamps.insert(newPosition - 1, ramp);
      }
      else
      {
        newListOfRamps.insert(newPosition, ramp);
      }
      _colorRamps.value = newListOfRamps;
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.kPalOrderChange);
    }
  }

  void replacePalette({required final LoadPaletteSet loadPaletteSet, required final PaletteReplaceBehavior paletteReplaceBehavior})
  {
    final String failMessage = "Loading palette failed (${loadPaletteSet.status})";
    final Logger logger = GetIt.I.get<Logger>();
    logger.i("Replacing palette");
    try
    {
      if (loadPaletteSet.rampData != null && loadPaletteSet.rampData!.isNotEmpty)
      {
        final LinkedHashSet<LayerState> collectedLayers = LinkedHashSet<LayerState>();
        for (final Frame f in _appState.timeline.frames.value)
        {
          final LayerCollection layers = f.layerList;
          for (int i = 0; i < layers.length; i++)
          {
            collectedLayers.add(layers.getLayer(index: i));
          }
        }

        final HashMap<ColorReference, ColorReference> rampMap = getRampMap(rampList1: colorRamps, rampList2: loadPaletteSet.rampData!);

        for (final LayerState layer in collectedLayers)
        {
          if (layer is DrawingLayerState)
          {
            if (paletteReplaceBehavior == PaletteReplaceBehavior.replace)
            {
              for (final KPalRampData kPalRampData in colorRamps)
              {
                layer.deleteRamp(ramp: kPalRampData);
              }
              layer.resetLayerEffectColors(newColor: loadPaletteSet.rampData!.first.references.first);
            }
            else
            {
              layer.remapAllColors(rampMap: rampMap);
              layer.remapLayerEffectColors(rampMap: rampMap);
            }
            layer.doManualRaster = true;
          }
        }
        _selectedColor.value = loadPaletteSet.rampData![0].references[0];
        _colorRamps.value = loadPaletteSet.rampData!;
        GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.kPalAdd);
      }
      else
      {
        logger.w(failMessage);
        showMessage(text: failMessage);
      }
    }
    catch (e, s)
    {
      logger.w(failMessage, error: e, stackTrace: s);
      showMessage(text: failMessage);
    }
  }

  void appendPalette({required final LoadPaletteSet loadPaletteSet})
  {
    if (loadPaletteSet.rampData != null && loadPaletteSet.rampData!.isNotEmpty)
    {
      final List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps);
      for (final KPalRampData ramp in loadPaletteSet.rampData!)
      {
        rampDataList.add(ramp);
      }
      _colorRamps.value = rampDataList;
      GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.kPalAdd);
    }
    else
    {
      final String failMessage = "Loading palette failed (${loadPaletteSet.status})";
      GetIt.I.get<Logger>().w(failMessage);
      showMessage(text: failMessage);
    }
  }

  void colorSelected({required final ColorReference? color, final bool addToHistory = true})
  {
    if (_selectedColor.value != color)
    {
      _selectedColor.value = color;
      if (addToHistory)
      {
        GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.colorChange);
      }

      final ToolState toolState = GetIt.I.get<ToolState>();
      if (!toolState.selectedTool.isDrawTool())
      {
        toolState.restorePreviousDrawTool();
      }
    }
  }

  void incrementColorSelection()
  {
    final (int, int) indices = _getRampAndColorIndex(color: selectedColor!);
    if (indices.$1 >= 0 && indices.$1 < colorRamps.length && indices.$2 >= 0 && indices.$2 < colorRamps[indices.$1].references.length)
    {
      if ((indices.$2 + 1) < colorRamps[indices.$1].references.length)
      {
        colorSelected(color: colorRamps[indices.$1].references[indices.$2 + 1]);
      }
      else if ((indices.$1 + 1) < colorRamps.length)
      {
        colorSelected(color: colorRamps[indices.$1 + 1].references.first);
      }
      else
      {
        colorSelected(color: colorRamps.first.references.first);
      }
    }
  }

  void decrementColorSelection()
  {
    final (int, int) indices = _getRampAndColorIndex(color: selectedColor!);
    if (indices.$1 >= 0 && indices.$1 < colorRamps.length && indices.$2 >= 0 && indices.$2 < colorRamps[indices.$1].references.length)
    {
      if ((indices.$2 - 1) >= 0)
      {
        colorSelected(color: colorRamps[indices.$1].references[indices.$2 - 1]);
      }
      else if ((indices.$1 - 1) >= 0)
      {
        colorSelected(color: colorRamps[indices.$1 - 1].references.last);
      }
      else
      {
        colorSelected(color: colorRamps.last.references.last);
      }
    }
  }

  (int, int) _getRampAndColorIndex({required final ColorReference color})
  {
    int rampIndex = -1;
    int colorIndex = -1;
    for (int i = 0; i < colorRamps.length; i++)
    {
      for (int j = 0; j < colorRamps[i].references.length; j++)
      {
        if (colorRamps[i].references[j] == color)
        {
          rampIndex = i;
          colorIndex = j;
        }
      }
    }

    return (rampIndex, colorIndex);
  }
}
