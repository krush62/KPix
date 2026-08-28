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

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';

const int _size = 8;

List<RenderedFrame> _frames({required final int count})
{
  final List<RenderedFrame> frames = <RenderedFrame>[];
  for (int f = 0; f < count; f++)
  {
    final Uint8List pixels = Uint8List(_size * _size * 4);
    for (int i = 0; i < pixels.length; i += 4)
    {
      pixels[i] = (f * 40) % 256;
      pixels[i + 1] = 128;
      pixels[i + 2] = 64;
      pixels[i + 3] = 255;
    }
    frames.add(RenderedFrame(pixels: pixels, width: _size, height: _size, durationMs: 100));
  }
  return frames;
}

void main()
{
  test("a rendered animation payload survives the isolate hop", () async {
    final List<RenderedFrame> frames = _frames(count: 3);

    //mirrors what the gif exporter hands to the background isolate
    final Uint8List gif = await runOffThread<Uint8List>(
      debugLabel: "test-gif",
      work: ()
      {
        final img.Image animation = img.Image(width: _size, height: _size, numChannels: 4);
        for (int i = 0; i < frames.length; i++)
        {
          final RenderedFrame renderedFrame = frames[i];
          final img.Image frame = img.Image.fromBytes(
            width: renderedFrame.width,
            height: renderedFrame.height,
            bytes: renderedFrame.pixels.buffer,
            order: img.ChannelOrder.rgba,
            numChannels: 4,
            frameDuration: renderedFrame.durationMs,
          );
          if (i == 0)
          {
            animation.frames[0] = frame;
          }
          else
          {
            animation.addFrame(frame);
          }
        }
        return img.encodeGif(animation);
      },
    );

    expect(gif.length, greaterThan(0));
    expect(String.fromCharCodes(gif.sublist(0, 3)), "GIF");
  });

  test("zipping runs off thread and produces a readable archive", () async {
    final Map<String, Uint8List> files = <String, Uint8List>{
      "one.bin": Uint8List.fromList(<int>[1, 2, 3, 4]),
      "nested/two.bin": Uint8List.fromList(<int>[9, 8, 7]),
    };

    final Uint8List zipped = await runOffThread<Uint8List>(
      debugLabel: "test-zip",
      work: ()
      {
        final Archive archive = Archive();
        for (final MapEntry<String, Uint8List> file in files.entries)
        {
          final List<int> content = file.value.toList();
          archive.addFile(ArchiveFile(file.key, content.length, content));
        }
        return Uint8List.fromList(ZipEncoder().encode(archive));
      },
    );

    final Archive readBack = ZipDecoder().decodeBytes(zipped);
    expect(readBack.files.map((final ArchiveFile f) => f.name).toSet(), files.keys.toSet());
  });

  test("the UI isolate keeps running while the work is off thread", () async {
    int ticks = 0;
    bool done = false;

    //a heartbeat that can only advance if the main isolate is not blocked
    Future<void> beat() async
    {
      while (!done)
      {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        ticks++;
      }
    }

    final Future<void> heartbeat = beat();
    await runOffThread<int>(
      debugLabel: "test-busy",
      work: ()
      {
        int sum = 0;
        for (int i = 0; i < 40000000; i++)
        {
          sum += i % 7;
        }
        return sum;
      },
    );
    done = true;
    await heartbeat;

    expect(ticks, greaterThan(0));
  });
}
