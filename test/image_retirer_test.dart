import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/util/helpers/image_helper.dart';

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
