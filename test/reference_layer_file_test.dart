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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/reference_layer_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_reference_layer.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 8);

ReferenceImageManager get _images => GetIt.I.get<ReferenceImageManager>();

/// A png on disk, loaded the way picking a reference image does.
Future<ReferenceImage> _loadedImage({required final String name}) async
{
  final File file = File(p.join(GetIt.I.get<AppPaths>().exportDir, name))..writeAsBytesSync(pngBytes(width: 6, height: 4));
  return (await _images.loadImageFile(path: file.path))!;
}

ReferenceLayerState _reference({required final ReferenceImage? image})
{
  final ReferenceLayerState reference = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.reference, select: true).$2! as ReferenceLayerState;
  reference.imageNotifier.value = image;
  reference.opacityNotifier.value = 33;
  reference.aspectRatioNotifier.value = 1.5;
  reference.zoomNotifier.value = 700;
  reference.offsetXNotifier.value = 3.5;
  reference.offsetYNotifier.value = -4.25;
  reference.brightnessNotifier.value = 0.25;
  reference.contrastNotifier.value = 1.25;
  reference.saturationNotifier.value = 0.75;
  reference.warmthNotifier.value = -0.5;
  return reference;
}

void _expectSettings({required final ReferenceLayerState reference})
{
  expect(reference.opacity, 33);
  expect(reference.aspectRatioNotifier.value, 1.5);
  expect(reference.zoomNotifier.value, 700);
  expect(reference.offsetX, 3.5);
  expect(reference.offsetY, -4.25);
  expect(reference.brightnessNotifier.value, 0.25);
  expect(reference.contrastNotifier.value, 1.25);
  expect(reference.saturationNotifier.value, 0.75);
  expect(reference.warmthNotifier.value, -0.5);
}

/// Saves the project and puts the loaded file back on top of a fresh one.
Future<ReferenceLayerState> _reloaded({required final ProjectSession projectSession}) async
{
  final LoadFileSet loaded = await loadProjectBytes(bytes: await projectBytes(), path: "saved.kpix");
  expect(loaded.historyState, isNotNull, reason: "setup: ${loaded.status}");
  projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
  await settle();
  final ProjectLoadResult result = await projectSession.restoreFromFile(loadFileSet: loaded);
  await settle();
  expect(result.restore, HistoryRestoreResult.success);
  return GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getAllLayers().whereType<ReferenceLayerState>().single;
}

void _fileTest(final String description, final Future<void> Function(ProjectSession projectSession) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
    {
      await body(projectSession);
    },);
  });
}

/// One value of the reference layer record to break, and how loading has to take it.
class _BadValue
{
  final String name;
  final void Function(ByteData record, int offset) write;
  final String warning;
  final void Function(HistoryReferenceLayer layer) expectFallback;
  const _BadValue({required this.name, required this.write, required this.warning, required this.expectFallback});
}

