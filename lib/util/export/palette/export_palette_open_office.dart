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

Future<Uint8List> getPaletteOpenOfficeData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
{
  final List<ui.Color> colorList = _getColorList(ramps: rampList);
  final StringBuffer stringBuffer = StringBuffer();
  stringBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  stringBuffer.writeln(
      '<office:color-table xmlns:office="http://openoffice.org/2000/office" '
          'xmlns:style="http://openoffice.org/2000/style" '
          'xmlns:text="http://openoffice.org/2000/text" '
          'xmlns:table="http://openoffice.org/2000/table" '
          'xmlns:draw="http://openoffice.org/2000/drawing" '
          'xmlns:fo="http://www.w3.org/1999/XSL/Format" '
          'xmlns:xlink="http://www.w3.org/1999/xlink" '
          'xmlns:dc="http://purl.org/dc/elements/1.1/" '
          'xmlns:meta="http://openoffice.org/2000/meta" '
          'xmlns:number="http://openoffice.org/2000/datastyle" '
          'xmlns:svg="http://www.w3.org/2000/svg" '
          'xmlns:chart="http://openoffice.org/2000/chart" '
          'xmlns:dr3d="http://openoffice.org/2000/dr3d" '
          'xmlns:math="http://www.w3.org/1998/Math/MathML" '
          'xmlns:form="http://openoffice.org/2000/form" '
          'xmlns:script="http://openoffice.org/2000/script" '
          'xmlns:config="http://openoffice.org/2001/config">');

  for (final ui.Color color in colorList)
  {
    final String colorHex = colorToHexString(c: color).toLowerCase();
    final String colorName = escapeXml(input: colorNames.getColorName(r: color.r, g: color.g, b: color.b));
    stringBuffer.writeln('\t<draw:color draw:name="$colorName" draw:color="$colorHex"/>');
  }

  stringBuffer.writeln('</office:color-table>');
  final String str = stringBuffer.toString();
  return Uint8List.fromList(utf8.encode(str));
}
