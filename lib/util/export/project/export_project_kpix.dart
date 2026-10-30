/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

part of '../../export_functions.dart';

/// The pixels to write for [layer]: its own, plus the floating selection's for
/// the selected layer. Codes as in PaletteCodec, relative to the saved ramps.
PixelGridView _layerPixelsForSaving({
  required final HistoryDrawingLayer layer,
  required final HistorySelectionState selection,
  required final bool isSelectedLayer,
})
{
  if (!isSelectedLayer || selection.isEmpty)
  {
    return layer.pixels;
  }

  final PixelGrid merged = PixelGrid.fromSnapshot(snapshot: layer.pixels);
  selection.pixels!.forEach(action: (final int x, final int y, final int code)
  {
    //the grid drops floating pixels that are off the canvas
    if (code != PaletteCodec.transparent)
    {
      merged.set(x: x, y: y, value: code);
    }
  },);
  return merged;
}

typedef _PixelBounds = ({int left, int top, int width, int height});

/// The smallest box around the non-zero pixels; width and height are 0 when there are none.
_PixelBounds _boundsOf({required final PixelGridView pixels})
{
  if (pixels.isEmpty)
  {
    return (left: 0, top: 0, width: 0, height: 0);
  }
  int left = pixels.width;
  int top = pixels.height;
  int right = 0;
  int bottom = 0;
  pixels.forEachNonZero(action: (final int x, final int y, final int _)
  {
    left = min(left, x);
    top = min(top, y);
    right = max(right, x);
    bottom = max(bottom, y);
  },);
  return (left: left, top: top, width: right - left + 1, height: bottom - top + 1);
}

void _writeBounds({required final ByteData block, required final _PixelBounds bounds})
{
  block.setUint16(0, bounds.left);
  block.setUint16(2, bounds.top);
  block.setUint16(4, bounds.width);
  block.setUint16(6, bounds.height);
}

Uint8List _encodeDrawingPixels({required final PixelGridView pixels})
{
  final _PixelBounds bounds = _boundsOf(pixels: pixels);
  final Set<int> usedCodes = <int>{};
  pixels.forEachNonZero(action: (final int x, final int y, final int code) => usedCodes.add(code));
  final List<int> colors = usedCodes.toList()..sort();
  final bool wideIndices = colors.length > 255;

  final ByteData block = ByteData(8 + (colors.isEmpty ? 0 : 2 + colors.length * 2 + bounds.width * bounds.height * (wideIndices ? 2 : 1)));
  _writeBounds(block: block, bounds: bounds);
  if (colors.isEmpty)
  {
    return block.buffer.asUint8List();
  }
  int offset = 8;
  block.setUint16(offset, colors.length);
  offset += 2;
  final Uint16List colorIndices = Uint16List(colors.last + 1);
  for (int i = 0; i < colors.length; i++)
  {
    block.setUint8(offset++, PaletteCodec.rampIndexOf(code: colors[i]));
    block.setUint8(offset++, PaletteCodec.colorIndexOf(code: colors[i]));
    colorIndices[colors[i]] = i + 1;
  }
  final int pixelStart = offset;
  pixels.forEachNonZero(action: (final int x, final int y, final int code)
  {
    final int pixel = (y - bounds.top) * bounds.width + (x - bounds.left);
    if (wideIndices)
    {
      block.setUint16(pixelStart + pixel * 2, colorIndices[code]);
    }
    else
    {
      block.setUint8(pixelStart + pixel, colorIndices[code]);
    }
  },);
  return block.buffer.asUint8List();
}

Uint8List _encodeShadingPixels({required final PixelGridView pixels})
{
  final _PixelBounds bounds = _boundsOf(pixels: pixels);
  final Uint8List block = Uint8List(8 + bounds.width * bounds.height);
  _writeBounds(block: ByteData.sublistView(block), bounds: bounds);
  pixels.forEachSigned(action: (final int x, final int y, final int value)
  {
    block[8 + (y - bounds.top) * bounds.width + (x - bounds.left)] = value + shadingValueOffset;
  },);
  return block;
}

