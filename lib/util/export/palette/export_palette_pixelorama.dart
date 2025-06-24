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

Future<Uint8List> getPaletteJsonData({required final List<KPalRampData> rampList}) async
{
  final List<ui.Color> colorList = _getColorList(ramps: rampList);
  final StringBuffer stringBuffer = StringBuffer();
  stringBuffer.writeln('{"colors": [');
  for (int i = 0; i < colorList.length; i++)
  {
    stringBuffer.write('{"color": "(${colorList[i].r}, ${colorList[i].g}, ${colorList[i].b}, 1)", "index": $i}');
    if (i < colorList.length - 1)
    {
      stringBuffer.writeln(',');
    }
    else
    {
      stringBuffer.writeln();
    }
  }
  stringBuffer.write(']}');
  final String str = stringBuffer.toString();
  return Uint8List.fromList(utf8.encode(str));
}
