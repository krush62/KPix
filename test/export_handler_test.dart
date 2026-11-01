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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/export_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 6, y: 4);

String get _exportDir => GetIt.I.get<AppPaths>().exportDir;
String get _missingDir => p.join(_exportDir, "not created");

const List<int> _png = <int>[0x89, 0x50, 0x4E, 0x47];
const List<int> _zip = <int>[0x50, 0x4B, 0x03, 0x04];
const List<int> _riff = <int>[0x52, 0x49, 0x46, 0x46];
const List<int> _gif = <int>[0x47, 0x49, 0x46, 0x38];

/// How each kind of file starts, at the offset given, so that a mix up of the
/// formats shows.
final Map<ImageExportType, (int, List<int>)> _imageSignatures = <ImageExportType, (int, List<int>)>{
  ImageExportType.png: (0, _png),
  ImageExportType.webp: (0, _riff),
  ImageExportType.aseprite: (4, <int>[0xE0, 0xA5]),
  ImageExportType.photoshop: (0, "8BPS".codeUnits),
  ImageExportType.gimp: (0, "gimp xcf".codeUnits),
  ImageExportType.pixelorama: (0, _zip),
  ImageExportType.kpix: (0, <int>[for (int i = 0; i < 4; i++) int.parse(magicNumber.substring(i * 2, i * 2 + 2), radix: 16)]),
  ImageExportType.texturePack: (0, _zip),
};

final Map<AnimationExportType, (int, List<int>)> _animationSignatures = <AnimationExportType, (int, List<int>)>{
  AnimationExportType.gif: (0, _gif),
  AnimationExportType.apng: (0, _png),
  AnimationExportType.webp: (0, _riff),
  AnimationExportType.zippedPng: (0, _zip),
  AnimationExportType.texturePack: (0, _zip),
};

final Map<PaletteExportType, (int, List<int>)> _paletteSignatures = <PaletteExportType, (int, List<int>)>{
  PaletteExportType.png: (0, _png),
  PaletteExportType.aseprite: (4, <int>[0xE0, 0xA5]),
  PaletteExportType.gimp: (0, "GIMP Palette".codeUnits),
  PaletteExportType.paintNet: (0, "; KPix_".codeUnits),
  PaletteExportType.adobe: (0, "ASEF".codeUnits),
  PaletteExportType.jasc: (0, "JASC-PAL".codeUnits),
  PaletteExportType.corel: (0, "<?".codeUnits),
  PaletteExportType.openOffice: (0, "<?xml".codeUnits),
  PaletteExportType.json: (0, '{"colors"'.codeUnits),
  //option count and ramp count of the default palette
  PaletteExportType.kpal: (0, <int>[0, 7]),
};

void _expectSignature({required final String? path, required final String directory, required final String extension, required final (int, List<int>) signature})
{
  expect(path, p.join(directory, "out.$extension"));
  final Uint8List bytes = File(path!).readAsBytesSync();
  expect(bytes.sublist(signature.$1, signature.$1 + signature.$2.length), signature.$2);
}

void _handlerTest(final String description, final Future<void> Function(ProjectSession projectSession) body, {final bool skip = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
    {
      await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{CoordinateSetI(x: 2, y: 1): GetIt.I.get<PaletteState>().colorRamps[1].references[2]});
      await body(projectSession);
    },);
  }, skip: skip,);
}

