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

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/util/helpers/geometry_helper.dart';

/// Minimal readers for the file formats there is no decoder for, written from
/// the format descriptions. They prove structure and pixels; whether the real
/// applications accept a file is a manual check.
///
/// All of them are synchronous: hot typed data loops inside an async test body
/// crash flutter_tester.

/// One layer of an exported file, as the file holds it.
class ExportedLayer
{
  final bool visible;
  final bool locked;

  /// The opaque pixels as 0xRRGGBB.
  final Map<CoordinateSetI, int> pixels;

  const ExportedLayer({required this.visible, required this.locked, required this.pixels});
}

/// An exported project, with its layers top to bottom.
class ExportedProject
{
  final int width;
  final int height;
  final List<ExportedLayer> layers;

  const ExportedProject({required this.width, required this.height, required this.layers});
}

int _rgb(final int r, final int g, final int b) => (r << 16) | (g << 8) | b;

String _ascii(final Uint8List bytes, final int start, final int end) => String.fromCharCodes(bytes, start, end);

class AsepriteFile extends ExportedProject
{
  final int transparentIndex;

  /// The colors as 0xRRGGBB, from the current palette chunk.
  final List<int> palette;

  /// The colors as 0xRRGGBB, from the palette chunk older readers use.
  final List<int> oldPalette;

  /// The color index of every pixel of every cel, bottom layer first.
  final List<Uint8List> celIndices;

  const AsepriteFile({required super.width, required super.height, required super.layers, required this.transparentIndex, required this.palette, required this.oldPalette, required this.celIndices});
}

/// Walks the chunks by their declared sizes, so a size that does not match what
/// was written ends up reading garbage or missing the end of the file.
AsepriteFile readAseprite({required final Uint8List bytes})
{
  final ByteData data = ByteData.sublistView(bytes);
  int u16(final int at) => data.getUint16(at, Endian.little);
  int u32(final int at) => data.getUint32(at, Endian.little);
  const int headerSize = 128;
  const int frameHeaderSize = 16;

  expect(u32(0), bytes.length, reason: "file size");
  expect(u16(4), 0xA5E0, reason: "magic number");
  expect(u16(6), 1, reason: "frame count");
  expect(u16(12), 8, reason: "color depth");
  final int width = u16(8);
  final int height = u16(10);
  final int transparentIndex = data.getUint8(28);

  expect(u32(headerSize), bytes.length - headerSize, reason: "frame size");
  expect(u16(headerSize + 4), 0xF1FA, reason: "frame magic number");
  final int chunkCount = u32(headerSize + 12);
  expect(u16(headerSize + 6), chunkCount, reason: "both chunk counts");

  final List<int> palette = <int>[];
  final List<int> oldPalette = <int>[];
  final List<({bool visible, bool locked})> layerFlags = <({bool visible, bool locked})>[];
  final Map<int, Uint8List> cels = <int, Uint8List>{};

  int offset = headerSize + frameHeaderSize;
  for (int c = 0; c < chunkCount; c++)
  {
    final int size = u32(offset);
    final int type = u16(offset + 4);
    final int body = offset + 6;
    if (type == 0x2019)
    {
      final int count = u32(body);
      expect(u32(body + 4), 0, reason: "first palette index");
      expect(u32(body + 8), count - 1, reason: "last palette index");
      for (int i = 0; i < count; i++)
      {
        final int entry = body + 20 + i * 6;
        expect(u16(entry), 0, reason: "palette entries carry no name");
        expect(bytes[entry + 5], 255, reason: "palette entries are opaque");
        palette.add(_rgb(bytes[entry + 2], bytes[entry + 3], bytes[entry + 4]));
      }
    }
    else if (type == 0x0004)
    {
      expect(u16(body), 1, reason: "old palette packet count");
      final int count = bytes[body + 3] == 0 ? 256 : bytes[body + 3];
      for (int i = 0; i < count; i++)
      {
        final int entry = body + 4 + i * 3;
        oldPalette.add(_rgb(bytes[entry], bytes[entry + 1], bytes[entry + 2]));
      }
    }
    else if (type == 0x2004)
    {
      final int flags = u16(body);
      final int nameLength = u16(body + 16);
      expect(size, 24 + nameLength, reason: "layer chunk size");
      layerFlags.add((visible: flags & 1 != 0, locked: flags & 2 == 0));
    }
    else if (type == 0x2005)
    {
      expect(u16(body + 7), 2, reason: "compressed cel");
      expect(u16(body + 16), width, reason: "cel width");
      expect(u16(body + 18), height, reason: "cel height");
      final Uint8List indices = Uint8List.fromList(const ZLibDecoder().decodeBytes(Uint8List.sublistView(bytes, body + 20, offset + size), verify: true));
      expect(indices.length, width * height, reason: "cel size");
      cels[u16(body)] = indices;
    }
    else
    {
      expect(type, 0x2007, reason: "known chunk");
    }
    offset += size;
  }
  expect(offset, bytes.length, reason: "the chunks fill the file exactly");

  final List<Uint8List> celIndices = <Uint8List>[];
  final List<ExportedLayer> layers = <ExportedLayer>[];
  for (int l = 0; l < layerFlags.length; l++)
  {
    final Uint8List indices = cels[l]!;
    celIndices.add(indices);
    final Map<CoordinateSetI, int> pixels = <CoordinateSetI, int>{};
    for (int i = 0; i < indices.length; i++)
    {
      if (indices[i] != transparentIndex)
      {
        pixels[CoordinateSetI(x: i % width, y: i ~/ width)] = palette[indices[i]];
      }
    }
    layers.insert(0, ExportedLayer(visible: layerFlags[l].visible, locked: layerFlags[l].locked, pixels: pixels));
  }
  return AsepriteFile(width: width, height: height, layers: layers, transparentIndex: transparentIndex, palette: palette, oldPalette: oldPalette, celIndices: celIndices);
}

