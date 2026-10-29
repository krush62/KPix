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

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/util/export_functions.dart';

const int _size = 8;

//neighbours this close are what a quantizer merges or shifts
const List<List<int>> _colors = <List<int>>[
  <int>[200, 40, 40],
  <int>[202, 40, 40],
  <int>[20, 120, 220],
  <int>[21, 121, 221],
  <int>[250, 250, 250],
];

final Map<AnimationFormat, img.Image? Function(Uint8List)> _decoders = <AnimationFormat, img.Image? Function(Uint8List)>{
  AnimationFormat.gif: img.decodeGif,
  AnimationFormat.apng: img.decodePng,
  AnimationFormat.webp: img.decodeWebP,
};

/// A frame with a transparent border around a pattern that moves with [shift].
RenderedFrame _frame({required final int shift, final int durationMs = 100})
{
  final Uint8List pixels = Uint8List(_size * _size * 4);
  for (int y = 1; y < _size - 1; y++)
  {
    for (int x = 1; x < _size - 1; x++)
    {
      final List<int> color = _colors[(x + y + shift) % _colors.length];
      final int i = (y * _size + x) * 4;
      pixels[i] = color[0];
      pixels[i + 1] = color[1];
      pixels[i + 2] = color[2];
      pixels[i + 3] = 255;
    }
  }
  return RenderedFrame(pixels: pixels, width: _size, height: _size, durationMs: durationMs);
}

/// How many pixels of [decoded] differ from [frames]; transparent pixels match
/// whatever their color.
int _differingPixels({required final img.Image decoded, required final List<RenderedFrame> frames})
{
  int differing = 0;
  for (int f = 0; f < frames.length; f++)
  {
    final Uint8List expected = frames[f].pixels;
    int i = 0;
    for (final img.Pixel p in decoded.frames[f])
    {
      final int alpha = expected[i + 3];
      final bool same = p.a.toInt() == alpha && (alpha == 0 || (p.r.toInt() == expected[i] && p.g.toInt() == expected[i + 1] && p.b.toInt() == expected[i + 2]));
      if (!same)
      {
        differing++;
      }
      i += 4;
    }
  }
  return differing;
}

img.Image _roundTrip({required final List<RenderedFrame> frames, required final AnimationFormat format})
{
  final img.Image? decoded = _decoders[format]!(encodeAnimation(frames: frames, format: format));
  expect(decoded, isNotNull);
  expect(decoded!.numFrames, frames.length);
  return decoded;
}

/// [frame] with the pixels in [transparent] cleared.
RenderedFrame _withCleared({required final RenderedFrame frame, required final List<int> transparent})
{
  final Uint8List pixels = Uint8List.fromList(frame.pixels);
  for (final int index in transparent)
  {
    pixels.fillRange(index * 4, index * 4 + 4, 0);
  }
  return RenderedFrame(pixels: pixels, width: frame.width, height: frame.height, durationMs: frame.durationMs);
}

/// The x, y, width and height that every frame of an animated WebP covers.
List<List<int>> _webpFrameRects({required final Uint8List webp})
{
  final ByteData data = ByteData.sublistView(webp);
  int uint24(final int offset) => data.getUint16(offset, Endian.little) | (data.getUint8(offset + 2) << 16);
  final List<List<int>> rects = <List<int>>[];
  int offset = 12;
  while (offset + 8 <= webp.length)
  {
    final int size = data.getUint32(offset + 4, Endian.little);
    if (String.fromCharCodes(webp, offset, offset + 4) == "ANMF")
    {
      final int p = offset + 8;
      rects.add(<int>[uint24(p) * 2, uint24(p + 3) * 2, uint24(p + 6) + 1, uint24(p + 9) + 1]);
    }
    offset += 8 + size + size % 2;
  }
  return rects;
}

