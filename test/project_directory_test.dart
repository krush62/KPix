/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

void main() {
  setUpAll(() {
    if (!GetIt.I.isRegistered<Logger>()) {
      GetIt.I.registerSingleton<Logger>(Logger(level: Level.off));
    }
  });

  testMoveProjectFiles();
}

Future<void> _createFile({required final String path, final String content = "kpix"}) async {
  await File(path).writeAsString(content);
}

void testMoveProjectFiles() {
  group('moveProjectFiles', () {
    late Directory tempDir;
    late String sourceDir;
    late String targetDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("kpix_move_test");
      sourceDir = p.join(tempDir.path, "source");
      targetDir = p.join(tempDir.path, "target");
      await Directory(sourceDir).create();
      await Directory(targetDir).create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('moves project files and thumbnails, leaves unrelated files', () async {
      await _createFile(path: p.join(sourceDir, "a.$fileExtensionKpix"));
      await _createFile(path: p.join(sourceDir, "a.$thumbnailExtension"));
      await _createFile(path: p.join(sourceDir, "b.$fileExtensionKpix"));
      await _createFile(path: p.join(sourceDir, "unrelated.txt"));
      await _createFile(path: p.join(sourceDir, "unrelated.$thumbnailExtension"));

      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: sourceDir, targetDir: targetDir);

      expect(result.success, isTrue);
      expect(result.projectCount, 2);
      expect(File(p.join(targetDir, "a.$fileExtensionKpix")).existsSync(), isTrue);
      expect(File(p.join(targetDir, "a.$thumbnailExtension")).existsSync(), isTrue);
      expect(File(p.join(targetDir, "b.$fileExtensionKpix")).existsSync(), isTrue);
      expect(File(p.join(sourceDir, "a.$fileExtensionKpix")).existsSync(), isFalse);
      expect(File(p.join(sourceDir, "a.$thumbnailExtension")).existsSync(), isFalse);
      expect(File(p.join(sourceDir, "b.$fileExtensionKpix")).existsSync(), isFalse);
      expect(File(p.join(sourceDir, "unrelated.txt")).existsSync(), isTrue);
      expect(File(p.join(sourceDir, "unrelated.$thumbnailExtension")).existsSync(), isTrue);
    });

    test('succeeds with empty source directory', () async {
      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: sourceDir, targetDir: targetDir);
      expect(result.success, isTrue);
      expect(result.projectCount, 0);
    });

    test('succeeds when source directory does not exist', () async {
      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: p.join(tempDir.path, "does_not_exist"), targetDir: targetDir);
      expect(result.success, isTrue);
      expect(result.projectCount, 0);
    });

    test('creates target directory if it does not exist', () async {
      await _createFile(path: p.join(sourceDir, "a.$fileExtensionKpix"));
      final String newTarget = p.join(tempDir.path, "new_target");

      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: sourceDir, targetDir: newTarget);

      expect(result.success, isTrue);
      expect(File(p.join(newTarget, "a.$fileExtensionKpix")).existsSync(), isTrue);
    });

    test('fails on name collision and does not move any files', () async {
      await _createFile(path: p.join(sourceDir, "a.$fileExtensionKpix"));
      await _createFile(path: p.join(sourceDir, "b.$fileExtensionKpix"));
      await _createFile(path: p.join(targetDir, "b.$fileExtensionKpix"), content: "existing");

      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: sourceDir, targetDir: targetDir);

      expect(result.success, isFalse);
      expect(File(p.join(sourceDir, "a.$fileExtensionKpix")).existsSync(), isTrue);
      expect(File(p.join(sourceDir, "b.$fileExtensionKpix")).existsSync(), isTrue);
      expect(await File(p.join(targetDir, "b.$fileExtensionKpix")).readAsString(), "existing");
    });

    test('fails when target directory cannot be created', () async {
      await _createFile(path: p.join(sourceDir, "a.$fileExtensionKpix"));
      final String blockedTarget = p.join(tempDir.path, "blocked");
      await _createFile(path: blockedTarget);

      final ProjectDirectoryMoveResult result = await moveProjectFiles(sourceDir: sourceDir, targetDir: blockedTarget);

      expect(result.success, isFalse);
      expect(File(p.join(sourceDir, "a.$fileExtensionKpix")).existsSync(), isTrue);
    });
  });
}
