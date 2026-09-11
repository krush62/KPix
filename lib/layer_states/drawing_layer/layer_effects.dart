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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

/// Receives one effect pixel. A pixel handed over twice keeps the later color.
typedef EffectPixelSink = void Function(int x, int y, ColorReference color);

/// A color at a position of the canvas, or null where there is none.
typedef EffectColorLookup = ColorReference? Function(int x, int y);

/// One of the eight neighbour directions.
class _Direction
{
  final int dx;
  final int dy;
  const _Direction({required this.dx, required this.dy});

  bool get isOrthogonal => dx == 0 || dy == 0;
}

/// The effects of a drawing layer (drop shadow, outer and inner stroke) worked
/// out on the grid of its pixels.
///
/// Membership tests go through a mask with one byte per pixel and neighbours
/// are index offsets, where the map-based code this replaced built coordinate
/// sets and a small map per pixel. The results are the same, with one
/// exception: which neighbour a relative outer stroke takes its color from, see
/// [outerStroke].
///
/// Anything outside the layer's own pixels comes in through callbacks, so this
/// class does not need to know the layer stack.
class LayerEffects
{
  final DrawingLayerSettings settings;
  final int width;
  final int height;
  final PixelGridView _contentGrid;
  final PaletteCodec _codec;
  //1 where the layer (with its floating selection) has a pixel
  final Uint8List _content;
  //the indices of those pixels
  final Int32List _contentIndices;

  /// Effects around [content], the layer's pixels with its floating selection,
  /// whose codes belong to [codec].
  factory LayerEffects({required final DrawingLayerSettings settings, required final PixelGridView content, required final PaletteCodec codec})
  {
    final int width = content.width;
    final Uint8List mask = Uint8List(width * content.height);
    final Int32List indices = Int32List(content.nonZeroCount);
    int count = 0;
    content.forEachNonZero(action: (final int x, final int y, final int value)
    {
      final int index = y * width + x;
      mask[index] = 1;
      indices[count++] = index;
    },);
    return LayerEffects._(settings: settings, contentGrid: content, codec: codec, content: mask, contentIndices: indices);
  }

  LayerEffects._({required this.settings, required final PixelGridView contentGrid, required final PaletteCodec codec, required final Uint8List content, required final Int32List contentIndices}) :
        width = contentGrid.width,
        height = contentGrid.height,
        _contentGrid = contentGrid,
        _codec = codec,
        _content = content,
        _contentIndices = contentIndices;

  static List<_Direction> _selected({required final HashMap<Alignment, bool> selectionMap})
  {
    return <_Direction>[
      for (final Alignment alignment in allAlignments)
        if (selectionMap[alignment] == true) _directionOf(alignment: alignment),
    ];
  }

  static _Direction _directionOf({required final Alignment alignment})
  {
    return _Direction(dx: alignment.x.round(), dy: alignment.y.round());
  }

  static ColorReference _shifted({required final ColorReference color, required final int steps})
  {
    return color.ramp.references[(color.colorIndex + steps).clamp(0, color.ramp.references.length - 1)];
  }

  bool _isInside({required final int x, required final int y})
  {
    return x >= 0 && y >= 0 && x < width && y < height;
  }

  /// Every pixel next to the layer's pixels in one of [directions] that is on
  /// the canvas and not a pixel of the layer itself.
  List<int> _outerPositions({required final List<_Direction> directions})
  {
    final Uint8List marked = Uint8List(width * height);
    final List<int> positions = <int>[];
    for (final int index in _contentIndices)
    {
      final int x = index % width;
      final int y = index ~/ width;
      for (final _Direction direction in directions)
      {
        final int nx = x + direction.dx;
        final int ny = y + direction.dy;
        if (_isInside(x: nx, y: ny))
        {
          final int neighbour = ny * width + nx;
          if (_content[neighbour] == 0 && marked[neighbour] == 0)
          {
            marked[neighbour] = 1;
            positions.add(neighbour);
          }
        }
      }
    }
    return positions;
  }

