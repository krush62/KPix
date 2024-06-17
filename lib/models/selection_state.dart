import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

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
  final SelectionList selection = SelectionList();
  HashMap<CoordinateSetI, ColorReference?>? clipboard;
  final RepaintNotifier repaintNotifier;
  final SelectOptions selectionOptions = GetIt.I.get<PreferenceManager>().toolOptions.selectOptions;
  final List<SelectionLine> selectionLines = [];

  SelectionState({required this.repaintNotifier});

  void notifyRepaint()
  {
    notifyListeners();
    repaintNotifier.repaint();
  }

  void newSelectionFromPolygon({required final List<CoordinateSetI> points, final bool notify = true})
  {
    if (selectionOptions.mode.value == SelectionMode.replace)
    {
      deselect(notify: false);
    }

    for (final CoordinateSetI point in points)
    {
      _addPixelWithMode(coord: point, mode: selectionOptions.mode.value);
    }
    _createSelectionLines();

    if (notify)
    {
      notifyRepaint();
    }

  }


  void newSelectionFromShape({required final CoordinateSetI start, required final CoordinateSetI end, required final SelectShape selectShape, final bool notify = true})
  {
    if (selectionOptions.mode.value == SelectionMode.replace)
    {
      deselect(notify: false);
    }

    if (selectionOptions.mode.value != SelectionMode.replace || end.x != start.x || end.y != start.y)
    {
      if (selectShape == SelectShape.rectangle) {
        for (int x = start.x; x <= end.x; x++) {
          for (int y = start.y; y <= end.y; y++) {
            _addPixelWithMode(coord: CoordinateSetI(x: x, y: y), mode: selectionOptions.mode.value);
          }
        }
      }
      else if (selectShape == SelectShape.ellipse)
      {
        double centerX = (start.x + end.x + 1) / 2.0;
        double centerY = (start.y + end.y + 1) / 2.0;
        double radiusX = (end.x - start.x + 1) / 2.0;
        double radiusY = (end.y - start.y + 1) / 2.0;

        for (int x = start.x; x <= end.x; x++) {
          for (int y = start.y; y <= end.y; y++) {
            double dx = (x + 0.5) - centerX;
            double dy = (y + 0.5) - centerY;
            if ((dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1)
            {
              _addPixelWithMode(coord: CoordinateSetI(x: x, y: y), mode: selectionOptions.mode.value);
            }
          }
        }
      }

      _createSelectionLines();
    }
    else
    {
      //DISCARD SELECTION
    }
    if (notify)
    {
      notifyRepaint();
    }
  }

  void newSelectionFromWand({required final CoordinateSetI coord, required final SelectionMode mode, required final bool continuous, required final bool selectFromWholeRamp, final bool notify = true})
  {
    if (selectionOptions.mode.value == SelectionMode.replace)
    {
      deselect(notify: false);
    }

    if (!selection.contains(coord) || !(mode == SelectionMode.add || mode == SelectionMode.replace))
    {
      final List<CoordinateSetI> selectData = continuous ?
        getFloodReferences(layer: selection.currentLayer!, start: coord, selectFromWholeRamp: selectFromWholeRamp) :
        getSameReferences(layer: selection.currentLayer!, start: coord, selectFromWholeRamp: selectFromWholeRamp);

      for (final CoordinateSetI coord in selectData)
      {
        _addPixelWithMode(coord: coord, mode: mode);
      }

      _createSelectionLines();
      if (notify)
      {
        notifyRepaint();
      }
    }
  }

  List<CoordinateSetI> getFloodReferences({
    required final LayerState layer,
    required final CoordinateSetI start,
    required final bool selectFromWholeRamp})
  {
    final int numRows = GetIt.I.get<AppState>().canvasHeight;
    final int numCols = GetIt.I.get<AppState>().canvasWidth;
    final ColorReference? targetValue = (selection.currentLayer == layer && selection.contains(start)) ? selection.getColorReference(start) : layer.getData(start.x, start.y);
    final List<CoordinateSetI> result = [];
    final List<List<bool>> visited = List.generate(numCols, (_) => List.filled(numRows, false));

    void fill(int x, int y) {
      if (x < 0 || y >= numRows || y < 0 || x >= numCols) return;
      final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
      final ColorReference? refAtPos = (selection.currentLayer == layer && selection.contains(curCoord)) ? selection.getColorReference(curCoord) : layer.getData(curCoord.x, curCoord.y);
      if (!visited[x][y] && (refAtPos == targetValue || (refAtPos != null && targetValue != null && selectFromWholeRamp && refAtPos.ramp == targetValue.ramp)))
      {
        visited[x][y] = true;
        result.add(curCoord);
        fill(x + 1, y);
        fill(x - 1, y);
        fill(x, y + 1);
        fill(x, y - 1);
      }
    }

    fill(start.x, start.y);
    return result;
  }

  List<CoordinateSetI> getSameReferences({
    required final LayerState layer,
    required final CoordinateSetI start,
    required final bool selectFromWholeRamp})
  {
    final List<CoordinateSetI> result = [];
    final ColorReference? targetValue = (selection.currentLayer == layer && selection.contains(start)) ? selection.getColorReference(start) : layer.getData(start.x, start.y);
    for (int x = 0; x < GetIt.I.get<AppState>().canvasWidth; x++)
    {
      for (int y = 0; y < GetIt.I.get<AppState>().canvasHeight; y++)
      {
        final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
        final ColorReference? refAtPos = (selection.currentLayer == layer && selection.contains(curCoord)) ? selection.getColorReference(curCoord) : layer.getData(curCoord.x, curCoord.y);
        if (refAtPos == targetValue || (selectFromWholeRamp && refAtPos != null && targetValue != null && refAtPos.ramp == targetValue.ramp))
        {
          result.add(curCoord);
        }
      }
    }
    return result;
  }



  void _addPixelWithMode({required CoordinateSetI coord, required SelectionMode mode})
  {
    switch (selectionOptions.mode.value) {
      case SelectionMode.replace:
      case SelectionMode.add:
        if (!selection.contains(coord)) {
          selection.add(coord);
        }
        break;
      case SelectionMode.intersect:
        if (!selection.contains(coord)) {
          selection.add(coord);
        }
        else {
          selection.remove(coord);
        }
        break;
      case SelectionMode.subtract:
        if (selection.contains(coord)) {
          selection.remove(coord);
        }
        break;
    }
  }

  void _createSelectionLines()
  {
    selectionLines.clear();
    final Iterable<CoordinateSetI> selectedCoordinates = selection.getCoordinates();
    for (final CoordinateSetI coord in selectedCoordinates)
    {
      if (coord.x == 0 || !selection.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)))
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
      if (coord.x == GetIt.I.get<AppState>().canvasWidth - 1 || !selection.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)))
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
      if (coord.y == 0 || !selection.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)))
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
      if (coord.y == GetIt.I.get<AppState>().canvasHeight - 1 || !selection.contains(CoordinateSetI(x: coord.x, y: coord.y + 1)))
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

  void inverse({final bool notify = true})
  {
    for (int x = 0; x < GetIt.I.get<AppState>().canvasWidth; x++)
    {
      for (int y = 0; y < GetIt.I.get<AppState>().canvasHeight; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (selection.contains(coord))
        {
          selection.remove(coord);
        }
        else
        {
          selection.add(coord);
        }
      }
    }
    _createSelectionLines();
    if (notify)
    {
      notifyRepaint();
    }
  }


  void deselect({final bool notify = true})
  {
    selection.clear();
    _createSelectionLines();
    if (notify)
    {
      notifyRepaint();
    }
  }

  void selectAll({final bool notify = true})
  {
    for (int x = 0; x < GetIt.I.get<AppState>().canvasWidth; x++)
    {
      for (int y = 0; y < GetIt.I.get<AppState>().canvasHeight; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (!selection.contains(coord))
        {
          selection.add(coord);
        }
      }
    }
    _createSelectionLines();
    if (notify)
    {
      notifyRepaint();
    }
  }

  void delete({final bool notify = true, bool keepSelection = true})
  {
    if (selection.currentLayer!.visibilityState.value == LayerVisibilityState.hidden)
    {
      GetIt.I.get<AppState>().showMessage("Cannot delete from hidden layer!");
    }
    else if (selection.currentLayer!.lockState.value == LayerLockState.locked)
    {
      GetIt.I.get<AppState>().showMessage("Cannot delete from locked layer!");
    }
    else
    {
      selection.delete(keepSelection);
      if (!keepSelection)
      {
        _createSelectionLines();
      }
    }



    if (notify)
    {
      notifyRepaint();
    }
  }

  void cut({final bool notify = true, final bool keepSelection = false})
  {
    if (selection.currentLayer!.visibilityState.value == LayerVisibilityState.hidden)
    {
      GetIt.I.get<AppState>().showMessage("Cannot cut from hidden layer!");
    }
    else if (selection.currentLayer!.lockState.value == LayerLockState.locked)
    {
      GetIt.I.get<AppState>().showMessage("Cannot cut from locked layer!");
    }
    else if (copy(notify: false, keepSelection: true))
    {
      delete(keepSelection: true, notify: false);
      if (notify)
      {
        notifyRepaint();
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
        clipboard![coord] = selection.getColorReference(coord);
      }
      if (!keepSelection)
      {
        deselect(notify: false);
      }
      hasCopied = true;
      if (notify)
      {
        notifyRepaint();
      }
    }
    else
    {
      GetIt.I.get<AppState>().showMessage("Nothing to copy!");
    }
    return hasCopied;
  }

  void copyMerged({final bool notify = true, final keepSelection = false})
  {
    HashMap<CoordinateSetI, ColorReference?> tempCB = HashMap();
    final Iterable<LayerState> visibleLayers = GetIt.I.get<AppState>().layers.value.where((x) => x.visibilityState.value == LayerVisibilityState.visible);
    final Iterable<CoordinateSetI> coords = selection.getCoordinates();
    bool hasValues = false;

    for (final CoordinateSetI coord in coords)
    {
      bool pixelFound = false;
      //TODO is the order correct?
      for (final LayerState layer in visibleLayers)
      {
        final ColorReference? colRef = layer.getData(coord.x, coord.y);
        if (colRef != null)
        {
          hasValues = true;
          tempCB[coord] = colRef;
          pixelFound = true;
          break;
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
        deselect(notify: false);
      }

      if (notify)
      {
        notifyRepaint();
      }
    }
    else
    {
      GetIt.I.get<AppState>().showMessage("Nothing to copy!");
    }
  }

  void paste({final bool notify = true})
  {
    if (clipboard != null && selection.currentLayer != null) //should always be the case
    {
      if (selection.currentLayer!.lockState.value == LayerLockState.locked)
      {
        GetIt.I.get<AppState>().showMessage("Cannot paste to a locked layer!");
      }
      else if (selection.currentLayer!.visibilityState.value == LayerVisibilityState.hidden)
      {
        GetIt.I.get<AppState>().showMessage("Cannot paste to a hidden layer!");
      }
      else
      {
        deselect(notify: false);
        for (final CoordinateSetI key in clipboard!.keys) {
          selection.addDirectly(key, clipboard![key]);
        }
        _createSelectionLines();

        if (notify) {
          notifyRepaint();
        }
      }
    }
  }

  void flipH({final bool notify = true})
  {
    if (selection.currentLayer!.visibilityState.value == LayerVisibilityState.hidden)
    {
      GetIt.I.get<AppState>().showMessage("Cannot transform on a hidden layer!");
    }
    else if (selection.currentLayer!.lockState.value == LayerLockState.locked)
    {
      GetIt.I.get<AppState>().showMessage("Cannot transform on a locked layer!");
    }
    else
    {
      selection.flipH();
      _createSelectionLines();

      if (notify)
      {
        notifyRepaint();
      }
    }
  }

  void flipV({final bool notify = true})
  {
    if (selection.currentLayer!.visibilityState.value == LayerVisibilityState.hidden)
    {
      GetIt.I.get<AppState>().showMessage("Cannot transform on a hidden layer!");
    }
    else if (selection.currentLayer!.lockState.value == LayerLockState.locked)
    {
      GetIt.I.get<AppState>().showMessage("Cannot transform on a locked layer!");
    }
    else
    {
      selection.flipV();
      _createSelectionLines();

      if (notify)
      {
        notifyRepaint();
      }
    }
  }

  void rotate({final bool notify = true})
  {
    if (selection.currentLayer!.visibilityState.value == LayerVisibilityState.hidden)
    {
      GetIt.I.get<AppState>().showMessage("Cannot transform on a hidden layer!");
    }
    else if (selection.currentLayer!.lockState.value == LayerLockState.locked)
    {
      GetIt.I.get<AppState>().showMessage("Cannot transform on a locked layer!");
    }
    else
    {
      selection.rotate90cw();
      _createSelectionLines();

      if (notify)
      {
        notifyRepaint();
      }
    }
  }

  void setOffset(final CoordinateSetI offset)
  {
    selection.shiftSelection(offset);
    _createSelectionLines();
  }

  void finishMovement()
  {
    selection.resetLastOffset();
  }
}

