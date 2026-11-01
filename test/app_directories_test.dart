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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/selection_harness.dart';

void _test(final String description, final Future<void> Function(Directory temp) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 2, y: 2), body: (final ProjectSession projectSession) async
    {
      final Directory temp = await Directory.systemTemp.createTemp("kpix_directories_test");
      try
      {
        await body(temp);
      }
      finally
      {
        await temp.delete(recursive: true);
      }
    },);
  });
}

void _setCustomDirectory({required final bool use, required final String path})
{
  final PreferenceManager preferences = GetIt.I.get<PreferenceManager>();
  preferences.behaviorPreferenceContent.useCustomProjectDirectory.value = use;
  preferences.behaviorPreferenceContent.customProjectDirectory.value = path;
}

void main()
{
  group("the projects directory", ()
  {
    _test("sits inside the internal directory by default", (final Directory temp) async
    {
      expect(getDefaultProjectsDir(internalDir: temp.path), p.join(temp.path, projectsSubDirName));

      final ProjectDirectoryResolveResult result = await resolveProjectsDir(internalDir: temp.path);

      expect(result.resolvedDir, p.join(temp.path, projectsSubDirName));
      expect(result.useCustom, isFalse);
      expect(result.customValid, isFalse);
    });

    _test("is the custom one if asked for", (final Directory temp) async
    {
      final Directory custom = await Directory(p.join(temp.path, "custom")).create();
      _setCustomDirectory(use: true, path: custom.path);

      final ProjectDirectoryResolveResult result = await resolveProjectsDir(internalDir: temp.path);

      expect(result.resolvedDir, custom.path);
      expect(result.useCustom, isTrue);
      expect(result.customValid, isTrue);
    });

    _test("falls back to the default if the custom one is gone", (final Directory temp) async
    {
      _setCustomDirectory(use: true, path: p.join(temp.path, "gone"));

      final ProjectDirectoryResolveResult result = await resolveProjectsDir(internalDir: temp.path);

      expect(result.resolvedDir, p.join(temp.path, projectsSubDirName));
      expect(result.useCustom, isTrue);
      expect(result.customValid, isFalse);
    });

    _test("falls back to the default if none was given", (final Directory temp) async
    {
      _setCustomDirectory(use: true, path: "");

      final ProjectDirectoryResolveResult result = await resolveProjectsDir(internalDir: temp.path);

      expect(result.resolvedDir, p.join(temp.path, projectsSubDirName));
      expect(result.customValid, isFalse);
    });

    _test("still checks a custom one that is not in use", (final Directory temp) async
    {
      final Directory custom = await Directory(p.join(temp.path, "custom")).create();
      _setCustomDirectory(use: false, path: custom.path);

      final ProjectDirectoryResolveResult result = await resolveProjectsDir(internalDir: temp.path);

      expect(result.resolvedDir, p.join(temp.path, projectsSubDirName));
      expect(result.useCustom, isFalse);
      expect(result.customValid, isTrue);
    });
  });

  group("moving project files", ()
  {
    _test("puts everything back when one of them cannot be moved", (final Directory temp) async
    {
      final Directory source = await Directory(p.join(temp.path, "source")).create();
      final Directory target = await Directory(p.join(temp.path, "target")).create();
      await File(p.join(source.path, "a.$fileExtensionKpix")).writeAsString("a");
      await File(p.join(source.path, "b.$fileExtensionKpix")).writeAsString("b");
      await File(p.join(source.path, "a.$thumbnailExtension")).writeAsString("thumb");
      //not a file, so the check for colliding files does not see it
      await Directory(p.join(target.path, "b.$fileExtensionKpix")).create();

      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: source.path, targetDir: target.path);

      expect(result.success, isFalse);
      expect(result.error, ProjectDirectoryMoveError.moveFailed);
      expect(result.fileName, "b.$fileExtensionKpix");
      expect(await File(p.join(source.path, "a.$fileExtensionKpix")).readAsString(), "a");
      expect(await File(p.join(source.path, "b.$fileExtensionKpix")).readAsString(), "b");
      expect(await File(p.join(source.path, "a.$thumbnailExtension")).readAsString(), "thumb");
      expect(await File(p.join(target.path, "a.$fileExtensionKpix")).exists(), isFalse);
      expect(await File(p.join(target.path, "a.$thumbnailExtension")).exists(), isFalse);
    });
  });

  group("the internal directory", ()
  {
    testWidgets("comes from the platform", (final WidgetTester tester) async
    {
      const MethodChannel channel = MethodChannel("plugins.flutter.io/path_provider");
      final TestDefaultBinaryMessenger messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (final MethodCall call) async
      {
        return call.method == "getApplicationSupportDirectory" ? "support dir" : null;
      });
      addTearDown(() {messenger.setMockMethodCallHandler(channel, null);});

      expect(await findInternalDir(), "support dir");
    });
  });
}
