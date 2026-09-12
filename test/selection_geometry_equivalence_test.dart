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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/legacy_selection.dart';
import 'support/selection_harness.dart';

typedef _Line = (SelectionDirection, CoordinateSetI, CoordinateSetI);

//not square, and not a multiple of the buffer's tile size
final CoordinateSetI _canvasSize = CoordinateSetI(x: 23, y: 17);

CoordinateColorMapNullable _contentOf({required final SelectionList selection})
{
  final CoordinateColorMapNullable content = HashMap<CoordinateSetI, ColorReference?>();
  selection.forEachSelected(action: (final int x, final int y, final ColorReference? color) => content[CoordinateSetI(x: x, y: y)] = color);
  return content;
}

List<_Line> _linesOf({required final List<SelectionLine> lines})
{
  return <_Line>[for (final SelectionLine line in lines) (line.selectDir, line.startLoc, line.endLoc)];
}

/// Whether the reference can be trusted for this shape: its bounding box starts
/// out at the canvas size and at -1, so a selection that sits entirely beyond
/// the right or bottom edge, or entirely before the left or top one, throws it
/// off. The buffer measures the true box instead (see the separate test).
bool _referenceIsSound({required final CoordinateColorMapNullable content})
{
  if (content.isEmpty)
  {
    return false;
  }
  final Iterable<int> xs = content.keys.map((final CoordinateSetI coord) => coord.x);
  final Iterable<int> ys = content.keys.map((final CoordinateSetI coord) => coord.y);
  return xs.reduce(min) < _canvasSize.x && xs.reduce(max) >= 0 && ys.reduce(min) < _canvasSize.y && ys.reduce(max) >= 0;
}

void main()
{
  testWidgets("the selection buffer matches the map-based selection over random shapes, transforms and moves", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final List<ColorReference?> colors = <ColorReference?>[
        null,
        palette.colorRamps[0].references[0],
        palette.colorRamps[0].references[2],
        palette.colorRamps[1].references[1],
      ];
      final SelectionState selectionState = GetIt.I.get<DocumentState>().selectionState;
      final SelectionList selection = selectionState.selection;
      final Random random = Random(11);
      int comparisons = 0;

      void expectSame({required final LegacySelection legacy, required final String what})
      {
        expect(_contentOf(selection: selection), legacy.content, reason: what);
        expect(selection.getBoundingBox(), legacy.getBoundingBox(), reason: what);
        selectionState.createSelectionLines();
        expect(_linesOf(lines: selectionState.selectionLines), _linesOf(lines: legacySelectionLines(content: legacy.content)), reason: what);
        comparisons++;
      }

      for (int scene = 0; scene < 15; scene++)
      {
        //a shape that reaches off the canvas, with a hole or two in it
        final CoordinateColorMapNullable start = HashMap<CoordinateSetI, ColorReference?>();
        final int left = random.nextInt(_canvasSize.x) - 3;
        final int top = random.nextInt(_canvasSize.y) - 3;
        final int width = 1 + random.nextInt(9);
        final int height = 1 + random.nextInt(9);
        for (int x = left; x < left + width; x++)
        {
          for (int y = top; y < top + height; y++)
          {
            if (random.nextInt(4) != 0)
            {
              start[CoordinateSetI(x: x, y: y)] = colors[random.nextInt(colors.length)];
            }
          }
        }
        if (start.isEmpty)
        {
          continue;
        }

        final LegacySelection legacy = LegacySelection(canvasSize: _canvasSize);
        selection.delete(keepSelection: false);
        selection.addDirectlyAll(list: start);
        legacy.content = HashMap<CoordinateSetI, ColorReference?>.of(start);
        if (!_referenceIsSound(content: legacy.content))
        {
          continue;
        }
        expectSame(legacy: legacy, what: "scene $scene, fresh");

        for (int step = 0; step < 8; step++)
        {
          final int action = random.nextInt(6);
          if (action == 0)
          {
            selection.flipH();
            legacy.flipH();
          }
          else if (action == 1)
          {
            selection.flipV();
            legacy.flipV();
          }
          else if (action == 2)
          {
            selection.rotate90cw();
            legacy.rotate90cw();
          }
          else if (action == 3)
          {
            //a move, as the selection tool makes it: several offsets from where
            //the move started, then a reset
            for (int move = 0; move < 3; move++)
            {
              final CoordinateSetI offset = CoordinateSetI(x: random.nextInt(9) - 4, y: random.nextInt(9) - 4);
              selection.shiftSelection(offset: offset, withContent: true);
              legacy.shiftSelection(offset: offset);
            }
            selection.resetLastOffset();
            legacy.resetLastOffset();
          }
          else if (action == 4)
          {
            final CoordinateSetI coord = legacy.content.keys.elementAt(random.nextInt(legacy.content.length));
            selection.deleteDirectly(coord: coord);
            if (legacy.content[coord] != null)
            {
              legacy.content[coord] = null;
            }
          }
          else
          {
            final CoordinateSetI coord = CoordinateSetI(x: random.nextInt(_canvasSize.x + 8) - 4, y: random.nextInt(_canvasSize.y + 8) - 4);
            final ColorReference? color = colors[random.nextInt(colors.length)];
            selection.addDirectly(coord: coord, colRef: color);
            legacy.content[coord] = color;
          }
          if (!_referenceIsSound(content: legacy.content))
          {
            break;
          }
          expectSame(legacy: legacy, what: "scene $scene, step $step, action $action");
        }
      }
      expect(comparisons, greaterThan(60), reason: "the scenes have to get far enough to be worth comparing");
    },);
  });
}
