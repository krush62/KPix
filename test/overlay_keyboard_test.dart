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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

import 'support/selection_harness.dart';

const Key _hostKey = Key("host");

/// Pumps an empty app and returns a context below its [Overlay].
Future<BuildContext> _pumpHost(final WidgetTester tester) async
{
  await tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: SizedBox.expand(key: _hostKey)),
    ),
  );
  return tester.element(find.byKey(_hostKey));
}

KPixOverlay _overlay({final Function()? onEscape, final Function()? onEnter, final Widget child = const SizedBox.shrink()})
{
  return KPixOverlay(
    onEscape: onEscape,
    onEnter: onEnter,
    entry: OverlayEntry(builder: (final BuildContext context) => Material(child: child)),
  );
}

/// Takes the widgets down and releases the layers of a booted project, whose
/// raster timer would otherwise still be pending when the test ends.
Future<void> _releaseProject(final WidgetTester tester) async
{
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump();
}

void main()
{
  setUp(() {
    GetIt.I.registerSingleton<HotkeyManager>(HotkeyManager());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group("escape key", ()
  {
    testWidgets("escape calls the cancel action of a shown dialog", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int yes = 0;
      int no = 0;
      late final KPixOverlay dialog;
      dialog = getTwoButtonDialog(
        onYes: () {yes++; dialog.hide();},
        onNo: () {no++; dialog.hide();},
        outsideCancelable: false,
        message: (final AppLocalizations _) => "delete?",
      );
      dialog.show(context: context);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(no, 1);
      expect(yes, 0);
      expect(dialog.isVisible, isFalse);
    });

    testWidgets("escape only reaches the topmost overlay", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      final List<String> calls = <String>[];
      late final KPixOverlay outer;
      late final KPixOverlay inner;
      outer = _overlay(onEscape: () {calls.add("outer"); outer.hide();});
      inner = _overlay(onEscape: () {calls.add("inner"); inner.hide();});
      outer.show(context: context);
      inner.show(context: context);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(calls, <String>["inner"]);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(calls, <String>["inner", "outer"]);
    });

    testWidgets("a topmost overlay without a cancel action keeps the ones below open", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int outerCalls = 0;
      final KPixOverlay outer = _overlay(onEscape: () {outerCalls++;});
      final KPixOverlay loading = getLoadingDialog(message: (final AppLocalizations _) => "loading");
      outer.show(context: context);
      loading.show(context: context);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(outerCalls, 0);
      expect(loading.isVisible, isTrue);

      loading.hide();
      outer.hide();
      await tester.pump();
    });

    testWidgets("escape does nothing once the overlay is hidden", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int calls = 0;
      final KPixOverlay overlay = _overlay(onEscape: () {calls++;});
      overlay.show(context: context);
      await tester.pump();
      overlay.hide();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(calls, 0);
    });

    testWidgets("escape cancels while a text field of the dialog has focus", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int dismissed = 0;
      int accepted = 0;
      late final KPixOverlay dialog;
      dialog = getChangeTextToolDialog(
        onDismiss: () {dismissed++; dialog.hide();},
        onAccept: ({required final String newText}) {accepted++;},
        initialText: "abc",
      );
      dialog.show(context: context);
      await tester.pump(const Duration(milliseconds: 200));
      GetIt.I.get<HotkeyManager>().getFocusNode(id: FocusNodeEntry.changeTextToolFocus).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(dismissed, 1);
      expect(accepted, 0);
      expect(dialog.isVisible, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets("escape closes the add layer and align menus instead of reaching the hotkeys", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      final HotkeyManager manager = GetIt.I.get<HotkeyManager>();
      final GlobalKey anchorKey = GlobalKey();

      late final KPixOverlay addLayerMenu;
      addLayerMenu = getAddNewLayerMenu(
        onDismiss: () {addLayerMenu.hide();},
        onNewDrawingLayer: () {},
        onNewReferenceLayer: () {},
        onNewGridLayer: () {},
        onNewShadingLayer: () {},
        onNewDitherLayer: () {},
        anchorKey: anchorKey,
      );
      late final KPixOverlay alignMenu;
      alignMenu = getSelectionAlignMenu(
        onDismiss: () {alignMenu.hide();},
        onAlignLeft: () {},
        onAlignRight: () {},
        onAlignTop: () {},
        onAlignBottom: () {},
        onAlignCenterH: () {},
        onAlignCenterV: () {},
        anchorKey: anchorKey,
      );

      for (final KPixOverlay menu in <KPixOverlay>[addLayerMenu, alignMenu])
      {
        menu.show(context: context);
        await tester.pump();
        //with the hotkeys off, Escape cannot deselect as well
        expect(manager.callbackMap, isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(menu.isVisible, isFalse);
        expect(manager.callbackMap, isNotEmpty);
      }
    });

    testWidgets("the hotkeys are active again after escape closed the dialog", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      final HotkeyManager manager = GetIt.I.get<HotkeyManager>();
      late final KPixOverlay overlay;
      overlay = _overlay(onEscape: () {overlay.hide();});
      overlay.show(context: context);
      await tester.pump();
      expect(manager.callbackMap, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(manager.callbackMap, isNotEmpty);
    });
  });

  group("enter key", ()
  {
    testWidgets("enter confirms a single button dialog", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int calls = 0;
      late final KPixOverlay dialog;
      dialog = getSingleButtonDialog(onAction: () {calls++; dialog.hide();}, message: (final AppLocalizations _) => "done");
      dialog.show(context: context);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, 1);
      expect(dialog.isVisible, isFalse);
    });

    testWidgets("the numpad enter works like enter", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int calls = 0;
      late final KPixOverlay overlay;
      overlay = _overlay(onEnter: () {calls++; overlay.hide();});
      overlay.show(context: context);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      expect(calls, 1);
    });

    testWidgets("enter leaves yes/no and yes/no/cancel dialogs open", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      final List<String> calls = <String>[];
      final KPixOverlay twoButtons = getTwoButtonDialog(
        onYes: () {calls.add("yes");},
        onNo: () {calls.add("no");},
        outsideCancelable: true,
        message: (final AppLocalizations _) => "delete?",
      );
      final KPixOverlay threeButtons = getThreeButtonDialog(
        onYes: () {calls.add("yes");},
        onNo: () {calls.add("no");},
        onCancel: () {calls.add("cancel");},
        outsideCancelable: true,
        message: (final AppLocalizations _) => "save first?",
      );

      twoButtons.show(context: context);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(twoButtons.isVisible, isTrue);
      twoButtons.hide();

      threeButtons.show(context: context);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(threeButtons.isVisible, isTrue);
      threeButtons.hide();

      expect(calls, isEmpty);
      await tester.pump();
    });

    testWidgets("enter only reaches the topmost overlay", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int outerCalls = 0;
      final KPixOverlay outer = _overlay(onEnter: () {outerCalls++;});
      //e.g. the delete confirmation on top of the ramp editor
      final KPixOverlay confirmation = getTwoButtonDialog(onYes: () {}, onNo: () {}, outsideCancelable: false, message: (final AppLocalizations _) => "delete?");
      outer.show(context: context);
      confirmation.show(context: context);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(outerCalls, 0);

      confirmation.hide();
      outer.hide();
      await tester.pump();
    });

    testWidgets("a focused button keeps enter for itself", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      final FocusNode buttonFocus = FocusNode();
      addTearDown(buttonFocus.dispose);
      int pressed = 0;
      int entered = 0;
      final KPixOverlay overlay = _overlay(
        onEnter: () {entered++;},
        child: TextButton(focusNode: buttonFocus, onPressed: () {pressed++;}, child: const Text("button")),
      );
      overlay.show(context: context);
      await tester.pump();
      buttonFocus.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 1);
      expect(entered, 0);

      overlay.hide();
      await tester.pump();
    });

    testWidgets("enter with a modifier is ignored", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      int calls = 0;
      final KPixOverlay overlay = _overlay(onEnter: () {calls++;});
      overlay.show(context: context);
      await tester.pump();

      for (final LogicalKeyboardKey modifier in <LogicalKeyboardKey>[LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.altLeft, LogicalKeyboardKey.metaLeft])
      {
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(modifier);
      }
      expect(calls, 0);

      overlay.hide();
      await tester.pump();
    });

    testWidgets("enter applies the text tool dialog from its text field, unless the text is blank", (final WidgetTester tester) async {
      final BuildContext context = await _pumpHost(tester);
      final List<String> accepted = <String>[];
      late final KPixOverlay dialog;
      dialog = getChangeTextToolDialog(
        onDismiss: () {dialog.hide();},
        onAccept: ({required final String newText}) {accepted.add(newText); dialog.hide();},
        initialText: "abc",
      );
      dialog.show(context: context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(TextField), "   ");
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(accepted, isEmpty);
      expect(dialog.isVisible, isTrue);

      await tester.enterText(find.byType(TextField), "hello");
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(accepted, <String>["hello"]);
      expect(dialog.isVisible, isFalse);
    });

    testWidgets("enter creates the new project with the entered size", (final WidgetTester tester) async {
      //the square glyphs of the test font make the dialog overflow its maximum height
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final BuildContext context = await _pumpHost(tester);
      final List<CoordinateSetI> created = <CoordinateSetI>[];
      late final KPixOverlay dialog;
      dialog = getNewProjectDialog(
        onDismiss: null,
        onAccept: ({required final CoordinateSetI size}) {created.add(size); dialog.hide();},
        onOpen: () {},
      );
      dialog.show(context: context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(TextField).first, "100");
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(created, hasLength(1));
      expect(created.single.x, 100);
      expect(dialog.isVisible, isFalse);
    });

    testWidgets("enter never lets the save as dialog overwrite a project", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4));
      });
      final Directory projectsDir = Directory.systemTemp.createTempSync("kpix_save_as_");
      addTearDown(() {projectsDir.deleteSync(recursive: true);});
      File("${projectsDir.path}${Platform.pathSeparator}taken.kpix").writeAsStringSync("");
      GetIt.I.get<AppPaths>().projectsDir = projectsDir.path;

      final BuildContext context = await _pumpHost(tester);
      final List<String> saved = <String>[];
      late final KPixOverlay dialog;
      dialog = getSaveAsDialog(
        onDismiss: () {dialog.hide();},
        onAccept: ({required final String fileName, required final Function()? callback}) {saved.add(fileName); dialog.hide();},
      );

      dialog.show(context: context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), "taken");
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(saved, isEmpty);
      expect(dialog.isVisible, isTrue);

      //the button still overwrites
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(TextField)))!;
      await tester.tap(find.byTooltip(l10n.saveProject));
      await tester.pump();
      expect(saved, <String>["taken"]);

      dialog.show(context: context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), "fresh");
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(saved, <String>["taken", "fresh"]);
      expect(dialog.isVisible, isFalse);

      await _releaseProject(tester);
    });
  });
}
