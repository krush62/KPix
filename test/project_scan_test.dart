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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:path/path.dart' as p;

/// A valid one pixel PNG, used wherever a decodable thumbnail is needed.
const String _onePixelPngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testScanProjectDirectory();
  testStatProjectFile();
  testProjectFileStatMatches();
  testCanReuseFor();
  testLoadThumbnail();
}

Future<void> _createFile({required final String path, final String content = "kpix"}) async {
  await File(path).writeAsString(content);
}

Future<void> _createThumbnail({required final String path}) async {
  await File(path).writeAsBytes(base64Decode(_onePixelPngBase64));
}

ProjectFileStat _statFor({required final List<ProjectFileStat> stats, required final String path}) {
  return stats.firstWhere((final ProjectFileStat stat) => p.equals(stat.kpixPath, path));
}

void testScanProjectDirectory() {
  group('scanProjectDirectory', () {
    late Directory tempDir;
    late String projectDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("kpix_scan_test");
      projectDir = p.join(tempDir.path, "projects");
      await Directory(projectDir).create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('returns an empty list when the directory does not exist', () async {
      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: p.join(tempDir.path, "does_not_exist"));
      expect(stats, isEmpty);
    });

    test('returns an empty list for an empty directory', () async {
      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: projectDir);
      expect(stats, isEmpty);
    });

    test('picks up project files and ignores everything else', () async {
      await _createFile(path: p.join(projectDir, "a.$fileExtensionKpix"));
      await _createFile(path: p.join(projectDir, "b.$fileExtensionKpix"));
      await _createFile(path: p.join(projectDir, "notes.txt"));
      await _createFile(path: p.join(projectDir, "orphan.$thumbnailExtension"));
      await Directory(p.join(projectDir, "sub.$fileExtensionKpix")).create();

      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: projectDir);

      expect(stats.length, 2);
      expect(
        stats.map((final ProjectFileStat stat) => p.basename(stat.kpixPath)).toSet(),
        <String>{"a.$fileExtensionKpix", "b.$fileExtensionKpix"},
      );
    });

    test('reports a present thumbnail with its modification time and size', () async {
      final String kpixPath = p.join(projectDir, "a.$fileExtensionKpix");
      final String thumbnailPath = p.join(projectDir, "a.$thumbnailExtension");
      await _createFile(path: kpixPath);
      await _createThumbnail(path: thumbnailPath);

      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: projectDir);
      final ProjectFileStat stat = _statFor(stats: stats, path: kpixPath);

      expect(stat.hasThumbnailFile, isTrue);
      expect(p.equals(stat.thumbnailPath, thumbnailPath), isTrue);
      expect(stat.thumbnailSize, await File(thumbnailPath).length());
      expect(stat.thumbnailModified, isNotNull);
    });

    test('reports a missing thumbnail as absent', () async {
      final String kpixPath = p.join(projectDir, "a.$fileExtensionKpix");
      await _createFile(path: kpixPath);

      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: projectDir);
      final ProjectFileStat stat = _statFor(stats: stats, path: kpixPath);

      expect(stat.hasThumbnailFile, isFalse);
      expect(stat.thumbnailModified, isNull);
      expect(stat.thumbnailSize, isNull);
    });

    test('derives the thumbnail path from the last extension only', () async {
      final String kpixPath = p.join(projectDir, "my.project.v2.$fileExtensionKpix");
      await _createFile(path: kpixPath);

      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: projectDir);
      final ProjectFileStat stat = _statFor(stats: stats, path: kpixPath);

      expect(p.basename(stat.thumbnailPath), "my.project.v2.$thumbnailExtension");
    });

    test('reports absolute paths', () async {
      await _createFile(path: p.join(projectDir, "a.$fileExtensionKpix"));

      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: projectDir);

      expect(p.isAbsolute(stats.single.kpixPath), isTrue);
    });

    test('survives being run on a background isolate', () async {
      //this is how ProjectManager calls it, so the result has to be sendable and
      //the function must not reach for anything that only exists on the UI isolate
      await _createFile(path: p.join(projectDir, "a.$fileExtensionKpix"));
      await _createThumbnail(path: p.join(projectDir, "a.$thumbnailExtension"));
      final String dir = projectDir;

      final List<ProjectFileStat> stats = await runOffThread<List<ProjectFileStat>>(
        work: () => scanProjectDirectory(dir: dir),
        debugLabel: "scanProjectDirectoryTest",
      );

      expect(stats.length, 1);
      expect(stats.single.hasThumbnailFile, isTrue);
    });
  });
}

