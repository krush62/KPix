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
import 'package:kpix/util/messages.dart';

void showMessageForHistoryResult({required final HistoryRestoreResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case HistoryRestoreResult.failed:
      showMessage(text: l10n.historyRestoreFailed, toastType: ToastType.error);
    case HistoryRestoreResult.success:
      break;
  }
}

/// Shows which step was undone, and whether restoring it failed once the
/// restore has finished.
void showMessagesForUndo({required final HistoryStep step, required final AppLocalizations l10n})
{
  showMessage(text: l10n.undoStep(step.description), toastType: ToastType.undo);
  step.restore.then((final HistoryRestoreResult result) => showMessageForHistoryResult(result: result, l10n: l10n));
}

/// Shows which step was redone, and whether restoring it failed once the
/// restore has finished.
void showMessagesForRedo({required final HistoryStep step, required final AppLocalizations l10n})
{
  showMessage(text: l10n.redoStep(step.description), toastType: ToastType.redo);
  step.restore.then((final HistoryRestoreResult result) => showMessageForHistoryResult(result: result, l10n: l10n));
}
