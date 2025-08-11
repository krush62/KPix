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

Future<Uint8List?> getGimpData({required final ImageExportData exportData, required final List<KPalRampData> colorRamps, required final LayerCollection layerCollection, required final CoordinateSetI canvasSize, required final SelectionList selection}) async
{
  final List<Color> colorList = <ui.Color>[];
  final Map<ColorReference, int> colorMap = <ColorReference, int>{};
  int index = 0;
  for (final KPalRampData kPalRampData in colorRamps)
  {
    for (int i = 0; i < kPalRampData.shiftedColors.length; i++)
    {
      colorList.add(kPalRampData.shiftedColors[i].value.color);
      colorMap[kPalRampData.references[i]] = index;
      index++;
    }
  }
  assert(colorList.length < 256);

  final int fullHeaderSize = 30 + //header
      12 + (3 * colorList.length) + //color map
      9 + //compression
      16 + //resolution
      12 + //tattoo
      12 + //unit
      8 + //prop end
      8 + (layerCollection.length * 8) + //layer addresses
      8; //channel addresses

  //LAYER (without name and active layer prop)
  const int singleLayerSize =
      8 + //width
          8 + //height
          8 + //type
          12 + //opacity
          12 + //float opacity
          12 + //visible
          12 + //linked
          12 + //color tag
          12 + //lock content
          12 + //lock alpha
          12 + //lock position
          12 + //apply mask
          12 + //edit mask
          12 + //show mask
          16 + //offsets
          12 + //mode
          12 + //blend space
          12 + //composite space
          12 + //composite mode
          12 + //tattoo
          8 + //prop end
          8 + //hierarchy ptr
          8; //layer mask ptr

  //HIERARCHY
  const int hierarchySize = 4 + //width
      4 + //height
      4 + //bpp
      (4 * 8); //level pointers and end

  //LEVEL
  const int basicLevelSize = 4 + //width
      4 + //height
      8; //pointer end

  final List<List<List<int>>> layerEncBytes = <List<List<int>>>[];
  final List<Uint8List> layerNames = <Uint8List>[];
  const int tileSize = 64;
  final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];
  for (int l = 0; l < layerCollection.length; l++)
  {
    final LayerState layer = layerCollection.getLayer(index: l);
    if (layer.runtimeType == DrawingLayerState)
    {
      final DrawingLayerState layerState = layer as DrawingLayerState;
      int x = 0;
      int y = 0;
      final List<List<int>> tileList = <List<int>>[];
      do //TILING
          {
        final List<int> imgBytes = <int>[];
        final int endX = min(x + tileSize, canvasSize.x);
        final int endY = min(y + tileSize, canvasSize.y);
        for (int b = y; b < endY; b++)
        {
          for (int a = x; a < endX; a++)
          {
            final CoordinateSetI curCoord = CoordinateSetI(x: a, y: b);
            ColorReference? colAtPos;
            if (l == layerCollection.selectedLayerIndex)
            {
              colAtPos = selection.getColorReference(coord: curCoord);
            }
            colAtPos ??= layerState.getDataEntry(coord: curCoord, withSettingsPixels: true);

            if (colAtPos == null)
            {
              imgBytes.add(0);
              imgBytes.add(0);
            }
            else
            {
              final int shade = _getShadeForCoord(layerCollection: layerCollection, currentLayerIndex: l, coord: curCoord);
              if (shade != 0)
              {
                final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.references.length - 1);
                colAtPos = colAtPos.ramp.references[targetIndex];
              }
              imgBytes.add(colorMap[colAtPos]!);
              imgBytes.add(255);
            }
          }
        }
        final List<int> encData = const ZLibEncoder().encode(imgBytes);
        tileList.add(encData);

        x = (endX >= canvasSize.x) ? 0 : endX;
        y = (endX >= canvasSize.x) ? endY : y;
      }
      while (y < canvasSize.y);

      layerNames.add(utf8.encode("Layer$l"));
      layerEncBytes.add(tileList);
      drawingLayers.add(layerState);
    }
    }

  //CALCULATING SIZE
  bool activeLayerSet = false;
  int fileSize = fullHeaderSize;
  for (int i = 0; i < drawingLayers.length; i++)
  {
    final List<List<int>> tiles = layerEncBytes[i];
    fileSize += singleLayerSize;
    if (!activeLayerSet)
    {
      fileSize += 8; //ACTIVE LAYER
      activeLayerSet = true;
    }
    //name
    fileSize += 4 + layerNames[i].length + 1;
    //hierarchy
    fileSize += hierarchySize;
    //level 1
    fileSize += basicLevelSize;
    //tile data
    for (final List<int> tileData in tiles)
    {
      fileSize += tileData.length;
    }
    fileSize += tiles.length * 8;
    //level 2
    fileSize += basicLevelSize - 4;
    //level3
    fileSize += basicLevelSize - 4;
  }


  //WRITING

  final List<int> layerOffsetsInsertPositions = <int>[];

  int tattooIndex = 2;
  final ByteData outBytes = ByteData(fileSize);
  int offset = 0;

  //header
  final Uint8List fileType = utf8.encode("gimp xcf ");
  final Uint8List version = utf8.encode("v011");
  for (int i = 0; i < fileType.length; i++)
  {
    outBytes.setUint8(offset, fileType[i]);
    offset++;
  }

  for (int i = 0; i < version.length; i++)
  {
    outBytes.setUint8(offset, version[i]);
    offset++;
  }

  outBytes.setUint8(offset, 0);
  offset++;
  outBytes.setUint32(offset, canvasSize.x); //width;
  offset+=4;
  outBytes.setUint32(offset, canvasSize.y); //height
  offset+=4;
  outBytes.setUint32(offset, 2); //base type (2=indexed)
  offset+=4;
  outBytes.setUint32(offset, 150); //precision (8-bit gamma)
  offset+=4;

  //prop list

  //PROP_COLORMAP
  outBytes.setUint32(offset, 1);
  offset+=4;
  outBytes.setUint32(offset, (3 * colorList.length) + 4);
  offset+=4;
  outBytes.setUint32(offset, colorList.length);
  offset+=4;
  for (final Color c in colorList)
  {
    outBytes.setUint8(offset, (c.r * 255).toInt());
    offset++;
    outBytes.setUint8(offset, (c.g * 255).toInt());
    offset++;
    outBytes.setUint8(offset, (c.b * 255).toInt());
    offset++;
  }

  //PROP_COMPRESSION
  outBytes.setUint32(offset, 17);
  offset+=4;
  outBytes.setUint32(offset, 1);

  offset+=4;
  outBytes.setUint8(offset, 2);
  offset++;

  //PROP_RESOLUTION
  outBytes.setUint32(offset, 19);
  offset+=4;
  outBytes.setUint32(offset, 8);
  offset+=4;
  outBytes.setFloat32(offset, 300);
  offset+=4;
  outBytes.setFloat32(offset, 300);
  offset+=4;

  //PROP_TATTOO
  outBytes.setUint32(offset, 20);
  offset+=4;
  outBytes.setUint32(offset, 4);
  offset+=4;
  outBytes.setUint32(offset, tattooIndex++);
  offset+=4;

  //PROP_UNIT
  outBytes.setUint32(offset, 22);
  offset+=4;
  outBytes.setUint32(offset, 4);
  offset+=4;
  outBytes.setUint32(offset, 1);
  offset+=4;

  //PROP_END
  outBytes.setUint32(offset, 0);
  offset+=4;
  outBytes.setUint32(offset, 0);
  offset+=4;

  //LAYER POINTERS
  for (int i = 0; i < drawingLayers.length; i++)
  {
    layerOffsetsInsertPositions.add(offset);
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;
  }

  setUint64(bytes: outBytes, offset: offset, value: 0); //end layer pointers
  offset+=8;
  setUint64(bytes: outBytes, offset: offset, value: 0); //start/end channel pointers
  offset+=8;


  //LAYERS
  for (int i = 0; i < drawingLayers.length; i++)
  {
    setUint64(bytes: outBytes, offset: layerOffsetsInsertPositions[i], value: offset);

    final DrawingLayerState currentLayer = drawingLayers[i];
    outBytes.setUint32(offset, canvasSize.x);
    offset+=4;
    outBytes.setUint32(offset, canvasSize.y);
    offset+=4;
    outBytes.setUint32(offset, 5);
    offset+=4;
    outBytes.setUint32(offset, layerNames[i].length + 1);
    offset+=4;
    for (int j = 0; j < layerNames[i].length; j++)
    {
      outBytes.setUint8(offset, layerNames[i][j]);
      offset++;
    }
    outBytes.setUint8(offset, 0);
    offset++;

    //PROP_ACTIVE_LAYER
    if (i == 0)
    {
      outBytes.setUint32(offset, 2);
      offset+=4;
      outBytes.setUint32(offset, 0);
      offset+=4;
    }

    //PROP_OPACITY
    outBytes.setUint32(offset, 6);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 255);
    offset+=4;

    //PROP_FLOAT_OPACITY
    outBytes.setUint32(offset, 33);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setFloat32(offset, 1.0);
    offset+=4;

    //PROP_VISIBLE
    outBytes.setUint32(offset, 8);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, currentLayer.visibilityState.value == LayerVisibilityState.visible ? 1 : 0);
    offset+=4;

    //PROP_LINKED
    outBytes.setUint32(offset, 9);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_COLOR_TAG
    outBytes.setUint32(offset, 34);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_LOCK_CONTENT
    outBytes.setUint32(offset, 28);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, currentLayer.lockState.value == LayerLockState.locked ? 1 : 0);
    offset+=4;

    //PROP_LOCK_ALPHA
    outBytes.setUint32(offset, 10);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, currentLayer.lockState.value == LayerLockState.transparency ? 1 : 0);
    offset+=4;

    //PROP_LOCK_POSITION
    outBytes.setUint32(offset, 32);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_APPLY_MASK
    outBytes.setUint32(offset, 11);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_EDIT_MASK
    outBytes.setUint32(offset, 12);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_SHOW_MASK
    outBytes.setUint32(offset, 13);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_OFFSETS
    outBytes.setUint32(offset, 15);
    offset+=4;
    outBytes.setUint32(offset, 8);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_MODE
    outBytes.setUint32(offset, 7);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 28);
    offset+=4;

    //PROP_BLEND_SPACE
    outBytes.setUint32(offset, 37);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //PROP_COMPOSITE_SPACE
    outBytes.setUint32(offset, 36);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setInt32(offset, -1);
    offset+=4;

    //PROP_COMPOSITE_MODE
    outBytes.setUint32(offset, 35);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setInt32(offset, -1);
    offset+=4;

    //PROP_TATTOO
    outBytes.setUint32(offset, 20);
    offset+=4;
    outBytes.setUint32(offset, 4);
    offset+=4;
    outBytes.setUint32(offset, tattooIndex++);
    offset+=4;

    //PROP_END
    outBytes.setUint32(offset, 0);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;

    //HIERARCHY OFFSET
    final int hierarchyOffsetInsertPosition = offset;
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;

    //LAYER MASK
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;

    //HIERARCHY
    setUint64(bytes: outBytes, offset: hierarchyOffsetInsertPosition, value: offset);
    outBytes.setUint32(offset, canvasSize.x);
    offset+=4;
    outBytes.setUint32(offset, canvasSize.y);
    offset+=4;
    outBytes.setUint32(offset, 2);
    offset+=4;
    final int pointerInsertToLevel1 = offset;
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;
    final int pointerInsertToLevel2 = offset;
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;
    final int pointerInsertToLevel3 = offset;
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;

    //LEVEL1
    setUint64(bytes: outBytes, offset: pointerInsertToLevel1, value: offset);
    outBytes.setUint32(offset, canvasSize.x);
    offset+=4;
    outBytes.setUint32(offset, canvasSize.y);
    offset+=4;
    final List<int> tileOffsetsLv1 = <int>[];
    final List<List<int>> currentTiles = layerEncBytes[i];
    for (int j = 0; j < currentTiles.length; j++)
    {
      tileOffsetsLv1.add(offset);
      setUint64(bytes: outBytes, offset: offset, value: 0);
      offset+=8;
    }
    setUint64(bytes: outBytes, offset: offset, value: 0);
    offset+=8;

    //TILE DATA FOR LEVEL1
    for (int j = 0; j < currentTiles.length; j++)
    {
      setUint64(bytes: outBytes, offset: tileOffsetsLv1[j], value: offset);
      final List<int> currentTile = currentTiles[j];
      for (int k = 0; k < currentTile.length; k++)
      {
        outBytes.setUint8(offset, currentTile[k]);
        offset++;
      }
    }

    //LEVEL2
    setUint64(bytes: outBytes, offset: pointerInsertToLevel2, value: offset);
    outBytes.setUint32(offset, canvasSize.x ~/ 2);
    offset+=4;
    outBytes.setUint32(offset, canvasSize.y ~/ 2);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;
    //LEVEL3
    setUint64(bytes: outBytes, offset: pointerInsertToLevel3, value: offset);
    outBytes.setUint32(offset, canvasSize.x ~/ 4);
    offset+=4;
    outBytes.setUint32(offset, canvasSize.y ~/ 4);
    offset+=4;
    outBytes.setUint32(offset, 0);
    offset+=4;
  }

  return outBytes.buffer.asUint8List();
}
