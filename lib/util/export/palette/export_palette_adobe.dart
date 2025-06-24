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

Future<Uint8List> getPaletteAdobeData({required final List<KPalRampData> rampList, required final ColorNames colorNames}) async
{
  final List<ui.Color> colorList = _getColorList(ramps: rampList);
  final BytesBuilder buffer = BytesBuilder();
  buffer.add(intToBytes(value: 0x46455341, length: 4));
  buffer.add(intToBytes(value: 0x00000100, length: 4));
  buffer.add(intToBytes(value: colorList.length, length: 4, reverse: true));
  for (final ui.Color color in colorList)
  {
    final String colorName = colorNames.getColorName(r: color.r, g: color.g, b: color.b);
    buffer.add(intToBytes(value: 0x0100, length: 2));
    buffer.add(intToBytes(value: 22 + (colorName.length * 2), length: 4, reverse: true));
    buffer.add(intToBytes(value: colorName.length + 1, length: 2, reverse: true));
    for (final int codeUnit in colorName.codeUnits)
    {
      if (codeUnit != '-'.codeUnitAt(0))
      {
        buffer.add(intToBytes(value: codeUnit, length: 2, reverse: true));
      }
    }
    buffer.add(intToBytes(value: 0, length: 2, reverse: true));

    buffer.add(stringToBytes(value: "RGB ")); // Color model

    // Color values
    buffer.add(float32ToBytes(value: color.r, reverse: true));
    buffer.add(float32ToBytes(value: color.g, reverse: true));
    buffer.add(float32ToBytes(value: color.b, reverse: true));

    // Color type
    buffer.add(intToBytes(value: 0, length: 2, reverse: true));
  }
  return buffer.toBytes();
}
