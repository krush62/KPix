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

import 'dart:ui' as ui;

/// What the file system knows about a single project file and its thumbnail.
///
/// This holds plain data only: no `dart:ui` handles and nothing that reaches the
/// service locator, so it can be produced on a background isolate and sent back
/// to the UI isolate. It carries everything the project cache needs to decide
/// whether a project has to be read from disk again.
class ProjectFileStat
{
  final String kpixPath;
  final DateTime lastModified;
  final String thumbnailPath;
  final DateTime? thumbnailModified;
  final int? thumbnailSize;

  const ProjectFileStat({
    required this.kpixPath,
    required this.lastModified,
    required this.thumbnailPath,
    required this.thumbnailModified,
    required this.thumbnailSize,
  });

  /// Whether [other] describes the same files in the same state as this stat.
  ///
  /// The thumbnail size takes part in the comparison because a sync tool can
  /// replace a file without the modification time moving forward.
  bool matches({required final ProjectFileStat other})
  {
    return kpixPath == other.kpixPath &&
        lastModified == other.lastModified &&
        thumbnailPath == other.thumbnailPath &&
        thumbnailModified == other.thumbnailModified &&
        thumbnailSize == other.thumbnailSize;
  }

  /// Whether a thumbnail file was present when this stat was taken.
  bool get hasThumbnailFile
  {
    return thumbnailModified != null;
  }
}

/// Data structure for a KPix project file.
class ProjectManagerEntryData
{
  final ui.Image? thumbnail;
  final String path;
  final String name;
  final DateTime dateTime;

  /// The file system state this entry was built from.
  ///
  /// The project cache compares it against a fresh scan to tell whether the
  /// decoded [thumbnail] may be reused.
  final ProjectFileStat stat;

  ProjectManagerEntryData({required this.dateTime, required this.path, required this.thumbnail, required this.name, required this.stat});

  /// Whether this entry still describes [other] and its [thumbnail] may be kept.
  ///
  /// An entry that has no decoded thumbnail while a thumbnail file exists is not
  /// reusable: the last decode ran into a half written file, and retrying is what
  /// lets such an entry heal on a later scan instead of staying blank forever.
  bool canReuseFor({required final ProjectFileStat other})
  {
    return stat.matches(other: other) && (thumbnail != null || !other.hasThumbnailFile);
  }
}
