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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_color_reference.dart';
import 'package:kpix/managers/history/history_dither_layer.dart';
import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';

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
part 'export/project/export_project_zipped_png.dart';
part 'export/project/export_project_texture_pack.dart';
part 'export/project/export_project_texture_pack_animation.dart';



  Map<GridType, int> gridTypeValueMap =
  <GridType, int>{
    GridType.rectangular: 0,
    GridType.diagonal: 1,
    GridType.isometric: 2,
    GridType.hexagonal: 3,
    GridType.triangular: 4,
    GridType.brick: 5,
    GridType.onePointPerspective: 6,
    GridType.twoPointPerspective: 7,
    GridType.threePointPerspective: 8,
  };

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
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState drawingLayerState = layer as DrawingLayerState;
        if (drawingLayerState.getDataEntry(coord: coord) != null)
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
