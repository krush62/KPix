import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

void main()
{
  Widget optionsApp(final SelectOptions options)
  {
    return ToastificationWrapper(child: MaterialApp(
      theme: monochromeTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: Center(child: SizedBox(
        width: 400,
        height: 500,
        child: Builder(builder: (final BuildContext context) => SelectOptions.getWidget(context: context, selectOptions: options)),
      ),),),
    ),);
  }

  /// Pumps the options on a booted project, runs [body] and tears it all down.
  void optionsTest(final String description, final Future<void> Function(WidgetTester tester, SelectOptions options, HotkeyManager hotkeys) body)
  {
    testWidgets(description, (final WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
      });
      final SelectOptions options = GetIt.I.get<ToolOptions>().selectOptions;
      final HotkeyManager hotkeys = GetIt.I.get<HotkeyManager>();

      await tester.pumpWidget(optionsApp(options));

      await body(tester, options, hotkeys);

      hotkeys.shiftNotifier.value = false;
      hotkeys.altNotifier.value = false;
      hotkeys.controlNotifier.value = false;
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

  Future<void> settle(final WidgetTester tester) async
  {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> hold(final WidgetTester tester, final HotkeyManager hotkeys, {final bool shift = false, final bool alt = false, final bool ctrl = false}) async
  {
    hotkeys.shiftNotifier.value = shift;
    hotkeys.altNotifier.value = alt;
    hotkeys.controlNotifier.value = ctrl;
    await settle(tester);
  }

  Future<void> tapMode(final WidgetTester tester, final SelectMode mode) async
  {
    final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(SegmentedButton<SelectMode>)))!;
    await tester.tap(find.byTooltip(mode.label(l10n)));
    await settle(tester);
  }

  Future<void> tapShape(final WidgetTester tester, final SelectShape shape) async
  {
    final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(SegmentedButton<SelectMode>)))!;
    await tester.tap(find.byTooltip(shape.label(l10n)));
    await settle(tester);
  }

  SegmentedButton<SelectMode> modeButton(final WidgetTester tester) => tester.widget(find.byType(SegmentedButton<SelectMode>));
  List<Switch> visibleSwitches(final WidgetTester tester) => tester.widgetList<Switch>(find.byType(Switch)).toList();

  group("the mode follows the modifiers", () {
    final Map<String, ({bool shift, bool alt, bool ctrl, SelectMode? forced})> combos = <String, ({bool shift, bool alt, bool ctrl, SelectMode? forced})>{
      "none": (shift: false, alt: false, ctrl: false, forced: null),
      "shift": (shift: true, alt: false, ctrl: false, forced: SelectMode.add),
      "shift + alt": (shift: true, alt: true, ctrl: false, forced: SelectMode.subtract),
      "shift + ctrl": (shift: true, alt: false, ctrl: true, forced: SelectMode.intersect),
      "shift + alt + ctrl": (shift: true, alt: true, ctrl: true, forced: null),
      "alt": (shift: false, alt: true, ctrl: false, forced: null),
      "ctrl": (shift: false, alt: false, ctrl: true, forced: null),
      "alt + ctrl": (shift: false, alt: true, ctrl: true, forced: null),
    };

    for (final MapEntry<String, ({bool shift, bool alt, bool ctrl, SelectMode? forced})> combo in combos.entries)
    {
      optionsTest("${combo.key} over each chosen mode", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
        for (final SelectMode chosen in SelectMode.values)
        {
          await tapMode(tester, chosen);
          await hold(tester, hotkeys, shift: combo.value.shift, alt: combo.value.alt, ctrl: combo.value.ctrl);

          final SelectMode expected = combo.value.forced ?? chosen;
          expect(options.mode.value, expected, reason: "chosen ${chosen.name}");
          expect(modeButton(tester).selected, <SelectMode>{expected}, reason: "chosen ${chosen.name}");
          expect(options.unModifiedMode.value, chosen, reason: "chosen ${chosen.name}");

          await hold(tester, hotkeys);
          expect(options.mode.value, chosen, reason: "released, chosen ${chosen.name}");
          expect(modeButton(tester).selected, <SelectMode>{chosen}, reason: "released, chosen ${chosen.name}");
        }
      });
    }
  });

  group("choosing a mode", () {
    optionsTest("without a modifier it is remembered", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      for (final SelectMode mode in SelectMode.values)
      {
        await tapMode(tester, mode);
        expect(options.mode.value, mode);
        expect(options.unModifiedMode.value, mode);
        expect(modeButton(tester).selected, <SelectMode>{mode});
      }
    });

    for (final ({String name, bool shift, bool alt, bool ctrl}) held in <({String name, bool shift, bool alt, bool ctrl})>[
      (name: "shift", shift: true, alt: false, ctrl: false),
      (name: "alt", shift: false, alt: true, ctrl: false),
      (name: "ctrl", shift: false, alt: false, ctrl: true),
    ])
    {
      optionsTest("with ${held.name} held it only lasts until the release", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
        await tapMode(tester, SelectMode.replace);
        await hold(tester, hotkeys, shift: held.shift, alt: held.alt, ctrl: held.ctrl);

        await tapMode(tester, SelectMode.subtract);
        expect(options.mode.value, SelectMode.subtract);
        expect(modeButton(tester).selected, <SelectMode>{SelectMode.subtract});
        expect(options.unModifiedMode.value, SelectMode.replace);

        await hold(tester, hotkeys);
        expect(options.mode.value, SelectMode.replace);
        expect(modeButton(tester).selected, <SelectMode>{SelectMode.replace});
      });
    }

    optionsTest("with a modifier held can return to what the modifier sets", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await hold(tester, hotkeys, shift: true);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.add});

      await tapMode(tester, SelectMode.replace);
      expect(options.mode.value, SelectMode.replace);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.replace});

      await tapMode(tester, SelectMode.add);
      expect(options.mode.value, SelectMode.add);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.add});
      expect(options.unModifiedMode.value, SelectMode.replace);
    });

    optionsTest("with a modifier held gives way when the modifiers change", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await hold(tester, hotkeys, shift: true);
      await tapMode(tester, SelectMode.intersect);

      await hold(tester, hotkeys, shift: true, alt: true);
      expect(options.mode.value, SelectMode.subtract);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.subtract});

      await hold(tester, hotkeys, shift: true);
      expect(options.mode.value, SelectMode.add);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.add});
    });

    optionsTest("with a modifier held survives a rebuild of the options", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await hold(tester, hotkeys, alt: true);
      await tapMode(tester, SelectMode.intersect);

      final SegmentedButton<SelectMode> before = modeButton(tester);
      await tester.pumpWidget(optionsApp(options));
      await settle(tester);
      expect(identical(modeButton(tester), before), false);
      expect(options.mode.value, SelectMode.intersect);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.intersect});
    });

    optionsTest("the default selection tool resets it", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await tapMode(tester, SelectMode.subtract);

      GetIt.I.get<ToolState>().setDefaultSelectionTool();
      await settle(tester);
      expect(options.mode.value, SelectConstraints.modeDefault);
      expect(options.unModifiedMode.value, SelectConstraints.modeDefault);
      expect(modeButton(tester).selected, <SelectMode>{SelectConstraints.modeDefault});
    });

    optionsTest("the default selection tool wins over held modifiers until they change", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await hold(tester, hotkeys, shift: true);

      GetIt.I.get<ToolState>().setDefaultSelectionTool();
      await settle(tester);
      expect(options.mode.value, SelectConstraints.modeDefault);
      expect(modeButton(tester).selected, <SelectMode>{SelectConstraints.modeDefault});

      await hold(tester, hotkeys, shift: true, alt: true);
      expect(options.mode.value, SelectMode.subtract);
    });

    optionsTest("from outside shows up unless modifiers are held", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      options.unModifiedMode.value = SelectMode.intersect;
      await settle(tester);
      expect(options.mode.value, SelectMode.intersect);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.intersect});

      await hold(tester, hotkeys, shift: true, alt: true);
      options.unModifiedMode.value = SelectMode.add;
      await settle(tester);
      expect(options.mode.value, SelectMode.subtract, reason: "the modifiers still win");
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.subtract});

      await hold(tester, hotkeys);
      expect(options.mode.value, SelectMode.add);
    });

    optionsTest("offers every mode with its tooltip and icon", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(SegmentedButton<SelectMode>)))!;
      final SegmentedButton<SelectMode> button = modeButton(tester);
      expect(button.segments.map((final ButtonSegment<SelectMode> s) => s.value), SelectMode.values);
      expect(button.showSelectedIcon, false);
      for (final ButtonSegment<SelectMode> segment in button.segments)
      {
        expect(segment.tooltip, segment.value.label(l10n));
        expect((segment.icon! as Icon).icon, segment.value.icon);
      }
    });
  });

  group("without the options on screen", () {
    optionsTest("the mode follows the modifiers", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await tester.pumpWidget(const SizedBox.shrink());

      hotkeys.shiftNotifier.value = true;
      expect(options.mode.value, SelectMode.add);
      hotkeys.altNotifier.value = true;
      expect(options.mode.value, SelectMode.subtract);
      hotkeys.altNotifier.value = false;
      hotkeys.controlNotifier.value = true;
      expect(options.mode.value, SelectMode.intersect);
      hotkeys.shiftNotifier.value = false;
      hotkeys.controlNotifier.value = false;
      expect(options.mode.value, SelectMode.replace);
    });

    optionsTest("the mode follows the chosen mode", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await tester.pumpWidget(const SizedBox.shrink());

      options.unModifiedMode.value = SelectMode.subtract;
      expect(options.mode.value, SelectMode.subtract);
      hotkeys.shiftNotifier.value = true;
      expect(options.mode.value, SelectMode.add);
      hotkeys.shiftNotifier.value = false;
      expect(options.mode.value, SelectMode.subtract);
    });

    optionsTest("the options show what changed meanwhile", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await tester.pumpWidget(const SizedBox.shrink());
      hotkeys.shiftNotifier.value = true;

      await tester.pumpWidget(optionsApp(options));
      await settle(tester);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.add});

      await hold(tester, hotkeys);
      expect(modeButton(tester).selected, <SelectMode>{SelectMode.replace});
    });

    optionsTest("a new selection uses the modifiers", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final SelectionState selection = GetIt.I.get<DocumentState>().selectionState;

      void select(final int from, final int to)
      {
        selection.newSelectionFromShape(start: CoordinateSetI(x: from, y: from), end: CoordinateSetI(x: to, y: to), selectShape: SelectShape.rectangle, notify: false, addToHistoryStack: false);
      }

      select(0, 1);
      hotkeys.shiftNotifier.value = true;
      select(3, 4);
      hotkeys.shiftNotifier.value = false;
      expect(selection.selection.contains(coord: CoordinateSetI(x: 0, y: 0)), true);
      expect(selection.selection.contains(coord: CoordinateSetI(x: 3, y: 3)), true);

      select(6, 7);
      expect(selection.selection.contains(coord: CoordinateSetI(x: 0, y: 0)), false);
      expect(selection.selection.contains(coord: CoordinateSetI(x: 3, y: 3)), false);
      expect(selection.selection.contains(coord: CoordinateSetI(x: 6, y: 6)), true);
    });
  });

  group("the buttons rebuild when the mode changes", () {
    optionsTest("through a modifier", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final SegmentedButton<SelectMode> before = modeButton(tester);
      hotkeys.shiftNotifier.value = true;
      await settle(tester);
      expect(identical(modeButton(tester), before), false);
    });

    optionsTest("through the chosen mode", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final SegmentedButton<SelectMode> before = modeButton(tester);
      options.unModifiedMode.value = SelectMode.add;
      await settle(tester);
      expect(identical(modeButton(tester), before), false);
    });

    optionsTest("through a tap with a modifier held", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await hold(tester, hotkeys, alt: true);
      final SegmentedButton<SelectMode> before = modeButton(tester);
      await tapMode(tester, SelectMode.add);
      expect(identical(modeButton(tester), before), false);
    });

    optionsTest("not through modifiers that leave it alone", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final SegmentedButton<SelectMode> before = modeButton(tester);
      await hold(tester, hotkeys, alt: true);
      await hold(tester, hotkeys, ctrl: true);
      await hold(tester, hotkeys, alt: true, ctrl: true);
      await hold(tester, hotkeys);
      expect(identical(modeButton(tester), before), true);
    });

    optionsTest("not through the switches or the shape", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final SegmentedButton<SelectMode> before = modeButton(tester);
      options.keepAspectRatio.value = !options.keepAspectRatio.value;
      options.shape.value = SelectShape.wand;
      await settle(tester);
      expect(identical(modeButton(tester), before), true);
    });

    optionsTest("modifiers keep the switch rows untouched", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final Switch before = visibleSwitches(tester).first;
      await hold(tester, hotkeys, shift: true);
      expect(identical(visibleSwitches(tester).first, before), true);
    });
  });

  group("switches", () {
    optionsTest("a rectangle or ellipse offers 1:1", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(SegmentedButton<SelectMode>)))!;
      for (final SelectShape shape in <SelectShape>[SelectShape.rectangle, SelectShape.ellipse])
      {
        await tapShape(tester, shape);
        expect(find.text(l10n.keep1to1), findsOneWidget);
        expect(find.text(l10n.continuous), findsNothing);
        expect(find.text(l10n.wholeRamp), findsNothing);
        expect(visibleSwitches(tester).length, 1);

        final bool wasContinuous = options.wandContinuous.value;
        final bool keep = options.keepAspectRatio.value;
        expect(visibleSwitches(tester).first.value, keep);

        await tester.tap(find.byType(Switch).first);
        await settle(tester);
        expect(options.keepAspectRatio.value, !keep);
        expect(visibleSwitches(tester).first.value, !keep);
        expect(options.wandContinuous.value, wasContinuous);

        options.keepAspectRatio.value = keep;
        await settle(tester);
        expect(visibleSwitches(tester).first.value, keep);
      }
    });

    optionsTest("a polygon offers none", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(SegmentedButton<SelectMode>)))!;
      await tapShape(tester, SelectShape.polygon);
      expect(find.text(l10n.keep1to1), findsNothing);
      expect(find.text(l10n.continuous), findsNothing);
      expect(find.text(l10n.wholeRamp), findsNothing);
      expect(visibleSwitches(tester), isEmpty);
    });

    optionsTest("a wand offers continuous and whole ramp", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(SegmentedButton<SelectMode>)))!;
      await tapShape(tester, SelectShape.wand);
      expect(find.text(l10n.continuous), findsOneWidget);
      expect(find.text(l10n.wholeRamp), findsOneWidget);
      expect(find.text(l10n.keep1to1), findsNothing);
      expect(visibleSwitches(tester).length, 2);

      final bool keep = options.keepAspectRatio.value;
      final bool continuous = options.wandContinuous.value;
      final bool whole = options.wandWholeRamp.value;
      expect(visibleSwitches(tester)[0].value, continuous);
      expect(visibleSwitches(tester)[1].value, whole);

      await tester.tap(find.byType(Switch).at(0));
      await settle(tester);
      expect(options.wandContinuous.value, !continuous);
      expect(visibleSwitches(tester)[0].value, !continuous);
      expect(options.wandWholeRamp.value, whole);
      expect(options.keepAspectRatio.value, keep);

      await tester.tap(find.byType(Switch).at(1));
      await settle(tester);
      expect(options.wandWholeRamp.value, !whole);
      expect(visibleSwitches(tester)[1].value, !whole);

      options.wandContinuous.value = continuous;
      options.wandWholeRamp.value = whole;
      await settle(tester);
      expect(visibleSwitches(tester)[0].value, continuous);
      expect(visibleSwitches(tester)[1].value, whole);
    });

    optionsTest("the hidden switch still follows its value", (final WidgetTester tester, final SelectOptions options, final HotkeyManager hotkeys) async {
      await tapShape(tester, SelectShape.rectangle);
      final bool continuous = options.wandContinuous.value;
      options.wandContinuous.value = !continuous;
      await settle(tester);
      await tapShape(tester, SelectShape.wand);
      expect(visibleSwitches(tester)[0].value, !continuous);
      options.wandContinuous.value = continuous;
    });
  });
}
