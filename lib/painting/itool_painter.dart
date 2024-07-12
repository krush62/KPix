import 'dart:collection';
import 'dart:math';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class BorderCoordinateSetI
{
  final CoordinateSetI coord;
  final List<List<CoordinateSetI>> borders;
  BorderCoordinateSetI._({required this.coord, required this.borders});

  factory BorderCoordinateSetI({required bool left, required bool right, required bool top, required bool bottom, required CoordinateSetI coord})
  {
    List<List<CoordinateSetI>> borders = [];
    if (left && right && !top && !bottom)
    {
      borders = [[coord, CoordinateSetI(x: coord.x, y: coord.y + 1)],[CoordinateSetI(x: coord.x + 1, y: coord.y), CoordinateSetI(x: coord.x + 1, y: coord.y + 1)]];
    }
    else if (!left && !right && top && bottom)
    {
      borders = [[coord, CoordinateSetI(x: coord.x + 1, y: coord.y)],[CoordinateSetI(x: coord.x, y: coord.y + 1), CoordinateSetI(x: coord.x + 1, y: coord.y + 1)]];
    }
    else {
      List<CoordinateSetI> path = [];
      final CoordinateSetI tl = coord;
      final CoordinateSetI tr = CoordinateSetI(x: coord.x + 1, y: coord.y);
      final CoordinateSetI br = CoordinateSetI(x: coord.x + 1, y: coord.y + 1);
      final CoordinateSetI bl = CoordinateSetI(x: coord.x, y: coord.y + 1);

      if (top && !right && !bottom && !left) //top
          {
        path.addAll([tl, tr]);
      }
      else if (!top && right && !bottom && !left) //right
          {
        path.addAll([tr, br]);
      }
      else if (!top && !right && bottom && !left) //bottom
          {
        path.addAll([br, bl]);
      }
      else if (!top && !right && !bottom && left) //left
          {
        path.addAll([bl, tl]);
      }
      else if (top && right && !bottom && !left) //tr
          {
        path.addAll([tl, tr, br]);
      }
      else if (!top && right && bottom && !left) //br
          {
        path.addAll([tr, br, bl]);
      }
      else if (!top && !right && bottom && left) //bl
          {
        path.addAll([br, bl, tl]);
      }
      else if (top && !right && !bottom && left) //tl
          {
        path.addAll([bl, tl, tr]);
      }
      else if (!top && right && bottom && left) // - top
          {
        path.addAll([tr, br, bl, tl]);
      }
      else if (top && !right && bottom && left) // - right
          {
        path.addAll([br, bl, tl, tr]);
      }
      else if (top && right && !bottom && left) // - bottom
          {
        path.addAll([bl, tl, tr, br]);
      }
      else if (top && right && bottom && !left) // - left
          {
        path.addAll([tl, tr, br, bl]);
      }
      if (path.isNotEmpty)
      {
        borders = [path];
      }

    }
    return BorderCoordinateSetI._(coord: coord, borders: borders);
  }

}

class StatusBarData
{
  CoordinateSetI? cursorPos;
  CoordinateSetI? dimension;
  CoordinateSetI? diagonal;
  CoordinateSetI? aspectRatio;
  CoordinateSetI? angle;
}

abstract class IToolPainter
{
  final AppState appState = GetIt.I.get<AppState>();
  final ShaderOptions shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final KPixPainterOptions painterOptions;
  final StatusBarData statusBarData = StatusBarData();
  bool hasHistoryData = false;

  IToolPainter({required this.painterOptions});

  void calculate({required DrawingParameters drawParams}){}
  void drawExtras({required DrawingParameters drawParams}){}
  HashMap<CoordinateSetI, ColorReference> getCursorContent({required DrawingParameters drawParams}){return HashMap();}
  HashMap<CoordinateSetI, ColorReference> getToolContent({required DrawingParameters drawParams}){return HashMap();}
  void drawCursorOutline({required DrawingParameters drawParams});
  void setStatusBarData({required DrawingParameters drawParams})
  {
    statusBarData.cursorPos = null;
    statusBarData.dimension = null;
    statusBarData.diagonal = null;
    statusBarData.aspectRatio = null;
    statusBarData.angle = null;
  }



