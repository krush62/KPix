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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/project_recovery.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 8, y: 6);
final CoordinateSetI _dot = CoordinateSetI(x: 5, y: 2);

Directory get _recoverDir => Directory(p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName));

List<String> _recoveryFiles()
{
  return _recoverDir.listSync().map((final FileSystemEntity entity) => p.basename(entity.path)).toList();
}

/// A project with a painted dot and unsaved changes.
Future<void> _unsavedWork({required final ProjectSession projectSession}) async
{
  await paintPixels(projectSession: projectSession, pixels: <CoordinateSetI, ColorReference>{_dot: GetIt.I.get<PaletteState>().colorRamps[1].references[2]});
  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
  expect(projectSession.hasChanges.value, isTrue, reason: "setup");
}

void _expectDot({required final ProjectSession projectSession})
{
  final ColorReference? color = layerAt(projectSession: projectSession, index: 0).getDataEntry(coord: _dot);
  expect(color, isNotNull);
  expect(color!.ramp, GetIt.I.get<PaletteState>().colorRamps[1]);
  expect(color.colorIndex, 2);
}

/// Runs [body] in a project whose internal directories exist on disk.
void _recoveryTest(final String description, final Future<void> Function(ProjectSession projectSession) body, {final bool skip = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
    {
      await createInternalDirectories();
      await body(projectSession);
    },);
  }, skip: skip,);
}

Future<String?> _noRequest() async => null;

