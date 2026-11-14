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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/extra/preferences_widget.dart';
import 'package:kpix/widgets/preferences/behavior_preferences.dart';
import 'package:kpix/widgets/preferences/desktop_preferences.dart';
import 'package:kpix/widgets/preferences/gui_preferences.dart';
import 'package:kpix/widgets/preferences/stylus_preferences.dart';
import 'package:kpix/widgets/preferences/touch_preferences.dart';
import 'package:material_ui/material_ui.dart';

import 'support/widget_harness.dart';

PreferenceManager get _prefs => GetIt.I.get<PreferenceManager>();

class _FakePicker extends FilePickerPlatform
{
  String? answer;

  @override
  Future<String?> getDirectoryPath({
    final String? dialogTitle,
    final String? initialDirectory,
    final AndroidOptions androidOptions = const AndroidOptions(),
    final WindowsOptions windowsOptions = const WindowsOptions(),
    final LinuxOptions linuxOptions = const LinuxOptions(),
    final WebOptions webOptions = const WebOptions(),
  }) async => answer;
}

int _accepted = 0;
int _dismissed = 0;

Widget _preferences()
{
  _accepted = 0;
  _dismissed = 0;
  return Center(child: PreferencesWidget(accept: () {_accepted++;}, dismiss: () {_dismissed++;}));
}

Future<void> _openSection(final WidgetTester tester, final PreferenceSectionType section) async
{
  tester.widget<SegmentedButton<PreferenceSectionType>>(find.byType(SegmentedButton<PreferenceSectionType>)).onSelectionChanged!(<PreferenceSectionType>{section});
  await settleUi(tester);
}

KPixSlider _sliderOf(final WidgetTester tester, final String label)
{
  final Finder row = find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  return tester.widget<KPixSlider>(find.descendant(of: row, matching: find.byType(KPixSlider)));
}

