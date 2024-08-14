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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/color_pick_painter.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/fill_painter.dart';
import 'package:kpix/painting/font_painter.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/line_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/selection_painter.dart';
import 'package:kpix/painting/shape_painter.dart';
import 'package:kpix/painting/spray_can_painter.dart';
import 'package:kpix/painting/stamp_painter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/typedefs.dart';
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
  final bool secondaryDown;
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
    required this.secondaryDown,
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
  final ValueNotifier<bool> _stylusLongMoveStarted;
  final ValueNotifier<bool> _stylusLongMoveVertical;
  final ValueNotifier<bool> _stylusLongMoveHorizontal;
  final ValueNotifier<bool> _primaryDown;
  final ValueNotifier<bool> _secondaryDown;
  final ValueNotifier<Offset> _primaryPressStart;
  final KPixPainterOptions _options = GetIt.I.get<PreferenceManager>().kPixPainterOptions;
  final Color checkerboardColor1;
  final Color checkerboardColor2;
  late Map<ToolType, IToolPainter> toolPainterMap;
  late Size latestSize = const Size(0,0);
  IToolPainter? toolPainter;
  late ui.Image _checkerboardImage;


  KPixPainter({
    required AppState appState,
    required ValueNotifier<Offset> offset,
    required this.checkerboardColor1,
    required this.checkerboardColor2,
    required ValueNotifier<CoordinateSetD?> coords,
    required ValueNotifier<bool> primaryDown,
    required ValueNotifier<bool> secondaryDown,
    required ValueNotifier<Offset> primaryPressStart,
    required ValueNotifier<bool> isDragging,
    required ValueNotifier<bool> stylusLongMoveStarted,
    required ValueNotifier<bool> stylusLongMoveVertical,
    required ValueNotifier<bool> stylusLongMoveHorizontal})
      : _appState = appState,
        _offset = offset,
        _coords = coords,
        _isDragging = isDragging,
        _stylusLongMoveStarted = stylusLongMoveStarted,
        _stylusLongMoveVertical = stylusLongMoveVertical,
        _stylusLongMoveHorizontal = stylusLongMoveHorizontal,
        _primaryDown = primaryDown,
        _secondaryDown = secondaryDown,
        _primaryPressStart = primaryPressStart,
        super(repaint: appState.repaintNotifier)
  {
    toolPainterMap = {
      ToolType.select: SelectionPainter(painterOptions: _options),
      ToolType.erase: EraserPainter(painterOptions: _options),
      ToolType.pencil: PencilPainter(painterOptions: _options),
      ToolType.pick: ColorPickPainter(painterOptions: _options),
      ToolType.fill: FillPainter(painterOptions: _options),
      ToolType.shape: ShapePainter(painterOptions: _options),
      ToolType.font: FontPainter(painterOptions: _options),
      ToolType.spraycan: SprayCanPainter(painterOptions: _options),
      ToolType.line: LinePainter(painterOptions: _options),
      ToolType.stamp: StampPainter(painterOptions: _options)
    };
  }

  @override
  void paint(Canvas canvas, Size size)
  {
    toolPainter = toolPainterMap[_appState.selectedTool];
    if (size != latestSize)
    {
      latestSize = size;
      _createCheckerboard();
    }

    DrawingParameters drawParams = DrawingParameters(
        offset: _offset.value,
        canvas: canvas,
        paint: Paint(),
        pixelSize: _appState.zoomFactor,
        canvasSize: _appState.canvasSize,
        drawingSize: size,
        cursorPos: _coords.value,
        primaryDown: _primaryDown.value,
        secondaryDown: _secondaryDown.value,
        primaryPressStart: _primaryPressStart.value,
        currentLayer: _appState.getSelectedLayer()!,
        );


    _drawCheckerboard(drawParams: drawParams);
    toolPainter?.calculate(drawParams: drawParams);
    _drawLayers(drawParams: drawParams);
    _drawSelection(drawParams: drawParams);
    toolPainter?.drawExtras(drawParams: drawParams);
    _drawCursor(drawParams: drawParams);
    toolPainter?.setStatusBarData(drawParams: drawParams);
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

  void _drawCursor({required final DrawingParameters drawParams})
  {
    if (_coords.value != null)
    {
      if (!_isDragging.value && isOnCanvas(drawParams: drawParams, testCoords: drawParams.cursorPos!) && toolPainter != null)
      {
        toolPainter!.drawCursorOutline(drawParams: drawParams);
      }
      else
      {
        drawParams.paint.color = checkerboardColor1;
        drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), _options.cursorSize + _options.cursorBorderWidth, drawParams.paint);
        drawParams.paint.color = checkerboardColor2;
        drawParams.canvas.drawCircle(Offset(_coords.value!.x, _coords.value!.y), _options.cursorSize, drawParams.paint);
      }

      if (_stylusLongMoveStarted.value)
      {
        if (_stylusLongMoveHorizontal.value)
        {
          Path path1 = Path();
          path1.moveTo(_coords.value!.x + (-1 * _options.cursorSize), _coords.value!.y + (-1 * _options.cursorSize));
          path1.lineTo(_coords.value!.x + (-2 * _options.cursorSize), _coords.value!.y);
          path1.lineTo(_coords.value!.x + (-1 * _options.cursorSize), _coords.value!.y + (1 * _options.cursorSize));

          Path path2 = Path();
          path1.moveTo(_coords.value!.x + (1 * _options.cursorSize), _coords.value!.y + (-1 * _options.cursorSize));
          path1.lineTo(_coords.value!.x + (2 * _options.cursorSize), _coords.value!.y);
          path1.lineTo(_coords.value!.x + (1 * _options.cursorSize), _coords.value!.y + (1 * _options.cursorSize));

          drawParams.paint.style = PaintingStyle.stroke;
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthLarge;
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawPath(path1, drawParams.paint);
          drawParams.canvas.drawPath(path2, drawParams.paint);
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthSmall;
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawPath(path1, drawParams.paint);
          drawParams.canvas.drawPath(path2, drawParams.paint);

        }
        else if (_stylusLongMoveVertical.value)
        {
          Path path = Path();
          path.moveTo(_coords.value!.x + (-2 * _options.cursorSize), _coords.value!.y + (2 * _options.cursorSize));
          path.lineTo(_coords.value!.x, _coords.value!.y);
          path.lineTo(_coords.value!.x + (2 * _options.cursorSize), _coords.value!.y);
          path.lineTo(_coords.value!.x + (2 * _options.cursorSize), _coords.value!.y + (-2 * _options.cursorSize));
          path.lineTo(_coords.value!.x, _coords.value!.y + (-2 * _options.cursorSize));
          path.lineTo(_coords.value!.x, _coords.value!.y);
          drawParams.paint.style = PaintingStyle.stroke;
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthLarge;
          drawParams.paint.color = Colors.black;
          drawParams.canvas.drawPath(path, drawParams.paint);
          drawParams.paint.strokeWidth = _options.selectionStrokeWidthSmall;
          drawParams.paint.color = Colors.white;
          drawParams.canvas.drawPath(path, drawParams.paint);
        }
      }
    }
  }

  void _drawLayers({required final DrawingParameters drawParams})
  {
    final double pxlSzDbl = drawParams.pixelSize.toDouble();

    final List<LayerState> layers = _appState.layers;
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
          final CoordinateColorMap selectedLayerCursorContent = toolPainter != null ? toolPainter!.getCursorContent(drawParams: drawParams) : HashMap();
          final CoordinateColorMap toolContent = toolPainter != null ? toolPainter!.getToolContent(drawParams: drawParams) : HashMap();
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
                ColorReference? selColor = _appState.selectionState.selection.getColorReference(coord: CoordinateSetI(x: x, y: y));
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

