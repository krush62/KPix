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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/drawing_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 13, y: 11);

const Map<GridType, List<String>> _patterns = <GridType, List<String>>{
  GridType.rectangular: <String>[
    "#############",
    "#...#...#...#",
    "#...#...#...#",
    "#...#...#...#",
    "#############",
    "#...#...#...#",
    "#...#...#...#",
    "#...#...#...#",
    "#############",
    "#...#...#...#",
    "#...#...#...#",
  ],
  GridType.diagonal: <String>[
    "#...#...#...#",
    ".#.#.#.#.#.#.",
    "..#...#...#..",
    ".#.#.#.#.#.#.",
    "#...#...#...#",
    ".#.#.#.#.#.#.",
    "..#...#...#..",
    ".#.#.#.#.#.#.",
    "#...#...#...#",
    ".#.#.#.#.#.#.",
    "..#...#...#..",
  ],
  GridType.isometric: <String>[
    "##......##...",
    "..##..##..##.",
    "....##......#",
    "..##..##..##.",
    "##......##...",
    "..##..##..##.",
    "....##......#",
    "..##..##..##.",
    "##......##...",
    "..##..##..##.",
    "....##......#",
  ],
  GridType.hexagonal: <String>[
    "#####.......#",
    ".....#.....#.",
    ".....#.....#.",
    "......#####..",
    ".....#.....#.",
    ".....#.....#.",
    "#####.......#",
    ".....#.....#.",
    ".....#.....#.",
    "......#####..",
    ".....#.....#.",
  ],
  GridType.triangular: <String>[
    "#############",
    "..#...#...#..",
    ".#.#.#.#.#.#.",
    ".#.#.#.#.#.#.",
    "#############",
    "..#...#...#..",
    ".#.#.#.#.#.#.",
    ".#.#.#.#.#.#.",
    "#############",
    "..#...#...#..",
    ".#.#.#.#.#.#.",
  ],
  GridType.brick: <String>[
    "#############",
    "..#...#...#..",
    "..#...#...#..",
    "..#...#...#..",
    "#############",
    "#...#...#...#",
    "#...#...#...#",
    "#...#...#...#",
    "#############",
    "..#...#...#..",
    "..#...#...#..",
  ],
  GridType.onePointPerspective: <String>[
    "#..#..#..#.##",
    ".#.#.#.####..",
    "..###.###....",
    "#######.#####",
    "#############",
    "#######.#####",
    "..#######....",
    ".####.#####..",
    "##.#.#.#.#.##",
    ".#.#.#..#.##.",
    "#..#..#..#..#",
  ],
  GridType.twoPointPerspective: <String>[
    "##.#..#..#.##",
    ".#####.#####.",
    "..#######.##.",
    "#############",
    "#############",
    "#############",
    "..##########.",
    "..##########.",
    "##.###.#.#.##",
    ".#####.######",
    "#..#..#..#..#",
  ],
  GridType.threePointPerspective: <String>[
    "##.#..#..#.##",
    ".###########.",
    ".########.##.",
    "#############",
    "#############",
    "#############",
    ".###########.",
    "..##########.",
    "##.#######.##",
    ".############",
    "#############",
  ],
};

/// A grid with intervals of 4, a horizon at 0.4 and vanishing points at 0.25, 0.75
/// and 0.9.
Future<GridLayerState> _grid() async
{
  final GridLayerState grid = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.grid, select: true).$2! as GridLayerState;
  grid.intervalXNotifier.value = 4;
  grid.intervalYNotifier.value = 4;
  grid.horizonPositionNotifier.value = 0.4;
  grid.vanishingPoint1Notifier.value = 0.25;
  grid.vanishingPoint2Notifier.value = 0.75;
  grid.vanishingPoint3Notifier.value = 0.9;
  await grid.rasterizationComplete;
  return grid;
}

void _gridTest(final String description, final Future<void> Function(GridLayerState grid) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await body(await _grid());
    },);
  });
}

