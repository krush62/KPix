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

import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:path/path.dart' as p;

/// Reads what is on disk in the projects directory.
///
/// Kept beside [ProjectManager], its only caller, rather than in the file layer:
/// a service that scans a directory has to sit above the file helpers, not
/// below them.
/// Collects the file system state of every project in [dir].
///
/// This only stats files, so it holds no `dart:ui` handles and reaches nothing
/// in the service locator: [ProjectManager] runs it on a background isolate.
/// It does not log for the same reason, and lets errors surface to the caller.
Future<List<ProjectFileStat>> scanProjectDirectory({required final String dir}) async
{
  final List<ProjectFileStat> stats = <ProjectFileStat>[];
  final Directory directory = Directory(dir);
  if (!await directory.exists())
  {
    return stats;
  }

  await for (final FileSystemEntity entity in directory.list(followLinks: false))
  {
    if (entity is! File || p.extension(entity.path).toLowerCase() != ".$fileExtensionKpix")
    {
      continue;
    }
    final String kpixPath = entity.absolute.path;
    //FileStat.stat never throws, it reports a missing file as a not found type,
    //which is what a file deleted between listing and stating looks like here
    final FileStat kpixStat = await FileStat.stat(kpixPath);
    if (kpixStat.type != FileSystemEntityType.file)
    {
      continue;
    }
    final String thumbnailPath = p.setExtension(kpixPath, ".$thumbnailExtension");
    final FileStat thumbnailStat = await FileStat.stat(thumbnailPath);
    final bool hasThumbnail = thumbnailStat.type == FileSystemEntityType.file;
    stats.add(
      ProjectFileStat(
        kpixPath: kpixPath,
        lastModified: kpixStat.modified,
        thumbnailPath: thumbnailPath,
        thumbnailModified: hasThumbnail ? thumbnailStat.modified : null,
        thumbnailSize: hasThumbnail ? thumbnailStat.size : null,
      ),
    );
  }
  return stats;
}

/// Collects the file system state of the single project at [kpixPath].
///
/// Returns null when the project file is gone, which is how [ProjectManager]
/// detects a deletion.
Future<ProjectFileStat?> statProjectFile({required final String kpixPath}) async
{
  final FileStat kpixStat = await FileStat.stat(kpixPath);
  if (kpixStat.type != FileSystemEntityType.file)
  {
    return null;
  }
  final String thumbnailPath = p.setExtension(kpixPath, ".$thumbnailExtension");
  final FileStat thumbnailStat = await FileStat.stat(thumbnailPath);
  final bool hasThumbnail = thumbnailStat.type == FileSystemEntityType.file;
  return ProjectFileStat(
    kpixPath: kpixPath,
    lastModified: kpixStat.modified,
    thumbnailPath: thumbnailPath,
    thumbnailModified: hasThumbnail ? thumbnailStat.modified : null,
    thumbnailSize: hasThumbnail ? thumbnailStat.size : null,
  );
}
