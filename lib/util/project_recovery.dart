/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

/// A project to open: recovered at start up or requested from outside.
/// [importResult] is null when nothing was imported: for a recovery file or a
/// project of the projects directory. [requestedPath] is the file asked for.
class InitialProject
{
  final String? path;
  final bool fromRecovery;
  final ProjectImportResult? importResult;
  final String? requestedPath;

  const InitialProject({required this.path, required this.fromRecovery, this.importResult, this.requestedPath});
}

/// The unsaved work a session left behind in the recovery directory, if any.
Future<InitialProject?> findRecoveredProject() async
{
  final String? recoveryFile = await getRecoveryFile();
  return recoveryFile == null ? null : InitialProject(path: recoveryFile, fromRecovery: true);
}

/// Imports [path] into the projects directory and points at the project there.
/// A taken name is reported as [ProjectImportResult.projectAlreadyExists],
/// pointing at the existing project, unless [asCopy] imports the file under
/// the first free `_n` name. Recovery files are not looked at.
Future<InitialProject> importRequestedProject({required final String? path, final bool asCopy = false}) async
{
  final String projectsDir = GetIt.I.get<AppPaths>().projectsDir;
  final File expectedFile = File(p.join(projectsDir, extractFilenameFromPath(path: path)));
  //importing a project of the projects directory would only report it as a duplicate
  if (path != null && path.endsWith(fileExtensionKpix) && p.equals(path, expectedFile.path))
  {
    return InitialProject(path: await expectedFile.exists() ? expectedFile.path : null, fromRecovery: false, requestedPath: path);
  }
  final String? copyName = asCopy && path != null ? await _freeProjectFileName(path: path) : null;
  final ProjectImportResult importResult = await importProject(path: path, targetFileName: copyName);
  final String? projectPath = switch (importResult)
  {
    ProjectImportResult.success => p.join(projectsDir, copyName ?? extractFilenameFromPath(path: path)),
    ProjectImportResult.projectAlreadyExists => expectedFile.path,
    _ => null,
  };
  return InitialProject(path: projectPath, fromRecovery: false, importResult: importResult, requestedPath: path);
}

/// The file name of [path] with the first `_n` suffix free in the projects directory.
Future<String> _freeProjectFileName({required final String path}) async
{
  final String baseName = extractFilenameFromPath(path: path, keepExtension: false);
  for (int i = 1; ; i++)
  {
    final String candidate = "${baseName}_$i.$fileExtensionKpix";
    if (!await File(p.join(GetIt.I.get<AppPaths>().projectsDir, candidate)).exists())
    {
      return candidate;
    }
  }
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
