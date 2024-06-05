import 'dart:collection';

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

  void copyMerged({final bool notify = true})
  {
    //TODO
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }
}

class SelectionList
{
  final HashMap<CoordinateSetI, ColorReference?> _content = HashMap();

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
    //TODO this might need a bound check
    _content[coord] = layer.data[coord.x][coord.y];
    layer.data[coord.x][coord.y] = null;
  }

  void addDirectly(final CoordinateSetI coord, final ColorReference? colRef)
  {
    _content[coord] = colRef;
  }


  void remove(final CoordinateSetI coord, final LayerState layer)
  {
    //TODO this might need a bound check
    if (_content[coord] != null)
    {
      layer.data[coord.x][coord.y] = _content[coord];
    }
    _content.remove(coord);
  }

  void clear(final LayerState layer)
  {
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _content.entries)
    {
      //TODO this might need a bound check
      if (entry.value != null)
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
    if (contains(coord))
    {
      return _content[coord];
    }
    else
    {
      return null;
    }
  }


}

