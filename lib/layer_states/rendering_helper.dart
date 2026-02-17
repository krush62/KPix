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

import 'package:kpix/util/helper.dart';

class DirtyRegion {
  final int x;
  final int y;
  final int width;
  final int height;

  DirtyRegion({required this.x, required this.y, required this.width, required this.height});

  DirtyRegion expand({required final int padding}) {
    return DirtyRegion(
      x: x - padding,
      y: y - padding,
      width: width + padding * 2,
      height: height + padding * 2,
    );
  }

  bool overlaps({required final DirtyRegion other}) {
    return x < other.x + other.width &&
        x + width > other.x &&
        y < other.y + other.height &&
        y + height > other.y;
  }

  DirtyRegion merge({required final DirtyRegion other}) {
    final int newX = min(x, other.x);
    final int newY = min(y, other.y);
    final int newRight = max(x + width, other.x + other.width);
    final int newBottom = max(y + height, other.y + other.height);

    return DirtyRegion(
      x: newX,
      y: newY,
      width: newRight - newX,
      height: newBottom - newY,
    );
  }

  int get area => width * height;
}

enum RenderStrategy
{
  full,
  regional,
}

RenderStrategy determineStrategy({required final List<DirtyRegion> dirtyRegions, required final CoordinateSetI canvasSize,})
{
  if (dirtyRegions.isEmpty)
  {
    return RenderStrategy.full;
  }

  final List<DirtyRegion> merged = mergeOverlappingRegions(regions: dirtyRegions);

  int totalDirtyArea = 0;
  for (final DirtyRegion region in merged)
  {
    totalDirtyArea += region.area;
  }

  final int canvasArea = canvasSize.x * canvasSize.y;
  final double dirtyPercentage = totalDirtyArea / canvasArea;

  if (dirtyPercentage > 0.3) {
    return RenderStrategy.full;
  }

  if (merged.length > 20) {
    return RenderStrategy.full;
  }

  return RenderStrategy.regional;
}

List<DirtyRegion> mergeOverlappingRegions({required final List<DirtyRegion> regions}) {
  if (regions.isEmpty) return <DirtyRegion>[];

  final List<DirtyRegion> merged = List<DirtyRegion>.from(regions);
  bool didMerge = true;

  while (didMerge)
  {
    didMerge = false;

    for (int i = 0; i < merged.length; i++)
    {
      for (int j = i + 1; j < merged.length; j++)
      {
        if (merged[i].overlaps(other: merged[j]))
        {
          final DirtyRegion newRegion = merged[i].merge(other: merged[j]);
          merged.removeAt(j);
          merged.removeAt(i);
          merged.add(newRegion);
          didMerge = true;
          break;
        }
      }
      if (didMerge) break;
    }
  }

  return merged;
}
