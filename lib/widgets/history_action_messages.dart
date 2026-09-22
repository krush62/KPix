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
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/util/messages.dart';

String _getMessageForHistoryState({
  required final HistoryStateTypeIdentifier id,
  required final AppLocalizations l10n,
}) => switch (id) {
  HistoryStateTypeIdentifier.initial => l10n.initial,
  HistoryStateTypeIdentifier.generic => l10n.generic,
  HistoryStateTypeIdentifier.saveData => l10n.saveData,
  HistoryStateTypeIdentifier.loadData => l10n.loadData,
  HistoryStateTypeIdentifier.layerChange => l10n.selectLayer,
  HistoryStateTypeIdentifier.layerChangeWithSelection => l10n.selectLayerMoveSelection,
  HistoryStateTypeIdentifier.layerDelete => l10n.deleteLayer,
  HistoryStateTypeIdentifier.layerMerge => l10n.mergeLayer,
  HistoryStateTypeIdentifier.layerDuplicate => l10n.duplicateLayer,
  HistoryStateTypeIdentifier.layerNewDrawing => l10n.addNewDrawingLayer,
  HistoryStateTypeIdentifier.layerNewReference => l10n.addNewReferenceLayer,
  HistoryStateTypeIdentifier.layerNewGrid => l10n.addNewGridLayer,
  HistoryStateTypeIdentifier.layerNewShading => l10n.addNewShadingLayer,
  HistoryStateTypeIdentifier.layerNewDither => l10n.addNewDitherLayer,
  HistoryStateTypeIdentifier.layerOrderChange => l10n.changeLayerOrder,
  HistoryStateTypeIdentifier.layerVisibilityChange => l10n.layerVisibilityChanged,
  HistoryStateTypeIdentifier.layerLockChange => l10n.layerLockStateChanged,
  HistoryStateTypeIdentifier.layerChangeReferenceImage => l10n.changeReferenceImage,
  HistoryStateTypeIdentifier.layerRaster => l10n.rasterLayer,
  HistoryStateTypeIdentifier.layerSettingsChange => l10n.layerSettingsChange,
  HistoryStateTypeIdentifier.layerSettingsRaster => l10n.layerSettingsRaster,
  HistoryStateTypeIdentifier.selectionNew => l10n.newSelection,
  HistoryStateTypeIdentifier.selectionDeselect => l10n.deselect,
  HistoryStateTypeIdentifier.selectionSelectAll => l10n.selectAll,
  HistoryStateTypeIdentifier.selectionInverse => l10n.inverseSelection,
  HistoryStateTypeIdentifier.selectionCut => l10n.cutSelection,
  HistoryStateTypeIdentifier.selectionFlipH => l10n.flipSelectionHorizontally,
  HistoryStateTypeIdentifier.selectionFlipV => l10n.flipSelectionVertically,
  HistoryStateTypeIdentifier.selectionRotate => l10n.rotateSelection,
  HistoryStateTypeIdentifier.selectionMove => l10n.moveSelection,
  HistoryStateTypeIdentifier.selectionPaste => l10n.pasteSelection,
  HistoryStateTypeIdentifier.selectionNewLayer => l10n.selectionToNewLayer,
  HistoryStateTypeIdentifier.selectionDelete => l10n.deleteSelection,
  HistoryStateTypeIdentifier.canvasSizeChange => l10n.changeCanvasSize,
  HistoryStateTypeIdentifier.canvasFlipH => l10n.flipCanvasHorizontally,
  HistoryStateTypeIdentifier.canvasFlipV => l10n.flipCanvasVertically,
  HistoryStateTypeIdentifier.canvasRotate => l10n.rotateCanvas,
  HistoryStateTypeIdentifier.toolPen => l10n.penDrawing,
  HistoryStateTypeIdentifier.toolStamp => l10n.stampDrawing,
  HistoryStateTypeIdentifier.toolEraser => l10n.erase,
  HistoryStateTypeIdentifier.toolText => l10n.fontDrawing,
  HistoryStateTypeIdentifier.toolShape => l10n.shapeDrawing,
  HistoryStateTypeIdentifier.toolLine => l10n.lineDrawing,
  HistoryStateTypeIdentifier.toolSprayCan => l10n.sprayCanDrawing,
  HistoryStateTypeIdentifier.toolFill => l10n.fill,
  HistoryStateTypeIdentifier.colorChange => l10n.changeColorSelection,
  HistoryStateTypeIdentifier.kPalDelete => l10n.deleteRamp,
  HistoryStateTypeIdentifier.kPalChange => l10n.updateRamp,
  HistoryStateTypeIdentifier.kPalPaletteReplace => l10n.replacePalette,
  HistoryStateTypeIdentifier.kPalAdd => l10n.addNewRamp,
  HistoryStateTypeIdentifier.kPalOrderChange => l10n.changeRampOrder,
  HistoryStateTypeIdentifier.kPalAdjust => l10n.adjustPalette,
  HistoryStateTypeIdentifier.timelineFrameAdd => l10n.addFrame,
  HistoryStateTypeIdentifier.timelineFrameDelete => l10n.deleteFrame,
  HistoryStateTypeIdentifier.timelineFrameMove => l10n.moveFrame,
  HistoryStateTypeIdentifier.timelineFrameTimeChange => l10n.changeFrameTime,
  HistoryStateTypeIdentifier.timelineLoopMarkerChange => l10n.changeLoopMarker,
};

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
  final String message = _getMessageForHistoryState(id: step.identifier, l10n: l10n);
  showMessage(text: l10n.undoStep(message), toastType: ToastType.undo);
  step.restore.then((final HistoryRestoreResult result) => showMessageForHistoryResult(result: result, l10n: l10n));
}

/// Shows which step was redone, and whether restoring it failed once the
/// restore has finished.
void showMessagesForRedo({required final HistoryStep step, required final AppLocalizations l10n})
{
  final String message = _getMessageForHistoryState(id: step.identifier, l10n: l10n);
  showMessage(text: l10n.redoStep(message), toastType: ToastType.redo);
  step.restore.then((final HistoryRestoreResult result) => showMessageForHistoryResult(result: result, l10n: l10n));
}
