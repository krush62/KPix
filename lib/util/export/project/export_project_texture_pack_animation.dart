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

Future<Uint8List?> exportTexturePackAnimation({required final AnimationExportData exportData, required final AppState appState}) async
{
  final Archive zipFile = Archive();

  //create palette data
  final Uint8List paletteData = await createPaletteData(ramps: appState.colorRamps);
  final List<int> paletteDataList = paletteData.toList();
  zipFile.addFile(ArchiveFile("palette.bin", paletteDataList.length, paletteDataList));

  final int startFrameIndex = exportData.loopOnly ? appState.timeline.loopStartIndex.value : 0;
  final int endFrameIndex = exportData.loopOnly ? appState.timeline.loopEndIndex.value : appState.timeline.frames.value.length - 1;
  int frameCounter = 0;
  for (int frameIndex = startFrameIndex; frameIndex <= endFrameIndex; frameIndex++)
  {
    //Frame Name with two padding zeros
    final String frameName = "frame_${frameCounter.toString().padLeft(2, '0')}";
    final CoordinateColorMapNullable colorMap = await getMergedColors(frame: appState.timeline.frames.value[frameIndex], canvasSize: appState.canvasSize);

    //create color texture
    final Uint8List colorTexture = await createColorTexture(colorMap: colorMap, canvasSize: appState.canvasSize, ramps: appState.colorRamps);
    final List<int> colorTextureList = colorTexture.toList();
    zipFile.addFile(ArchiveFile("$frameName/color.bin", colorTextureList.length, colorTextureList));

    //create distance texture
    final Uint8List distanceTexture = await createDistanceTexture(colorMap: colorMap, canvasSize: appState.canvasSize, ramps: appState.colorRamps);
    final List<int> distanceTextureList = distanceTexture.toList();
    zipFile.addFile(ArchiveFile("$frameName/distance.bin", distanceTextureList.length, distanceTextureList));
    frameCounter++;
  }
  return Uint8List.fromList(ZipEncoder().encode(zipFile));
}
