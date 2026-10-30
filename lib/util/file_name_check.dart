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
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

enum FileNameStatus
{
  available(TablerIcons.check),
  forbidden(TablerIcons.x),
  noRights(TablerIcons.ban),
  overwrite(TablerIcons.exclamation_mark);

  String label(final AppLocalizations l10n) => switch(this)
  {
    available => l10n.available,
    forbidden => l10n.invalidFileName,
    noRights => l10n.insufficientPermissions,
    overwrite => l10n.overwritingExistingFile,
  };

  const FileNameStatus(this.icon);
  final IconData icon;
}

FileNameStatus checkFileName({required final String fileName, required final String directory, required final String extension, final bool allowRecoverFile = true,})
{
  final Logger logger = GetIt.I.get<Logger>();
  try
  {
    if (fileName.isEmpty)
    {
      return FileNameStatus.forbidden;
    }

    if (kIsWeb)
    {
      return FileNameStatus.available;
    }

    if (Platform.isWindows)
    {
      final List<String> reservedFilenames = <String>[
        'CON',
        'PRN',
        'AUX',
        'NUL',
        'COM1',
        'COM2',
        'COM3',
        'COM4',
        'COM5',
        'COM6',
        'COM7',
        'COM8',
        'COM9',
        'LPT1',
        'LPT2',
        'LPT3',
        'LPT4',
        'LPT5',
        'LPT6',
        'LPT7',
        'LPT8',
        'LPT9',
      ];
      if (fileName.endsWith(' ') || fileName.endsWith('.') || reservedFilenames.contains(fileName.toUpperCase()))
      {
        return FileNameStatus.forbidden;
      }
    }

    if (fileName == recoverFileName && !allowRecoverFile) 
    {
      return FileNameStatus.forbidden;
    }

    final List<String> invalidCharacters = <String>[
      '/',
      '\\',
      '?',
      '%',
      '*',
      ':',
      '|',
      '"',
      '<',
      '>',
    ];
    for (final String char in invalidCharacters)
    {
      if (fileName.contains(char))
      {
        return FileNameStatus.forbidden;
      }
    }
    if (!hasWriteAccess(directory: directory))
    {
      return FileNameStatus.noRights;
    }

    final String fullPath = p.join(directory, "$fileName.$extension");
    final File file = File(fullPath);
    if (file.existsSync())
    {
      return FileNameStatus.overwrite;
    }

    return FileNameStatus.available;
  }
  catch (e, s)
  {
    logger.w("Error checking file name.", error: e, stackTrace: s);
  }
  return FileNameStatus.forbidden;
}