void main()
{
  for (final AnimationFormat format in AnimationFormat.values)
  {
    test("${format.name} keeps exact colors and transparency", ()
    {
      final List<RenderedFrame> frames = <RenderedFrame>[_frame(shift: 0), _frame(shift: 1), _frame(shift: 2)];
      expect(_differingPixels(decoded: _roundTrip(frames: frames, format: format), frames: frames), 0);
    });

    test("${format.name} exports a single frame", ()
    {
      final List<RenderedFrame> frames = <RenderedFrame>[_frame(shift: 0)];
      expect(_differingPixels(decoded: _roundTrip(frames: frames, format: format), frames: frames), 0);
    });
  }

  test("gif keeps frame durations", ()
  {
    final List<int> durations = <int>[100, 250, 40];
    final List<RenderedFrame> frames = <RenderedFrame>[
      for (int i = 0; i < durations.length; i++) _frame(shift: i, durationMs: durations[i]),
    ];
    final img.Image decoded = _roundTrip(frames: frames, format: AnimationFormat.gif);
    expect(decoded.frames.map((final img.Image f) => f.frameDuration).toList(), durations);
  });

  test("webp keeps frame durations and repeated frames", ()
  {
    final List<RenderedFrame> frames = <RenderedFrame>[
      _frame(shift: 0),
      _frame(shift: 0, durationMs: 250),
      _frame(shift: 1, durationMs: 40),
      _frame(shift: 0, durationMs: 70),
    ];
    final img.Image decoded = _roundTrip(frames: frames, format: AnimationFormat.webp);
    expect(decoded.frames.map((final img.Image f) => f.frameDuration).toList(), <int>[100, 250, 40, 70]);
    expect(_differingPixels(decoded: decoded, frames: frames), 0);
  });

  test("webp keeps pixels that turn transparent and back", ()
  {
    final RenderedFrame full = _frame(shift: 0);
    final List<RenderedFrame> frames = <RenderedFrame>[
      full,
      _withCleared(frame: full, transparent: <int>[9, 10, 27, 28]),
      _withCleared(frame: full, transparent: <int>[28]),
    ];
    expect(_differingPixels(decoded: _roundTrip(frames: frames, format: AnimationFormat.webp), frames: frames), 0);
  });

  test("webp stores a small change as a small frame", ()
  {
    const int width = 64;
    final Uint8List first = Uint8List(width * width * 4);
    for (int i = 0; i < width * width; i++)
    {
      first.setAll(i * 4, <int>[i % 7 * 30, i % 5 * 50, 90, 255]);
    }
    final Uint8List second = Uint8List.fromList(first);
    for (final int index in <int>[31 * width + 21, 33 * width + 22])
    {
      second.setAll(index * 4, <int>[255, 255, 255, 255]);
    }
    final List<RenderedFrame> frames = <RenderedFrame>[
      RenderedFrame(pixels: first, width: width, height: width, durationMs: 100),
      RenderedFrame(pixels: second, width: width, height: width, durationMs: 100),
    ];

    final Uint8List webp = encodeAnimation(frames: frames, format: AnimationFormat.webp);
    //offsets snap down to even coordinates
    expect(_webpFrameRects(webp: webp), <List<int>>[<int>[0, 0, width, width], <int>[20, 30, 3, 4]]);
    expect(_differingPixels(decoded: img.decodeWebP(webp)!, frames: frames), 0);
  });

  test("gif with more colors than a palette holds still exports", ()
  {
    const int width = 32;
    final Uint8List pixels = Uint8List(width * width * 4);
    for (int i = 0; i < width * width; i++)
    {
      pixels[i * 4] = i & 0xFF;
      pixels[i * 4 + 1] = i >> 8;
      pixels[i * 4 + 2] = 128;
      pixels[i * 4 + 3] = 255;
    }
    final Uint8List gif = encodeAnimation(
      frames: <RenderedFrame>[RenderedFrame(pixels: pixels, width: width, height: width, durationMs: 100)],
      format: AnimationFormat.gif,
    );
    expect(img.decodeGif(gif)?.width, width);
  });
}
