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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/canvas_transformation.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/kpal_ramp_data.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// The pixel at [coord] of [image] as RGBA, in the layout RgbaCache uses.
Future<int> _rgbaAt({required final ui.Image image, required final CoordinateSetI coord}) async
{
  final ByteData? bytes = await image.toByteData();
  return bytes!.getUint32((coord.y * image.width + coord.x) * 4);
}

Future<void> _paint({required final DrawingLayerState layer, required final Map<CoordinateSetI, ColorReference?> pixels}) async
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(pixels));
  await settle();
}

ui.Image _rasterOf({required final DrawingLayerState layer})
{
  final Frame frame = GetIt.I.get<DocumentState>().timeline.frames.value.first;
  final ui.Image? image = layer.rasterImageMap.value[frame]?.raster;
  expect(image, isNotNull, reason: "setup: the layer has been rastered");
  return image!;
}

/// Drawing layers keep their pixels as color codes in a PixelGrid. These pin
/// down what the rest of the app sees of that: the colors that come back out,
/// the rendered image, and what the palette operations do to both.
void main()
{
  final CoordinateSetI a = CoordinateSetI(x: 3, y: 2);
  final CoordinateSetI b = CoordinateSetI(x: 10, y: 11);

  testWidgets("the raster shows the painted colors, in a full and in a partial render", (final WidgetTester tester) async
  {
    //large enough that a change of a few pixels is rendered as a region
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 32, y: 32), body: (final ProjectSession projectSession) async
    {
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
      final ColorReference first = ramps[0].references[1];
      final ColorReference second = ramps[1].references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: first, b: second});

      ui.Image image = _rasterOf(layer: layer);
      expect(await _rgbaAt(image: image, coord: a), RgbaCache().rgbaOf(reference: first));
      expect(await _rgbaAt(image: image, coord: b), RgbaCache().rgbaOf(reference: second));
      expect(await _rgbaAt(image: image, coord: CoordinateSetI(x: 0, y: 0)) & 0xFF, 0, reason: "an empty pixel is transparent");

      final CoordinateSetI c = CoordinateSetI(x: 5, y: 2);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{c: second, a: null});
      image = _rasterOf(layer: layer);
      expect(await _rgbaAt(image: image, coord: c), RgbaCache().rgbaOf(reference: second));
      expect(await _rgbaAt(image: image, coord: a) & 0xFF, 0, reason: "the erased pixel is gone from the image");
      expect(await _rgbaAt(image: image, coord: b), RgbaCache().rgbaOf(reference: second), reason: "pixels outside the change stay");
    },);
  });

  testWidgets("reordering the palette changes neither the pixels nor what the layer shows", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 16, y: 16), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference first = palette.colorRamps[0].references[2];
      final ColorReference third = palette.colorRamps[2].references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: first, b: third});

      palette.changeColorOrder(ramp: palette.colorRamps[0], newPosition: 2);
      layer.doManualRaster = true;
      await settle();
      expect(palette.colorRamps.indexOf(first.ramp), 1, reason: "setup: the first ramp moved");

      final Frame frame = GetIt.I.get<DocumentState>().timeline.frames.value.first;
      expect(layer.getDataEntry(coord: a), same(first));
      expect(layer.getDataEntry(coord: b), same(third));
      expect(layer.compositeAt(frame: frame, coord: a), same(first));
      expect(layer.compositeAt(frame: frame, coord: b), same(third));
    },);
  });

  testWidgets("deleting a ramp removes its pixels and keeps the others", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 16, y: 16), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final KPalRampData deleted = palette.colorRamps[0];
      final ColorReference kept = palette.colorRamps[1].references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: deleted.references[0], b: kept});

      palette.deleteRamp(ramp: deleted);
      await settle();

      expect(layer.getDataEntry(coord: a), isNull);
      expect(layer.getDataEntry(coord: b), same(kept));
      expect(layer.getPixelCountForRamp(ramp: deleted), 0);
      expect(layer.getPixelCountForRamp(ramp: kept.ramp), 1);
    },);
  });

  testWidgets("a color count change moves the ramp's pixels like the palette moves its colors", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 16, y: 16), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final KPalRampData ramp = palette.colorRamps.firstWhere((final KPalRampData r) => r.references.length >= 7);
      final int oldCount = ramp.references.length;
      final ColorReference untouched = palette.colorRamps.firstWhere((final KPalRampData r) => r != ramp).references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      //color 1 is moved by the index map to another place than clamping would put it
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: ramp.references[1], b: untouched});

      final KPalRampData original = KPalRampData.from(other: ramp);
      ramp.settings.colorCount = 4;
      ramp.updateColors(colorCountChanged: true);
      palette.updateRamp(ramp: ramp, originalData: original, addToHistoryStack: false);
      await settle();

      final HashMap<int, int> indexMap = remapIndices(oldLength: oldCount, newLength: 4);
      expect(indexMap[1], isNot(1), reason: "setup: the index map moves color 1");
      expect(layer.getDataEntry(coord: a), same(ramp.references[indexMap[1]!]));
      expect(layer.getDataEntry(coord: b), same(untouched));
    },);
  });

  testWidgets("replacing the palette maps the pixels onto the new ramps", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 16, y: 16), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference first = palette.colorRamps[0].references[1];
      final ColorReference second = palette.colorRamps[1].references[2];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: first, b: second});

      final List<KPalRampData> replacement = <KPalRampData>[
        KPalRampData(uuid: "replacement-1", settings: KPalRampSettings()),
        KPalRampData(uuid: "replacement-2", settings: KPalRampSettings()),
      ];
      final HashMap<ColorReference, ColorReference> colorMap = getRampMap(rampList1: palette.colorRamps, rampList2: replacement);
      layer.remapAllColors(rampMap: colorMap);
      await settle();

      expect(layer.getDataEntry(coord: a), same(colorMap[first]));
      expect(layer.getDataEntry(coord: b), same(colorMap[second]));
    },);
  });

  testWidgets("a layer keeps colors of ramps the palette does not have yet", (final WidgetTester tester) async
  {
    //the image importer builds its layer before its new palette is in place
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 16, y: 16), body: (final ProjectSession projectSession) async
    {
      final KPalRampData foreign = KPalRampData(uuid: "not-in-the-palette", settings: KPalRampSettings());
      final DrawingLayerState layer = DrawingLayerState(
        size: CoordinateSetI(x: 16, y: 16),
        content: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{a: foreign.references[2]}),
        ramps: GetIt.I.get<PaletteState>().colorRamps,
      );
      await settle();

      expect(layer.getDataEntry(coord: a), same(foreign.references[2]));
      expect(layer.usedColors(), <ColorReference>{foreign.references[2]});
      layer.dispose();
    },);
  });

  testWidgets("a drop shadow still shows in the composite and in the image", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 16, y: 16), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final ColorReference content = palette.colorRamps[0].references[1];
      final ColorReference shadow = palette.colorRamps[1].references[0];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{a: content});

      layer.settings.dropShadowColorReference.value = shadow;
      layer.settings.dropShadowOffset.value = CoordinateSetI(x: 1, y: 1);
      layer.settings.dropShadowStyle.value = DropShadowStyle.solid;
      await settle();

      final CoordinateSetI shadowed = CoordinateSetI(x: a.x + 1, y: a.y + 1);
      final Frame frame = GetIt.I.get<DocumentState>().timeline.frames.value.first;
      expect(layer.getSettingsPixel(coord: shadowed), same(shadow));
      expect(layer.compositeAt(frame: frame, coord: shadowed), same(shadow));
      expect(layer.compositeAt(frame: frame, coord: a), same(content));
      expect(await _rgbaAt(image: _rasterOf(layer: layer), coord: shadowed), RgbaCache().rgbaOf(reference: shadow));
    },);
  });

  testWidgets("rotating the canvas turns a layer linked into two frames once, pending writes included", (final WidgetTester tester) async
  {
    //not square, so a missing or doubled rotation shows in the size as well
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 6, y: 4), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[1];
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 0): color});
      timeline.linkFrameRight();
      timeline.selectFrameByIndex(index: 0);
      await settle();
      expect(timeline.frames.value[1].layerList.getLayer(index: 0), same(layer), reason: "setup: one layer in two frames");

      //still waiting in the raster queue when the canvas turns
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 5, y: 3): color}));
      GetIt.I.get<CanvasState>().canvasTransform(transformation: CanvasTransformation.rotate);
      await settle();

      expect(GetIt.I.get<CanvasState>().canvasSize.x, 4);
      expect(GetIt.I.get<CanvasState>().canvasSize.y, 6);
      //a quarter clockwise: x|y becomes (height - 1 - y)|x
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 3, y: 1)), same(color));
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 0, y: 5)), same(color));
      expect(layer.usedColors().length, 1);
      int painted = 0;
      for (int x = 0; x < 4; x++)
      {
        for (int y = 0; y < 6; y++)
        {
          if (layer.getDataEntry(coord: CoordinateSetI(x: x, y: y)) != null)
          {
            painted++;
          }
        }
      }
      expect(painted, 2, reason: "nothing else may have appeared");
    },);
  });

  testWidgets("resizing the canvas moves and crops the pixels, pending writes included", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 6, y: 4), body: (final ProjectSession projectSession) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[1];
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      await _paint(layer: layer, pixels: <CoordinateSetI, ColorReference?>{CoordinateSetI(x: 1, y: 0): color, CoordinateSetI(x: 0, y: 3): color});
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 5, y: 3): color}));

      GetIt.I.get<CanvasState>().changeCanvasSize(newSize: CoordinateSetI(x: 8, y: 5), offset: CoordinateSetI(x: 2, y: -1));
      await settle();

      expect(layer.getDataEntry(coord: CoordinateSetI(x: 2, y: 2)), same(color));
      expect(layer.getDataEntry(coord: CoordinateSetI(x: 7, y: 2)), same(color));
      expect(layer.usedColors().length, 1);
      expect(layer.getPixelCountForRamp(ramp: color.ramp), 2, reason: "the pixel moved above the top edge is cut off");
    },);
  });
}
