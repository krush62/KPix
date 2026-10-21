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
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/selection_harness.dart';

/// What [saveFilePressed] reported back.
class _SaveReport
{
  int finished = 0;
  int saved = 0;
  int failed = 0;
}

Future<_SaveReport> _save({required final String fileName}) async
{
  final _SaveReport report = _SaveReport();
  await saveFilePressed(
    fileName: fileName,
    finishCallback: () {report.finished++;},
    savedCallback: (final String _) {report.saved++;},
    failedCallback: () {report.failed++;},
  );
  return report;
}

void main()
{
  late Directory projectsDir;

  setUp(() async
  {
    projectsDir = await Directory.systemTemp.createTemp("kpix_save_test");
  });

  tearDown(() async
  {
    try
    {
      await projectsDir.delete(recursive: true);
    }
    catch (_)
    {
      //a left over temp directory is not worth failing the test over
    }
  });

  testWidgets("a failed save reports only the failure and keeps the changes", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 4), body: (final ProjectSession projectSession) async
    {
      GetIt.I.get<AppPaths>().projectsDir = projectsDir.path;
      //a directory in place of the file makes the write fail on every platform
      await Directory(p.join(projectsDir.path, "blocked.$fileExtensionKpix")).create();
      projectSession.hasChanges.value = true;

      final _SaveReport report = await _save(fileName: "blocked");

      expect(report.failed, 1);
      expect(report.finished, 0, reason: "whatever waits for the save (exit, new project, load, import) must not go ahead");
      expect(report.saved, 0);
      expect(projectSession.hasChanges.value, isTrue, reason: "the changes were not saved, so they are still unsaved");
    },);
  });

  testWidgets("a successful save reports the save and then the finish", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 4), body: (final ProjectSession projectSession) async
    {
      GetIt.I.get<AppPaths>().projectsDir = projectsDir.path;
      projectSession.hasChanges.value = true;

      final _SaveReport report = await _save(fileName: "fine");

      expect(report.failed, 0);
      expect(report.saved, 1);
      expect(report.finished, 1);
      expect(projectSession.hasChanges.value, isFalse);
      expect(File(p.join(projectsDir.path, "fine.$fileExtensionKpix")).existsSync(), isTrue);
    },);
  });
}
