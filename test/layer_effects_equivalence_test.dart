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
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/layer_effects.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/drawing_layer_settings_constraints.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/legacy_layer_effects.dart';

const DrawingLayerSettingsConstraints _constraints = DrawingLayerSettingsConstraints(
  darkenBrightenMin: -5,
  darkenBrightenDefault: 1,
  darkenBrightenMax: 5,
  glowDepthMin: -5,
  glowDepthDefault: 1,
  glowDepthMax: 5,
  glowRecursiveDefault: false,
  bevelDistanceMin: 1,
  bevelDistanceDefault: 2,
  bevelDistanceMax: 8,
  bevelStrengthMin: 1,
  bevelStrengthDefault: 1,
  bevelStrengthMax: 8,
  dropShadowOffsetMin: -16,
  dropShadowOffsetDefault: 1,
  dropShadowOffsetMax: 16,
);

//not square, so that mixing up x and y shows
const int _width = 20;
const int _height = 15;

typedef _Colors = Map<(int, int), ColorReference>;

/// One layer and what surrounds it: the stored pixels, the floating selection
/// on top of them, and what the layers below show.
class _Scene
{
  final String name;
  final CoordinateColorMap layerData;
  final Map<CoordinateSetI, ColorReference?> selection;
  final CoordinateColorMap below;
  final CoordinateColorMap belowWithEffects;
  _Scene({required this.name, required this.layerData, required this.selection, required this.below, required this.belowWithEffects});

  /// The layer's pixels with the selection on top, as the effects see them.
  CoordinateColorMap get content
  {
    final CoordinateColorMap content = CoordinateColorMap.from(layerData);
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in selection.entries)
    {
      if (entry.value != null)
      {
        content[entry.key] = entry.value!;
      }
    }
    return content;
  }

  ColorReference? colorBelow({required final int x, required final int y, required final bool withEffects})
  {
    final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
    return (withEffects ? belowWithEffects[coord] : null) ?? below[coord];
  }

  ColorReference? innerColorAt({required final int x, required final int y})
  {
    final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
    return selection.containsKey(coord) ? selection[coord] : layerData[coord];
  }
}

_Colors _asColors({required final Map<CoordinateSetI, ColorReference> map})
{
  return <(int, int), ColorReference>{for (final MapEntry<CoordinateSetI, ColorReference> entry in map.entries) (entry.key.x, entry.key.y): entry.value};
}

List<_Scene> _scenes({required final List<KPalRampData> ramps})
{
  final List<ColorReference> colors = <ColorReference>[for (final KPalRampData ramp in ramps) ...ramp.references];
  CoordinateColorMap shape(final bool Function(int x, int y) inside, {required final int seed})
  {
    final Random random = Random(seed);
    final CoordinateColorMap map = CoordinateColorMap();
    for (int x = 0; x < _width; x++)
    {
      for (int y = 0; y < _height; y++)
      {
        if (inside(x, y))
        {
          map[CoordinateSetI(x: x, y: y)] = colors[random.nextInt(colors.length)];
        }
      }
    }
    return map;
  }
  CoordinateColorMap scattered({required final int seed, required final double density})
  {
    final Random random = Random(seed);
    return shape((final int x, final int y) => random.nextDouble() < density, seed: seed + 1);
  }

  final List<_Scene> scenes = <_Scene>[];
  void add(final String name, final CoordinateColorMap layerData, {final Map<CoordinateSetI, ColorReference?>? selection, required final int seed})
  {
    scenes.add(_Scene(
      name: name,
      layerData: layerData,
      selection: selection ?? <CoordinateSetI, ColorReference?>{},
      below: scattered(seed: seed, density: 0.6),
      belowWithEffects: scattered(seed: seed + 50, density: 0.2),
    ),);
  }

  add("single pixel", shape((final int x, final int y) => x == 9 && y == 7, seed: 1), seed: 100);
  add("line", shape((final int x, final int y) => y == 5 && x > 2 && x < 17, seed: 2), seed: 200);
  add("block with a hole", shape((final int x, final int y) => x > 3 && x < 14 && y > 2 && y < 12 && !(x > 6 && x < 11 && y > 5 && y < 9), seed: 3), seed: 300);
  add("touching every edge", shape((final int x, final int y) => x == 0 || y == 0 || x == _width - 1 || y == _height - 1 || (x == 10 && y == 7), seed: 4), seed: 400);
  add("checkerboard", shape((final int x, final int y) => (x + y).isEven && x > 1 && x < 15 && y > 1 && y < 12, seed: 5), seed: 500);
  add("everything", shape((final int x, final int y) => true, seed: 6), seed: 600);
  for (int seed = 0; seed < 6; seed++)
  {
    add("random $seed", scattered(seed: 1000 + seed, density: 0.15 + seed * 0.12), seed: 700 + seed);
  }
  //a floating selection that covers some pixels and empties others
  final CoordinateColorMap floor = shape((final int x, final int y) => y > 8, seed: 7);
  add("with a selection", floor, seed: 800, selection: <CoordinateSetI, ColorReference?>{
    for (int x = 4; x < 9; x++) CoordinateSetI(x: x, y: 6): colors[x],
    CoordinateSetI(x: 12, y: 10): null,
    CoordinateSetI(x: 13, y: 10): colors[3],
  },);
  return scenes;
}