  /// The pixels among [indices] (all set in [mask]) with at least one
  /// neighbour in [directions] that is not set in [mask], and how many such
  /// neighbours each has. A neighbour off the canvas counts as not set.
  Map<int, int> _innerPositions({required final List<_Direction> directions, required final Uint8List mask, required final Iterable<int> indices})
  {
    final Map<int, int> positions = <int, int>{};
    for (final int index in indices)
    {
      final int x = index % width;
      final int y = index ~/ width;
      int open = 0;
      for (final _Direction direction in directions)
      {
        final int nx = x + direction.dx;
        final int ny = y + direction.dy;
        if (!_isInside(x: nx, y: ny) || mask[ny * width + nx] == 0)
        {
          open++;
        }
      }
      if (open > 0)
      {
        positions[index] = open;
      }
    }
    return positions;
  }

  /// The drop shadow: the layer's pixels, and its solid or relative outer
  /// stroke, moved by the shadow offset, where they do not cover themselves.
  /// [colorBelow] is what a shade shadow darkens or brightens.
  void dropShadow({required final EffectColorLookup colorBelow, required final EffectPixelSink emit})
  {
    final DropShadowStyle style = settings.dropShadowStyle.value;
    if (style == DropShadowStyle.off)
    {
      return;
    }
    final Uint8List origin = Uint8List.fromList(_content);
    final List<int> originIndices = List<int>.of(_contentIndices);
    final OuterStrokeStyle outerStyle = settings.outerStrokeStyle.value;
    if (outerStyle == OuterStrokeStyle.relative || outerStyle == OuterStrokeStyle.solid)
    {
      for (final int index in _outerPositions(directions: _selected(selectionMap: settings.outerSelectionMap.value)))
      {
        origin[index] = 1;
        originIndices.add(index);
      }
    }

    for (final int index in _shadowPositions(origin: origin, originIndices: originIndices))
    {
      final int x = index % width;
      final int y = index ~/ width;
      if (style == DropShadowStyle.solid)
      {
        emit(x, y, settings.dropShadowColorReference.value);
      }
      else
      {
        final ColorReference? color = colorBelow(x, y);
        if (color != null)
        {
          emit(x, y, _shifted(color: color, steps: settings.dropShadowDarkenBrighten.value));
        }
      }
    }
  }

  List<int> _shadowPositions({required final Uint8List origin, required final List<int> originIndices})
  {
    final int offsetX = settings.dropShadowOffset.value.x;
    final int offsetY = settings.dropShadowOffset.value.y;
    final Uint8List marked = Uint8List(width * height);
    final List<int> positions = <int>[];
    for (final int index in originIndices)
    {
      final int x = index % width + offsetX;
      final int y = index ~/ width + offsetY;
      if (_isInside(x: x, y: y))
      {
        final int target = y * width + x;
        if (origin[target] == 0 && marked[target] == 0)
        {
          marked[target] = 1;
          positions.add(target);
        }
      }
    }
    return positions;
  }

  /// The outer stroke. [colorBelow] is what a shade stroke and a glow
  /// darken or brighten.
  ///
  /// A relative stroke pixel takes the color of a neighbouring layer pixel,
  /// preferring one it touches by an edge over one it touches by a corner. When
  /// there are several, the map-based implementation took whichever its hash
  /// order visited last (by an edge) or first (by a corner); this one takes the
  /// first in the order of `allAlignments`, so the result no longer depends on
  /// how the pixels happened to be stored.
  void outerStroke({required final EffectColorLookup colorBelow, required final EffectPixelSink emit})
  {
    final OuterStrokeStyle style = settings.outerStrokeStyle.value;
    final List<_Direction> directions = _selected(selectionMap: settings.outerSelectionMap.value);
    if (style == OuterStrokeStyle.solid || style == OuterStrokeStyle.shade || style == OuterStrokeStyle.relative)
    {
      final List<_Direction> byPreference = <_Direction>[
        ...directions.where((final _Direction direction) => direction.isOrthogonal),
        ...directions.where((final _Direction direction) => !direction.isOrthogonal),
      ];
      for (final int index in _outerPositions(directions: directions))
      {
        final int x = index % width;
        final int y = index ~/ width;
        if (style == OuterStrokeStyle.solid)
        {
          emit(x, y, settings.outerColorReference.value);
        }
        else if (style == OuterStrokeStyle.relative)
        {
          emit(x, y, _shifted(color: _neighbourColor(x: x, y: y, byPreference: byPreference), steps: settings.outerDarkenBrighten.value));
        }
        else
        {
          final ColorReference? color = colorBelow(x, y);
          if (color != null)
          {
            emit(x, y, _shifted(color: color, steps: settings.outerDarkenBrighten.value));
          }
        }
      }
    }
    else if (style == OuterStrokeStyle.glow)
    {
      _outerGlow(directions: directions, colorBelow: colorBelow, emit: emit);
    }
  }