class XcfFile extends ExportedProject
{
  /// The colors as 0xRRGGBB.
  final List<int> colorMap;

  const XcfFile({required super.width, required super.height, required super.layers, required this.colorMap});
}

/// Follows the pointers of an indexed, zlib compressed xcf of version 11.
XcfFile readXcf({required final Uint8List bytes})
{
  final ByteData data = ByteData.sublistView(bytes);
  int u32(final int at) => data.getUint32(at);
  int u64(final int at) => data.getUint64(at);
  const int tileSize = 64;

  expect(_ascii(bytes, 0, 14), "gimp xcf v011\x00", reason: "magic number");
  final int width = u32(14);
  final int height = u32(18);
  expect(u32(22), 2, reason: "indexed base type");
  int offset = 30;

  final List<int> colorMap = <int>[];
  for (;;)
  {
    final int type = u32(offset);
    final int size = u32(offset + 4);
    final int body = offset + 8;
    offset = body + size;
    if (type == 0)
    {
      break;
    }
    if (type == 1)
    {
      final int count = u32(body);
      expect(size, 4 + count * 3, reason: "color map size");
      for (int i = 0; i < count; i++)
      {
        final int entry = body + 4 + i * 3;
        colorMap.add(_rgb(bytes[entry], bytes[entry + 1], bytes[entry + 2]));
      }
    }
    else if (type == 17)
    {
      expect(bytes[body], 2, reason: "zlib compression");
    }
  }

  final List<int> layerPointers = <int>[];
  for (int pointer = u64(offset); pointer != 0; pointer = u64(offset))
  {
    layerPointers.add(pointer);
    offset += 8;
  }

  final List<ExportedLayer> layers = <ExportedLayer>[];
  for (final int pointer in layerPointers)
  {
    expect(u32(pointer), width, reason: "layer width");
    expect(u32(pointer + 4), height, reason: "layer height");
    expect(u32(pointer + 8), 5, reason: "indexed layer with alpha");
    final int nameLength = u32(pointer + 12);
    expect(bytes[pointer + 16 + nameLength - 1], 0, reason: "terminated layer name");
    int at = pointer + 16 + nameLength;

    bool visible = false;
    bool locked = false;
    for (;;)
    {
      final int type = u32(at);
      final int size = u32(at + 4);
      final int body = at + 8;
      at = body + size;
      if (type == 0)
      {
        break;
      }
      if (type == 8)
      {
        visible = u32(body) == 1;
      }
      else if (type == 28)
      {
        locked = u32(body) == 1;
      }
    }

    final int hierarchy = u64(at);
    expect(u64(at + 8), 0, reason: "no layer mask");
    expect(u32(hierarchy), width, reason: "hierarchy width");
    expect(u32(hierarchy + 4), height, reason: "hierarchy height");
    expect(u32(hierarchy + 8), 2, reason: "index and alpha");
    final int level = u64(hierarchy + 12);
    final int nextLevel = u64(hierarchy + 20);
    expect(u32(level), width, reason: "level width");
    expect(u32(level + 4), height, reason: "level height");

    final List<int> tilePointers = <int>[];
    for (int tile = level + 8; u64(tile) != 0; tile += 8)
    {
      tilePointers.add(u64(tile));
    }
    final int tilesX = (width + tileSize - 1) ~/ tileSize;
    final int tilesY = (height + tileSize - 1) ~/ tileSize;
    expect(tilePointers.length, tilesX * tilesY, reason: "tile count");

    final Map<CoordinateSetI, int> pixels = <CoordinateSetI, int>{};
    for (int t = 0; t < tilePointers.length; t++)
    {
      final int end = t + 1 < tilePointers.length ? tilePointers[t + 1] : nextLevel;
      final Uint8List tile = Uint8List.fromList(const ZLibDecoder().decodeBytes(Uint8List.sublistView(bytes, tilePointers[t], end), verify: true));
      final int left = (t % tilesX) * tileSize;
      final int top = (t ~/ tilesX) * tileSize;
      final int tileWidth = (width - left).clamp(0, tileSize);
      final int tileHeight = (height - top).clamp(0, tileSize);
      expect(tile.length, tileWidth * tileHeight * 2, reason: "tile size");
      for (int i = 0; i < tileWidth * tileHeight; i++)
      {
        if (tile[i * 2 + 1] != 0)
        {
          pixels[CoordinateSetI(x: left + i % tileWidth, y: top + i ~/ tileWidth)] = colorMap[tile[i * 2]];
        }
      }
    }
    layers.add(ExportedLayer(visible: visible, locked: locked, pixels: pixels));
  }
  return XcfFile(width: width, height: height, layers: layers, colorMap: colorMap);
}

