/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_image.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/export_fixture.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 6, y: 4);

/// The frame rates of the three frames, and how long they show for.
const List<int> _fps = <int>[10, 20, 25];
const List<int> _durationsMs = <int>[100, 50, 40];

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;

CoordinateSetI _dotOf({required final int frame}) => CoordinateSetI(x: frame + 1, y: frame);

ColorReference _colorOf({required final int frame}) => GetIt.I.get<PaletteState>().colorRamps[frame].references[frame + 1];

/// Three frames, each with one pixel of its own in a color of its own.
Future<void> _threeFrames() async
{
  expect(_timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
  expect(_timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
  await settle();
  for (int f = 0; f < 3; f++)
  {
    final Frame frame = _timeline.frames.value[f];
    frame.fps.value = _fps[f];
    (frame.layerList.getLayer(index: 0) as DrawingLayerState).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_dotOf(frame: f): _colorOf(frame: f)}));
  }
  await settle();
}

AnimationExportData _exportData({final int scaling = 1, final bool loopOnly = false})
{
  return AnimationExportData(name: "ANIMATION", extension: "bin", scalable: true, scaling: scaling, loopOnly: loopOnly);
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

/// What frame [frame] has to show.
Map<CoordinateSetI, int> _expectedPixels({required final int frame, final int scaling = 1})
{
  final CoordinateSetI dot = _dotOf(frame: frame);
  return <CoordinateSetI, int>{
    for (int y = 0; y < scaling; y++)
      for (int x = 0; x < scaling; x++) CoordinateSetI(x: dot.x * scaling + x, y: dot.y * scaling + y): rgbOf(reference: _colorOf(frame: frame)),
  };
}

class _AnimatedFormat
{
  final String name;
  final Future<Uint8List?> Function({required AnimationExportData exportData}) export;
  final img.Image? Function(Uint8List bytes) decode;
  const _AnimatedFormat({required this.name, required this.export, required this.decode});
}

final List<_AnimatedFormat> _animatedFormats = <_AnimatedFormat>[
  const _AnimatedFormat(name: "gif", export: exportGIF, decode: img.decodeGif),
  const _AnimatedFormat(name: "apng", export: exportAPNG, decode: img.decodePng),
  const _AnimatedFormat(name: "webp", export: exportWebPAnimation, decode: img.decodeWebP),
];

void _animationTest(final String description, final Future<void> Function() body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await _threeFrames();
      await body();
    },);
  });
}

