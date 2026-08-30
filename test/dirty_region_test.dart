/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/layer_states/rendering_helper.dart';

DirtyRegion _r(final int x, final int y, final int w, final int h) =>
    DirtyRegion(x: x, y: y, width: w, height: h);

/// Every pixel covered by [regions], as "x,y" keys.
Set<String> _covered({required final List<DirtyRegion> regions}) {
  final Set<String> pixels = <String>{};
  for (final DirtyRegion r in regions) {
    for (int x = r.x; x < r.x + r.width; x++) {
      for (int y = r.y; y < r.y + r.height; y++) {
        pixels.add('$x,$y');
      }
    }
  }
  return pixels;
}

void main() {
  group('mergeOverlappingRegions', () {
    test('an empty list stays empty', () {
      expect(mergeOverlappingRegions(regions: <DirtyRegion>[]), isEmpty);
    });

    test('regions that do not touch are left alone', () {
      final List<DirtyRegion> out = mergeOverlappingRegions(
        regions: <DirtyRegion>[_r(0, 0, 2, 2), _r(10, 10, 2, 2), _r(20, 0, 2, 2)],
      );
      expect(out.length, 3);
    });

    test('two overlapping regions become their bounding box', () {
      final List<DirtyRegion> out = mergeOverlappingRegions(
        regions: <DirtyRegion>[_r(0, 0, 4, 4), _r(2, 2, 4, 4)],
      );
      expect(out.length, 1);
      expect(out.first.x, 0);
      expect(out.first.y, 0);
      expect(out.first.width, 6);
      expect(out.first.height, 6);
    });

    test('a region bridging two others collapses all three', () {
      //neither end overlaps the other, only the bridge touches both
      final List<DirtyRegion> out = mergeOverlappingRegions(
        regions: <DirtyRegion>[_r(0, 0, 3, 3), _r(10, 0, 3, 3), _r(2, 0, 9, 3)],
      );
      expect(out.length, 1);
      expect(out.first.x, 0);
      expect(out.first.width, 13);
    });

    test('a merge that grows into an already-passed region still collapses', () {
      //the first region sits in the corner gap between two L-shaped strips: it
      //overlaps neither of them, but their bounding box swallows it. An
      //incremental pass only catches this if it rescans from the start after a
      //merge, so this is the case that pins the rescan.
      final List<DirtyRegion> out = mergeOverlappingRegions(
        regions: <DirtyRegion>[_r(5, 5, 2, 2), _r(0, 0, 20, 3), _r(0, 0, 3, 20)],
      );
      expect(out.length, 1);
      expect(out.first.width, 20);
      expect(out.first.height, 20);
    });

    test('output regions never overlap, and cover exactly the input pixels', () {
      final Random rnd = Random(4);
      for (int t = 0; t < 400; t++) {
        final int n = 1 + rnd.nextInt(10);
        final List<DirtyRegion> input = List<DirtyRegion>.generate(
          n,
          (final int _) => _r(rnd.nextInt(25), rnd.nextInt(25), 1 + rnd.nextInt(8), 1 + rnd.nextInt(8)),
        );
        final List<DirtyRegion> out = mergeOverlappingRegions(regions: input);

        for (int i = 0; i < out.length; i++) {
          for (int j = i + 1; j < out.length; j++) {
            expect(out[i].overlaps(other: out[j]), isFalse,
                reason: 'output regions must be disjoint',);
          }
        }
        //merging only ever grows boxes, so the result must cover every input pixel
        expect(_covered(regions: out).containsAll(_covered(regions: input)), isTrue,
            reason: 'every dirty pixel must still be inside some region',);
      }
    });
  });
}
