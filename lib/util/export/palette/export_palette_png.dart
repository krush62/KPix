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

part of '../../export_functions.dart';

Future<Uint8List?> getPalettePngData({required final List<KPalRampData> ramps}) async
{
  final List<ui.Color> colorList = _getColorList(ramps: ramps);
  final ByteData byteData = await _getPaletteImageData(colorList: colorList);

  final Completer<ui.Image> c = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      byteData.buffer.asUint8List(),
      colorList.length,
      1,
      ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
  {
    c.complete(convertedImage);
  }
  );
  final ui. Image img = await c.future;

  final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  return pngBytes!.buffer.asUint8List();
}

Future<ByteData> _getPaletteImageData({required final List<ui.Color> colorList}) async
{
  final ByteData byteData = ByteData(colorList.length * 4);
  for (int i = 0; i < colorList.length; i++)
  {
    byteData.setUint32(i * 4, argbToRgba(argb: colorList[i].toARGB32()));
  }
  return byteData;
}
