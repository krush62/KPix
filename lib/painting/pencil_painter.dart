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
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';

class PencilPainter extends IToolPainter
{
  final PencilOptions _options = GetIt.I.get<PreferenceManager>().toolOptions.pencilOptions;
  final LineOptions _lineOptions = GetIt.I.get<PreferenceManager>().toolOptions.lineOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final List<CoordinateSetI> _paintPositions = <CoordinateSetI>[];
  final Set<CoordinateSetI> _allPaintPositions = <CoordinateSetI>{};
  CoordinateSetI? _previousCursorPosNorm;
  int _previousToolSize = -1;
  Set<CoordinateSetI> _contentPoints = <CoordinateSetI>{};
  bool _waitingForDump = false;
  final CoordinateColorMap _drawingPixels = HashMap<CoordinateSetI, ColorReference>();
  CoordinateSetI? _lastDrawingPosition;
  bool _isLineDrawing = false;
  bool _hasNewCursorPos = false;
  bool _lastShadingEnabled = false;
  ShaderDirection _lastShadingDirection = ShaderDirection.left;
  bool _lastShadingCurrentRamp = false;
  ColorReference? _lastColorSelection;


  PencilPainter({required super.painterOptions});

  @override
  void calculate({required final DrawingParameters drawParams})
  {
    if (drawParams.currentRasterLayer != null)
    {
      final RasterableLayerState rasterLayer = drawParams.currentRasterLayer!;
      if (drawParams.cursorPosNorm != null) {

        _hasNewCursorPos =
            drawParams.cursorPosNorm! != _previousCursorPosNorm ||
            _previousToolSize != _options.size.value ||
            _lastShadingEnabled != shaderOptions.isEnabled.value ||
            _lastShadingCurrentRamp != shaderOptions.onlyCurrentRampEnabled.value ||
            _lastShadingDirection != shaderOptions.shaderDirection.value ||
            _lastColorSelection != appState.selectedColor;

        if (_hasNewCursorPos)
        {
          _contentPoints = getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: drawParams.cursorPosNorm!);
          _previousCursorPosNorm = CoordinateSetI(x: drawParams.cursorPosNorm!.x, y: drawParams.cursorPosNorm!.y);
          _previousToolSize = _options.size.value;
          _lastShadingEnabled = shaderOptions.isEnabled.value;
          _lastShadingCurrentRamp = shaderOptions.onlyCurrentRampEnabled.value;
          _lastShadingDirection = shaderOptions.shaderDirection.value;
          _lastColorSelection = appState.selectedColor;
        }
      }
      if (!_waitingForDump)
      {
        if (drawParams.primaryDown)
        {
          if (rasterLayer.lockState.value != LayerLockState.locked && rasterLayer.visibilityState.value != LayerVisibilityState.hidden)
          {
            if (_hotkeyManager.shiftIsPressed)
            {
              _isLineDrawing = true;
            }
            else if (drawParams.cursorPosNorm != null || _previousCursorPosNorm != null)
            {
              final CoordinateSetI cpn = drawParams.cursorPosNorm != null ? drawParams.cursorPosNorm! : _previousCursorPosNorm!;
              if (_paintPositions.isEmpty || (cpn.isAdjacent(other: _paintPositions[_paintPositions.length - 1], withDiagonal: true) && _hasNewCursorPos))
              {
                final CoordinateSetI drawPos = CoordinateSetI(x: cpn.x, y: cpn.y);
                _paintPositions.add(drawPos);
                _allPaintPositions.add(drawPos);
                _lastDrawingPosition = drawPos;
                //PIXEL PERFECT
                if (_paintPositions.length >= 3)
                {
                  if (_options.pixelPerfect.value &&
                      _paintPositions.last.isDiagonal(other: _paintPositions[_paintPositions.length - 3]))
                  {
                    final CoordinateSetI deletedPos = _paintPositions.removeAt(_paintPositions.length - 2);
                    if (_allPaintPositions.elementAt(_allPaintPositions.length - 2) == deletedPos)
                    {
                      _allPaintPositions.remove(deletedPos);
                    }
                  }
                }
              }
              else
              {
                final List<CoordinateSetI> bresenLine = bresenham(start: _paintPositions[_paintPositions.length - 1], end: cpn).sublist(1);
                _paintPositions.addAll(bresenLine);
                _allPaintPositions.addAll(bresenLine);
                _lastDrawingPosition = CoordinateSetI.from(other: cpn);
              }
            }
          }

          if (_hasNewCursorPos)
          {
            final Set<CoordinateSetI> posSet = _options.pixelPerfect.value ? _paintPositions.sublist(0, _paintPositions.length - min(3, _paintPositions.length)).toSet() : _paintPositions.toSet();
            final Set<CoordinateSetI> paintPoints = <CoordinateSetI>{};
            for (final CoordinateSetI pos in posSet)
            {
              paintPoints.addAll(getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: pos));
            }
            final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: paintPoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
            CoordinateColorMap pixelsToDraw = CoordinateColorMap();
            if (rasterLayer is DrawingLayerState)
            {
              pixelsToDraw = getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
            }
            else if (rasterLayer is ShadingLayerState)
            {
              pixelsToDraw = getPixelsToDrawForShading(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, shaderOptions: shaderOptions);
            }

            _drawingPixels.addAll(pixelsToDraw);
            if (rasterLayer is DrawingLayerState)
            {
              _paintPositions.removeRange(0, _paintPositions.length - min(3, _paintPositions.length));
            }

            CoordinateColorMap addPixels;
            if (_paintPositions.isNotEmpty)
            {
              final Set<CoordinateSetI> additionalPaintPoints = <CoordinateSetI>{};
              for (final CoordinateSetI pos in _paintPositions)
              {
                additionalPaintPoints.addAll(getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: pos));
              }

              CoordinateColorMap additionalDrawingPixels = CoordinateColorMap();
              final Set<CoordinateSetI> additionalMirrorPoints = getMirrorPoints(coords: additionalPaintPoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
              if (rasterLayer is DrawingLayerState)
              {
                additionalDrawingPixels = getPixelsToDraw(coords: additionalMirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
              }
              else if (rasterLayer is ShadingLayerState)
              {
                additionalDrawingPixels = getPixelsToDrawForShading(coords: additionalMirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, shaderOptions: shaderOptions);
              }

              addPixels = HashMap<CoordinateSetI, ColorReference>();
              addPixels.addAll(_drawingPixels);
              addPixels.addAll(additionalDrawingPixels);
            }
            else
            {
              addPixels = _drawingPixels;
            }
            rasterizePixels(drawingPixels: addPixels, currentLayer: rasterLayer).then((final ContentRasterSet? rasterSet) {
              if (rasterSet != null)
              {
                setContentRasterData(content: rasterSet);
              }
              else
              {
                resetContentRaster(currentLayer: rasterLayer);
              }
              hasAsyncUpdate = true;
            });

          }


        }
        else //final dumping
        {
          if (_allPaintPositions.isNotEmpty)
          {
            final Set<CoordinateSetI> posSet = _allPaintPositions.toSet();
            final Set<CoordinateSetI> paintPoints = <CoordinateSetI>{};
            for (final CoordinateSetI pos in posSet)
            {
              paintPoints.addAll(getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: pos));
            }


            final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: paintPoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
            if (rasterLayer is DrawingLayerState)
            {
              _drawingPixels.addAll(getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
              _dumpDrawing(currentLayer: rasterLayer);
              _waitingForDump = true;
            }
            else if (rasterLayer is ShadingLayerState)
            {
               dumpShading(shadingLayer: rasterLayer, coordinates: mirrorPoints, shaderOptions: shaderOptions);
               _drawingPixels.clear();
            }
            _paintPositions.clear();
            _allPaintPositions.clear();
          }
          else if (_hotkeyManager.shiftIsPressed && _isLineDrawing)
          {
            final Set<CoordinateSetI> linePoints = _hotkeyManager.controlIsPressed ?
            getIntegerRatioLinePoints(startPos: _lastDrawingPosition!, endPos: drawParams.cursorPosNorm!, size: _options.size.value, angles: _lineOptions.angles, shape: _options.shape.value) :
            getLinePoints(startPos: _lastDrawingPosition!, endPos: drawParams.cursorPosNorm!, size: _options.size.value, shape: _options.shape.value);

            final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: linePoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
            if (rasterLayer is DrawingLayerState)
            {
              _drawingPixels.addAll(getPixelsToDraw(coords: mirrorPoints, canvasSize: drawParams.canvasSize, currentLayer: rasterLayer, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions));
              _dumpDrawing(currentLayer: rasterLayer);
              _waitingForDump = true;
            }
            else if (rasterLayer is ShadingLayerState)
            {
              dumpShading(shadingLayer: rasterLayer, coordinates: mirrorPoints, shaderOptions: shaderOptions);
              _drawingPixels.clear();
            }
            _lastDrawingPosition = CoordinateSetI.from(other: linePoints.last);
          }
          _isLineDrawing = false;
        }
      }
      else if (rasterLayer is DrawingLayerState && rasterLayer.rasterQueue.isEmpty && !rasterLayer.isRasterizing && _waitingForDump)
      {
        _drawingPixels.clear();
        _waitingForDump = false;
      }

      //CURSOR CONTENT
      if (_hasNewCursorPos)
      {
        CoordinateColorMap cursorPixels = CoordinateColorMap();
        if (_hotkeyManager.shiftIsPressed && _lastDrawingPosition != null && _paintPositions.isEmpty && _allPaintPositions.isEmpty)
        {
          final Set<CoordinateSetI> linePoints = _hotkeyManager.controlIsPressed ?
          getIntegerRatioLinePoints(startPos: _lastDrawingPosition!, endPos: drawParams.cursorPosNorm!, size: _options.size.value, angles: _lineOptions.angles, shape: _options.shape.value) :
          getLinePoints(startPos: _lastDrawingPosition!, endPos: drawParams.cursorPosNorm!, size: _options.size.value, shape: _options.shape.value);

          final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: linePoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);

          if (rasterLayer is DrawingLayerState)
          {
            cursorPixels = getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
          }
          else if (rasterLayer is ShadingLayerState)
          {
            cursorPixels = getPixelsToDrawForShading(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, shaderOptions: shaderOptions);
          }
        }
        else
        {
          final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: _contentPoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
          if (rasterLayer is DrawingLayerState)
          {
            cursorPixels = getPixelsToDraw(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, selectedColor: appState.selectedColor!, selection: appState.selectionState, shaderOptions: shaderOptions);
          }
          else if (rasterLayer is ShadingLayerState)
          {
            cursorPixels = getPixelsToDrawForShading(coords: mirrorPoints, currentLayer: rasterLayer, canvasSize: drawParams.canvasSize, shaderOptions: shaderOptions);
          }
        }
        rasterizePixels(drawingPixels: cursorPixels, currentLayer: rasterLayer).then((final ContentRasterSet? rasterSet) {
          cursorRaster = rasterSet;
          hasAsyncUpdate = true;
        });
        _hasNewCursorPos = false;
      }
      else if (drawParams.cursorPos == null)
      {
        cursorRaster = null;
      }
    }
  }

  void _dumpDrawing({required final DrawingLayerState currentLayer})
  {
    if (_drawingPixels.isNotEmpty)
    {
      if (!appState.selectionState.selection.isEmpty)
      {
        appState.selectionState.selection.addDirectlyAll(list: _drawingPixels);
      }
      else
      {
        currentLayer.setDataAll(list: _drawingPixels);
      }
    }
    hasHistoryData = true;
    resetContentRaster(currentLayer: currentLayer);
  }




  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final double effPxlSize = drawParams.pixelSize / drawParams.pixelRatio;
    //Surrounding
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: _contentPoints);
    final Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * effPxlSize) + drawParams.offset.dx, (pathPoints[i].y * effPxlSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * effPxlSize) + drawParams.offset.dx, (pathPoints[i + 1].y * effPxlSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * effPxlSize) + drawParams.offset.dx, (pathPoints[0].y * effPxlSize) + drawParams.offset.dy);
      }
    }

    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = blackToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = whiteToolAlphaColor;
    drawParams.canvas.drawPath(path, drawParams.paint);
  }

  @override
  void setStatusBarData({required final DrawingParameters drawParams})
  {
      super.setStatusBarData(drawParams: drawParams);
      statusBarData.cursorPos = drawParams.cursorPosNorm;
  }

  @override
  void reset()
  {
    _paintPositions.clear();
    _allPaintPositions.clear();
    _previousToolSize = -1;
    _contentPoints.clear();
    _waitingForDump = false;
    _drawingPixels.clear();
    _lastDrawingPosition = null;
    _isLineDrawing = false;
  }
}