void main()
{
  test("every export type has a signature to check", ()
  {
    expect(_imageSignatures.keys.toSet(), ImageExportType.values.toSet());
    expect(_animationSignatures.keys.toSet(), AnimationExportType.values.toSet());
    expect(_paletteSignatures.keys.toSet(), PaletteExportType.values.toSet());
  });

  group("exportImage", ()
  {
    for (final ImageExportType type in ImageExportType.values)
    {
      _handlerTest("writes ${type.name} under its extension", (final ProjectSession projectSession) async
      {
        final ImageExportData data = ImageExportData.exportTypeMap[type]!;

        final String? path = await exportImage(exportData: ImageExportData.fromWithConcreteData(other: data, scaling: 1, fileName: "out", directory: _exportDir), exportType: type);

        _expectSignature(path: path, directory: _exportDir, extension: data.extension, signature: _imageSignatures[type]!);
      });
    }

    _handlerTest("reports a directory it cannot write to", (final ProjectSession projectSession) async
    {
      final ImageExportData data = ImageExportData.exportTypeMap[ImageExportType.png]!;

      expect(await exportImage(exportData: ImageExportData.fromWithConcreteData(other: data, scaling: 1, fileName: "out", directory: _missingDir), exportType: ImageExportType.png), isNull);
    });

    _handlerTest("reports a format that cannot hold the project", (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final List<KPalRampData> ramps = <KPalRampData>[for (int i = 0; i < 20; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()..colorCount = 15)];
      palette.colorRamps = ramps;
      final ImageExportData data = ImageExportData.exportTypeMap[ImageExportType.aseprite]!;

      final String? path = await exportImage(exportData: ImageExportData.fromWithConcreteData(other: data, scaling: 1, fileName: "out", directory: _exportDir), exportType: ImageExportType.aseprite);

      expect(path, isNull);
      expect(Directory(_exportDir).listSync(), isEmpty, reason: "no half written file");
    });
  });

  group("exportAnimation", ()
  {
    for (final AnimationExportType type in AnimationExportType.values)
    {
      _handlerTest("writes ${type.name} under its extension", (final ProjectSession projectSession) async
      {
        final AnimationExportData data = AnimationExportData.exportTypeMap[type]!;

        final String? path = await exportAnimation(exportData: AnimationExportData.fromWithConcreteData(other: data, scaling: 1, fileName: "out", directory: _exportDir, loopOnly: false), exportType: type);

        _expectSignature(path: path, directory: _exportDir, extension: data.extension, signature: _animationSignatures[type]!);
      });
    }

    _handlerTest("reports a directory it cannot write to", (final ProjectSession projectSession) async
    {
      final AnimationExportData data = AnimationExportData.exportTypeMap[AnimationExportType.gif]!;

      expect(await exportAnimation(exportData: AnimationExportData.fromWithConcreteData(other: data, scaling: 1, fileName: "out", directory: _missingDir, loopOnly: false), exportType: AnimationExportType.gif), isNull);
    });
  });

  group("exportPalettePressed", ()
  {
    for (final PaletteExportType type in PaletteExportType.values)
    {
      _handlerTest("writes ${type.name} under its extension", (final ProjectSession projectSession) async
      {
        final PaletteExportData data = PaletteExportData.exportTypeMap[type]!;

        final String? path = await exportPalettePressed(saveData: PaletteExportData.fromWithConcreteData(other: data, fileName: "out", directory: _exportDir), paletteType: type);

        _expectSignature(path: path, directory: _exportDir, extension: data.extension, signature: _paletteSignatures[type]!);
      });
    }

    _handlerTest("reports a directory it cannot write to", (final ProjectSession projectSession) async
    {
      final PaletteExportData data = PaletteExportData.exportTypeMap[PaletteExportType.jasc]!;

      expect(await exportPalettePressed(saveData: PaletteExportData.fromWithConcreteData(other: data, fileName: "out", directory: _missingDir), paletteType: PaletteExportType.jasc), isNull);
    });
  });

  group("saveCurrentPalette", ()
  {
    //BUG: skipped until fixed, the widget shows an error when this returns null, but a
    //failed write throws instead, so nothing is shown and the error goes unhandled
    _handlerTest("reports a directory it cannot write to", (final ProjectSession projectSession) async
    {
      expect(await saveCurrentPalette(fileName: "out", directory: _missingDir, extension: fileExtensionKpal), isNull);
    }, skip: true,);
  });
}
