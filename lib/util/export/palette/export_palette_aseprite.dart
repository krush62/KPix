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

Future<Uint8List?> getPaletteAsepriteData({required final List<KPalRampData> rampList}) async
{
  final List<ui.Color> colorList = _getColorList(ramps: rampList);
  colorList.insert(0, Colors.black);
  assert(colorList.length < 256);
  final List<List<int>> layerEncBytes = <List<int>>[];
  final List<Uint8List> layerNames = <Uint8List>[];
  final List<int> imgBytes = <int>[];
  for (int i = 0; i < colorList.length; i++)
  {
    imgBytes.add(i);
  }
  final List<int> encData = const ZLibEncoder().encode(imgBytes);
  layerEncBytes.add(encData);
  layerNames.add(utf8.encode("KPixPalette"));

  return _createAsepriteData(colorList: colorList, layerNames: layerNames, layerEncBytes: layerEncBytes, canvasSize: CoordinateSetI(x: colorList.length, y: 1));
}
