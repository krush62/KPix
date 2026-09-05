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

HashMap<CoordinateSetI, HistoryColorReference> _layerDataForSaving({
  required final HistoryDrawingLayer layer,
  required final HistorySelectionState selection,
  required final bool isSelectedLayer,
  required final CoordinateSetI canvasSize,
})
{
  final HashMap<CoordinateSetI, HistoryColorReference> layerData = layer.data;
  if (!isSelectedLayer || selection.isEmpty)
  {
    return layerData;
  }

  final HashMap<CoordinateSetI, HistoryColorReference> merged = HashMap<CoordinateSetI, HistoryColorReference>.from(layerData);
  for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in selection.colors.entries)
  {
    if (entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < canvasSize.x && entry.key.y < canvasSize.y)
    {
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}

Future<ByteData> createKPixData() async
{
  final HistoryState saveData = HistoryState.fromDocument(identifier: HistoryStateTypeIdentifier.saveData);
  final ByteData byteData = ByteData(_calculateKPixFileSize(saveData: saveData));

  int offset = 0;


  //HEADER

  //header
  byteData.setUint32(offset, int.parse(magicNumber, radix: 16));
  offset+=4;
  //file version
  byteData.setUint8(offset++, fileVersion);


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

  final HistoryFrame currentlySelectedFrame = saveData.timeline.frames[saveData.timeline.selectedFrameIndex];
  final HistoryLayer currentlySelectedLayer = allHLayers.elementAt(currentlySelectedFrame.layerIndices.elementAt(currentlySelectedFrame.selectedLayerIndex));

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
      //data count
      final HashMap<CoordinateSetI, HistoryColorReference> layerData = _layerDataForSaving(
        layer: cLayer,
        selection: saveData.selectionState,
        isSelectedLayer: currentlySelectedLayer == cLayer,
        canvasSize: saveData.canvasSize,
      );
      byteData.setUint32(offset, layerData.length);
      offset+=4;
      //image data
      for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in layerData.entries)
      {
        //x
        byteData.setUint16(offset, entry.key.x);
        offset+=2;
        //y
        byteData.setUint16(offset, entry.key.y);
        offset+=2;

        //ramp index
        byteData.setUint8(offset++, entry.value.rampIndex);

        //color index
        byteData.setUint8(offset++, entry.value.colorIndex);
      }
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

      //data count
      final int dataLength = cLayer.data.length;
      byteData.setUint32(offset, dataLength);
      offset+=4;

      for (final MapEntry<CoordinateSetI, int> entry in cLayer.data.entries)
      {
        //x
        byteData.setUint16(offset, entry.key.x);
        offset+=2;
        //y
        byteData.setUint16(offset, entry.key.y);
        offset+=2;
        //shading
        byteData.setInt8(offset++, entry.value);
      }
    }
  }


  //TIMELINE

  //frames_count ``ubyte (1)``
  byteData.setInt8(offset++, saveData.timeline.frames.length);
  //start_frame ``ubyte (1)``
  byteData.setInt8(offset++, saveData.timeline.loopStart);
  //end_frame ``ubyte (1)``
  byteData.setInt8(offset++, saveData.timeline.loopEnd);

  for (final HistoryFrame frame in saveData.timeline.frames)
  {
    //fps ``ubyte (1)``
    byteData.setInt8(offset++, frame.fps);
    //frame_layer_count ``ubyte (1)``
    byteData.setInt8(offset++, frame.layerIndices.length);
    for (int i = 0; i < frame.layerIndices.length; i++)
    {
      //layer_index ``ubyte (1)``
      byteData.setInt8(offset++, frame.layerIndices.elementAt(i));
    }
  }

  return byteData;
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

int _calculateKPixFileSize({required final HistoryState saveData})
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
  final HistoryFrame currentlySelectedFrame = saveData.timeline.frames[saveData.timeline.selectedFrameIndex];
  final HistoryLayer currentlySelectedLayer = allLayers.elementAt(currentlySelectedFrame.layerIndices.elementAt(currentlySelectedFrame.selectedLayerIndex));
  for (final HistoryLayer cLayer in allLayers)
  {
    //type
    size += 1;
    //visibility
    size += 1;
    if (cLayer.runtimeType == HistoryDrawingLayer)
    {
      final HistoryDrawingLayer drawingLayer = cLayer as HistoryDrawingLayer;
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
      //data count
      size += 4;
      //x (2) + y (2) + color ramp index (1) + color index (1) per pixel, counted from the very same merge the writer emits
      size += _layerDataForSaving(
        layer: drawingLayer,
        selection: saveData.selectionState,
        isSelectedLayer: currentlySelectedLayer == cLayer,
        canvasSize: saveData.canvasSize,
      ).length * 6;
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

      //data count
      size += 4;
      //x (2) + y (2) + shading (1) per pixel. A selection holds color references,
      // which mean nothing on a shading layer, so the writer never merges one in here and neither does this count.
      size += cLayer.data.length * 5;
    }
  }


  //TIMELINE/FRAMES

  //frames_count ``ubyte (1)``
  size += 1;

  //start_frame ``ubyte (1)``
  size += 1;

  //end_frame ``ubyte (1)``
  size += 1;

  for (final HistoryFrame frame in saveData.timeline.frames)
  {
    //fps ``ubyte (1)``
    size += 1;

    //frame_layer_count ``ubyte (1)``
    size += 1;

    for (int i = 0; i < frame.layerIndices.length; i++)
    {
      //layer_index ``ubyte (1)``
      size += 1;
    }
  }


  return size;
}
