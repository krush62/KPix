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
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/main/layer_widget.dart';

enum SelectionDirection
{
  undefined,
  left,
  right,
  top,
  bottom
}

class SelectionLine
{
  final SelectionDirection selectDir;
  CoordinateSetI startLoc;
  CoordinateSetI endLoc;

  SelectionLine({required this.selectDir, required this.startLoc, required this.endLoc});
}


class SelectionState with ChangeNotifier
{
  final AppState _appState = GetIt.I.get<AppState>();
  final BehaviorPreferenceContent _behaviorOptions = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
  final SelectionList selection = SelectionList();
  CoordinateColorMapNullable? clipboard;
  final RepaintNotifier repaintNotifier;
  final SelectOptions selectionOptions = GetIt.I.get<PreferenceManager>().toolOptions.selectOptions;
  final List<SelectionLine> selectionLines = [];

  SelectionState({required this.repaintNotifier})
  {
    _setHotkeys();
  }

  void _setHotkeys()
  {
    HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : copy();}, action: HotkeyAction.selectionCopy);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : copyMerged();}, action: HotkeyAction.selectionCopyMerged);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : cut();}, action: HotkeyAction.selectionCut);
    hotkeyManager.addListener(func: () {clipboard == null ? null : paste();}, action: HotkeyAction.selectionPaste);
    hotkeyManager.addListener(func: () {clipboard == null ? null : _appState.addNewDrawingLayer(select: _behaviorOptions.selectLayerAfterInsert.value, content: _appState.selectionState.clipboard);}, action: HotkeyAction.selectionPasteAsNewLayer);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : delete();}, action: HotkeyAction.selectionDelete);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : flipH();}, action: HotkeyAction.selectionFlipH);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : flipV();}, action: HotkeyAction.selectionFlipV);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : rotate();}, action: HotkeyAction.selectionRotate);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : inverse();}, action: HotkeyAction.selectionInvert);
    hotkeyManager.addListener(func: selectAll, action: HotkeyAction.selectionSelectAll);
    hotkeyManager.addListener(func: () {selection.isEmpty() ? null : deselect(addToHistoryStack: true);}, action: HotkeyAction.selectionDeselect);
    hotkeyManager.addListener(func: () {_moveSelection(offset: CoordinateSetI(x: 0, y: -1));}, action: HotkeyAction.selectionMoveUp);
    hotkeyManager.addListener(func: () {_moveSelection(offset: CoordinateSetI(x: 0, y: 1));}, action: HotkeyAction.selectionMoveDown);
    hotkeyManager.addListener(func: () {_moveSelection(offset: CoordinateSetI(x: -1, y: 0));}, action: HotkeyAction.selectionMoveLeft);
    hotkeyManager.addListener(func: () {_moveSelection(offset: CoordinateSetI(x: 1, y: 0));}, action: HotkeyAction.selectionMoveRight);

  }

  void notifyRepaint()
  {
    notifyListeners();
    repaintNotifier.repaint();
  }

  void newSelectionFromPolygon({required final Set<CoordinateSetI> points, final bool notify = true})
  {
    if (selectionOptions.mode.value == SelectionMode.replace)
    {
      deselect(notify: false, addToHistoryStack: false);
    }

    _addPixelsWithMode(coords: points, mode: selectionOptions.mode.value);
    createSelectionLines();

    if (notify)
    {
      notifyRepaint();
    }
  }

  void newSelectionFromShape({required final CoordinateSetI start, required final CoordinateSetI end, required final SelectShape selectShape, final bool notify = true, final bool addToHistoryStack = true})
  {
    if (selectionOptions.mode.value == SelectionMode.replace)
    {
      deselect(notify: false, addToHistoryStack: false);
    }

    if (selectionOptions.mode.value != SelectionMode.replace || end.x != start.x || end.y != start.y)
    {
      final Set<CoordinateSetI> coords = {};
      if (selectShape == SelectShape.rectangle)
      {
        for (int x = start.x; x <= end.x; x++)
        {
          for (int y = start.y; y <= end.y; y++)
          {
            coords.add(CoordinateSetI(x: x, y: y));
          }
        }
        _addPixelsWithMode(coords: coords, mode: selectionOptions.mode.value);
      }
      else if (selectShape == SelectShape.ellipse)
      {
        final Set<CoordinateSetI> coords = {};
        final double centerX = (start.x + end.x + 1) / 2.0;
        final double centerY = (start.y + end.y + 1) / 2.0;
        final double radiusX = (end.x - start.x + 1) / 2.0;
        final double radiusY = (end.y - start.y + 1) / 2.0;

        for (int x = start.x; x <= end.x; x++) {
          for (int y = start.y; y <= end.y; y++) {
            final double dx = (x + 0.5) - centerX;
            final double dy = (y + 0.5) - centerY;
            if ((dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1)
            {
              coords.add(CoordinateSetI(x: x, y: y));
            }
          }
        }
        _addPixelsWithMode(coords: coords, mode: selectionOptions.mode.value);
      }

      createSelectionLines();
    }
    else
    {
      //DISCARD SELECTION
    }
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "new selection");
    }

    if (notify)
    {
      notifyRepaint();
    }
  }

  void newSelectionFromWand({required final CoordinateSetI coord, required final SelectionMode mode, required final bool continuous, required final bool selectFromWholeRamp, final bool notify = true, final bool addToHistoryStack = true})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (selectionOptions.mode.value == SelectionMode.replace)
      {
        deselect(notify: false, addToHistoryStack: false);
      }

      if (!selection.contains(coord: coord) || !(mode == SelectionMode.add || mode == SelectionMode.replace))
      {
        final Set<CoordinateSetI> selectData = continuous ?
        _getFloodReferences(layer: drawingLayer, start: coord, selectFromWholeRamp: selectFromWholeRamp) :
        _getSameReferences(layer: drawingLayer, start: coord, selectFromWholeRamp: selectFromWholeRamp);
        _addPixelsWithMode(coords: selectData, mode: mode);
        createSelectionLines();
        if (notify)
        {
          notifyRepaint();
        }
      }
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "new selection");
      }
    }
  }

  void addNewSelectionWithContent({required final CoordinateColorMap colorMap})
  {
    deselect(notify: false, addToHistoryStack: false);
    selection.addDirectlyAll(list: colorMap);
    createSelectionLines();
  }

  Set<CoordinateSetI> _getFloodReferences({
    required final DrawingLayerState layer,
    required final CoordinateSetI start,
    required final bool selectFromWholeRamp})
  {
    final int numRows = _appState.canvasSize.y;
    final int numCols = _appState.canvasSize.x;
    final ColorReference? targetValue = (_appState.currentLayer == layer && selection.contains(coord: start)) ? selection.getColorReference(coord: start) : layer.getDataEntry(coord: start);
    final Set<CoordinateSetI> result = {};
    final Set<CoordinateSetI> visited = {};
    final StackCol<CoordinateSetI> pointStack = StackCol<CoordinateSetI>();

    pointStack.push(CoordinateSetI(x: start.x, y: start.y));

    while (pointStack.isNotEmpty)
    {
      final CoordinateSetI curCoord = pointStack.pop();
      if (curCoord.x >= 0 && curCoord.y < numRows && curCoord.y >= 0 && curCoord.x < numCols)
      {
        final ColorReference? refAtPos = (_appState.currentLayer == layer && selection.contains(coord: curCoord)) ? selection.getColorReference(coord: curCoord) : layer.getDataEntry(coord: curCoord);
        if (!visited.contains(curCoord) && (refAtPos == targetValue || (refAtPos != null && targetValue != null && selectFromWholeRamp && refAtPos.ramp == targetValue.ramp)))
        {
          result.add(curCoord);
          if (curCoord.x + 1 < numCols)
          {
            pointStack.push(CoordinateSetI(x: curCoord.x + 1, y: curCoord.y));
          }
          if (curCoord.x > 0)
          {
            pointStack.push(CoordinateSetI(x: curCoord.x - 1, y: curCoord.y));
          }
          if (curCoord.y + 1 < numRows)
          {
            pointStack.push(CoordinateSetI(x: curCoord.x, y: curCoord.y + 1));
          }
          if (curCoord.y > 0)
          {
            pointStack.push(CoordinateSetI(x: curCoord.x, y: curCoord.y - 1));
          }
        }
        visited.add(curCoord);
      }
    }

    return result;
  }

  Set<CoordinateSetI> _getSameReferences({
    required final DrawingLayerState layer,
    required final CoordinateSetI start,
    required final bool selectFromWholeRamp})
  {
    final Set<CoordinateSetI> result = {};
    final ColorReference? targetValue = (_appState.currentLayer == layer && selection.contains(coord: start)) ? selection.getColorReference(coord: start) : layer.getDataEntry(coord: start);
    for (int x = 0; x < _appState.canvasSize.x; x++)
    {
      for (int y = 0; y < _appState.canvasSize.y; y++)
      {
        final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
        final ColorReference? refAtPos = (_appState.currentLayer == layer && selection.contains(coord: curCoord)) ? selection.getColorReference(coord: curCoord) : layer.getDataEntry(coord: curCoord);
        if (refAtPos == targetValue || (selectFromWholeRamp && refAtPos != null && targetValue != null && refAtPos.ramp == targetValue.ramp))
        {
          result.add(curCoord);
        }
      }
    }
    return result;
  }

  void _addPixelsWithMode({required Set<CoordinateSetI> coords, required SelectionMode mode})
  {
    final Set<CoordinateSetI> addCoords = {};
    final Set<CoordinateSetI> removeCoords = {};

    for (final CoordinateSetI coord in coords)
    {
      switch (selectionOptions.mode.value) {
        case SelectionMode.replace:
        case SelectionMode.add:
          if (!selection.contains(coord: coord)) {
            addCoords.add(coord);
          }
          break;
        case SelectionMode.intersect:
          if (!selection.contains(coord: coord)) {
            addCoords.add(coord);
          }
          else
          {
            removeCoords.add(coord);
          }
          break;
        case SelectionMode.subtract:
          if (selection.contains(coord: coord)) {
            removeCoords.add(coord);
          }
          break;
      }
    }
    if (addCoords.isNotEmpty)
    {
      selection.addAll(coords: addCoords);
    }
    if (removeCoords.isNotEmpty)
    {
      selection.removeAll(coords: removeCoords);
    }
  }

  void createSelectionLines()
  {
    selectionLines.clear();
    final Iterable<CoordinateSetI> selectedCoordinates = selection.getCoordinates();
    for (final CoordinateSetI coord in selectedCoordinates)
    {
      if (coord.x == 0 || !selection.contains(coord: CoordinateSetI(x: coord.x - 1, y: coord.y)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.left);
        bool inserted = false;
        for (final SelectionLine selLine in leftLines)
        {
          if (selLine.startLoc.x == coord.x && selLine.startLoc.y == coord.y + 1)
          {
            selLine.startLoc = coord;
            inserted = true;
          }
          else if (selLine.endLoc.x == coord.x && selLine.endLoc.y == coord.y - 1)
          {
            selLine.endLoc = coord;
            inserted = true;
          }
        }
        if (!inserted)
        {
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.left, startLoc: coord, endLoc: coord));
        }
      }
      if (coord.x == _appState.canvasSize.x - 1 || !selection.contains(coord: CoordinateSetI(x: coord.x + 1, y: coord.y)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.right);
        bool inserted = false;
        for (final SelectionLine selLine in leftLines)
        {
          if (selLine.startLoc.x == coord.x && selLine.startLoc.y == coord.y + 1)
          {
            selLine.startLoc = coord;
            inserted = true;
          }
          else if (selLine.endLoc.x == coord.x && selLine.endLoc.y == coord.y - 1)
          {
            selLine.endLoc = coord;
            inserted = true;
          }
        }
        if (!inserted)
        {
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.right, startLoc: coord, endLoc: coord));
        }
      }
      if (coord.y == 0 || !selection.contains(coord: CoordinateSetI(x: coord.x, y: coord.y - 1)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.top);
        bool inserted = false;
        for (final SelectionLine selLine in leftLines)
        {
          if (selLine.startLoc.x == coord.x + 1 && selLine.startLoc.y == coord.y)
          {
            selLine.startLoc = coord;
            inserted = true;
          }
          else if (selLine.endLoc.x == coord.x - 1 && selLine.endLoc.y == coord.y)
          {
            selLine.endLoc = coord;
            inserted = true;
          }
        }
        if (!inserted)
        {
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.top, startLoc: coord, endLoc: coord));
        }
      }
      if (coord.y == _appState.canvasSize.y - 1 || !selection.contains(coord: CoordinateSetI(x: coord.x, y: coord.y + 1)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.bottom);
        bool inserted = false;
        for (final SelectionLine selLine in leftLines)
        {
          if (selLine.startLoc.x == coord.x + 1 && selLine.startLoc.y == coord.y)
          {
            selLine.startLoc = coord;
            inserted = true;
          }
          else if (selLine.endLoc.x == coord.x - 1 && selLine.endLoc.y == coord.y)
          {
            selLine.endLoc = coord;
            inserted = true;
          }
        }
        if (!inserted)
        {
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.bottom, startLoc: coord, endLoc: coord));
        }
      }
    }
  }

  void inverse({final bool notify = true, final bool addToHistoryStack = true})
  {
    Set<CoordinateSetI> addSet = {};
    Set<CoordinateSetI> removeSet = {};
    for (int x = 0; x < _appState.canvasSize.x; x++)
    {
      for (int y = 0; y < _appState.canvasSize.y; y++)
      {
        final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (selection.contains(coord: coord))
        {
          removeSet.add(coord);
        }
        else
        {
          addSet.add(coord);
        }
      }
    }

    selection.removeAll(coords: removeSet);
    selection.addAll(coords: addSet);
    createSelectionLines();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "inverse selection");
    }
    if (notify)
    {
      notifyRepaint();
    }
  }


  void deselect({final bool notify = true, required final bool addToHistoryStack})
  {
    selection.clear();
    createSelectionLines();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "deselect");
    }
    if (notify)
    {
      notifyRepaint();
    }
  }

  void selectAll({final bool notify = true, final bool addToHistoryStack = true})
  {
    Set<CoordinateSetI> addSet = {};
    for (int x = 0; x < _appState.canvasSize.x; x++)
    {
      for (int y = 0; y < _appState.canvasSize.y; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (!selection.contains(coord: coord))
        {
          addSet.add(coord);
        }
      }
    }
    selection.addAll(coords: addSet);
    createSelectionLines();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "select all");
    }
    if (notify)
    {
      notifyRepaint();
    }
  }

  void delete({final bool notify = true, final bool keepSelection = true, final bool addToHistoryStack = true})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (drawingLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        _appState.showMessage(text: "Cannot delete from hidden layer!");
      }
      else if (drawingLayer.lockState.value == LayerLockState.locked)
      {
        _appState.showMessage(text: "Cannot delete from locked layer!");
      }
      else
      {
        selection.delete(keepSelection: keepSelection);
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "delete selection");
        }
        if (!keepSelection)
        {
          createSelectionLines();
        }
      }
      if (notify)
      {
        notifyRepaint();
        drawingLayer.doManualRaster = true;
      }
    }
  }

  void cut({final bool notify = true, final bool keepSelection = false, final bool addToHistoryStack = true})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (drawingLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        _appState.showMessage(text: "Cannot cut from hidden layer!");
      }
      else if (drawingLayer.lockState.value == LayerLockState.locked)
      {
        _appState.showMessage(text: "Cannot cut from locked layer!");
      }
      else if (copy(notify: false, keepSelection: true))
      {
        delete(keepSelection: true, notify: false);
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "cut selection");
        }
        if (notify)
        {
          notifyRepaint();
          drawingLayer.doManualRaster = true;
        }
      }
    }
  }

  bool copy({final bool notify = true, final keepSelection = false})
  {
    bool hasCopied = false;
    if (selection.hasValues())
    {
      clipboard = HashMap();
      final Iterable<CoordinateSetI> coords = selection.getCoordinates();
      for (final CoordinateSetI coord in coords)
      {
        clipboard![coord] = selection.getColorReference(coord: coord);
      }
      if (!keepSelection)
      {
        deselect(notify: false, addToHistoryStack: false);
      }
      hasCopied = true;
      if (notify)
      {
        notifyRepaint();
      }
    }
    else
    {
      _appState.showMessage(text: "Nothing to copy!");
    }
    return hasCopied;
  }

  void copyMerged({final bool notify = true, final keepSelection = false})
  {
    final CoordinateColorMapNullable tempCB = HashMap();
    final Iterable<LayerState> visibleLayers = _appState.layers.where((x) => x.visibilityState.value == LayerVisibilityState.visible);
    final Iterable<CoordinateSetI> coords = selection.getCoordinates();
    bool hasValues = false;

    for (final CoordinateSetI coord in coords)
    {
      bool pixelFound = false;
      for (final LayerState layer in visibleLayers)
      {
        if (layer.runtimeType == DrawingLayerState)
        {
          final DrawingLayerState drawingLayer = layer as DrawingLayerState;
          ColorReference? colRef = drawingLayer.getDataEntry(coord: coord);
          if (drawingLayer == _appState.currentLayer)
          {
            final ColorReference? selColRef = selection.getColorReference(coord: coord);
            if (selColRef != null)
            {
              colRef = selColRef;
            }
          }
          if (colRef != null)
          {
            hasValues = true;
            tempCB[coord] = colRef;
            pixelFound = true;
            break;
          }
        }
      }
      if (!pixelFound)
      {
        tempCB[coord] = null;
      }
    }

    if (hasValues)
    {
      clipboard = tempCB;
      if (!keepSelection)
      {
        deselect(notify: false, addToHistoryStack: false);
      }

      if (notify)
      {
        notifyRepaint();
      }
    }
    else
    {
      _appState.showMessage(text: "Nothing to copy!");
    }
  }

  void paste({final bool notify = true, final bool addToHistoryStack = true})
  {
    if (clipboard != null && _appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState) //should always be the case
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (drawingLayer.lockState.value == LayerLockState.locked)
      {
        _appState.showMessage(text: "Cannot paste to a locked layer!");
      }
      else if (drawingLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        _appState.showMessage(text: "Cannot paste to a hidden layer!");
      }
      else
      {
        deselect(notify: false, addToHistoryStack: false);
        final CoordinateColorMap addCoords = HashMap();
        for (final CoordinateSetI key in clipboard!.keys)
        {
          if (clipboard![key] != null)
          {
            addCoords[key] = clipboard![key]!;
          }
        }
        selection.addDirectlyAll(list: addCoords);
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "paste");
        }

        if (notify)
        {
          notifyRepaint();
          drawingLayer.doManualRaster = true;
        }
      }
    }
  }

  void flipH({final bool notify = true, final bool addToHistoryStack = true})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (drawingLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        _appState.showMessage(text: "Cannot transform on a hidden layer!");
      }
      else if (drawingLayer.lockState.value == LayerLockState.locked)
      {
        _appState.showMessage(text: "Cannot transform on a locked layer!");
      }
      else
      {
        selection.flipH();
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "flip selection horizontally");
        }

        if (notify)
        {
          notifyRepaint();
          drawingLayer.doManualRaster = true;
        }
      }
    }
  }

  void flipV({final bool notify = true, final bool addToHistoryStack = true})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (drawingLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        _appState.showMessage(text: "Cannot transform on a hidden layer!");
      }
      else if (drawingLayer.lockState.value == LayerLockState.locked)
      {
        _appState.showMessage(text: "Cannot transform on a locked layer!");
      }
      else
      {
        selection.flipV();
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "flip selection vertically");
        }

        if (notify)
        {
          notifyRepaint();
          drawingLayer.doManualRaster = true;
        }
      }
    }
  }

  void rotate({final bool notify = true, final bool addToHistoryStack = true})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      if (drawingLayer.visibilityState.value == LayerVisibilityState.hidden)
      {
        _appState.showMessage(text: "Cannot transform on a hidden layer!");
      }
      else if (drawingLayer.lockState.value == LayerLockState.locked)
      {
        _appState.showMessage(text: "Cannot transform on a locked layer!");
      }
      else
      {
        selection.rotate90cw();
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "flip selection vertically");
        }

        if (notify)
        {
          notifyRepaint();
          drawingLayer.doManualRaster = true;
        }
      }
    }
  }

  void _moveSelection({required final CoordinateSetI offset})
  {
    setOffset(offset: offset);
    finishMovement();
  }

  void setOffset({required final CoordinateSetI offset})
  {
    selection.shiftSelection(offset: offset);
    createSelectionLines();
  }

  void finishMovement()
  {
    selection.resetLastOffset();
    GetIt.I.get<HistoryManager>().addState(appState: _appState, description: "selection moved");
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      drawingLayer.doManualRaster = true;
    }
  }
}

