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
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/messages.dart';

void showMessageForSelectionResult({required final SelectionActionResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case SelectionActionResult.hiddenLayerDelete:
      showMessage(text: l10n.cannotDeleteFromHiddenLayer, toastType: ToastType.warning);
    case SelectionActionResult.lockedLayerDelete:
      showMessage(text: l10n.cannotDeleteFromLockedLayer, toastType: ToastType.warning);
    case SelectionActionResult.hiddenLayerCut:
      showMessage(text: l10n.cannotCutFromHiddenLayer, toastType: ToastType.warning);
    case SelectionActionResult.lockedLayerCut:
      showMessage(text: l10n.cannotCutFromLockedLayer, toastType: ToastType.warning);
    case SelectionActionResult.nothingToCopy:
      showMessage(text: l10n.nothingToCopy, toastType: ToastType.warning);
    case SelectionActionResult.clipboardColorsMissing:
      showMessage(text: l10n.nothingToPasteColorsNotInPalette, toastType: ToastType.warning);
    case SelectionActionResult.hiddenLayerPaste:
      showMessage(text: l10n.cannotPasteToHiddenLayer, toastType: ToastType.warning);
    case SelectionActionResult.lockedLayerPaste:
      showMessage(text: l10n.cannotPasteToLockedLayer, toastType: ToastType.warning);
    case SelectionActionResult.hiddenLayerTransform:
      showMessage(text: l10n.cannotTransformOnHiddenLayer, toastType: ToastType.warning);
    case SelectionActionResult.lockedLayerTransform:
      showMessage(text: l10n.cannotTransformOnLockedLayer, toastType: ToastType.warning);
    case SelectionActionResult.success:
    case SelectionActionResult.notApplicable:
      break;
  }
}
