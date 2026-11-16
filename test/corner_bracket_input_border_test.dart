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
import 'package:kpix/widgets/controls/corner_bracket_input_border.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:material_ui/material_ui.dart';

const Color _stroke = Color(0xFFFFFFFF);
const Color _background = Color(0xFF000000);

Future<ByteData> _paintBorder({required final CornerBracketInputBorder border, required final Size size}) async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = _background);
  border.paint(canvas, Offset.zero & size);
  final ui.Image image = recorder.endRecording().toImageSync(size.width.toInt(), size.height.toInt());
  final ByteData bytes = (await image.toByteData())!;
  image.dispose();
  return bytes;
}

Color _pixel({required final ByteData bytes, required final int width, required final int x, required final int y})
{
  final int offset = (y * width + x) * 4;
  return Color.fromARGB(bytes.getUint8(offset + 3), bytes.getUint8(offset), bytes.getUint8(offset + 1), bytes.getUint8(offset + 2));
}

Future<Color> _renderedColor({required final WidgetTester tester, required final GlobalKey key, required final Offset at}) async
{
  final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ByteData bytes = (await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData? data = await image.toByteData();
    image.dispose();
    return data;
  }))!;
  return _pixel(bytes: bytes, width: boundary.size.width.toInt(), x: at.dx.toInt(), y: at.dy.toInt());
}