class SelectionList
{
  CoordinateColorMapNullable _content = HashMap();
  final AppState _appState = GetIt.I.get<AppState>();
  CoordinateColorMapNullable get selectedPixels
  {
    return _content;
  }

  final CoordinateSetI _lastOffset = CoordinateSetI(x: 0, y: 0);

  void changeLayer({required final LayerState? oldLayer, required final LayerState newLayer})
  {
    final CoordinateColorMapNullable refsOld = HashMap();
    final CoordinateColorMapNullable refsNew = HashMap();
    for (final CoordinateSetI key in _content.keys)
    {
      final ColorReference? curVal = _content[key];
      if (curVal != null)
      {
        //oldLayer.setData(key, curVal);
        refsOld[key] = curVal;
      }
      if (newLayer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState newDrawingLayer = newLayer as DrawingLayerState;
        if (newDrawingLayer.lockState.value != LayerLockState.locked)
        {
          _content[key] = newDrawingLayer.getDataEntry(coord: key);
          //newLayer.setData(key, null);
          refsNew[key] = null;
        }
      }
    }
    if (oldLayer != null && oldLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState oldDrawingLayer = oldLayer as DrawingLayerState;
      oldDrawingLayer.setDataAll(list: refsOld);
    }

    if (newLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState newDrawingLayer = newLayer as DrawingLayerState;
      newDrawingLayer.setDataAll(list: refsNew);
    }
  }

