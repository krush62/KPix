import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/layer_widget.dart';

class KPixPainterOptions
{
  final double cursorSize;
  final double cursorBorderWidth;
  final double selectionSolidStrokeWidth;
  final double pixelExtension;
  final double checkerBoardDivisor;
  final double checkerBoardSizeMin;
  final double checkerBoardSizeMax;
  final double selectionPolygonCircleRadius;
  final double selectionStrokeWidthLarge;
  final double selectionStrokeWidthSmall;


  KPixPainterOptions({
    required this.cursorSize,
    required this.cursorBorderWidth,
    required this.selectionSolidStrokeWidth,
    required this.pixelExtension,
    required this.checkerBoardDivisor,
    required this.checkerBoardSizeMin,
    required this.checkerBoardSizeMax,
    required this.selectionPolygonCircleRadius,
    required this.selectionStrokeWidthLarge,
    required this.selectionStrokeWidthSmall,
  });
}

class DrawingParameters
{
  final Offset offset;
  final Canvas canvas;
  final Paint paint;
  final int pixelSize;
  final CoordinateSetI canvasSize;
  final CoordinateSetI scaledCanvasSize;
  final CoordinateSetI drawingStart;
  final CoordinateSetI drawingEnd;
  final Size drawingSize;
  final CoordinateSetD? cursorPos;
  final bool primaryDown;
  final Offset primaryPressStart;
  final LayerState currentLayer;
  DrawingParameters({
    required this.offset,
    required this.canvas,
    required this.paint,
    required this.pixelSize,
    required this.canvasSize,
    required this.drawingSize,
    required this.cursorPos,
    required this.primaryDown,
    required this.primaryPressStart,
    required this.currentLayer
}) :
        scaledCanvasSize = CoordinateSetI(x: canvasSize.x * pixelSize, y: canvasSize.y * pixelSize),
        drawingStart = CoordinateSetI(x: offset.dx > 0 ? 0 : -(offset.dx / pixelSize).ceil(), y: offset.dy > 0 ? 0 : -(offset.dy / pixelSize).ceil()),
        drawingEnd = CoordinateSetI(x: offset.dx + (canvasSize.x * pixelSize) < drawingSize.width ? canvasSize.x : canvasSize.x - ((offset.dx + (canvasSize.x * pixelSize) - drawingSize.width) / pixelSize).floor(),
                                    y: offset.dy + (canvasSize.y) * pixelSize < drawingSize.height ? canvasSize.y : canvasSize.y - ((offset.dy + (canvasSize.y * pixelSize) - drawingSize.height) / pixelSize).floor());
}

class KPixPainter extends CustomPainter
{
  final AppState appState;
  final ValueNotifier<Offset> offset;
  final ValueNotifier<CoordinateSetD?> coords;
  final ValueNotifier<bool> isDragging;
  final ValueNotifier<bool> primaryDown;
  final ValueNotifier<Offset> primaryPressStart;
  final KPixPainterOptions options = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final Color checkerboardColor1;
  final Color checkerboardColor2;
  late Map<ToolType, IToolPainter> toolPainterMap;
  Size? latestSize;


