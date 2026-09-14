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
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/util/messages.dart';

void showMessageForCanvasResult({required final CanvasActionResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case CanvasActionResult.cropFailed:
      showMessage(text: l10n.couldNotCrop, toastType: ToastType.error);
    case CanvasActionResult.success:
      break;
  }
}