void main()
{
  group('CornerBracketInputBorder painting', () {
    const Size size = Size(60, 30);
    const CornerBracketInputBorder border = CornerBracketInputBorder(borderSide: BorderSide(color: _stroke, width: 2.0), cornerLength: 10.0);

    test('draws the arms near every corner', () async {
      final ByteData bytes = await _paintBorder(border: border, size: size);
      final int w = size.width.toInt();
      final int h = size.height.toInt();
      expect(_pixel(bytes: bytes, width: w, x: 7, y: 0), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: 0, y: 7), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: w - 8, y: 0), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: w - 1, y: 7), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: 7, y: h - 1), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: 0, y: h - 8), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: w - 8, y: h - 1), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: w - 1, y: h - 8), _stroke);
    });

    test('ends every arm exactly cornerLength from the outer edge', () async {
      final ByteData bytes = await _paintBorder(border: border, size: size);
      final int w = size.width.toInt();
      final int h = size.height.toInt();
      expect(_pixel(bytes: bytes, width: w, x: 9, y: 0), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: 10, y: 0), _background);
      expect(_pixel(bytes: bytes, width: w, x: w - 10, y: h - 1), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: w - 11, y: h - 1), _background);
      expect(_pixel(bytes: bytes, width: w, x: 0, y: 9), _stroke);
      expect(_pixel(bytes: bytes, width: w, x: 0, y: 10), _background);
    });

    test('leaves the middle of each edge and the rounded corner tip empty', () async {
      final ByteData bytes = await _paintBorder(border: border, size: size);
      final int w = size.width.toInt();
      final int h = size.height.toInt();
      expect(_pixel(bytes: bytes, width: w, x: w ~/ 2, y: 0), _background);
      expect(_pixel(bytes: bytes, width: w, x: w ~/ 2, y: h - 1), _background);
      expect(_pixel(bytes: bytes, width: w, x: 0, y: h ~/ 2), _background);
      expect(_pixel(bytes: bytes, width: w, x: w - 1, y: h ~/ 2), _background);
      expect(_pixel(bytes: bytes, width: w, x: 0, y: 0), _background);
      expect(_pixel(bytes: bytes, width: w, x: w - 1, y: h - 1), _background);
    });

    test('paints nothing with BorderSide.none', () async {
      final ByteData bytes = await _paintBorder(border: const CornerBracketInputBorder(borderSide: BorderSide.none), size: size);
      for (int x = 0; x < size.width; x++)
      {
        expect(_pixel(bytes: bytes, width: size.width.toInt(), x: x, y: 0), _background);
      }
    });
  });

  group('CornerBracketInputBorder values', () {
    const CornerBracketInputBorder a = CornerBracketInputBorder(borderSide: BorderSide(width: 2.0), cornerLength: 6.0, radius: 4.0);
    const CornerBracketInputBorder b = CornerBracketInputBorder(borderSide: BorderSide(width: 4.0), cornerLength: 10.0, radius: 6.0);

    test('lerps width, length and radius', () {
      final CornerBracketInputBorder mid = b.lerpFrom(a, 0.5)! as CornerBracketInputBorder;
      expect(mid.borderSide.width, 3.0);
      expect(mid.cornerLength, 8.0);
      expect(mid.radius, 5.0);
      expect(a.lerpTo(b, 0.5), mid);
    });

    test('copyWith keeps the geometry', () {
      final CornerBracketInputBorder copy = a.copyWith(borderSide: const BorderSide(color: _stroke));
      expect(copy.cornerLength, a.cornerLength);
      expect(copy.radius, a.radius);
      expect(copy.borderSide.color, _stroke);
      expect(copy, isNot(a));
    });

    test('is not an outline border', () {
      expect(a.isOutline, isFalse);
    });
  });

  group('Theme text fields', () {
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[('light', monochromeTheme), ('dark', monochromeThemeDark)])
    {
      testWidgets('$name theme fills a text field with primaryColorDark only while focused', (final WidgetTester tester) async {
        final GlobalKey key = GlobalKey();
        final FocusNode focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: theme.primaryColor,
                child: SizedBox(width: 200, child: Material(type: MaterialType.transparency, child: TextField(focusNode: focusNode))),
              ),
            ),
          ),
        ));
        final Offset inside = Offset(100, tester.getSize(find.byType(TextField)).height / 2);

        expect(await _renderedColor(tester: tester, key: key, at: inside), theme.primaryColor);

        focusNode.requestFocus();
        // The blinking cursor never settles.
        await tester.pump(const Duration(milliseconds: 300));
        expect(await _renderedColor(tester: tester, key: key, at: inside), theme.primaryColorDark);
        // The fill stays inside the slider-like margin.
        expect(await _renderedColor(tester: tester, key: key, at: const Offset(100, 4)), theme.primaryColor);
      });

      // Desktop platforms default to compact density; tests run as Android.
      for (final VisualDensity density in <VisualDensity>[VisualDensity.standard, VisualDensity.compact])
      {
        testWidgets('$name theme text field is as tall as a default KPixSlider with $density', (final WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(
            theme: theme.copyWith(visualDensity: density),
            home: Material(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(width: 200, child: KPixSlider(value: 0.5, onChanged: (final double v) {}, textStyle: theme.textTheme.bodyLarge!)),
                  const SizedBox(width: 200, child: TextField()),
                ],
              ),
            ),
          ));
          final Rect slider = tester.getRect(find.byType(KPixSlider));
          final Rect field = tester.getRect(find.byType(TextField));
          expect(field.height, slider.height);
          final Rect text = tester.getRect(find.byType(EditableText));
          expect(text.center.dy - field.top, closeTo(field.height / 2, 0.5));
          final CornerBracketInputBorder resting = theme.inputDecorationTheme.enabledBorder! as CornerBracketInputBorder;
          expect(text.left - field.left, resting.cornerLength);
          expect(field.right - text.right, resting.cornerLength);
        });
      }
    }
  });

  test('margin insets the outer path and lerps', () {
    const CornerBracketInputBorder border = CornerBracketInputBorder(margin: EdgeInsets.symmetric(vertical: 8.0));
    final Rect bounds = border.getOuterPath(const Rect.fromLTWH(0, 0, 100, 40)).getBounds();
    expect(bounds, const Rect.fromLTWH(0, 8, 100, 24));
    final CornerBracketInputBorder mid = border.lerpFrom(const CornerBracketInputBorder(), 0.5)! as CornerBracketInputBorder;
    expect(mid.margin, const EdgeInsets.symmetric(vertical: 4.0));
  });
}
