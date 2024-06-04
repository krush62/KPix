import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

enum SelectionDirection
{
  Undefined,
  Left,
  Right,
  Top,
  Bottom
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

  void newSelection({required final CoordinateSetI start, required final CoordinateSetI end, final bool notify = true})
  {
    if (selectionOptions.mode == SelectionMode.replace)
    {
      deselect(notify: false);
    }

    if (end.x > start.x && end.y > start.y)
    {
      for (int x = start.x; x <= end.x; x++)
      {
        for (int y = start.y; y <= end.y; y++)
        {
          CoordinateSetI selectedPixel = CoordinateSetI(x: x, y: y);
          switch (selectionOptions.mode) {
            case SelectionMode.replace:
            case SelectionMode.add:
              if (!selection.selectedPixels.contains(selectedPixel))
              {
                selection.selectedPixels.add(selectedPixel);
              }
              break;
            case SelectionMode.intersect:
              if (!selection.selectedPixels.contains(selectedPixel))
              {
                selection.selectedPixels.add(selectedPixel);
              }
              else
              {
                selection.selectedPixels.remove(selectedPixel);
              }
              break;
            case SelectionMode.subtract:
              if (selection.selectedPixels.contains(selectedPixel))
              {
                selection.selectedPixels.remove(selectedPixel);
              }
              break;
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
    for (final CoordinateSetI coord in selection.selectedPixels)
    {
      if (coord.x == 0 || !selection.selectedPixels.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.Left);
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
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.Left, startLoc: coord, endLoc: coord));
        }
      }
      if (coord.x == GetIt.I.get<AppState>().canvasWidth - 1 || !selection.selectedPixels.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.Right);
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
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.Right, startLoc: coord, endLoc: coord));
        }
      }
      if (coord.y == 0 || !selection.selectedPixels.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.Top);
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
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.Top, startLoc: coord, endLoc: coord));
        }
      }
      if (coord.y == GetIt.I.get<AppState>().canvasHeight - 1 || !selection.selectedPixels.contains(CoordinateSetI(x: coord.x, y: coord.y + 1)))
      {
        Iterable<SelectionLine> leftLines = selectionLines.where((x) => x.selectDir == SelectionDirection.Bottom);
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
          selectionLines.add(SelectionLine(selectDir: SelectionDirection.Bottom, startLoc: coord, endLoc: coord));
        }
      }
    }
  }

  void inverse({required final int width, required final int height, final bool notify = true})
  {
    for (int x = 0; x < width; x++)
    {
      for (int y = 0; y < height; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (selection.selectedPixels.contains(coord))
        {
          selection.selectedPixels.remove(coord);
        }
        else
        {
          selection.selectedPixels.add(coord);
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
    selection.selectedPixels.clear();
    _createSelectionLines();
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void selectAll({required final int width, required final int height, final bool notify = true})
  {
    for (int x = 0; x < width; x++)
    {
      for (int y = 0; y < height; y++)
      {
        CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        if (!selection.selectedPixels.contains(coord))
        {
          selection.selectedPixels.add(coord);
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

  void cut({required final LayerState layer, final bool notify = true})
  {
    print("CUT");
    copy(layer: layer, notify: false);
    delete(layer: layer, notify: false);

    deselect(notify: false);

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void delete({required final LayerState layer, final bool notify = true})
  {
    print("DELETE");
    for (final CoordinateSetI coord in selection.selectedPixels)
    {
      layer.data[coord.x][coord.y] = null;
    }

    deselect(notify: false);

    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void copy({required final LayerState layer, final bool notify = true})
  {
    print("COPY");
    clipboard = HashMap();
    for (final CoordinateSetI coord in selection.selectedPixels)
    {
      clipboard![coord] = layer.data[coord.x][coord.y];
    }
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }

  void copyMerged({required final List<LayerState> layers, final bool notify = true})
  {
    print("COPY MERGED");
    clipboard = HashMap();
    for (final CoordinateSetI coord in selection.selectedPixels)
    {
      ColorReference? ref;
      for (int i = 0; i < layers.length; i++)
      {
        if (layers[i].data[coord.x][coord.y] != null)
        {
          ref = layers[i].data[coord.x][coord.y];
          break;
        }
      }
      clipboard![coord] = ref;
    }
    if (notify)
    {
      notifyListeners();
      repaintNotifier.repaint();
    }
  }
}

class SelectionList
{
  Set<CoordinateSetI> selectedPixels = Set<CoordinateSetI>();
  HashMap<CoordinateSetI, ColorReference>? content;

  bool hasContent()
  {
    return content == null;
  }
}