void main()
{
  group("the preferences", ()
  {
    for (final (PreferenceSectionType, Type) entry in <(PreferenceSectionType, Type)>[
      (PreferenceSectionType.gui, GuiPreferences),
      (PreferenceSectionType.behavior, BehaviorPreferences),
      (PreferenceSectionType.controlsPC, DesktopPreferences),
      (PreferenceSectionType.controlsStylus, StylusPreferences),
      (PreferenceSectionType.controlsTouch, TouchPreferences),
    ])
    {
      projectWidgetTest("show their ${entry.$1.name} section", _preferences, (final WidgetTester tester) async
      {
        await _openSection(tester, entry.$1);

        expect(find.byType(entry.$2), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    projectWidgetTest("name all sections", _preferences, (final WidgetTester tester) async
    {
      expect(getPreferenceMap(testL10n).keys.toSet(), PreferenceSectionType.values.toSet());
      for (final PreferenceSectionType section in PreferenceSectionType.values)
      {
        expect(preferenceTitle(l10n: testL10n, type: section), isNotEmpty);
      }
    });

    projectWidgetTest("say when they are accepted or dismissed", _preferences, (final WidgetTester tester) async
    {
      await tapTooltip(tester, testL10n.apply);
      expect(_accepted, 1);

      await tapTooltip(tester, testL10n.cancel);
      expect(_dismissed, 1);
    });
  });

  group("the gui section", ()
  {
    projectWidgetTest("hands its controls on", _preferences, (final WidgetTester tester) async
    {
      final GuiPreferenceContent gui = _prefs.guiPreferenceContent;
      final Finder sliders = find.byType(KPixSlider, skipOffstage: false);
      expect(sliders.evaluate().length, greaterThanOrEqualTo(4));

      tester.widget<KPixSlider>(sliders.at(1)).onChanged!(gui.rasterContrast.value == 10 ? 20 : 10);
      await tester.pump();
      expect(gui.rasterContrast.value, isIn(<int>[10, 20]));

      tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>)).onSelectionChanged!(<ThemeMode>{ThemeMode.dark});
      await tester.pump();
      expect(gui.themeType.value, ThemeMode.dark);
    });

    projectWidgetTest("only lets the side of the cursor info be changed while it shows", _preferences, (final WidgetTester tester) async
    {
      final GuiPreferenceContent gui = _prefs.guiPreferenceContent;
      Switch side() => tester.widget<Switch>(find.byType(Switch, skipOffstage: false).last);

      gui.showCursorInfo.value = false;
      await tester.pump();
      expect(side().onChanged, isNull);

      gui.showCursorInfo.value = true;
      await tester.pump();
      expect(side().onChanged, isNotNull);
    });
  });

  group("the behavior section", ()
  {
    BehaviorPreferenceContent behavior() => _prefs.behaviorPreferenceContent;
    late _FakePicker picker;

    Future<void> open(final WidgetTester tester) async
    {
      picker = _FakePicker();
      FilePickerPlatform.instance = picker;
      await _openSection(tester, PreferenceSectionType.behavior);
    }

    projectWidgetTest("hands its sliders and switches on", _preferences, (final WidgetTester tester) async
    {
      await open(tester);

      _sliderOf(tester, testL10n.undoSteps).onChanged!(behavior().undoSteps.min + 5.0);
      await tester.pump();
      expect(behavior().undoSteps.value, behavior().undoSteps.min + 5);

      final bool selectInserted = behavior().selectLayerAfterInsert.value;
      await tester.tap(find.descendant(of: find.ancestor(of: find.text(testL10n.selectInsertedLayers), matching: find.byType(Row)).first, matching: find.byType(Switch)));
      await tester.pump();
      expect(behavior().selectLayerAfterInsert.value, !selectInserted);
    });

    projectWidgetTest("asks for a directory when going custom without one", _preferences, (final WidgetTester tester) async
    {
      await open(tester);
      final Directory chosen = (await tester.runAsync(() => Directory.systemTemp.createTemp("kpix_prefs_test")))!;
      addTearDown(() => chosen.delete(recursive: true));
      picker.answer = chosen.path;

      await tester.tap(find.text(testL10n.customDir));
      await settleUi(tester);

      expect(behavior().customProjectDirectory.value, chosen.path);
      expect(behavior().useCustomProjectDirectory.value, isTrue);
    });

    projectWidgetTest("stays with the default when no directory was chosen", _preferences, (final WidgetTester tester) async
    {
      await open(tester);
      picker.answer = null;

      await tester.tap(find.text(testL10n.customDir));
      await settleUi(tester);

      expect(behavior().useCustomProjectDirectory.value, isFalse);
    });

    projectWidgetTest("refuses a directory it cannot write to", _preferences, (final WidgetTester tester) async
    {
      await open(tester);
      picker.answer = "${Directory.systemTemp.path}${Platform.pathSeparator}kpix does not exist";

      await tester.tap(find.byTooltip(testL10n.chooseDirectory));
      await settleUi(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(behavior().useCustomProjectDirectory.value, isFalse);
      expect(find.text(testL10n.insufficientPermissionsForDir), findsOneWidget);
    });

    projectWidgetTest("goes back and forth once a directory is known", _preferences, (final WidgetTester tester) async
    {
      await open(tester);
      behavior().customProjectDirectory.value = "somewhere";
      await tester.pump();

      await tester.tap(find.text(testL10n.customDir));
      await tester.pump();
      expect(behavior().useCustomProjectDirectory.value, isTrue);

      await tester.tap(find.text(testL10n.defaultDir));
      await tester.pump();
      expect(behavior().useCustomProjectDirectory.value, isFalse);

      await tester.tap(find.byType(Radio<bool>).last);
      await tester.pump();
      expect(behavior().useCustomProjectDirectory.value, isTrue);
    });
  });

  group("the stylus section", ()
  {
    projectWidgetTest("hands its sliders on", _preferences, (final WidgetTester tester) async
    {
      final StylusPreferenceContent stylus = _prefs.stylusPreferenceContent;
      await _openSection(tester, PreferenceSectionType.controlsStylus);
      final List<KPixSlider> sliders = tester.widgetList<KPixSlider>(find.byType(KPixSlider)).toList();
      expect(sliders, hasLength(5));

      sliders[0].onChanged!(stylus.stylusLongPressDelay.max.toDouble());
      sliders[1].onChanged!(stylus.stylusLongPressCancelDistance.max);
      sliders[2].onChanged!(stylus.stylusZoomStepDistance.max);
      sliders[3].onChanged!(stylus.stylusSizeStepDistance.max);
      sliders[4].onChanged!(stylus.stylusPickMaxDuration.max.toDouble());

      expect(stylus.stylusLongPressDelay.value, stylus.stylusLongPressDelay.max);
      expect(stylus.stylusLongPressCancelDistance.value, stylus.stylusLongPressCancelDistance.max);
      expect(stylus.stylusZoomStepDistance.value, stylus.stylusZoomStepDistance.max);
      expect(stylus.stylusSizeStepDistance.value, stylus.stylusSizeStepDistance.max);
      expect(stylus.stylusPickMaxDuration.value, stylus.stylusPickMaxDuration.max);
    });
  });

  group("the touch section", ()
  {
    projectWidgetTest("hands its controls on", _preferences, (final WidgetTester tester) async
    {
      final TouchPreferenceContent touch = _prefs.touchPreferenceContent;
      await _openSection(tester, PreferenceSectionType.controlsTouch);
      final List<KPixSlider> sliders = tester.widgetList<KPixSlider>(find.byType(KPixSlider)).toList();
      final bool joysticks = touch.showJoysticks.value;

      sliders[0].onChanged!(touch.singleTouchDelay.max.toDouble());
      sliders[1].onChanged!(touch.zoomStepDistance.max);
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(touch.singleTouchDelay.value, touch.singleTouchDelay.max);
      expect(touch.zoomStepDistance.value, touch.zoomStepDistance.max);
      expect(touch.showJoysticks.value, !joysticks);
    });
  });

  group("the reset buttons", ()
  {
    for (final PreferenceSectionType section in <PreferenceSectionType>[PreferenceSectionType.gui, PreferenceSectionType.behavior, PreferenceSectionType.controlsStylus, PreferenceSectionType.controlsTouch])
    {
      projectWidgetTest("bring the ${section.name} sliders back to their defaults", _preferences, (final WidgetTester tester) async
      {
        await _openSection(tester, section);
        final Finder sliders = find.byType(KPixSlider);
        final Finder resets = find.byTooltip(testL10n.resetValue);
        final int count = sliders.evaluate().length;
        expect(resets, findsNWidgets(count));

        for (int i = 0; i < count; i++)
        {
          IconButton reset() => tester.widget<IconButton>(find.ancestor(of: resets.at(i), matching: find.byType(IconButton)));
          final KPixSlider slider = tester.widget<KPixSlider>(sliders.at(i));
          final double initial = slider.value;
          expect(reset().onPressed, isNull);

          slider.onChanged!(initial == slider.max ? slider.min : slider.max);
          await tester.pump();
          expect(reset().onPressed, isNotNull);

          await tester.ensureVisible(resets.at(i));
          await tester.tap(resets.at(i));
          await tester.pump();
          expect(tester.widget<KPixSlider>(sliders.at(i)).value, initial);
          expect(reset().onPressed, isNull);
        }
      });
    }
  });

  group("the desktop section", ()
  {
    projectWidgetTest("hands the cursor type on", _preferences, (final WidgetTester tester) async
    {
      await _openSection(tester, PreferenceSectionType.controlsPC);

      tester.widget<SegmentedButton<CursorType>>(find.byType(SegmentedButton<CursorType>)).onSelectionChanged!(<CursorType>{CursorType.arrow});
      await tester.pump();

      expect(_prefs.desktopPreferenceContent.cursorType.value, CursorType.arrow);
    });
  });
}
