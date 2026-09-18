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

/// The encoded pixel data of every drawing, shading and dither layer.
Map<HistoryLayer, Uint8List> _encodePixelBlocks({required final HistoryState saveData})
{
  final LinkedHashSet<HistoryLayer> allLayers = saveData.timeline.allLayers;
  final HistoryFrame currentlySelectedFrame = saveData.timeline.frames[saveData.timeline.selectedFrameIndex];
  final HistoryLayer currentlySelectedLayer = allLayers.elementAt(currentlySelectedFrame.layerIndices.elementAt(currentlySelectedFrame.selectedLayerIndex));
  final Map<HistoryLayer, Uint8List> blocks = HashMap<HistoryLayer, Uint8List>.identity();
  for (final HistoryLayer layer in allLayers)
  {
    if (layer is HistoryDrawingLayer)
    {
      blocks[layer] = _encodeDrawingPixels(pixels: _layerPixelsForSaving(
        layer: layer,
        selection: saveData.selectionState,
        isSelectedLayer: currentlySelectedLayer == layer,
      ),);
    }
    else if (layer is HistoryShadingLayer)
    {
      //a selection holds color references, which mean nothing on a shading layer
      blocks[layer] = _encodeShadingPixels(pixels: layer.pixels);
    }
  }
  return blocks;
}