/// Serialises [state], or the live document when none is given.
Future<ByteData> createKPixData({final HistoryState? state}) async
{
  final HistoryState saveData = state ?? HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.saveData);
  final FileByteWriter writer = FileByteWriter();

  //HEADER
  writer.setUint32(int.parse(magicNumber, radix: 16));
  writer.setUint8(fileVersion);
  final int headerLength = writer.length;

  //PALETTE
  writer.setUint8(saveData.rampList.length);
  for (final HistoryRampData ramp in saveData.rampList)
  {
    _writeRamp(writer: writer, ramp: ramp);
  }

  //IMAGE
  //columns
  writer.setUint16(saveData.canvasSize.x);
  //rows
  writer.setUint16(saveData.canvasSize.y);

  //LAYERS
  final LinkedHashSet<HistoryLayer> allLayers = saveData.timeline.allLayers;
  final HistoryFrame selectedFrame = saveData.timeline.frames[saveData.timeline.selectedFrameIndex];
  final HistoryLayer selectedLayer = allLayers.elementAt(selectedFrame.layerIndices.elementAt(selectedFrame.selectedLayerIndex));
  writer.setUint16(allLayers.length);
  for (final HistoryLayer layer in allLayers)
  {
    //layer type
    writer.setUint8(historyLayerTypeToId[layer.runtimeType]!);
    //visibility
    writer.setUint8(layer.visibilityState.id);

    if (layer is HistoryDrawingLayer)
    {
      _writeDrawingLayer(writer: writer, layer: layer, pixels: _layerPixelsForSaving(layer: layer, selection: saveData.selectionState, isSelectedLayer: layer == selectedLayer));
    }
    else if (layer is HistoryReferenceLayer)
    {
      _writeReferenceLayer(writer: writer, layer: layer);
    }
    else if (layer is HistoryGridLayer)
    {
      _writeGridLayer(writer: writer, layer: layer);
    }
    else if (layer is HistoryShadingLayer) //SHADING AND DITHERING
    {
      _writeShadingLayer(writer: writer, layer: layer);
    }
  }

  //TIMELINE
  _writeTimeline(writer: writer, timeline: saveData.timeline);

  //everything after the header is compressed
  final Uint8List bytes = writer.bytes;
  final Uint8List body = const ZLibEncoder().encodeBytes(Uint8List.sublistView(bytes, headerLength));
  final Uint8List file = Uint8List(headerLength + body.length)
    ..setAll(0, Uint8List.sublistView(bytes, 0, headerLength))
    ..setAll(headerLength, body);
  return ByteData.sublistView(file);
}

void _writeRamp({required final FileByteWriter writer, required final HistoryRampData ramp})
{
  final KPalRampSettings rampSettings = ramp.settings;
  //color count
  writer.setUint8(rampSettings.colorCount);
  //base hue
  writer.setUint16(rampSettings.baseHue);
  //base sat
  writer.setUint8(rampSettings.baseSat);
  //hue shift
  writer.setInt8(rampSettings.hueShift);
  //hue shift exp
  writer.setUint8((rampSettings.hueShiftExp * 100).round());
  //sat shift
  writer.setInt8(rampSettings.satShift);
  //sat shift exp
  writer.setUint8((rampSettings.satShiftExp * 100).round());
  //sat curve
  writer.setUint8(rampSettings.satCurve.id);
  //val min
  writer.setUint8(rampSettings.valueRangeMin);
  //val max
  writer.setUint8(rampSettings.valueRangeMax);
  //color shifts
  for (int j = 0; j < rampSettings.colorCount; j++)
  {
    //hue shift
    writer.setInt8(ramp.shiftSets[j].hueShift);
    //sat shift
    writer.setInt8(ramp.shiftSets[j].satShift);
    //val shift
    writer.setInt8(ramp.shiftSets[j].valShift);
  }
}

void _writeDrawingLayer({required final FileByteWriter writer, required final HistoryDrawingLayer layer, required final PixelGridView pixels})
{
  //lock type
  writer.setUint8(layer.lockState.id);
  //* outer_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = relative, ``03`` = glow, ``04`` = shade
  writer.setUint8(layer.settings.outerStrokeStyle.id);
  //* outer_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
  writer.setUint8(_packAlignments(alignments: layer.settings.outerSelectionMap));
  //* outer_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
  writer.setUint8(layer.settings.outerColorReference.rampIndex);
  //* outer_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
  writer.setUint8(layer.settings.outerColorReference.colorIndex);
  //* outer_stroke_darken_brighten ``byte (1)`` // shading amount for relative/shade -5...5
  writer.setInt8(layer.settings.outerDarkenBrighten);
  //* outer_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
  writer.setInt8(layer.settings.outerGlowDepth);
  //* outer_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
  writer.setInt8(layer.settings.outerGlowRecursive ? 1 : 0);
  //* inner_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = bevel, ``03`` = glow, ``04`` = shade
  writer.setUint8(layer.settings.innerStrokeStyle.id);
  //* inner_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
  writer.setUint8(_packAlignments(alignments: layer.settings.innerSelectionMap));
  //* inner_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
  writer.setUint8(layer.settings.innerColorReference.rampIndex);
  //* inner_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
  writer.setUint8(layer.settings.innerColorReference.colorIndex);
  //* inner_stroke_darken_brighten ``byte (1)`` // shading amount for shade -5...5
  writer.setInt8(layer.settings.innerDarkenBrighten);
  //* inner_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...6
  writer.setInt8(layer.settings.innerGlowDepth);
  //* inner_stroke_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
  writer.setUint8(layer.settings.innerGlowRecursive ? 1 : 0);
  //* inner_stroke_bevel_distance ``ubyte (1)`` // border distance of bevel 1...8
  writer.setUint8(layer.settings.bevelDistance);
  //* inner_stroke_bevel_strength ``ubyte (1)`` // shading strength of bevel 1...8
  writer.setUint8(layer.settings.bevelStrength);
  //* drop_shadow_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = shade
  writer.setUint8(layer.settings.dropShadowStyle.id);
  //* drop_shadow_solid_color_ramp_index ``ubyte (1)`` // color ramp index
  writer.setUint8(layer.settings.dropShadowColorReference.rampIndex);
  //* drop_shadow_solid_color_index ``ubyte (1)`` // index in color ramp
  writer.setUint8(layer.settings.dropShadowColorReference.colorIndex);
  //* drop_shadow_offset_x ``byte (1)`` // -16...16
  writer.setInt8(layer.settings.dropShadowOffset.x);
  //* drop_shadow_offset_y ``byte (1)`` // -16...16
  writer.setInt8(layer.settings.dropShadowOffset.y);
  //* drop_shadow_darken_brighten ``byte (1)`` // shading amount for shade -5...5
  writer.setInt8(layer.settings.dropShadowDarkenBrighten);
  //image data
  writer.setBytes(_encodeDrawingPixels(pixels: pixels));
}

