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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/clipboard_content.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/selection_buffer.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:logger/logger.dart';

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
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();
  final BehaviorPreferenceContent _behaviorOptions = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
  final SelectionList selection = SelectionList();
  ClipboardContent? _clipboard;
  final RepaintNotifier repaintNotifier;
  final SelectOptions selectionOptions = GetIt.I.get<ToolOptions>().selectOptions;
  final List<SelectionLine> selectionLines = <SelectionLine>[];

  SelectionState({required this.repaintNotifier})
  {
    _setHotkeys();
  }

  void _setHotkeys()
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) copy();}, action: HotkeyAction.selectionCopy);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) copyMerged();}, action: HotkeyAction.selectionCopyMerged);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) cut();}, action: HotkeyAction.selectionCut);
    hotkeyManager.addListener(func: () {if (_clipboard != null) paste();}, action: HotkeyAction.selectionPaste);
    hotkeyManager.addListener(func: () {if (_clipboard != null) pasteAsNewLayer();}, action: HotkeyAction.selectionPasteAsNewLayer);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) delete();}, action: HotkeyAction.selectionDelete);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) flipH();}, action: HotkeyAction.selectionFlipH);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) flipV();}, action: HotkeyAction.selectionFlipV);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) rotate();}, action: HotkeyAction.selectionRotate);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) inverse();}, action: HotkeyAction.selectionInvert);
    hotkeyManager.addListener(func: selectAll, action: HotkeyAction.selectionSelectAll);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) deselect(addToHistoryStack: true);}, action: HotkeyAction.selectionDeselect);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) _moveSelection(offset: CoordinateSetI(x: 0, y: -1), withContent: true);}, action: HotkeyAction.selectionMoveUp);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) _moveSelection(offset: CoordinateSetI(x: 0, y: 1), withContent: true);}, action: HotkeyAction.selectionMoveDown);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) _moveSelection(offset: CoordinateSetI(x: -1, y: 0), withContent: true);}, action: HotkeyAction.selectionMoveLeft);
    hotkeyManager.addListener(func: () {if (!selection.isEmpty) _moveSelection(offset: CoordinateSetI(x: 1, y: 0), withContent: true);}, action: HotkeyAction.selectionMoveRight);

  }

  void notifyRepaint()
  {
    notifyListeners();
    repaintNotifier.repaint();
  }

  void newSelectionFromPolygon({required final Set<CoordinateSetI> points, final bool notify = true, final bool addToHistoryStack = true})
  {
    if (selectionOptions.mode.value == SelectMode.replace)
    {
      deselect(notify: false, addToHistoryStack: false);
    }

    final Set<CoordinateSetI> canvasPoints = points.where((final CoordinateSetI p) => p.x >= 0 && p.y >= 0 && p.x < _canvasState.canvasSize.x && p.y < _canvasState.canvasSize.y).toSet();
    _addPixelsWithMode(coords: canvasPoints, mode: selectionOptions.mode.value);
    createSelectionLines();

    //lifts pixels out of the layer like every other way of selecting, so it has
    //to be an undo step like them too
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionNew, originLayer: _documentState.timeline.getCurrentLayer());
    }

    if (notify)
    {
      notifyRepaint();
    }
  }

 void newSelectionFromShape({required final CoordinateSetI start, required final CoordinateSetI end, required final SelectShape selectShape, final bool notify = true, final bool addToHistoryStack = true})
  {
    if (selectionOptions.mode.value == SelectMode.replace)
    {
      deselect(notify: false, addToHistoryStack: false);
    }
    if (selectionOptions.mode.value != SelectMode.replace || end.x != start.x || end.y != start.y)
    {
      final Set<CoordinateSetI> coords = <CoordinateSetI>{};
      if (selectShape == SelectShape.rectangle)
      {
        for (int x = start.x; x <= end.x; x++)
        {
          for (int y = start.y; y <= end.y; y++)
          {
            if (x >= 0 && x < _canvasState.canvasSize.x && y >= 0 && y < _canvasState.canvasSize.y)
            {
              coords.add(CoordinateSetI(x: x, y: y));
            }
          }
        }
        _addPixelsWithMode(coords: coords, mode: selectionOptions.mode.value);
      }
      else if (selectShape == SelectShape.ellipse)
      {
        final Set<CoordinateSetI> coords = <CoordinateSetI>{};
        final double centerX = (start.x + end.x + 1) / 2.0;
        final double centerY = (start.y + end.y + 1) / 2.0;
        final double radiusX = (end.x - start.x + 1) / 2.0;
        final double radiusY = (end.y - start.y + 1) / 2.0;

        for (int x = start.x; x <= end.x; x++)
        {
          for (int y = start.y; y <= end.y; y++)
          {
            if (x >= 0 && x < _canvasState.canvasSize.x && y >= 0 && y < _canvasState.canvasSize.y)
            {
              final double dx = (x + 0.5) - centerX;
              final double dy = (y + 0.5) - centerY;
              if ((dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1)
              {
                coords.add(CoordinateSetI(x: x, y: y));
              }
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
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionNew, originLayer: _documentState.timeline.getCurrentLayer());
    }

    if (notify)
    {
      notifyRepaint();
    }
  }

  void newSelectionFromWand({required final CoordinateSetI coord, required final SelectMode mode, required final bool continuous, required final bool selectFromWholeRamp, final bool notify = true, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      if (selectionOptions.mode.value == SelectMode.replace)
      {
        deselect(notify: false, addToHistoryStack: false);
      }

      if (!selection.contains(coord: coord) || !(mode == SelectMode.add || mode == SelectMode.replace))
      {
        final Set<CoordinateSetI> selectData = continuous ?
        _getFloodReferences(layer: layer, start: coord, selectFromWholeRamp: selectFromWholeRamp) :
        _getSameReferences(layer: layer, start: coord, selectFromWholeRamp: selectFromWholeRamp);
        _addPixelsWithMode(coords: selectData, mode: mode);
        createSelectionLines();
        if (notify)
        {
          notifyRepaint();
        }
      }
      if (addToHistoryStack)
      {
        GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionNew, originLayer: _documentState.timeline.getCurrentLayer());
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
    required final bool selectFromWholeRamp,})
  {
    final int numRows = _canvasState.canvasSize.y;
    final int numCols = _canvasState.canvasSize.x;
    final ColorReference? targetValue = (_documentState.timeline.getCurrentLayer() == layer && selection.contains(coord: start)) ? selection.getColorReference(coord: start) : layer.getDataEntry(coord: start);
    final Set<CoordinateSetI> result = <CoordinateSetI>{};
    final Uint8List visited = Uint8List(numCols * numRows);
    final StackCol<CoordinateSetI> pointStack = StackCol<CoordinateSetI>();

    pointStack.push(CoordinateSetI(x: start.x, y: start.y));

    while (pointStack.isNotEmpty)
    {
      final CoordinateSetI curCoord = pointStack.pop();
      if (curCoord.x >= 0 && curCoord.y < numRows && curCoord.y >= 0 && curCoord.x < numCols)
      {
        final ColorReference? refAtPos = (_documentState.timeline.getCurrentLayer() == layer && selection.contains(coord: curCoord)) ? selection.getColorReference(coord: curCoord) : layer.getDataEntry(coord: curCoord);
        if (visited[curCoord.y * numCols + curCoord.x] == 0 && (refAtPos == targetValue || (refAtPos != null && targetValue != null && selectFromWholeRamp && refAtPos.ramp == targetValue.ramp)))
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
        visited[curCoord.y * numCols + curCoord.x] = 1;
      }
    }

    return result;
  }

  Set<CoordinateSetI> _getSameReferences({
    required final DrawingLayerState layer,
    required final CoordinateSetI start,
    required final bool selectFromWholeRamp,})
  {
    final Set<CoordinateSetI> result = <CoordinateSetI>{};
    final ColorReference? targetValue = (_documentState.timeline.getCurrentLayer() == layer && selection.contains(coord: start)) ? selection.getColorReference(coord: start) : layer.getDataEntry(coord: start);
    for (int x = 0; x < _canvasState.canvasSize.x; x++)
    {
      for (int y = 0; y < _canvasState.canvasSize.y; y++)
      {
        final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
        final ColorReference? refAtPos = (_documentState.timeline.getCurrentLayer() == layer && selection.contains(coord: curCoord)) ? selection.getColorReference(coord: curCoord) : layer.getDataEntry(coord: curCoord);
        if (refAtPos == targetValue || (selectFromWholeRamp && refAtPos != null && targetValue != null && refAtPos.ramp == targetValue.ramp))
        {
          result.add(curCoord);
        }
      }
    }
    return result;
  }

  void _addPixelsWithMode({required final Set<CoordinateSetI> coords, required final SelectMode mode})
  {
    final Set<CoordinateSetI> addCoords = <CoordinateSetI>{};
    final Set<CoordinateSetI> removeCoords = <CoordinateSetI>{};

    for (final CoordinateSetI coord in coords)
    {
      switch (mode)
      {
        case SelectMode.replace:
        case SelectMode.add:
          if (!selection.contains(coord: coord)) {
            addCoords.add(coord);
          }
          //break;
        case SelectMode.intersect:
          if (!selection.contains(coord: coord)) {
            addCoords.add(coord);
          }
          else
          {
            removeCoords.add(coord);
          }
          //break;
        case SelectMode.subtract:
          if (selection.contains(coord: coord)) {
            removeCoords.add(coord);
          }
          //break;
      }
    }
    if (addCoords.isNotEmpty)
    {
      selection.transferAll(coords: addCoords);
    }
    if (removeCoords.isNotEmpty)
    {
      selection.removeAll(coords: removeCoords);
    }
  }

  void createSelectionLines()
  {
    selectionLines.clear();
    final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selection.getBoundingBox();
    if (topLeft == null || bottomRight == null)
    {
      return;
    }
    //one pass per direction, so that the lines come out grouped by direction and
    //in order within a group, as the merged lines did before
    for (final SelectionDirection direction in <SelectionDirection>[SelectionDirection.left, SelectionDirection.right, SelectionDirection.top, SelectionDirection.bottom])
    {
      _addEdgeLines(direction: direction, topLeft: topLeft, bottomRight: bottomRight);
    }
  }

  /// Adds a line for every run of selected pixels whose neighbour towards
  /// [direction] is not selected. Left and right edges run down a column, top
  /// and bottom edges along a row.
  void _addEdgeLines({required final SelectionDirection direction, required final CoordinateSetI topLeft, required final CoordinateSetI bottomRight})
  {
    final bool vertical = direction == SelectionDirection.left || direction == SelectionDirection.right;
    final int neighbourX = direction == SelectionDirection.left ? -1 : (direction == SelectionDirection.right ? 1 : 0);
    final int neighbourY = direction == SelectionDirection.top ? -1 : (direction == SelectionDirection.bottom ? 1 : 0);
    final int firstLine = vertical ? topLeft.x : topLeft.y;
    final int lastLine = vertical ? bottomRight.x : bottomRight.y;
    final int runStart = vertical ? topLeft.y : topLeft.x;
    final int runEnd = vertical ? bottomRight.y : bottomRight.x;

    for (int line = firstLine; line <= lastLine; line++)
    {
      int? start;
      //one past the end, so that a run reaching the edge of the box is closed
      for (int position = runStart; position <= runEnd + 1; position++)
      {
        final int x = vertical ? line : position;
        final int y = vertical ? position : line;
        final bool isEdge = position <= runEnd &&
            selection.isSelectedAt(x: x, y: y) &&
            !selection.isSelectedAt(x: x + neighbourX, y: y + neighbourY);
        if (isEdge)
        {
          start ??= position;
        }
        else if (start != null)
        {
          selectionLines.add(SelectionLine(
            selectDir: direction,
            startLoc: vertical ? CoordinateSetI(x: line, y: start) : CoordinateSetI(x: start, y: line),
            endLoc: vertical ? CoordinateSetI(x: line, y: position - 1) : CoordinateSetI(x: position - 1, y: line),
          ),);
          start = null;
        }
      }
    }
  }

  void inverse({final bool notify = true, final bool addToHistoryStack = true})
  {
    final Set<CoordinateSetI> addSet = <CoordinateSetI>{};
    final Set<CoordinateSetI> removeSet = <CoordinateSetI>{};
    for (int x = 0; x < _canvasState.canvasSize.x; x++)
    {
      for (int y = 0; y < _canvasState.canvasSize.y; y++)
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
    selection.transferAll(coords: addSet);
    createSelectionLines();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionInverse, originLayer: _documentState.timeline.getCurrentLayer());
    }
    if (notify)
    {
      notifyRepaint();
    }
  }

  void deselectWithHistory()
  {
    deselect(addToHistoryStack: true);
  }


  void deselect({final bool notify = true, required final bool addToHistoryStack})
  {
    selection.clear();
    createSelectionLines();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionDeselect, originLayer: _documentState.timeline.getCurrentLayer());
    }
    if (notify)
    {
      notifyRepaint();
    }
  }

  void selectAll({final bool notify = true, final bool addToHistoryStack = true})
  {
    final Set<CoordinateSetI> addSet = <CoordinateSetI>{};
    for (int x = 0; x < _canvasState.canvasSize.x; x++)
    {
      for (int y = 0; y < _canvasState.canvasSize.y; y++)
      {
        final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (!selection.contains(coord: coord))
        {
          addSet.add(coord);
        }
      }
    }
    selection.transferAll(coords: addSet);
    createSelectionLines();
    if (addToHistoryStack)
    {
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionSelectAll, originLayer: _documentState.timeline.getCurrentLayer());
    }
    if (notify)
    {
      notifyRepaint();
    }
  }

  void delete({final bool notify = true, final bool keepSelection = true, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      if (layer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot delete from hidden layer!");
      }
      else if (layer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot delete from locked layer!");
      }
      else
      {
        selection.delete(keepSelection: keepSelection);
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionDelete, originLayer: _documentState.timeline.getCurrentLayer());
        }
        if (!keepSelection)
        {
          createSelectionLines();
        }
      }
      if (notify)
      {
        notifyRepaint();
        layer.doManualRaster = true;
      }
    }
  }

  void cut({final bool notify = true, final bool keepSelection = false, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      if (layer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot cut from hidden layer!");
      }
      else if (layer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot cut from locked layer!");
      }
      else if (copy(notify: false, keepSelection: true))
      {
        delete(notify: false);
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionCut, originLayer: _documentState.timeline.getCurrentLayer());
        }
        if (notify)
        {
          notifyRepaint();
          layer.doManualRaster = true;
        }
      }
    }
  }

  bool copy({final bool notify = true, final bool keepSelection = false})
  {
    bool hasCopied = false;
    if (selection.hasValues())
    {
      //the copy shares its tiles with the selection until either side changes
      _clipboard = ClipboardContent(pixels: selection.snapshot()!, codec: selection.codec);
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
      showMessage(text: "Nothing to copy!");
    }
    return hasCopied;
  }

  void copyMerged({final bool notify = true, final bool keepSelection = false})
  {
    final Frame? frame = _documentState.timeline.selectedFrame;
    if (frame != null)
    {
      final Iterable<LayerState> visibleLayers = frame.layerList.getVisibleLayers();
      final SelectionBuffer merged = SelectionBuffer();
      final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selection.getBoundingBox();
      if (topLeft != null && bottomRight != null)
      {
        merged.cover(left: topLeft.x, top: topLeft.y, right: bottomRight.x, bottom: bottomRight.y);
      }
      //the merged pixels come from several layers, so they get their own codec
      PaletteCodec codec = PaletteCodec(ramps: const <KPalRampData>[]);
      bool hasValues = false;

      for (final CoordinateSetI coord in selection.getCoordinates())
      {
        ColorReference? mergedColor;
        for (final LayerState layer in visibleLayers)
        {
          if (layer is DrawingLayerState)
          {
            ColorReference? colRef = layer.getDataEntry(coord: coord);
            if (layer == _documentState.timeline.getCurrentLayer())
            {
              final ColorReference? selColRef = selection.getColorReference(coord: coord);
              if (selColRef != null)
              {
                colRef = selColRef;
              }
            }
            if (colRef != null)
            {
              mergedColor = colRef;
              break;
            }
          }
        }
        int code = PaletteCodec.transparent;
        if (mergedColor != null)
        {
          hasValues = true;
          codec = codec.withRamp(ramp: mergedColor.ramp);
          code = codec.encode(color: mergedColor);
        }
        merged.select(x: coord.x, y: coord.y, code: code);
      }

      if (hasValues)
      {
        _clipboard = ClipboardContent(pixels: merged.snapshot()!, codec: codec);
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
        showMessage(text: "Nothing to copy!");
      }
    }
  }

  bool get hasClipboard => _clipboard != null;

  /// Forgets the copied pixels, e.g. because another project was opened.
  void clearClipboard()
  {
    if (_clipboard != null)
    {
      _clipboard = null;
      notifyListeners();
    }
  }

  int getClipboardPixelCountForRamp({required final KPalRampData ramp})
  {
    return _clipboard?.getPixelCountForRamp(ramp: ramp) ?? 0;
  }

  /// The clipboard matched against the current palette, or null (with a message)
  /// if none of the copied colors is left.
  ResolvedClipboard? _resolveClipboard()
  {
    final ResolvedClipboard? content = _clipboard?.resolve(ramps: _documentState.palette.colorRamps);
    if (_clipboard != null && content == null)
    {
      showMessage(text: "Nothing to paste: the copied colors are no longer in the palette!");
    }
    return content;
  }

  void paste({final bool notify = true, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (_clipboard != null && layer != null && layer is DrawingLayerState) //should always be the case
    {
      if (layer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot paste to a locked layer!");
      }
      else if (layer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot paste to a hidden layer!");
      }
      else
      {
        final ResolvedClipboard? content = _resolveClipboard();
        if (content != null)
        {
          deselect(notify: false, addToHistoryStack: false);
          selection.replaceContent(pixels: content.pixels, codec: content.codec);
          createSelectionLines();
          if (addToHistoryStack)
          {
            GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionPaste, originLayer: _documentState.timeline.getCurrentLayer());
          }

          if (notify)
          {
            notifyRepaint();
            layer.doManualRaster = true;
          }
        }
      }
    }
  }

  void pasteAsNewLayer()
  {
    final ResolvedClipboard? content = _resolveClipboard();
    if (content != null)
    {
      final CoordinateColorMapNullable colors = HashMap<CoordinateSetI, ColorReference?>();
      content.pixels.forEach(action: (final int x, final int y, final int code) => colors[CoordinateSetI(x: x, y: y)] = content.codec.decode(code: code));
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState, select: _behaviorOptions.selectLayerAfterInsert.value, content: colors);
    }
  }

  void flipH({final bool notify = true, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      if (layer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot transform on a hidden layer!");
      }
      else if (layer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot transform on a locked layer!");
      }
      else
      {
        selection.flipH();
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionFlipH, originLayer: _documentState.timeline.getCurrentLayer());
        }

        if (notify)
        {
          notifyRepaint();
          layer.doManualRaster = true;
        }
      }
    }
  }

  void flipV({final bool notify = true, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      if (layer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot transform on a hidden layer!");
      }
      else if (layer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot transform on a locked layer!");
      }
      else
      {
        selection.flipV();
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionFlipV, originLayer: _documentState.timeline.getCurrentLayer());
        }

        if (notify)
        {
          notifyRepaint();
          layer.doManualRaster = true;
        }
      }
    }
  }

  void rotate({final bool notify = true, final bool addToHistoryStack = true})
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      if (layer.visibilityState.value == LayerVisibilityState.hidden)
      {
        showMessage(text: "Cannot transform on a hidden layer!");
      }
      else if (layer.lockState.value == LayerLockState.locked)
      {
        showMessage(text: "Cannot transform on a locked layer!");
      }
      else
      {
        selection.rotate90cw();
        createSelectionLines();
        if (addToHistoryStack)
        {
          GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionRotate, originLayer: _documentState.timeline.getCurrentLayer());
        }

        if (notify)
        {
          notifyRepaint();
          layer.doManualRaster = true;
        }
      }
    }
  }

  void _moveSelection({required final CoordinateSetI offset, required final bool withContent})
  {
    setOffset(offset: offset, withContent: withContent);
    finishMovement();
  }

  void setOffset({required final CoordinateSetI offset, required final bool withContent})
  {
    selection.shiftSelection(offset: offset, withContent: withContent);
    createSelectionLines();
  }

  void finishMovement()
  {
    selection.resetLastOffset();
    if (!selection.isEmpty)
    {
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.selectionMove, originLayer: _documentState.timeline.getCurrentLayer());
    }
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      layer.doManualRaster = true;
    }
  }

  void centerSelectionH()
  {
    final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selection.getBoundingBox();
    if (topLeft != null && bottomRight != null)
    {
      final int width = bottomRight.x - topLeft.x;
      final int newX = (_canvasState.canvasSize.x / 2 - width / 2).floor();
      if (newX != topLeft.x)
      {
        final CoordinateSetI offset = CoordinateSetI(x: newX - topLeft.x, y: 0);
        _moveSelection(offset: offset, withContent: true);
      }
    }
  }

  void centerSelectionV()
  {
    final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selection.getBoundingBox();
    if (topLeft != null && bottomRight != null)
    {
      final int height = bottomRight.y - topLeft.y;
      final int newY = (_canvasState.canvasSize.y / 2 - height / 2).floor();
      if (newY != topLeft.y)
      {
        final CoordinateSetI offset = CoordinateSetI(x: 0, y: newY - topLeft.y);
        _moveSelection(offset: offset, withContent: true);
      }
    }
  }

  void alignSelectionLeft()
  {
    final (CoordinateSetI? topLeft, CoordinateSetI? _) = selection.getBoundingBox();
    if (topLeft != null && topLeft.x != 0)
    {
      final CoordinateSetI offset = CoordinateSetI(x: -topLeft.x, y: 0);
      _moveSelection(offset: offset, withContent: true);
    }
  }

  void alignSelectionRight()
  {
    final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selection.getBoundingBox();
    if (topLeft != null && bottomRight != null)
    {
      final int width = bottomRight.x - topLeft.x;
      final int newX = _canvasState.canvasSize.x - width - 1;
      if (newX != topLeft.x)
      {
        final CoordinateSetI offset = CoordinateSetI(x: newX - topLeft.x, y: 0);
        _moveSelection(offset: offset, withContent: true);
      }
    }
  }

  void alignSelectionTop()
  {
    final (CoordinateSetI? topLeft, CoordinateSetI? _) = selection.getBoundingBox();
    if (topLeft != null && topLeft.y != 0)
    {
      final CoordinateSetI offset = CoordinateSetI(x: 0, y: -topLeft.y);
      _moveSelection(offset: offset, withContent: true);
    }
  }

  void alignSelectionBottom()
  {
    final (CoordinateSetI? topLeft, CoordinateSetI? bottomRight) = selection.getBoundingBox();
    if (topLeft != null && bottomRight != null)
    {
      final int height = bottomRight.y - topLeft.y;
      final int newY = _canvasState.canvasSize.y - height - 1;
      if (newY != topLeft.y)
      {
        final CoordinateSetI offset = CoordinateSetI(x: 0, y: newY - topLeft.y);
        _moveSelection(offset: offset, withContent: true);
      }
    }
  }

}

