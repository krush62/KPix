import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/selection_bar_widget.dart';
import 'package:uuid/uuid.dart';


class RepaintNotifier extends ChangeNotifier
{
  void repaint()
  {
    notifyListeners();
  }
}

class AppState
{
  final ValueNotifier<ToolType> selectedTool = ValueNotifier(ToolType.pencil);
  late IToolOptions currentToolOptions;
  final ValueNotifier<List<KPalRampData>> colorRamps = ValueNotifier([]);
  final Map<ToolType, bool> _selectionMap = {};
  final ValueNotifier<IdColor?> selectedColor = ValueNotifier(IdColor(color: Colors.black, uuid: ""));
  final ValueNotifier<List<LayerState>> layers = ValueNotifier([]);
  final RepaintNotifier repaintNotifier = RepaintNotifier();
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();


  static final List<int> _zoomLevels = [100, 200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2400, 2800, 3200, 4800, 6400];
  int _zoomLevelIndex = 0;

  //StatusBar
  final ValueNotifier<String?> statusBarDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarCursorPositionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarZoomFactorString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDiagonalString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAspectRatioString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAngleString = ValueNotifier(null);

  int canvasWidth = 0;
  int canvasHeight = 0;
  late SelectionState selectionState = SelectionState(repaintNotifier: repaintNotifier);

  AppState()
  {
    for (ToolType toolType in toolList.keys)
    {
      _selectionMap[toolType] = false;
    }
    setToolSelection(ToolType.pencil);
    setStatusBarZoomFactor(getZoomLevel());

    //TODO TEMP
    setStatusBarDimensions(200, 400);

  }

  void setCanvasDimensions({required int width, required int height})
  {
    canvasWidth = width;
    canvasHeight = height;
  }

  int getZoomLevel()
  {
    return _zoomLevels[_zoomLevelIndex];
  }

  void increaseZoomLevel()
  {
    if (_zoomLevelIndex < _zoomLevels.length - 1)
    {
      _zoomLevelIndex++;
      setStatusBarZoomFactor(getZoomLevel());
    }
  }

  void decreaseZoomLevel()
  {
    if (_zoomLevelIndex > 0)
    {
      _zoomLevelIndex--;
      setStatusBarZoomFactor(getZoomLevel());
      //shouldRepaint.value = true;
    }
  }

  void setZoomLevelByDistance(final int startZoomLevel, final int steps)
  {
    if (steps != 0)
    {
      int endIndex = _zoomLevels.indexOf(startZoomLevel) + steps;
      if (endIndex < _zoomLevels.length && endIndex >= 0 && endIndex != _zoomLevelIndex)
      {
         _zoomLevelIndex = endIndex;
         setStatusBarZoomFactor(getZoomLevel());
      }
    }
  }



  void deleteRamp(final KPalRampData ramp)
  {
    IdColor? col = getSelectedColorFromRampByUuid(ramp);
    if (col != null)
    {
      selectedColor.value = null;
    }
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    rampDataList.remove(ramp);
    colorRamps.value = rampDataList;
  }

  void updateRamp(final KPalRampData ramp)
  {
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    colorRamps.value = rampDataList;
    IdColor? col = getSelectedColorFromRampByUuid(ramp);
    if (col != null)
    {
      selectedColor.value = col;
    }
    repaintNotifier.repaint();
  }

  IdColor? getSelectedColorFromRampByUuid(final KPalRampData ramp)
  {
    IdColor? col;
    for (int j = 0; j < ramp.colors.length; j++)
    {
      if (selectedColor.value != null && ramp.colors[j].value.uuid == selectedColor.value!.uuid)
      {
        col = ramp.colors[j].value;
        break;
      }
    }
    return col;
  }


  void addNewRamp()
  {
    const Uuid uuid = Uuid();
    List<KPalRampData> rampDataList = List<KPalRampData>.from(colorRamps.value);
    rampDataList.add(
      KPalRampData(
        uuid: uuid.v1(),
        settings: KPalRampSettings(
          constraints: prefs.kPalConstraints
        )
      )
    );
    colorRamps.value = rampDataList;
  }

  LayerState addNewLayer()
  {
    List<LayerState> layerList = [];
    LayerState newLayer = LayerState(width: canvasWidth, height: canvasHeight, color: Colors.primaries[Random().nextInt(Colors.primaries.length)]);
    layerList.add(newLayer);
    layerList.addAll(layers.value);
    layers.value = layerList;
    return newLayer;
  }

  void changeLayerOrder(final LayerState state, final int newPosition)
  {
    int sourcePosition = -1;
    for (int i = 0; i < layers.value.length; i++)
    {
       if (layers.value[i] == state)
       {
          sourcePosition = i;
          break;
       }
    }

    if (sourcePosition != newPosition && (sourcePosition + 1) != newPosition)
    {
      List<LayerState> stateList = List<LayerState>.from(layers.value);
      stateList.removeAt(sourcePosition);
      if (newPosition > sourcePosition) {
        stateList.insert(newPosition - 1, state);
      }
      else
        {
          stateList.insert(newPosition, state);
        }
      layers.value = stateList;
    }
  }