  Set<CoordinateSetI> getRoundSquareContentPoints(final PencilShape shape, final int size, final CoordinateSetI position)
  {
    final CoordinateSetI startPos = CoordinateSetI(x: position.x - ((size - 1) ~/ 2), y: position.y - ((size - 1) ~/ 2));
    final CoordinateSetI endPos = CoordinateSetI(x: position.x + (size ~/ 2), y: position.y + (size ~/ 2));
    final Set<CoordinateSetI> coords = {};
    if (shape == PencilShape.square)
    {
      for (int x = startPos.x; x <= endPos.x; x++)
      {
        for (int y = startPos.y; y <= endPos.y; y++)
        {
          coords.add(CoordinateSetI(x: x, y: y));
        }
      }
    }
    else if (shape == PencilShape.round) {
      final double centerX = (startPos.x + endPos.x + 1) / 2.0;
      final double centerY = (startPos.y + endPos.y + 1) / 2.0;
      final double radiusX = (endPos.x - startPos.x + 1) / 2.0;
      final double radiusY = (endPos.y - startPos.y + 1) / 2.0;

      for (int x = startPos.x; x <= endPos.x; x++) {
        for (int y = startPos.y; y <= endPos.y; y++) {
          double dx = (x + 0.5) - centerX;
          double dy = (y + 0.5) - centerY;
          if ((dx * dx) / (radiusX * radiusX) +
              (dy * dy) / (radiusY * radiusY) <= 1) {
            coords.add(CoordinateSetI(x: x, y: y));
          }
        }
      }
    }
    return coords;
  }



