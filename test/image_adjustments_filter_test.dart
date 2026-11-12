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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:material_ui/material_ui.dart';

/// What the filter makes of a pixel, as (red, green, blue).
Future<(int, int, int)> _filtered({required final WidgetTester tester, required final (int, int, int) rgb, required final ColorFilter filter}) async
{
  final (int, int, int)? result = await tester.runAsync(() async
  {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()
      ..color = Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3)
      ..colorFilter = filter,);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(1, 1);
    final ByteData data = (await image.toByteData())!;
    final (int, int, int) pixel = (data.getUint8(0), data.getUint8(1), data.getUint8(2));
    image.dispose();
    picture.dispose();
    return pixel;
  });
  return result!;
}

void _expectClose({required final (int, int, int) actual, required final (double, double, double) expected})
{
  expect(actual.$1, closeTo(expected.$1, 1.0), reason: "red");
  expect(actual.$2, closeTo(expected.$2, 1.0), reason: "green");
  expect(actual.$3, closeTo(expected.$3, 1.0), reason: "blue");
}

void main()
{
  const (int, int, int) color = (200, 100, 50);

  group("the image adjustments", ()
  {
    testWidgets("leave a pixel alone by default", (final WidgetTester tester) async
    {
      _expectClose(actual: await _filtered(tester: tester, rgb: color, filter: imageAdjustmentsFilter()), expected: (200, 100, 50));
    });

    testWidgets("turn it into its Rec. 709 luminance without saturation", (final WidgetTester tester) async
    {
      const double luminance = 0.2126 * 200 + 0.7152 * 100 + 0.0722 * 50;

      _expectClose(actual: await _filtered(tester: tester, rgb: color, filter: imageAdjustmentsFilter(saturation: 0.0)), expected: (luminance, luminance, luminance));
    });

    testWidgets("push it away from its luminance with more saturation", (final WidgetTester tester) async
    {
      const double luminance = 0.2126 * 120 + 0.7152 * 100 + 0.0722 * 80;

      _expectClose(
        actual: await _filtered(tester: tester, rgb: (120, 100, 80), filter: imageAdjustmentsFilter(saturation: 1.5)),
        expected: (luminance + 1.5 * (120 - luminance), luminance + 1.5 * (100 - luminance), luminance + 1.5 * (80 - luminance)),
      );
    });

    testWidgets("add brightness to all channels", (final WidgetTester tester) async
    {
      _expectClose(actual: await _filtered(tester: tester, rgb: color, filter: imageAdjustmentsFilter(brightness: 0.1)), expected: (225.5, 125.5, 75.5));
      _expectClose(actual: await _filtered(tester: tester, rgb: color, filter: imageAdjustmentsFilter(brightness: -0.1)), expected: (174.5, 74.5, 24.5));
    });

    testWidgets("spread contrast around the middle", (final WidgetTester tester) async
    {
      _expectClose(actual: await _filtered(tester: tester, rgb: (100, 128, 150), filter: imageAdjustmentsFilter(contrast: 2.0)), expected: (72, 128, 172));
      _expectClose(actual: await _filtered(tester: tester, rgb: (100, 128, 150), filter: imageAdjustmentsFilter(contrast: 0.5)), expected: (114, 128, 139));
    });

    testWidgets("shift warmth from blue to red", (final WidgetTester tester) async
    {
      _expectClose(actual: await _filtered(tester: tester, rgb: (100, 100, 100), filter: imageAdjustmentsFilter(warmth: 1.0)), expected: (115, 106, 85));
      _expectClose(actual: await _filtered(tester: tester, rgb: (100, 100, 100), filter: imageAdjustmentsFilter(warmth: -1.0)), expected: (85, 94, 115));
    });

    testWidgets("apply saturation, warmth, contrast and brightness in that order", (final WidgetTester tester) async
    {
      final (int, int, int) actual = await _filtered(
        tester: tester,
        rgb: (100, 100, 100),
        filter: imageAdjustmentsFilter(saturation: 0.5, warmth: 1.0, contrast: 2.0, brightness: 0.1),
      );

      //grey stays grey, warmed to 115|106|85, contrast to 102|84|42, then 25.5 brighter
      _expectClose(actual: actual, expected: (127.5, 109.5, 67.5));
    });
  });
}