void testStatProjectFile() {
  group('statProjectFile', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("kpix_stat_test");
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('returns null for a file that does not exist', () async {
      final ProjectFileStat? stat = await statProjectFile(kpixPath: p.join(tempDir.path, "gone.$fileExtensionKpix"));
      expect(stat, isNull);
    });

    test('returns null for a directory', () async {
      final String path = p.join(tempDir.path, "a.$fileExtensionKpix");
      await Directory(path).create();
      final ProjectFileStat? stat = await statProjectFile(kpixPath: path);
      expect(stat, isNull);
    });

    test('describes an existing project and its thumbnail', () async {
      final String kpixPath = p.join(tempDir.path, "a.$fileExtensionKpix");
      final String thumbnailPath = p.join(tempDir.path, "a.$thumbnailExtension");
      await _createFile(path: kpixPath);
      await _createThumbnail(path: thumbnailPath);

      final ProjectFileStat? stat = await statProjectFile(kpixPath: kpixPath);

      expect(stat, isNotNull);
      expect(stat!.kpixPath, kpixPath);
      expect(stat.hasThumbnailFile, isTrue);
    });

    test('agrees with a directory scan of the same file', () async {
      final String kpixPath = p.join(tempDir.path, "a.$fileExtensionKpix");
      await _createFile(path: kpixPath);
      await _createThumbnail(path: p.join(tempDir.path, "a.$thumbnailExtension"));

      final List<ProjectFileStat> stats = await scanProjectDirectory(dir: tempDir.path);
      final ProjectFileStat? single = await statProjectFile(kpixPath: stats.single.kpixPath);

      expect(single, isNotNull);
      expect(single!.matches(other: stats.single), isTrue);
    });
  });
}

void testProjectFileStatMatches() {
  group('ProjectFileStat.matches', () {
    final DateTime modified = DateTime(2026, 8, 28, 12);
    final ProjectFileStat base = ProjectFileStat(
      kpixPath: p.join("dir", "a.$fileExtensionKpix"),
      lastModified: modified,
      thumbnailPath: p.join("dir", "a.$thumbnailExtension"),
      thumbnailModified: modified,
      thumbnailSize: 100,
    );

    test('matches an identical stat', () {
      expect(base.matches(other: base), isTrue);
    });

    test('does not match when the project was modified', () {
      final ProjectFileStat other = ProjectFileStat(
        kpixPath: base.kpixPath,
        lastModified: modified.add(const Duration(seconds: 1)),
        thumbnailPath: base.thumbnailPath,
        thumbnailModified: base.thumbnailModified,
        thumbnailSize: base.thumbnailSize,
      );
      expect(base.matches(other: other), isFalse);
    });

    test('does not match when only the thumbnail size changed', () {
      //a sync tool can replace a file without moving the modification time
      final ProjectFileStat other = ProjectFileStat(
        kpixPath: base.kpixPath,
        lastModified: base.lastModified,
        thumbnailPath: base.thumbnailPath,
        thumbnailModified: base.thumbnailModified,
        thumbnailSize: 101,
      );
      expect(base.matches(other: other), isFalse);
    });

    test('does not match when the thumbnail appeared', () {
      final ProjectFileStat without = ProjectFileStat(
        kpixPath: base.kpixPath,
        lastModified: base.lastModified,
        thumbnailPath: base.thumbnailPath,
        thumbnailModified: null,
        thumbnailSize: null,
      );
      expect(without.matches(other: base), isFalse);
      expect(without.hasThumbnailFile, isFalse);
    });
  });
}

