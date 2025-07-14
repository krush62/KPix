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

Future<Uint8List?> getAsepriteData({required final ExportData exportData, required final AppState appState}) async
{
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
  assert(colorList.length < 256);

  final List<List<int>> layerEncBytes = <List<int>>[];
  final List<Uint8List> layerNames = <Uint8List>[];
  final List<DrawingLayerState> drawingLayers = <DrawingLayerState>[];

  for (int l = 0; l < appState.layerCount; l++)
  {
    final LayerState? layer = appState.getLayerAt(index: l);
    if (layer != null)
    {
      if (layer.runtimeType == DrawingLayerState)
      {
        final DrawingLayerState layerState = layer as DrawingLayerState;
        final List<int> imgBytes = <int>[];
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
              imgBytes.add(0);
            }
            else
            {
              final int shade = _getShadeForCoord(appState: appState, currentLayerIndex: l, coord: curCoord);
              if (shade != 0)
              {
                final int targetIndex = (colAtPos.colorIndex + shade).clamp(0, colAtPos.ramp.references.length - 1);
                colAtPos = colAtPos.ramp.references[targetIndex];
              }
              imgBytes.add(colorMap[colAtPos]!);
            }
          }
        }
        final List<int> encData = const ZLibEncoder().encode(imgBytes);
        layerEncBytes.add(encData);
        layerNames.add(utf8.encode("Layer$l"));
        drawingLayers.add(layerState);
      }
    }


  }

  return _createAsepriteData(colorList: colorList, layerNames: layerNames, layerEncBytes: layerEncBytes, canvasSize: appState.canvasSize, layerList: drawingLayers);
}
