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

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/legacy_pencil_painter.dart';
import 'support/selection_harness.dart';

KPixPainterOptions _painterOptions()
{
  return KPixPainterOptions(
    cursorSize: 1.0,
    cursorBorderWidth: 1.0,
    selectionSolidStrokeWidth: 1.0,
    pixelExtension: 0.0,
    selectionPolygonCircleRadius: 1.0,
    selectionStrokeWidthLarge: 1.0,
    selectionStrokeWidthSmall: 1.0,
    backupPainterPollingRateMs: 100,
  );
}

/// The pixels of a brush stamped at every position, merged the way the
/// painters did it before [IToolPainter.getStampedContentPoints].
List<CoordinateSetI> _unionOfStamps({required final IToolPainter painter, required final PencilShape shape, required final int size, required final Iterable<CoordinateSetI> positions})
{
  final Set<CoordinateSetI> points = <CoordinateSetI>{};
  for (final CoordinateSetI position in positions)
  {
    points.addAll(painter.getRoundSquareContentPoints(shape: shape, size: size, position: position));
  }
  return points.toList();
}

/// [IToolPainter.getLinePoints] as it was before the stamping changed.
Set<CoordinateSetI> _legacyLinePoints({required final IToolPainter painter, required final CoordinateSetI startPos, required final CoordinateSetI endPos, required final int size, required final PencilShape shape})
{
  Set<CoordinateSetI> linePoints = <CoordinateSetI>{};
  final Set<CoordinateSetI> bresenhamPoints = bresenham(start: startPos, end: endPos).toSet();
  if (size == 1)
  {
    linePoints = bresenhamPoints;
  }
  else
  {
    final Set<CoordinateSetI> lPoints = <CoordinateSetI>{};
    for (final CoordinateSetI coord in bresenhamPoints)
    {
      lPoints.addAll(painter.getRoundSquareContentPoints(shape: shape, size: size, position: coord));
    }
    linePoints = lPoints;
  }
  return linePoints;
}

/// [IToolPainter.getIntegerRatioLinePoints] as it was before the stamping
/// changed.
Set<CoordinateSetI> _legacyIntegerRatioLinePoints({required final IToolPainter painter, required final CoordinateSetI startPos, required final CoordinateSetI endPos, required final int size, required final PencilShape shape, required final Set<AngleData> angles})
{
  Set<CoordinateSetI> linePoints = <CoordinateSetI>{};
  final AngleData? closestAngle = painter.getClosestAngle(startPos: startPos, endPos: endPos, angles: angles);

  if (closestAngle != null)
  {
    double shortestDist = double.maxFinite;
    final CoordinateSetI currentPos = CoordinateSetI.from(other: startPos);
    final Set<CoordinateSetI> lPoints = <CoordinateSetI>{};
    lPoints.add(CoordinateSetI.from(other: startPos));
    bool firstRun = true;
    do
    {
      final int startReducer = firstRun ? -1 : 0;
      firstRun = false;
      final Set<CoordinateSetI> currPoints = <CoordinateSetI>{};
      if (closestAngle.x.abs() > closestAngle.y.abs())
      {
        for (int i = 0; i < closestAngle.x.abs() + startReducer; i++)
        {
          if (closestAngle.x > 0)
          {
            currentPos.x++;
          }
          else
          {
            currentPos.x--;
          }
          currPoints.add(CoordinateSetI.from(other: currentPos));
        }
        if (closestAngle.y > 0)
        {
          currentPos.y++;
        }
        else if (closestAngle.y < 0)
        {
          currentPos.y--;
        }
      }
      else
      {
        for (int i = 0; i < closestAngle.y.abs() + startReducer; i++)
        {
          if (closestAngle.y > 0)
          {
            currentPos.y++;
          }
          else
          {
            currentPos.y--;
          }
          currPoints.add(CoordinateSetI.from(other: currentPos));
        }
        if (closestAngle.x > 0)
        {
          currentPos.x++;
        }
        else if (closestAngle.x < 0)
        {
          currentPos.x--;
        }
      }

      final double dist = currentPos.distanceTo(b: endPos);
      if (dist <= shortestDist)
      {
        shortestDist = dist;
        lPoints.addAll(currPoints);
      }
      else
      {
        break;
      }
    } while(true);

    if (size == 1)
    {
      linePoints = lPoints;
    }
    else
    {
      final Set<CoordinateSetI> widePoints = <CoordinateSetI>{};
      for (final CoordinateSetI coord in lPoints)
      {
        widePoints.addAll(painter.getRoundSquareContentPoints(shape: shape, size: size, position: coord));
      }
      linePoints = widePoints;
    }
  }

  return linePoints;
}