/// The pixels a selection floats: which positions are selected, and the color
/// each of them holds.
///
/// The pixels physically belong to the selection while it is up: they are taken
/// out of the layer when they are selected ([transferAll]) and written back into
/// it when they are let go ([clear], [removeAll]). [owner] is the layer they
/// came from, which has to stay the selected one until then.
class SelectionList
{
  static final PaletteCodec _noRamps = PaletteCodec(ramps: const <KPalRampData>[]);

  final SelectionBuffer _pixels = SelectionBuffer();
  //the codes in _pixels belong to this codec, which takes in a ramp the first
  //time one of its colors is selected. Nothing keeps it in step with the
  //palette; the history lines it up when it takes a snapshot.
  PaletteCodec _codec = _noRamps;
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();
  final ValueNotifier<bool> isEmptyNotifer = ValueNotifier<bool>(true);
  int _revision = 0;
  //whether a selected pixel holds a color, as of this revision
  bool _hasValues = false;
  int _hasValuesRevision = -1;

  int get revision => _revision;

  /// The codec the codes of [forEachCode] and [snapshot] belong to.
  PaletteCodec get codec => _codec;

  LayerState? _owner;
  LayerState? get owner => _owner;

  void _touch({final bool notifyEmpty = true, final bool claimOwner = false})
  {
    _revision++;
    if (_pixels.isEmpty)
    {
      //nothing floating, nothing to misplace
      _owner = null;
      //and no color left for a code to stand for
      _codec = _noRamps;
    }
    else if (claimOwner)
    {
      _owner = _documentState.timeline.getCurrentLayer();
    }
    if (notifyEmpty)
    {
      isEmptyNotifer.value = _pixels.isEmpty;
    }
  }

