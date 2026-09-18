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
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// A canvas whose byte count is not a power of two, so the thumbnail's base fill
/// has to cope with a last block that does not divide evenly.
final CoordinateSetI _canvasSize = CoordinateSetI(x: 5, y: 3);

Future<void> _settleShading({required final ShadingLayerState layer}) async
{
  for (int i = 0; i < 80 && (layer.doManualRaster || layer.isRasterizing); i++)
  {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Future<Map<String, int>> _pixels({required final ui.Image image}) async
{
  final ByteData bytes = (await image.toByteData())!;
  final Map<String, int> pixels = <String, int>{};
  for (int y = 0; y < image.height; y++)
  {
    for (int x = 0; x < image.width; x++)
    {
      pixels["$x|$y"] = bytes.getUint32((y * image.width + x) * 4);
    }
  }
  return pixels;
}

/// The grey a pixel carrying [value] shows in the thumbnail, as the layer works
/// it out from its step counts.
int _greyFor({required final ShadingLayerState layer, required final int value})
{
  final int minus = layer.settings.shadingStepsMinus.value;
  final int plus = layer.settings.shadingStepsPlus.value;
  final int step = 255 ~/ (minus + plus + 1);
  final int brightness = step * (value + minus);
  return (brightness << 24) | (brightness << 16) | (brightness << 8) | 0xFF;
}

void main()
{
  testWidgets("a shading layer shades what is below it and greys its thumbnail", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final KPalRampData ramp = GetIt.I.get<PaletteState>().colorRamps.first;
      final ColorReference base = ramp.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      //a column of content, so there are shaded pixels with and without a color
      //below them
      final CoordinateColorMapNullable content = CoordinateColorMapNullable();
      for (int y = 0; y < _canvasSize.y; y++)
      {
        content[CoordinateSetI(x: 1, y: y)] = base;
      }
      layer.setDataAll(list: content);
      await settle();

      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, addToHistoryStack: false).$2! as ShadingLayerState;
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.from(<CoordinateSetI, int>{
        //over the content
        CoordinateSetI(x: 1, y: 0): 1,
        CoordinateSetI(x: 1, y: 1): -1,
        //over nothing
        CoordinateSetI(x: 3, y: 2): 1,
      },),);
      await settle();
      await _settleShading(layer: shading);

      final Map<String, int> raster = await _pixels(image: shading.rasterImage.value!);
      final Map<String, int> thumbnail = await _pixels(image: shading.thumbnail.value!);

      int rgbaOf({required final int colorIndex})
      {
        return argbToRgba(argb: ramp.references[colorIndex.clamp(0, ramp.references.length - 1)].getIdColor().color.toARGB32());
      }

      expect(raster["1|0"], rgbaOf(colorIndex: base.colorIndex + 1), reason: "a shaded pixel shows the color below shifted by its step");
      expect(raster["1|1"], rgbaOf(colorIndex: base.colorIndex - 1));
      expect(raster["1|2"], 0, reason: "content below with no shading over it is not the shading layer's to show");
      expect(raster["3|2"], 0, reason: "a shading step with nothing below it shows nothing");
      expect(raster["0|0"], 0);
      expect(raster["4|2"], 0);

      expect(thumbnail["1|0"], _greyFor(layer: shading, value: 1));
      expect(thumbnail["1|1"], _greyFor(layer: shading, value: -1));
      expect(thumbnail["3|2"], _greyFor(layer: shading, value: 1), reason: "the thumbnail shows the step, whatever is below");
      //every pixel the layer does not shade, including the last one, carries the
      //grey of no shading at full alpha
      for (int y = 0; y < _canvasSize.y; y++)
      {
        for (int x = 0; x < _canvasSize.x; x++)
        {
          if (shading.hasCoord(coord: CoordinateSetI(x: x, y: y)))
          {
            continue;
          }
          expect(thumbnail["$x|$y"], _greyFor(layer: shading, value: 0), reason: "$x|$y carries no step");
        }
      }
    },);
  });

  testWidgets("a dither layer greys its thumbnail the same way", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference base = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final CoordinateColorMapNullable content = CoordinateColorMapNullable();
      for (int y = 0; y < _canvasSize.y; y++)
      {
        content[CoordinateSetI(x: 1, y: y)] = base;
      }
      layer.setDataAll(list: content);
      await settle();

      final DitherLayerState dither = GetIt.I.get<LayerManager>().addNewLayer(layerType: DitherLayerState, addToHistoryStack: false).$2! as DitherLayerState;
      dither.addCoords(coords: HashMap<CoordinateSetI, int>.from(<CoordinateSetI, int>{
        CoordinateSetI(x: 1, y: 0): 1,
        CoordinateSetI(x: 3, y: 2): -1,
      },),);
      await settle();
      await _settleShading(layer: dither);

      final Map<String, int> raster = await _pixels(image: dither.rasterImage.value!);
      final Map<String, int> thumbnail = await _pixels(image: dither.thumbnail.value!);

      expect(thumbnail["1|0"], _greyFor(layer: dither, value: 1));
      expect(thumbnail["3|2"], _greyFor(layer: dither, value: -1));
      expect(thumbnail["0|0"], _greyFor(layer: dither, value: 0));
      expect(thumbnail["4|2"], _greyFor(layer: dither, value: 0), reason: "the last pixel of the base fill is covered too");
      expect(raster["0|0"], 0, reason: "a pixel with no step shows nothing");
      expect(raster["3|2"], 0, reason: "a step with nothing below it shows nothing");
    },);
  });

  testWidgets("a change below keeps the shading thumbnail, a change of the steps makes a new one", (final WidgetTester tester) async {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async {
      final ColorReference base = GetIt.I.get<PaletteState>().colorRamps.first.references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 0): base}));
      await settle();
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: ShadingLayerState, addToHistoryStack: false).$2! as ShadingLayerState;
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.from(<CoordinateSetI, int>{CoordinateSetI(x: 1, y: 0): 1}));
      await settle();
      await _settleShading(layer: shading);
      final ui.Image before = shading.thumbnail.value!.clone();

      //erasing below changes what the layer shows, not its steps
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 0): null}));
      await settle();
      await _settleShading(layer: shading);
      expect((await _pixels(image: shading.rasterImage.value!))["1|0"], 0, reason: "setup: the shading followed the erasure");
      expect(shading.thumbnail.value!.isCloneOf(before), isTrue, reason: "the thumbnail shows only the steps, so it is kept");

      shading.addCoords(coords: HashMap<CoordinateSetI, int>.from(<CoordinateSetI, int>{CoordinateSetI(x: 3, y: 2): -1}));
      await settle();
      await _settleShading(layer: shading);
      expect(shading.thumbnail.value!.isCloneOf(before), isFalse, reason: "new steps make a new thumbnail");
      final Map<String, int> thumbnail = await _pixels(image: shading.thumbnail.value!);
      expect(thumbnail["3|2"], _greyFor(layer: shading, value: -1));
      expect(thumbnail["1|0"], _greyFor(layer: shading, value: 1));
      before.dispose();
    },);
  });
}
