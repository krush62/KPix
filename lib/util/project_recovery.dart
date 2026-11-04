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

import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/import/import_kpix.dart';
import 'package:path/path.dart' as p;

/// Keeps the recovery directory in line with the unsaved work of the project.
class ProjectRecovery
{
  HistoryState? _lastWrittenState;

  /// Writes the project once per history state while it has unsaved changes and
  /// empties the directory when it has none. [mayWrite] holds back the write.
  Future<void> update({required final bool mayWrite}) async
  {
    final ProjectSession projectSession = GetIt.I.get<ProjectSession>();
    if (projectSession.hasProject && projectSession.hasChanges.value)
    {
      final HistoryState? currentState = GetIt.I.get<HistoryManager>().getCurrentState();
      if (mayWrite && currentState != _lastWrittenState)
      {
        _lastWrittenState = currentState;
        await clearRecoverDir();
        final String fileName = projectSession.projectName.value ?? recoverFileName;
        await saveKPixFile(path: p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName, "$fileName.$fileExtensionKpix"));
      }
    }
    else
    {
      //going back to the last written state later has to write it again
      _lastWrittenState = null;
      await clearRecoverDir();
    }
  }
}

/// The project to open at start up. [importResult] is null when nothing was
/// imported: for a recovery file or a project of the projects directory.
class InitialProject
{
  final String? path;
  final bool fromRecovery;
  final ProjectImportResult? importResult;

  const InitialProject({required this.path, required this.fromRecovery, this.importResult});
}

/// Finds the project to open at start up. A recovery file wins; otherwise the
/// file from [requestedPath], which is only asked for then, gets imported.
Future<InitialProject> findInitialProject({required final Future<String?> Function() requestedPath}) async
{
  final String? recoveryFile = await getRecoveryFile();
  if (recoveryFile != null)
  {
    return InitialProject(path: recoveryFile, fromRecovery: true);
  }

  return importRequestedProject(path: await requestedPath());
}

/// Imports [path] into the projects directory and points at the project there,
/// which may have existed before. Recovery files are not looked at.
Future<InitialProject> importRequestedProject({required final String? path}) async
{
  final File expectedFile = File(p.join(GetIt.I.get<AppPaths>().projectsDir, extractFilenameFromPath(path: path)));
  //importing a project of the projects directory would only report it as a duplicate
  final bool isProject = path != null && path.endsWith(fileExtensionKpix) && p.equals(path, expectedFile.path);
  final ProjectImportResult? importResult = isProject ? null : await importProject(path: path);
  return InitialProject(path: await expectedFile.exists() ? expectedFile.path : null, fromRecovery: false, importResult: importResult);
}

/// Loads [project] into the session; returns null if nothing was loaded.
Future<ProjectLoadResult?> openInitialProject({required final InitialProject project}) async
{
  final String? path = project.path;
  if (path == null || path.isEmpty)
  {
    return null;
  }

  final PreferenceManager preferenceManager = GetIt.I.get<PreferenceManager>();
  final LoadFileSet loadFileSet = await loadKPixFile(
    fileData: null,
    path: path,
    drawingLayerSettingsConstraints: preferenceManager.drawingLayerSettingsConstraints,
    shadingLayerSettingsConstraints: preferenceManager.shadingLayerSettingsConstraints,
    frameConstraints: preferenceManager.frameConstraints,
  );
  if (loadFileSet.path == null || loadFileSet.historyState == null)
  {
    return null;
  }
  return GetIt.I.get<ProjectSession>().restoreFromFile(loadFileSet: loadFileSet, setHasChanges: project.fromRecovery);
}
