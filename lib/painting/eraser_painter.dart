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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

class EraserPainter extends IToolPainter
{
  static const double _lineHighlightOpacityFactor = 0.5;
  final EraserOptions _options = GetIt.I.get<ToolOptions>().eraserOptions;
  final LineOptions _lineOptions = GetIt.I.get<ToolOptions>().lineOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final CoordinateSetI _previousCursorPosNorm = CoordinateSetI.zero();
  bool _isDown = false;
  bool _hasErasedPixels = false;
  CoordinateSetI? _lastErasePosition;
  bool _isFreehandErasing = false;
  Object? _linePreviewKey;
  Set<CoordinateSetI> _linePreviewPoints = <CoordinateSetI>{};
  Path? _linePreviewFill;
  Path? _linePreviewOutline;

  EraserPainter({required super.painterOptions});

  bool get _isInLineMode
  {
    return _hotkeyManager.shiftIsPressed && _lastErasePosition != null && !_isFreehandErasing;
  }

  @visibleForTesting
  Set<CoordinateSetI> get linePreviewPoints
  {
    return _linePreviewPoints;
  }

  @override
  void calculate({required final DrawingParameters drawParams})
  {
    final CoordinateSetI? cursor = drawParams.cursorPosNorm;
    final RasterableLayerState? rasterLayer = drawParams.currentRasterLayer;
    if (cursor != null && rasterLayer != null)
    {
      final bool isEditable = rasterLayer.lockState.value != LayerLockState.locked && rasterLayer.visibilityState.value != LayerVisibilityState.hidden;
      if (drawParams.primaryDown && isEditable)
      {
        //with shift, the line is erased on release and a freehand stroke pauses
        if (!_hotkeyManager.shiftIsPressed || _lastErasePosition == null)
        {
          final List<CoordinateSetI> pixelsToDelete = <CoordinateSetI>[cursor];
          if (!cursor.isAdjacent(other: _previousCursorPosNorm, withDiagonal: true))
          {
            pixelsToDelete.addAll(bresenham(start: _previousCursorPosNorm, end: cursor).sublist(1));
          }
          final Set<CoordinateSetI> content = getStampedContentPoints(shape: _options.shape.value, size: _options.size.value, positions: pixelsToDelete);
          _erase(coords: getMirrorPoints(coords: content, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical), rasterLayer: rasterLayer, canvasSize: drawParams.canvasSize);
          _isFreehandErasing = true;
          _lastErasePosition = CoordinateSetI.from(other: cursor);
        }
      }
      else if (!drawParams.primaryDown && _isDown && _isInLineMode && isEditable)
      {
        final (Set<CoordinateSetI> linePoints, CoordinateSetI lineEnd) = _getLine(start: _lastErasePosition!, end: cursor);
        _erase(coords: getMirrorPoints(coords: linePoints, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical), rasterLayer: rasterLayer, canvasSize: drawParams.canvasSize);
        _lastErasePosition = lineEnd;
      }
      _previousCursorPosNorm.x = cursor.x;
      _previousCursorPosNorm.y = cursor.y;
    }
    if (drawParams.primaryDown && _isDown == false)
    {
      _isDown = true;
    }
    else if (!drawParams.primaryDown && _isDown == true)
    {
      _isDown = false;
      _isFreehandErasing = false;
      if (_hasErasedPixels)
      {
        hasHistoryData = true;
        _hasErasedPixels = false;
      }
    }
    _updateLinePreview(drawParams: drawParams);
  }