  KPixPainter({
    required this.appState,
    required this.offset,
    required this.checkerboardColor1,
    required this.checkerboardColor2,
    required this.coords,
    required this.primaryDown,
    required this.primaryPressStart,
    required this.isDragging})
      : super(repaint: appState.repaintNotifier)
  {
    toolPainterMap = {
      ToolType.select: SelectionPainter(painterOptions: options),
      ToolType.erase: EraserPainter(painterOptions: options),
      ToolType.pencil: PencilPainter(painterOptions: options),
      ToolType.pick: ColorPickPainter(painterOptions: options),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {

    latestSize = size;
    DrawingParameters drawParams = DrawingParameters(
        offset: offset.value,
        canvas: canvas,
        paint: Paint(),
        pixelSize: appState.getZoomFactor(),
        canvasSize: CoordinateSetI(x: appState.canvasWidth, y: appState.canvasHeight),
        drawingSize: size,
        cursorPos: coords.value,
        primaryDown: primaryDown.value,
        primaryPressStart: primaryPressStart.value,
        currentLayer: appState.currentLayer.value!
        );


    //TODO this is too slow (solid color?)
    _drawCheckerboard(drawParams: drawParams);
    _calculateTool(drawParams: drawParams);
    _drawLayers(drawParams: drawParams);
    _drawSelection(drawParams: drawParams);
    _drawToolOverlay(drawParams: drawParams);
    _drawToolExtras(drawParams: drawParams);
    _drawCursor(drawParams: drawParams);
  }

  void _drawSelection({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = options.selectionSolidStrokeWidth;

    if (!appState.selectionState.selection.isEmpty())
    {
      for (final SelectionLine line in appState.selectionState.selectionLines) {
        if (line.selectDir == SelectionDirection.left) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2),
              Offset(
                  offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy + (line.startLoc.y * pxlSzDbl)),
              Offset(
                  offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.right) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2),
              Offset(
                  offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      pxlSzDbl -
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy + (line.startLoc.y * pxlSzDbl)),
              Offset(
                  offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl -
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.top) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2),
              Offset(
                  offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx + (line.startLoc.x * pxlSzDbl),
                  offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      options.selectionSolidStrokeWidth / 2),
              Offset(
                  offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl,
                  offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.bottom) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2),
              Offset(
                  offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2,
                  offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  offset.value.dx + (line.startLoc.x * pxlSzDbl),
                  offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      pxlSzDbl -
                      options.selectionSolidStrokeWidth / 2),
              Offset(
                  offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl,
                  offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl -
                      options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
        }
      }
    }
  }

  void _calculateTool({required final DrawingParameters drawParams})
  {
    IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
    toolPainter?.calculate(drawParams: drawParams);
  }

  void _drawToolOverlay({required final DrawingParameters drawParams})
  {
    if (coords.value != null)
    {
      IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
      toolPainter?.drawTool(drawParams: drawParams);
    }
  }

  void _drawToolExtras({required final DrawingParameters drawParams})
  {
    IToolPainter? toolPainter = toolPainterMap[appState.selectedTool.value];
    if (toolPainter != null)
    {
      toolPainter.drawExtras(
          drawParams: drawParams);
    }
  }

  void _drawCursor({required final DrawingParameters drawParams})
  {
    if (coords.value != null)
    {
      if (!isDragging.value && _isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!))
      {
        toolPainterMap[appState.selectedTool.value]?.drawCursor(drawParams: drawParams);
      }
      else
      {
        drawParams.paint.color = checkerboardColor1;
        drawParams.canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), options.cursorSize + options.cursorBorderWidth, drawParams.paint);
        drawParams.paint.color = checkerboardColor2;
        drawParams.canvas.drawCircle(Offset(coords.value!.x, coords.value!.y), options.cursorSize, drawParams.paint);
      }
    }
  }

  void _drawLayers({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    final List<LayerState> layers = appState.layers.value;
    for (int x = drawParams.drawingStart.x; x < drawParams.drawingEnd.x; x++)
    {
      for (int y = drawParams.drawingStart.y; y < drawParams.drawingEnd.y; y++)
      {
        for (int i = 0; i < layers.length; i++)
        {
          if (layers[i].visibilityState.value == LayerVisibilityState.visible) {
            bool foundInSelection = false;
            if (layers[i].isSelected.value)
            {
              ColorReference? selColor = appState.selectionState.selection.getColorReference(CoordinateSetI(x: x, y: y));
              if (selColor != null)
              {
                foundInSelection = true;
                drawParams.paint.color = selColor.getIdColor().color;
                drawParams.canvas.drawRect(Rect.fromLTWH(offset.value.dx + (x * pxlSzDbl) - options.pixelExtension,
                    offset.value.dy + (y * pxlSzDbl) - options.pixelExtension, pxlSzDbl + (2.0 * options.pixelExtension), pxlSzDbl + (2.0 * options.pixelExtension)), drawParams.paint);
              }
            }
            ColorReference? layerColor = layers[i].data[x][y];
            if (layerColor != null && !foundInSelection) {
              drawParams.paint.color = layerColor.getIdColor().color;
              drawParams.canvas.drawRect(Rect.fromLTWH(offset.value.dx + (x * pxlSzDbl) - options.pixelExtension,
                  offset.value.dy + (y * pxlSzDbl) - options.pixelExtension, pxlSzDbl + (2.0 * options.pixelExtension), pxlSzDbl + (2.0 * options.pixelExtension)), drawParams.paint);
              break;
            }
            if (foundInSelection)
            {
              break;
            }
          }
        }
      }
    }
  }

  void _drawCheckerboard({required final DrawingParameters drawParams})
  {
    bool rowFlip = false;
    bool colFlip = false;
   double cbSizeDbl = (drawParams.pixelSize / options.checkerBoardDivisor).clamp(options.checkerBoardSizeMin, options.checkerBoardSizeMax);

    for (int i = drawParams.drawingStart.x * drawParams.pixelSize; i < drawParams.drawingEnd.x * drawParams.pixelSize; i += cbSizeDbl.floor())
    {
      colFlip = rowFlip;
      for (int j = drawParams.drawingStart.y * drawParams.pixelSize; j < drawParams.drawingEnd.y * drawParams.pixelSize; j += cbSizeDbl.floor())
      {
        drawParams.paint.color = colFlip ? checkerboardColor1 : checkerboardColor2;
        double width = cbSizeDbl;
        double height = cbSizeDbl;
        if (i + cbSizeDbl > drawParams.scaledCanvasSize.x)
        {
          width = drawParams.scaledCanvasSize.x - i.toDouble();
        }

        if (j + cbSizeDbl > drawParams.scaledCanvasSize.y)
        {
          height = drawParams.scaledCanvasSize.y - j.toDouble();
        }

        drawParams.canvas.drawRect(
          Rect.fromLTWH(offset.value.dx + i, offset.value.dy + j , width, height),
          drawParams.paint,
        );

        colFlip = !colFlip;
      }
      rowFlip = !rowFlip;
    }
  }


  static int getClosestPixel({required double value, required double pixelSize})
  {
    final double remainder = value % pixelSize;
    double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }




  static bool _isOnCanvas({required final DrawingParameters drawParams, required final CoordinateSetD testCoords})
  {
    bool isOn = false;
    if (testCoords.x >= drawParams.offset.dx && testCoords.x < drawParams.offset.dx + drawParams.scaledCanvasSize.x && testCoords.y >= drawParams.offset.dy && testCoords.y < drawParams.offset.dy + drawParams.scaledCanvasSize.y)
    {
      isOn = true;
    }
    return isOn;
  }



  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

