import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/main/main_button_widget.dart';
import 'package:kpix/widgets/tools/shader_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

const List<HotkeyAction> _mainButtonActions = <HotkeyAction>[
  HotkeyAction.generalOpen,
  HotkeyAction.generalSave,
  HotkeyAction.generalSaveAs,
  HotkeyAction.generalNew,
  HotkeyAction.generalUndo,
  HotkeyAction.generalRedo,
  HotkeyAction.generalExport,
];

Widget _app(final Widget child)
{
  return ToastificationWrapper(child: MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: Center(child: SizedBox(width: 400, height: 300, child: child))),
  ),);
}

void _hotkeyTest(final String description, final Future<void> Function(WidgetTester tester, HotkeyManager hotkeys) body)
{
  testWidgets(description, (final WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
    });

    await body(tester, GetIt.I.get<HotkeyManager>());

    await tester.pumpWidget(const SizedBox.shrink());
    for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      for (int i = 0; i < frame.layerList.length; i++)
      {
        frame.layerList.getLayer(index: i).dispose();
      }
    }
    await tester.pump(const Duration(seconds: 1));
  });
}

void main()
{
  group("the shader options", () {
    const Widget shader = ShaderWidget(titleStyle: TextStyle(fontSize: 16), labelStyle: TextStyle(fontSize: 12));

    final List<({HotkeyAction action, Object Function(ShaderOptions) read})> shortcuts = <({HotkeyAction action, Object Function(ShaderOptions) read})>[
      (action: HotkeyAction.shadingToggle, read: (final ShaderOptions o) => o.isEnabled.value),
      (action: HotkeyAction.shadingCurrentRampOnly, read: (final ShaderOptions o) => o.onlyCurrentRampEnabled.value),
      (action: HotkeyAction.shadingDirection, read: (final ShaderOptions o) => o.shaderDirection.value),
    ];

    for (final ({HotkeyAction action, Object Function(ShaderOptions) read}) shortcut in shortcuts)
    {
      _hotkeyTest("${shortcut.action.name} works while they show", (final WidgetTester tester, final HotkeyManager hotkeys) async {
        final ShaderOptions options = GetIt.I.get<ShaderOptions>();
        await tester.pumpWidget(_app(shader));
        final Object before = shortcut.read(options);
        hotkeys.triggerShortcut(action: shortcut.action);
        expect(shortcut.read(options), isNot(before));
      });

      _hotkeyTest("${shortcut.action.name} stops working once they are gone", (final WidgetTester tester, final HotkeyManager hotkeys) async {
        final ShaderOptions options = GetIt.I.get<ShaderOptions>();
        await tester.pumpWidget(_app(shader));
        await tester.pumpWidget(const SizedBox.shrink());
        final Object before = shortcut.read(options);
        hotkeys.triggerShortcut(action: shortcut.action);
        expect(shortcut.read(options), before);
      });

      _hotkeyTest("${shortcut.action.name} works once after they came back", (final WidgetTester tester, final HotkeyManager hotkeys) async {
        final ShaderOptions options = GetIt.I.get<ShaderOptions>();
        await tester.pumpWidget(_app(shader));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(_app(shader));
        final Object before = shortcut.read(options);
        hotkeys.triggerShortcut(action: shortcut.action);
        expect(shortcut.read(options), isNot(before), reason: "toggled twice would look untouched");
      });
    }
  });

  group("the main buttons", () {
    const Widget buttons = MainButtonWidget();

    void addHistory(final int count)
    {
      final HistoryManager history = GetIt.I.get<HistoryManager>();
      for (int i = 0; i < count; i++)
      {
        history.addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: GetIt.I.get<DocumentState>().timeline.getCurrentLayer());
      }
    }

    //lets the restore settle and the toast about it time out
    Future<void> finishUndo(final WidgetTester tester) async
    {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
    }

    for (final HotkeyAction action in _mainButtonActions)
    {
      _hotkeyTest("${action.name} is ignored once they are gone", (final WidgetTester tester, final HotkeyManager hotkeys) async {
        await tester.pumpWidget(_app(buttons));
        await tester.pumpWidget(_app(const SizedBox.shrink()));
        hotkeys.triggerShortcut(action: action);
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    _hotkeyTest("new closes the project while they show", (final WidgetTester tester, final HotkeyManager hotkeys) async {
      await tester.pumpWidget(_app(buttons));
      hotkeys.triggerShortcut(action: HotkeyAction.generalNew);
      expect(GetIt.I.get<ProjectSession>().hasProject, false);
      GetIt.I.get<ProjectSession>().hasProjectNotifier.value = true;
    });

    _hotkeyTest("new leaves the project alone once they are gone", (final WidgetTester tester, final HotkeyManager hotkeys) async {
      await tester.pumpWidget(_app(buttons));
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      hotkeys.triggerShortcut(action: HotkeyAction.generalNew);
      expect(GetIt.I.get<ProjectSession>().hasProject, true);
    });

    _hotkeyTest("redo does nothing once they are gone", (final WidgetTester tester, final HotkeyManager hotkeys) async {
      addHistory(2);
      await tester.pumpWidget(_app(buttons));
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      GetIt.I.get<HistoryController>().undoPressed();
      expect(GetIt.I.get<HistoryManager>().hasRedo.value, true);
      hotkeys.triggerShortcut(action: HotkeyAction.generalRedo);
      expect(GetIt.I.get<HistoryManager>().hasRedo.value, true);
      await finishUndo(tester);
    });

    _hotkeyTest("undo goes one step while they show", (final WidgetTester tester, final HotkeyManager hotkeys) async {
      addHistory(3);
      await tester.pumpWidget(_app(buttons));
      hotkeys.triggerShortcut(action: HotkeyAction.generalUndo);
      await tester.pump();
      expect(GetIt.I.get<HistoryManager>().hasUndo.value, true);
      expect(GetIt.I.get<HistoryManager>().hasRedo.value, true);
      await finishUndo(tester);
    });

    _hotkeyTest("undo does nothing once they are gone", (final WidgetTester tester, final HotkeyManager hotkeys) async {
      addHistory(1);
      await tester.pumpWidget(_app(buttons));
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      hotkeys.triggerShortcut(action: HotkeyAction.generalUndo);
      await tester.pump();
      expect(GetIt.I.get<HistoryManager>().hasRedo.value, false);
    });

    _hotkeyTest("undo goes one step after they came back", (final WidgetTester tester, final HotkeyManager hotkeys) async {
      addHistory(3);
      await tester.pumpWidget(_app(buttons));
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await tester.pumpWidget(_app(buttons));
      hotkeys.triggerShortcut(action: HotkeyAction.generalUndo);
      await tester.pump();
      expect(GetIt.I.get<HistoryManager>().hasUndo.value, true, reason: "two listeners would undo both steps");
      await finishUndo(tester);
    });
  });
}