void testCanReuseFor() {
  group('ProjectManagerEntryData.canReuseFor', () {
    late Directory tempDir;
    late ProjectFileStat statWithThumbnail;
    late ProjectFileStat statWithoutThumbnail;
    late ui.Image image;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("kpix_reuse_test");
      final String kpixPath = p.join(tempDir.path, "a.$fileExtensionKpix");
      final String thumbnailPath = p.join(tempDir.path, "a.$thumbnailExtension");
      await _createFile(path: kpixPath);
      await _createThumbnail(path: thumbnailPath);
      statWithThumbnail = (await statProjectFile(kpixPath: kpixPath))!;
      statWithoutThumbnail = ProjectFileStat(
        kpixPath: statWithThumbnail.kpixPath,
        lastModified: statWithThumbnail.lastModified,
        thumbnailPath: statWithThumbnail.thumbnailPath,
        thumbnailModified: null,
        thumbnailSize: null,
      );
      image = (await loadThumbnail(thumbnailPath: thumbnailPath))!;
    });

    tearDown(() async {
      image.dispose();
      await tempDir.delete(recursive: true);
    });

    ProjectManagerEntryData entryFor({required final ProjectFileStat stat, required final ui.Image? thumbnail}) {
      return ProjectManagerEntryData(
        dateTime: stat.lastModified,
        path: stat.kpixPath,
        thumbnail: thumbnail,
        name: "a",
        stat: stat,
      );
    }

    test('reuses an unchanged entry that has its thumbnail', () {
      final ProjectManagerEntryData entry = entryFor(stat: statWithThumbnail, thumbnail: image);
      expect(entry.canReuseFor(other: statWithThumbnail), isTrue);
    });

    test('reuses an unchanged entry when there is no thumbnail file at all', () {
      final ProjectManagerEntryData entry = entryFor(stat: statWithoutThumbnail, thumbnail: null);
      expect(entry.canReuseFor(other: statWithoutThumbnail), isTrue);
    });

    test('retries an entry whose thumbnail failed to decode', () {
      //the file is there but the entry has no image: the decode hit a half
      //written file, and without this the entry would stay blank forever
      final ProjectManagerEntryData entry = entryFor(stat: statWithThumbnail, thumbnail: null);
      expect(entry.canReuseFor(other: statWithThumbnail), isFalse);
    });

    test('does not reuse an entry when the file changed', () {
      final ProjectManagerEntryData entry = entryFor(stat: statWithThumbnail, thumbnail: image);
      final ProjectFileStat changed = ProjectFileStat(
        kpixPath: statWithThumbnail.kpixPath,
        lastModified: statWithThumbnail.lastModified.add(const Duration(seconds: 1)),
        thumbnailPath: statWithThumbnail.thumbnailPath,
        thumbnailModified: statWithThumbnail.thumbnailModified,
        thumbnailSize: statWithThumbnail.thumbnailSize,
      );
      expect(entry.canReuseFor(other: changed), isFalse);
    });

    test('does not reuse an entry when a thumbnail appeared', () {
      final ProjectManagerEntryData entry = entryFor(stat: statWithoutThumbnail, thumbnail: null);
      expect(entry.canReuseFor(other: statWithThumbnail), isFalse);
    });
  });
}

void testLoadThumbnail() {
  group('loadThumbnail', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("kpix_thumb_test");
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('decodes a valid png', () async {
      final String path = p.join(tempDir.path, "a.$thumbnailExtension");
      await _createThumbnail(path: path);

      final ui.Image? image = await loadThumbnail(thumbnailPath: path);

      expect(image, isNotNull);
      expect(image!.width, 1);
      expect(image.height, 1);
      image.dispose();
    });

    test('returns null for a missing file', () async {
      final ui.Image? image = await loadThumbnail(thumbnailPath: p.join(tempDir.path, "gone.$thumbnailExtension"));
      expect(image, isNull);
    });

    test('returns null for a half written file instead of throwing', () async {
      final String path = p.join(tempDir.path, "torn.$thumbnailExtension");
      //the first bytes of a png, as a sync tool would leave them behind mid write
      final Uint8List complete = base64Decode(_onePixelPngBase64);
      await File(path).writeAsBytes(complete.sublist(0, complete.length ~/ 2));

      final ui.Image? image = await loadThumbnail(thumbnailPath: path);

      expect(image, isNull);
    });
  });
}
