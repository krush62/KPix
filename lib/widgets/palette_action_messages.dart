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
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/messages.dart';

void showMessageForPaletteResult({required final PaletteActionResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case PaletteActionResult.rampCountMinReached:
      showMessage(text: l10n.needAtLeastColorRamps(KPalConstraints.rampCountMin), toastType: ToastType.warning);
    case PaletteActionResult.rampCountMaxReached:
      showMessage(text: l10n.notMoreThanColorRampsAllowed(KPalConstraints.rampCountMax), toastType: ToastType.warning);
    case PaletteActionResult.loadingFailed:
      showMessage(text: l10n.loadingPaletteFailed, toastType: ToastType.error);
    case PaletteActionResult.success:
      break;
  }
}