  /// The color of the first layer pixel that reaches [x]|[y] in one of
  /// [byPreference]; there is one, since the position is an outer position.
  ColorReference _neighbourColor({required final int x, required final int y, required final List<_Direction> byPreference})
  {
    for (final _Direction direction in byPreference)
    {
      final int sx = x - direction.dx;
      final int sy = y - direction.dy;
      if (_isInside(x: sx, y: sy) && _content[sy * width + sx] != 0)
      {
        return _codec.decode(code: _contentGrid.get(x: sx, y: sy))!;
      }
    }
    throw StateError("$x|$y is not next to the layer's pixels");
  }

  /// Rings around the layer, each one grown from the layer and every ring
  /// before it that found a color below.
  void _outerGlow({required final List<_Direction> directions, required final EffectColorLookup colorBelow, required final EffectPixelSink emit})
  {
    final int depth = settings.outerGlowDepth.value;
    final bool recursive = settings.outerGlowRecursive.value;
    final Uint8List grown = Uint8List.fromList(_content);
    final List<int> grownIndices = List<int>.of(_contentIndices);
    final Uint8List counts = Uint8List(width * height);
    int lastSelfGlow = 100000;
    for (int i = 0; i < depth.abs(); i++)
    {
      final List<int> candidates = _countNeighbours(directions: directions, from: grownIndices, excluded: grown, counts: counts);
      int highestSelfGlow = 0;
      final List<int> ring = <int>[];
      for (final int index in candidates)
      {
        final int amount = counts[index];
        counts[index] = 0;
        final int x = index % width;
        final int y = index ~/ width;
        final ColorReference? color = colorBelow(x, y);
        if (color != null)
        {
          final int selfGlow = recursive ? min(amount - 1, lastSelfGlow) : 0;
          highestSelfGlow = max(highestSelfGlow, selfGlow);
          final int steps = depth > 0 ? depth - i + selfGlow : depth + i - selfGlow;
          emit(x, y, _shifted(color: color, steps: steps));
          ring.add(index);
        }
      }
      lastSelfGlow = highestSelfGlow;
      for (final int index in ring)
      {
        grown[index] = 1;
        grownIndices.add(index);
      }
    }
  }

  /// Counts, for every canvas pixel not set in [excluded], how many pixels of
  /// [from] reach it in one of [directions]; returns the pixels counted.
  List<int> _countNeighbours({required final List<_Direction> directions, required final Iterable<int> from, required final Uint8List excluded, required final Uint8List counts})
  {
    final List<int> counted = <int>[];
    for (final int index in from)
    {
      final int x = index % width;
      final int y = index ~/ width;
      for (final _Direction direction in directions)
      {
        final int nx = x + direction.dx;
        final int ny = y + direction.dy;
        if (_isInside(x: nx, y: ny))
        {
          final int neighbour = ny * width + nx;
          if (excluded[neighbour] == 0)
          {
            if (counts[neighbour] == 0)
            {
              counted.add(neighbour);
            }
            counts[neighbour]++;
          }
        }
      }
    }
    return counted;
  }

  /// The inner stroke. [innerColorAt] is what a shade stroke and a glow
  /// darken or brighten, [layerColorAt] what a bevel does.
  void innerStroke({required final EffectColorLookup innerColorAt, required final EffectColorLookup layerColorAt, required final EffectPixelSink emit})
  {
    final InnerStrokeStyle style = settings.innerStrokeStyle.value;
    if (style == InnerStrokeStyle.solid || style == InnerStrokeStyle.shade)
    {
      final Map<int, int> positions = _innerPositions(directions: _selected(selectionMap: settings.innerSelectionMap.value), mask: _content, indices: _contentIndices);
      for (final int index in positions.keys)
      {
        final int x = index % width;
        final int y = index ~/ width;
        if (style == InnerStrokeStyle.solid)
        {
          emit(x, y, settings.innerColorReference.value);
        }
        else
        {
          final ColorReference? color = innerColorAt(x, y);
          if (color != null)
          {
            emit(x, y, _shifted(color: color, steps: settings.innerDarkenBrighten.value));
          }
        }
      }
    }
    else if (style == InnerStrokeStyle.glow)
    {
      _innerGlow(innerColorAt: innerColorAt, emit: emit);
    }
    else if (style == InnerStrokeStyle.bevel)
    {
      _bevel(layerColorAt: layerColorAt, emit: emit);
    }
  }

