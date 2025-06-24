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

Future<Uint8List?> exportPNG({required final ExportData exportData, required final AppState appState}) async
{
  final ByteData byteData = await _getImageData(
    scaling: exportData.scaling,
    appState: appState,
  );


  final Completer<ui.Image> c = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      byteData.buffer.asUint8List(),
      appState.canvasSize.x * exportData.scaling,
      appState.canvasSize.y * exportData.scaling,
      ui.PixelFormat.rgba8888, (final ui.Image convertedImage)
  {
    c.complete(convertedImage);
  }
  );
  final ui. Image img = await c.future;

  final ByteData? pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  return pngBytes!.buffer.asUint8List();
}

Future<ByteData> _getImageData({required final AppState appState, required final int scaling}) async
{
  final ui.Image i = await getImageFromLayers(appState: appState, scalingFactor: scaling);
  return (await i.toByteData())!;
}
