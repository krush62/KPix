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

import 'package:archive/archive.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/export_fixture.dart';
import 'support/format_readers.dart';
import 'support/selection_harness.dart';

class _LayeredFormat
{
  final String name;
  final Future<Uint8List?> Function({required List<KPalRampData> colorRamps, required LayerCollection layerCollection, required CoordinateSetI canvasSize, required SelectionList selection}) export;
  final ExportedProject Function(Uint8List bytes) read;
  final bool keepsLock;

  const _LayeredFormat({required this.name, required this.export, required this.read, required this.keepsLock});
}

final List<_LayeredFormat> _layeredFormats = <_LayeredFormat>[
  _LayeredFormat(name: "aseprite", export: getAsepriteData, read: (final Uint8List bytes) => readAseprite(bytes: bytes), keepsLock: true),
  _LayeredFormat(name: "gimp", export: getGimpData, read: (final Uint8List bytes) => readXcf(bytes: bytes), keepsLock: true),
  _LayeredFormat(name: "photoshop", export: getPsdDataRGB, read: (final Uint8List bytes) => readPsd(bytes: bytes), keepsLock: false),
  _LayeredFormat(name: "pixelorama", export: getPixeloramaData, read: (final Uint8List bytes) => readPixelorama(bytes: bytes), keepsLock: true),
];

void _fixtureTest(final String description, final Future<void> Function(ExportFixture fixture) body, {final bool skip = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: exportCanvasSize, body: (final ProjectSession projectSession) async
    {
      await body(await buildExportFixture(projectSession: projectSession));
    },);
  }, skip: skip,);
}

Future<Uint8List> _exported({required final _LayeredFormat format}) async
{
  final Uint8List? bytes = await format.export(
    colorRamps: GetIt.I.get<PaletteState>().colorRamps,
    layerCollection: GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList,
    canvasSize: GetIt.I.get<CanvasState>().canvasSize,
    selection: GetIt.I.get<DocumentState>().selectionState.selection,
  );
  expect(bytes, isNotNull);
  return bytes!;
}

