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

part of '../../export_functions.dart';

Future<Uint8List?> exportWebP({required final ImageExportData exportData, required final CoordinateSetI canvasSize, required final LayerCollection layerList, required final SelectionList selection}) async
{
  final ByteData byteData = await _getImageData(
    scaling: exportData.scaling,
    canvasSize: canvasSize,
    layerList: layerList,
    selection: selection,
  );
  final int width = canvasSize.x * exportData.scaling;
  final int height = canvasSize.y * exportData.scaling;

  return await runOffThread<Uint8List>(
    debugLabel: "webp-export",
    work: () => img.encodeWebP(img.Image.fromBytes(width: width, height: height, bytes: byteData.buffer, order: img.ChannelOrder.rgba, numChannels: 4)),
  );
}

Future<Uint8List?> exportWebPAnimation({required final AnimationExportData exportData}) async
{
  final List<RenderedFrame>? frames = await _renderAnimationFrames(exportData: exportData);
  if (frames == null || frames.isEmpty)
  {
    return null;
  }

  return await runOffThread<Uint8List>(
    debugLabel: "webp-animation-export",
    work: () => encodeAnimation(frames: frames, format: AnimationFormat.webp),
  );
}

/// The area of a frame that differs from the frame before it.
class _ChangedRect
{
  const _ChangedRect({required this.x, required this.y, required this.width, required this.height, required this.opaque});
  final int x;
  final int y;
  final int width;
  final int height;

  /// Whether every changed pixel is fully opaque, so drawing the area over the
  /// previous frame reproduces it exactly.
  final bool opaque;
}

/// Encodes [frames] as a lossless animated WebP.
///
/// Every frame after the first only stores the area that changed since the one
/// before, which the image package's own encoder does not do.
Uint8List _encodeWebPAnimation({required final List<RenderedFrame> frames})
{
  final int width = frames.first.width;
  final int height = frames.first.height;
  final BytesBuilder animationFrames = BytesBuilder(copy: false);
  bool hasAlpha = false;

  for (int i = 0; i < frames.length; i++)
  {
    final Uint8List pixels = frames[i].pixels;
    final Uint8List? previous = i > 0 ? frames[i - 1].pixels : null;
    hasAlpha = hasAlpha || _hasTransparency(pixels: pixels);

    final _ChangedRect rect = previous == null
      ? _ChangedRect(x: 0, y: 0, width: width, height: height, opaque: false)
      : _changedRect(current: pixels, previous: previous, width: width, height: height);
    Uint8List bitstream = _encodeVP8L(image: _cropFrame(pixels: pixels, frameWidth: width, rect: rect));
    bool blend = false;
    if (previous != null && rect.opaque)
    {
      //unchanged pixels left transparent let the previous frame show through, which often codes smaller
      final Uint8List withHoles = _encodeVP8L(image: _cropFrame(pixels: pixels, frameWidth: width, rect: rect, previous: previous));
      if (withHoles.length < bitstream.length)
      {
        bitstream = withHoles;
        blend = true;
      }
    }

    final ByteData header = ByteData(16);
    _setUint24(data: header, offset: 0, value: rect.x ~/ 2);
    _setUint24(data: header, offset: 3, value: rect.y ~/ 2);
    _setUint24(data: header, offset: 6, value: rect.width - 1);
    _setUint24(data: header, offset: 9, value: rect.height - 1);
    _setUint24(data: header, offset: 12, value: frames[i].durationMs.clamp(0, 0xFFFFFF));
    header.setUint8(15, blend ? 0x00 : 0x02); //0x02: do not blend, 0x01 (unused): dispose to background
    final BytesBuilder frame = BytesBuilder(copy: false)..add(header.buffer.asUint8List());
    _addRiffChunk(out: frame, id: "VP8L", payload: bitstream);
    _addRiffChunk(out: animationFrames, id: "ANMF", payload: frame.takeBytes());
  }

  final ByteData vp8x = ByteData(10);
  vp8x.setUint8(0, (hasAlpha ? 0x10 : 0x00) | 0x02); //alpha, animation
  _setUint24(data: vp8x, offset: 4, value: width - 1);
  _setUint24(data: vp8x, offset: 7, value: height - 1);
  final BytesBuilder chunks = BytesBuilder(copy: false);
  _addRiffChunk(out: chunks, id: "VP8X", payload: vp8x.buffer.asUint8List());
  _addRiffChunk(out: chunks, id: "ANIM", payload: Uint8List(6)); //transparent background, endless loop
  chunks.add(animationFrames.takeBytes());

  final ByteData riffHeader = ByteData(12);
  _setFourCC(data: riffHeader, offset: 0, id: "RIFF");
  riffHeader.setUint32(4, 4 + chunks.length, Endian.little);
  _setFourCC(data: riffHeader, offset: 8, id: "WEBP");
  return (BytesBuilder(copy: false)
    ..add(riffHeader.buffer.asUint8List())
    ..add(chunks.takeBytes()))
    .takeBytes();
}