/// Pairs the entries of the layer list with the files they describe: the entry
/// at position n belongs to the images named `n + 1`.
ExportedProject readPixelorama({required final Uint8List bytes})
{
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final Map<String, dynamic> json = jsonDecode(utf8.decode(archive.findFile("data.json")!.content)) as Map<String, dynamic>;
  final int width = json["size_x"] as int;
  final int height = json["size_y"] as int;
  final List<dynamic> layerEntries = json["layers"] as List<dynamic>;
  final List<dynamic> frames = json["frames"] as List<dynamic>;
  expect(frames, hasLength(1), reason: "frame count");
  expect((frames.single as Map<String, dynamic>)["cels"], hasLength(layerEntries.length), reason: "one cel per layer");

  final List<ExportedLayer> layers = <ExportedLayer>[];
  for (int l = 0; l < layerEntries.length; l++)
  {
    final Map<String, dynamic> entry = layerEntries[l] as Map<String, dynamic>;
    final Uint8List image = archive.findFile("image_data/frames/1/layer_${l + 1}")!.content;
    final Uint8List indices = archive.findFile("image_data/frames/1/indices_layer_${l + 1}")!.content;
    expect(image.length, width * height * 4, reason: "layer size");
    expect(indices.length, width * height, reason: "index size");
    final Map<CoordinateSetI, int> pixels = <CoordinateSetI, int>{};
    for (int i = 0; i < width * height; i++)
    {
      final int alpha = image[i * 4 + 3];
      expect(alpha == 0 || alpha == 255, isTrue, reason: "pixel art has no partial alpha");
      expect(indices[i] != 0, alpha != 0, reason: "the index is set where the pixel is");
      if (alpha != 0)
      {
        pixels[CoordinateSetI(x: i % width, y: i ~/ width)] = _rgb(image[i * 4], image[i * 4 + 1], image[i * 4 + 2]);
      }
    }
    layers.insert(0, ExportedLayer(visible: entry["visible"] as bool, locked: entry["locked"] as bool, pixels: pixels));
  }
  return ExportedProject(width: width, height: height, layers: layers);
}

