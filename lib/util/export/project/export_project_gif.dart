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


class _GifExportParams {
  final List<Uint8List> frameData;
  final List<int> frameDurations;
  final int width;
  final int height;

  _GifExportParams({
    required this.frameData,
    required this.frameDurations,
    required this.width,
    required this.height,
  });
}

Future<Uint8List?> exportGIF({required final AnimationExportData exportData, required final AppState appState}) async {
  final int startFrame = exportData.loopOnly ? appState.timeline.loopStartIndex.value : 0;
  final int endFrame = exportData.loopOnly ? appState.timeline.loopEndIndex.value : appState.timeline.frames.value.length - 1;

  final int width = appState.canvasSize.x * exportData.scaling;
  final int height = appState.canvasSize.y * exportData.scaling;

  final List<Uint8List> frameDatas = <Uint8List>[];
  final List<int> durations = <int>[];

  // 1. Prepare frame data (must happen in main isolate due to getImageFromLayers)
  for (int i = startFrame; i <= endFrame; i++) {
    final Frame frame = appState.timeline.frames.value[i];
    final ui.Image uiImage = await getImageFromLayers(
      selection: appState.selectionState.selection,
      canvasSize: appState.canvasSize,
      layerCollection: frame.layerList,
      scalingFactor: exportData.scaling,
      frame: frame,
    );

    final ByteData? uiBytes = await uiImage.toByteData();
    if (uiBytes == null) return null;

    frameDatas.add(uiBytes.buffer.asUint8List());
    durations.add(frame.frameTime);

    // Dispose UI image to save memory
    uiImage.dispose();
  }

  // 2. Run encoding in an isolate
  return await compute(_encodeGifIsolate, _GifExportParams(
    frameData: frameDatas,
    frameDurations: durations,
    width: width,
    height: height,
  ),);
}

/// The actual encoding logic that runs in the background isolate
Uint8List? _encodeGifIsolate(final _GifExportParams params) {
  final img.Image gifImg = img.Image(
    width: params.width,
    height: params.height,
    numChannels: 4,
  );

  for (int i = 0; i < params.frameData.length; i++) {
    final img.Image frame = img.Image.fromBytes(
      width: params.width,
      height: params.height,
      bytes: params.frameData[i].buffer,
      order: img.ChannelOrder.rgba,
      numChannels: 4,
      frameDuration: params.frameDurations[i],
    );

    if (i == 0) {
      gifImg.frames[0] = frame;
    } else {
      gifImg.addFrame(frame);
    }
  }

  return img.encodeGif(gifImg);
}