  /// Rings peeled off the layer from the outside in.
  void _innerGlow({required final EffectColorLookup innerColorAt, required final EffectPixelSink emit})
  {
    final int depth = settings.innerGlowDepth.value;
    final bool recursive = settings.innerGlowRecursive.value;
    final List<_Direction> directions = _selected(selectionMap: settings.innerSelectionMap.value);
    final Uint8List remaining = Uint8List.fromList(_content);
    List<int> remainingIndices = List<int>.of(_contentIndices);
    int lastSelfGlow = 100000;
    for (int i = 0; i < depth.abs(); i++)
    {
      final Map<int, int> ring = _innerPositions(directions: directions, mask: remaining, indices: remainingIndices);
      int highestSelfGlow = 0;
      for (final MapEntry<int, int> entry in ring.entries)
      {
        final int x = entry.key % width;
        final int y = entry.key ~/ width;
        final ColorReference? color = innerColorAt(x, y);
        if (color != null)
        {
          final int selfGlow = recursive ? min(entry.value - 1, lastSelfGlow) : 0;
          highestSelfGlow = max(highestSelfGlow, selfGlow);
          final int steps = depth > 0 ? depth - i + selfGlow : depth + i - selfGlow;
          emit(x, y, _shifted(color: color, steps: steps));
        }
        remaining[entry.key] = 0;
      }
      remainingIndices = remainingIndices.where((final int index) => remaining[index] != 0).toList();
      lastSelfGlow = highestSelfGlow;
    }
  }

  /// Peels the layer [DrawingLayerSettings.bevelDistance] - 1 times, then
  /// darkens the edge facing away from the chosen direction and brightens the
  /// one facing it.
  void _bevel({required final EffectColorLookup layerColorAt, required final EffectPixelSink emit})
  {
    //the first direction switched on, in the map's own order as before
    Alignment? chosen;
    for (final MapEntry<Alignment, bool> entry in settings.innerSelectionMap.value.entries)
    {
      if (entry.value == true)
      {
        chosen = entry.key;
        break;
      }
    }
    final List<_Direction> towards = chosen == null ? <_Direction>[] :
        (_isDiagonal(alignment: chosen) ? _adjacentDirections(alignment: chosen) : <Alignment>[chosen]).map((final Alignment alignment) => _directionOf(alignment: alignment)).toList();
    final List<_Direction> awayFrom = chosen == null ? <_Direction>[] :
        _oppositeAlignments(alignment: chosen).map((final Alignment alignment) => _directionOf(alignment: alignment)).toList();
    final List<_Direction> everyDirection = allAlignments.map((final Alignment alignment) => _directionOf(alignment: alignment)).toList();

    final Uint8List remaining = Uint8List.fromList(_content);
    List<int> remainingIndices = List<int>.of(_contentIndices);
    final int distance = settings.bevelDistance.value;
    final int strength = settings.bevelStrength.value;
    for (int i = 0; i < distance; i++)
    {
      if (i == distance - 1)
      {
        final Map<int, int> darkened = _innerPositions(directions: awayFrom, mask: remaining, indices: remainingIndices);
        final Map<int, int> brightened = _innerPositions(directions: towards, mask: remaining, indices: remainingIndices);
        for (final int index in darkened.keys)
        {
          final ColorReference? color = layerColorAt(index % width, index ~/ width);
          if (color != null)
          {
            emit(index % width, index ~/ width, _shifted(color: color, steps: -strength));
          }
        }
        for (final int index in brightened.keys)
        {
          final ColorReference? color = layerColorAt(index % width, index ~/ width);
          if (color != null)
          {
            emit(index % width, index ~/ width, _shifted(color: color, steps: strength));
          }
        }
      }
      else
      {
        for (final int index in _innerPositions(directions: everyDirection, mask: remaining, indices: remainingIndices).keys)
        {
          remaining[index] = 0;
        }
        remainingIndices = remainingIndices.where((final int index) => remaining[index] != 0).toList();
      }
    }
  }

  static bool _isDiagonal({required final Alignment alignment})
  {
    return alignment == Alignment.topLeft || alignment == Alignment.topRight || alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft;
  }

