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

import 'dart:async';
import 'dart:collection';
import 'dart:convert' show utf8;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_layer_type.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_selection_state.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';

part 'export/palette/export_palette_adobe.dart';
part 'export/palette/export_palette_aseprite.dart';
part 'export/palette/export_palette_corel.dart';
part 'export/palette/export_palette_gimp.dart';
part 'export/palette/export_palette_jasc.dart';
part 'export/palette/export_palette_kpal.dart';
part 'export/palette/export_palette_open_office.dart';
part 'export/palette/export_palette_paint_net.dart';
part 'export/palette/export_palette_pixelorama.dart';
part 'export/palette/export_palette_png.dart';
part 'export/project/export_project_apng.dart';
part 'export/project/export_project_aseprite.dart';
part 'export/project/export_project_gif.dart';
part 'export/project/export_project_gimp.dart';
part 'export/project/export_project_kpix.dart';
part 'export/project/export_project_pixelorama.dart';
part 'export/project/export_project_png.dart';
part 'export/project/export_project_psd.dart';
part 'export/project/export_project_texture_pack.dart';
part 'export/project/export_project_texture_pack_animation.dart';
part 'export/project/export_project_zipped_png.dart';


/// One rendered animation frame as plain data.
///
/// Rendering needs `dart:ui` and therefore has to happen on the UI isolate, but
/// everything in here is copyable, so the encoding that follows can be handed to
/// a background isolate.
class RenderedFrame
{
  const RenderedFrame({
    required this.pixels,
    required this.width,
    required this.height,
    required this.durationMs,
  });

  /// Raw RGBA bytes, four per pixel.
  final Uint8List pixels;
  final int width;
  final int height;

  /// How long this frame is shown, in milliseconds.
  final int durationMs;
}

/// The animated formats that [_encodeAnimation] can produce.
enum _AnimationFormat
{
  gif,
  apng,
}

/// Renders the exported frame range to raw pixels on the UI isolate.
///
/// Returns null when a frame could not be read back, which is what the callers
/// report as a failed export.
Future<List<RenderedFrame>?> _renderAnimationFrames({
  required final AnimationExportData exportData,
  required final AppState appState,
}) async
{
  final int startFrame = exportData.loopOnly ? appState.timeline.loopStartIndex.value : 0;
  final int endFrame = exportData.loopOnly ? appState.timeline.loopEndIndex.value : appState.timeline.frames.value.length - 1;

  final List<RenderedFrame> renderedFrames = <RenderedFrame>[];
  for (int i = startFrame; i <= endFrame; i++)
  {
    final Frame frame = appState.timeline.frames.value[i];
    final ui.Image uiImage = await getImageFromLayers(
      selection: appState.selectionState.selection,
      canvasSize: appState.canvasSize,
      layerCollection: frame.layerList,
      scalingFactor: exportData.scaling,
      frame: frame,
    );
    final ByteData? uiBytes = await uiImage.toByteData();
    final int width = uiImage.width;
    final int height = uiImage.height;
    uiImage.dispose();

    if (uiBytes == null)
    {
      return null;
    }

    renderedFrames.add(
      RenderedFrame(
        pixels: uiBytes.buffer.asUint8List(),
        width: width,
        height: height,
        durationMs: frame.frameTime,
      ),
    );
  }
  return renderedFrames;
}

/// Assembles [frames] into an animation and encodes it.
///
/// Pure computation over plain data, so it can run on a background isolate. This
/// is the expensive half of an animation export: quantizing and encoding a GIF
/// takes seconds for anything but a tiny canvas.
Uint8List _encodeAnimation({
  required final List<RenderedFrame> frames,
  required final _AnimationFormat format,
})
{
  final img.Image animation = img.Image(
    width: frames.first.width,
    height: frames.first.height,
    numChannels: 4,
  );

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

  return format == _AnimationFormat.gif ? img.encodeGif(animation) : img.encodePng(animation);
}