/// The opaque pixels of [image] as 0xRRGGBB.
Map<CoordinateSetI, int> _pixelsOf({required final img.Image image})
{
  final Map<CoordinateSetI, int> pixels = <CoordinateSetI, int>{};
  for (final img.Pixel p in image)
  {
    if (p.a != 0)
    {
      pixels[CoordinateSetI(x: p.x, y: p.y)] = (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
    }
  }
  return pixels;
}

void main()
{
  for (final _LayeredFormat format in _layeredFormats)
  {
    group(format.name, ()
    {
      _fixtureTest("keeps the canvas size", (final ExportFixture fixture) async
      {
        final ExportedProject file = format.read(await _exported(format: format));

        expect(file.width, exportCanvasSize.x);
        expect(file.height, exportCanvasSize.y);
      });

      _fixtureTest("holds the drawing layers top to bottom with shading, selection and exact colors", (final ExportFixture fixture) async
      {
        final ExportedProject file = format.read(await _exported(format: format));

        expect(file.layers.map((final ExportedLayer layer) => layer.pixels).toList(), fixture.expectedLayers);
      });

      //BUG: skipped until fixed for pixelorama, the layer list is written top to bottom
      //while the image files are numbered from the bottom, so the flags land on the wrong layers
      _fixtureTest("marks the hidden layer", (final ExportFixture fixture) async
      {
        final ExportedProject file = format.read(await _exported(format: format));

        expect(file.layers.map((final ExportedLayer layer) => layer.visible), <bool>[true, false, true, true]);
      }, skip: format.name == "pixelorama",);

      if (format.keepsLock)
      {
        //BUG: skipped until fixed for pixelorama, same as the hidden layer
        _fixtureTest("marks the locked layer", (final ExportFixture fixture) async
        {
          final ExportedProject file = format.read(await _exported(format: format));

          expect(file.layers.map((final ExportedLayer layer) => layer.locked), <bool>[false, false, true, false]);
        }, skip: format.name == "pixelorama",);
      }

      testWidgets("includes the pixels of a layer effect", (final WidgetTester tester) async
      {
        await withProject(tester: tester, canvasSize: exportCanvasSize, body: (final ProjectSession projectSession) async
        {
          final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
          final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
          final CoordinateSetI dot = CoordinateSetI(x: 3, y: 2);
          layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: ramps[0].references[1]}));
          layer.settings.outerColorReference.value = ramps[1].references[2];
          layer.settings.outerSelectionMap.value = HashMap<Alignment, bool>.of(<Alignment, bool>{for (final Alignment alignment in allAlignments) alignment: alignment == Alignment.centerRight});
          layer.settings.outerStrokeStyle.value = OuterStrokeStyle.solid;
          await settle();

          final Map<CoordinateSetI, int> pixels = format.read(await _exported(format: format)).layers.single.pixels;

          expect(pixels[dot], rgbOf(reference: ramps[0].references[1]));
          expect(pixels[CoordinateSetI(x: 4, y: 2)], rgbOf(reference: ramps[1].references[2]), reason: "the stroke next to the pixel");
        },);
      });

      testWidgets("reaches pixels on the far side of the canvas", (final WidgetTester tester) async
      {
        final CoordinateSetI size = CoordinateSetI(x: 70, y: 66);
        await withProject(tester: tester, canvasSize: size, body: (final ProjectSession projectSession) async
        {
          final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[1].references[2];
          final Map<CoordinateSetI, int> corners = <CoordinateSetI, int>{
            for (final CoordinateSetI coord in <CoordinateSetI>[CoordinateSetI(x: 0, y: 0), CoordinateSetI(x: 63, y: 63), CoordinateSetI(x: 64, y: 0), CoordinateSetI(x: 0, y: 64), CoordinateSetI(x: 69, y: 65)]) coord: rgbOf(reference: color),
          };
          layerAt(projectSession: projectSession, index: 0).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{for (final CoordinateSetI coord in corners.keys) coord: color}));
          await settle();

          final ExportedProject file = format.read(await _exported(format: format));

          expect(file.layers.single.pixels, corners);
        },);
      }, timeout: const Timeout(Duration(minutes: 2)),);
    });
  }

  group("aseprite", ()
  {
    _fixtureTest("starts the palette with the transparent color, in both palette chunks", (final ExportFixture fixture) async
    {
      final AsepriteFile file = readAseprite(bytes: (await getAsepriteData(colorRamps: fixture.ramps, layerCollection: fixture.layers, canvasSize: exportCanvasSize, selection: fixture.selection))!);

      expect(file.transparentIndex, 0);
      expect(file.palette.first, 0x000000);
      expect(file.palette.skip(1), <int>[
        for (final KPalRampData ramp in fixture.ramps)
          for (final ColorReference reference in ramp.references) rgbOf(reference: reference),
      ]);
      expect(file.oldPalette, file.palette);
    });
  });

  group("gimp", ()
  {
    _fixtureTest("holds the whole palette as its color map", (final ExportFixture fixture) async
    {
      final XcfFile file = readXcf(bytes: (await getGimpData(colorRamps: fixture.ramps, layerCollection: fixture.layers, canvasSize: exportCanvasSize, selection: fixture.selection))!);

      expect(file.colorMap, <int>[
        for (final KPalRampData ramp in fixture.ramps)
          for (final ColorReference reference in ramp.references) rgbOf(reference: reference),
      ]);
    });
  });

  group("photoshop", ()
  {
    _fixtureTest("holds what is visible as its composite", (final ExportFixture fixture) async
    {
      final PsdFile file = readPsd(bytes: (await getPsdDataRGB(colorRamps: fixture.ramps, layerCollection: fixture.layers, canvasSize: exportCanvasSize, selection: fixture.selection))!);

      expect(file.merged, fixture.expectedMerged);
    });

    testWidgets("protects the transparency of a transparency locked layer", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: exportCanvasSize, body: (final ProjectSession projectSession) async
      {
        final LayerState upper = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.drawing, select: true).$2!;
        (upper as DrawingLayerState).lockState.value = LayerLockState.transparency;
        final LayerCollection layers = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList;
        final SelectionList selection = GetIt.I.get<DocumentState>().selectionState.selection;

        final PsdFile file = readPsd(bytes: (await getPsdDataRGB(colorRamps: GetIt.I.get<PaletteState>().colorRamps, layerCollection: layers, canvasSize: exportCanvasSize, selection: selection))!);

        expect(file.transparencyLocked, <bool>[true, false]);
      },);
    });
  });

  group("pixelorama", ()
  {
    testWidgets("has nothing to export without a drawing layer", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: exportCanvasSize, body: (final ProjectSession projectSession) async
      {
        final bool empty = await getPixeloramaData(
          colorRamps: GetIt.I.get<PaletteState>().colorRamps,
          layerCollection: LayerCollection.empty(),
          canvasSize: exportCanvasSize,
          selection: GetIt.I.get<DocumentState>().selectionState.selection,
        ) == null;

        expect(empty, isTrue);
      },);
    });
  });

  group("more colors than an index holds", ()
  {
    //BUG: skipped until fixed, this is only an assert: in a release build the indices
    //wrap around and the file shows the wrong colors without any warning
    for (final _LayeredFormat format in _layeredFormats.where((final _LayeredFormat f) => f.name == "aseprite" || f.name == "gimp"))
    {
      testWidgets("${format.name} refuses instead of writing wrong colors", (final WidgetTester tester) async
      {
        await withProject(tester: tester, canvasSize: exportCanvasSize, body: (final ProjectSession projectSession) async
        {
          final List<KPalRampData> ramps = <KPalRampData>[for (int i = 0; i < 20; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()..colorCount = 15)];

          final Uint8List? bytes = await format.export(colorRamps: ramps, layerCollection: GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList, canvasSize: exportCanvasSize, selection: GetIt.I.get<DocumentState>().selectionState.selection);

          expect(bytes, isNull);
        },);
      }, skip: true,);
    }
  });

  group("png", ()
  {
    _fixtureTest("shows what is visible", (final ExportFixture fixture) async
    {
      final Uint8List? bytes = await exportPNG(exportData: ImageExportData.exportTypeMap[ImageExportType.png]!, canvasSize: exportCanvasSize, layerList: fixture.layers, selection: fixture.selection);

      final img.Image image = img.decodePng(bytes!)!;

      expect(image.width, exportCanvasSize.x);
      expect(image.height, exportCanvasSize.y);
      expect(_pixelsOf(image: image), fixture.expectedMerged);
    });

    _fixtureTest("scales every pixel to a sharp block", (final ExportFixture fixture) async
    {
      const int scaling = 3;
      final Uint8List? bytes = await exportPNG(exportData: const ImageExportData(name: "PNG", extension: "png", scalable: true, scaling: scaling), canvasSize: exportCanvasSize, layerList: fixture.layers, selection: fixture.selection);

      final img.Image image = img.decodePng(bytes!)!;

      expect(image.width, exportCanvasSize.x * scaling);
      expect(image.height, exportCanvasSize.y * scaling);
      expect(_pixelsOf(image: image), <CoordinateSetI, int>{
        for (final MapEntry<CoordinateSetI, int> pixel in fixture.expectedMerged.entries)
          for (int y = 0; y < scaling; y++)
            for (int x = 0; x < scaling; x++) CoordinateSetI(x: pixel.key.x * scaling + x, y: pixel.key.y * scaling + y): pixel.value,
      });
    });
  });

  group("texture pack", ()
  {
    /// A file of the pack as a map from pixel to value, leaving out the empty ones.
    Map<CoordinateSetI, int> texture({required final Uint8List bytes})
    {
      expect(bytes, hasLength(exportCanvasSize.x * exportCanvasSize.y));
      final Map<CoordinateSetI, int> values = <CoordinateSetI, int>{};
      for (int i = 0; i < bytes.length; i++)
      {
        if (bytes[i] != 255)
        {
          values[CoordinateSetI(x: i % exportCanvasSize.x, y: i ~/ exportCanvasSize.x)] = bytes[i];
        }
      }
      return values;
    }

    _fixtureTest("holds the ramp and distance of what is visible, and the palette", (final ExportFixture fixture) async
    {
      final Archive archive = ZipDecoder().decodeBytes((await exportTexturePack())!);

      expect(archive.files.map((final ArchiveFile file) => file.name).toSet(), <String>{"color.bin", "distance.bin", "palette.bin"});
      expect(texture(bytes: archive.findFile("color.bin")!.content), fixture.expectedMergedColors.map((final CoordinateSetI coord, final ColorReference reference) => MapEntry<CoordinateSetI, int>(coord, fixture.ramps.indexOf(reference.ramp))));
      expect(texture(bytes: archive.findFile("distance.bin")!.content), fixture.expectedMergedColors.map((final CoordinateSetI coord, final ColorReference reference) => MapEntry<CoordinateSetI, int>(coord, 255 - (reference.colorIndex * (255.0 / reference.ramp.references.length)).round())));

      final Uint8List palette = archive.findFile("palette.bin")!.content;
      int offset = 0;
      expect(palette[offset++], fixture.ramps.length);
      for (final KPalRampData ramp in fixture.ramps)
      {
        expect(palette[offset++], ramp.references.length);
        for (final ColorReference reference in ramp.references)
        {
          final Color color = reference.getIdColor().color;
          expect(palette.sublist(offset, offset + 3), <int>[(color.r * 255.0).round(), (color.g * 255.0).round(), (color.b * 255.0).round()]);
          offset += 3;
        }
      }
    });
  });
}
