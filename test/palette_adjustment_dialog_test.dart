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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/palette/palette_adjustment_widget.dart';

import 'support/selection_harness.dart';

/// Boots a project and shows the adjustment dialog on top of it.
///
/// The project has to be built with the real event loop running, the dialog is
/// driven with the fake one, where the layer copies of the preview never finish
/// rastering - which keeps the preview render, and with it the engine, out of
/// these tests.
Future<void> _pumpDialog(final WidgetTester tester, {required final VoidCallback dismiss}) async
{
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4));
  });
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PaletteAdjustmentWidget(dismiss: dismiss),
    ),
  );
  //past the scale in of the dialog, which is not hit testable while it plays
  await tester.pump(const Duration(milliseconds: 200));
}

/// Takes the dialog down and releases the layers of the project.
///
/// The layer copies of the preview and the layers of the project poll the same
/// raster scheduler, whose timer would otherwise still be pending when the test
/// ends.
Future<void> _close(final WidgetTester tester) async
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

AppLocalizations _l10n(final WidgetTester tester)
{
  return AppLocalizations.of(tester.element(find.byType(PaletteAdjustmentWidget)))!;
}

/// The base hue of every ramp of the palette.
List<int> _baseHues()
{
  return GetIt.I.get<PaletteState>().colorRamps.map((final KPalRampData ramp) => ramp.settings.baseHue).toList();
}

/// The row of the slider labelled [label].
Finder _sliderRow({required final String label})
{
  return find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
}

/// Drags the slider of the row labelled [label] to its right end.
Future<void> _dragSliderToMax(final WidgetTester tester, {required final String label}) async
{
  await tester.drag(find.descendant(of: _sliderRow(label: label), matching: find.byType(Slider)), const Offset(1000.0, 0.0));
  await tester.pump();
}

/// The reset button of the row of the slider labelled [label].
Finder _resetButton({required final String label})
{
  return find.descendant(of: _sliderRow(label: label), matching: find.byType(IconButton));
}

void main()
{
  testWidgets("the dialog builds with a slider row for every adjustment", (final WidgetTester tester) async {
    await _pumpDialog(tester, dismiss: () {});

    expect(find.byType(KPixSlider), findsNWidgets(7));
    //one switch per ramp, to take it out of the adjustment
    expect(find.byType(Switch), findsNWidgets(GetIt.I.get<PaletteState>().colorRamps.length));
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets("a hue shift moves every ramp and is taken back by the reset", (final WidgetTester tester) async {
    await _pumpDialog(tester, dismiss: () {});
    final AppLocalizations l10n = _l10n(tester);
    final List<int> before = _baseHues();

    await _dragSliderToMax(tester, label: l10n.hueShift);
    expect(_baseHues(), isNot(before));

    await tester.tap(find.byTooltip(l10n.resetAllAdjustments));
    await tester.pump();
    expect(_baseHues(), before);
    await _close(tester);
  });

  testWidgets("a slider has a reset button of its own that only takes back its own value", (final WidgetTester tester) async {
    await _pumpDialog(tester, dismiss: () {});
    final AppLocalizations l10n = _l10n(tester);
    final List<int> before = _baseHues();

    //nothing to take back while every slider sits on its default
    expect(tester.widget<IconButton>(_resetButton(label: l10n.hueShift)).onPressed, isNull);

    await _dragSliderToMax(tester, label: l10n.hueShift);
    await _dragSliderToMax(tester, label: l10n.brightness);
    expect(tester.widget<IconButton>(_resetButton(label: l10n.hueShift)).onPressed, isNotNull);

    await tester.tap(_resetButton(label: l10n.hueShift));
    await tester.pump();

    //the hue is back, the brightness is not, so the ramps are still moved
    expect(tester.widget<IconButton>(_resetButton(label: l10n.hueShift)).onPressed, isNull);
    expect(tester.widget<IconButton>(_resetButton(label: l10n.brightness)).onPressed, isNotNull);
    expect(_baseHues(), before);
    await _close(tester);
  });

  testWidgets("a ramp that is switched off keeps its colors", (final WidgetTester tester) async {
    await _pumpDialog(tester, dismiss: () {});
    final AppLocalizations l10n = _l10n(tester);
    final KPalRampData excluded = GetIt.I.get<PaletteState>().colorRamps.first;
    final int excludedHueBefore = excluded.settings.baseHue;
    final List<int> before = _baseHues();

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await _dragSliderToMax(tester, label: l10n.hueShift);

    expect(excluded.settings.baseHue, excludedHueBefore);
    expect(_baseHues().sublist(1), isNot(before.sublist(1)));
    await _close(tester);
  });

  testWidgets("applying the adjustment keeps it and adds a history step", (final WidgetTester tester) async {
    bool dismissed = false;
    await _pumpDialog(tester, dismiss: () {dismissed = true;});
    final AppLocalizations l10n = _l10n(tester);
    final List<int> before = _baseHues();

    await _dragSliderToMax(tester, label: l10n.hueShift);
    await tester.tap(find.byTooltip(l10n.apply));
    await tester.pump();

    expect(dismissed, isTrue);
    expect(_baseHues(), isNot(before));
    expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), HistoryStateTypeIdentifier.kPalAdjust);
    await _close(tester);
  });

  testWidgets("cancelling puts the palette back without a history step", (final WidgetTester tester) async {
    bool dismissed = false;
    await _pumpDialog(tester, dismiss: () {dismissed = true;});
    final AppLocalizations l10n = _l10n(tester);
    final List<int> before = _baseHues();
    final HistoryStateTypeIdentifier stepBefore = GetIt.I.get<HistoryManager>().getCurrentIdentifier();

    await _dragSliderToMax(tester, label: l10n.hueShift);
    await tester.tap(find.byTooltip(l10n.cancel));
    await tester.pump();

    expect(dismissed, isTrue);
    expect(_baseHues(), before);
    expect(GetIt.I.get<HistoryManager>().getCurrentIdentifier(), stepBefore);
    await _close(tester);
  });
}