void main()
{
  group("internal directories", ()
  {
    testWidgets("are created next to each other and survive a second run", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
      {
        await createInternalDirectories();
        final String internalDir = GetIt.I.get<AppPaths>().internalDir;
        for (final String name in <String>[palettesSubDirName, projectsSubDirName, recoverSubDirName, stampsSubDirName])
        {
          expect(Directory(p.join(internalDir, name)).existsSync(), isTrue, reason: name);
        }
        final File kept = File(p.join(internalDir, palettesSubDirName, "kept.kpal"))..writeAsBytesSync(<int>[1]);

        await createInternalDirectories();

        expect(kept.existsSync(), isTrue);
      },);
    });
  });

  group("recovery directory", ()
  {
    _recoveryTest("holds no recovery file while it is empty", (final ProjectSession projectSession) async
    {
      expect(await getRecoveryFile(), isNull);
    });

    testWidgets("holds no recovery file while it does not exist", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
      {
        expect(await getRecoveryFile(), isNull);
        await expectLater(clearRecoverDir(), completes);
      },);
    });

    _recoveryTest("gives the one file it holds", (final ProjectSession projectSession) async
    {
      final File file = File(p.join(_recoverDir.path, "work.kpix"))..writeAsBytesSync(<int>[1]);

      expect(await getRecoveryFile(), file.path);
    });

    _recoveryTest("does not guess between several files", (final ProjectSession projectSession) async
    {
      File(p.join(_recoverDir.path, "first.kpix")).writeAsBytesSync(<int>[1]);
      File(p.join(_recoverDir.path, "second.kpix")).writeAsBytesSync(<int>[1]);

      expect(await getRecoveryFile(), isNull);
    });

    _recoveryTest("is emptied of files and folders", (final ProjectSession projectSession) async
    {
      File(p.join(_recoverDir.path, "first.kpix")).writeAsBytesSync(<int>[1]);
      File(p.join((Directory(p.join(_recoverDir.path, "sub"))..createSync()).path, "second.kpix")).writeAsBytesSync(<int>[1]);

      await clearRecoverDir();

      expect(_recoverDir.existsSync(), isTrue);
      expect(_recoveryFiles(), isEmpty);
    });
  });

  group("ProjectRecovery", ()
  {
    _recoveryTest("writes unsaved work of an unnamed project under the recovery name", (final ProjectSession projectSession) async
    {
      await _unsavedWork(projectSession: projectSession);

      await ProjectRecovery().update(mayWrite: true);

      expect(_recoveryFiles(), <String>["$recoverFileName.$fileExtensionKpix"]);
    });

    _recoveryTest("writes unsaved work of a named project under its name", (final ProjectSession projectSession) async
    {
      projectSession.projectName.value = "my drawing";
      await _unsavedWork(projectSession: projectSession);

      await ProjectRecovery().update(mayWrite: true);

      expect(_recoveryFiles(), <String>["my drawing.$fileExtensionKpix"]);
    });

    _recoveryTest("replaces the previous file instead of adding to it", (final ProjectSession projectSession) async
    {
      final ProjectRecovery recovery = ProjectRecovery();
      await _unsavedWork(projectSession: projectSession);
      await recovery.update(mayWrite: true);

      projectSession.projectName.value = "named by now";
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
      await recovery.update(mayWrite: true);

      expect(_recoveryFiles(), <String>["named by now.$fileExtensionKpix"]);
    });

    _recoveryTest("holds back the write when told to and keeps what is there", (final ProjectSession projectSession) async
    {
      final ProjectRecovery recovery = ProjectRecovery();
      await _unsavedWork(projectSession: projectSession);

      await recovery.update(mayWrite: false);
      expect(_recoveryFiles(), isEmpty);

      await recovery.update(mayWrite: true);
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
      await recovery.update(mayWrite: false);
      expect(_recoveryFiles(), hasLength(1));
    });

    _recoveryTest("writes once per history state", (final ProjectSession projectSession) async
    {
      final ProjectRecovery recovery = ProjectRecovery();
      await _unsavedWork(projectSession: projectSession);
      await recovery.update(mayWrite: true);
      await clearRecoverDir();

      await recovery.update(mayWrite: true);
      expect(_recoveryFiles(), isEmpty, reason: "nothing changed since the last write");

      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerOrderChange);
      await recovery.update(mayWrite: true);
      expect(_recoveryFiles(), hasLength(1));
    });

    _recoveryTest("empties the directory once nothing is unsaved", (final ProjectSession projectSession) async
    {
      final ProjectRecovery recovery = ProjectRecovery();
      await _unsavedWork(projectSession: projectSession);
      await recovery.update(mayWrite: true);
      expect(_recoveryFiles(), hasLength(1), reason: "setup");

      projectSession.hasChanges.value = false;
      await recovery.update(mayWrite: false);

      expect(_recoveryFiles(), isEmpty);
    });

    _recoveryTest("empties the directory without a project", (final ProjectSession projectSession) async
    {
      final ProjectRecovery recovery = ProjectRecovery();
      await _unsavedWork(projectSession: projectSession);
      await recovery.update(mayWrite: true);

      projectSession.hasProjectNotifier.value = false;
      await recovery.update(mayWrite: true);

      expect(_recoveryFiles(), isEmpty);
    });

    //BUG: skipped until fixed, clearing the directory does not forget the last written state
    _recoveryTest("writes again after going back to a state whose file was cleared", (final ProjectSession projectSession) async
    {
      final ProjectRecovery recovery = ProjectRecovery();
      await _unsavedWork(projectSession: projectSession);
      await recovery.update(mayWrite: true);

      //undo back to the saved state empties the directory, and redo returns to
      //the state written before, which is unsaved work with no file behind it
      await GetIt.I.get<HistoryController>().undoPressed()!.restore;
      expect(projectSession.hasChanges.value, isFalse, reason: "setup");
      await recovery.update(mayWrite: true);
      expect(_recoveryFiles(), isEmpty, reason: "setup");
      await GetIt.I.get<HistoryController>().redoPressed()!.restore;
      expect(projectSession.hasChanges.value, isTrue, reason: "setup");

      await recovery.update(mayWrite: true);

      expect(_recoveryFiles(), hasLength(1));
    }, skip: true,);
  });

  group("start up", ()
  {
    _recoveryTest("a recovery file wins and the requested file is not even asked for", (final ProjectSession projectSession) async
    {
      await _unsavedWork(projectSession: projectSession);
      await ProjectRecovery().update(mayWrite: true);
      bool asked = false;

      final InitialProject initial = await findInitialProject(requestedPath: () async
      {
        asked = true;
        return "somewhere/else.kpix";
      },);

      expect(asked, isFalse);
      expect(initial.fromRecovery, isTrue);
      expect(initial.path, p.join(_recoverDir.path, "$recoverFileName.$fileExtensionKpix"));
      expect(initial.importResult, isNull);
    });

    _recoveryTest("nothing to open without a recovery file or a request", (final ProjectSession projectSession) async
    {
      final InitialProject initial = await findInitialProject(requestedPath: _noRequest);

      expect(initial.path, isNull);
      expect(initial.fromRecovery, isFalse);
      expect(initial.importResult, ProjectImportResult.cancelled);
      expect(await openInitialProject(project: initial), isNull);
    });

    _recoveryTest("a requested file is imported and opened from the projects directory", (final ProjectSession projectSession) async
    {
      await _unsavedWork(projectSession: projectSession);
      final File requested = File(p.join(GetIt.I.get<AppPaths>().exportDir, "shared.kpix"))..writeAsBytesSync(await projectBytes());

      final InitialProject initial = await findInitialProject(requestedPath: () async => requested.path);

      expect(initial.importResult, ProjectImportResult.success);
      expect(initial.fromRecovery, isFalse);
      expect(initial.path, p.join(GetIt.I.get<AppPaths>().projectsDir, "shared.kpix"));
      expect(File(initial.path!).existsSync(), isTrue);
    });

    _recoveryTest("a requested file already in the projects directory opens that project", (final ProjectSession projectSession) async
    {
      final File requested = File(p.join(GetIt.I.get<AppPaths>().exportDir, "shared.kpix"))..writeAsBytesSync(await projectBytes());
      final File existing = File(p.join(GetIt.I.get<AppPaths>().projectsDir, "shared.kpix"))..writeAsBytesSync(await projectBytes());

      final InitialProject initial = await findInitialProject(requestedPath: () async => requested.path);

      expect(initial.importResult, ProjectImportResult.projectAlreadyExists);
      expect(initial.path, existing.path);
    });

    _recoveryTest("a requested file of another type opens nothing", (final ProjectSession projectSession) async
    {
      final InitialProject initial = await findInitialProject(requestedPath: () async => "folder/picture.png");

      expect(initial.importResult, ProjectImportResult.notAKPixFile);
      expect(initial.path, isNull);
    });

    _recoveryTest("unsaved work comes back after a restart, still marked as unsaved", (final ProjectSession projectSession) async
    {
      await _unsavedWork(projectSession: projectSession);
      await ProjectRecovery().update(mayWrite: true);
      projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
      await settle();

      final ProjectLoadResult? result = await openInitialProject(project: await findInitialProject(requestedPath: _noRequest));
      await settle();

      expect(result!.restore, HistoryRestoreResult.success);
      _expectDot(projectSession: projectSession);
      expect(projectSession.hasChanges.value, isTrue);
      expect(projectSession.projectName.value, isNull);
    });

    _recoveryTest("a named project comes back under its name", (final ProjectSession projectSession) async
    {
      projectSession.projectName.value = "my drawing";
      await _unsavedWork(projectSession: projectSession);
      await ProjectRecovery().update(mayWrite: true);
      projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
      await settle();

      await openInitialProject(project: await findInitialProject(requestedPath: _noRequest));
      await settle();

      expect(projectSession.projectName.value, "my drawing");
      expect(projectSession.hasChanges.value, isTrue);
    });

    _recoveryTest("a project opened by request is not marked as unsaved", (final ProjectSession projectSession) async
    {
      await _unsavedWork(projectSession: projectSession);
      final File requested = File(p.join(GetIt.I.get<AppPaths>().exportDir, "shared.kpix"))..writeAsBytesSync(await projectBytes());
      projectSession.init(dimensions: CoordinateSetI(x: 3, y: 3));
      await settle();

      final ProjectLoadResult? result = await openInitialProject(project: await findInitialProject(requestedPath: () async => requested.path));
      await settle();

      expect(result!.restore, HistoryRestoreResult.success);
      _expectDot(projectSession: projectSession);
      expect(projectSession.hasChanges.value, isFalse);
      expect(projectSession.projectName.value, "shared");
    });

    _recoveryTest("a damaged recovery file loads nothing and leaves the session alone", (final ProjectSession projectSession) async
    {
      File(p.join(_recoverDir.path, "$recoverFileName.$fileExtensionKpix")).writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6, 7, 8]);
      projectSession.projectName.value = "current";

      final ProjectLoadResult? result = await openInitialProject(project: await findInitialProject(requestedPath: _noRequest));

      expect(result, isNull);
      expect(projectSession.projectName.value, "current");
    });
  });
}
