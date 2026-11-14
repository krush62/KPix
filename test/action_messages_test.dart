/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/widgets/canvas_action_messages.dart';
import 'package:kpix/widgets/history_action_messages.dart';
import 'package:kpix/widgets/layer_action_messages.dart';
import 'package:kpix/widgets/palette_action_messages.dart';
import 'package:kpix/widgets/project_action_messages.dart';
import 'package:kpix/widgets/selection_action_messages.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale("en"));

/// What a result is expected to show: nothing at all for a null text.
typedef _Toast = (String?, ToastType?);

const _Toast _nothing = (null, null);

Future<void> _pumpHost(final WidgetTester tester) async
{
  await tester.pumpWidget(getToastificationWrapper(child: MaterialApp(theme: monochromeTheme, home: const SizedBox.shrink())));
}

Future<void> _settleToasts(final WidgetTester tester) async
{
  //a toast is only inserted a moment after it was asked for, and then built and laid out
  for (int i = 0; i < 3; i++)
  {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _clearToasts(final WidgetTester tester) async
{
  toastification.dismissAll(delayForAnimation: false);
  await tester.pump(const Duration(seconds: 10));
}

void _toastTest({required final String description, required final void Function() show, required final _Toast toast})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await _pumpHost(tester);

    show();
    await _settleToasts(tester);

    if (toast.$1 == null)
    {
      expect(find.byType(Icon), findsNothing, reason: "there is nothing to report");
    }
    else
    {
      expect(find.text(toast.$1!), findsOneWidget);
      expect(find.byIcon(toast.$2!.iconData), findsOneWidget);
    }
    await _clearToasts(tester);
  });
}

void _resultTable<T extends Enum>({required final List<T> values, required final Map<T, _Toast> table, required final void Function(T result) show})
{
  test("every result is listed", ()
  {
    expect(table.keys.toSet(), values.toSet());
  });

  for (final MapEntry<T, _Toast> entry in table.entries)
  {
    _toastTest(description: entry.key.name, show: () => show(entry.key), toast: entry.value);
  }
}

