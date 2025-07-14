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

Future<Uint8List?> getPixeloramaData({required final ExportData exportData, required final AppState appState}) async
{
  final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];
  for (int l = 0; l < appState.layerCount; l++)
  {
    final LayerState? layerState = appState.getLayerAt(index: l);
    if (layerState != null && layerState.runtimeType == DrawingLayerState)
    {
      drawingLayers.add(layerState as DrawingLayerState);
    }
  }

  if (drawingLayers.isEmpty)
  {
    return null;
  }

  //data.json
  final StringBuffer dataBuffer = StringBuffer();
  dataBuffer.write('{"color_mode": 5,"frames": [{"cels": [');
  for (int i = 0; i < drawingLayers.length; i++)
  {
    dataBuffer.write("{}");
    if (i != drawingLayers.length - 1)
    {
      dataBuffer.write(",");
    }
  }

  dataBuffer.write(']}],"layers": [');
  for (final DrawingLayerState drawingLayer in drawingLayers)
  {
    dataBuffer.write('{"locked": ');
    drawingLayer.lockState.value == LayerLockState.locked ? dataBuffer.write('true') : dataBuffer.write('false');
    dataBuffer.write(',"visible": ');
    drawingLayer.visibilityState.value == LayerVisibilityState.visible ? dataBuffer.write('true') : dataBuffer.write('false');
    dataBuffer.write('}');
    if (drawingLayer != drawingLayers.last)
    {
      dataBuffer.write(',');
    }
  }
  dataBuffer.write('],');
  dataBuffer.write('"size_x": ');
  dataBuffer.write(appState.canvasSize.x);
  dataBuffer.write(',"size_y": ');
  dataBuffer.write(appState.canvasSize.y);
  dataBuffer.write('}');

  final List<ByteData> layerList = <ByteData>[];
  final List<ByteData> indexList = <ByteData>[];

  //LAYERS
  final List<ui.Color> colorList = <ui.Color>[];
  final Map<ColorReference, int> colorMap = <ColorReference, int>{};
  colorList.add(Colors.black);
  int index = 1;
  for (final KPalRampData kPalRampData in appState.colorRamps)
  {
    for (int i = 0; i < kPalRampData.shiftedColors.length; i++)
    {
      colorList.add(kPalRampData.shiftedColors[i].value.color);
      colorMap[kPalRampData.references[i]] = index;
      index++;
    }
  }

  final int layerFileSize = appState.canvasSize.x * appState.canvasSize.y * 4;
  final int indexFileSize = appState.canvasSize.x * appState.canvasSize.y;

  for (int l = 0; l < appState.layerCount; l++)
  {
    final LayerState? layer = appState.getLayerAt(index: l);
    if (layer != null)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final ByteData layerData = ByteData(layerFileSize);
        final ByteData indexData = ByteData(indexFileSize);
        int byteOffsetLayer = 0;
        int byteOffsetIndex = 0;

        final DrawingLayerState layerState = layer as DrawingLayerState;
        for (int y = 0; y < appState.canvasSize.y; y++)
        {
          for (int x = 0; x < appState.canvasSize.x; x++)
          {
            final CoordinateSetI curCoord = CoordinateSetI(x: x, y: y);
            ColorReference? colAtPos;
            if (appState.getSelectedLayer() == layer)
            {
              colAtPos = appState.selectionState.selection.getColorReference(coord: curCoord);
            }
            colAtPos ??= layerState.getDataEntry(coord: curCoord, withSettingsPixels: true);

            if (colAtPos == null)
            {
              indexData.setUint8(byteOffsetIndex++, 0);
              layerData.setUint8(byteOffsetLayer++, 0);//r
              layerData.setUint8(byteOffsetLayer++, 0);//g
              layerData.setUint8(byteOffsetLayer++, 0);//b
              layerData.setUint8(byteOffsetLayer++, 0);//a
            }
            else
            {
              final int shade = _getShadeForCoord(appState: appState, currentLayerIndex: l, coord: curCoord);
              if (shade != 0)
              {
                final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.references.length - 1);
                colAtPos = colAtPos.ramp.references[targetIndex];
              }
              indexData.setUint8(byteOffsetIndex++, colorMap[colAtPos]!);
              layerData.setUint8(byteOffsetLayer++, (colAtPos.getIdColor().color.r * 255.0).round());//r
              layerData.setUint8(byteOffsetLayer++, (colAtPos.getIdColor().color.g * 255.0).round());//g
              layerData.setUint8(byteOffsetLayer++, (colAtPos.getIdColor().color.b * 255.0).round());//b
              layerData.setUint8(byteOffsetLayer++, 255);//a

            }
          }
        }
        layerList.add(layerData);
        indexList.add(indexData);
      }
    }


  }

  final Archive zipFile = Archive();
  final List<int> dataBytes = utf8.encode(dataBuffer.toString());
  zipFile.addFile(ArchiveFile("data.json", dataBytes.length, dataBytes));


  const String layerDir = "image_data/frames/1";
  int layerIndex = 1;
  for (int l = layerList.length - 1; l >= 0; l--)
  {
    final Uint8List layerData = layerList[l].buffer.asUint8List();
    final Uint8List indexData = indexList[l].buffer.asUint8List();
    final String layerPath = "$layerDir/layer_$layerIndex";
    final String indexPath = "$layerDir/indices_layer_$layerIndex";
    zipFile.addFile(ArchiveFile(layerPath, layerData.length, layerData));
    zipFile.addFile(ArchiveFile(indexPath, indexData.length, indexData));
    layerIndex++;
  }

  return Uint8List.fromList(ZipEncoder().encode(zipFile));

}
