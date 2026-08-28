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
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// The alpha the smoke behind a dialog settles on.
const int _fullSmoke = OverlayEntryAlertDialogOptions.smokeOpacity;

/// The route below the overlay has a [ModalBarrier] of its own, so the smoke is
/// located through the builder that fades it.
int _barrierAlpha(final WidgetTester tester)
{
  final Finder smoke = find.descendant(
    of: find.byType(TweenAnimationBuilder<double>),
    matching: find.byType(ModalBarrier),
  );
  return (tester.widget<ModalBarrier>(smoke).color!.a * 255.0).round();
}

/// Inserts [overlay] into a live [Overlay] without going through
/// [KPixOverlay.show], which needs the service locator.
Future<void> _pumpOverlay(final WidgetTester tester, final KPixOverlay overlay) async
{
  await tester.pumpWidget(
    MaterialApp(
      home: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(builder: (final BuildContext context) => const SizedBox.expand()),
          overlay.entry,
        ],
      ),
    ),
  );
}

void main()
{
  testWidgets("the barrier smoke starts transparent", (final WidgetTester tester) async {
    await _pumpOverlay(tester, getSingleButtonDialog(onAction: () {}, message: "hello"));

    expect(_barrierAlpha(tester), 0);
  });

  testWidgets("the barrier smoke fades in", (final WidgetTester tester) async {
    await _pumpOverlay(tester, getSingleButtonDialog(onAction: () {}, message: "hello"));

    await tester.pump(const Duration(milliseconds: 75));
    final int midway = _barrierAlpha(tester);
    expect(midway, greaterThan(0));
    expect(midway, lessThan(_fullSmoke));
  });

  testWidgets("the barrier smoke reaches full opacity", (final WidgetTester tester) async {
    await _pumpOverlay(tester, getSingleButtonDialog(onAction: () {}, message: "hello"));
    await tester.pumpAndSettle();

    expect(_barrierAlpha(tester), _fullSmoke);
  });

  testWidgets("the barrier swallows taps while it is still fading", (final WidgetTester tester) async {
    bool tappedBelow = false;
    final KPixOverlay overlay = getSingleButtonDialog(onAction: () {}, message: "hello");

    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (final BuildContext context) => GestureDetector(
                onTap: () {tappedBelow = true;},
                child: const SizedBox.expand(),
              ),
            ),
            overlay.entry,
          ],
        ),
      ),
    );

    //still fully transparent at this point
    expect(_barrierAlpha(tester), 0);
    await tester.tapAt(const Offset(5.0, 5.0));
    await tester.pump();

    expect(tappedBelow, isFalse);
  });
}