void main()
{
  group("a layer action", ()
  {
    _resultTable<LayerActionResult>(
      values: LayerActionResult.values,
      show: (final LayerActionResult result) => showMessageForResult(result: result, l10n: _l10n),
      table: <LayerActionResult, _Toast>{
        LayerActionResult.success: _nothing,
        LayerActionResult.invalidIndex: (_l10n.invalidLayerIndex, ToastType.error),
        LayerActionResult.layerLimitReached: (_l10n.couldNotAddMoreLayers, ToastType.warning),
        LayerActionResult.frameLimitReached: (_l10n.cannotAddMoreFrames, ToastType.warning),
        LayerActionResult.alreadyExists: (_l10n.layerAlreadyExistsOnFrame, ToastType.warning),
        LayerActionResult.noLayerBelow: (_l10n.noLayerBelow, ToastType.warning),
        LayerActionResult.linkedLayerMergeFrom: (_l10n.cannotMergeFromLinkedLayer, ToastType.warning),
        LayerActionResult.linkedLayerMergeTo: (_l10n.cannotMergeToLinkedLayer, ToastType.warning),
        LayerActionResult.invisibleLayerMergeFrom: (_l10n.cannotMergeFromInvisibleLayer, ToastType.warning),
        LayerActionResult.invisibleLayerMergeTo: (_l10n.cannotMergeToInvisibleLayer, ToastType.warning),
        LayerActionResult.lockedLayerMergeFrom: (_l10n.cannotMergeFromLockedLayer, ToastType.warning),
        LayerActionResult.lockedLayerMergeTo: (_l10n.cannotMergeToLockedLayer, ToastType.warning),
        LayerActionResult.onlyMergeDrawingLayers: (_l10n.canOnlyMergeWithDrawingLayer, ToastType.warning),
        LayerActionResult.effectLayerMerge: (_l10n.cannotMergeWithActiveEffects, ToastType.warning),
        LayerActionResult.lastLayerDelete: (_l10n.cannotDeleteLastLayer, ToastType.error),
        LayerActionResult.unknownError: (_l10n.unknownError, ToastType.warning),
      },
    );
  });

  group("a selection action", ()
  {
    _resultTable<SelectionActionResult>(
      values: SelectionActionResult.values,
      show: (final SelectionActionResult result) => showMessageForSelectionResult(result: result, l10n: _l10n),
      table: <SelectionActionResult, _Toast>{
        SelectionActionResult.success: _nothing,
        SelectionActionResult.notApplicable: _nothing,
        SelectionActionResult.hiddenLayerDelete: (_l10n.cannotDeleteFromHiddenLayer, ToastType.warning),
        SelectionActionResult.lockedLayerDelete: (_l10n.cannotDeleteFromLockedLayer, ToastType.warning),
        SelectionActionResult.hiddenLayerCut: (_l10n.cannotCutFromHiddenLayer, ToastType.warning),
        SelectionActionResult.lockedLayerCut: (_l10n.cannotCutFromLockedLayer, ToastType.warning),
        SelectionActionResult.nothingToCopy: (_l10n.nothingToCopy, ToastType.warning),
        SelectionActionResult.clipboardColorsMissing: (_l10n.nothingToPasteColorsNotInPalette, ToastType.warning),
        SelectionActionResult.hiddenLayerPaste: (_l10n.cannotPasteToHiddenLayer, ToastType.warning),
        SelectionActionResult.lockedLayerPaste: (_l10n.cannotPasteToLockedLayer, ToastType.warning),
        SelectionActionResult.hiddenLayerTransform: (_l10n.cannotTransformOnHiddenLayer, ToastType.warning),
        SelectionActionResult.lockedLayerTransform: (_l10n.cannotTransformOnLockedLayer, ToastType.warning),
      },
    );
  });

  group("a canvas action", ()
  {
    _resultTable<CanvasActionResult>(
      values: CanvasActionResult.values,
      show: (final CanvasActionResult result) => showMessageForCanvasResult(result: result, l10n: _l10n),
      table: <CanvasActionResult, _Toast>{
        CanvasActionResult.success: _nothing,
        CanvasActionResult.cropFailed: (_l10n.couldNotCrop, ToastType.error),
      },
    );
  });

  group("a palette action", ()
  {
    _resultTable<PaletteActionResult>(
      values: PaletteActionResult.values,
      show: (final PaletteActionResult result) => showMessageForPaletteResult(result: result, l10n: _l10n),
      table: <PaletteActionResult, _Toast>{
        PaletteActionResult.success: _nothing,
        PaletteActionResult.rampCountMinReached: (_l10n.needAtLeastColorRamps(count: KPalConstraints.rampCountLimits.min), ToastType.warning),
        PaletteActionResult.rampCountMaxReached: (_l10n.notMoreThanColorRampsAllowed(count: KPalConstraints.rampCountLimits.max), ToastType.warning),
        PaletteActionResult.loadingFailed: (_l10n.loadingPaletteFailed, ToastType.error),
      },
    );
  });

  group("a palette import", ()
  {
    _resultTable<PaletteImportResult>(
      values: PaletteImportResult.values,
      show: (final PaletteImportResult result) => showMessageForPaletteImport(result: result, l10n: _l10n),
      table: <PaletteImportResult, _Toast>{
        PaletteImportResult.success: (_l10n.paletteImportSuccessful, ToastType.success),
        PaletteImportResult.cancelled: _nothing,
        PaletteImportResult.failed: (_l10n.paletteImportFailed, ToastType.error),
        PaletteImportResult.paletteAlreadyExists: (_l10n.paletteWithSameNameExists, ToastType.error),
        PaletteImportResult.notAKPalFile: (_l10n.pleaseSelectAKPalFile, ToastType.warning),
      },
    );
  });

  group("an image import", ()
  {
    _resultTable<ImageImportResult>(
      values: ImageImportResult.values,
      show: (final ImageImportResult result) => showMessageForImageImport(result: result, l10n: _l10n),
      table: <ImageImportResult, _Toast>{
        ImageImportResult.success: (_l10n.imageImportSuccessful, ToastType.info),
        ImageImportResult.conversionFailed: (_l10n.couldNotConvertImageData, ToastType.info),
      },
    );
  });

  group("a project import", ()
  {
    _resultTable<ProjectImportResult>(
      values: ProjectImportResult.values,
      show: (final ProjectImportResult result) => showMessageForProjectImport(result: result, l10n: _l10n),
      table: <ProjectImportResult, _Toast>{
        ProjectImportResult.success: (_l10n.projectImportSuccessful, ToastType.success),
        ProjectImportResult.cancelled: _nothing,
        ProjectImportResult.couldNotOpenFile: (_l10n.couldNotOpenFile, ToastType.error),
        ProjectImportResult.projectAlreadyExists: (_l10n.projectWithSameNameExists, ToastType.error),
        ProjectImportResult.notAKPixFile: (_l10n.pleaseSelectAKPixFile, ToastType.warning),
      },
    );
  });

  group("saving a file", ()
  {
    _toastTest(description: "names where it went", show: () => showMessageForFileSaved(displayPath: "some/path", l10n: _l10n), toast: (_l10n.fileSavedAt(path: "some/path"), ToastType.success));
    _toastTest(description: "says when it failed", show: () => showMessageForFileSaveFailed(l10n: _l10n), toast: (_l10n.errorSavingProject, ToastType.error));
  });

  group("loading a project", ()
  {
    _toastTest(
      description: "reports the file's problem when nothing could be restored",
      show: () => showMessagesForProjectLoad(result: (restore: null, status: "broken file"), l10n: _l10n),
      toast: (_l10n.loadingFailed(status: "broken file"), ToastType.error),
    );
    _toastTest(
      description: "reports nothing when all went well",
      show: () => showMessagesForProjectLoad(result: (restore: HistoryRestoreResult.success, status: ""), l10n: _l10n),
      toast: _nothing,
    );
    _toastTest(
      description: "passes on what the reader has to say",
      show: () => showMessagesForProjectLoad(result: (restore: HistoryRestoreResult.success, status: "dropped a layer"), l10n: _l10n),
      toast: ("dropped a layer", ToastType.error),
    );
    _toastTest(
      description: "reports a restore that failed",
      show: () => showMessagesForProjectLoad(result: (restore: HistoryRestoreResult.failed, status: ""), l10n: _l10n),
      toast: (_l10n.historyRestoreFailed, ToastType.error),
    );
  });

  group("moving the project directory", ()
  {
    for (final (ProjectDirectoryMoveError?, String) entry in <(ProjectDirectoryMoveError?, String)>[
      (ProjectDirectoryMoveError.targetNotCreated, _l10n.targetDirCouldNotBeCreated),
      (ProjectDirectoryMoveError.insufficientPermissions, _l10n.insufficientPermissionsForDir),
      (ProjectDirectoryMoveError.targetFileExists, _l10n.dirAlreadyContainsFile(fileName: "a.kpix")),
      (ProjectDirectoryMoveError.moveFailed, _l10n.couldNotMoveFile(fileName: "a.kpix")),
      (ProjectDirectoryMoveError.unexpected, _l10n.unexpectedErrorMovingProjectFiles),
      (null, _l10n.unexpectedErrorMovingProjectFiles),
    ])
    {
      test("explains ${entry.$1?.name ?? "no error at all"}", ()
      {
        final ProjectDirectoryMoveResult result = ProjectDirectoryMoveResult(success: false, error: entry.$1, fileName: "a.kpix");

        expect(getMessageForProjectDirectoryMove(result: result, l10n: _l10n), entry.$2);
      });
    }
  });

  group("undoing and redoing", ()
  {
    HistoryStep stepFor({required final HistoryStateTypeIdentifier identifier, final HistoryRestoreResult result = HistoryRestoreResult.success})
    {
      return (identifier: identifier, restore: Future<HistoryRestoreResult>.value(result));
    }

    _toastTest(
      description: "undo names the step",
      show: () => showMessagesForUndo(step: stepFor(identifier: HistoryStateTypeIdentifier.layerMerge), l10n: _l10n),
      toast: (_l10n.undoStep(description: _l10n.mergeLayer), ToastType.undo),
    );
    _toastTest(
      description: "redo names the step",
      show: () => showMessagesForRedo(step: stepFor(identifier: HistoryStateTypeIdentifier.toolFill), l10n: _l10n),
      toast: (_l10n.redoStep(description: _l10n.fill), ToastType.redo),
    );

    for (final (String, void Function({required HistoryStep step, required AppLocalizations l10n})) direction in <(String, void Function({required HistoryStep step, required AppLocalizations l10n}))>[
      ("undo", showMessagesForUndo),
      ("redo", showMessagesForRedo),
    ])
    {
      testWidgets("${direction.$1} says so when the restore failed", (final WidgetTester tester) async
      {
        await _pumpHost(tester);

        direction.$2(step: stepFor(identifier: HistoryStateTypeIdentifier.layerMerge, result: HistoryRestoreResult.failed), l10n: _l10n);
        await _settleToasts(tester);

        expect(find.text(_l10n.historyRestoreFailed), findsOneWidget);
        await _clearToasts(tester);
      });
    }

    testWidgets("every kind of step has a name of its own", (final WidgetTester tester) async
    {
      await _pumpHost(tester);
      final String prefix = _l10n.undoStep(description: "");
      final Set<String> names = <String>{};

      for (final HistoryStateTypeIdentifier identifier in HistoryStateTypeIdentifier.values)
      {
        showMessagesForUndo(step: stepFor(identifier: identifier), l10n: _l10n);
        await _settleToasts(tester);
        final Text toast = tester.widget<Text>(find.textContaining(prefix));
        final String name = toast.data!.substring(prefix.length);
        expect(name, isNotEmpty, reason: identifier.name);
        names.add(name);
        await _clearToasts(tester);
      }

      expect(names, hasLength(HistoryStateTypeIdentifier.values.length));
    });
  });
}