  void _erase({required final Set<CoordinateSetI> coords, required final RasterableLayerState rasterLayer, required final CoordinateSetI canvasSize})
  {
    final CoordinateColorMapNullable refs = HashMap<CoordinateSetI, ColorReference?>();
    final SelectionState selection = GetIt.I.get<DocumentState>().selectionState;
    for (final CoordinateSetI coord in coords)
    {
      if (canvasSize.contains(coord: coord))
      {
        if (rasterLayer.runtimeType == DrawingLayerState)
        {
          final DrawingLayerState drawingLayer = rasterLayer as DrawingLayerState;
          if (selection.selection.isEmpty)
          {
            if (drawingLayer.getDataEntry(coord: coord) != null)
            {
              refs[coord] = null;
            }
          }
          else if (selection.selection.getColorReference(coord: coord) != null)
          {
            selection.selection.deleteDirectly(coord: coord);
            _hasErasedPixels = true;
          }
        }
        else if (rasterLayer is ShadingLayerState)
        {
          if (rasterLayer.hasCoord(coord: coord))
          {
            refs[coord] = null;
          }
        }
      }
    }
    if (refs.isNotEmpty)
    {
      _hasErasedPixels = true;
      if (rasterLayer is DrawingLayerState)
      {
        rasterLayer.setDataAll(list: refs);
      }
      else if (rasterLayer is ShadingLayerState)
      {
        rasterLayer.removeCoords(coords: refs.keys);
      }
    }
  }

  /// The pixels a line from [start] to [end] covers, and where it really ends
  /// (a line snapped to an angle can stop short of [end]).
  (Set<CoordinateSetI>, CoordinateSetI) _getLine({required final CoordinateSetI start, required final CoordinateSetI end})
  {
    final Set<CoordinateSetI> spine = _hotkeyManager.controlIsPressed ?
      getIntegerRatioLinePoints(startPos: start, endPos: end, size: 1, shape: _options.shape.value, angles: _lineOptions.angles) :
      getLinePoints(startPos: start, endPos: end, size: 1, shape: _options.shape.value);
    final Set<CoordinateSetI> points = getStampedContentPoints(shape: _options.shape.value, size: _options.size.value, positions: spine);
    return (points, spine.isEmpty ? start : spine.last);
  }

  void _updateLinePreview({required final DrawingParameters drawParams})
  {
    if (!_isInLineMode || drawParams.cursorPosNorm == null)
    {
      _linePreviewKey = null;
      _linePreviewPoints = <CoordinateSetI>{};
      _linePreviewFill = null;
      _linePreviewOutline = null;
      return;
    }

    final Object key = (_lastErasePosition, drawParams.cursorPosNorm, _options.size.value, _options.shape.value, _hotkeyManager.controlIsPressed, drawParams.symmetryHorizontal, drawParams.symmetryVertical, drawParams.canvasSize);
    if (key == _linePreviewKey)
    {
      return;
    }
    _linePreviewKey = key;
    final Set<CoordinateSetI> mirrorPoints = getMirrorPoints(coords: _getLine(start: _lastErasePosition!, end: drawParams.cursorPosNorm!).$1, canvasSize: drawParams.canvasSize, symmetryX: drawParams.symmetryHorizontal, symmetryY: drawParams.symmetryVertical);
    _linePreviewPoints = mirrorPoints.where((final CoordinateSetI coord) => drawParams.canvasSize.contains(coord: coord)).toSet();

    //both paths are in canvas pixels; one rect per horizontal run keeps the fill small
    final Path fill = Path();
    final Map<int, List<int>> rows = <int, List<int>>{};
    for (final CoordinateSetI coord in _linePreviewPoints)
    {
      rows.putIfAbsent(coord.y, () => <int>[]).add(coord.x);
    }
    for (final MapEntry<int, List<int>> row in rows.entries)
    {
      final List<int> xs = row.value..sort();
      int runStart = xs.first;
      for (int i = 1; i <= xs.length; i++)
      {
        if (i == xs.length || xs[i] != xs[i - 1] + 1)
        {
          fill.addRect(Rect.fromLTRB(runStart.toDouble(), row.key.toDouble(), xs[i - 1] + 1.0, row.key + 1.0));
          if (i < xs.length)
          {
            runStart = xs[i];
          }
        }
      }
    }

    final Path outline = Path();
    for (final CoordinateSetI coord in _linePreviewPoints)
    {
      final double x = coord.x.toDouble();
      final double y = coord.y.toDouble();
      if (!_linePreviewPoints.contains(CoordinateSetI(x: coord.x - 1, y: coord.y)))
      {
        outline..moveTo(x, y)..lineTo(x, y + 1);
      }
      if (!_linePreviewPoints.contains(CoordinateSetI(x: coord.x + 1, y: coord.y)))
      {
        outline..moveTo(x + 1, y)..lineTo(x + 1, y + 1);
      }
      if (!_linePreviewPoints.contains(CoordinateSetI(x: coord.x, y: coord.y - 1)))
      {
        outline..moveTo(x, y)..lineTo(x + 1, y);
      }
      if (!_linePreviewPoints.contains(CoordinateSetI(x: coord.x, y: coord.y + 1)))
      {
        outline..moveTo(x, y + 1)..lineTo(x + 1, y + 1);
      }
    }
    _linePreviewFill = fill;
    _linePreviewOutline = outline;
  }

