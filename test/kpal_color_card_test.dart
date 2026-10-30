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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

const Duration _touchTimeout = Duration(milliseconds: 1600);

/// One card between another, as in a ramp, and what it shows.
class _Card
{
  final ShiftSet shifts = ShiftSet(hueShiftNotifier: ValueNotifier<int>(0), satShiftNotifier: ValueNotifier<int>(0), valShiftNotifier: ValueNotifier<int>(0));
  final ValueNotifier<IdColor> color = ValueNotifier<IdColor>(IdColor(hsv: KHSV(h: 210, s: 0.6, v: 0.4), uuid: "a"));
}

Finder _pencil(final int card) => find.descendant(of: find.byType(KPalColorCardWidget).at(card), matching: find.byIcon(TablerIcons.pencil));

Finder _colorArea(final int card) => find.descendant(of: find.byType(KPalColorCardWidget).at(card), matching: find.byType(Stack)).first;

Finder _sliders(final int card) => find.descendant(of: find.byType(KPalColorCardWidget).at(card), matching: find.byType(Slider));

double _pencilOpacity(final WidgetTester tester, {final int card = 0}) => tester.widget<AnimatedOpacity>(find.ancestor(of: _pencil(card), matching: find.byType(AnimatedOpacity)).first).opacity;

double _slidersOpacity(final WidgetTester tester, {final int card = 0}) => tester.widget<AnimatedOpacity>(find.ancestor(of: _sliders(card).first, matching: find.byType(AnimatedOpacity)).first).opacity;

Future<void> _settleDown(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpCards(final WidgetTester tester, {required final _Card first, required final _Card second, final bool firstShowsName = true}) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
  });
  await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: Center(child: SizedBox(
      width: 700,
      height: 600,
      child: Row(children: <Widget>[
        KPalColorCardWidget(showName: firstShowsName, shiftSet: first.shifts, colorNotifier: first.color),
        KPalColorCardWidget(showName: false, shiftSet: second.shifts, colorNotifier: second.color, isLast: true),
      ],),
    ),),),
  ),),);
  await _settleDown(tester);
}

/// Lets a touch timeout started by the test run out, and clears the project.
Future<void> _close(final WidgetTester tester) async
{
  await tester.pump(_touchTimeout);
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump(const Duration(seconds: 1));
}

