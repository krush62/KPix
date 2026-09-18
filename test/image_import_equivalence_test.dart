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

import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/image_importer.dart';

import 'support/legacy_image_import.dart';
import 'support/selection_harness.dart';

const int _width = 23;
const int _height = 17;
/// Every 37th pixel of a transparent test image is empty, which is often enough
/// to land in several rows and never on a row boundary.
const int _transparentEvery = 37;

bool _isTransparent({required final int index})
{
  return index % _transparentEvery == 0;
}

/// An image with colors spread over the whole range, either fully opaque or
/// with [_isTransparent] pixels left empty.
Future<ui.Image> _testImage({required final bool withTransparency}) async
{
  final Uint8List pixels = Uint8List(_width * _height * 4);
  final Random rng = Random(4711);
  for (int i = 0; i < _width * _height; i++)
  {
    final int base = i * 4;
    final bool transparent = withTransparency && _isTransparent(index: i);
    pixels[base + 0] = transparent ? 0 : rng.nextInt(256);
    pixels[base + 1] = transparent ? 0 : rng.nextInt(256);
    pixels[base + 2] = transparent ? 0 : rng.nextInt(256);
    pixels[base + 3] = transparent ? 0 : 255;
  }
  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(pixels, _width, _height, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

ImportData _importData({required final ui.Image image, required final bool createNewPalette})
{
  return ImportData(
    filePath: "equivalence.png",
    maxRamps: KPalConstraints.rampCountDefault,
    maxColors: KPalConstraints.colorCountDefault,
    image: image,
    includeReference: false,
    maxClusters: KPalConstraints.maxClusters,
    createNewPalette: createNewPalette,
    scaledImage: image,
  );
}

/// The image import used to walk every pixel on the UI isolate, converting the
/// whole palette to Lab again for each comparison, which froze the app for as
/// long as it took. It now runs on a background isolate and looks a color up
/// once, so these pin down that the colors did not move - and that a
/// transparent pixel no longer shifts the ones behind it.
void main()
{
  testWidgets("every pixel of an opaque image ends up on the same palette color as before", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: _width, y: _height), body: (final ProjectSession projectSession) async
    {
      final ui.Image image = await _testImage(withTransparency: false);
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;

      final ImportResult result = await import(importData: _importData(image: image, createNewPalette: false), currentRamps: ramps);
      expect(result.result, ImageImportResult.success);

      final ByteData bytes = (await image.toByteData())!;
      final HashMap<CoordinateSetI, ColorReference?> expected = legacyLayerContent(
        colorList: legacyExtractColorsFromImage(imgBytes: bytes),
        width: _width,
        ramps: ramps,
      );
      //without transparency the old code covered the whole canvas, so this
      //compares every single pixel
      expect(expected.length, _width * _height);

      final DrawingLayerState layer = result.data!.drawingLayer;
      for (int y = 0; y < _height; y++)
      {
        for (int x = 0; x < _width; x++)
        {
          final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
          expect(layer.getDataEntry(coord: coord), expected[coord], reason: "pixel $x|$y");
        }
      }
    },);
  },);

  testWidgets("a transparent pixel stays empty and leaves the ones behind it in place", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: _width, y: _height), body: (final ProjectSession projectSession) async
    {
      final ui.Image image = await _testImage(withTransparency: true);
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;

      final ImportResult result = await import(importData: _importData(image: image, createNewPalette: false), currentRamps: ramps);
      expect(result.result, ImageImportResult.success);

      final Uint8List bytes = (await image.toByteData())!.buffer.asUint8List();
      final DrawingLayerState layer = result.data!.drawingLayer;
      final Set<int> emptyRows = <int>{};
      for (int i = 0; i < _width * _height; i++)
      {
        final CoordinateSetI coord = CoordinateSetI(x: i % _width, y: i ~/ _width);
        final ColorReference? found = layer.getDataEntry(coord: coord);
        if (_isTransparent(index: i))
        {
          emptyRows.add(coord.y);
          expect(found, isNull, reason: "transparent pixel ${coord.x}|${coord.y}");
        }
        else
        {
          //the color of the pixel at this very coordinate, not of whatever the
          //dropped pixels used to shift into its place
          final int base = i * 4;
          final KHSV hsv = KHSV.fromColor(color: ui.Color.fromARGB(255, bytes[base], bytes[base + 1], bytes[base + 2]));
          expect(found, legacyFindClosestColor(color: hsv, ramps: ramps), reason: "pixel ${coord.x}|${coord.y}");
        }
      }
      expect(emptyRows.length, greaterThan(3), reason: "setup: the empty pixels have to span several rows");
    },);
  },);

  testWidgets("a palette built from the image survives the isolate hop", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: _width, y: _height), body: (final ProjectSession projectSession) async
    {
      final ui.Image image = await _testImage(withTransparency: true);

      final ImportResult result = await import(importData: _importData(image: image, createNewPalette: true), currentRamps: GetIt.I.get<PaletteState>().colorRamps);
      expect(result.result, ImageImportResult.success);

      final List<KPalRampData> ramps = result.data!.rampDataList;
      expect(ramps, isNotEmpty);
      expect(ramps.length, lessThanOrEqualTo(KPalConstraints.rampCountDefault));
      //the unused ramps are dropped, so every ramp that is left has to carry
      //at least one pixel
      final Set<ColorReference> used = result.data!.drawingLayer.usedColors();
      for (final KPalRampData ramp in ramps)
      {
        expect(used.any((final ColorReference reference) => reference.ramp == ramp), isTrue, reason: "ramp ${ramp.uuid} is unused");
      }
      //and no pixel may point at a ramp that is no longer part of the palette
      for (final ColorReference reference in used)
      {
        expect(ramps.contains(reference.ramp), isTrue);
      }
    },);
  },);
}
