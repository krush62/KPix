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

import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

/// The geometry of the map-based selection, copied from
/// `lib/models/selection_state.dart` at commit 8e5d3c8, before the selection
/// moved onto a [SelectionBuffer]. It is the reference the buffer is checked
/// against in `selection_geometry_equivalence_test.dart`.
///
/// Only the data access changed: the content map and the canvas size are fields
/// of this class instead of the selection's and the canvas state's, and the
/// selection lines are returned instead of being stored on the selection state.
/// Everything else is the original code, quirks included.
class LegacySelection
{
  LegacySelection({required this.canvasSize});

  CoordinateColorMapNullable content = HashMap<CoordinateSetI, ColorReference?>();
  final CoordinateSetI canvasSize;
  final CoordinateSetI _lastOffset = CoordinateSetI.zero();

  void flipH()
  {
    final CoordinateSetI minXcoord = content.keys.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x < b.x ? a : b);
    final CoordinateSetI maxXcoord = content.keys.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.x > b.x ? a : b);

    final CoordinateColorMapNullable newContent = HashMap<CoordinateSetI, ColorReference?>();
    for (final CoordinateColorNullable entry in content.entries)
    {
      newContent[CoordinateSetI(x: maxXcoord.x - entry.key.x + minXcoord.x , y: entry.key.y)] = entry.value;
    }
    content = newContent;
  }

  void flipV()
  {
    final CoordinateSetI minYcoord = content.keys.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y < b.y ? a : b);
    final CoordinateSetI maxYcoord = content.keys.reduce((final CoordinateSetI a, final CoordinateSetI b) => a.y > b.y ? a : b);

    final CoordinateColorMapNullable newContent = HashMap<CoordinateSetI, ColorReference?>();
    for (final CoordinateColorNullable entry in content.entries)
    {
      newContent[CoordinateSetI(x: entry.key.x, y: maxYcoord.y - entry.key.y + minYcoord.y)] = entry.value;
    }
    content = newContent;
  }

  void rotate90cw()
  {
    final CoordinateSetI minCoords = CoordinateSetI.from(other: canvasSize);
    final CoordinateSetI maxCoords = CoordinateSetI.zero();
    for (final CoordinateSetI coord in content.keys)
    {
      minCoords.x = min(coord.x, minCoords.x);
      minCoords.y = min(coord.y, minCoords.y);
      maxCoords.x = max(coord.x, maxCoords.x);
      maxCoords.y = max(coord.y, maxCoords.y);
    }

    final CoordinateSetI centerCoord = CoordinateSetI(x: (minCoords.x + maxCoords.x) ~/ 2, y: (minCoords.y + maxCoords.y) ~/ 2);
    final CoordinateColorMapNullable newContent = HashMap<CoordinateSetI, ColorReference?>();
    for (final CoordinateColorNullable entry in content.entries)
    {
      newContent[CoordinateSetI(x: centerCoord.y - entry.key.y + centerCoord.x, y: entry.key.x - centerCoord.x + centerCoord.y)] = entry.value;
    }
    content = newContent;
  }

  void shiftSelection({required final CoordinateSetI offset})
  {
    if (offset != _lastOffset)
    {
      final CoordinateColorMapNullable newContent = HashMap<CoordinateSetI, ColorReference?>();
      for (final CoordinateColorNullable entry in content.entries)
      {
        newContent[CoordinateSetI(x: entry.key.x + (offset.x - _lastOffset.x), y: entry.key.y + (offset.y - _lastOffset.y))] = entry.value;
      }
      content = newContent;
      _lastOffset.x = offset.x;
      _lastOffset.y = offset.y;
    }
  }

  void resetLastOffset()
  {
    _lastOffset.x = 0;
    _lastOffset.y = 0;
  }

  (CoordinateSetI?, CoordinateSetI?) getBoundingBox()
  {
    CoordinateSetI? topLeft;
    CoordinateSetI? bottomRight;
    int minX = canvasSize.x;
    int maxX = -1;
    int minY = canvasSize.y;
    int maxY = -1;

    final Iterable<CoordinateSetI> allCoords = content.keys;
    for (final CoordinateSetI coord in allCoords)
    {
      minX = min(minX, coord.x);
      maxX = max(maxX, coord.x);
      minY = min(minY, coord.y);
      maxY = max(maxY, coord.y);
    }

    if (minX <= maxX && minY <= maxY)
    {
       topLeft = CoordinateSetI(x: minX, y: minY);
       bottomRight = CoordinateSetI(x: maxX, y: maxY);
    }
    return (topLeft, bottomRight);
  }
}

