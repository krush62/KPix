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
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
// ignore: implementation_imports
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 6);
final CoordinateSetI _dot = CoordinateSetI(x: 5, y: 2);

String get _exportDir => GetIt.I.get<AppPaths>().exportDir;
String get _projectsDir => GetIt.I.get<AppPaths>().projectsDir;

/// A valid project file outside the projects directory.
Future<File> _exportedProject({final String name = "shared.$fileExtensionKpix"}) async
{
  return File(p.join(_exportDir, name)).writeAsBytes(await projectBytes());
}

void _importTest(final String description, final Future<void> Function(ProjectSession projectSession) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
    {
      await body(projectSession);
    },);
  });
}

Future<void> _setReadOnly({required final String path, required final bool readOnly}) async
{
  final ProcessResult result = Platform.isWindows
      ? await Process.run("attrib", <String>[if (readOnly) "+r" else "-r", path])
      : await Process.run("chmod", <String>[if (readOnly) "444" else "644", path]);
  expect(result.exitCode, 0, reason: "setup: ${result.stderr}");
}

/// Waits until [condition] holds, on a clock that is not the one under test.
Future<void> _waitFor({required final bool Function() condition, required final String what}) async
{
  final Stopwatch stopwatch = Stopwatch()..start();
  while (!condition())
  {
    if (stopwatch.elapsed > const Duration(seconds: 20))
    {
      fail("Timed out waiting for $what.");
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _FakeFilePicker extends FilePickerPlatform
{
  final FilePickerResult? result;
  int pickCount = 0;
  _FakeFilePicker({required this.result});

  @override
  Future<FilePickerResult?> pickFiles({
    final String? dialogTitle,
    final String? initialDirectory,
    final FileType type = FileType.any,
    final List<String>? allowedExtensions,
    final Function(FilePickerStatus)? onFileLoading,
    final int compressionQuality = 0,
    final bool allowMultiple = false,
    final bool withData = false,
    final bool withReadStream = false,
    final bool lockParentWindow = false,
    final bool readSequential = false,
    final bool cancelUploadOnWindowBlur = true,
  }) async
  {
    pickCount++;
    return result;
  }
}

void main()
{
  group("importProject", ()
  {
    _importTest("without a path was cancelled", (final ProjectSession projectSession) async
    {
      expect(await importProject(path: null), ProjectImportResult.cancelled);
      expect(await importProject(path: ""), ProjectImportResult.cancelled);
    });

    _importTest("refuses another file type without opening it", (final ProjectSession projectSession) async
    {
      expect(await importProject(path: p.join(_exportDir, "does not exist.png")), ProjectImportResult.notAKPixFile);
    });

    _importTest("reports a missing file", (final ProjectSession projectSession) async
    {
      expect(await importProject(path: p.join(_exportDir, "gone.$fileExtensionKpix")), ProjectImportResult.couldNotOpenFile);
    });

    _importTest("reports a damaged file and copies nothing", (final ProjectSession projectSession) async
    {
      final File damaged = File(p.join(_exportDir, "damaged.$fileExtensionKpix"))..writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6, 7, 8]);

      expect(await importProject(path: damaged.path), ProjectImportResult.couldNotOpenFile);
      expect(Directory(_projectsDir).listSync(), isEmpty);
    });

    _importTest("copies the project and renders a thumbnail for it", (final ProjectSession projectSession) async
    {
      await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: GetIt.I.get<PaletteState>().colorRamps[1].references[2]});
      final File source = await _exportedProject();

      expect(await importProject(path: source.path), ProjectImportResult.success);

      final File copy = File(p.join(_projectsDir, "shared.$fileExtensionKpix"));
      expect(copy.readAsBytesSync(), source.readAsBytesSync());
      expect(source.existsSync(), isTrue, reason: "an import is a copy");
      final ui.Codec codec = await ui.instantiateImageCodec(File(p.join(_projectsDir, "shared.$thumbnailExtension")).readAsBytesSync());
      final ui.Image thumbnail = (await codec.getNextFrame()).image;
      expect(thumbnail.width, _canvasSize.x);
      expect(thumbnail.height, _canvasSize.y);
      final ByteData pixels = (await thumbnail.toByteData())!;
      expect(pixels.getUint8((_dot.y * _canvasSize.x + _dot.x) * 4 + 3), 255, reason: "the painted pixel shows on the thumbnail");
      expect(pixels.getUint8(3), 0, reason: "the rest stays transparent");
      thumbnail.dispose();
      codec.dispose();
    });

    _importTest("does not overwrite a project of the same name", (final ProjectSession projectSession) async
    {
      final File source = await _exportedProject();
      final File existing = File(p.join(_projectsDir, "shared.$fileExtensionKpix"))..writeAsBytesSync(<int>[9, 9, 9]);

      expect(await importProject(path: source.path), ProjectImportResult.projectAlreadyExists);
      expect(existing.readAsBytesSync(), <int>[9, 9, 9]);
    });

    _importTest("reports a projects directory it cannot write to", (final ProjectSession projectSession) async
    {
      final File source = await _exportedProject();
      GetIt.I.get<AppPaths>().projectsDir = p.join(_projectsDir, "not created");

      expect(await importProject(path: source.path), ProjectImportResult.couldNotOpenFile);
    });

    //a file picked from a phone over MTP arrives read-only on Windows, File.copy
    //passed that on, and the project could then neither be saved nor deleted
    _importTest("leaves the copy of a read-only file writable", (final ProjectSession projectSession) async
    {
      final File source = await _exportedProject();
      await _setReadOnly(path: source.path, readOnly: true);
      try
      {
        if (Platform.isWindows)
        {
          expect(() => source.writeAsBytesSync(<int>[1]), throwsA(isA<FileSystemException>()), reason: "setup: the source is read-only");
        }

        expect(await importProject(path: source.path), ProjectImportResult.success);

        final File copy = File(p.join(_projectsDir, "shared.$fileExtensionKpix"));
        expect(() => copy.writeAsBytesSync(<int>[1]), returnsNormally);
        expect(() => copy.deleteSync(), returnsNormally);
      }
      finally
      {
        await _setReadOnly(path: source.path, readOnly: false);
      }
    });

    _importTest("reaches an open project list", (final ProjectSession projectSession) async
    {
      final ProjectManager manager = ProjectManager();
      GetIt.I.registerSingleton<ProjectManager>(manager);
      await manager.reindex();
      final File source = await _exportedProject();

      expect(await importProject(path: source.path), ProjectImportResult.success);

      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the imported project to be listed");
      expect(manager.projects.value.map((final ProjectManagerEntryData entry) => entry.name), <String>["shared"]);
      manager.dispose();
    });
  });

  group("deleteProject", ()
  {
    _importTest("removes the project and its thumbnail", (final ProjectSession projectSession) async
    {
      final File project = File(p.join(_projectsDir, "gone.$fileExtensionKpix"))..writeAsBytesSync(<int>[1]);
      final File thumbnail = File(p.join(_projectsDir, "gone.$thumbnailExtension"))..writeAsBytesSync(<int>[1]);
      final File other = File(p.join(_projectsDir, "other.$fileExtensionKpix"))..writeAsBytesSync(<int>[1]);

      expect(await deleteProject(fullProjectPath: project.path), isTrue);

      expect(project.existsSync(), isFalse);
      expect(thumbnail.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);
    });

    _importTest("does not need a thumbnail", (final ProjectSession projectSession) async
    {
      final File project = File(p.join(_projectsDir, "gone.$fileExtensionKpix"))..writeAsBytesSync(<int>[1]);

      expect(await deleteProject(fullProjectPath: project.path), isTrue);
      expect(project.existsSync(), isFalse);
    });

    _importTest("reports a project that is not there", (final ProjectSession projectSession) async
    {
      expect(await deleteProject(fullProjectPath: p.join(_projectsDir, "gone.$fileExtensionKpix")), isFalse);
    });

    _importTest("drops the project from an open project list", (final ProjectSession projectSession) async
    {
      final File project = File(p.join(_projectsDir, "gone.$fileExtensionKpix"))..writeAsBytesSync(<int>[1]);
      final ProjectManager manager = ProjectManager();
      GetIt.I.registerSingleton<ProjectManager>(manager);
      await manager.reindex();
      expect(manager.projects.value, hasLength(1), reason: "setup");

      await deleteProject(fullProjectPath: project.path);

      await _waitFor(condition: () => manager.projects.value.isEmpty, what: "the project to drop out of the list");
      manager.dispose();
    });
  });

  group("loadFilePressed", ()
  {
    /// Presses load with [picked] coming back from the file dialog.
    Future<({bool started, ProjectLoadResult? result})> pressLoad({required final FilePickerResult picked}) async
    {
      final FilePickerPlatform previous = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _FakeFilePicker(result: picked);
      addTearDown(() => FilePickerPlatform.instance = previous);

      bool started = false;
      final Completer<ProjectLoadResult?> finished = Completer<ProjectLoadResult?>();
      loadFilePressed(
        loadStartCallback: () {started = true;},
        finishCallback: finished.complete,
      );
      final ProjectLoadResult? result = await finished.future.timeout(const Duration(seconds: 20));
      return (started: started, result: result);
    }

    _importTest("loads the picked file into the session", (final ProjectSession projectSession) async
    {
      await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: GetIt.I.get<PaletteState>().colorRamps[1].references[2]});
      final File source = await _exportedProject(name: "picked.$fileExtensionKpix");
      projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
      await settle();

      final ({bool started, ProjectLoadResult? result}) load = await pressLoad(picked: FilePickerResult(<PlatformFile>[PlatformFile(name: "picked.$fileExtensionKpix", path: source.path, size: source.lengthSync())]));
      await settle();

      expect(load.started, isTrue);
      expect(load.result!.restore, HistoryRestoreResult.success);
      expect(projectSession.projectName.value, "picked");
      expect(layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: _dot)!.colorIndex, 2);
    });

    //what web hands back: bytes and a name, but no path to read from
    _importTest("prefers bytes that came with the pick", (final ProjectSession projectSession) async
    {
      final Uint8List bytes = await projectBytes();

      final ({bool started, ProjectLoadResult? result}) load = await pressLoad(picked: FilePickerResult(<PlatformFile>[PlatformFile(name: "from web.$fileExtensionKpix", bytes: bytes, size: bytes.length)]));

      expect(load.result!.restore, HistoryRestoreResult.success);
      expect(projectSession.projectName.value, "from web");
    });

    _importTest("reports a damaged file without touching the session", (final ProjectSession projectSession) async
    {
      projectSession.projectName.value = "current";
      final File damaged = File(p.join(_exportDir, "damaged.$fileExtensionKpix"))..writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6, 7, 8]);

      final ({bool started, ProjectLoadResult? result}) load = await pressLoad(picked: FilePickerResult(<PlatformFile>[PlatformFile(name: "damaged.$fileExtensionKpix", path: damaged.path, size: 8)]));

      expect(load.result!.restore, isNull);
      expect(load.result!.status, isNotEmpty);
      expect(projectSession.projectName.value, "current");
    });

    _importTest("does nothing when the dialog is cancelled", (final ProjectSession projectSession) async
    {
      final FilePickerPlatform previous = FilePickerPlatform.instance;
      final _FakeFilePicker picker = _FakeFilePicker(result: null);
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = previous);
      bool called = false;

      loadFilePressed(loadStartCallback: () {called = true;}, finishCallback: (final ProjectLoadResult? result) {called = true;});
      await _waitFor(condition: () => picker.pickCount == 1, what: "the dialog");
      await Future<void>.delayed(Duration.zero);

      expect(called, isFalse);
    });
  });
}