_ChangedRect _changedRect({required final Uint8List current, required final Uint8List previous, required final int width, required final int height})
{
  int left = width;
  int top = height;
  int right = -1;
  int bottom = -1;
  bool opaque = true;
  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      final int p = (y * width + x) * 4;
      if (!_isSamePixel(a: current, b: previous, offset: p))
      {
        left = min(left, x);
        right = max(right, x);
        top = min(top, y);
        bottom = max(bottom, y);
        opaque = opaque && current[p + 3] == 255;
      }
    }
  }

  //an unchanged frame still needs an entry for its duration: one pixel drawn as it already is
  if (right < 0)
  {
    return const _ChangedRect(x: 0, y: 0, width: 1, height: 1, opaque: true);
  }

  //frame offsets are stored halved, so they have to be even
  left -= left % 2;
  top -= top % 2;
  return _ChangedRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1, opaque: opaque);
}

/// The [rect] of a frame; with [previous], the pixels that match it are left
/// fully transparent.
img.Image _cropFrame({required final Uint8List pixels, required final int frameWidth, required final _ChangedRect rect, final Uint8List? previous})
{
  final Uint8List cropped = Uint8List(rect.width * rect.height * 4);
  for (int y = 0; y < rect.height; y++)
  {
    final int source = ((rect.y + y) * frameWidth + rect.x) * 4;
    final int target = y * rect.width * 4;
    if (previous == null)
    {
      cropped.setRange(target, target + rect.width * 4, pixels, source);
      continue;
    }
    for (int x = 0; x < rect.width * 4; x += 4)
    {
      if (!_isSamePixel(a: pixels, b: previous, offset: source + x))
      {
        cropped.setRange(target + x, target + x + 4, pixels, source + x);
      }
    }
  }
  return img.Image.fromBytes(width: rect.width, height: rect.height, bytes: cropped.buffer, order: img.ChannelOrder.rgba, numChannels: 4);
}

/// Fully transparent pixels count as equal whatever their color.
bool _isSamePixel({required final Uint8List a, required final Uint8List b, required final int offset})
{
  final int alpha = a[offset + 3];
  return alpha == b[offset + 3] && (alpha == 0 || (a[offset] == b[offset] && a[offset + 1] == b[offset + 1] && a[offset + 2] == b[offset + 2]));
}

bool _hasTransparency({required final Uint8List pixels})
{
  for (int i = 3; i < pixels.length; i += 4)
  {
    if (pixels[i] != 255)
    {
      return true;
    }
  }
  return false;
}

/// The lossless bitstream of [image], taken out of the container the image
/// package wraps it in.
Uint8List _encodeVP8L({required final img.Image image})
{
  final Uint8List webp = img.encodeWebP(image, singleFrame: true);
  final ByteData data = ByteData.sublistView(webp);
  int offset = 12;
  while (offset + 8 <= webp.length)
  {
    final int size = data.getUint32(offset + 4, Endian.little);
    if (String.fromCharCodes(webp, offset, offset + 4) == "VP8L")
    {
      return Uint8List.sublistView(webp, offset + 8, offset + 8 + size);
    }
    offset += 8 + size + size % 2;
  }
  throw StateError("The WebP encoder wrote no lossless bitstream.");
}

void _addRiffChunk({required final BytesBuilder out, required final String id, required final Uint8List payload})
{
  final ByteData header = ByteData(8);
  _setFourCC(data: header, offset: 0, id: id);
  header.setUint32(4, payload.length, Endian.little);
  out.add(header.buffer.asUint8List());
  out.add(payload);
  if (payload.length.isOdd)
  {
    out.addByte(0);
  }
}

void _setFourCC({required final ByteData data, required final int offset, required final String id})
{
  for (int i = 0; i < 4; i++)
  {
    data.setUint8(offset + i, id.codeUnitAt(i));
  }
}

void _setUint24({required final ByteData data, required final int offset, required final int value})
{
  data.setUint16(offset, value & 0xFFFF, Endian.little);
  data.setUint8(offset + 2, value >> 16);
}