/// The map-based `SelectionState.createSelectionLines`, `_areContiguous` and
/// `extendLine` from the same commit, over [content].
List<SelectionLine> legacySelectionLines({required final CoordinateColorMapNullable content})
{
  final List<SelectionLine> selectionLines = <SelectionLine>[];
  final List<SelectionLine> unMergedLines = <SelectionLine>[];
  final Iterable<CoordinateSetI> selectedCoordinates = content.keys;

  // Step 1: Add all boundary lines
  for (final CoordinateSetI coord in selectedCoordinates)
  {
    if (!content.containsKey(CoordinateSetI(x: coord.x - 1, y: coord.y)))
    {
      unMergedLines.add(SelectionLine(selectDir: SelectionDirection.left, startLoc: coord, endLoc: coord));
    }
    if (!content.containsKey(CoordinateSetI(x: coord.x + 1, y: coord.y)))
    {
      unMergedLines.add(SelectionLine(selectDir: SelectionDirection.right, startLoc: coord, endLoc: coord));
    }
    if (!content.containsKey(CoordinateSetI(x: coord.x, y: coord.y - 1))) {
      unMergedLines.add(SelectionLine(selectDir: SelectionDirection.top, startLoc: coord, endLoc: coord));
    }
    if (!content.containsKey(CoordinateSetI(x: coord.x, y: coord.y + 1)))
    {
      unMergedLines.add(SelectionLine(selectDir: SelectionDirection.bottom, startLoc: coord, endLoc: coord));
    }
  }

  // Step 2: Merge contiguous lines
  if (unMergedLines.isNotEmpty)
  {
    final Map<SelectionDirection, List<SelectionLine>> groupedLines =
    <SelectionDirection, List<SelectionLine>>{
      SelectionDirection.left: <SelectionLine>[],
      SelectionDirection.right: <SelectionLine>[],
      SelectionDirection.top: <SelectionLine>[],
      SelectionDirection.bottom: <SelectionLine>[],
      SelectionDirection.undefined: <SelectionLine>[],
    };

    for (final SelectionLine line in unMergedLines)
    {
      groupedLines[line.selectDir]!.add(line);
    }

    for (final SelectionDirection direction in SelectionDirection.values)
    {
      final List<SelectionLine> directionLines = groupedLines[direction]!;

      directionLines.sort((final SelectionLine a, final SelectionLine b) {
        if (direction == SelectionDirection.top || direction == SelectionDirection.bottom)
        {
          return (a.startLoc.y != b.startLoc.y)
              ? a.startLoc.y - b.startLoc.y
              : a.startLoc.x - b.startLoc.x;
        }
        else
        {
          return (a.startLoc.x != b.startLoc.x)
              ? a.startLoc.x - b.startLoc.x
              : a.startLoc.y - b.startLoc.y;
        }
      });

      SelectionLine? currentLine;
      for (final SelectionLine line in directionLines)
      {
        if (currentLine == null)
        {
          currentLine = line;
        }
        else if (_areContiguous(a: currentLine, b: line))
        {
          _extendLine(a: currentLine, b: line);
        }
        else
        {
          selectionLines.add(currentLine);
          currentLine = line;
        }
      }

      if (currentLine != null)
      {
        selectionLines.add(currentLine);
      }
    }
  }
  return selectionLines;
}

bool _areContiguous({required final SelectionLine a, required final SelectionLine b})
{
  if (a.selectDir == SelectionDirection.top || a.selectDir == SelectionDirection.bottom) {
    // Horizontal: same y, touching or overlapping in x
    return a.startLoc.y == b.startLoc.y &&
        (a.endLoc.x + 1 == b.startLoc.x || b.endLoc.x + 1 == a.startLoc.x);
  } else {
    // Vertical: same x, touching or overlapping in y
    return a.startLoc.x == b.startLoc.x &&
        (a.endLoc.y + 1 == b.startLoc.y || b.endLoc.y + 1 == a.startLoc.y);
  }
}

void _extendLine({required final SelectionLine a, required final SelectionLine b})
{
  if (a.selectDir == SelectionDirection.top || a.selectDir == SelectionDirection.bottom)
  {
    // Horizontal: extend x bounds
    a.startLoc = CoordinateSetI(
        x: min(a.startLoc.x, b.startLoc.x), y: a.startLoc.y,);
    a.endLoc = CoordinateSetI(x: max(a.endLoc.x, b.endLoc.x), y: a.endLoc.y);
  }
  else
  {
    // Vertical: extend y bounds
    a.startLoc = CoordinateSetI(
        x: a.startLoc.x, y: min(a.startLoc.y, b.startLoc.y),);
    a.endLoc = CoordinateSetI(x: a.endLoc.x, y: max(a.endLoc.y, b.endLoc.y));
  }
}
