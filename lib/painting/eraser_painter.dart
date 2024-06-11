import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

class EraserPainter extends IToolPainter
{
  final EraserOptions options = GetIt.I.get<PreferenceManager>().toolOptions.eraserOptions;

  EraserPainter({required super.painterOptions});

  @override
  void drawCursor({required DrawingParameters drawParams})
  {
    final CoordinateSetI cursorPosNorm = CoordinateSetI(
        x: KPixPainter.getClosestPixel(
            value: drawParams.cursorPos!.x - drawParams.offset.dx,
            pixelSize: drawParams.pixelSize.toDouble())
            .round(),
        y: KPixPainter.getClosestPixel(
            value: drawParams.cursorPos!.y - drawParams.offset.dy,
            pixelSize: drawParams.pixelSize.toDouble())
            .round());
    List<CoordinateSetI> pathPoints = _getEraserPath(options.shape.value, options.size.value, cursorPosNorm);

    Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[i].y * drawParams.pixelSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[i + 1].y * drawParams.pixelSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * drawParams.pixelSize) + drawParams.offset.dx, (pathPoints[0].y * drawParams.pixelSize) + drawParams.offset.dy);
      }
    }

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = Colors.black;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = Colors.white;
    drawParams.canvas.drawPath(path, drawParams.paint);

    if (drawParams.primaryDown && drawParams.currentLayer.lockState.value != LayerLockState.locked && drawParams.currentLayer.visibilityState.value != LayerVisibilityState.hidden)
    {
      final CoordinateSetI startPos = CoordinateSetI(x: cursorPosNorm.x - ((options.size.value - 1) ~/ 2), y: cursorPosNorm.y - ((options.size.value - 1) ~/ 2));
      final CoordinateSetI endPos = CoordinateSetI(x: cursorPosNorm.x + (options.size.value ~/ 2), y: cursorPosNorm.y + (options.size.value ~/ 2));
      List<CoordinateSetI> content = _getContentPoints(startPos, endPos, options.shape.value);
      final SelectionState selection = GetIt.I.get<AppState>().selectionState;
      for (final CoordinateSetI coord in content)
      {
        if (coord.x >= 0 && coord.y >= 0 &&
            coord.x < drawParams.canvasSize.x &&
            coord.y < drawParams.canvasSize.y) {
          if (selection.selection.isEmpty()) {
            if (drawParams.currentLayer.data[coord.x][coord.y] != null) {
              drawParams.currentLayer.data[coord.x][coord.y] = null;
            }
          }
          else {
            selection.selection.deleteDirectly(coord);
          }
        }
      }
    }
  }

  @override
  void drawExtras({required DrawingParameters drawParams}) {
    //nothing to do
  }

  @override
  void drawTool({required DrawingParameters drawParams})
  {

  }



  List<CoordinateSetI> _getEraserPath(final EraserShape shape, final int size, final CoordinateSetI position)
  {
    List<CoordinateSetI> pathList = [];
    final CoordinateSetI startPos = CoordinateSetI(x: position.x - ((size - 1) ~/ 2), y: position.y - ((size - 1) ~/ 2));
    final CoordinateSetI endPos = CoordinateSetI(x: position.x + (size ~/ 2), y: position.y + (size ~/ 2));
    if (shape == EraserShape.square || size < 4)
    {
      pathList.add(startPos);
      pathList.add(CoordinateSetI(x: endPos.x + 1, y: startPos.y));
      pathList.add(CoordinateSetI(x: endPos.x + 1, y: endPos.y + 1));
      pathList.add(CoordinateSetI(x: startPos.x, y: endPos.y + 1));
    }
    else if (shape == EraserShape.round)
    {
      pathList = _getBoundaryPath(_getContentPoints(startPos, endPos, shape));
    }


    return pathList;
  }

  List<CoordinateSetI> _getContentPoints(final CoordinateSetI startPos, final CoordinateSetI endPos, final EraserShape shape)
  {
    final List<CoordinateSetI> coords = [];
    if (shape == EraserShape.square)
    {
      for (int x = startPos.x; x <= endPos.x; x++)
      {
        for (int y = startPos.y; y <= endPos.y; y++)
        {
          coords.add(CoordinateSetI(x: x, y: y));
        }
      }
    }
    else if (shape == EraserShape.round) {
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

  List<CoordinateSetI> _getBoundaryPath(final List<CoordinateSetI> coords)
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


    final List<CoordinateSetI> path = [];


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
    };
    return path;
  }
}

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