  void _checkOwnership({required final String operation})
  {
    if (_pixels.isEmpty || _owner == null || identical(_owner, _documentState.timeline.getCurrentLayer()))
    {
      return;
    }
    final String message = "Selection content belongs to a layer that is no longer selected (during: $operation).";
    GetIt.I.get<Logger>().w(message);
    assert(false, message);
  }

  bool get isEmpty
  {
    return _pixels.isEmpty;
  }

  final CoordinateSetI _lastOffset = CoordinateSetI.zero();

  /// The code for [color] in [codec], which takes in the ramp of a color it has
  /// not seen before.
  int _encode({required final ColorReference? color})
  {
    if (color == null)
    {
      return PaletteCodec.transparent;
    }
    _codec = _codec.withRamp(ramp: color.ramp);
    return _codec.encode(color: color);
  }

  /// Makes room for [coords], so that a batch of writes grows the buffer once.
  void _cover({required final Iterable<CoordinateSetI> coords})
  {
    if (coords.isEmpty)
    {
      return;
    }
    int left = coords.first.x;
    int top = coords.first.y;
    int right = left;
    int bottom = top;
    for (final CoordinateSetI coord in coords)
    {
      left = min(left, coord.x);
      top = min(top, coord.y);
      right = max(right, coord.x);
      bottom = max(bottom, coord.y);
    }
    _pixels.cover(left: left, top: top, right: right, bottom: bottom);
  }

