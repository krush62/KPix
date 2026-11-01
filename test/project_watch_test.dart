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
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 4, y: 4);

String get _projectsDir => GetIt.I.get<AppPaths>().projectsDir;

File _project({required final String name, final String? dir}) => File(p.join(dir ?? _projectsDir, "$name.$fileExtensionKpix"));
File _thumbnail({required final String name}) => File(p.join(_projectsDir, "$name.$thumbnailExtension"));

List<String> _names({required final ProjectManager manager})
{
  return manager.projects.value.map((final ProjectManagerEntryData entry) => entry.name).toList()..sort();
}

/// Waits until [condition] holds. File system events take their time and the
/// manager debounces them, so a fixed wait would be either slow or flaky.
Future<void> _waitFor({required final bool Function() condition, required final String what}) async
{
  final Stopwatch stopwatch = Stopwatch()..start();
  while (!condition())
  {
    if (stopwatch.elapsed > const Duration(seconds: 30))
    {
      fail("Timed out waiting for $what.");
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// A started manager on the projects directory, as the app runs one.
void _watchTest(final String description, final Future<void> Function(ProjectManager manager) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
    {
      final ProjectManager manager = ProjectManager();
      GetIt.I.registerSingleton<ProjectManager>(manager);
      try
      {
        await manager.start();
        await body(manager);
      }
      finally
      {
        manager.dispose();
      }
    },);
  }, timeout: const Timeout(Duration(minutes: 2)),);
}

