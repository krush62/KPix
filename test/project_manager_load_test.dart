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
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
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
  required final LoadProjectFn onLoad,
  required final LoadProjectFn onSaveAndLoad,
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
            dismiss: () {},
            loadProject: onLoad,
            saveAndLoadProject: onSaveAndLoad,
          ),
        ),
      ),
    ),
  );
}

/// Lists the fixture in a fresh project directory, mounts the manager and
/// selects the fixture; returns the directory for the tear down.
Future<Directory> _setUpAndSelect(
  final WidgetTester tester, {
  required final LoadProjectFn onLoad,
  required final LoadProjectFn onSaveAndLoad,
}) async
{
  late final Directory projectsDir;
  //the scan reads a real directory, so it has to run outside the fake clock
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4));
    projectsDir = await Directory.systemTemp.createTemp("kpix_manager_test");
    await File(_fixture).copy(p.join(projectsDir.path, "fixture.kpix"));
    GetIt.I.get<AppPaths>().projectsDir = projectsDir.path;
    final ProjectManager projectManager = ProjectManager();
    GetIt.I.registerSingleton<ProjectManager>(projectManager);
    await projectManager.start();
  });

  await _pumpManager(tester, onLoad: onLoad, onSaveAndLoad: onSaveAndLoad);
  //the dialog ignores pointers while it fades in
  await tester.pump(const Duration(milliseconds: 300));

  expect(find.text("fixture"), findsOneWidget, reason: "setup: the copied project is listed");
  await tester.tap(find.text("fixture"));
  await tester.pump();
  expect(GetIt.I.get<ProjectManager>().selectedPath.value, isNotNull, reason: "setup: tapping an entry selects it");
  return projectsDir;
}

Future<void> _tearDown(final WidgetTester tester, {required final Directory projectsDir}) async
{
  await tester.runAsync(() async {
    GetIt.I.get<ProjectManager>().dispose();
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
}

void main()
{
  testWidgets("loading a project without unsaved changes hands the selected path to the owner", (final WidgetTester tester) async
  {
    final List<String> loaded = <String>[];
    final List<String> savedAndLoaded = <String>[];
    final Directory projectsDir = await _setUpAndSelect(
      tester,
      onLoad: ({required final String path}) {loaded.add(path);},
      onSaveAndLoad: ({required final String path}) {savedAndLoaded.add(path);},
    );
    final String selected = GetIt.I.get<ProjectManager>().selectedPath.value!;

    //the booted project has no unsaved changes, so the load runs without the
    //save warning ever being shown
    await tester.tap(find.widgetWithIcon(IconButton, TablerIcons.check));
    await tester.pump();

    expect(loaded, <String>[selected], reason: "the owner has to be asked to load the selected project");
    expect(savedAndLoaded, isEmpty, reason: "nothing was unsaved, so nothing should be saved first");

    await _tearDown(tester, projectsDir: projectsDir);
  }, timeout: const Timeout(Duration(seconds: 90)),);

  testWidgets("answering yes to the save warning hands the selected path on before saving can close the manager", (final WidgetTester tester) async
  {
    final List<String> loaded = <String>[];
    final List<String> savedAndLoaded = <String>[];
    final Directory projectsDir = await _setUpAndSelect(
      tester,
      onLoad: ({required final String path}) {loaded.add(path);},
      onSaveAndLoad: ({required final String path}) {savedAndLoaded.add(path);},
    );
    final String selected = GetIt.I.get<ProjectManager>().selectedPath.value!;
    GetIt.I.get<ProjectSession>().hasChanges.value = true;

    await tester.tap(find.widgetWithIcon(IconButton, TablerIcons.check));
    //the warning ignores pointers while it fades in
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip("Yes"));
    await tester.pump();

    //saving closes the manager, which clears the selection; the path has to be
    //taken before that, or the project is saved and the new one never opened
    expect(savedAndLoaded, <String>[selected], reason: "the owner has to save and then load the selected project");
    expect(loaded, isEmpty, reason: "loading without saving would drop the unsaved changes");

    await _tearDown(tester, projectsDir: projectsDir);
  }, timeout: const Timeout(Duration(seconds: 90)),);
}