  void addAll({required final Set<CoordinateSetI> coords})
  {
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      for (final CoordinateSetI coord in coords)
      {
        _content[coord] = drawingLayer.getDataEntry(coord: coord);
      }
      drawingLayer.removeDataAll(removeCoordList: coords);

    }
  }

  void addEmpty({required final CoordinateSetI coord})
  {
    _content[coord] = null;
  }

  void addDirectly({required final CoordinateSetI coord, required final ColorReference? colRef})
  {
    _content[coord] = colRef;
  }

  void addDirectlyAll({required final CoordinateColorMapNullable list})
  {
    _content.addAll(list);

  }

  void removeAll({required final Set<CoordinateSetI> coords})
  {
    final CoordinateColorMapNullable refs = HashMap();
    for (final CoordinateSetI coord in coords)
    {
      if (coord.x >= 0 && coord.y >= 0 && coord.x < _appState.canvasSize.x && coord.y < _appState.canvasSize.y)
      {
        if (_content[coord] != null)
        {
          refs[coord] = _content[coord];
        }
        _content.remove(coord);
      }
    }
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      drawingLayer.setDataAll(list: refs);
    }

  }

  void clear()
  {
    final CoordinateColorMapNullable refs = HashMap();
    for (final CoordinateColorNullable entry in _content.entries)
    {
      if (entry.value != null && entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < _appState.canvasSize.x && entry.key.y < _appState.canvasSize.y)
      {
        refs[entry.key] = entry.value;
      }
    }
    if (_appState.currentLayer != null && _appState.currentLayer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState drawingLayer = _appState.currentLayer as DrawingLayerState;
      drawingLayer.setDataAll(list: refs);
    }
    _content.clear();
  }

  void deleteDirectly({required final CoordinateSetI coord})
  {
    if (_content.keys.contains(coord) && _content[coord] != null)
    {
      _content[coord] = null;
    }
  }

  void delete({required bool keepSelection})
  {
    if (keepSelection)
    {
      for (final CoordinateSetI entry in _content.keys)
      {
          _content[entry] = null;
      }
    }
    else
    {
      _content.clear();
    }
  }

  void flipH()
  {
    CoordinateSetI minXcoord = _content.keys.reduce((a, b) => a.x < b.x ? a : b);
    CoordinateSetI maxXcoord = _content.keys.reduce((a, b) => a.x > b.x ? a : b);

    final CoordinateColorMapNullable newContent = HashMap();
    for (final CoordinateColorNullable entry in _content.entries)
    {
      newContent[CoordinateSetI(x: maxXcoord.x - entry.key.x + minXcoord.x , y: entry.key.y)] = entry.value;
    }
    _content = newContent;
  }

  void flipV()
  {
    CoordinateSetI minYcoord = _content.keys.reduce((a, b) => a.y < b.y ? a : b);
    CoordinateSetI maxYcoord = _content.keys.reduce((a, b) => a.y > b.y ? a : b);

    final CoordinateColorMapNullable newContent = HashMap();
    for (final CoordinateColorNullable entry in _content.entries)
    {
      newContent[CoordinateSetI(x: entry.key.x, y: maxYcoord.y - entry.key.y + minYcoord.y)] = entry.value;
    }
    _content = newContent;
  }

  void rotate90cw()
  {
    CoordinateSetI minCoords = _appState.canvasSize;
    CoordinateSetI maxCoords = CoordinateSetI(x: 0, y: 0);
    for (final CoordinateSetI coord in _content.keys)
    {
      minCoords.x = min(coord.x, minCoords.x);
      minCoords.y = min(coord.y, minCoords.y);
      maxCoords.x = max(coord.x, maxCoords.x);
      maxCoords.y = max(coord.y, maxCoords.y);
    }

    final CoordinateSetI centerCoord = CoordinateSetI(x: (minCoords.x + maxCoords.x) ~/ 2, y: (minCoords.y + maxCoords.y) ~/ 2);
    final CoordinateColorMapNullable newContent = HashMap();
    for (final CoordinateColorNullable entry in _content.entries)
    {
      newContent[CoordinateSetI(x: centerCoord.y - entry.key.y + centerCoord.x, y: entry.key.x - centerCoord.x + centerCoord.y)] = entry.value;
    }
    _content = newContent;
  }

  bool contains({required final CoordinateSetI coord})
  {
    return _content.containsKey(coord);
  }

  bool isEmpty()
  {
    return _content.isEmpty;
  }

  Iterable<CoordinateSetI> getCoordinates()
  {
    return _content.keys;
  }


  ColorReference? getColorReference({required final CoordinateSetI coord})
  {
    return contains(coord: coord) ? _content[coord] : null;
  }

  void shiftSelection({required final CoordinateSetI offset})
  {
    if (offset != _lastOffset)
    {
      final CoordinateColorMapNullable newContent = HashMap();
      for (final CoordinateColorNullable entry in _content.entries)
      {
        newContent[CoordinateSetI(x: entry.key.x + (offset.x - _lastOffset.x), y: entry.key.y + (offset.y - _lastOffset.y))] = entry.value;
      }
      _content = newContent;
      _lastOffset.x = offset.x;
      _lastOffset.y = offset.y;
    }
  }

  void resetLastOffset()
  {
    _lastOffset.x = 0;
    _lastOffset.y = 0;
  }

  bool hasValues()
  {
    bool has = false;
    for (final ColorReference? colRef in _content.values)
    {
      if (colRef != null)
      {
        has = true;
        break;
      }
    }
    return has;
  }

  (CoordinateSetI?, CoordinateSetI?) getBoundingBox(
      {required final CoordinateSetI canvasSize})
  {
    CoordinateSetI? topLeft, bottomRight;
    int minX = canvasSize.x;
    int maxX = -1;
    int minY = canvasSize.y;
    int maxY = -1;

    final Iterable<CoordinateSetI> allCoords = _content.keys;
    for (final CoordinateSetI coord in allCoords)
    {
      minX = min(minX, coord.x);
      maxX = max(maxX, coord.x);
      minY = min(minY, coord.y);
      maxY = max(maxY, coord.y);
    }

    if (minX <= maxX && minY <= maxY)
    {
       topLeft = CoordinateSetI(x: minX, y: minY);
       bottomRight = CoordinateSetI(x: maxX, y: maxY);
    }
    return (topLeft, bottomRight);
  }

}