void main()
{
  group("watching the directory", ()
  {
    _watchTest("lists a project that appears", (final ProjectManager manager) async
    {
      expect(manager.projects.value, isEmpty, reason: "setup");

      _project(name: "new").writeAsBytesSync(<int>[1]);

      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the new project");
      expect(_names(manager: manager), <String>["new"]);
      expect(manager.projects.value.single.thumbnail, isNull);
    });

    _watchTest("drops a project that disappears", (final ProjectManager manager) async
    {
      _project(name: "first").writeAsBytesSync(<int>[1]);
      _project(name: "second").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.length == 2, what: "both projects");

      _project(name: "first").deleteSync();

      await _waitFor(condition: () => manager.projects.value.length == 1, what: "the project to drop out");
      expect(_names(manager: manager), <String>["second"]);
    });

    _watchTest("follows a rename", (final ProjectManager manager) async
    {
      _project(name: "before").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the project");

      _project(name: "before").renameSync(_project(name: "after").path);

      await _waitFor(condition: () => _names(manager: manager).contains("after") && !_names(manager: manager).contains("before"), what: "the rename");
    });

    _watchTest("picks up a thumbnail written after the project", (final ProjectManager manager) async
    {
      _project(name: "drawing").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the project");

      _thumbnail(name: "drawing").writeAsBytesSync(pngBytes(width: 3, height: 2));

      await _waitFor(condition: () => manager.projects.value.single.thumbnail != null, what: "the thumbnail");
      expect(manager.projects.value.single.thumbnail!.width, 3);
    });

    _watchTest("ignores temporary and unrelated files", (final ProjectManager manager) async
    {
      _project(name: ".hidden").writeAsBytesSync(<int>[1]);
      _project(name: "~temp").writeAsBytesSync(<int>[1]);
      File(p.join(_projectsDir, "notes.txt")).writeAsBytesSync(<int>[1]);
      //events arrive in order, so once this one is through the others have been seen
      _project(name: "real").writeAsBytesSync(<int>[1]);

      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the real project");

      expect(_names(manager: manager), <String>["real"]);
    });

    _watchTest("ignores a file in a sub directory", (final ProjectManager manager) async
    {
      final Directory sub = Directory(p.join(_projectsDir, "sub"))..createSync();
      _project(name: "nested", dir: sub.path).writeAsBytesSync(<int>[1]);
      _project(name: "real").writeAsBytesSync(<int>[1]);

      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the real project");

      expect(_names(manager: manager), <String>["real"]);
    });

    _watchTest("clears the selection when the selected project disappears", (final ProjectManager manager) async
    {
      _project(name: "chosen").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the project");
      manager.selectedPath.value = manager.projects.value.single.path;

      _project(name: "chosen").deleteSync();

      await _waitFor(condition: () => manager.selectedPath.value == null, what: "the selection to clear");
    });

    _watchTest("keeps the selection when another project disappears", (final ProjectManager manager) async
    {
      _project(name: "chosen").writeAsBytesSync(<int>[1]);
      _project(name: "other").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.length == 2, what: "both projects");
      final String selected = manager.projects.value.firstWhere((final ProjectManagerEntryData entry) => entry.name == "chosen").path;
      manager.selectedPath.value = selected;

      _project(name: "other").deleteSync();

      await _waitFor(condition: () => manager.projects.value.length == 1, what: "the other project to drop out");
      expect(manager.selectedPath.value, selected);
    });
  });

  group("moving to another directory", ()
  {
    _watchTest("replaces the list and watches the new directory", (final ProjectManager manager) async
    {
      final AppPaths paths = GetIt.I.get<AppPaths>();
      final String oldDir = paths.projectsDir;
      _project(name: "old").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the old project");
      final String newDir = (Directory(p.join(paths.exportDir, "moved"))..createSync()).path;
      _project(name: "waiting", dir: newDir).writeAsBytesSync(<int>[1]);

      paths.projectsDir = newDir;

      await _waitFor(condition: () => _names(manager: manager).join() == "waiting", what: "the list of the new directory");

      _project(name: "added", dir: newDir).writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => _names(manager: manager).contains("added"), what: "the watch on the new directory");

      //once the new directory has reported this, the old one has had its chance
      _project(name: "stale", dir: oldDir).writeAsBytesSync(<int>[1]);
      _project(name: "later", dir: newDir).writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => _names(manager: manager).contains("later"), what: "the second event");
      expect(_names(manager: manager), <String>["added", "later", "waiting"]);
    });
  });

  group("a directory that is not there yet", ()
  {
    testWidgets("is picked up once a view opens after it was created", (final WidgetTester tester) async
    {
      final AppPaths paths = createTestPaths();
      final String missing = p.join(paths.projectsDir, "not yet");
      paths.projectsDir = missing;
      await withProject(tester: tester, canvasSize: _canvasSize, appPaths: paths, body: (final ProjectSession projectSession) async
      {
        final ProjectManager manager = ProjectManager();
        GetIt.I.registerSingleton<ProjectManager>(manager);
        try
        {
          await manager.start();
          expect(manager.projects.value, isEmpty);
          expect(manager.indexState.value, ProjectIndexState.idle);
          //the watch fails asynchronously and leaves a timer-free fallback behind
          await Future<void>.delayed(const Duration(milliseconds: 100));

          Directory(missing).createSync();
          _project(name: "arrived").writeAsBytesSync(<int>[1]);
          manager.retain();

          await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the project");
          expect(_names(manager: manager), <String>["arrived"]);

          //the watch is back up, so changes arrive without another view opening
          _project(name: "next").writeAsBytesSync(<int>[1]);
          await _waitFor(condition: () => manager.projects.value.length == 2, what: "the next project");
          manager.release();
        }
        finally
        {
          manager.dispose();
        }
      },);
    }, timeout: const Timeout(Duration(minutes: 2)),);
  });

  group("the end of the manager", ()
  {
    _watchTest("nothing is listed after dispose and a new event changes nothing", (final ProjectManager manager) async
    {
      _project(name: "first").writeAsBytesSync(<int>[1]);
      await _waitFor(condition: () => manager.projects.value.isNotEmpty, what: "the project");
      final List<ProjectManagerEntryData> before = manager.projects.value;

      manager.dispose();
      _project(name: "second").writeAsBytesSync(<int>[1]);
      await manager.reindex();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(manager.projects.value, same(before));
    });

    _watchTest("releasing the selection with the last view", (final ProjectManager manager) async
    {
      manager.retain();
      manager.retain();
      manager.selectedPath.value = "something";

      manager.release();
      expect(manager.selectedPath.value, "something", reason: "a view is still open");

      manager.release();
      expect(manager.selectedPath.value, isNull);

      manager.release();
      expect(manager.selectedPath.value, isNull, reason: "one release too many is harmless");
    });
  });
}