/// Zips [files] on a background isolate.
///
/// [files] maps the name inside the archive to its contents.
Future<Uint8List> _zipOffThread({required final Map<String, Uint8List> files, required final String debugLabel}) async
{
  return await runOffThread<Uint8List>(
    debugLabel: debugLabel,
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
}


Future<CoordinateColorMapNullable> getMergedColors({required final Frame frame, required final CoordinateSetI canvasSize}) async
{
  final CoordinateColorMapNullable colorData = CoordinateColorMapNullable();
  final Iterable<RasterableLayerState> layerList = frame.layerList.getVisibleRasterLayers();
  for (int x = 0; x < canvasSize.x; x++)
  {
    for (int y = 0; y < canvasSize.y; y++)
    {
      final CoordinateSetI coord = CoordinateSetI(x: x, y: y);
      for (final RasterableLayerState layer in layerList)
      {
        final ColorReference? colAtPos = layer.pixelsForFrame(frame: frame)[coord];
        if (colAtPos != null)
        {
          colorData[coord] = colAtPos;
          break;
        }
      }
    }
  }
  return colorData;
}

List<ui.Color> _getColorList({required final List<KPalRampData> ramps})
{
  final List<ui.Color> colorList = <ui.Color>[];
  for (final KPalRampData ramp in ramps)
  {
    for (final ColorReference colRef in ramp.references)
    {
      colorList.add(colRef.getIdColor().color);
    }
  }
  return colorList;
}

int _getShadeForCoord({required final int currentLayerIndex, required final CoordinateSetI coord, required final LayerCollection layerCollection})
{
  assert(currentLayerIndex < layerCollection.length);
  int shade = 0;
  for (int i = currentLayerIndex - 1; i >= 0; i--)
  {
    final LayerState layer = layerCollection.getLayer(index: i);
    if (layer.visibilityState.value == LayerVisibilityState.visible)
    {
      if (layer is DrawingLayerState)
      {
        if (layer.getDataEntry(coord: coord) != null)
        {
          return 0;
        }
      }
      else if (layer is ShadingLayerState)
      {
        final int? shadingAt = layer.getDisplayValueAt(coord: coord);
        if (shadingAt != null)
        {
          shade += shadingAt;
        }
      }
    }
  }

  return shade;
}

  Future<Uint8List> _createAsepriteData({required final List<ui.Color> colorList, required final List<Uint8List> layerNames, required final List<List<int>> layerEncBytes, required final CoordinateSetI canvasSize, final List<DrawingLayerState>? layerList}) async
  {
    const int headerSize = 128;
    const int frameHeaderSize = 16;
    const int colorProfileSize = 22;
    final int paletteNewSize = 26 + (colorList.length * 6);
    final int paletteOldSize = 10 + (colorList.length * 3);

    //CALCULATE SIZE
    int fileSize = 0;
    fileSize += headerSize;
    fileSize += frameHeaderSize;
    fileSize += colorProfileSize;
    fileSize += paletteNewSize;
    fileSize += paletteOldSize;

    for (int i = 0; i < layerNames.length; i++)
    {
      fileSize += 24 + layerNames[i].length;
    }

    for (int i = 0; i < layerEncBytes.length; i++)
    {
      fileSize += 26 + layerEncBytes[i].length;
    }

    final ByteData outBytes = ByteData(fileSize);
    int offset = 0;

    //WRITE HEADER
    outBytes.setUint32(offset, fileSize, Endian.little); //file size
    offset+=4;
    outBytes.setUint16(offset, 0xA5E0, Endian.little); //magic number
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //frames
    offset+=2;
    outBytes.setUint16(offset, canvasSize.x, Endian.little); //width
    offset+=2;
    outBytes.setUint16(offset, canvasSize.y, Endian.little); //height
    offset+=2;
    outBytes.setUint16(offset, 8, Endian.little); //color depth
    offset+=2;
    outBytes.setUint32(offset, 1, Endian.little); //flags
    offset+=4;
    outBytes.setUint16(offset, 100, Endian.little); //speed
    offset+=2;
    outBytes.setUint32(offset, 0, Endian.little); //empty
    offset+=4;
    outBytes.setUint32(offset, 0, Endian.little); //empty
    offset+=4;
    outBytes.setUint8(offset, 0); //transparent index
    offset++;
    for (int i = 0; i < 3; i++) //ignore bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    outBytes.setUint16(offset, colorList.length, Endian.little); //color count
    offset+=2;
    outBytes.setUint8(offset, 1); //pixel width
    offset++;
    outBytes.setUint8(offset, 1); //pixel height
    offset++;
    outBytes.setInt16(offset, 0, Endian.little); //x pos grid
    offset+=2;
    outBytes.setInt16(offset, 0, Endian.little); //y pos grid
    offset+=2;
    outBytes.setUint16(offset, 16, Endian.little); //grid width
    offset+=2;
    outBytes.setUint16(offset, 16, Endian.little); //grid height
    offset+=2;
    for (int i = 0; i < 84; i++) //future bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }

    //FRAMES HEADER
    outBytes.setUint32(offset, fileSize - headerSize, Endian.little); //frame size
    offset+=4;
    outBytes.setUint16(offset, 0xF1FA, Endian.little); //magic number
    offset+=2;
    outBytes.setUint16(offset, 3 + (layerEncBytes.length * 2), Endian.little); //chunk count
    offset+=2;
    outBytes.setUint16(offset, 100, Endian.little); //duration
    offset+=2;
    for (int i = 0; i < 2; i++) //empty bytes
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    outBytes.setUint32(offset, 3 + (layerEncBytes.length * 2), Endian.little); //chunk count
    offset+=4;

    //COLOR PROFILE
    outBytes.setUint32(offset, colorProfileSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x2007, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //profile type
    offset+=2;
    outBytes.setUint16(offset, 0, Endian.little); //flags
    offset+=2;
    outBytes.setUint32(offset, 0, Endian.little); //gamma
    offset+=4;
    for (int i = 0; i < 8; i++) //reserved
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }

    //PALETTE
    outBytes.setUint32(offset, paletteNewSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x2019, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint32(offset, colorList.length, Endian.little); //color count
    offset+=4;
    outBytes.setUint32(offset, 0, Endian.little); //first color index
    offset+=4;
    outBytes.setUint32(offset, colorList.length - 1, Endian.little); //last color index
    offset+=4;
    for (int i = 0; i < 8; i++) //reserved
    {
      outBytes.setUint8(offset, 0);
      offset++;
    }
    for (int i = 0; i < colorList.length; i++)
    {
      outBytes.setUint16(offset, 0, Endian.little); //has name
      offset+=2;
      outBytes.setUint8(offset, (colorList[i].r * 255).toInt()); //red
      offset++;
      outBytes.setUint8(offset, (colorList[i].g * 255).toInt()); //green
      offset++;
      outBytes.setUint8(offset, (colorList[i].b * 255).toInt()); //blue
      offset++;
      outBytes.setUint8(offset, 255); //alpha
      offset++;
    }

    //PALETTE OLD
    outBytes.setUint32(offset, paletteOldSize, Endian.little); //chunk size
    offset+=4;
    outBytes.setUint16(offset, 0x0004, Endian.little); //chunk type
    offset+=2;
    outBytes.setUint16(offset, 1, Endian.little); //packet count
    offset+=2;
    outBytes.setUint8(offset, 0); //skip entries
    offset++;
    outBytes.setUint8(offset, colorList.length); //color count
    offset++;
    for (int i = 0; i < colorList.length; i++)
    {
      outBytes.setUint8(offset, (colorList[i].r * 255).toInt()); //red
      offset++;
      outBytes.setUint8(offset, (colorList[i].g * 255).toInt()); //green
      offset++;
      outBytes.setUint8(offset, (colorList[i].b * 255).toInt()); //blue
      offset++;
    }

    //LAYERS AND CELS
    for (int i = layerEncBytes.length - 1; i >= 0 ; i--)
    {
      //LAYER
      outBytes.setUint32(offset, 24 + layerNames[i].length, Endian.little); //chunk size
      offset+=4;
      outBytes.setUint16(offset, 0x2004, Endian.little); //chunk type
      offset+=2;
      int flagVal = 0;
      if (layerList != null)
      {
        if (layerList[i].visibilityState.value == LayerVisibilityState.visible)
        {
          flagVal += 1;
        }
        if (layerList[i].lockState.value != LayerLockState.locked)
        {
          flagVal += 2;
        }
      }
      else
      {
        flagVal += 1;
        flagVal += 2;
      }

      outBytes.setUint16(offset, flagVal, Endian.little); //flags
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //type
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //child level
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //ignored width
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //ignored height
      offset+=2;
      outBytes.setUint16(offset, 0, Endian.little); //blend mode
      offset+=2;
      outBytes.setUint8(offset, 255); //opacity
      offset++;
      for (int j = 0; j < 3; j++) //reserved
      {
        outBytes.setUint8(offset, 0);
        offset++;
      }
      outBytes.setUint16(offset, layerNames[i].length, Endian.little); //name length
      offset+=2;

      for (int j = 0; j < layerNames[i].length; j++) //name
      {
        outBytes.setUint8(offset, layerNames[(layerEncBytes.length - 1) - i][j]);
        offset++;
      }

      //CEL
      outBytes.setUint32(offset, 26 + layerEncBytes[i].length, Endian.little); //chunk size
      offset+=4;
      outBytes.setUint16(offset, 0x2005, Endian.little); //chunk type
      offset+=2;
      outBytes.setUint16(offset, (layerEncBytes.length - 1) - i, Endian.little); //layer index
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //x pos
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //y pos
      offset+=2;
      outBytes.setUint8(offset, 255); //opacity
      offset++;
      outBytes.setUint16(offset, 2, Endian.little); //cel type
      offset+=2;
      outBytes.setInt16(offset, 0, Endian.little); //z index
      offset+=2;
      for (int j = 0; j < 5; j++) //reserved
      {
        outBytes.setUint8(offset, 0);
        offset++;
      }
      if (layerList != null)
      {
        outBytes.setUint16(offset, canvasSize.x, Endian.little); //width
        offset+=2;
        outBytes.setUint16(offset, canvasSize.y, Endian.little); //height
        offset+=2;
      }
      else
      {
        outBytes.setUint16(offset, canvasSize.x, Endian.little); //width
        offset+=2;
        outBytes.setUint16(offset, canvasSize.y, Endian.little); //height
        offset+=2;
      }

      for (int j = 0; j < layerEncBytes[i].length; j++)
      {
        outBytes.setUint8(offset, layerEncBytes[i][j]);
        offset++;
      }
    }
    return outBytes.buffer.asUint8List();
  }
