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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;


Future<bool> deleteFile({required final String path}) async {
  final File file = File(path);
  if (await file.exists()) {
    await file.delete();
  } else {
    return false;
  }
  return true;
}

bool hasWriteAccess({required final String directory}) {
  try {
    final File tempFile = File(
      '$directory${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}.tmp',);
    tempFile.createSync();
    tempFile.deleteSync();
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> moveFile(
    {required final File sourceFile, required final String targetPath,}) async {
  try {
    await sourceFile.rename(targetPath);
  } on FileSystemException {
    //rename does not work across file systems -> copy and delete
    await sourceFile.copy(targetPath);
    await sourceFile.delete();
  }
}

Future<bool> hasAllFilesAccess() async
{
  if (kIsWeb || !Platform.isAndroid)
  {
    return true;
  }
  try
  {
    const MethodChannel channel = MethodChannel('app.channel.shared.data');
    final bool? result = await channel.invokeMethod<bool>('hasAllFilesAccess');
    return result ?? false;
  }
  on PlatformException
  {
    return false;
  }
}

Future<void> openAllFilesAccessSettings() async
{
  if (!kIsWeb && Platform.isAndroid)
  {
    try
    {
      const MethodChannel channel = MethodChannel('app.channel.shared.data');
      await channel.invokeMethod<bool>('openAllFilesAccessSettings');
    }
    on PlatformException
    {
      //the settings page could not be opened, nothing to do here
    }
  }
}

String extractFilenameFromPath({required final String? path, final bool keepExtension = true})
{
  if (path != null && path.isNotEmpty)
  {
    return keepExtension ? p.basename(path) : p.basenameWithoutExtension(path);
  }
  else
  {
    return "";
  }
}

String getBaseDir({required final String fullPath})
{
  return p.dirname(fullPath);
}

Future<String?> replaceFileExtension({required final String filePath, required final String newExtension, required final bool inputFileMustExist}) async
{
  if ((!await File(filePath).exists()) && inputFileMustExist)
  {
    return null;
  }

  final String currentExtension = p.extension(filePath);
  if (currentExtension.isEmpty)
  {
    return null;
  }
  return filePath.replaceAll(RegExp(r'\.[^.]+$'), '.$newExtension');
}
