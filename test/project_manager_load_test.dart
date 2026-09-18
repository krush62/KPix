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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart' as flutter_localizations;
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/file/project_manager_widget.dart';
import 'package:path/path.dart' as p;
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

/// A project written by an older version; any valid file does here, the test is
/// only interested in what the manager does around the load.
const String _fixture = "test/assets/pre_grid_v4.kpix";

/// Mounts [ProjectManagerWidget] the way the overlay does, with the
/// localizations it reads while building.
Future<void> _pumpManager(
  final WidgetTester tester, {
  required final Function() onDismiss,
  required final Function() onFileLoad,
}) async
{
  await tester.pumpWidget(
    ToastificationWrapper(
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...flutter_localizations.GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectManagerWidget(
            dismiss: onDismiss,
            fileLoad: onFileLoad,
            saveKnownFileFn: ({final Function()? callback}) {},
          ),
        ),
      ),
    ),
  );
}

void main()
{
  testWidgets("loading a project without unsaved changes reports the load and dismisses the manager", (final WidgetTester tester) async
  {
    late final Directory projectsDir;
    late final ProjectManager projectManager;
    int dismissCount = 0;
    int loadCount = 0;

    //the scan reads a real directory, so it has to run outside the fake clock
    await tester.runAsync(() async {
      await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4));
      projectsDir = await Directory.systemTemp.createTemp("kpix_manager_test");
      await File(_fixture).copy(p.join(projectsDir.path, "fixture.kpix"));
      GetIt.I.get<AppPaths>().projectsDir = projectsDir.path;
      projectManager = ProjectManager();
      GetIt.I.registerSingleton<ProjectManager>(projectManager);
      await projectManager.start();
    });

    await _pumpManager(tester, onDismiss: () {dismissCount++;}, onFileLoad: () {loadCount++;});
    //the dialog ignores pointers while it fades in
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("fixture"), findsOneWidget, reason: "setup: the copied project is listed");
    await tester.tap(find.text("fixture"));
    await tester.pump();
    expect(projectManager.selectedPath.value, isNotNull, reason: "setup: tapping an entry selects it");

    //the booted project has no unsaved changes, so the load runs without the
    //save warning ever being shown
    await tester.tap(find.widgetWithIcon(IconButton, TablerIcons.check));
    await tester.pump();

    expect(loadCount, 1, reason: "the manager has to report the load, otherwise the caller never learns about it");
    expect(dismissCount, 1, reason: "the manager has to dismiss itself, otherwise it stays on screen above the project");

    //let the load that was kicked off run to its end before the tear down
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
      projectManager.dispose();
      //the directory watch can still hold the directory for a moment on Windows
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try
      {
        await projectsDir.delete(recursive: true);
      }
      catch (_)
      {
        //a left over temp directory is not worth failing the test over
      }
    });
    await tester.pump();
  }, timeout: const Timeout(Duration(seconds: 90)),);
}
