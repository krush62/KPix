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

import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/widgets/history_action_messages.dart';

void showMessagesForProjectLoad({required final ProjectLoadResult result, required final AppLocalizations l10n})
{
  final HistoryRestoreResult? restore = result.restore;
  if (restore == null)
  {
    showMessage(text: l10n.loadingFailed(result.status), toastType: ToastType.error);
  }
  else
  {
    showMessageForHistoryResult(result: restore, l10n: l10n);
    //the reader's report names details of the file and is shown as it is
    if (result.status.isNotEmpty)
    {
      showMessage(text: result.status, toastType: ToastType.error);
    }
  }
}

void showMessageForFileSaved({required final String displayPath, required final AppLocalizations l10n})
{
  showMessage(text: l10n.fileSavedAt(displayPath), toastType: ToastType.success);
}

void showMessageForImageImport({required final ImageImportResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case ImageImportResult.success:
      showMessage(text: l10n.imageImportSuccessful, toastType: ToastType.info);
    case ImageImportResult.conversionFailed:
      showMessage(text: l10n.couldNotConvertImageData, toastType: ToastType.info);
  }
}

void showMessageForProjectImport({required final ProjectImportResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case ProjectImportResult.success:
      showMessage(text: l10n.projectImportSuccessful, toastType: ToastType.success);
    case ProjectImportResult.cancelled:
      //no file was picked, so there is nothing to report
      break;
    case ProjectImportResult.couldNotOpenFile:
      showMessage(text: l10n.couldNotOpenFile, toastType: ToastType.error);
    case ProjectImportResult.projectAlreadyExists:
      showMessage(text: l10n.projectWithSameNameExists, toastType: ToastType.error);
    case ProjectImportResult.notAKPixFile:
      showMessage(text: l10n.pleaseSelectAKPixFile, toastType: ToastType.warning);
  }
}

/// The reason a project directory move failed, ready to be shown.
///
/// This one hands back the text instead of showing it, because the caller puts
/// it into a dialog rather than a toast.
String getMessageForProjectDirectoryMove({required final ProjectDirectoryMoveResult result, required final AppLocalizations l10n})
{
  switch (result.error)
  {
    case ProjectDirectoryMoveError.targetNotCreated:
      return l10n.targetDirCouldNotBeCreated;
    case ProjectDirectoryMoveError.insufficientPermissions:
      return l10n.insufficientPermissionsForDir;
    case ProjectDirectoryMoveError.targetFileExists:
      return l10n.dirAlreadyContainsFile(result.fileName);
    case ProjectDirectoryMoveError.moveFailed:
      return l10n.couldNotMoveFile(result.fileName);
    case ProjectDirectoryMoveError.unexpected:
    case null:
      return l10n.unexpectedErrorMovingProjectFiles;
  }
}