DrawingParameters _params({required final LayerState layer, required final CoordinateSetI cursor, required final bool primaryDown, final double? symmetry})
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  return DrawingParameters(
    offset: Offset.zero,
    canvas: Canvas(recorder),
    paint: Paint(),
    pixelSize: 1,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    drawingSize: const Size(4, 4),
    cursorPos: CoordinateSetD(x: cursor.x.toDouble(), y: cursor.y.toDouble()),
    cursorPosNorm: cursor,
    primaryDown: primaryDown,
    stylusButtonDown: false,
    secondaryDown: false,
    primaryPressStart: Offset.zero,
    pixelRatio: 1.0,
    currentLayer: layer,
    symmetryHorizontal: symmetry,
    symmetryVertical: symmetry,
    isPlaying: false,
  );
}

/// Cursor positions of a stroke: diagonal steps for pixel perfect to prune,
/// jumps that get filled in, a pause on one pixel and a run off the canvas.
/// It ends on the canvas, so the last positions, which only the dump stamps,
/// show.
List<CoordinateSetI> _strokePath()
{
  final List<CoordinateSetI> path = <CoordinateSetI>[];
  void to(final int x, final int y) => path.add(CoordinateSetI(x: x, y: y));
  to(3, 4); to(4, 4); to(5, 5); to(6, 5); to(7, 6); to(7, 6); to(8, 7); to(9, 7);
  to(13, 9);
  to(14, 10); to(15, 10); to(16, 11); to(17, 11); to(18, 12);
  to(4, 14);
  for (int x = 3; x >= -3; x--)
  {
    to(x, x.isEven ? 14 : 15);
  }
  to(2, 16); to(3, 17);
  to(20, 18);
  for (int step = 1; step <= 4; step++)
  {
    to(20 + (step ~/ 3), 18 + step);
  }
  to(20, 21); to(19, 22); to(18, 21); to(17, 22); to(16, 21);
  return path;
}

enum _Target { layer, lockedTransparency, selection, shadingLayer }

class _Scenario
{
  final PencilShape shape;
  final int size;
  final bool pixelPerfect;
  final double? symmetry;
  final bool shaderEnabled;
  final _Target target;

  const _Scenario({required this.shape, required this.size, required this.pixelPerfect, this.symmetry, this.shaderEnabled = false, this.target = _Target.layer});

  @override
  String toString() => "${shape.name} size $size, pixel perfect $pixelPerfect, symmetry $symmetry, shading ${shaderEnabled ? "on" : "off"}, ${target.name}";
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 24, y: 24);

/// Draws [_strokePath] with the painter [createPainter] makes and returns what
/// ended up where, with colors written as ramp index and color index so that
/// separate projects compare.
Future<Map<String, String>> _drawStroke({required final WidgetTester tester, required final _Scenario scenario, required final IToolPainter Function() createPainter}) async
{
  final Map<String, String> result = <String, String>{};
  await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
    final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
    final ColorReference selected = ramps.first.references[2];
    final ColorReference other = ramps.first.references[4];
    String name(final ColorReference? color) => color == null ? "-" : "${ramps.indexOf(color.ramp)}:${color.colorIndex}";

    final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
    final CoordinateColorMapNullable content = CoordinateColorMapNullable();
    for (int x = 0; x < _canvasSize.x; x++)
    {
      for (int y = 0; y < _canvasSize.y; y++)
      {
        if ((x + y) % 5 == 0)
        {
          content[CoordinateSetI(x: x, y: y)] = selected;
        }
        else if ((x * y) % 7 == 1)
        {
          content[CoordinateSetI(x: x, y: y)] = other;
        }
      }
    }
    layer.setDataAll(list: content);
    await settle();

    GetIt.I.get<PaletteState>().colorSelected(color: selected);
    final PencilOptions options = GetIt.I.get<ToolOptions>().pencilOptions;
    options.shape.value = scenario.shape;
    options.size.value = scenario.size;
    options.pixelPerfect.value = scenario.pixelPerfect;
    final ShaderOptions shaderOptions = GetIt.I.get<ShaderOptions>();
    shaderOptions.isEnabled.value = scenario.shaderEnabled;
    shaderOptions.shaderDirection.value = ShaderDirection.right;
    shaderOptions.onlyCurrentRampEnabled.value = false;

    RasterableLayerState target = layer;
    switch (scenario.target)
    {
      case _Target.layer:
        break;
      case _Target.lockedTransparency:
        layer.lockState.value = LayerLockState.transparency;
      case _Target.selection:
        GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 5, y: 2), end: CoordinateSetI(x: 16, y: 15), selectShape: SelectShape.rectangle);
        await settle();
        expect(GetIt.I.get<DocumentState>().selectionState.selection.isEmpty, isFalse, reason: "setup: the selection floats");
      case _Target.shadingLayer:
        target = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, select: true, addToHistoryStack: false)! as ShadingLayerState;
        await settle();
    }

    final IToolPainter painter = createPainter();
    final List<CoordinateSetI> path = _strokePath();
    for (final CoordinateSetI cursor in path)
    {
      painter.calculate(drawParams: _params(layer: target, cursor: cursor, primaryDown: true, symmetry: scenario.symmetry));
    }
    painter.calculate(drawParams: _params(layer: target, cursor: path.last, primaryDown: false, symmetry: scenario.symmetry));
    await settle();

    for (int x = 0; x < _canvasSize.x; x++)
    {
      for (int y = 0; y < _canvasSize.y; y++)
      {
        final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
        result["layer $x|$y"] = name(layer.getDataEntry(coord: coord));
        result["selection $x|$y"] = name(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: coord));
        if (target is ShadingLayerState)
        {
          result["shading $x|$y"] = "${target.getRawValueAt(coord: coord)}";
        }
      }
    }
  },);
  return result;
}