HashMap<Alignment, bool> _directions({required final Set<Alignment> selected})
{
  return HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: selected.contains(alignment)});
}

final Map<String, Set<Alignment>> _directionSets = <String, Set<Alignment>>{
  "bottom right": <Alignment>{Alignment.bottomRight},
  "right": <Alignment>{Alignment.centerRight},
  "top and bottom": <Alignment>{Alignment.topCenter, Alignment.bottomCenter},
  "edges": <Alignment>{Alignment.topCenter, Alignment.centerRight, Alignment.bottomCenter, Alignment.centerLeft},
  "corners": <Alignment>{Alignment.topLeft, Alignment.topRight, Alignment.bottomRight, Alignment.bottomLeft},
  "all": allAlignments.toSet(),
  "none": <Alignment>{},
};

/// Runs both implementations on every scene and expects the same pixels.
void _compare({
  required final DrawingLayerSettings settings,
  required final List<KPalRampData> ramps,
  required final String setup,
  final bool relativeOuter = false,
})
{
  final PaletteCodec codec = PaletteCodec(ramps: ramps);
  for (final _Scene scene in _scenes(ramps: ramps))
  {
    final CoordinateColorMap content = scene.content;
    final PixelGrid grid = PixelGrid(width: _width, height: _height);
    content.forEach((final CoordinateSetI coord, final ColorReference color) => grid.set(x: coord.x, y: coord.y, value: codec.encode(color: color)));
    final LegacyLayerEffects legacy = LegacyLayerEffects(settings: settings, colorBelow: (final CoordinateSetI coord, final bool withEffects) => scene.colorBelow(x: coord.x, y: coord.y, withEffects: withEffects));
    final LegacyLayer legacyLayer = LegacyLayer(dataAt: (final CoordinateSetI coord) => scene.layerData[coord]);
    final LegacySelection legacySelection = LegacySelection(colors: scene.selection);
    final LayerEffects effects = LayerEffects(settings: settings, content: grid, codec: codec);
    final CoordinateSetI canvasSize = CoordinateSetI(x: _width, y: _height);
    final String where = "$setup, ${scene.name}";

    _Colors collect(final void Function(EffectPixelSink emit) run)
    {
      final _Colors pixels = <(int, int), ColorReference>{};
      run((final int x, final int y, final ColorReference color) => pixels[(x, y)] = color);
      return pixels;
    }

    final _Colors shadow = collect((final EffectPixelSink emit) => effects.dropShadow(colorBelow: (final int x, final int y) => scene.colorBelow(x: x, y: y, withEffects: true), emit: emit));
    expect(shadow, _asColors(map: legacy.getDropShadowPixels(data: content, layerState: legacyLayer, canvasSize: canvasSize, layers: <Object>[])), reason: "drop shadow: $where");

    final _Colors outer = collect((final EffectPixelSink emit) => effects.outerStroke(colorBelow: (final int x, final int y) => scene.colorBelow(x: x, y: y, withEffects: false), emit: emit));
    final _Colors legacyOuter = _asColors(map: legacy.getOuterStrokePixels(data: content, layerState: legacyLayer, canvasSize: canvasSize, layers: <Object>[]));
    if (relativeOuter)
    {
      _expectRelativeStroke(actual: outer, legacy: legacyOuter, content: content, settings: settings, where: where);
    }
    else
    {
      expect(outer, legacyOuter, reason: "outer stroke: $where");
    }

    final _Colors inner = collect((final EffectPixelSink emit) => effects.innerStroke(
      innerColorAt: (final int x, final int y) => scene.innerColorAt(x: x, y: y),
      layerColorAt: (final int x, final int y) => scene.layerData[CoordinateSetI(x: x, y: y)],
      emit: emit,
    ),);
    expect(inner, _asColors(map: legacy.getInnerStrokePixels(data: content, layerState: legacyLayer, canvasSize: canvasSize, layers: <Object>[], selectionList: legacySelection)), reason: "inner stroke: $where");

    final Map<(int, int), int> shading = <(int, int), int>{};
    effects.outerShading(emit: (final int x, final int y, final int amount) => shading[(x, y)] = amount);
    final HashMap<CoordinateSetI, int> legacyShading = legacy.getOuterShadingPixels(data: content, canvasSize: canvasSize);
    expect(shading, <(int, int), int>{for (final MapEntry<CoordinateSetI, int> entry in legacyShading.entries) (entry.key.x, entry.key.y): entry.value}, reason: "outer shading: $where");
  }
}

