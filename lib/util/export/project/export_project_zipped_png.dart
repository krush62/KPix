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

Future<Uint8List?> exportZippedPng({required final AnimationExportData exportData}) async
{
  final int startFrame = exportData.loopOnly ? GetIt.I.get<DocumentState>().timeline.loopStartIndex.value : 0;
  final int endFrame = exportData.loopOnly ? GetIt.I.get<DocumentState>().timeline.loopEndIndex.value : GetIt.I.get<DocumentState>().timeline.frames.value.length - 1;

  //encoding each png needs dart:ui and therefore the UI isolate
  final Map<String, Uint8List> files = <String, Uint8List>{};
  for (int i = startFrame; i <= endFrame; i++)
  {
    final Uint8List? png = await exportPNG(exportData: exportData, selection: GetIt.I.get<DocumentState>().selectionState.selection, canvasSize: GetIt.I.get<CanvasState>().canvasSize, layerList: GetIt.I.get<DocumentState>().timeline.frames.value[i].layerList);
    if (png != null)
    {
      files["frame_${(i + startFrame + 1).toString().padLeft(3, "0")}.png"] = png;
    }
  }

  return await _zipOffThread(files: files, debugLabel: "zipped-png-export");
}
