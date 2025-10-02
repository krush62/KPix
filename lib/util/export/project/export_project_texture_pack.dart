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

Future<Uint8List?> exportTexturePack({required final ImageExportData exportData, required final AppState appState}) async
{
  final Archive zipFile = Archive();

  final CoordinateColorMapNullable colorMap = await getMergedColors(frame: appState.timeline.selectedFrame!, canvasSize: appState.canvasSize);

  //create color texture
  final Uint8List colorTexture = await createColorTexture(colorMap: colorMap, canvasSize: appState.canvasSize, ramps: appState.colorRamps);
  final List<int> colorTextureList = colorTexture.toList();
  zipFile.addFile(ArchiveFile("color.bin", colorTextureList.length, colorTextureList));

  //create distance texture
  final Uint8List distanceTexture = await createDistanceTexture(colorMap: colorMap, canvasSize: appState.canvasSize, ramps: appState.colorRamps);
  final List<int> distanceTextureList = distanceTexture.toList();
  zipFile.addFile(ArchiveFile("distance.bin", distanceTextureList.length, distanceTextureList));

  //create palette data
  final Uint8List paletteData = await createPaletteData(ramps: appState.colorRamps);
  final List<int> paletteDataList = paletteData.toList();
  zipFile.addFile(ArchiveFile("palette.bin", paletteDataList.length, paletteDataList));

  return Uint8List.fromList(ZipEncoder().encode(zipFile));
}


Future<Uint8List> createColorTexture({required final CoordinateColorMapNullable colorMap, required final CoordinateSetI canvasSize, required final List<KPalRampData> ramps}) async
{
  final int fileSize = canvasSize.x * canvasSize.y;
  final ByteData outBytes = ByteData(fileSize);
  int offset = 0;
  for (int y = 0; y < canvasSize.y; y++)
  {
    for (int x = 0; x < canvasSize.x; x++)
    {
      final CoordinateSetI pos = CoordinateSetI(x: x, y: y);
      final ColorReference? colAtPos = colorMap[pos];
      if (colAtPos == null)
      {
        outBytes.setUint8(offset++, 255);
      }
      else
      {
        outBytes.setUint8(offset++, ramps.indexOf(colAtPos.ramp));
      }
    }
  }
  return outBytes.buffer.asUint8List();
}

Future<Uint8List> createDistanceTexture({required final CoordinateColorMapNullable colorMap, required final CoordinateSetI canvasSize, required final List<KPalRampData> ramps}) async
{
  final int fileSize = canvasSize.x * canvasSize.y;
  final ByteData outBytes = ByteData(fileSize);
  int offset = 0;
  for (int y = 0; y < canvasSize.y; y++)
  {
    for (int x = 0; x < canvasSize.x; x++)
    {
      final CoordinateSetI pos = CoordinateSetI(x: x, y: y);
      final ColorReference? colAtPos = colorMap[pos];
      if (colAtPos == null)
      {
        outBytes.setUint8(offset++, 255);
      }
      else
      {
        final int distance = 255 - (colAtPos.colorIndex.toDouble() * (255.0 / colAtPos.ramp.references.length.toDouble())).round();
        outBytes.setUint8(offset++, distance);
      }
    }

  }
  return outBytes.buffer.asUint8List();
}

Future<Uint8List> createPaletteData({required final List<KPalRampData> ramps}) async
{
  int colorCount = 0;
  for (final KPalRampData ramp in ramps)
  {
    colorCount += ramp.shiftedColors.length;
  }

  final int fileSize = colorCount * 4 + 1;
  final ByteData outBytes = ByteData(fileSize);
  int offset = 0;
  outBytes.setUint8(offset++, ramps.length);
  //outBytes.setUint8(offset++, ramps.first.shiftedColors.length);

  for (final KPalRampData ramp in ramps)
  {
    outBytes.setUint8(offset++, ramp.shiftedColors.length);
    for (final ValueNotifier<IdColor> ref in ramp.shiftedColors)
    {
      final int r = (ref.value.color.r * 255.0).round();
      final int g = (ref.value.color.g * 255.0).round();
      final int b = (ref.value.color.b * 255.0).round();
      outBytes.setUint8(offset++, r);
      outBytes.setUint8(offset++, g);
      outBytes.setUint8(offset++, b);
    }
  }
  return outBytes.buffer.asUint8List();
}