/// Serialises [state], or the live document when none is given.
Future<ByteData> createKPixData({final HistoryState? state}) async
{
  final HistoryState saveData = state ?? HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.saveData);
  final Map<HistoryLayer, Uint8List> pixelBlocks = _encodePixelBlocks(saveData: saveData);
  final ByteData byteData = ByteData(_calculateKPixFileSize(saveData: saveData, pixelBlocks: pixelBlocks));
  final Uint8List bytes = byteData.buffer.asUint8List();

  int offset = 0;


  //HEADER

  //header
  byteData.setUint32(offset, int.parse(magicNumber, radix: 16));
  offset+=4;
  //file version
  byteData.setUint8(offset++, fileVersion);
  final int headerLength = offset;


  //PALETTE

  //rampCount
  byteData.setUint8(offset++, saveData.rampList.length);
  //color ramps
  for (int i = 0; i < saveData.rampList.length; i++)
  {
    final KPalRampSettings rampSettings = saveData.rampList[i].settings;
    //color count
    byteData.setUint8(offset++, rampSettings.colorCount);
    //base hue
    byteData.setUint16(offset, rampSettings.baseHue);
    offset+=2;
    //base sat
    byteData.setUint8(offset++, rampSettings.baseSat);
    //hue shift
    byteData.setInt8(offset++, rampSettings.hueShift);
    //hue shift exp
    byteData.setUint8(offset++, (rampSettings.hueShiftExp * 100).round());
    //sat shift
    byteData.setInt8(offset++, rampSettings.satShift);
    //sat shift exp
    byteData.setUint8(offset++, (rampSettings.satShiftExp * 100).round());
    //sat curve
    final int satCurveVal = rampSettings.satCurve.id;
    byteData.setUint8(offset++, satCurveVal);
    //val min
    byteData.setUint8(offset++, rampSettings.valueRangeMin);
    //val max
    byteData.setUint8(offset++, rampSettings.valueRangeMax);
    //color shifts
    for (int j = 0; j < rampSettings.colorCount; j++)
    {
      //hue shift
      byteData.setInt8(offset++, saveData.rampList[i].shiftSets[j].hueShift);
      //sat shift
      byteData.setInt8(offset++, saveData.rampList[i].shiftSets[j].satShift);
      //val shift
      byteData.setInt8(offset++, saveData.rampList[i].shiftSets[j].valShift);
    }
  }


  //IMAGE

  //columns
  byteData.setUint16(offset, saveData.canvasSize.x);
  offset+=2;

  //rows
  byteData.setUint16(offset, saveData.canvasSize.y);
  offset+=2;

  //layer count
  byteData.setUint16(offset, saveData.timeline.allLayers.length);
  offset+=2;

  //LAYERS
  final LinkedHashSet<HistoryLayer> allHLayers = saveData.timeline.allLayers;

  for (int i = 0; i < allHLayers.length; i++)
  {

    final HistoryLayer cLayer = allHLayers.elementAt(i);
    //layer type
    byteData.setUint8(offset++, historyLayerTypeToId[cLayer.runtimeType]!);

    //visibility
    byteData.setUint8(offset++, cLayer.visibilityState.id);

    if (cLayer is HistoryDrawingLayer)
    {
      //lock type
      byteData.setUint8(offset++, cLayer.lockState.id);

      if (fileVersion >= 2)
      {
        //* outer_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = relative, ``03`` = glow, ``04`` = shade
        byteData.setUint8(offset++, cLayer.settings.outerStrokeStyle.id);
        //* outer_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
        byteData.setUint8(offset++, _packAlignments(alignments: cLayer.settings.outerSelectionMap));
        //* outer_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
        byteData.setUint8(offset++, cLayer.settings.outerColorReference.rampIndex);
        //* outer_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
        byteData.setUint8(offset++, cLayer.settings.outerColorReference.colorIndex);
        //* outer_stroke_darken_brighten ``byte (1)`` // shading amount for relative/shade -5...5
        byteData.setInt8(offset++, cLayer.settings.outerDarkenBrighten);
        //* outer_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
        byteData.setInt8(offset++, cLayer.settings.outerGlowDepth);
        //* outer_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
        byteData.setInt8(offset++, cLayer.settings.outerGlowRecursive ? 1 : 0);
        //* inner_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = bevel, ``03`` = glow, ``04`` = shade
        byteData.setUint8(offset++, cLayer.settings.innerStrokeStyle.id);
        //* inner_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
        byteData.setUint8(offset++, _packAlignments(alignments: cLayer.settings.innerSelectionMap));
        //* inner_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
        byteData.setUint8(offset++, cLayer.settings.innerColorReference.rampIndex);
        //* inner_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
        byteData.setUint8(offset++, cLayer.settings.innerColorReference.colorIndex);
        //* inner_stroke_darken_brighten ``byte (1)`` // shading amount for shade -5...5
        byteData.setInt8(offset++, cLayer.settings.innerDarkenBrighten);
        //* inner_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...6
        byteData.setInt8(offset++, cLayer.settings.innerGlowDepth);
        //* inner_stroke_glow_recursive ``ubyte (1)`` // ``00`` = false, ``01`` = true
        byteData.setUint8(offset++, cLayer.settings.innerGlowRecursive ? 1 : 0);
        //* inner_stroke_bevel_distance ``ubyte (1)`` // border distance of bevel 1...8
        byteData.setUint8(offset++, cLayer.settings.bevelDistance);
        //* inner_stroke_bevel_strength ``ubyte (1)`` // shading strength of bevel 1...8
        byteData.setUint8(offset++, cLayer.settings.bevelStrength);
        //* drop_shadow_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = shade
        byteData.setUint8(offset++, cLayer.settings.dropShadowStyle.id);
        //* drop_shadow_solid_color_ramp_index ``ubyte (1)`` // color ramp index
        byteData.setUint8(offset++, cLayer.settings.dropShadowColorReference.rampIndex);
        //* drop_shadow_solid_color_index ``ubyte (1)`` // index in color ramp
        byteData.setUint8(offset++, cLayer.settings.dropShadowColorReference.colorIndex);
        //* drop_shadow_offset_x ``byte (1)`` // -16...16
        byteData.setInt8(offset++, cLayer.settings.dropShadowOffset.x);
        //* drop_shadow_offset_y ``byte (1)`` // -16...16
        byteData.setInt8(offset++, cLayer.settings.dropShadowOffset.y);
        //* drop_shadow_darken_brighten ``byte (1)`` // shading amount for shade -5...5
        byteData.setInt8(offset++, cLayer.settings.dropShadowDarkenBrighten);
      }
      //image data
      bytes.setAll(offset, pixelBlocks[cLayer]!);
      offset += pixelBlocks[cLayer]!.length;
    }
    else if (cLayer.runtimeType == HistoryReferenceLayer)
    {
      final HistoryReferenceLayer referenceLayer = cLayer as HistoryReferenceLayer;

      //path (string)
      final Uint8List encodedPath = utf8.encode(referenceLayer.path);
      byteData.setUint16(offset, encodedPath.length);
      offset += 2;
      for (int i = 0; i < encodedPath.length; i++)
      {
        byteData.setUint8(offset++, encodedPath[i]);
      }
      //opacity ``ubyte (1)`` // 0...100
      byteData.setUint8(offset++, referenceLayer.opacity);
      //offset_x ``float (1)``
      byteData.setFloat32(offset, referenceLayer.offsetX);
      offset += 4;
      //offset_y ``float (1)``
      byteData.setFloat32(offset, referenceLayer.offsetY);
      offset += 4;
      //zoom ``ushort (1)``
      byteData.setUint16(offset, referenceLayer.zoom);
      offset+=2;
      //aspect_ratio ``float (1)``
      byteData.setFloat32(offset, referenceLayer.aspectRatio);
      offset += 4;
      //brightness ``float (1)`` // -1...1
      byteData.setFloat32(offset, referenceLayer.brightness);
      offset += 4;
      //contrast ``float (1)`` // 0...2
      byteData.setFloat32(offset, referenceLayer.contrast);
      offset += 4;
      //saturation ``float (1)`` // 0...2
      byteData.setFloat32(offset, referenceLayer.saturation);
      offset += 4;
      //warmth ``float (1)`` // -1...1
      byteData.setFloat32(offset, referenceLayer.warmth);
      offset += 4;
    }
    else if (cLayer.runtimeType == HistoryGridLayer)
    {
      final HistoryGridLayer gridLayer = cLayer as HistoryGridLayer;
      //opacity ``ubyte (1)`` // 0...100
      byteData.setUint8(offset++, gridLayer.opacity);
      //brightness ``ubyte (1)`` // 0...100
      byteData.setUint8(offset++, gridLayer.brightness);
      //grid_type ``ubyte (1)`` // ``00``= rectangular, ``01`` = diagonal, ``02`` = isometric
      byteData.setUint8(offset++, gridLayer.gridType.id);
      //interval_x ``ubyte (1)`` // 2...64
      byteData.setUint8(offset++, gridLayer.intervalX);
      //interval_x ``ubyte (1)`` // 2...64
      byteData.setUint8(offset++, gridLayer.intervalY);
      //horizon_position ``float (1)``// 0...1 (vertical horizon position)
      byteData.setFloat32(offset, gridLayer.horizonPosition);
      offset += 4;
      //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
      byteData.setFloat32(offset, gridLayer.vanishingPoint1);
      offset += 4;
      //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
      byteData.setFloat32(offset, gridLayer.vanishingPoint2);
      offset += 4;
      //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
      byteData.setFloat32(offset, gridLayer.vanishingPoint3);
      offset += 4;
    }
    else if (cLayer is HistoryShadingLayer) //SHADING AND DITHERING
        {
      //lock type
      byteData.setUint8(offset++, cLayer.lockState.id);

      if (fileVersion >= 2)
      {
        //* shading_step_limit_low ``ubyte (1)`` // 1...6
        byteData.setUint8(offset++, cLayer.settings.shadingLow);
        //* shading_step_limit_high ``ubyte (1)`` // 1...6
        byteData.setUint8(offset++, cLayer.settings.shadingHigh);
      }

      //image data
      bytes.setAll(offset, pixelBlocks[cLayer]!);
      offset += pixelBlocks[cLayer]!.length;
    }
  }


  //TIMELINE

  //frames_count ``ushort (1)``
  byteData.setUint16(offset, saveData.timeline.frames.length);
  offset+=2;
  //start_frame ``ushort (1)``
  byteData.setUint16(offset, saveData.timeline.loopStart);
  offset+=2;
  //end_frame ``ushort (1)``
  byteData.setUint16(offset, saveData.timeline.loopEnd);
  offset+=2;

  for (final HistoryFrame frame in saveData.timeline.frames)
  {
    //fps ``ubyte (1)``
    byteData.setUint8(offset++, frame.fps);
    //frame_layer_count ``ushort (1)``
    byteData.setUint16(offset, frame.layerIndices.length);
    offset+=2;
    for (final int layerIndex in frame.layerIndices)
    {
      //layer_index ``ushort (1)``
      byteData.setUint16(offset, layerIndex);
      offset+=2;
    }
  }

  //everything after the header is compressed
  final Uint8List body = const ZLibEncoder().encodeBytes(Uint8List.sublistView(bytes, headerLength));
  final Uint8List file = Uint8List(headerLength + body.length)
    ..setAll(0, Uint8List.sublistView(bytes, 0, headerLength))
    ..setAll(headerLength, body);
  return ByteData.sublistView(file);
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

