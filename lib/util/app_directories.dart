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

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/platform_helper.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> findExportDir() async
{
  if (!kIsWeb)
  {
    if (isDesktop() || Platform.isIOS)
    {
      final Directory? downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) 
      {
        return downloadDir.path;
      }
    } 
    else if (Platform.isAndroid)
    {
      final Directory directoryDL = Directory("/storage/emulated/0/Download/");
      final Directory directoryDLs = Directory("/storage/emulated/0/Downloads/");
      if (await directoryDL.exists())
      {
        return directoryDL.path;
      } 
      else if (await directoryDLs.exists())
      {
        return directoryDLs.path;
      }
      else
      {
        final Directory? directory = await getExternalStorageDirectory();
        if (directory != null && await directory.exists()) {
          return directory.path;
        }
      }
    }
  }
  return "";
}

Future<String> findInternalDir() async
{
  if (kIsWeb)
  {
    return "";
  }

  final Directory internalDir = await getApplicationSupportDirectory();
  return internalDir.path;
}

String getDefaultProjectsDir({required final String internalDir})
{
  return p.join(internalDir, projectsSubDirName);
}

class ProjectDirectoryResolveResult
{
  final String resolvedDir;
  final bool useCustom;
  final bool customValid;
  ProjectDirectoryResolveResult({required this.resolvedDir, required this.useCustom, required this.customValid});
}

Future<ProjectDirectoryResolveResult> resolveProjectsDir({required final String internalDir}) async
{
  String dirToUse = getDefaultProjectsDir(internalDir: internalDir);
  bool customValid = false;
  bool useCustomDir = false;
  if (!kIsWeb)
  {
    useCustomDir = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.useCustomProjectDirectory.value;
    final String customDir = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.customProjectDirectory.value;

    if (customDir.isNotEmpty)
    {
      if (await Directory(customDir).exists() && hasWriteAccess(directory: customDir))
      {
        customValid = true;
      }
    }

    if (useCustomDir)
    {
      if (!customValid)
      {
        GetIt.I.get<Logger>().w("Custom project directory $customDir is not accessible, falling back to the default directory.",);
      }
      else
      {
        dirToUse = customDir;
      }
    }
  }
  return ProjectDirectoryResolveResult(resolvedDir: dirToUse, useCustom: useCustomDir, customValid: customValid);
}

Future<ProjectDirectoryMoveResult> moveProjectFiles({required final String sourceDir, required final String targetDir,}) async
{
  final Logger logger = GetIt.I.get<Logger>();
  logger.i("Moving project files from $sourceDir to $targetDir.");
  try
  {
    final Directory target = Directory(targetDir);
    if (!await target.exists())
    {
      try
      {
        await target.create(recursive: true);
      }
      catch (e, s)
      {
        logger.w(
          "Could not create target directory $targetDir.",
          error: e,
          stackTrace: s,
        );
        return ProjectDirectoryMoveResult(
          success: false,
          error: ProjectDirectoryMoveError.targetNotCreated,
        );
      }
    }
    if (!hasWriteAccess(directory: targetDir))
    {
      return ProjectDirectoryMoveResult(
        success: false,
        error: ProjectDirectoryMoveError.insufficientPermissions,
      );
    }

    final List<File> filesToMove = <File>[];
    int projectCount = 0;
    final Directory source = Directory(sourceDir);
    if (await source.exists())
    {
      await for (final FileSystemEntity entity in source.list(followLinks: false))
      {
        if (entity is File && entity.path.endsWith(".$fileExtensionKpix"))
        {
          filesToMove.add(entity);
          projectCount++;
          final String? pngPath = await replaceFileExtension(filePath: entity.path, newExtension: thumbnailExtension, inputFileMustExist: true,);
          if (pngPath != null) 
          {
            final File pngFile = File(pngPath);
            if (await pngFile.exists())
            {
              filesToMove.add(pngFile);
            }
          }
        }
      }
    }

    for (final File file in filesToMove)
    {
      final String targetPath = p.join(targetDir, p.basename(file.path));
      if (await File(targetPath).exists())
      {
        return ProjectDirectoryMoveResult(success: false, error: ProjectDirectoryMoveError.targetFileExists, fileName: p.basename(file.path),);
      }
    }

    final List<(String, String)> movedFiles = <(String, String)>[];
    for (final File file in filesToMove)
    {
      final String targetPath = p.join(targetDir, p.basename(file.path));
      try
      {
        await moveFile(sourceFile: file, targetPath: targetPath);
        movedFiles.add((file.path, targetPath));
      }
      catch (e, s)
      {
        logger.w(
          "Error moving ${file.path} to $targetPath, rolling back.",
          error: e,
          stackTrace: s,
        );
        for (final (String, String) movedFile in movedFiles)
        {
          try
          {
            await moveFile(
              sourceFile: File(movedFile.$2),
              targetPath: movedFile.$1,
            );
          }
          catch (e2, s2)
          {
            logger.e(
              "Rollback failed for ${movedFile.$2}.",
              error: e2,
              stackTrace: s2,
            );
          }
        }
        return ProjectDirectoryMoveResult(
          success: false,
          error: ProjectDirectoryMoveError.moveFailed,
          fileName: p.basename(file.path),
        );
      }
    }

    logger.i("Moved $projectCount project file(s) to $targetDir.");
    return ProjectDirectoryMoveResult(success: true, projectCount: projectCount,);
  }
  catch (e, s)
  {
    logger.w("Error moving project files.", error: e, stackTrace: s);
    return ProjectDirectoryMoveResult(success: false, error: ProjectDirectoryMoveError.unexpected,);
  }
}

Future<void> createInternalDirectories() async
{
  final String internalDir = GetIt.I.get<AppPaths>().internalDir;
  final List<Directory> internalDirectories = <Directory>[
    Directory(p.join(internalDir, palettesSubDirName)),
    Directory(p.join(internalDir, projectsSubDirName)),
    Directory(p.join(internalDir, recoverSubDirName)),
    Directory(p.join(internalDir, stampsSubDirName)),
  ];

  for (final Directory dir in internalDirectories)
  {
    final bool dirExists = await dir.exists();
    if (!dirExists)
    {
      await dir.create();
    }
  }
}

Future<void> clearRecoverDir() async
{
  if (!kIsWeb)
  {
    final Logger logger = GetIt.I.get<Logger>();
    try
    {
      final Directory recoverDir = Directory(
        p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName),
      );
      final List<FileSystemEntity> files = await recoverDir.list().toList();
      for (final FileSystemEntity file in files)
      {
        await file.delete(recursive: true);
      }
    }
    catch (e, s)
    {
      logger.w("Error clearing recovery directory.", error: e, stackTrace: s);
    }
  }
}

Future<String?> getRecoveryFile() async
{
  final Logger logger = GetIt.I.get<Logger>();
  try
  {
    final Directory recoverDir = Directory(
      p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName),
    );
    final List<FileSystemEntity> files = await recoverDir.list().toList();
    if (files.length == 1) {
      logger.i("Found recovery file ${files[0].path}.");
      return files[0].path;
    }
  }
  catch (e, s)
  {
    logger.w("Error getting recovery file.", error: e, stackTrace: s);
  }
  return null;
}