void main()
{
  group("stamping a brush along positions", () {
    testWidgets("gives the pixels, in order, of merging a stamp per position", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
        final Random random = Random(7);
        for (final PencilShape shape in PencilShape.values)
        {
          for (int size = PencilConstraints.sizeMin; size <= PencilConstraints.sizeMax; size++)
          {
            final List<CoordinateSetI> positions = <CoordinateSetI>[];
            int x = random.nextInt(40) - 20;
            int y = random.nextInt(40) - 20;
            for (int i = 0; i < 30; i++)
            {
              //mostly neighbors, sometimes a repeat or a jump
              final int kind = random.nextInt(10);
              if (kind == 0)
              {
                x += random.nextInt(21) - 10;
                y += random.nextInt(21) - 10;
              }
              else if (kind > 1)
              {
                x += random.nextInt(3) - 1;
                y += random.nextInt(3) - 1;
              }
              positions.add(CoordinateSetI(x: x, y: y));
            }
            expect(painter.getStampedContentPoints(shape: shape, size: size, positions: positions).toList(), _unionOfStamps(painter: painter, shape: shape, size: size, positions: positions),
                reason: "${shape.name} brush of size $size",);
          }
        }
      },);
    });

    testWidgets("works the same far from the origin and without positions", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
        final List<CoordinateSetI> far = <CoordinateSetI>[CoordinateSetI(x: 70001, y: -65536), CoordinateSetI(x: 70002, y: -65535), CoordinateSetI(x: 70000, y: -65537)];
        for (final PencilShape shape in PencilShape.values)
        {
          expect(painter.getStampedContentPoints(shape: shape, size: 7, positions: far).toList(), _unionOfStamps(painter: painter, shape: shape, size: 7, positions: far));
          expect(painter.getStampedContentPoints(shape: shape, size: 7, positions: <CoordinateSetI>[]), isEmpty);
        }
      },);
    });

    testWidgets("gives the same pixels when the stamped area is too large for a bit mask", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
        //about 36 million pixels between the two ends
        final List<CoordinateSetI> apart = <CoordinateSetI>[CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 1, y: 0), CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 6000, y: 6000), CoordinateSetI(x: 6001, y: 6001)];
        for (final PencilShape shape in PencilShape.values)
        {
          expect(painter.getStampedContentPoints(shape: shape, size: 5, positions: apart).toList(), _unionOfStamps(painter: painter, shape: shape, size: 5, positions: apart));
        }
      },);
    });

    testWidgets("leaves the pencil's lines as they were", (final WidgetTester tester) async {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
        final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
        final Set<AngleData> angles = GetIt.I.get<ToolOptions>().lineOptions.angles;
        final List<(CoordinateSetI, CoordinateSetI)> lines = <(CoordinateSetI, CoordinateSetI)>[
          (CoordinateSetI(x: 2, y: 3), CoordinateSetI(x: 19, y: 9)),
          (CoordinateSetI(x: 15, y: 20), CoordinateSetI(x: -4, y: 1)),
          (CoordinateSetI(x: 5, y: 5), CoordinateSetI(x: 5, y: 17)),
          (CoordinateSetI(x: 8, y: 8), CoordinateSetI(x: 8, y: 8)),
        ];
        for (final PencilShape shape in PencilShape.values)
        {
          for (final int size in <int>[1, 2, 5, 12])
          {
            for (final (CoordinateSetI start, CoordinateSetI end) in lines)
            {
              final String reason = "${shape.name} size $size from $start to $end";
              expect(painter.getLinePoints(startPos: start, endPos: end, size: size, shape: shape).toList(),
                  _legacyLinePoints(painter: painter, startPos: start, endPos: end, size: size, shape: shape).toList(), reason: reason,);
              if (angles.isNotEmpty && start != end)
              {
                expect(painter.getIntegerRatioLinePoints(startPos: start, endPos: end, size: size, shape: shape, angles: angles).toList(),
                    _legacyIntegerRatioLinePoints(painter: painter, startPos: start, endPos: end, size: size, shape: shape, angles: angles).toList(), reason: reason,);
              }
            }
          }
        }
      },);
    });
  });

  group("a pencil stroke lands the same as before the dump only took the rest of the stroke", () {
    final List<_Scenario> scenarios = <_Scenario>[
      for (final PencilShape shape in PencilShape.values)
        for (final int size in <int>[1, 3, 6])
          for (final bool pixelPerfect in <bool>[true, false])
            _Scenario(shape: shape, size: size, pixelPerfect: pixelPerfect),
      const _Scenario(shape: PencilShape.round, size: 3, pixelPerfect: true, symmetry: 10.0),
      const _Scenario(shape: PencilShape.square, size: 2, pixelPerfect: false, symmetry: 7.5),
      const _Scenario(shape: PencilShape.round, size: 3, pixelPerfect: true, shaderEnabled: true),
      const _Scenario(shape: PencilShape.square, size: 3, pixelPerfect: false, target: _Target.lockedTransparency),
      const _Scenario(shape: PencilShape.round, size: 4, pixelPerfect: true, target: _Target.selection),
      const _Scenario(shape: PencilShape.round, size: 3, pixelPerfect: true, target: _Target.shadingLayer),
      const _Scenario(shape: PencilShape.square, size: 2, pixelPerfect: false, symmetry: 12.0, target: _Target.shadingLayer),
    ];
    for (final _Scenario scenario in scenarios)
    {
      testWidgets("$scenario", (final WidgetTester tester) async {
        final Map<String, String> expected = await _drawStroke(tester: tester, scenario: scenario, createPainter: () => LegacyPencilPainter(painterOptions: _painterOptions()));
        final Map<String, String> actual = await _drawStroke(tester: tester, scenario: scenario, createPainter: () => PencilPainter(painterOptions: _painterOptions()));
        expect(expected.values.where((final String value) => value != "-" && value != "null"), isNotEmpty, reason: "setup: the canvas holds something");
        expect(actual, expected);
      });
    }
  });

  testWidgets("a stroke lands as its preview showed it when the brush grows halfway", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference selected = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      GetIt.I.get<PaletteState>().colorSelected(color: selected);
      final PencilOptions options = GetIt.I.get<ToolOptions>().pencilOptions;
      options.shape.value = PencilShape.square;
      options.size.value = 1;
      options.pixelPerfect.value = false;
      GetIt.I.get<ShaderOptions>().isEnabled.value = false;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);

      final PencilPainter painter = PencilPainter(painterOptions: _painterOptions());
      for (int x = 2; x <= 12; x++)
      {
        painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: x, y: 5), primaryDown: true));
      }
      options.size.value = 5;
      for (int x = 13; x <= 20; x++)
      {
        painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: x, y: 5), primaryDown: true));
      }
      painter.calculate(drawParams: _params(layer: layer, cursor: CoordinateSetI(x: 20, y: 5), primaryDown: false));
      await settle();

      expect(layer.getDataEntry(coord: CoordinateSetI(x: 3, y: 5)), selected, reason: "setup: the thin part landed");
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 18, y: 7)), selected, reason: "setup: the wide part landed");
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 3, y: 6)), isNull,
          reason: "the start of the stroke was drawn with the small brush; landing it must not stamp it again with the large one",);
    },);
  });
}
