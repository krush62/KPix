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
import 'dart:ui' as ui;

import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/extra/about_screen_widget.dart';
import 'package:kpix/widgets/extra/controls_widget.dart';
import 'package:kpix/widgets/extra/credits_widget.dart';
import 'package:kpix/widgets/extra/licenses_widget.dart';
import 'package:kpix/widgets/extra/preferences_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/file/project_manager_widget.dart';
import 'package:kpix/widgets/file/save_as_widget.dart';
import 'package:kpix/widgets/file/shader_export_widget.dart';
import 'package:kpix/widgets/main/main_button_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';
import 'support/widget_harness.dart';

ProjectSession get _session => GetIt.I.get<ProjectSession>();
HistoryManager get _history => GetIt.I.get<HistoryManager>();
HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();
AppPaths get _paths => GetIt.I.get<AppPaths>();

void _flowTest(final String description, final Future<void> Function(WidgetTester tester) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    final AppPaths paths = createTestPaths();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async
    {
      await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8), appPaths: paths);
      await createInternalDirectories();
      GetIt.I.registerSingleton<PackageInfo>(PackageInfo(appName: "KPix", packageName: "kpix", version: "1.2.3", buildNumber: "4"));
      GetIt.I.registerSingleton<ProjectManager>(ProjectManager());
    });
    await tester.pumpWidget(testApp(textScale: 0.4, child: const Align(alignment: Alignment.topLeft, child: SizedBox(width: 320, child: MainButtonWidget()))));
    await settleUi(tester);

    await body(tester);

    GetIt.I.get<ProjectManager>().dispose();
    await closeTestApp(tester);
  }, semanticsEnabled: false,);
}

Future<void> _openMenu(final WidgetTester tester, {required final String tooltip}) async
{
  await tester.tap(find.byTooltip(tooltip));
  await settleUi(tester);
}

Future<void> _pickFromMenu(final WidgetTester tester, {required final String entry}) async
{
  await tester.tap(findTooltipStarting(entry).first);
  await settleUi(tester);
}

