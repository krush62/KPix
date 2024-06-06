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


  void newSelection({required final CoordinateSetI start, required final CoordinateSetI end, required final SelectShape selectShape, final bool notify = true})
  {
    if (selectionOptions.mode == SelectionMode.replace)
    {
      deselect(notify: false);
    }
    final LayerState currentLayer = GetIt.I.get<AppState>().getSelectedLayer()!;

    if (selectionOptions.mode != SelectionMode.replace || end.x != start.x || end.y != start.y)
    {
      if (selectShape == SelectShape.rectangle) {
        for (int x = start.x; x <= end.x; x++) {
          for (int y = start.y; y <= end.y; y++) {
            CoordinateSetI selectedPixel = CoordinateSetI(x: x, y: y);
            switch (selectionOptions.mode) {
              case SelectionMode.replace:
              case SelectionMode.add:
                if (!selection.contains(selectedPixel)) {
                  selection.add(selectedPixel, currentLayer);
                }
                break;
              case SelectionMode.intersect:
                if (!selection.contains(selectedPixel)) {
                  selection.add(selectedPixel, currentLayer);
                }
                else {
                  selection.remove(selectedPixel, currentLayer);
                }
                break;
              case SelectionMode.subtract:
                if (selection.contains(selectedPixel)) {
                  selection.remove(selectedPixel, currentLayer);
                }
                break;
            }
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
              CoordinateSetI selectedPixel = CoordinateSetI(x: x, y: y);
              switch (selectionOptions.mode) {
                case SelectionMode.replace:
                case SelectionMode.add:
                  if (!selection.contains(selectedPixel)) {
                    selection.add(selectedPixel, currentLayer);
                  }
                  break;
                case SelectionMode.intersect:
                  if (!selection.contains(selectedPixel)) {
                    selection.add(selectedPixel, currentLayer);
                  }
                  else {
                    selection.remove(selectedPixel, currentLayer);
                  }
                  break;
                case SelectionMode.subtract:
                  if (selection.contains(selectedPixel)) {
                    selection.remove(selectedPixel, currentLayer);
                  }
                  break;
              }
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
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void _createSelectionLines()
  {
    selectionLines.clear();
    final selectedCoordinates = selection.getCoordinates();
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
    final LayerState currentLayer = GetIt.I.get<AppState>().getSelectedLayer()!;
    for (int x = 0; x < GetIt.I.get<AppState>().canvasWidth; x++)
    {
      for (int y = 0; y < GetIt.I.get<AppState>().canvasHeight; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (selection.contains(coord))
        {
          selection.remove(coord, currentLayer);
        }
        else
        {
          selection.add(coord, currentLayer);
        }
      }
    }
    _createSelectionLines();
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }


  void deselect({final bool notify = true})
  {
    final LayerState currentLayer = GetIt.I.get<AppState>().getSelectedLayer()!;
    selection.clear(currentLayer);
    _createSelectionLines();
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void selectAll({final bool notify = true})
  {
    final LayerState currentLayer = GetIt.I.get<AppState>().getSelectedLayer()!;
    for (int x = 0; x < GetIt.I.get<AppState>().canvasWidth; x++)
    {
      for (int y = 0; y < GetIt.I.get<AppState>().canvasHeight; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (!selection.contains(coord))
        {
          selection.add(coord, currentLayer);
        }
      }
    }
    _createSelectionLines();
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void delete({final bool notify = true, bool keepSelection = true})
  {
    final LayerState currentLayer = GetIt.I.get<AppState>().getSelectedLayer()!;
    selection.delete(currentLayer, keepSelection);
    if (!keepSelection)
    {
      _createSelectionLines();
    }

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void cut({final bool notify = true, final bool keepSelection = false})
  {
    copy(notify: false, keepSelection: true);
    delete(keepSelection: true, notify: false);

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void copy({final bool notify = true, final keepSelection = false})
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

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void copyMerged({final bool notify = true, final keepSelection = false})
  {
    clipboard = HashMap();
    final Iterable<LayerState> visibleLayers = GetIt.I.get<AppState>().layers.value.where((x) => x.visibilityState.value == LayerVisibilityState.visible);
    final Iterable<CoordinateSetI> coords = selection.getCoordinates();

    for (final CoordinateSetI coord in coords)
    {
      bool pixelFound = false;
      //TODO is the order correct?
      for (final LayerState layer in visibleLayers)
      {
        final ColorReference? colRef = layer.data[coord.x][coord.y];
        if (colRef != null)
        {
          clipboard![coord] = colRef;
          pixelFound = true;
          break;
        }
      }
      if (!pixelFound)
      {
        clipboard![coord] = null;
      }
    }

    if (!keepSelection)
    {
      deselect(notify: false);
    }

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void paste({final bool notify = true})
  {
    if (clipboard != null) //should always be the case
    {
        deselect(notify: false);
        for (final CoordinateSetI key in clipboard!.keys)
        {
          selection.addDirectly(key, clipboard![key]);
        }
        _createSelectionLines();
    }

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void flipH({final bool notify = true})
  {
    selection.flipH();
    _createSelectionLines();

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void flipV({final bool notify = true})
  {
    selection.flipV();
    _createSelectionLines();

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void rotate({final bool notify = true})
  {
    selection.rotate90cw();
    _createSelectionLines();

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
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

  HashMap<CoordinateSetI, ColorReference?> getSelectedPixels()
  {
    return _content;
  }

  void changeLayer(final LayerState oldLayer, final LayerState newLayer)
  {
    for (final CoordinateSetI key in _content.keys)
    {
      final ColorReference? curVal = _content[key];
      if (curVal != null)
      {
        oldLayer.data[key.x][key.y] = curVal;
      }
      _content[key] = newLayer.data[key.x][key.y];
      newLayer.data[key.x][key.y] = null;
    }
  }

  void add(final CoordinateSetI coord, final LayerState layer)
  {
    _content[coord] = layer.data[coord.x][coord.y];
    layer.data[coord.x][coord.y] = null;
  }

  void addDirectly(final CoordinateSetI coord, final ColorReference? colRef)
  {
    _content[coord] = colRef;
  }


  void remove(final CoordinateSetI coord, final LayerState layer)
  {
    if (_content[coord] != null && coord.x > 0 && coord.y > 0 && coord.x < GetIt.I.get<AppState>().canvasWidth && coord.y < GetIt.I.get<AppState>().canvasHeight)
    {
      layer.data[coord.x][coord.y] = _content[coord];
    }
    _content.remove(coord);
  }

  void clear(final LayerState layer)
  {
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
    {
      if (entry.value != null && entry.key.x > 0 && entry.key.y > 0 && entry.key.x < GetIt.I.get<AppState>().canvasWidth && entry.key.y < GetIt.I.get<AppState>().canvasHeight)
      {
        layer.data[entry.key.x][entry.key.y] = entry.value;
      }
    }
    _content.clear();
  }

  void delete(final LayerState layer, bool keepSelection)
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
}