Future<TestGesture> _mouse(final WidgetTester tester) async
{
  final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

void main()
{
  group("pencil", () {
    testWidgets("does not show for a color without shifts", (final WidgetTester tester) async {
      await _pumpCards(tester, first: _Card(), second: _Card());
      expect(_pencilOpacity(tester), 0);
      await _close(tester);
    });

    testWidgets("shows for each kind of shift once the sliders are gone again", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card());
      final Map<String, ValueNotifier<int>> shifts = <String, ValueNotifier<int>>{
        "hue": card.shifts.hueShiftNotifier,
        "sat": card.shifts.satShiftNotifier,
        "val": card.shifts.valShiftNotifier,
      };
      for (final MapEntry<String, ValueNotifier<int>> shift in shifts.entries)
      {
        shift.value.value = 3;
        await tester.pump();
        expect(_pencilOpacity(tester), 0, reason: "${shift.key}: the sliders show");
        await tester.pump(_touchTimeout);
        await _settleDown(tester);
        expect(_pencilOpacity(tester), 1, reason: shift.key);

        shift.value.value = 0;
        await tester.pump(_touchTimeout);
        await _settleDown(tester);
        expect(_pencilOpacity(tester), 0, reason: "${shift.key} back");
      }
      await _close(tester);
    });

    testWidgets("gives way to the sliders on hover and returns afterwards", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card());
      card.shifts.valShiftNotifier.value = 2;
      await tester.pump(_touchTimeout);
      await _settleDown(tester);
      expect(_pencilOpacity(tester), 1);

      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_colorArea(0)));
      await _settleDown(tester);
      expect(_pencilOpacity(tester), 0);

      await mouse.moveTo(Offset.zero);
      await _settleDown(tester);
      expect(_pencilOpacity(tester), 1);
      await _close(tester);
    });

    testWidgets("follows the shifts of its own card", (final WidgetTester tester) async {
      final _Card second = _Card();
      await _pumpCards(tester, first: _Card(), second: second);
      second.shifts.hueShiftNotifier.value = 1;
      await tester.pump(_touchTimeout);
      await _settleDown(tester);
      expect(_pencilOpacity(tester, card: 1), 1);
      expect(_pencilOpacity(tester), 0);
      await _close(tester);
    });

    testWidgets("is padded and has a shadow in the dark color", (final WidgetTester tester) async {
      await _pumpCards(tester, first: _Card(), second: _Card());
      final Icon icon = tester.widget<Icon>(_pencil(0));
      expect(icon.shadows!.single.color, Theme.of(tester.element(_pencil(0))).primaryColorDark);
      expect(tester.widget<Padding>(find.ancestor(of: _pencil(0), matching: find.byType(Padding)).first).padding, const EdgeInsets.all(8));
      await _close(tester);
    });
  });

  group("sliders", () {
    testWidgets("show while the mouse is over the color", (final WidgetTester tester) async {
      await _pumpCards(tester, first: _Card(), second: _Card());
      expect(_slidersOpacity(tester), 0);

      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_colorArea(0)));
      await _settleDown(tester);
      expect(_slidersOpacity(tester), 1);
      expect(_slidersOpacity(tester, card: 1), 0);

      await mouse.moveTo(Offset.zero);
      await _settleDown(tester);
      expect(_slidersOpacity(tester), 0);
      await _close(tester);
    });

    testWidgets("show for a while after a tap", (final WidgetTester tester) async {
      await _pumpCards(tester, first: _Card(), second: _Card());
      await tester.tap(_colorArea(0));
      await _settleDown(tester);
      expect(_slidersOpacity(tester), 1);
      await tester.pump(_touchTimeout);
      await _settleDown(tester);
      expect(_slidersOpacity(tester), 0);
      await _close(tester);
    });

    testWidgets("stay while the mouse is inside, past the timeout of a change", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card());
      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_colorArea(0)));
      await _settleDown(tester);
      card.shifts.hueShiftNotifier.value = 4;
      await tester.pump(_touchTimeout);
      await _settleDown(tester);
      expect(_slidersOpacity(tester), 1);
      await mouse.moveTo(Offset.zero);
      await _close(tester);
    });

    testWidgets("take no drag while hidden", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card());
      await tester.drag(_sliders(0).first, const Offset(0, -40), warnIfMissed: false);
      await _settleDown(tester);
      expect(card.shifts.hueShiftNotifier.value, 0);
      await _close(tester);
    });

    testWidgets("each move their own shift within its limits", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card());
      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_colorArea(0)));
      await _settleDown(tester);

      final List<ValueNotifier<int>> shifts = <ValueNotifier<int>>[card.shifts.hueShiftNotifier, card.shifts.satShiftNotifier, card.shifts.valShiftNotifier];
      final List<(int, int)> limits = <(int, int)>[
        (KPalSliderConstraints.minHue, KPalSliderConstraints.maxHue),
        (KPalSliderConstraints.minSat, KPalSliderConstraints.maxSat),
        (KPalSliderConstraints.minVal, KPalSliderConstraints.maxVal),
      ];
      for (int i = 0; i < 3; i++)
      {
        final Slider slider = tester.widget<Slider>(_sliders(0).at(i));
        expect((slider.min.toInt(), slider.max.toInt()), limits[i], reason: "slider $i");
        await tester.drag(_sliders(0).at(i), const Offset(0, -40));
        await _settleDown(tester);
        expect(shifts[i].value, greaterThan(0), reason: "slider $i");
        for (int other = i + 1; other < 3; other++)
        {
          expect(shifts[other].value, 0, reason: "slider $i moved $other");
        }
      }
      await mouse.moveTo(Offset.zero);
      await _close(tester);
    });
  });

  group("color", () {
    testWidgets("shows name, hex value and numbers, and follows its notifier", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card());
      void expectShown(final IdColor color)
      {
        final Finder inCard = find.byType(KPalColorCardWidget).first;
        final String name = GetIt.I.get<PreferenceManager>().colorNames.getColorName(r: color.color.r, g: color.color.g, b: color.color.b);
        expect(find.descendant(of: inCard, matching: find.text(name)), findsOneWidget);
        expect(find.descendant(of: inCard, matching: find.text(colorToHexString(color: color.color, toUpper: true))), findsOneWidget);
        expect(find.descendant(of: inCard, matching: find.text("${color.hsv.h.round()}°")), findsOneWidget);
        expect(find.descendant(of: inCard, matching: find.text("${(color.hsv.s * 100).round()}%")), findsOneWidget);
        expect(find.descendant(of: inCard, matching: find.text("${(color.hsv.v * 100).round()}%")), findsOneWidget);
        final Container swatch = tester.widget<Container>(find.descendant(of: _colorArea(0), matching: find.byType(Container)).first);
        expect(swatch.color, color.color);
      }

      expectShown(card.color.value);
      card.color.value = IdColor(hsv: KHSV(h: 90, s: 0.75, v: 1), uuid: "b");
      await _settleDown(tester);
      expectShown(card.color.value);
      await _close(tester);
    });

    testWidgets("leaves name and hex value out when asked to", (final WidgetTester tester) async {
      final _Card card = _Card();
      await _pumpCards(tester, first: card, second: _Card(), firstShowsName: false);
      expect(find.descendant(of: find.byType(KPalColorCardWidget).first, matching: find.text(colorToHexString(color: card.color.value.color, toUpper: true))), findsNothing);
      await _close(tester);
    });
  });

  testWidgets("only the last card has padding on its right side", (final WidgetTester tester) async {
    await _pumpCards(tester, first: _Card(), second: _Card());
    EdgeInsetsGeometry paddingOf(final int card) => tester.widget<Padding>(find.descendant(of: find.byType(KPalColorCardWidget).at(card), matching: find.byType(Padding)).first).padding;
    expect(paddingOf(0), const EdgeInsets.only(left: 8, top: 8, bottom: 8));
    expect(paddingOf(1), const EdgeInsets.all(8));
    await _close(tester);
  });
}