/// Lets a file operation finish.
Future<void> _waitForFiles(final WidgetTester tester) async
{
  for (int i = 0; i < 20; i++)
  {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _markChanged()
{
  _session.hasChanges.value = true;
}

void main()
{
  group("the load menu", ()
  {
    _flowTest("offers a new project, which leaves the current one", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.newOpenDot);

      await _pickFromMenu(tester, entry: testL10n.newProject);

      expect(_session.hasProject, isFalse);
      expect(findTooltipStarting(testL10n.newProject), findsNothing, reason: "the menu closed");
      _session.hasProjectNotifier.value = true;
      await settleUi(tester);
    });

    _flowTest("opens the project manager", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.newOpenDot);

      await _pickFromMenu(tester, entry: testL10n.openProject);

      expect(find.byType(ProjectManagerWidget), findsOneWidget);
    });

    _flowTest("goes to the import right away without changes", (final WidgetTester tester) async
    {
      _session.hasChanges.value = false;
      await _openMenu(tester, tooltip: testL10n.newOpenDot);

      await _pickFromMenu(tester, entry: testL10n.importImage);

      expect(find.text(testL10n.thereAreUnsavedChanges), findsNothing);
      expect(findTooltipStarting(testL10n.newProject), findsNothing);
      expect(find.byType(ImportWidget), findsOneWidget);
    });

    group("with unsaved changes", ()
    {
      Future<void> askForImport(final WidgetTester tester) async
      {
        _markChanged();
        await _openMenu(tester, tooltip: testL10n.newOpenDot);
        await _pickFromMenu(tester, entry: testL10n.importImage);
        expect(find.text(testL10n.thereAreUnsavedChanges), findsOneWidget, reason: "setup");
      }

      _flowTest("asks first, and cancel stays", (final WidgetTester tester) async
      {
        await askForImport(tester);

        await tapTooltip(tester, testL10n.cancel);

        expect(find.text(testL10n.thereAreUnsavedChanges), findsNothing);
        expect(find.byType(ImportWidget), findsNothing);
      });

      _flowTest("goes on without saving on no", (final WidgetTester tester) async
      {
        await askForImport(tester);

        await tapTooltip(tester, testL10n.no);

        expect(find.byType(ImportWidget), findsOneWidget);
      });

      _flowTest("takes the warning away on no", (final WidgetTester tester) async
      {
        await askForImport(tester);

        await tapTooltip(tester, testL10n.no);

        expect(find.text(testL10n.thereAreUnsavedChanges), findsNothing);
        expect(findTooltipStarting(testL10n.newProject), findsNothing);
        expect(find.byType(ImportWidget), findsOneWidget);
      });

      _flowTest("saves first on yes, once the project has a name", (final WidgetTester tester) async
      {
        _session.projectName.value = "named";
        await askForImport(tester);

        await tapTooltip(tester, testL10n.yes);
        await _waitForFiles(tester);

        expect(await tester.runAsync(() => File(p.join(_paths.projectsDir, "named.$fileExtensionKpix")).exists()), isTrue);
        expect(find.byType(ImportWidget), findsOneWidget);
        expect(find.text(testL10n.thereAreUnsavedChanges), findsNothing);
      });

      _flowTest("asks for a name first on yes, if it has none", (final WidgetTester tester) async
      {
        _session.projectName.value = null;
        await askForImport(tester);

        await tapTooltip(tester, testL10n.yes);

        expect(find.byType(SaveAsWidget), findsOneWidget);
      });
    });
  });

  group("the save menu", ()
  {
    _flowTest("saves under the name of the project", (final WidgetTester tester) async
    {
      _session.projectName.value = "named";
      await _openMenu(tester, tooltip: testL10n.saveDot);

      await _pickFromMenu(tester, entry: testL10n.saveProject);
      await _waitForFiles(tester);

      final String file = p.join(_paths.projectsDir, "named.$fileExtensionKpix");
      expect(await tester.runAsync(() => File(file).exists()), isTrue);
      expect(await tester.runAsync(() => File(p.join(_paths.projectsDir, "named.$thumbnailExtension")).exists()), isTrue, reason: "with its thumbnail");
      expect(find.textContaining("named"), findsWidgets, reason: "says where it went");
      expect(_session.hasChanges.value, isFalse);
    });

    _flowTest("says so when saving fails", (final WidgetTester tester) async
    {
      _session.projectName.value = "named";
      //a file where the directory should be
      await tester.runAsync(() async
      {
        await Directory(_paths.projectsDir).delete(recursive: true);
        await File(_paths.projectsDir).writeAsString("in the way");
      });
      await _openMenu(tester, tooltip: testL10n.saveDot);

      await _pickFromMenu(tester, entry: testL10n.saveProject);
      await _waitForFiles(tester);

      expect(find.text(testL10n.errorSavingProject), findsOneWidget);
      await tester.runAsync(() => File(_paths.projectsDir).delete());
      await tester.runAsync(() => Directory(_paths.projectsDir).create());
    });

    _flowTest("asks for a name when there is none", (final WidgetTester tester) async
    {
      _session.projectName.value = null;
      await _openMenu(tester, tooltip: testL10n.saveDot);

      await _pickFromMenu(tester, entry: testL10n.saveProject);

      expect(find.byType(SaveAsWidget), findsOneWidget);
    });

    _flowTest("saves under a new name", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.saveDot);
      await _pickFromMenu(tester, entry: testL10n.saveProjectAs);
      expect(find.byType(SaveAsWidget), findsOneWidget);

      await tester.enterText(find.descendant(of: find.byType(SaveAsWidget), matching: find.byType(TextField)), "another");
      await tester.pump();
      await tester.tap(find.descendant(of: find.byType(SaveAsWidget), matching: find.byTooltip(testL10n.saveProject)));
      await _waitForFiles(tester);

      expect(find.byType(SaveAsWidget), findsNothing);
      expect(await tester.runAsync(() => File(p.join(_paths.projectsDir, "another.$fileExtensionKpix")).exists()), isTrue);
      expect(_session.projectName.value, "another");
    });

    _flowTest("opens the export", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.saveDot);

      await _pickFromMenu(tester, entry: testL10n.exportProjectPalette);

      expect(find.byType(ExportWidget), findsOneWidget);
    });

    _flowTest("opens the shader export", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.saveDot);

      await _pickFromMenu(tester, entry: testL10n.exportShaderImage);

      expect(find.byType(ShaderExportWidget), findsOneWidget);
    });
  });

  group("the hotkeys", ()
  {
    _flowTest("open the save dialog and the export", (final WidgetTester tester) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.generalSaveAs);
      await settleUi(tester);
      expect(find.byType(SaveAsWidget), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(SaveAsWidget), matching: find.byTooltip(testL10n.cancel)));
      await settleUi(tester);
      expect(find.byType(SaveAsWidget), findsNothing);

      _hotkeys.triggerShortcut(action: HotkeyAction.generalExport);
      await settleUi(tester);
      expect(find.byType(ExportWidget), findsOneWidget);
    });

    _flowTest("open the project manager", (final WidgetTester tester) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.generalOpen);
      await settleUi(tester);

      expect(find.byType(ProjectManagerWidget), findsOneWidget);
    });
  });

  group("undo and redo", ()
  {
    IconButton undo(final WidgetTester tester) => tester.widget<IconButton>(find.ancestor(of: find.byIcon(TablerIcons.arrow_back_up), matching: find.byType(IconButton)));
    IconButton redo(final WidgetTester tester) => tester.widget<IconButton>(find.ancestor(of: find.byIcon(TablerIcons.arrow_forward_up), matching: find.byType(IconButton)));

    _flowTest("are only possible when there is something to do", (final WidgetTester tester) async
    {
      _history.clear();
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);
      await tester.pump();
      expect(undo(tester).onPressed, isNull);
      expect(redo(tester).onPressed, isNull);

      _history.addState(identifier: HistoryStateTypeIdentifier.layerMerge);
      await tester.pump();
      expect(undo(tester).onPressed, isNotNull);
    });

    _flowTest("name the step they took", (final WidgetTester tester) async
    {
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);
      _history.addState(identifier: HistoryStateTypeIdentifier.layerMerge);
      await tester.pump();

      await tester.tap(find.byIcon(TablerIcons.arrow_back_up));
      await settleUi(tester);
      expect(find.text(testL10n.undoStep(description: testL10n.mergeLayer)), findsOneWidget);
      expect(redo(tester).onPressed, isNotNull);

      await tester.tap(find.byIcon(TablerIcons.arrow_forward_up));
      await settleUi(tester);
      expect(find.text(testL10n.redoStep(description: testL10n.mergeLayer)), findsOneWidget);
    });

    _flowTest("are ignored by the hotkeys when there is nothing to do", (final WidgetTester tester) async
    {
      _history.clear();
      _history.addState(identifier: HistoryStateTypeIdentifier.generic);
      await tester.pump();

      _hotkeys.triggerShortcut(action: HotkeyAction.generalUndo);
      _hotkeys.triggerShortcut(action: HotkeyAction.generalRedo);
      await settleUi(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group("the about screen", ()
  {
    _flowTest("shows the version", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.about);

      expect(find.byType(AboutScreenWidget), findsOneWidget);
      expect(find.textContaining("1.2.3"), findsWidgets);
    });

    for (final (String Function(), Type) entry in <(String Function(), Type)>[
      (() => testL10n.licenses, LicensesWidget),
      (() => testL10n.credits, CreditsWidget),
      (() => testL10n.controlsShortcuts, ControlsWidget),
    ])
    {
      _flowTest("opens and closes ${entry.$2}", (final WidgetTester tester) async
      {
        await _openMenu(tester, tooltip: testL10n.about);

        await tester.tap(find.byTooltip(entry.$1()));
        await settleUi(tester);
        expect(find.byType(entry.$2), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.descendant(of: find.byType(entry.$2), matching: find.byType(IconButton)).last);
        await settleUi(tester);
        expect(find.byType(entry.$2), findsNothing);
        expect(find.byType(AboutScreenWidget), findsOneWidget);
      });
    }

    _flowTest("closes", (final WidgetTester tester) async
    {
      await _openMenu(tester, tooltip: testL10n.about);

      await tester.tap(find.descendant(of: find.byType(AboutScreenWidget), matching: find.byTooltip(testL10n.close)));
      await settleUi(tester);

      expect(find.byType(AboutScreenWidget), findsNothing);
    });
  });

  group("the update mark", ()
  {
    _flowTest("shows when there is an update", (final WidgetTester tester) async
    {
      expect(find.text("⬤"), findsNothing);

      GetIt.I.get<UpdateState>().hasUpdateNotifier.value = true;
      await tester.pump();

      expect(find.text("⬤"), findsOneWidget);
    });
  });

  group("the preferences", ()
  {
    _flowTest("go back to what was saved when cancelled", (final WidgetTester tester) async
    {
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final int before = prefs.behaviorPreferenceContent.undoSteps.value;
      await _openMenu(tester, tooltip: testL10n.preferences);
      expect(find.byType(PreferencesWidget), findsOneWidget);
      prefs.behaviorPreferenceContent.undoSteps.value = before + 1;

      await tapTooltip(tester, testL10n.cancel);
      await _waitForFiles(tester);

      expect(find.byType(PreferencesWidget), findsNothing);
      expect(prefs.behaviorPreferenceContent.undoSteps.value, before);
    });

    _flowTest("keep what was changed when accepted", (final WidgetTester tester) async
    {
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final int before = prefs.behaviorPreferenceContent.undoSteps.value;
      await _openMenu(tester, tooltip: testL10n.preferences);
      prefs.behaviorPreferenceContent.undoSteps.value = before + 1;

      await tapTooltip(tester, testL10n.apply);
      await _waitForFiles(tester);

      expect(find.byType(PreferencesWidget), findsNothing);
      expect(prefs.behaviorPreferenceContent.undoSteps.value, before + 1);
    });

    _flowTest("move the projects when the directory changes", (final WidgetTester tester) async
    {
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final String custom = p.join(_paths.internalDir, "custom");
      await tester.runAsync(() async
      {
        await Directory(custom).create();
        await File(p.join(_paths.projectsDir, "moved.$fileExtensionKpix")).writeAsString("kpix");
      });
      await _openMenu(tester, tooltip: testL10n.preferences);
      prefs.behaviorPreferenceContent.customProjectDirectory.value = custom;
      prefs.behaviorPreferenceContent.useCustomProjectDirectory.value = true;

      await tapTooltip(tester, testL10n.apply);
      await _waitForFiles(tester);

      expect(_paths.projectsDir, custom);
      expect(await tester.runAsync(() => File(p.join(custom, "moved.$fileExtensionKpix")).exists()), isTrue);
      expect(find.text(testL10n.changedProjectDirectoryFiles(directory: custom, count: 1)), findsOneWidget);
    });

    _flowTest("stay with the old directory when the move fails, and say why", (final WidgetTester tester) async
    {
      final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
      final String custom = p.join(_paths.internalDir, "custom");
      _paths.projectsDir = getDefaultProjectsDir(internalDir: _paths.internalDir);
      final String before = _paths.projectsDir;
      await tester.runAsync(() async
      {
        await Directory(custom).create();
        await File(p.join(before, "moved.$fileExtensionKpix")).writeAsString("kpix");
        await File(p.join(custom, "moved.$fileExtensionKpix")).writeAsString("in the way");
      });
      await _openMenu(tester, tooltip: testL10n.preferences);
      prefs.behaviorPreferenceContent.customProjectDirectory.value = custom;
      prefs.behaviorPreferenceContent.useCustomProjectDirectory.value = true;

      await tapTooltip(tester, testL10n.apply);
      await _waitForFiles(tester);

      expect(_paths.projectsDir, before);
      expect(prefs.behaviorPreferenceContent.useCustomProjectDirectory.value, isFalse);
      expect(find.textContaining(testL10n.dirAlreadyContainsFile(fileName: "moved.$fileExtensionKpix")), findsOneWidget);
    });
  });

  group("a project in the project manager", ()
  {
    final CoordinateSetI pixel = CoordinateSetI(x: 2, y: 2);

    DrawingLayerState layer() => GetIt.I.get<DocumentState>().timeline.getCurrentLayer()! as DrawingLayerState;

    /// A project on disk with a pixel the open one does not have, and the manager open on it.
    Future<void> openOnStoredProject(final WidgetTester tester) async
    {
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps[0].references[0];
      layer().setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
      await tester.runAsync(settle);
      _session.projectName.value = "stored";
      await _openMenu(tester, tooltip: testL10n.saveDot);
      await _pickFromMenu(tester, entry: testL10n.saveProject);
      await _waitForFiles(tester);

      layer().removeDataAll(removeCoordList: <CoordinateSetI>{pixel});
      await tester.runAsync(settle);
      await tester.runAsync(() => GetIt.I.get<ProjectManager>().reindex());
      _hotkeys.triggerShortcut(action: HotkeyAction.generalOpen);
      await _waitForFiles(tester);
      await tester.tap(find.byType(ProjectManagerEntryWidget));
      await settleUi(tester);
    }

    _flowTest("is loaded when picked", (final WidgetTester tester) async
    {
      await openOnStoredProject(tester);
      _session.hasChanges.value = false;

      await tapTooltip(tester, testL10n.loadSelectedProject);
      await _waitForFiles(tester);

      expect(find.byType(ProjectManagerWidget), findsNothing);
      expect(layer().getDataEntry(coord: pixel), isNotNull);
      expect(_session.projectName.value, "stored");
    });

    _flowTest("asks about unsaved changes first, and no just loads", (final WidgetTester tester) async
    {
      await openOnStoredProject(tester);
      _markChanged();

      await tapTooltip(tester, testL10n.loadSelectedProject);
      expect(find.text(testL10n.thereAreUnsavedChanges), findsOneWidget);
      await tapTooltip(tester, testL10n.no);
      await _waitForFiles(tester);

      expect(layer().getDataEntry(coord: pixel), isNotNull);
    });

    _flowTest("saves the open project first on yes", (final WidgetTester tester) async
    {
      await openOnStoredProject(tester);
      _markChanged();
      final File stored = File(p.join(_paths.projectsDir, "stored.$fileExtensionKpix"));
      final DateTime before = (await tester.runAsync(stored.lastModified))!;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));

      await tapTooltip(tester, testL10n.loadSelectedProject);
      await tapTooltip(tester, testL10n.yes);
      await _waitForFiles(tester);

      final DateTime after = (await tester.runAsync(stored.lastModified))!;
      expect(after.isAfter(before), isTrue, reason: "it was written again");
      expect(find.byType(ProjectManagerWidget), findsNothing);
    });

    _flowTest("stays open when closed without a choice", (final WidgetTester tester) async
    {
      _hotkeys.triggerShortcut(action: HotkeyAction.generalOpen);
      await settleUi(tester);

      await tester.tap(find.descendant(of: find.byType(ProjectManagerWidget), matching: find.byTooltip(testL10n.close)));
      await settleUi(tester);

      expect(find.byType(ProjectManagerWidget), findsNothing);
    });
  });

  group("the export", ()
  {
    Future<List<String>> exported(final WidgetTester tester) async
    {
      final List<FileSystemEntity> files = (await tester.runAsync(() => Directory(_paths.exportDir).list().toList()))!;
      return <String>[for (final FileSystemEntity file in files) p.basename(file.path)];
    }

    Future<void> runExport(final WidgetTester tester, {final String? section}) async
    {
      await tester.runAsync(() async
      {
        await Directory(_paths.exportDir).create(recursive: true);
      });
      _hotkeys.triggerShortcut(action: HotkeyAction.generalExport);
      await settleUi(tester);
      if (section != null)
      {
        await tester.tap(find.byTooltip(section));
        await settleUi(tester);
      }
      await tester.enterText(find.descendant(of: find.byType(ExportWidget), matching: find.byType(TextField)).first, "out");
      await tester.pump();
      await tester.tap(find.byTooltip(testL10n.exportFile));
      await tester.pump();
    }

    Future<void> waitUntilGone(final WidgetTester tester) async
    {
      for (int i = 0; i < 80 && find.byType(ExportWidget).evaluate().isNotEmpty; i++)
      {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await settleUi(tester);
    }

    _flowTest("writes an image and says where", (final WidgetTester tester) async
    {
      await runExport(tester);
      await waitUntilGone(tester);

      expect(find.byType(ExportWidget), findsNothing);
      expect(await exported(tester), isNotEmpty);
      expect(find.textContaining(_paths.exportDir), findsOneWidget);
    });

    _flowTest("writes an animation", (final WidgetTester tester) async
    {
      await runExport(tester, section: testL10n.animation);
      await waitUntilGone(tester);

      expect(find.byType(ExportWidget), findsNothing);
      expect(await exported(tester), isNotEmpty);
    });

    _flowTest("writes a palette and says where", (final WidgetTester tester) async
    {
      await runExport(tester, section: testL10n.palette);
      await waitUntilGone(tester);

      expect(find.byType(ExportWidget), findsNothing);
      expect(await exported(tester), isNotEmpty);
      expect(find.textContaining(_paths.exportDir), findsOneWidget);
    });
  });

  group("importing an image", ()
  {
    Future<void> accept(final WidgetTester tester, {required final ui.Image image}) async
    {
      await _openMenu(tester, tooltip: testL10n.newOpenDot);
      await _pickFromMenu(tester, entry: testL10n.importImage);

      tester.widget<ImportWidget>(find.byType(ImportWidget)).import(importData: ImportData(
        filePath: "import.png",
        maxRamps: KPalConstraints.rampCountLimits.defaultValue,
        maxColors: KPalConstraints.colorCountLimits.defaultValue,
        image: image,
        includeReference: false,
        maxClusters: KPalConstraints.maxClusters,
        createNewPalette: true,
        scale: 1,
      ),);
      await tester.pump();
    }

    Future<ui.Image> anImage(final WidgetTester tester) async
    {
      final ui.Image? image = await tester.runAsync(() async
      {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = const Color(0xFF3355AA));
        return recorder.endRecording().toImage(4, 4);
      });
      return image!;
    }

    _flowTest("replaces the project and says so", (final WidgetTester tester) async
    {
      final ui.Image image = await anImage(tester);
      _session.hasChanges.value = false;

      await accept(tester, image: image);
      for (int i = 0; i < 6; i++)
      {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(ImportWidget), findsNothing);
      expect(find.text(testL10n.imageImportSuccessful), findsOneWidget);
      expect(GetIt.I.get<CanvasState>().canvasSize, CoordinateSetI(x: 4, y: 4));
      await tester.runAsync(settle);
      expect(image.debugDisposed, isTrue, reason: "the import owns the image and releases it");
    });

    _flowTest("says so when it fails", (final WidgetTester tester) async
    {
      final ui.Image image = await anImage(tester);
      _session.hasChanges.value = false;
      image.dispose();

      await accept(tester, image: image);
      for (int i = 0; i < 6; i++)
      {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text(testL10n.errorImportingImage), findsOneWidget);
    });
  });
}