  void addNewLayerPressed()
  {
    addNewLayer();
  }

  LayerState? getSelectedLayer()
  {
    LayerState? selectedLayer;
    for (final LayerState state in layers.value)
    {
      if (state.isSelected.value)
      {
        selectedLayer = state;
      }
    }
    return selectedLayer;
  }

  void layerSelected(final LayerState selectedState)
  {
    for (final LayerState state in layers.value)
    {
      state.isSelected.value = state == selectedState;
    }
  }

  void layerDeleted(final LayerState deleteState)
  {
    if (layers.value.length > 1)
    {
      List<LayerState> stateList = [];
      int foundIndex = 0;
      for (int i = 0; i < layers.value.length; i++)
      {
        if (layers.value[i] != deleteState)
        {
          stateList.add(layers.value[i]);
        }
        else
        {
          foundIndex = i;
        }
      }

      if (foundIndex > 0)
      {
        stateList[foundIndex - 1].isSelected.value = true;
      }
      else
      {
        stateList[0].isSelected.value = true;
      }

      layers.value = stateList;
    }
  }

  void layerMerged(final LayerState mergeState)
  {
    //TODO
    print("MERGE ME");

    //shouldRepaint.value= true;
  }

  void layerDuplicated(final LayerState duplicateState)
  {
    List<LayerState> stateList = [];
    for (int i = 0; i < layers.value.length; i++)
    {
      if (layers.value[i] == duplicateState)
      {
        LayerState layerState = LayerState(width: canvasWidth, height: canvasHeight, color: layers.value[i].color.value);
        layerState.lockState.value = layers.value[i].lockState.value;
        layerState.visibilityState.value = layers.value[i].visibilityState.value;
        stateList.add(layerState);
      }
      stateList.add(layers.value[i]);
    }
    layers.value = stateList;
    //shouldRepaint.value = true;
  }

  void colorSelected(final IdColor color)
  {
    selectedColor.value = color;
  }


  void setStatusBarDimensions(final int width, final int height)
  {
    statusBarDimensionString.value = "$width,$height";
  }

  void hideStatusBarDimension()
  {
    statusBarDimensionString.value = null;
  }

  void setStatusBarCursorPosition(final CoordinateSetD coords)
  {
    statusBarCursorPositionString.value = "${coords.x.toStringAsFixed(1)},${coords.y.toStringAsFixed(1)}";
  }

  void hideStatusBarCursorPosition()
  {
    statusBarCursorPositionString.value = null;
  }

  void setStatusBarZoomFactor(final int zoomFactor)
  {
    statusBarZoomFactorString.value = "$zoomFactor%";
  }

  void hideStatusBarZoomFactor()
  {
    statusBarZoomFactorString.value = null;
  }

  void setStatusBarToolDimension(final int x1, final int y1, final int x2, int y2)
  {
    final int width = (x1 - x2).abs();
    final int height = (y1 - y2).abs();
    statusBarToolDimensionString.value = "$width,$height";
  }

  void hideStatusBarToolDimension()
  {
    statusBarToolDimensionString.value = null;
  }

  void setStatusBarToolDiagonal(final int x1, final int y1, final int x2, int y2)
  {
    final int width = (x1 - x2).abs();
    final int height = (y1 - y2).abs();
    final double result = sqrt((width * width).toDouble() + (height * height).toDouble());
    statusBarToolDiagonalString.value = result.toStringAsFixed(1);  }

  void hideStatusBarToolDiagonal()
  {
    statusBarToolDiagonalString.value = null;
  }

  void setStatusBarToolAspectRatio(final int x1, final int y1, final int x2, int y2)
  {
    final int width = (x1 - x2).abs();
    final int height = (y1 - y2).abs();
    final int divisor = Helper.gcd(width, height);
    final int reducedWidth = divisor != 0 ? width ~/ divisor : 0;
    final int reducedHeight = divisor != 0 ? height ~/ divisor : 0;
    statusBarToolAspectRatioString.value = '$reducedWidth:$reducedHeight';
  }

  void hideStatusBarToolAspectRatio()
  {
    statusBarToolAspectRatioString.value = null;
  }

  void setStatusBarToolAngle(final int x1, final int y1, final int x2, final int y2)
  {
    double angle = Helper.calculateAngle(x1, y1, x2, y2);
    statusBarToolAngleString.value = "${angle.toStringAsFixed(1)}°";
  }

  void hideStatusBarToolAngle()
  {
    statusBarToolAngleString.value = null;
  }

  //TODO TEMP
  void changeTool(ToolType t)
  {
    print("ChangeTool");
  }

  void setToolSelection(final ToolType tool)
  {

    for (final ToolType k in _selectionMap.keys)
    {
      final bool shouldSelect = (k == tool);
      if (_selectionMap[k] != shouldSelect)
      {
        _selectionMap[k] = shouldSelect;
      }

    }
    selectedTool.value = tool;
    currentToolOptions = prefs.toolOptions.toolOptionMap[selectedTool.value]!;
  }

  bool toolIsSelected(final ToolType tool)
  {
    return _selectionMap[tool] ?? false;
  }
}

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
    selectionLines.clear();
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


