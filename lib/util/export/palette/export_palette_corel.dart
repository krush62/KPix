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

Future<Uint8List> getPaletteCorelData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
{
  final List<ui.Color> colorList = _getColorList(ramps: rampList);
  final StringBuffer stringBuffer = StringBuffer();
  stringBuffer.writeln('<? version = "1.0" ?>');
  stringBuffer.writeln('<palette name="" guid="">');
  stringBuffer.writeln("\t<colors>");
  stringBuffer.writeln("\t\t<page>");

  for (final ui.Color color in colorList)
  {
    stringBuffer.writeln('''\t\t\t<color cs="RGB" tints="${color.r.toStringAsFixed(6)},${color.g.toStringAsFixed(6)},${color.b.toStringAsFixed(6)}"name="${escapeXml(input: colorNames.getColorName(r: color.r, g: color.g, b: color.b))}" />''');
  }

  stringBuffer.writeln("\t\t</page>");
  stringBuffer.writeln("\t</colors>");
  stringBuffer.writeln("</palette>");

  final String str = stringBuffer.toString();
  return Uint8List.fromList(utf8.encode(str));
}