int _calculateKPixFileSize({required final HistoryState saveData, required final Map<HistoryLayer, Uint8List> pixelBlocks})
{
  int size = 0;

  //header
  size += 4;
  //file version
  size += 1;

  //ramp count
  size += 1;
  for (int i = 0; i < saveData.rampList.length; i++)
  {
    //color count
    size += 1;
    //base hue
    size += 2;
    //base sat
    size += 1;
    //hue shift
    size += 1;
    //hue shift exp
    size += 1;
    //sat shift
    size += 1;
    //sat shift exp
    size += 1;
    //sat curve
    size += 1;
    //val min
    size += 1;
    //val max
    size += 1;
    for (int j = 0; j < saveData.rampList[i].settings.colorCount; j++)
    {
      //hue shift
      size += 1;
      //sat shift
      size += 1;
      //val shift
      size += 1;
    }
  }

  //columns
  size += 2;
  //rows
  size += 2;
  //layer count
  size += 2;


  //LAYERS

  final LinkedHashSet<HistoryLayer> allLayers = saveData.timeline.allLayers;
  for (final HistoryLayer cLayer in allLayers)
  {
    //type
    size += 1;
    //visibility
    size += 1;
    if (cLayer.runtimeType == HistoryDrawingLayer)
    {
      //lock type
      size += 1;

      if (fileVersion >= 2)
      {
        //* outer_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = relative, ``03`` = glow, ``04`` = shade
        size += 1;
        //* outer_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
        size += 1;
        //* outer_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
        size += 1;
        //* outer_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
        size += 1;
        //* outer_stroke_darken_brighten ``byte (1)`` // shading amount for relative/shade -5...5
        size += 1;
        //* outer_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
        size += 1;
        //* outer_glow_direction ``ubyte (1)`` // ``00`` = darken, ``01`` = brighten
        size += 1;
        //* inner_stroke_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = bevel, ``03`` = glow, ``04`` = shade
        size += 1;
        //* inner_stroke_directions ``ubyte (1)`` // bitmask of directions: ``00`` = top left, ``01`` = center top, ``02`` = top right, ``03`` = center right, ``04`` = bottom right, ``05`` = center bottom, ``06`` = bottom left, ``07`` = center left
        size += 1;
        //* inner_stroke_solid_color_ramp_index ``ubyte (1)`` // color ramp index
        size += 1;
        //* inner_stroke_solid_color_index ``ubyte (1)`` // index in color ramp
        size += 1;
        //* inner_stroke_darken_brighten ``byte (1)`` // shading amount for shade -5...5
        size += 1;
        //* inner_stroke_glow_depth ``byte (1)`` // amount of glow depth -6...+6
        size += 1;
        //* inner_stroke_glow_direction ``ubyte (1)`` // ``00`` = darken, ``01`` = brighten
        size += 1;
        //* inner_stroke_bevel_distance ``ubyte (1)`` // border distance of bevel 1...8
        size += 1;
        //* inner_stroke_bevel_strength ``ubyte (1)`` // shading strength of bevel 1...8
        size += 1;
        //* drop_shadow_style ``ubyte (1)`` // ``00`` = off, ``01`` = solid, ``02`` = shade
        size += 1;
        //* drop_shadow_solid_color_ramp_index ``ubyte (1)`` // color ramp index
        size += 1;
        //* drop_shadow_solid_color_index ``ubyte (1)`` // index in color ramp
        size += 1;
        //* drop_shadow_offset_x ``byte (1)`` // -16...16
        size += 1;
        //* drop_shadow_offset_y ``byte (1)`` // -16...16
        size += 1;
        //* drop_shadow_darken_brighten ``byte (1)`` // shading amount for shade -5...5
        size += 1;
      }
      //image data
      size += pixelBlocks[cLayer]!.length;
    }
    else if (cLayer.runtimeType == HistoryReferenceLayer)
    {
      final HistoryReferenceLayer referenceLayer = cLayer as HistoryReferenceLayer;
      //path (string)
      size += 2;
      size += utf8.encode(referenceLayer.path).length;
      //opacity ``ubyte (1)`` // 0...100
      size += 1;
      //offset_x ``float (1)``
      size += 4;
      //offset_y ``float (1)``
      size += 4;
      //zoom ``ushort (1)``
      size += 2;
      //aspect_ratio ``float (1)``
      size += 4;
      //brightness ``float (1)`` // -1...1
      size += 4;
      //contrast ``float (1)`` // 0...2
      size += 4;
      //saturation ``float (1)`` // 0...2
      size += 4;
      //warmth ``float (1)`` // -1...1
      size += 4;
    }
    else if (cLayer.runtimeType == HistoryGridLayer)
    {
      //opacity ``ubyte (1)`` // 0...100
      size += 1;
      //brightness ``ubyte (1)`` // 0...100
      size += 1;
      //grid_type ``ubyte (1)`` // ``00``= rectangular, ``01`` = diagonal, ``02`` = isometric
      size += 1;
      //interval_x ``ubyte (1)`` // 2...64
      size += 1;
      //interval_x ``ubyte (1)`` // 2...64
      size += 1;
      //horizon_position ``float (1)``// 0...1 (vertical horizon position)
      size += 4;
      //vanishing_point_1 ``float (1)``// 0...1 (horizontal position of first vanishing point)
      size += 4;
      //vanishing_point_2 ``float (1)``// 0...1 (horizontal position of second vanishing point)
      size += 4;
      //vanishing_point_3 ``float (1)``// 0...1 (vertical position of third vanishing point)
      size += 4;
    }
    else if (cLayer is HistoryShadingLayer)
    {
      //lock type
      size += 1;
      if (fileVersion >= 2)
      {
        //* shading_step_limit_low ``ubyte (1)`` // 1...6
        size += 1;
        //* shading_step_limit_high ``ubyte (1)`` // 1...6
        size += 1;
      }

      //image data
      size += pixelBlocks[cLayer]!.length;
    }
  }


  //TIMELINE/FRAMES

  //frames_count ``ushort (1)``
  size += 2;

  //start_frame ``ushort (1)``
  size += 2;

  //end_frame ``ushort (1)``
  size += 2;

  for (final HistoryFrame frame in saveData.timeline.frames)
  {
    //fps ``ubyte (1)``
    size += 1;

    //frame_layer_count ``ushort (1)``
    size += 2;

    //layer_index ``ushort (1)`` per layer
    size += frame.layerIndices.length * 2;
  }


  return size;
}
