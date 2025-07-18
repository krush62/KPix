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

Future<Uint8List?> exportAPNG({required final AnimationExportData exportData, required final AppState appState}) async
{
  final int startFrame = exportData.loopOnly ? appState.timeline.loopStartIndex.value : 0;
  final int endFrame = exportData.loopOnly ? appState.timeline.loopEndIndex.value : appState.timeline.frames.value.length - 1;
  final img.Image pngImg = img.Image(width: appState.canvasSize.x * exportData.scaling, height: appState.canvasSize.y * exportData.scaling, numChannels: 4);

  for (int i = startFrame; i <= endFrame; i++)
  {
    final ui.Image uiImage = await getImageFromLayers(selection: appState.selectionState.selection, canvasSize: appState.canvasSize, layerCollection: appState.timeline.frames.value[i].layerList, scalingFactor: exportData.scaling);
    final ByteData? uiBytes = await uiImage.toByteData();
    if (uiBytes == null)
    {
      return null;
    }

    final img.Image frame = img.Image.fromBytes(
      width: uiImage.width,
      height: uiImage.height,
      bytes: uiBytes.buffer,
      order: img.ChannelOrder.rgba,
      numChannels: 4,
      frameDuration: appState.timeline.frames.value[i].frameTime,
    );

    if (i == 0)
    {
      pngImg.frames[0] = frame;
    }
    else
    {
      pngImg.addFrame(frame);
    }
  }
  return img.encodePng(pngImg);
}
