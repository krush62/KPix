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

import 'dart:io';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/import/import_kpix.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:path/path.dart' as p;

import 'selection_harness.dart';

/// Real export, internal and project directories in a scratch folder that goes
/// away with the test. Tear downs run on the fake clock, so this stays sync.
AppPaths createTestPaths()
{
  final Directory root = Directory.systemTemp.createTempSync("kpix_files_test");
  addTearDown(()
  {
    try
    {
      root.deleteSync(recursive: true);
    }
    catch (_)
    {
      //a directory watch can still hold the folder for a moment on Windows, and a
      //left over temp directory is not worth failing a test over
    }
  });
  String subDir(final String name) => (Directory(p.join(root.path, name))..createSync()).path;
  return AppPaths(exportDir: subDir("export"), internalDir: subDir("internal"), projectsDir: subDir("projects"));
}

Future<Uint8List> projectBytes() async
{
  return (await createKPixData()).buffer.asUint8List();
}

Future<LoadFileSet> loadProjectBytes({required final Uint8List bytes, required final String path, final bool strict = false}) async
{
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
  return loadKPixFile(
    fileData: bytes,
    path: path,
    drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
    shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
    frameConstraints: prefs.frameConstraints,
    strict: strict,
  );
}

/// Sets [pixels] on the drawing layer at [layerIndex] of the selected frame.
Future<void> paintPixels({required final ProjectSession projectSession, required final Map<CoordinateSetI, ColorReference> pixels, final int layerIndex = 0}) async
{
  layerAt(projectSession: projectSession, index: layerIndex).setDataAll(list: CoordinateColorMapNullable.from(pixels));
  await settle();
}

Future<void> setReadOnly({required final String path, required final bool readOnly}) async
{
  final ProcessResult result = Platform.isWindows
      ? await Process.run("attrib", <String>[if (readOnly) "+r" else "-r", path])
      : await Process.run("chmod", <String>[if (readOnly) "444" else "644", path]);
  expect(result.exitCode, 0, reason: "setup: ${result.stderr}");
}

/// A file the way a native dialog hands it back: a path on disk, read on demand.
final class FakePickedFile extends PlatformFile
{
  final File file;
  int readCount = 0;
  FakePickedFile(this.file);

  @override
  String get name => p.basename(file.path);

  @override
  Uri get uri => Uri.file(file.path);

  @override
  XFile get xFile => XFile(file.path, name: name);

  @override
  int? lengthSync() => file.lengthSync();

  @override
  Future<int?> length() => file.length();

  @override
  Future<Uint8List> readAsBytes()
  {
    readCount++;
    return file.readAsBytes();
  }

  @override
  Stream<Uint8List> readAsByteStream()
  {
    readCount++;
    return file.openRead().map<Uint8List>(Uint8List.fromList);
  }
}

class FakeFilePicker extends FilePickerPlatform
{
  final PlatformFile? file;
  int pickCount = 0;
  FakeFilePicker({required this.file});

  @override
  Future<PlatformFile?> pickFile({
    final String? dialogTitle,
    final String? initialDirectory,
    final FileType type = FileType.any,
    final List<String>? allowedExtensions,
    final Function(FilePickerStatus)? onFileLoading,
    final int compressionQuality = 0,
    final AndroidOptions androidOptions = const AndroidOptions(),
    final DarwinOptions darwinOptions = const DarwinOptions(),
    final WindowsOptions windowsOptions = const WindowsOptions(),
    final LinuxOptions linuxOptions = const LinuxOptions(),
    final WebOptions webOptions = const WebOptions(),
  }) async
  {
    pickCount++;
    return file;
  }
}

/// Answers the file dialog with [file] until the end of the test.
FakeFilePicker installFakeFilePicker({required final PlatformFile? file})
{
  final FilePickerPlatform previous = FilePickerPlatform.instance;
  final FakeFilePicker picker = FakeFilePicker(file: file);
  FilePickerPlatform.instance = picker;
  addTearDown(() => FilePickerPlatform.instance = previous);
  return picker;
}

/// A blank png of the given size.
Uint8List pngBytes({required final int width, required final int height})
{
  return img.encodePng(img.Image(width: width, height: height, numChannels: 4));
}