/// Where a relative stroke pixel has neighbours of different colors, the old
/// code picked one by hash order. Both answers must come from a neighbour of
/// the kind it prefers (by an edge over by a corner); everywhere else they
/// must agree.
void _expectRelativeStroke({
  required final _Colors actual,
  required final _Colors legacy,
  required final CoordinateColorMap content,
  required final DrawingLayerSettings settings,
  required final String where,
})
{
  expect(actual.keys.toSet(), legacy.keys.toSet(), reason: "relative outer stroke positions: $where");
  final List<Alignment> selected = allAlignments.where((final Alignment alignment) => settings.outerSelectionMap.value[alignment] == true).toList();
  for (final (int, int) position in actual.keys)
  {
    Set<ColorReference> candidates({required final bool byEdge}) => <ColorReference>{
      for (final Alignment alignment in selected)
        if ((alignment.x == 0 || alignment.y == 0) == byEdge && content[CoordinateSetI(x: position.$1 - alignment.x.round(), y: position.$2 - alignment.y.round())] != null)
          content[CoordinateSetI(x: position.$1 - alignment.x.round(), y: position.$2 - alignment.y.round())]!,
    };
    final Set<ColorReference> byEdge = candidates(byEdge: true);
    final Set<ColorReference> sources = byEdge.isNotEmpty ? byEdge : candidates(byEdge: false);
    final Set<ColorReference> allowed = <ColorReference>{
      for (final ColorReference color in sources) color.ramp.references[(color.colorIndex + settings.outerDarkenBrighten.value).clamp(0, color.ramp.references.length - 1)],
    };
    expect(allowed, contains(actual[position]), reason: "relative outer stroke at $position: $where");
    expect(allowed, contains(legacy[position]), reason: "setup: the reference agrees with the rule at $position: $where");
    if (allowed.length == 1)
    {
      expect(actual[position], legacy[position], reason: "relative outer stroke at $position: $where");
    }
  }
}