void main()
{
  test("every grid type has a pattern to check", ()
  {
    expect(_patterns.keys.toSet(), GridType.values.toSet());
  });

  for (final MapEntry<GridType, List<String>> pattern in _patterns.entries)
  {
    _gridTest("draws the ${pattern.key.name} pattern", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = pattern.key;

      expect(patternOf(coords: await grid.getRasterData(), size: _canvasSize), pattern.value);
    });
  }

  group("the intervals", ()
  {
    _gridTest("apply to the columns and the rows on their own", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.rectangular;
      grid.intervalXNotifier.value = 3;
      grid.intervalYNotifier.value = 5;

      final Set<CoordinateSetI> coords = await grid.getRasterData();

      for (int x = 0; x < _canvasSize.x; x++)
      {
        for (int y = 0; y < _canvasSize.y; y++)
        {
          expect(coords.contains(CoordinateSetI(x: x, y: y)), x % 3 == 0 || y % 5 == 0, reason: "$x|$y");
        }
      }
    });

    _gridTest("offset every other row of bricks", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.brick;
      grid.intervalXNotifier.value = 6;
      grid.intervalYNotifier.value = 3;

      final Set<CoordinateSetI> coords = await grid.getRasterData();

      expect(coords.contains(CoordinateSetI(x: 3, y: 1)), isTrue, reason: "the mortar of the first row");
      expect(coords.contains(CoordinateSetI(x: 0, y: 1)), isFalse);
      expect(coords.contains(CoordinateSetI(x: 0, y: 4)), isTrue, reason: "the mortar of the second row");
      expect(coords.contains(CoordinateSetI(x: 3, y: 4)), isFalse);
    });

    _gridTest("larger than the canvas leave only the first lines", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.rectangular;
      grid.intervalXNotifier.value = 40;
      grid.intervalYNotifier.value = 40;

      expect(await grid.getRasterData(), <CoordinateSetI>{
        for (int x = 0; x < _canvasSize.x; x++) CoordinateSetI(x: x, y: 0),
        for (int y = 0; y < _canvasSize.y; y++) CoordinateSetI(x: 0, y: y),
      });
    });
  });

  group("the perspective", ()
  {
    _gridTest("always shows the horizon and reaches the corners", (final GridLayerState grid) async
    {
      for (final GridType type in <GridType>[GridType.onePointPerspective, GridType.twoPointPerspective, GridType.threePointPerspective])
      {
        grid.gridTypeNotifier.value = type;

        final Set<CoordinateSetI> coords = await grid.getRasterData();

        expect(coords, containsAll(<CoordinateSetI>[for (int x = 0; x < _canvasSize.x; x++) CoordinateSetI(x: x, y: 4)]), reason: "${type.name}: the horizon");
        expect(coords, containsAll(<CoordinateSetI>[CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 12, y: 0), CoordinateSetI(x: 0, y: 10), CoordinateSetI(x: 12, y: 10)]), reason: "${type.name}: the corners");
      }
    });

    _gridTest("takes its horizon from the setting", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.onePointPerspective;
      grid.horizonPositionNotifier.value = 0.8;

      expect(await grid.getRasterData(), containsAll(<CoordinateSetI>[for (int x = 0; x < _canvasSize.x; x++) CoordinateSetI(x: x, y: 9)]));
    });

    _gridTest("runs its lines from the vanishing point", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.onePointPerspective;
      grid.vanishingPoint1Notifier.value = 0.5;
      final CoordinateSetI vanishingPoint = CoordinateSetI(x: 7, y: 4);

      expect(await grid.getRasterData(), containsAll(bresenham(start: vanishingPoint, end: CoordinateSetI(x: 0, y: 0))));
    });

    _gridTest("still reaches the far side from a vanishing point on the edge", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.onePointPerspective;
      grid.vanishingPoint1Notifier.value = 0.0;
      grid.intervalXNotifier.value = 2;

      expect(await grid.getRasterData(), containsAll(bresenham(start: CoordinateSetI(x: 0, y: 4), end: CoordinateSetI(x: 12, y: 5))));
    });

    _gridTest("the third vanishing point fans out to the side away from the horizon", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.threePointPerspective;
      grid.intervalXNotifier.value = 4;

      //below the horizon: the lines go up
      grid.vanishingPoint3Notifier.value = 0.9;
      final Set<CoordinateSetI> below = await grid.getRasterData();
      expect(below, containsAll(bresenham(start: CoordinateSetI(x: 6, y: 10), end: CoordinateSetI(x: 6, y: 0))), reason: "from the third point up the middle");

      //above the horizon: the lines go down
      grid.vanishingPoint3Notifier.value = 0.1;
      final Set<CoordinateSetI> above = await grid.getRasterData();
      expect(above, containsAll(bresenham(start: CoordinateSetI(x: 6, y: 1), end: CoordinateSetI(x: 6, y: 10))), reason: "from the third point down the middle");
    });
  });

  group("the raster", ()
  {
    Future<ByteData> rendered({required final GridLayerState grid}) async
    {
      await grid.rasterizationComplete;
      await settle();
      return (await grid.raster!.toByteData())!;
    }

    int alphaAt({required final ByteData data, required final int x, required final int y}) => data.getUint8((y * _canvasSize.x + x) * 4 + 3);

    int redAt({required final ByteData data, required final int x, required final int y}) => data.getUint8((y * _canvasSize.x + x) * 4);

    _gridTest("colors the lines and leaves the rest empty", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.rectangular;
      grid.opacityNotifier.value = 100;
      grid.brightnessNotifier.value = 100;

      final ByteData data = await rendered(grid: grid);

      expect(grid.raster!.width, _canvasSize.x);
      expect(alphaAt(data: data, x: 0, y: 0), 255);
      expect(redAt(data: data, x: 0, y: 0), 255);
      expect(alphaAt(data: data, x: 1, y: 1), 0);
    });

    _gridTest("takes its opacity and brightness from the settings", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.rectangular;
      grid.opacityNotifier.value = 100;
      grid.brightnessNotifier.value = 0;
      expect(redAt(data: await rendered(grid: grid), x: 0, y: 0), 0);

      grid.brightnessNotifier.value = 100;
      grid.opacityNotifier.value = 50;
      final ByteData faded = await rendered(grid: grid);

      expect(alphaAt(data: faded, x: 0, y: 0), 128);
      expect(redAt(data: faded, x: 0, y: 0), 128, reason: "the colors are premultiplied");
    });

    _gridTest("follows a manual render and shows on its thumbnail", (final GridLayerState grid) async
    {
      grid.manualRender();
      await rendered(grid: grid);

      expect(grid.thumbnail.value, same(grid.raster));
    });

    _gridTest("stops rendering once it is disposed", (final GridLayerState grid) async
    {
      final ui.Image? before = grid.raster;
      expect(before, isNotNull, reason: "setup");

      grid.dispose();

      expect(grid.isDisposed, isTrue);
      expect(grid.raster, isNull);
      expect(grid.thumbnail.value, isNull);
    });
  });

  group("the grid as colors", ()
  {
    _gridTest("holds the selected color on every line", (final GridLayerState grid) async
    {
      grid.gridTypeNotifier.value = GridType.rectangular;

      final Map<CoordinateSetI, ColorReference> colors = await grid.getHashMap();

      expect(colors.keys.toSet(), await grid.getRasterData());
      expect(colors.values.toSet(), <ColorReference>{GetIt.I.get<PaletteState>().selectedColor!});
    });
  });
}