void main()
{
  for (final _AnimatedFormat format in _animatedFormats)
  {
    group(format.name, ()
    {
      _animationTest("shows every frame with its own pixels and duration", () async
      {
        final img.Image decoded = format.decode((await format.export(exportData: _exportData()))!)!;

        expect(decoded.numFrames, 3);
        expect(decoded.width, _canvasSize.x);
        expect(decoded.height, _canvasSize.y);
        for (int f = 0; f < 3; f++)
        {
          expect(_pixelsOf(image: decoded.frames[f]), _expectedPixels(frame: f), reason: "frame $f");
          expect(decoded.frames[f].frameDuration, _durationsMs[f], reason: "frame $f");
        }
      });

      _animationTest("only exports the loop range when asked to", () async
      {
        _timeline.loopStartIndex.value = 1;
        _timeline.loopEndIndex.value = 2;

        final img.Image decoded = format.decode((await format.export(exportData: _exportData(loopOnly: true)))!)!;

        expect(decoded.numFrames, 2);
        expect(_pixelsOf(image: decoded.frames[0]), _expectedPixels(frame: 1));
        expect(_pixelsOf(image: decoded.frames[1]), _expectedPixels(frame: 2));
      });

      _animationTest("scales every frame to sharp blocks", () async
      {
        const int scaling = 3;

        final img.Image decoded = format.decode((await format.export(exportData: _exportData(scaling: scaling)))!)!;

        expect(decoded.width, _canvasSize.x * scaling);
        expect(decoded.height, _canvasSize.y * scaling);
        expect(_pixelsOf(image: decoded.frames[2]), _expectedPixels(frame: 2, scaling: scaling));
      });
    });
  }

  group("png sequence", ()
  {
    _animationTest("holds one numbered png per frame", () async
    {
      final Archive archive = ZipDecoder().decodeBytes((await exportZippedPng(exportData: _exportData()))!);

      expect(archive.files.map((final ArchiveFile file) => file.name), <String>["frame_001.png", "frame_002.png", "frame_003.png"]);
      for (int f = 0; f < 3; f++)
      {
        expect(_pixelsOf(image: img.decodePng(archive.files[f].content)!), _expectedPixels(frame: f), reason: "frame $f");
      }
    });

    _animationTest("scales its frames", () async
    {
      const int scaling = 2;
      final Archive archive = ZipDecoder().decodeBytes((await exportZippedPng(exportData: _exportData(scaling: scaling)))!);

      expect(_pixelsOf(image: img.decodePng(archive.files[1].content)!), _expectedPixels(frame: 1, scaling: scaling));
    });

    _animationTest("only holds the frames of the loop range when asked to", () async
    {
      _timeline.loopStartIndex.value = 1;
      _timeline.loopEndIndex.value = 2;

      final Archive archive = ZipDecoder().decodeBytes((await exportZippedPng(exportData: _exportData(loopOnly: true)))!);

      expect(archive.files, hasLength(2));
      expect(_pixelsOf(image: img.decodePng(archive.files[0].content)!), _expectedPixels(frame: 1));
      expect(_pixelsOf(image: img.decodePng(archive.files[1].content)!), _expectedPixels(frame: 2));
    });

    _animationTest("numbers the frames of a loop range from one", () async
    {
      _timeline.loopStartIndex.value = 1;
      _timeline.loopEndIndex.value = 2;

      final Archive archive = ZipDecoder().decodeBytes((await exportZippedPng(exportData: _exportData(loopOnly: true)))!);

      expect(archive.files.map((final ArchiveFile file) => file.name), <String>["frame_001.png", "frame_002.png"]);
    });
  });

  group("texture pack animation", ()
  {
    /// The value of the single pixel set in a texture of the pack.
    int valueAt({required final Archive archive, required final String file, required final CoordinateSetI coord})
    {
      return archive.findFile(file)!.content[coord.y * _canvasSize.x + coord.x];
    }

    _animationTest("holds the palette and the textures of every frame", () async
    {
      final Archive archive = ZipDecoder().decodeBytes((await exportTexturePackAnimation(exportData: _exportData()))!);
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;

      expect(archive.files.map((final ArchiveFile file) => file.name).toSet(), <String>{
        "palette.bin",
        for (int f = 0; f < 3; f++) ...<String>["frame_0$f/color.bin", "frame_0$f/distance.bin"],
      });
      for (int f = 0; f < 3; f++)
      {
        expect(valueAt(archive: archive, file: "frame_0$f/color.bin", coord: _dotOf(frame: f)), ramps.indexOf(_colorOf(frame: f).ramp), reason: "frame $f");
        final Uint8List color = archive.findFile("frame_0$f/color.bin")!.content;
        expect(color.where((final int value) => value != 255), hasLength(1), reason: "frame $f holds one pixel");
      }
    });

    _animationTest("counts the frames of a loop range from zero", () async
    {
      _timeline.loopStartIndex.value = 1;
      _timeline.loopEndIndex.value = 2;

      final Archive archive = ZipDecoder().decodeBytes((await exportTexturePackAnimation(exportData: _exportData(loopOnly: true)))!);

      expect(archive.files.map((final ArchiveFile file) => file.name).toSet(), <String>{"palette.bin", "frame_00/color.bin", "frame_00/distance.bin", "frame_01/color.bin", "frame_01/distance.bin"});
      expect(valueAt(archive: archive, file: "frame_00/color.bin", coord: _dotOf(frame: 1)), GetIt.I.get<PaletteState>().colorRamps.indexOf(_colorOf(frame: 1).ramp));
    });
  });

  group("a shading layer linked into two frames", ()
  {
    /// A shaded pixel with a different color below it in each frame, and the color
    /// each frame has to show there.
    Future<List<int>> linkedShading() async
    {
      final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
      final CoordinateSetI dot = CoordinateSetI(x: 2, y: 2);
      expect(_timeline.addNewFrameRight(), LayerActionResult.success, reason: "setup");
      await settle();
      final Frame first = _timeline.frames.value[0];
      final Frame second = _timeline.frames.value[1];
      (first.layerList.getLayer(index: 0) as DrawingLayerState).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: ramps[0].references[1]}));
      (second.layerList.getLayer(index: 0) as DrawingLayerState).setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{dot: ramps[1].references[1]}));
      _timeline.selectFrame(frame: first);
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
      shading.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{dot: 1}));
      await settle();
      expect(GetIt.I.get<LayerManager>().linkLayerToOtherFrame(sourceLayer: shading, targetFrame: second, position: 0), LayerActionResult.success, reason: "setup");
      await settle();
      return <int>[rgbOf(reference: ramps[0].references[2]), rgbOf(reference: ramps[1].references[2])];
    }

    testWidgets("shows each frame's own result in a gif", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final List<int> expected = await linkedShading();

        final img.Image decoded = img.decodeGif((await exportGIF(exportData: _exportData()))!)!;

        expect(_pixelsOf(image: decoded.frames[0])[CoordinateSetI(x: 2, y: 2)], expected[0]);
        expect(_pixelsOf(image: decoded.frames[1])[CoordinateSetI(x: 2, y: 2)], expected[1]);
      },);
    });

    testWidgets("shows each frame's own result in a png sequence", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final List<int> expected = await linkedShading();

        final Archive archive = ZipDecoder().decodeBytes((await exportZippedPng(exportData: _exportData()))!);

        expect(_pixelsOf(image: img.decodePng(archive.files[0].content)!)[CoordinateSetI(x: 2, y: 2)], expected[0]);
        expect(_pixelsOf(image: img.decodePng(archive.files[1].content)!)[CoordinateSetI(x: 2, y: 2)], expected[1]);
      },);
    });

    for (final (String name, Future<Uint8List?> Function({required ImageExportData exportData, required CoordinateSetI canvasSize, required LayerCollection layerList, required SelectionList selection}) export, img.Image? Function(Uint8List) decode) format in <(String, Future<Uint8List?> Function({required ImageExportData exportData, required CoordinateSetI canvasSize, required LayerCollection layerList, required SelectionList selection}), img.Image? Function(Uint8List))>[
      ("png", exportPNG, img.decodePng),
      ("webp", exportWebP, img.decodeWebP),
    ])
    {
      testWidgets("shows the second frame's own result in a still ${format.$1}", (final WidgetTester tester) async
      {
        await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
        {
          final List<int> expected = await linkedShading();

          final Uint8List? bytes = await format.$2(
            exportData: const ImageExportData(name: "IMAGE", extension: "bin", scalable: true),
            canvasSize: _canvasSize,
            layerList: _timeline.frames.value[1].layerList,
            selection: GetIt.I.get<DocumentState>().selectionState.selection,
          );

          expect(_pixelsOf(image: format.$3(bytes!)!)[CoordinateSetI(x: 2, y: 2)], expected[1]);
        },);
      });
    }

    testWidgets("falls back to the layer's last raster for layers outside the document", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState layer = _timeline.selectedFrame!.layerList.getLayer(index: 0) as DrawingLayerState;
        final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[1].references[2];
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 2, y: 2): color}));
        await settle();

        final ui.Image image = await getImageFromLayers(layerCollection: LayerCollection(layers: <LayerState>[layer], selLayerIdx: 0), canvasSize: _canvasSize, selection: GetIt.I.get<DocumentState>().selectionState.selection);
        final ByteData pixels = (await image.toByteData())!;
        image.dispose();

        expect(pixels.getUint8((2 * _canvasSize.x + 2) * 4 + 3), 255);
      },);
    });
  });
}
