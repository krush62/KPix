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

part of '../file_handler.dart';

Future<StampMap> loadStamps({required final bool loadUserStamps}) async
{
  const String userSectionName = "user";
  final StampMap allStamps = await _loadInstalledStamps();
  if (loadUserStamps)
  {
    allStamps[userSectionName] = await _loadUserStamps();
  }
  return allStamps;
}

Future<StampMap> _loadInstalledStamps() async
{
  final StampMap stampData = <String, List<StampManagerEntryData>>{};
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  const String stampRoot = "${PreferenceManager.ASSET_PATH_STAMPS}/";
  final List<String> stampAssets = assetManifest
      .listAssets()
      .where((final String path) => path.startsWith(stampRoot) && path.endsWith(".png"))
      .toList();
  for (final String path in stampAssets)
  {
    final String folder = path.substring(0, path.lastIndexOf('/')).substring(stampRoot.length);
    final ByteData byteData = await rootBundle.load(path);
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final StampManagerEntryData data = await _readStampFromFileData(pngBytes: pngBytes, fileName: path, isLocked: true);
    if (data.thumbnail != null)
    {
      stampData[folder] ??= <StampManagerEntryData>[];
      stampData[folder]!.add(data);
    }

  }
  return stampData;
}

Future<List<StampManagerEntryData>> _loadUserStamps() async
{
  final List<StampManagerEntryData> stampData = <StampManagerEntryData>[];
  final Directory dir = Directory(p.join(GetIt.I.get<AppState>().internalDir, stampsSubDirName));
  final List<String> filesWithExtension = <String>[];
  if (await dir.exists())
  {
    dir.listSync(followLinks: false).forEach((final FileSystemEntity entity)
    {
      if (entity is File && entity.path.endsWith(".png"))
      {
        filesWithExtension.add(entity.absolute.path);
      }
    });
  }
  for (final String filePath in filesWithExtension)
  {
    final Uint8List pngBytes = await File(filePath).readAsBytes();
    final StampManagerEntryData data = await _readStampFromFileData(pngBytes: pngBytes, fileName: filePath, isLocked: false);

    if (data.thumbnail != null)
    {
      stampData.add(data);
    }
  }
  return stampData;
}

Future<StampManagerEntryData> _readStampFromFileData({required final Uint8List pngBytes, required final String fileName, required final bool isLocked}) async
{
  final ui.Image decImg = await decodeImageFromList(pngBytes);
  final int imgHeight = decImg.height;
  final int imgWidth = decImg.width;
  final ByteData? imgData = await decImg.toByteData();
  final HashMap<CoordinateSetI, int> stampMap = HashMap<CoordinateSetI, int>();
  ui.Image? thumbnail;

  if (imgData != null)
  {
    for (int x = 0; x < imgWidth; x++)
    {
      for (int y = 0; y < imgHeight; y++)
      {
        final int r = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 0);
        final int g = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 1);
        final int b = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 2);
        final int a = imgData.getUint8((y * imgWidth * 4) + (x * 4) + 3);
        if (a == 255 && r == g && r == b)
        {
          int? val;
          if (r == 0)
          {
            val = -2;
          }
          else if (r == 64)
          {
            val = -1;
          }
          else if (r == 128)
          {
            val = 0;
          }
          else if (r == 192)
          {
            val = 1;
          }
          else if (r == 255)
          {
            val = 2;
          }

          if (val != null)
          {
            stampMap[CoordinateSetI(x: x, y: y)] = val;
          }
        }
      }
    }
    try
    {
      final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      thumbnail = frame.image;
    }
    catch(_){}

  }
  return StampManagerEntryData(path: fileName, isLocked: isLocked, name: extractFilenameFromPath(path: fileName, keepExtension: false), data: stampMap, thumbnail: thumbnail, width: imgWidth, height: imgHeight);
}
