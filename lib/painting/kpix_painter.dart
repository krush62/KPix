import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/fill_painter.dart';
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
  final int checkerBoardSize;
  final double selectionPolygonCircleRadius;
  final double selectionStrokeWidthLarge;
  final double selectionStrokeWidthSmall;


  KPixPainterOptions({
    required this.cursorSize,
    required this.cursorBorderWidth,
    required this.selectionSolidStrokeWidth,
    required this.pixelExtension,
    required this.checkerBoardSize,
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
  final AppState _appState;
  final ValueNotifier<Offset> _offset;
  final ValueNotifier<CoordinateSetD?> _coords;
  final ValueNotifier<bool> _isDragging;
  final ValueNotifier<bool> _primaryDown;
  final ValueNotifier<Offset> _primaryPressStart;
  final KPixPainterOptions _options = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final Color checkerboardColor1;
  final Color checkerboardColor2;
  late Map<ToolType, IToolPainter> toolPainterMap;
  late Size latestSize = const Size(0,0);
  IToolPainter? _toolPainter;
  late ui.Image _checkerboardImage;


  KPixPainter({
    required AppState appState,
    required ValueNotifier<Offset> offset,
    required this.checkerboardColor1,
    required this.checkerboardColor2,
    required ValueNotifier<CoordinateSetD?> coords,
    required ValueNotifier<bool> primaryDown,
    required ValueNotifier<Offset> primaryPressStart,
    required ValueNotifier<bool> isDragging})
      : _appState = appState, _offset = offset, _coords = coords, _isDragging = isDragging, _primaryDown = primaryDown, _primaryPressStart = primaryPressStart, super(repaint: appState.repaintNotifier)
  {
    toolPainterMap = {
      ToolType.select: SelectionPainter(painterOptions: _options),
      ToolType.erase: EraserPainter(painterOptions: _options),
      ToolType.pencil: PencilPainter(painterOptions: _options),
      ToolType.pick: ColorPickPainter(painterOptions: _options),
      ToolType.fill: FillPainter(painterOptions: _options),
    };
  }

  @override
  void paint(Canvas canvas, Size size)
  {
    _toolPainter = toolPainterMap[_appState.selectedTool.value];
    if (size != latestSize)
    {
      latestSize = size;
      _createCheckerboard();
    }

    DrawingParameters drawParams = DrawingParameters(
        offset: _offset.value,
        canvas: canvas,
        paint: Paint(),
        pixelSize: _appState.getZoomFactor(),
        canvasSize: CoordinateSetI(x: _appState.canvasWidth, y: _appState.canvasHeight),
        drawingSize: size,
        cursorPos: _coords.value,
        primaryDown: _primaryDown.value,
        primaryPressStart: _primaryPressStart.value,
        currentLayer: _appState.currentLayer.value!
        );


    _drawCheckerboard(drawParams: drawParams);
    _calculateTool(drawParams: drawParams);
    _drawLayers(drawParams: drawParams);
    _drawSelection(drawParams: drawParams);
    _drawToolExtras(drawParams: drawParams);
    _drawCursor(drawParams: drawParams);
  }

  void _drawSelection({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = _options.selectionSolidStrokeWidth;

    if (!_appState.selectionState.selection.isEmpty())
    {
      for (final SelectionLine line in _appState.selectionState.selectionLines) {
        if (line.selectDir == SelectionDirection.left) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.startLoc.y * pxlSzDbl)),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.right) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.startLoc.y * pxlSzDbl)),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy + (line.endLoc.y * pxlSzDbl) + pxlSzDbl),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.top) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx + (line.startLoc.x * pxlSzDbl),
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
        } else if (line.selectDir == SelectionDirection.bottom) {
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx +
                      (line.startLoc.x * pxlSzDbl) -
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx +
                      (line.endLoc.x * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl +
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawLine(
              Offset(
                  _offset.value.dx + (line.startLoc.x * pxlSzDbl),
                  _offset.value.dy +
                      (line.startLoc.y * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2),
              Offset(
                  _offset.value.dx + (line.endLoc.x * pxlSzDbl) + pxlSzDbl,
                  _offset.value.dy +
                      (line.endLoc.y * pxlSzDbl) +
                      pxlSzDbl -
                      _options.selectionSolidStrokeWidth / 2),
              drawParams.paint);
        }
      }
    }
  }

  void _calculateTool({required final DrawingParameters drawParams})
  {
    IToolPainter? toolPainter = toolPainterMap[_appState.selectedTool.value];
    toolPainter?.calculate(drawParams: drawParams);
  }

  void _drawToolExtras({required final DrawingParameters drawParams})
  {
    if (_toolPainter != null)
    {
      _toolPainter!.drawExtras(
          drawParams: drawParams);
    }
  }

  void _drawCursor({required final DrawingParameters drawParams})
  {
    if (_coords.value != null)
    {
      if (!_isDragging.value && isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!) && _toolPainter != null)
      {
        _toolPainter!.drawCursorOutline(drawParams: drawParams);
      }
      else
      {
        drawParams.paint.color = checkerboardColor1;
        drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), _options.cursorSize + _options.cursorBorderWidth, drawParams.paint);
        drawParams.paint.color = checkerboardColor2;
        drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), _options.cursorSize, drawParams.paint);
      }
    }
  }

  void _drawLayers({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();

    final List<LayerState> layers = _appState.layers.value;
    for (int i = layers.length - 1; i >= 0; i--)
    {
      if (layers[i].visibilityState.value == LayerVisibilityState.visible)
      {

        if (layers[i].raster != null)
        {
          paintImage(
              canvas: drawParams.canvas,
              rect: ui.Rect.fromLTWH(drawParams.offset.dx, drawParams.offset.dy,
                  drawParams.scaledCanvasSize.x.toDouble(),
                  drawParams.scaledCanvasSize.y.toDouble()),
              image: layers[i].raster!,
              scale: 1.0 / pxlSzDbl,
              fit: BoxFit.none,
              alignment: Alignment.topLeft,
              filterQuality: FilterQuality.none);
        }

        if (layers[i].isSelected.value)
        {
          final HashMap<CoordinateSetI, ColorReference> selectedLayerCursorContent = _toolPainter != null ? _toolPainter!.getCursorContent(drawPars: drawParams) : HashMap();
          final HashMap<CoordinateSetI, ColorReference> toolContent = _toolPainter != null ? _toolPainter!.getToolContent(drawPars: drawParams) : HashMap();
          for (int x = drawParams.drawingStart.x; x < drawParams.drawingEnd.x; x++)
          {
            for (int y = drawParams.drawingStart.y; y < drawParams.drawingEnd.y; y++)
            {
              Color? drawColor;
              //DRAW CURSOR CONTENT PIXEL
              final selLayerCoord = CoordinateSetI(x: x, y: y);
              if (selectedLayerCursorContent.keys.contains(selLayerCoord))
              {
                drawColor = selectedLayerCursorContent[selLayerCoord]!.getIdColor().color;
              }

              //DRAW TOOL CONTENT
              if (drawColor == null && toolContent.keys.contains(selLayerCoord))
              {
                drawColor = toolContent[selLayerCoord]!.getIdColor().color;
              }

              //DRAW SELECTION PIXEL
              if (drawColor == null)
              {
                ColorReference? selColor = _appState.selectionState.selection.getColorReference(CoordinateSetI(x: x, y: y));
                if (selColor != null)
                {
                  drawColor = selColor.getIdColor().color;
                }
              }
              if (drawColor != null)
              {
                drawParams.paint.color = drawColor;
                drawParams.canvas.drawRect(Rect.fromLTWH(
                    _offset.value.dx + (x * pxlSzDbl) - _options.pixelExtension,
                    _offset.value.dy + (y * pxlSzDbl) - _options.pixelExtension,
                    pxlSzDbl + (2.0 * _options.pixelExtension),
                    pxlSzDbl + (2.0 * _options.pixelExtension)),
                    drawParams.paint);
              }
            }
          }
        }
      }
    }

  }

  void _createCheckerboard()
  {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();
    bool rowFlip = false;
    bool colFlip = false;



    for (int x = 0; x < latestSize.width; x += _options.checkerBoardSize)
    {
      colFlip = rowFlip;
      for (int y = 0; y < latestSize.height; y += _options.checkerBoardSize)
      {
        paint.color = colFlip ? checkerboardColor1 : checkerboardColor2;
        int width = _options.checkerBoardSize;
        int height = _options.checkerBoardSize;
        if (x + _options.checkerBoardSize > latestSize.width.floor())
        {
          width = latestSize.width.floor() - x;
        }

        if (y + _options.checkerBoardSize > latestSize.height.floor())
        {
          height = latestSize.height.floor() - y;
        }
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble() , width.toDouble(), height.toDouble()),
          paint,
        );
        colFlip = !colFlip;
      }
      rowFlip = !rowFlip;
    }
    final ui.Picture picture = recorder.endRecording();
    _checkerboardImage = picture.toImageSync(latestSize.width.floor(), latestSize.height.floor());
  }

  void _drawCheckerboard({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();
    paintImage(
        canvas: drawParams.canvas,
        rect: ui.Rect.fromLTWH(drawParams.offset.dx, drawParams.offset.dy, drawParams.scaledCanvasSize.x.toDouble(), drawParams.scaledCanvasSize.y.toDouble()),
        image: _checkerboardImage,
        scale: 1.0 / pxlSzDbl,
        fit: BoxFit.none,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.none);
  }


  static int getClosestPixel({required double value, required double pixelSize})
  {
    final double remainder = value % pixelSize;
    double lowerMultiple = value - remainder;
    return (lowerMultiple / pixelSize).round();
  }




  static bool isOnCanvas({required final DrawingParameters drawParams, required final CoordinateSetD testCoords})
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

