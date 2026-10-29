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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/layer_effects.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/drawing_layer_settings_constraints.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';

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

void main()
{
  final List<KPalRampData> ramps = <KPalRampData>[
    for (int i = 0; i < 3; i++) KPalRampData(uuid: "ramp-$i", settings: KPalRampSettings()),
  ];

  test("a relative stroke between differently colored neighbours takes the first direction in order", ()
  {
    final PaletteCodec codec = PaletteCodec(ramps: ramps);
    final PixelGrid content = PixelGrid(width: 5, height: 5);
    //the stroke pixel at 2|2 has the left pixel and the upper pixel as neighbours
    content.set(x: 1, y: 2, value: codec.encode(color: ramps[0].references[1]));
    content.set(x: 2, y: 1, value: codec.encode(color: ramps[2].references[1]));
    final DrawingLayerSettings settings = DrawingLayerSettings.defaultValues(startingColor: ramps[1].references[2], constraints: _constraints);
    settings.outerStrokeStyle.value = OuterStrokeStyle.relative;
    settings.outerSelectionMap.value = HashMap<Alignment, bool>.of(<Alignment, bool>{
      for (final Alignment alignment in allAlignments) alignment: alignment == Alignment.centerRight || alignment == Alignment.bottomCenter,
    });
    settings.outerDarkenBrighten.value = 1;

    final Map<(int, int), ColorReference> pixels = <(int, int), ColorReference>{};
    LayerEffects(settings: settings, content: content, codec: codec).outerStroke(
      colorBelow: (final int x, final int y) => null,
      emit: (final int x, final int y, final ColorReference color) => pixels[(x, y)] = color,
    );
    //of the two, centerRight comes before bottomCenter in allAlignments
    expect(pixels[(2, 2)], same(ramps[0].references[2]));
  });
}
