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
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/util/messages.dart';

void showMessageForResult({required final LayerActionResult result, required final AppLocalizations l10n})
{
  switch (result)
  {
    case LayerActionResult.invalidIndex:
      showMessage(text: l10n.invalidLayerIndex, toastType: ToastType.error);
    case LayerActionResult.layerLimitReached:
      showMessage(text: l10n.couldNotAddMoreLayers, toastType: ToastType.warning);
    case LayerActionResult.frameLimitReached:
      showMessage(text: l10n.cannotAddMoreFrames, toastType: ToastType.warning);
    case LayerActionResult.alreadyExists:
      showMessage(text: l10n.layerAlreadyExistsOnFrame, toastType: ToastType.warning);
    case LayerActionResult.noLayerBelow:
      showMessage(text: l10n.noLayerBelow, toastType: ToastType.warning);
    case LayerActionResult.linkedLayerMergeFrom:
      showMessage(text: l10n.cannotMergeFromLinkedLayer, toastType: ToastType.warning);
    case LayerActionResult.linkedLayerMergeTo:
      showMessage(text: l10n.cannotMergeToLinkedLayer, toastType: ToastType.warning);
    case LayerActionResult.invisibleLayerMergeFrom:
      showMessage(text: l10n.cannotMergeFromInvisibleLayer, toastType: ToastType.warning);
    case LayerActionResult.invisibleLayerMergeTo:
      showMessage(text: l10n.cannotMergeToInvisibleLayer, toastType: ToastType.warning);
    case LayerActionResult.lockedLayerMergeFrom:
      showMessage(text: l10n.cannotMergeFromLockedLayer, toastType: ToastType.warning);
    case LayerActionResult.lockedLayerMergeTo:
      showMessage(text: l10n.cannotMergeToLockedLayer, toastType: ToastType.warning);
    case LayerActionResult.onlyMergeDrawingLayers:
      showMessage(text: l10n.canOnlyMergeWithDrawingLayer, toastType: ToastType.warning);
    case LayerActionResult.effectLayerMerge:
      showMessage(text: l10n.cannotMergeWithActiveEffects, toastType: ToastType.warning);
    case LayerActionResult.lastLayerDelete:
      showMessage(text: l10n.cannotDeleteLastLayer, toastType: ToastType.error);
    case LayerActionResult.unknownError:
      showMessage(text: l10n.unknownError, toastType: ToastType.warning);
    case LayerActionResult.success:
      break;
  }
}