  /// Asks the layer the selection floats over for a new raster.
  void _rasterCurrentLayer()
  {
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      layer.doManualRaster = true;
    }
  }

  void changeLayer({required final LayerState? oldLayer, required final LayerState newLayer})
  {
    final CoordinateColorMapNullable refsOld = HashMap<CoordinateSetI, ColorReference?>();
    final CoordinateColorMapNullable refsNew = HashMap<CoordinateSetI, ColorReference?>();
    final DrawingLayerState? receivingLayer = (newLayer is DrawingLayerState && newLayer.lockState.value != LayerLockState.locked) ? newLayer : null;
    //what the selection floats afterwards, collected first because the old
    //colors have to be read before the new codes are written
    final List<(CoordinateSetI, ColorReference?)> lifted = <(CoordinateSetI, ColorReference?)>[];
    _pixels.forEach(action: (final int x, final int y, final int code)
    {
      final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
      if (code != PaletteCodec.transparent)
      {
        refsOld[coord] = _codec.decode(code: code);
      }
      if (receivingLayer != null)
      {
        lifted.add((coord, receivingLayer.getDataEntry(coord: coord)));
        refsNew[coord] = null;
      }
      else
      {
        lifted.add((coord, null));
      }
    },);
    //every pixel gets a new color, so the old ones need no code any more
    _codec = _noRamps;
    for (final (CoordinateSetI coord, ColorReference? color) in lifted)
    {
      _pixels.select(x: coord.x, y: coord.y, code: _encode(color: color));
    }
    if (oldLayer != null && oldLayer is DrawingLayerState)
    {
      oldLayer.setDataAll(list: refsOld);
    }

    if (newLayer is DrawingLayerState)
    {
      newLayer.setDataAll(list: refsNew);
    }
    _touch(claimOwner: true);
  }

  void transferAll({required final Set<CoordinateSetI> coords, final bool notifyEmpty = true})
  {
    _checkOwnership(operation: "adding to the selection");
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      _cover(coords: coords);
      for (final CoordinateSetI coord in coords)
      {
        _pixels.select(x: coord.x, y: coord.y, code: _encode(color: layer.getDataEntry(coord: coord)));
      }
      layer.removeDataAll(removeCoordList: coords);
    }
    _touch(notifyEmpty: notifyEmpty, claimOwner: true);
  }

  void addEmpty({required final CoordinateSetI coord})
  {
    _pixels.select(x: coord.x, y: coord.y, code: PaletteCodec.transparent);
    _touch(claimOwner: true);
  }

  void addDirectly({required final CoordinateSetI coord, required final ColorReference? colRef})
  {
    _pixels.select(x: coord.x, y: coord.y, code: _encode(color: colRef));
    _touch(claimOwner: true);
    _rasterCurrentLayer();
  }

  void addDirectlyAll({required final CoordinateColorMapNullable list})
  {
    _cover(coords: list.keys);
    for (final CoordinateColorNullable entry in list.entries)
    {
      _pixels.select(x: entry.key.x, y: entry.key.y, code: _encode(color: entry.value));
    }
    _touch(claimOwner: true);
    _rasterCurrentLayer();
  }

  void removeAll({required final Set<CoordinateSetI> coords})
  {
    _checkOwnership(operation: "removing from the selection");
    final CoordinateSetI canvasSize = _canvasState.canvasSize;
    final CoordinateColorMapNullable refs = HashMap<CoordinateSetI, ColorReference?>();
    for (final CoordinateSetI coord in coords)
    {
      if (coord.x >= 0 && coord.y >= 0 && coord.x < canvasSize.x && coord.y < canvasSize.y)
      {
        final int? code = _pixels.codeAt(x: coord.x, y: coord.y);
        if (code != null && code != PaletteCodec.transparent)
        {
          refs[coord] = _codec.decode(code: code);
        }
        _pixels.deselect(x: coord.x, y: coord.y);
      }
    }
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      layer.setDataAll(list: refs);
    }
    _touch();
  }

  void clear({final bool notifyEmpty = true})
  {
    _checkOwnership(operation: "deselecting");
    final CoordinateSetI canvasSize = _canvasState.canvasSize;
    final CoordinateColorMapNullable refs = HashMap<CoordinateSetI, ColorReference?>();
    _pixels.forEach(action: (final int x, final int y, final int code)
    {
      //what floats off the canvas is lost, as it was before
      if (code != PaletteCodec.transparent && x >= 0 && y >= 0 && x < canvasSize.x && y < canvasSize.y)
      {
        refs[CoordinateSetI(x: x, y: y)] = _codec.decode(code: code);
      }
    },);
    final LayerState? layer = _documentState.timeline.getCurrentLayer();
    if (layer != null && layer is DrawingLayerState)
    {
      layer.setDataAll(list: refs);
    }
    _pixels.clear();
    _touch(notifyEmpty: notifyEmpty);
  }

  void deleteDirectly({required final CoordinateSetI coord})
  {
    final int? code = _pixels.codeAt(x: coord.x, y: coord.y);
    if (code != null && code != PaletteCodec.transparent)
    {
      _pixels.select(x: coord.x, y: coord.y, code: PaletteCodec.transparent);
    }
    _touch();
  }

  void delete({required final bool keepSelection})
  {
    if (keepSelection)
    {
      //every pixel stays selected, holding no color
      _pixels.remap(lut: Uint16List(_codec.codeCount));
      _codec = _noRamps;
    }
    else
    {
      _pixels.clear();
    }
    _touch();
  }

  /// Empties every selected pixel of the deleted [ramp], keeping the shape of
  /// the selection.
  void deleteRamp({required final KPalRampData ramp})
  {
    final PaletteCodec remaining = _codec.withoutRamp(ramp: ramp);
    if (!identical(remaining, _codec))
    {
      final bool changed = getPixelCountForRamp(ramp: ramp) > 0;
      //the ramp's codes have no place in the remaining codec, so they are dropped
      _pixels.remap(lut: _codec.remapLut(target: remaining));
      _codec = remaining;
      if (changed)
      {
        _touch();
      }
    }
  }

  /// Moves the selected pixels of [ramp] after its color count changed, through
  /// the same [map] the layers are remapped with.
  void remapRamp({required final KPalRampData ramp, required final HashMap<int, int> map})
  {
    if (_codec.indexOfRamp(ramp: ramp) != null && getPixelCountForRamp(ramp: ramp) > 0)
    {
      _pixels.remap(lut: _codec.remapLut(target: _codec, colorIndexMaps: <KPalRampData, Map<int, int>>{ramp: map}));
      _touch();
    }
  }

  /// Swaps every selected color through [colorMap] after the palette was
  /// replaced. A color missing from the map becomes transparent.
  void remapColors({required final HashMap<ColorReference, ColorReference> colorMap})
  {
    if (hasValues())
    {
      PaletteCodec target = _codec;
      for (final ColorReference color in colorMap.values)
      {
        target = target.withRamp(ramp: color.ramp);
      }
      _pixels.remap(lut: _codec.remapLutByColor(target: target, colorMap: colorMap));
      _codec = target;
      _touch();
    }
  }

  int getPixelCountForRamp({required final KPalRampData ramp})
  {
    final int? rampIndex = _codec.indexOfRamp(ramp: ramp);
    if (rampIndex == null)
    {
      return 0;
    }
    int count = 0;
    _pixels.forEach(action: (final int x, final int y, final int code)
    {
      if (code != PaletteCodec.transparent && PaletteCodec.rampIndexOf(code: code) == rampIndex)
      {
        count++;
      }
    },);
    return count;
  }

  void flipH()
  {
    _pixels.flipHorizontally();
    _touch();
  }

  void flipV()
  {
    _pixels.flipVertically();
    _touch();
  }

  void rotate90cw()
  {
    _pixels.rotateClockwise();
    _touch();
  }

  bool contains({required final CoordinateSetI coord})
  {
    return _pixels.contains(x: coord.x, y: coord.y);
  }

  /// Whether [x]|[y] is selected, without building a coordinate for it.
  bool isSelectedAt({required final int x, required final int y})
  {
    return _pixels.contains(x: x, y: y);
  }

  /// Every selected position, in a new list.
  List<CoordinateSetI> getCoordinates()
  {
    final List<CoordinateSetI> coords = <CoordinateSetI>[];
    _pixels.forEach(action: (final int x, final int y, final int code) => coords.add(CoordinateSetI(x: x, y: y)));
    return coords;
  }

  ColorReference? getColorReference({required final CoordinateSetI coord})
  {
    final int? code = _pixels.codeAt(x: coord.x, y: coord.y);
    return code == null ? null : _codec.decode(code: code);
  }

  /// Calls [action] for every selected pixel, with the color it floats or null
  /// where it floats none.
  void forEachSelected({required final void Function(int x, int y, ColorReference? color) action})
  {
    _pixels.forEach(action: (final int x, final int y, final int code) => action(x, y, _codec.decode(code: code)));
  }

  /// Calls [action] for every selected pixel with its code in [codec].
  void forEachCode({required final void Function(int x, int y, int code) action})
  {
    _pixels.forEach(action: action);
  }

  void shiftSelection({required final CoordinateSetI offset, required final bool withContent})
  {
    if (offset != _lastOffset)
    {
      final int stepX = offset.x - _lastOffset.x;
      final int stepY = offset.y - _lastOffset.y;
      if (withContent)
      {
        //the pixels stay as they are, only where they float moves
        _pixels.moveBy(dx: stepX, dy: stepY);
        _lastOffset.x = offset.x;
        _lastOffset.y = offset.y;
        _rasterCurrentLayer();
      }
      else
      {
        final CoordinateSetI canvasSize = _canvasState.canvasSize;
        final Set<CoordinateSetI> coordinateList = <CoordinateSetI>{};
        _pixels.forEach(action: (final int x, final int y, final int code)
        {
          final CoordinateSetI newCoord = CoordinateSetI(x: x + stepX, y: y + stepY);
          if (newCoord.x >= 0 && newCoord.y >= 0 && newCoord.x < canvasSize.x && newCoord.y < canvasSize.y)
          {
            coordinateList.add(newCoord);
          }
        },);
        _lastOffset.x = offset.x;
        _lastOffset.y = offset.y;

        clear(notifyEmpty: false);
        transferAll(coords: coordinateList, notifyEmpty: false);
      }
    }
    _touch();
  }

  void resetLastOffset()
  {
    _lastOffset.x = 0;
    _lastOffset.y = 0;
  }

  bool hasValues()
  {
    if (_hasValuesRevision != _revision)
    {
      bool has = false;
      _pixels.forEach(action: (final int x, final int y, final int code)
      {
        has = has || code != PaletteCodec.transparent;
      },);
      _hasValues = has;
      _hasValuesRevision = _revision;
    }
    return _hasValues;
  }

  /// The box around the selected pixels, or (null, null) if nothing is selected.
  (CoordinateSetI?, CoordinateSetI?) getBoundingBox()
  {
    final SelectionBounds? box = _pixels.bounds;
    return box == null ? (null, null) : (CoordinateSetI(x: box.left, y: box.top), CoordinateSetI(x: box.right, y: box.bottom));
  }

  /// The selected pixels as they are, sharing their tiles until either side
  /// changes, or null if nothing is selected. Their codes belong to [codec].
  SelectionBufferSnapshot? snapshot()
  {
    return _pixels.snapshot();
  }

  /// The selected pixels as codes whose ramp index is the ramp's position in
  /// [ramps], which is how the history and the file store them, or null if
  /// nothing is selected. A color of a ramp missing from [ramps] is left out.
  ///
  /// Like a drawing layer (see DrawingLayerState.historySnapshot), the selection
  /// first moves its own codes into the palette's order when [ramps] is the
  /// palette. The snapshot then shares its tiles instead of being translated on
  /// every step.
  SelectionBufferSnapshot? historySnapshot({required final List<HistoryRampData> ramps})
  {
    if (_pixels.isEmpty)
    {
      return null;
    }
    final List<String> uuids = <String>[for (final HistoryRampData ramp in ramps) ramp.uuid];
    final PaletteCodec palette = _documentState.palette.codec;
    if (palette.listsUuids(uuids: uuids))
    {
      _alignCodec(target: palette);
    }
    final ({Uint16List lut, bool linesUp}) translation = _codec.remapLutToUuids(uuids: uuids);
    final SelectionBufferSnapshot current = _pixels.snapshot()!;
    if (translation.linesUp)
    {
      return current;
    }
    final SelectionBuffer translated = SelectionBuffer.fromSnapshot(snapshot: current);
    translated.remap(lut: translation.lut);
    return translated.snapshot();
  }

  /// Moves the codes into [target]'s order, so that a code means the same in the
  /// selection and in [target]. Ramps only the selection floats colors of follow
  /// behind [target]'s; ramps without pixels are dropped. Nothing visible
  /// changes.
  void _alignCodec({required final PaletteCodec target})
  {
    if (_codec.followsOrderOf(target: target))
    {
      return;
    }
    final Set<int> usedRamps = <int>{};
    _pixels.forEach(action: (final int x, final int y, final int code)
    {
      if (code != PaletteCodec.transparent)
      {
        usedRamps.add(PaletteCodec.rampIndexOf(code: code));
      }
    },);
    final PaletteCodec aligned = _codec.alignedTo(target: target, usedRampIndices: usedRamps);
    _pixels.remap(lut: _codec.remapLut(target: aligned));
    _codec = aligned;
  }

  /// Replaces the selection with [pixels], whose codes belong to [codec] once
  /// they went through [lut], if one is given. This is how the history and the
  /// clipboard hand pixels over, so nothing is taken out of a layer.
  void replaceContent({required final SelectionBufferSnapshot? pixels, required final PaletteCodec codec, final Uint16List? lut})
  {
    _pixels.replaceWith(snapshot: pixels);
    if (lut != null)
    {
      _pixels.remap(lut: lut);
    }
    _codec = codec;
    _touch(claimOwner: true);
    _rasterCurrentLayer();
  }
}
