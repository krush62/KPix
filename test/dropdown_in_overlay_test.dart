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
import 'package:kpix/widgets/controls/kpix_dropdown.dart';

/// A dropdown shown the way [KPixOverlay] shows its dialogs: an [OverlayEntry]
/// inserted into the navigator's overlay by hand.
///
/// [Navigator] re-appends such entries above all route entries whenever a route
/// is pushed, so a route based menu can never be drawn above them. These tests
/// pin that the dropdown does not rely on a route.
const Map<String, String> _values = <String, String>{"a": "Alpha", "b": "Beta"};

/// Counts the routes pushed after it is armed.
class _PushCounter extends NavigatorObserver
{
  int pushes = 0;
  bool armed = false;

  @override
  void didPush(final Route<dynamic> route, final Route<dynamic>? previousRoute)
  {
    if (armed)
    {
      pushes++;
    }
  }
}

Future<OverlayEntry> _showDropdownInOverlay(
  final WidgetTester tester, {
  required final ValueNotifier<String> notifier,
  final NavigatorObserver? observer,
}) async
{
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: <NavigatorObserver>[if (observer != null) observer],
      home: const Scaffold(body: Center(child: Text("behind"))),
    ),
  );

  final OverlayEntry entry = OverlayEntry(
    builder: (final BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 300.0,
        child: ValueListenableBuilder<String>(
          valueListenable: notifier,
          builder: (final BuildContext context, final String value, final Widget? child) => KPixDropdown<String>(
            value: value,
            valueMap: _values,
            onChanged: (final String newValue) {notifier.value = newValue;},
          ),
        ),
      ),
    ),
  );
  //the same context the dialogs use: below the navigator, so its overlay is found
  Overlay.of(tester.element(find.text("behind"))).insert(entry);
  await tester.pumpAndSettle();
  return entry;
}

void main()
{
  testWidgets("a dropdown inside a hand inserted overlay entry opens and selects", (final WidgetTester tester) async {
    final ValueNotifier<String> notifier = ValueNotifier<String>("a");
    final OverlayEntry entry = await _showDropdownInOverlay(tester, notifier: notifier);

    expect(find.text("Alpha"), findsOneWidget);

    await tester.tap(find.byType(KPixDropdown<String>));
    await tester.pumpAndSettle();
    expect(find.text("Beta"), findsOneWidget);

    await tester.tap(find.text("Beta"));
    await tester.pumpAndSettle();

    expect(notifier.value, "b");
    //a second tap used to trip an assertion in DropdownButton, because the
    //menu route was still open behind the entry
    await tester.tap(find.byType(KPixDropdown<String>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    entry.remove();
    await tester.pumpAndSettle();
  });

  testWidgets("opening the menu does not push a route", (final WidgetTester tester) async {
    final ValueNotifier<String> notifier = ValueNotifier<String>("a");
    final _PushCounter counter = _PushCounter();
    final OverlayEntry entry = await _showDropdownInOverlay(tester, notifier: notifier, observer: counter);

    //a pushed route would be put below this entry again by the navigator, so the
    //menu has to come from somewhere else
    counter.armed = true;
    await tester.tap(find.byType(KPixDropdown<String>));
    await tester.pumpAndSettle();

    expect(find.text("Beta"), findsOneWidget);
    expect(counter.pushes, 0);

    entry.remove();
    await tester.pumpAndSettle();
  });
}
