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


import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/util/helpers/platform_helper.dart';

/// The path of a picked file; on web there is only its name.
String pickedFilePath({required final PlatformFile file})
{
  return !kIsWeb && file.path != null ? file.path! : file.name;
}

Future<String?> _pickFile({required final String extension}) async
{
  final String exportDir = GetIt.I.get<AppPaths>().exportDir;
  final PlatformFile? file = isDesktop(includingWeb: true)
      ? await FilePicker.pickFile(type: FileType.custom, allowedExtensions: <String>[extension], initialDirectory: exportDir,)
      : await FilePicker.pickFile(initialDirectory: exportDir,);
  return file != null ? pickedFilePath(file: file) : null;
}

Future<String?> getPathForKPixFile() async
{
  return _pickFile(extension: fileExtensionKpix);
}

Future<String?> getPathForKPalFile() async
{
  return _pickFile(extension: fileExtensionKpal);
}

Future<(String?, Uint8List?)> getPathAndDataForImage() async
{
  final String exportDir = GetIt.I.get<AppPaths>().exportDir;
  final PlatformFile? file;
  if (isDesktop())
  {
    file = await FilePicker.pickFile(type: FileType.image, allowedExtensions: imageExtensions, initialDirectory: exportDir,);
  }
  else if (kIsWeb)
  {
    file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: imageExtensions, initialDirectory: exportDir,);
  }
  else //mobile
      {
    file = await FilePicker.pickFile(initialDirectory: exportDir,);
  }

  if (file == null)
  {
    return (null, null);
  }

  //web has no file system to read from afterwards, so the bytes have to be
  //read right after the pick
  final Uint8List? data = kIsWeb ? await file.readAsBytes() : null;
  return (pickedFilePath(file: file), data);
}

Future<String?> getDirectory({required final String startDir, required final String dialogTitle}) async
{
  return await FilePicker.getDirectoryPath(dialogTitle: dialogTitle, initialDirectory: startDir,);
}
