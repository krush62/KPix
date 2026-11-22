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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/widgets/controls/kpix_dropdown.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:material_ui/material_ui.dart';

const Map<String, String> _values = <String, String>{"a": "Alpha", "b": "Beta", "c": "Gamma"};
const double _width = 200.0;

Future<Color> _renderedColor({required final WidgetTester tester, required final GlobalKey key, required final Offset at}) async
{
  final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ByteData bytes = (await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData? data = await image.toByteData();
    image.dispose();
    return data;
  }))!;
  final int offset = (at.dy.toInt() * boundary.size.width.toInt() + at.dx.toInt()) * 4;
  return Color.fromARGB(bytes.getUint8(offset + 3), bytes.getUint8(offset), bytes.getUint8(offset + 1), bytes.getUint8(offset + 2));
}

Future<void> _pumpDropdown({required final WidgetTester tester, required final ThemeData theme, required final ValueNotifier<String> notifier, final GlobalKey? key}) async
{
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: MaterialApp(
      theme: theme,
      home: Material(
        color: theme.primaryColor,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                KPixSlider(value: 0.5, onChanged: (final double v) {}, textStyle: theme.textTheme.bodyLarge!),
                ValueListenableBuilder<String>(
                  valueListenable: notifier,
                  builder: (final BuildContext context, final String value, final Widget? child) => KPixDropdown<String>(
                    value: value,
                    valueMap: _values,
                    onChanged: (final String newValue) {notifier.value = newValue;},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
}

Rect _box(final WidgetTester tester) => tester.getRect(find.descendant(of: find.byType(KPixDropdown<String>), matching: find.byType(ClipRRect)));

Finder _menuText(final String text) => find.descendant(of: find.byType(MenuItemButton), matching: find.text(text));

void main()
{
  for (final (String name, ThemeData theme) in <(String, ThemeData)>[('light', monochromeTheme), ('dark', monochromeThemeDark)])
  {
    // Desktop platforms default to compact density; tests run as Android.
    for (final VisualDensity density in <VisualDensity>[VisualDensity.standard, VisualDensity.compact])
    {
      testWidgets('$name theme dropdown is as tall as a default KPixSlider with $density', (final WidgetTester tester) async {
        final ValueNotifier<String> notifier = ValueNotifier<String>("a");
        await _pumpDropdown(tester: tester, theme: theme.copyWith(visualDensity: density), notifier: notifier);

        final Rect dropdown = tester.getRect(find.byType(KPixDropdown<String>));
        expect(dropdown.height, tester.getSize(find.byType(KPixSlider)).height);
        final Rect box = _box(tester);
        expect(box.height, 24.0);
        expect(box.top - dropdown.top, 8.0);
        // Same inset as the text in a text field.
        expect(tester.getRect(find.text("Alpha")).left - box.left, 10.0);
      });

      testWidgets('$name theme dropdown menu is as wide as the box with $density', (final WidgetTester tester) async {
        final ValueNotifier<String> notifier = ValueNotifier<String>("a");
        await _pumpDropdown(tester: tester, theme: theme.copyWith(visualDensity: density), notifier: notifier);

        await tester.tap(find.byType(KPixDropdown<String>));
        await tester.pumpAndSettle();

        final Rect box = _box(tester);
        final Rect first = tester.getRect(find.byType(MenuItemButton).first);
        expect(find.byType(MenuItemButton), findsNWidgets(_values.length));
        expect(first.size, const Size(_width, 32.0));
        // 4px gap plus the 2px menu padding.
        expect(first.top - box.bottom, 6.0);
        expect(tester.getRect(_menuText("Alpha")).left - first.left, 10.0);
      });
    }

    testWidgets('$name theme dropdown shows a light arrow tab and fills the box while open', (final WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final ValueNotifier<String> notifier = ValueNotifier<String>("a");
      await _pumpDropdown(tester: tester, theme: theme, notifier: notifier, key: key);

      final Rect box = _box(tester);
      final Offset inside = Offset(box.left + 4.0, box.center.dy);
      expect(await _renderedColor(tester: tester, key: key, at: inside), theme.primaryColor);
      // Left of the icon, which tests render as a solid square.
      expect(await _renderedColor(tester: tester, key: key, at: Offset(box.right - 23.0, box.center.dy)), theme.primaryColorLight);

      await tester.tap(find.byType(KPixDropdown<String>));
      await tester.pumpAndSettle();
      expect(await _renderedColor(tester: tester, key: key, at: inside), theme.primaryColorDark);

      // The selected entry is inverted, the others sit on the menu background.
      final Rect alpha = tester.getRect(find.byType(MenuItemButton).at(0));
      final Rect beta = tester.getRect(find.byType(MenuItemButton).at(1));
      expect(await _renderedColor(tester: tester, key: key, at: Offset(alpha.left + 4.0, alpha.center.dy)), theme.primaryColorLight);
      expect(await _renderedColor(tester: tester, key: key, at: Offset(beta.left + 4.0, beta.center.dy)), theme.primaryColorDark);
      expect(tester.widget<Text>(_menuText("Alpha")).style!.color, theme.primaryColorDark);
      expect(tester.widget<Text>(_menuText("Beta")).style!.color, theme.textTheme.bodyLarge!.color);

      await tester.tap(_menuText("Beta"));
      await tester.pumpAndSettle();
      expect(notifier.value, "b");
      expect(find.byType(MenuItemButton), findsNothing);
      expect(await _renderedColor(tester: tester, key: key, at: inside), theme.primaryColor);
    });
  }

  testWidgets('the margin around the box opens the menu as well', (final WidgetTester tester) async {
    final ValueNotifier<String> notifier = ValueNotifier<String>("a");
    await _pumpDropdown(tester: tester, theme: monochromeThemeDark, notifier: notifier);

    final Rect dropdown = tester.getRect(find.byType(KPixDropdown<String>));
    await tester.tapAt(Offset(dropdown.center.dx, dropdown.top + 2.0));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNWidgets(_values.length));

    await tester.tapAt(Offset(dropdown.center.dx, dropdown.top + 2.0));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
  });
}