/// A psd as package:image reads it, an independent decoder.
class PsdFile extends ExportedProject
{
  /// The composite, which has no alpha: empty pixels read as black.
  final Map<CoordinateSetI, int> merged;

  /// Whether the transparency of each layer is protected, top to bottom.
  final List<bool> transparencyLocked;

  const PsdFile({required super.width, required super.height, required super.layers, required this.merged, required this.transparencyLocked});
}

PsdFile readPsd({required final Uint8List bytes})
{
  final img.PsdImage psd = img.PsdDecoder().decodePsd(bytes)!;
  final List<ExportedLayer> layers = <ExportedLayer>[];
  final List<bool> transparencyLocked = <bool>[];
  for (final img.PsdLayer layer in psd.layers)
  {
    final Map<CoordinateSetI, int> pixels = <CoordinateSetI, int>{};
    final img.Image image = layer.layerImage!;
    for (final img.Pixel p in image)
    {
      if (p.a != 0)
      {
        pixels[CoordinateSetI(x: p.x, y: p.y)] = _rgb(p.r.toInt(), p.g.toInt(), p.b.toInt());
      }
    }
    //psd stores the bottom layer first; locking the content has no equivalent here
    layers.insert(0, ExportedLayer(visible: layer.isVisible(), locked: false, pixels: pixels));
    transparencyLocked.insert(0, layer.flags & 1 != 0);
  }
  final Map<CoordinateSetI, int> merged = <CoordinateSetI, int>{};
  for (final img.Pixel p in psd.mergedImage!)
  {
    final int rgb = _rgb(p.r.toInt(), p.g.toInt(), p.b.toInt());
    if (rgb != 0)
    {
      merged[CoordinateSetI(x: p.x, y: p.y)] = rgb;
    }
  }
  return PsdFile(width: psd.width, height: psd.height, layers: layers, merged: merged, transparencyLocked: transparencyLocked);
}

/// One color of an Adobe swatch exchange file.
class AdobeColor
{
  final String name;
  final String model;
  final double red;
  final double green;
  final double blue;
  final int type;

  const AdobeColor({required this.name, required this.model, required this.red, required this.green, required this.blue, required this.type});
}

/// Reads an ase file and holds every block to the length it declares.
List<AdobeColor> readAdobePalette({required final Uint8List bytes})
{
  final ByteData data = ByteData.sublistView(bytes);
  expect(_ascii(bytes, 0, 4), "ASEF", reason: "signature");
  expect(data.getUint16(4), 1, reason: "major version");
  expect(data.getUint16(6), 0, reason: "minor version");
  final int count = data.getUint32(8);

  final List<AdobeColor> colors = <AdobeColor>[];
  int offset = 12;
  for (int i = 0; i < count; i++)
  {
    expect(data.getUint16(offset), 1, reason: "color block $i");
    final int length = data.getUint32(offset + 2);
    final int end = offset + 6 + length;
    int at = offset + 6;
    final int nameLength = data.getUint16(at);
    at += 2;
    final StringBuffer name = StringBuffer();
    for (int c = 0; c < nameLength - 1; c++)
    {
      name.writeCharCode(data.getUint16(at));
      at += 2;
    }
    expect(data.getUint16(at), 0, reason: "terminated name of color $i");
    at += 2;
    final String model = _ascii(bytes, at, at + 4);
    at += 4;
    final double red = data.getFloat32(at);
    final double green = data.getFloat32(at + 4);
    final double blue = data.getFloat32(at + 8);
    final int type = data.getUint16(at + 12);
    at += 14;
    expect(at, end, reason: "color $i fills its block exactly");
    colors.add(AdobeColor(name: name.toString(), model: model, red: red, green: green, blue: blue, type: type));
    offset = end;
  }
  expect(offset, bytes.length, reason: "the blocks fill the file exactly");
  return colors;
}
