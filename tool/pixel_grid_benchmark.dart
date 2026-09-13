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
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

//the largest canvas, fully painted
const int _size = 640;
//a palette of 64 ramps with 15 colors each
const int _colorCount = 960;
//bytes per pixel of the HashMap layer storage, measured in docs/dev/pixel_storage_plan.md §1
const int _hashMapBytesPerPixel = 104;

int _sink = 0;

void _time({required final String name, required final void Function() body, final int repetitions = 5})
{
  body();
  final Stopwatch stopwatch = Stopwatch()..start();
  for (int i = 0; i < repetitions; i++)
  {
    body();
  }
  stopwatch.stop();
  final double milliseconds = stopwatch.elapsedMicroseconds / repetitions / 1000.0;
  stdout.writeln("${name.padRight(62)} ${milliseconds.toStringAsFixed(2).padLeft(8)} ms");
}

String _kiloBytes({required final int bytes})
{
  return "${(bytes / 1024).toStringAsFixed(0)} KB";
}

/// Times [PixelGrid] against the `HashMap<CoordinateSetI, …>` it replaces.
///
/// Pure Dart, so it runs outside Flutter. For numbers that match a release
/// build, compile it ahead of time:
///
///     dart compile exe tool/pixel_grid_benchmark.dart -o <somewhere>/pixel_grid_benchmark.exe
void main()
{
  //stand-ins for the shared ColorReference objects a layer map points to
  final List<Object> colors = List<Object>.generate(_colorCount, (final int i) => Object());
  final HashMap<CoordinateSetI, Object> map = HashMap<CoordinateSetI, Object>();
  final PixelGrid grid = PixelGrid(width: _size, height: _size);

  stdout.writeln("$_size x $_size, every pixel set\n");

  _time(name: "fill every pixel: HashMap", repetitions: 3, body: () {
    map.clear();
    for (int y = 0; y < _size; y++)
    {
      for (int x = 0; x < _size; x++)
      {
        map[CoordinateSetI(x: x, y: y)] = colors[(x + y) % _colorCount];
      }
    }
  },);
  _time(name: "fill every pixel: PixelGrid", repetitions: 3, body: () {
    grid.clear();
    for (int y = 0; y < _size; y++)
    {
      for (int x = 0; x < _size; x++)
      {
        grid.set(x: x, y: y, value: (x + y) % _colorCount + 1);
      }
    }
  },);

  _time(name: "read every pixel by coordinate: HashMap", body: () {
    int found = 0;
    for (int x = 0; x < _size; x++)
    {
      for (int y = 0; y < _size; y++)
      {
        if (map[CoordinateSetI(x: x, y: y)] != null)
        {
          found++;
        }
      }
    }
    _sink += found;
  },);
  _time(name: "read every pixel by coordinate: PixelGrid", body: () {
    int found = 0;
    for (int x = 0; x < _size; x++)
    {
      for (int y = 0; y < _size; y++)
      {
        if (grid.get(x: x, y: y) != 0)
        {
          found++;
        }
      }
    }
    _sink += found;
  },);

  _time(name: "visit every set pixel: HashMap entries", body: () {
    int sum = 0;
    for (final MapEntry<CoordinateSetI, Object> entry in map.entries)
    {
      sum += entry.key.x;
    }
    _sink += sum;
  },);
  _time(name: "visit every set pixel: PixelGrid.forEachNonZero", body: () {
    int sum = 0;
    grid.forEachNonZero(action: (final int x, final int y, final int value) {
      sum += x;
    },);
    _sink += sum;
  },);

  _time(name: "copy the layer: HashMap.from", repetitions: 3, body: () {
    _sink += HashMap<CoordinateSetI, Object>.from(map).length;
  },);
  _time(name: "copy the layer: PixelGrid.copy", body: () {
    _sink += grid.copy().nonZeroCount;
  },);
  _time(name: "copy, then write into every tile (worst case clone)", body: () {
    final PixelGrid copy = grid.copy();
    for (int y = 0; y < _size; y += PixelGridView.tileSize)
    {
      for (int x = 0; x < _size; x += PixelGridView.tileSize)
      {
        copy.set(x: x, y: y, value: copy.get(x: x, y: y) % _colorCount + 1);
      }
    }
    _sink += copy.nonZeroCount;
  },);
  int toggle = 1;
  _time(name: "history step: one pixel changed, then snapshot", repetitions: 100, body: () {
    toggle = toggle == 1 ? 2 : 1;
    grid.set(x: 0, y: 0, value: toggle);
    _sink += grid.snapshot().nonZeroCount;
  },);

  //a permutation of all codes, so every pixel changes on every pass
  final Uint16List lut = Uint16List(_colorCount + 1);
  for (int code = 1; code <= _colorCount; code++)
  {
    lut[code] = code % _colorCount + 1;
  }
  _time(name: "remap every pixel (palette reorder)", body: () => grid.remap(lut: lut));
  _time(name: "rotate a quarter", repetitions: 3, body: () {
    _sink += grid.rotatedClockwise().nonZeroCount;
  },);

  const int tileBytes = PixelGridView.tileSize * PixelGridView.tileSize * 2;
  stdout.writeln("\nmemory, pixel data only");
  stdout.writeln("  full layer:   PixelGrid ${_kiloBytes(bytes: grid.allocatedTileCount * tileBytes)}, "
      "HashMap ~${_kiloBytes(bytes: grid.nonZeroCount * _hashMapBytesPerPixel)}",);
  final Random random = Random(1);
  final PixelGrid sparse = PixelGrid(width: _size, height: _size);
  for (int i = 0; i < _size * _size ~/ 20; i++)
  {
    sparse.set(x: random.nextInt(_size), y: random.nextInt(_size), value: 1);
  }
  stdout.writeln("  5% scattered: PixelGrid ${_kiloBytes(bytes: sparse.allocatedTileCount * tileBytes)}, "
      "HashMap ~${_kiloBytes(bytes: sparse.nonZeroCount * _hashMapBytesPerPixel)}",);
  final PixelGrid sprite = PixelGrid(width: _size, height: _size);
  for (int y = 300; y < 364; y++)
  {
    for (int x = 300; x < 364; x++)
    {
      sprite.set(x: x, y: y, value: 1);
    }
  }
  stdout.writeln("  64x64 sprite: PixelGrid ${_kiloBytes(bytes: sprite.allocatedTileCount * tileBytes)}, "
      "HashMap ~${_kiloBytes(bytes: sprite.nonZeroCount * _hashMapBytesPerPixel)}",);
  stdout.writeln("\n(checksum $_sink)");
}