class SelectionList
{
  HashMap<CoordinateSetI, ColorReference?> _content = HashMap();
  final CoordinateSetI _lastOffset = CoordinateSetI(x: 0, y: 0);
  LayerState? currentLayer;

  HashMap<CoordinateSetI, ColorReference?> getSelectedPixels()
  {
    return _content;
  }

  void setCurrentLayer(final LayerState? layerState)
  {
    currentLayer = layerState;
  }

  void changeLayer(final LayerState oldLayer, final LayerState newLayer)
  {
    for (final CoordinateSetI key in _content.keys)
    {
      final ColorReference? curVal = _content[key];
      if (curVal != null)
      {
        oldLayer.setData(key.x, key.y, curVal);
      }
      if (newLayer.lockState.value != LayerLockState.locked)
      {
        _content[key] = newLayer.getData(key.x, key.y);
        newLayer.setData(key.x, key.y, null);
      }
    }
  }

  void add(final CoordinateSetI coord)
  {
    _content[coord] = currentLayer!.getData(coord.x, coord.y);
    currentLayer!.setData(coord.x, coord.y, null);
  }

  void addEmpty(final CoordinateSetI coord)
  {
    _content[coord] = null;
  }

  void addDirectly(final CoordinateSetI coord, final ColorReference? colRef)
  {
    _content[coord] = colRef;
  }


