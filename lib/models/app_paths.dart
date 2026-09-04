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

import 'package:flutter/foundation.dart';

/// The directories the application reads from and writes to.
///
/// Resolved once at start up. [exportDir] follows the last directory the user
/// picked in the export dialog, and [projectsDir] can be pointed elsewhere from
/// the behavior preferences, so both are observable.
class AppPaths
{
  final ValueNotifier<String> _exportDir;
  String get exportDir
  {
    return _exportDir.value;
  }
  ValueNotifier<String> get exportDirNotifier
  {
    return _exportDir;
  }
  set exportDir(final String dir)
  {
    _exportDir.value = dir;
  }

  final ValueNotifier<String> _internalDir;
  String get internalDir
  {
    return _internalDir.value;
  }
  ValueNotifier<String> get internalDirNotifier
  {
    return _internalDir;
  }
  set internalDir(final String dir)
  {
    _internalDir.value = dir;
  }

  final ValueNotifier<String> _projectsDir;
  String get projectsDir
  {
    return _projectsDir.value;
  }
  ValueNotifier<String> get projectsDirNotifier
  {
    return _projectsDir;
  }
  set projectsDir(final String dir)
  {
    _projectsDir.value = dir;
  }

  AppPaths({required final String exportDir, required final String internalDir, required final String projectsDir}) : _exportDir = ValueNotifier<String>(exportDir), _internalDir = ValueNotifier<String>(internalDir), _projectsDir = ValueNotifier<String>(projectsDir);
}