void main()
{
  final List<KPalRampData> ramps = <KPalRampData>[
    for (int i = 0; i < 3; i++) KPalRampData(uuid: "ramp-$i", settings: KPalRampSettings()),
  ];

  DrawingLayerSettings freshSettings()
  {
    return DrawingLayerSettings.defaultValues(startingColor: ramps[1].references[2], constraints: _constraints);
  }

  group("the grid effects give the same pixels as the map-based ones", ()
  {
    test("outer strokes: solid, shade and relative", ()
    {
      for (final OuterStrokeStyle style in <OuterStrokeStyle>[OuterStrokeStyle.solid, OuterStrokeStyle.shade, OuterStrokeStyle.relative])
      {
        for (final MapEntry<String, Set<Alignment>> directions in _directionSets.entries)
        {
          final DrawingLayerSettings settings = freshSettings();
          settings.outerStrokeStyle.value = style;
          settings.outerSelectionMap.value = _directions(selected: directions.value);
          settings.outerDarkenBrighten.value = 2;
          _compare(settings: settings, ramps: ramps, setup: "$style ${directions.key}", relativeOuter: style == OuterStrokeStyle.relative);
        }
      }
    });

    test("outer glow, recursive or not, both ways", ()
    {
      for (final int depth in <int>[1, 3, -2, 5])
      {
        for (final bool recursive in <bool>[false, true])
        {
          for (final String directions in <String>["bottom right", "edges", "all", "top and bottom"])
          {
            final DrawingLayerSettings settings = freshSettings();
            settings.outerStrokeStyle.value = OuterStrokeStyle.glow;
            settings.outerSelectionMap.value = _directions(selected: _directionSets[directions]!);
            settings.outerGlowDepth.value = depth;
            settings.outerGlowRecursive.value = recursive;
            _compare(settings: settings, ramps: ramps, setup: "glow $depth recursive $recursive $directions");
          }
        }
      }
    });

    test("inner strokes: solid and shade", ()
    {
      for (final InnerStrokeStyle style in <InnerStrokeStyle>[InnerStrokeStyle.solid, InnerStrokeStyle.shade])
      {
        for (final MapEntry<String, Set<Alignment>> directions in _directionSets.entries)
        {
          final DrawingLayerSettings settings = freshSettings();
          settings.innerStrokeStyle.value = style;
          settings.innerSelectionMap.value = _directions(selected: directions.value);
          settings.innerDarkenBrighten.value = -2;
          _compare(settings: settings, ramps: ramps, setup: "$style ${directions.key}");
        }
      }
    });

    test("inner glow, recursive or not, both ways", ()
    {
      for (final int depth in <int>[1, 2, -3])
      {
        for (final bool recursive in <bool>[false, true])
        {
          for (final String directions in <String>["bottom right", "edges", "all", "corners"])
          {
            final DrawingLayerSettings settings = freshSettings();
            settings.innerStrokeStyle.value = InnerStrokeStyle.glow;
            settings.innerSelectionMap.value = _directions(selected: _directionSets[directions]!);
            settings.innerGlowDepth.value = depth;
            settings.innerGlowRecursive.value = recursive;
            _compare(settings: settings, ramps: ramps, setup: "inner glow $depth recursive $recursive $directions");
          }
        }
      }
    });

    test("bevels in every direction", ()
    {
      for (final Alignment direction in allAlignments)
      {
        for (final int distance in <int>[1, 2, 3])
        {
          final DrawingLayerSettings settings = freshSettings();
          settings.innerStrokeStyle.value = InnerStrokeStyle.bevel;
          settings.innerSelectionMap.value = _directions(selected: <Alignment>{direction});
          settings.bevelDistance.value = distance;
          settings.bevelStrength.value = 2;
          _compare(settings: settings, ramps: ramps, setup: "bevel $direction distance $distance");
        }
      }
      //several directions: both take the first one of the same map
      final DrawingLayerSettings several = freshSettings();
      several.innerStrokeStyle.value = InnerStrokeStyle.bevel;
      several.innerSelectionMap.value = _directions(selected: _directionSets["corners"]!);
      _compare(settings: several, ramps: ramps, setup: "bevel corners");
    });

    test("drop shadows with every kind of outer stroke", ()
    {
      for (final DropShadowStyle style in <DropShadowStyle>[DropShadowStyle.solid, DropShadowStyle.shade])
      {
        for (final CoordinateSetI offset in <CoordinateSetI>[CoordinateSetI(x: 1, y: 1), CoordinateSetI(x: -2, y: 1), CoordinateSetI(x: 0, y: 3), CoordinateSetI(x: 3, y: -3)])
        {
          for (final OuterStrokeStyle outer in <OuterStrokeStyle>[OuterStrokeStyle.off, OuterStrokeStyle.solid, OuterStrokeStyle.shade, OuterStrokeStyle.glow])
          {
            final DrawingLayerSettings settings = freshSettings();
            settings.dropShadowStyle.value = style;
            settings.dropShadowOffset.value = offset;
            settings.dropShadowDarkenBrighten.value = -1;
            settings.outerStrokeStyle.value = outer;
            settings.outerSelectionMap.value = _directions(selected: _directionSets["edges"]!);
            _compare(settings: settings, ramps: ramps, setup: "$style shadow ${offset.x}|${offset.y} with $outer");
          }
        }
      }
    });
  });

  test("a relative stroke between differently colored neighbours takes the first direction in order", ()
  {
    final PaletteCodec codec = PaletteCodec(ramps: ramps);
    final PixelGrid content = PixelGrid(width: 5, height: 5);
    //the stroke pixel at 2|2 has the left pixel and the upper pixel as neighbours
    content.set(x: 1, y: 2, value: codec.encode(color: ramps[0].references[1]));
    content.set(x: 2, y: 1, value: codec.encode(color: ramps[2].references[1]));
    final DrawingLayerSettings settings = freshSettings();
    settings.outerStrokeStyle.value = OuterStrokeStyle.relative;
    settings.outerSelectionMap.value = _directions(selected: <Alignment>{Alignment.centerRight, Alignment.bottomCenter});
    settings.outerDarkenBrighten.value = 1;

    final _Colors pixels = <(int, int), ColorReference>{};
    LayerEffects(settings: settings, content: content, codec: codec).outerStroke(
      colorBelow: (final int x, final int y) => null,
      emit: (final int x, final int y, final ColorReference color) => pixels[(x, y)] = color,
    );
    //of the two, centerRight comes before bottomCenter in allAlignments
    expect(pixels[(2, 2)], same(ramps[0].references[2]));
  });
}