void _writeReferenceLayer({required final FileByteWriter writer, required final HistoryReferenceLayer layer})
{
  //path (string)
  final Uint8List encodedPath = utf8.encode(layer.path);
  writer.setUint16(encodedPath.length);
  writer.setBytes(encodedPath);
  //opacity ``ubyte (1)`` // 0...100
  writer.setUint8(layer.opacity);
  //offset_x ``float (1)``
  writer.setFloat32(layer.offsetX);
  //offset_y ``float (1)``
  writer.setFloat32(layer.offsetY);
  //zoom ``ushort (1)``
  writer.setUint16(layer.zoom);
  //aspect_ratio ``float (1)``
  writer.setFloat32(layer.aspectRatio);
  //brightness ``float (1)`` // -1...1
  writer.setFloat32(layer.brightness);
  //contrast ``float (1)`` // 0...2
  writer.setFloat32(layer.contrast);
  //saturation ``float (1)`` // 0...2
  writer.setFloat32(layer.saturation);
  //warmth ``float (1)`` // -1...1
  writer.setFloat32(layer.warmth);
}

void _writeGridLayer({required final FileByteWriter writer, required final HistoryGridLayer layer})
{
  //opacity ``ubyte (1)`` // 0...100
  writer.setUint8(layer.opacity);
  //brightness ``ubyte (1)`` // 0...100
  writer.setUint8(layer.brightness);
  //grid_type ``ubyte (1)`` // ``00``= rectangular, ``01`` = diagonal, ``02`` = isometric
  writer.setUint8(layer.gridType.id);
  //interval_x ``ubyte (1)`` // 2...64
  writer.setUint8(layer.intervalX);
  //interval_y ``ubyte (1)`` // 2...64
  writer.setUint8(layer.intervalY);
  //horizon_position ``float (1)``// 0...1 (vertical horizon position)
  writer.setFloat32(layer.horizonPosition);
  //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
  writer.setFloat32(layer.vanishingPoint1);
  //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
  writer.setFloat32(layer.vanishingPoint2);
  //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
  writer.setFloat32(layer.vanishingPoint3);
}

void _writeShadingLayer({required final FileByteWriter writer, required final HistoryShadingLayer layer})
{
  //lock type
  writer.setUint8(layer.lockState.id);
  //* shading_step_limit_low ``ubyte (1)`` // 1...6
  writer.setUint8(layer.settings.shadingLow);
  //* shading_step_limit_high ``ubyte (1)`` // 1...6
  writer.setUint8(layer.settings.shadingHigh);
  //image data
  //a selection holds color references, which mean nothing on a shading layer
  writer.setBytes(_encodeShadingPixels(pixels: layer.pixels));
}

void _writeTimeline({required final FileByteWriter writer, required final HistoryTimeline timeline})
{
  //frames_count ``ushort (1)``
  writer.setUint16(timeline.frames.length);
  //start_frame ``ushort (1)``
  writer.setUint16(timeline.loopStart);
  //end_frame ``ushort (1)``
  writer.setUint16(timeline.loopEnd);
  for (final HistoryFrame frame in timeline.frames)
  {
    //fps ``ubyte (1)``
    writer.setUint8(frame.fps);
    //frame_layer_count ``ushort (1)``
    writer.setUint16(frame.layerIndices.length);
    for (final int layerIndex in frame.layerIndices)
    {
      //layer_index ``ushort (1)``
      writer.setUint16(layerIndex);
    }
  }
}

int _packAlignments({required final HashMap<Alignment, bool> alignments})
{
  assert(allAlignments.length == 8);
  assert(alignments.length == 8);

  int byte = 0;
  int i = 0;
  for (final Alignment alignment in allAlignments)
  {
    if (alignments[alignment] == true)
    {
      byte |= 1 << i;
    }
    i++;
  }
  return byte;
}