void main()
{
  _fileTest("a saved reference layer keeps its settings, visibility and image path", (final ProjectSession projectSession) async
  {
    final ReferenceImage image = await _loadedImage(name: "picture.png");
    final ReferenceLayerState reference = _reference(image: image);
    reference.visibilityState.value = LayerVisibilityState.hidden;

    final LoadFileSet loaded = await loadProjectBytes(bytes: await projectBytes(), path: "saved.kpix", strict: true);

    expect(loaded.historyState, isNotNull, reason: loaded.status);
    final HistoryReferenceLayer layer = loaded.historyState!.timeline.allLayers.whereType<HistoryReferenceLayer>().single;
    expect(layer.path, image.path);
    expect(layer.opacity, 33);
    expect(layer.aspectRatio, 1.5);
    expect(layer.zoom, 700);
    expect(layer.offsetX, 3.5);
    expect(layer.offsetY, -4.25);
    expect(layer.brightness, 0.25);
    expect(layer.contrast, 1.25);
    expect(layer.saturation, 0.75);
    expect(layer.warmth, -0.5);
    expect(layer.visibilityState, LayerVisibilityState.hidden);
  });

  _fileTest("loading the project puts the image back on the layer", (final ProjectSession projectSession) async
  {
    final ReferenceImage image = await _loadedImage(name: "picture.png");
    _reference(image: image);
    await _images.removeImage(refImage: image);

    final ReferenceLayerState restored = await _reloaded(projectSession: projectSession);

    _expectSettings(reference: restored);
    expect(restored.image, isNotNull);
    expect(restored.image!.path, image.path);
    expect(restored.image!.image.width, 6);
    expect(restored.image!.image.height, 4);
  });

  _fileTest("a path outside of ascii survives", (final ProjectSession projectSession) async
  {
    final ReferenceImage image = await _loadedImage(name: "Größe € ぴ.png");
    _reference(image: image);

    final ReferenceLayerState restored = await _reloaded(projectSession: projectSession);

    expect(restored.image, isNotNull);
    expect(restored.image!.path, image.path);
  });

  _fileTest("an image that is gone leaves the layer in place without one", (final ProjectSession projectSession) async
  {
    final ReferenceImage image = await _loadedImage(name: "picture.png");
    _reference(image: image);
    final Uint8List bytes = await projectBytes();
    await _images.removeImage(refImage: image);
    File(image.path).deleteSync();
    final LoadFileSet loaded = await loadProjectBytes(bytes: bytes, path: "saved.kpix");
    projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
    await settle();

    final ProjectLoadResult result = await projectSession.restoreFromFile(loadFileSet: loaded);
    await settle();

    expect(result.restore, HistoryRestoreResult.success);
    final ReferenceLayerState restored = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.getAllLayers().whereType<ReferenceLayerState>().single;
    expect(restored.image, isNull);
    _expectSettings(reference: restored);
  });

  _fileTest("a layer that never had an image comes back without one", (final ProjectSession projectSession) async
  {
    _reference(image: null);

    final ReferenceLayerState restored = await _reloaded(projectSession: projectSession);

    expect(restored.image, isNull);
    _expectSettings(reference: restored);
  });

  group("values out of range", ()
  {
    //file offsets behind the path of a reference layer record
    const int opacityAt = 0;
    const int zoomAt = 9;
    const int aspectRatioAt = 11;
    const int brightnessAt = 15;
    const int contrastAt = 19;
    const int saturationAt = 23;
    const int warmthAt = 27;

    final List<_BadValue> badValues = <_BadValue>[
      _BadValue(
        name: "opacity",
        write: (final ByteData record, final int offset) => record.setUint8(offset + opacityAt, 101),
        warning: "Opacity for reference layer is out of range: 101",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.opacity, ReferenceLayerConstraints.opacityDefault),
      ),
      _BadValue(
        name: "zoom",
        write: (final ByteData record, final int offset) => record.setUint16(offset + zoomAt, 2001),
        warning: "Zoom for reference layer is out of range: 2001",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.zoom, ReferenceLayerConstraints.zoomDefault),
      ),
      _BadValue(
        name: "aspect ratio",
        write: (final ByteData record, final int offset) => record.setFloat32(offset + aspectRatioAt, 50.0),
        warning: "Aspect ratio for reference layer is out of range: 50.0",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.aspectRatio, ReferenceLayerConstraints.aspectRatioDefault),
      ),
      _BadValue(
        name: "brightness",
        write: (final ByteData record, final int offset) => record.setFloat32(offset + brightnessAt, 2.0),
        warning: "Brightness for reference layer is out of range: 2.0",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.brightness, ReferenceLayerConstraints.brightnessDefault),
      ),
      _BadValue(
        name: "contrast",
        write: (final ByteData record, final int offset) => record.setFloat32(offset + contrastAt, 3.0),
        warning: "Contrast for reference layer is out of range: 3.0",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.contrast, ReferenceLayerConstraints.contrastDefault),
      ),
      _BadValue(
        name: "saturation",
        write: (final ByteData record, final int offset) => record.setFloat32(offset + saturationAt, 3.0),
        warning: "Saturation for reference layer is out of range: 3.0",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.saturation, ReferenceLayerConstraints.saturationDefault),
      ),
      _BadValue(
        name: "warmth",
        write: (final ByteData record, final int offset) => record.setFloat32(offset + warmthAt, -2.0),
        warning: "Warmth for reference layer is out of range: -2.0",
        expectFallback: (final HistoryReferenceLayer layer) => expect(layer.warmth, ReferenceLayerConstraints.warmthDefault),
      ),
    ];

    /// The file of a project with the reference layer on top, with [bad] written into it.
    Future<Uint8List> damagedFile({required final _BadValue bad}) async
    {
      final ReferenceImage image = await _loadedImage(name: "picture.png");
      _reference(image: image);
      final Uint8List file = await projectBytes();
      final Uint8List body = Uint8List.fromList(const ZLibDecoder().decodeBytes(Uint8List.sublistView(file, 5)));

      //ramps, canvas size and layer count come before the first layer record,
      //which starts with its type, its visibility and the path length
      int recordAt = 1 + 6;
      for (final KPalRampData ramp in GetIt.I.get<PaletteState>().colorRamps)
      {
        recordAt += 11 + 3 * ramp.settings.colorCount;
      }
      final ByteData record = ByteData.sublistView(body);
      final int pathLength = record.getUint16(recordAt + 2);
      expect(pathLength, utf8.encode(image.path).length, reason: "setup: the record starts here");
      bad.write(record, recordAt + 4 + pathLength);

      final Uint8List compressed = const ZLibEncoder().encodeBytes(body);
      return Uint8List(5 + compressed.length)
        ..setAll(0, Uint8List.sublistView(file, 0, 5))
        ..setAll(5, compressed);
    }

    for (final _BadValue bad in badValues)
    {
      _fileTest("${bad.name} falls back to its default with a warning", (final ProjectSession projectSession) async
      {
        final LoadFileSet loaded = await loadProjectBytes(bytes: await damagedFile(bad: bad), path: "saved.kpix");

        expect(loaded.historyState, isNotNull, reason: loaded.status);
        expect(loaded.status, contains(bad.warning));
        final HistoryLayer layer = loaded.historyState!.timeline.allLayers.first;
        bad.expectFallback(layer as HistoryReferenceLayer);
      });

      _fileTest("${bad.name} refuses the file when loading strictly", (final ProjectSession projectSession) async
      {
        final LoadFileSet loaded = await loadProjectBytes(bytes: await damagedFile(bad: bad), path: "saved.kpix", strict: true);

        expect(loaded.historyState, isNull);
        expect(loaded.status, contains(bad.warning));
      });
    }
  });
}