  static List<Alignment> _adjacentDirections({required final Alignment alignment})
  {
    if (alignment == Alignment.topLeft) return <Alignment>[Alignment.centerLeft, Alignment.topCenter];
    if (alignment == Alignment.topRight) return <Alignment>[Alignment.topCenter, Alignment.centerRight];
    if (alignment == Alignment.bottomRight) return <Alignment>[Alignment.centerRight, Alignment.bottomCenter];
    if (alignment == Alignment.bottomLeft) return <Alignment>[Alignment.bottomCenter, Alignment.centerLeft];
    return <Alignment>[alignment];
  }

  static List<Alignment> _oppositeAlignments({required final Alignment alignment})
  {
    if (alignment == Alignment.topLeft) return _adjacentDirections(alignment: Alignment.bottomRight);
    if (alignment == Alignment.topRight) return _adjacentDirections(alignment: Alignment.bottomLeft);
    if (alignment == Alignment.bottomRight) return _adjacentDirections(alignment: Alignment.topLeft);
    if (alignment == Alignment.bottomLeft) return _adjacentDirections(alignment: Alignment.topRight);
    if (alignment == Alignment.topCenter) return <Alignment>[Alignment.bottomCenter];
    if (alignment == Alignment.centerRight) return <Alignment>[Alignment.centerLeft];
    if (alignment == Alignment.bottomCenter) return <Alignment>[Alignment.topCenter];
    if (alignment == Alignment.centerLeft) return <Alignment>[Alignment.centerRight];
    return <Alignment>[Alignment.center];
  }

  /// How much the outer effects shade what lies below them: a shade drop
  /// shadow, then a shade stroke or a glow on top of it. This is what the tool
  /// preview needs of a layer.
  void outerShading({required final void Function(int x, int y, int amount) emit})
  {
    if (settings.dropShadowStyle.value == DropShadowStyle.shade)
    {
      //moved from the layer's pixels only, unlike the drop shadow itself
      for (final int index in _shadowPositions(origin: _content, originIndices: _contentIndices))
      {
        emit(index % width, index ~/ width, settings.dropShadowDarkenBrighten.value);
      }
    }

    final OuterStrokeStyle style = settings.outerStrokeStyle.value;
    final List<_Direction> directions = _selected(selectionMap: settings.outerSelectionMap.value);
    if (style == OuterStrokeStyle.shade)
    {
      for (final int index in _outerPositions(directions: directions))
      {
        emit(index % width, index ~/ width, settings.outerDarkenBrighten.value);
      }
    }
    else if (style == OuterStrokeStyle.glow)
    {
      _outerShadingGlow(directions: directions, emit: emit);
    }
  }

  /// Rings grown one from the next, each counted from the ring before only.
  void _outerShadingGlow({required final List<_Direction> directions, required final void Function(int x, int y, int amount) emit})
  {
    final int depth = settings.outerGlowDepth.value;
    final bool recursive = settings.outerGlowRecursive.value;
    //the ring before is part of what is processed, and processed pixels are
    //never counted, so this one mask serves both
    final Uint8List processed = Uint8List.fromList(_content);
    List<int> edge = List<int>.of(_contentIndices);
    final Uint8List counts = Uint8List(width * height);
    int lastHighestSelfGlow = 100000;
    for (int i = 0; i < depth.abs(); i++)
    {
      if (edge.isEmpty)
      {
        break;
      }
      final List<int> candidates = _countNeighbours(directions: directions, from: edge, excluded: processed, counts: counts);
      final List<int> next = <int>[];
      int currentHighestSelfGlow = 0;
      for (final int index in candidates)
      {
        final int baseAmount = counts[index];
        counts[index] = 0;
        int selfGlow = 0;
        if (recursive)
        {
          selfGlow = min(max(baseAmount - 1, 0), lastHighestSelfGlow);
          currentHighestSelfGlow = max(currentHighestSelfGlow, selfGlow);
        }
        final int steps = depth > 0 ? depth - i + selfGlow : depth + i - selfGlow;
        emit(index % width, index ~/ width, steps);
        next.add(index);
      }
      for (final int index in next)
      {
        processed[index] = 1;
      }
      edge = next;
      if (recursive)
      {
        lastHighestSelfGlow = currentHighestSelfGlow;
      }
    }
  }
}
