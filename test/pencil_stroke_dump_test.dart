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
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/models/kpix_painter_options.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/painting/itool_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

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

final CoordinateSetI _canvasSize = CoordinateSetI(x: 24, y: 24);

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