  static List<CoordinateSetI> getBoundaryPath(final Set<CoordinateSetI> coords)
  {
    final List<CoordinateSetI> path = [];
    if (coords.length == 1)
    {
      path.add(coords.last);
      path.add(CoordinateSetI(x: coords.last.x + 1, y: coords.last.y));
      path.add(CoordinateSetI(x: coords.last.x + 1, y: coords.last.y + 1));
      path.add(CoordinateSetI(x: coords.last.x, y: coords.last.y + 1));
    }
    else
    {
      final List<BorderCoordinateSetI> boundaryPoints = [];
      for (final CoordinateSetI coord in coords)
      {
        BorderCoordinateSetI bcoord = BorderCoordinateSetI(
            coord: coord,
            left: !coords.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)),
            right: !coords.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)),
            top: !coords.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)),
            bottom: !coords.contains(CoordinateSetI(x: coord.x, y: coord.y + 1))
        );

        if (bcoord.borders.isNotEmpty)
        {
          boundaryPoints.add(bcoord);
        }
      }





      bool itemAdded = true;
      while (boundaryPoints.isNotEmpty && itemAdded)
      {
        itemAdded = false;
        if (path.isEmpty)
        {
          final BorderCoordinateSetI bPoint = boundaryPoints[0];
          path.addAll(bPoint.borders[0]);
          if (bPoint.borders.length == 1)
          {
            boundaryPoints.remove(bPoint);
          }
          else if (bPoint.borders.length == 2)
          {
            bPoint.borders.removeAt(0);
          }
          itemAdded = true;
        }
        else
        {
          for (int i = 0; i < boundaryPoints.length; i++)
          {
            final BorderCoordinateSetI bPoint = boundaryPoints[i];
            for (int j = 0; j < bPoint.borders.length; j++)
            {
              if (bPoint.borders[j][0] == path[path.length - 1])
              {
                path.addAll(bPoint.borders[j].sublist(1));
                bPoint.borders.removeAt(j);
                itemAdded = true;
                break;
              }
              else if (bPoint.borders[j][bPoint.borders[j].length - 1] == path[0])
              {
                path.insertAll(0, bPoint.borders[j].sublist(0, bPoint.borders[j].length - 1));
                bPoint.borders.removeAt(j);
                itemAdded = true;
                break;
              }
            }
            if (itemAdded)
            {
              if (bPoint.borders.isEmpty)
              {
                boundaryPoints.remove(bPoint);
              }
              break;
            }
          }
        }
      }
    }



    return path;
  }

  HashMap<CoordinateSetI, ColorReference> getPixelsToDraw({required final CoordinateSetI canvasSize, required final LayerState currentLayer, required final Set<CoordinateSetI> coords, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
  {
    final HashMap<CoordinateSetI, ColorReference> pixelMap = HashMap();
    for (final CoordinateSetI coord in coords)
    {
      if (coord.x >= 0 && coord.y >= 0 &&
          coord.x < canvasSize.x &&
          coord.y < canvasSize.y)
      {
        if (!shaderOptions.isEnabled.value) //without shading
            {
          //if no selection and current pixel is different
          if ((selection.selection.isEmpty() && currentLayer.getDataEntry(coord) != selectedColor) ||
              //if selection and selection contains pixel and selection pixel is different
              (!selection.selection.isEmpty() && selection.selection.contains(coord) && selection.selection.getColorReference(coord) != selectedColor))
          {
            pixelMap[coord] = selectedColor;
          }
        }
        //with shading
        else
          //if no selection and pixel is not null
        if ((selection.selection.isEmpty() && currentLayer.getDataEntry(coord) != null) ||
            //if selection and selection contains pixel and pixel is not null
            (!selection.selection.isEmpty() && selection.selection.contains(coord) && selection.selection.getColorReference(coord) != null))
        {
          final ColorReference layerRef = selection.selection.isEmpty() ? currentLayer.getDataEntry(coord)! : selection.selection.getColorReference(coord)!;
          if (layerRef.ramp.uuid == selectedColor.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value)
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              if (layerRef.colorIndex + 1 < layerRef.ramp.colors.length)
              {
                pixelMap[coord] = layerRef.ramp.references[layerRef.colorIndex  + 1];
              }
            }
            else
            {
              if (layerRef.colorIndex > 0)
              {
                pixelMap[coord] = layerRef.ramp.references[layerRef.colorIndex  - 1];
              }
            }
          }
        }
      }
    }
    return pixelMap;
  }

  HashMap<CoordinateSetI, ColorReference> getStampPixelsToDraw({required final CoordinateSetI canvasSize, required final LayerState currentLayer, required final HashMap<CoordinateSetI, int> stampData, required final SelectionState selection, required final ShaderOptions shaderOptions, required final ColorReference selectedColor})
  {
    final HashMap<CoordinateSetI, ColorReference> pixelMap = HashMap();
    for (final MapEntry<CoordinateSetI, int> stampEntry in stampData.entries)
    {
      final CoordinateSetI coord = stampEntry.key;

      if (coord.x >= 0 && coord.y >= 0 &&
          coord.x < canvasSize.x &&
          coord.y < canvasSize.y)
      {
        if (!shaderOptions.isEnabled.value) //without shading
        {
          final int index = min(max(selectedColor.colorIndex + stampEntry.value, 0), selectedColor.ramp.colors.length - 1);
          final ColorReference drawColor = selectedColor.ramp.references[index];
          //if no selection and current pixel is different
          if ((selection.selection.isEmpty() && currentLayer.getDataEntry(coord) != drawColor) ||
              //if selection and selection contains pixel and selection pixel is different
              (!selection.selection.isEmpty() && selection.selection.contains(coord) && selection.selection.getColorReference(coord) != drawColor))
          {
            pixelMap[coord] = drawColor;
          }
        }
        //with shading
        else
          //if no selection and pixel is not null
        if ((selection.selection.isEmpty() && currentLayer.getDataEntry(coord) != null) ||
            //if selection and selection contains pixel and pixel is not null
            (!selection.selection.isEmpty() && selection.selection.contains(coord) && selection.selection.getColorReference(coord) != null))
        {
          final ColorReference layerRef = selection.selection.isEmpty() ? currentLayer.getDataEntry(coord)! : selection.selection.getColorReference(coord)!;
          if (layerRef.ramp.uuid == selectedColor.ramp.uuid || !shaderOptions.onlyCurrentRampEnabled.value) //all ramps
          {
            if (shaderOptions.shaderDirection.value == ShaderDirection.right)
            {
              final int index = min(max(layerRef.colorIndex + stampEntry.value + 1, 0), layerRef.ramp.colors.length - 1);
              pixelMap[coord] = layerRef.ramp.references[index];
            }
            else
            {
              final int index = min(max(layerRef.colorIndex - stampEntry.value - 1, 0), layerRef.ramp.colors.length - 1);
              pixelMap[coord] = layerRef.ramp.references[index];
            }
          }
        }
      }
    }
    return pixelMap;
  }
}