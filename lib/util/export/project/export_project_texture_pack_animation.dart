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
  final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
  final Map<String, Uint8List> files = <String, Uint8List>{
    "palette.bin": await createPaletteData(ramps: ramps),
  };

  final int startFrameIndex = exportData.loopOnly ? appState.timeline.loopStartIndex.value : 0;
  final int endFrameIndex = exportData.loopOnly ? appState.timeline.loopEndIndex.value : appState.timeline.frames.value.length - 1;
  int frameCounter = 0;
  for (int frameIndex = startFrameIndex; frameIndex <= endFrameIndex; frameIndex++)
  {
    //Frame Name with two padding zeros
    final String frameName = "frame_${frameCounter.toString().padLeft(2, '0')}";
    final CoordinateSetI canvasSize = GetIt.I.get<CanvasState>().canvasSize;
    final CoordinateColorMapNullable colorMap = await getMergedColors(frame: appState.timeline.frames.value[frameIndex], canvasSize: canvasSize);

    files["$frameName/color.bin"] = await createColorTexture(colorMap: colorMap, canvasSize: canvasSize, ramps: ramps);
    files["$frameName/distance.bin"] = await createDistanceTexture(colorMap: colorMap, canvasSize: canvasSize, ramps: ramps);
    frameCounter++;
  }

  return await _zipOffThread(files: files, debugLabel: "texture-pack-animation-export");
}