  void remove(final CoordinateSetI coord)
  {
    if (_content[coord] != null && coord.x > 0 && coord.y > 0 && coord.x < GetIt.I.get<AppState>().canvasWidth && coord.y < GetIt.I.get<AppState>().canvasHeight)
    {
      currentLayer!.setData(coord.x, coord.y, _content[coord]);
    }
    _content.remove(coord);
  }


  void clear()
  {
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
    {
      if (entry.value != null && entry.key.x > 0 && entry.key.y > 0 && entry.key.x < GetIt.I.get<AppState>().canvasWidth && entry.key.y < GetIt.I.get<AppState>().canvasHeight)
      {
        currentLayer!.setData(entry.key.x, entry.key.y, entry.value);
      }
    }
    _content.clear();
  }

  void deleteDirectly(final CoordinateSetI coord)
  {
    if (_content.keys.contains(coord) && _content[coord] != null)
    {
      _content[coord] = null;
    }
  }

  void delete(bool keepSelection)
  {
    if (keepSelection) {
      for (final CoordinateSetI entry in _content
          .keys) {
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

    final HashMap<CoordinateSetI, ColorReference?> newContent = HashMap();
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
    {
      newContent[CoordinateSetI(x: maxXcoord.x - entry.key.x + minXcoord.x , y: entry.key.y)] = entry.value;
    }
    _content = newContent;
  }

  void flipV()
  {
    CoordinateSetI minYcoord = _content.keys.reduce((a, b) => a.y < b.y ? a : b);
    CoordinateSetI maxYcoord = _content.keys.reduce((a, b) => a.y > b.y ? a : b);

    final HashMap<CoordinateSetI, ColorReference?> newContent = HashMap();
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
    {
      newContent[CoordinateSetI(x: entry.key.x, y: maxYcoord.y - entry.key.y + minYcoord.y)] = entry.value;
    }
    _content = newContent;
  }

  void rotate90cw()
  {
    CoordinateSetI minCoords = CoordinateSetI(x: GetIt.I.get<AppState>().canvasWidth, y: GetIt.I.get<AppState>().canvasHeight);
    CoordinateSetI maxCoords = CoordinateSetI(x: 0, y: 0);
    for (final CoordinateSetI coord in _content.keys)
    {
      minCoords.x = min(coord.x, minCoords.x);
      minCoords.y = min(coord.y, minCoords.y);
      maxCoords.x = max(coord.x, maxCoords.x);
      maxCoords.y = max(coord.y, maxCoords.y);
    }

    final CoordinateSetI centerCoord = CoordinateSetI(x: (minCoords.x + maxCoords.x) ~/ 2, y: (minCoords.y + maxCoords.y) ~/ 2);
    final HashMap<CoordinateSetI, ColorReference?> newContent = HashMap();
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
    {
      newContent[CoordinateSetI(x: centerCoord.y - entry.key.y + centerCoord.x, y: entry.key.x - centerCoord.x + centerCoord.y)] = entry.value;
    }
    _content = newContent;
  }

  bool contains(final CoordinateSetI coord)
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


  ColorReference? getColorReference(final CoordinateSetI coord)
  {
    return contains(coord) ? _content[coord] : null;
  }

  void shiftSelection(final CoordinateSetI offset)
  {

    if (offset != _lastOffset) {
      final HashMap<CoordinateSetI, ColorReference?> newContent = HashMap();
      for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
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

}