  void _drawLinePreview({required final DrawingParameters drawParams, required final double effPixelSize})
  {
    if (_linePreviewFill == null || _linePreviewOutline == null)
    {
      return;
    }
    final Float64List toScreen = Float64List.fromList(<double>[
      effPixelSize, 0, 0, 0,
      0, effPixelSize, 0, 0,
      0, 0, 1, 0,
      drawParams.offset.dx, drawParams.offset.dy, 0, 1,
    ]);

    drawParams.paint.style = PaintingStyle.fill;
    drawParams.paint.color = Colors.white.withAlpha((guiPrefs.toolOpacity.value * 2.55 * _lineHighlightOpacityFactor).round());
    drawParams.canvas.drawPath(_linePreviewFill!.transform(toScreen), drawParams.paint);

    //the outline is loose edges, square caps close the corners
    final Path outline = _linePreviewOutline!.transform(toScreen);
    drawParams.paint.style = PaintingStyle.stroke;
    drawParams.paint.strokeCap = StrokeCap.square;
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthLarge;
    drawParams.paint.color = blackToolAlphaColor;
    drawParams.canvas.drawPath(outline, drawParams.paint);
    drawParams.paint.strokeWidth = painterOptions.selectionStrokeWidthSmall;
    drawParams.paint.color = whiteToolAlphaColor;
    drawParams.canvas.drawPath(outline, drawParams.paint);
    drawParams.paint.strokeCap = StrokeCap.butt;
  }

  @override
  void drawCursorOutline({required final DrawingParameters drawParams})
  {
    final double effPixelSize = drawParams.pixelSize / drawParams.pixelRatio;
    _drawLinePreview(drawParams: drawParams, effPixelSize: effPixelSize);

    final Set<CoordinateSetI> contentPoints = getRoundSquareContentPoints(shape: _options.shape.value, size: _options.size.value, position: drawParams.cursorPosNorm!);
    final List<CoordinateSetI> pathPoints = IToolPainter.getBoundaryPath(coords: contentPoints);

    final Path path = Path();
    for (int i = 0; i < pathPoints.length; i++)
    {
      if (i == 0)
      {
        path.moveTo((pathPoints[i].x * effPixelSize) + drawParams.offset.dx, (pathPoints[i].y * effPixelSize) + drawParams.offset.dy);
      }

      if (i < pathPoints.length - 1)
      {
        path.lineTo((pathPoints[i + 1].x * effPixelSize) + drawParams.offset.dx, (pathPoints[i + 1].y * effPixelSize) + drawParams.offset.dy);
      }
      else
      {
        path.lineTo((pathPoints[0].x * effPixelSize) + drawParams.offset.dx, (pathPoints[0].y * effPixelSize) + drawParams.offset.dy);
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
    if (_isInLineMode && drawParams.cursorPosNorm != null)
    {
      setLineStatusBarData(startPos: _lastErasePosition!, endPos: drawParams.cursorPosNorm!);
    }
  }

  @override
  void reset()
  {
    _isDown = false;
    _hasErasedPixels = false;
    _lastErasePosition = null;
    _isFreehandErasing = false;
    _linePreviewKey = null;
    _linePreviewPoints = <CoordinateSetI>{};
    _linePreviewFill = null;
    _linePreviewOutline = null;
  }

}
