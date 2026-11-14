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

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/util/helpers/image_helper.dart';
import 'package:material_ui/material_ui.dart';

Future<ui.Image> _image() async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = const Color(0xFFCC3333));
  return recorder.endRecording().toImage(2, 2);
}

Future<List<ui.Image>> _images(final WidgetTester tester, final int count) async
{
  final List<ui.Image> images = <ui.Image>[];
  await tester.runAsync(() async {
    for (int i = 0; i < count; i++)
    {
      images.add(await _image());
    }
  });
  return images;
}

void main()
{
  group("disposeAfterFrame", () {
    testWidgets("waits for the frame", (final WidgetTester tester) async {
      final List<ui.Image> images = await _images(tester, 2);
      disposeAfterFrame(images: images);
      expect(images[0].debugDisposed, false);
      expect(images[1].debugDisposed, false);

      await tester.pump();
      expect(images[0].debugDisposed, true);
      expect(images[1].debugDisposed, true);
    });

    testWidgets("asks for a frame itself", (final WidgetTester tester) async {
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, false);
      final List<ui.Image> images = await _images(tester, 1);
      disposeAfterFrame(images: images);
      expect(tester.binding.hasScheduledFrame, true);
      await tester.pump();
    });
  });

  group("ImageRetirer", () {
    testWidgets("waits for the frame", (final WidgetTester tester) async {
      final List<ui.Image> images = await _images(tester, 1);
      ImageRetirer().retire(image: images[0]);
      expect(images[0].debugDisposed, false);

      await tester.pump();
      expect(images[0].debugDisposed, true);
    });

    testWidgets("asks for a frame itself", (final WidgetTester tester) async {
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, false);
      final List<ui.Image> images = await _images(tester, 1);
      ImageRetirer().retire(image: images[0]);
      expect(tester.binding.hasScheduledFrame, true);
      await tester.pump();
    });

    testWidgets("takes everything retired before that frame along, once", (final WidgetTester tester) async {
      final List<ui.Image> images = await _images(tester, 3);
      final ImageRetirer retirer = ImageRetirer();
      for (final ui.Image image in images)
      {
        retirer.retire(image: image);
      }
      await tester.pump();
      for (final ui.Image image in images)
      {
        expect(image.debugDisposed, true);
      }
    });

    testWidgets("schedules again for images after a flush", (final WidgetTester tester) async {
      final List<ui.Image> images = await _images(tester, 2);
      final ImageRetirer retirer = ImageRetirer();
      retirer.retire(image: images[0]);
      await tester.pump();

      retirer.retire(image: images[1]);
      expect(images[1].debugDisposed, false);
      await tester.pump();
      expect(images[1].debugDisposed, true);
    });

    testWidgets("can be told to dispose right away", (final WidgetTester tester) async {
      final List<ui.Image> images = await _images(tester, 2);
      final ImageRetirer retirer = ImageRetirer();
      retirer.retire(image: images[0]);
      retirer.retire(image: images[1]);

      retirer.disposeNow();
      expect(images[0].debugDisposed, true);
      expect(images[1].debugDisposed, true);

      //the flush that is still scheduled has nothing left to do
      await tester.pump();
    });
  });
}
