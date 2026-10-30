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

import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:kpix/util/helpers/png_helper.dart';
import 'package:path/path.dart' as p;

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
  final List<Uint8List> pngContents = await Future.wait(stampAssets.map((final String path) async => (await rootBundle.load(path)).buffer.asUint8List()));
  final List<StampManagerEntryData?> stamps = await _readStamps(pngContents: pngContents, fileNames: stampAssets, isLocked: true);
  for (int i = 0; i < stampAssets.length; i++)
  {
    final StampManagerEntryData? data = stamps[i];
    if (data != null)
    {
      final String folder = stampAssets[i].substring(0, stampAssets[i].lastIndexOf('/')).substring(stampRoot.length);
      stampData[folder] ??= <StampManagerEntryData>[];
      stampData[folder]!.add(data);
    }
  }
  return stampData;
}

Future<List<StampManagerEntryData>> _loadUserStamps() async
{
  final List<StampManagerEntryData> stampData = <StampManagerEntryData>[];
  final Directory dir = Directory(p.join(GetIt.I.get<AppPaths>().internalDir, stampsSubDirName));
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
  final List<Uint8List> pngContents = await Future.wait(filesWithExtension.map((final String filePath) => File(filePath).readAsBytes()));
  final List<StampManagerEntryData?> stamps = await _readStamps(pngContents: pngContents, fileNames: filesWithExtension, isLocked: false);
  stampData.addAll(stamps.nonNulls);
  return stampData;
}

/// Pixel data of a stamp, decoded away from the UI isolate.
class _StampPixels
{
  final int width;
  final int height;
  final HashMap<CoordinateSetI, int> data;

  _StampPixels({required this.width, required this.height, required this.data});
}

/// Reads all stamps at once; an entry is null if its file could not be decoded.
Future<List<StampManagerEntryData?>> _readStamps({required final List<Uint8List> pngContents, required final List<String> fileNames, required final bool isLocked}) async
{
  //the engine only decodes the thumbnails, the stamp data is decoded in Dart to avoid a GPU readback per stamp
  final Future<List<ui.Image?>> thumbnailsFuture = Future.wait(pngContents.map(_decodeStampThumbnail));
  final List<_StampPixels?> pixels = await _decodeStampsOffThread(pngContents: pngContents);
  final List<ui.Image?> thumbnails = await thumbnailsFuture;

  final List<StampManagerEntryData?> stamps = <StampManagerEntryData?>[];
  for (int i = 0; i < pngContents.length; i++)
  {
    final _StampPixels? stampPixels = pixels[i];
    final ui.Image? thumbnail = thumbnails[i];
    if (stampPixels != null && thumbnail != null)
    {
      stamps.add(StampManagerEntryData(path: fileNames[i], isLocked: isLocked, name: extractFilenameFromPath(path: fileNames[i], keepExtension: false), data: stampPixels.data, thumbnail: thumbnail, width: stampPixels.width, height: stampPixels.height));
    }
    else
    {
      thumbnail?.dispose();
      stamps.add(null);
    }
  }
  return stamps;
}

Future<ui.Image?> _decodeStampThumbnail(final Uint8List pngBytes) async
{
  try
  {
    return await decodeImageFromList(pngBytes);
  }
  catch (_)
  {
    return null;
  }
}

Future<List<_StampPixels?>> _decodeStampsOffThread({required final List<Uint8List> pngContents})
{
  return runOffThread<List<_StampPixels?>>(
    work: () => pngContents.map((final Uint8List pngBytes) => _decodeStampPixels(pngBytes: pngBytes)).toList(),
    debugLabel: "stamp decoding",
  );
}

_StampPixels? _decodeStampPixels({required final Uint8List pngBytes})
{
  final RgbaPixels? pixels = decodePngToRgba(pngBytes: pngBytes);
  if (pixels == null)
  {
    return null;
  }
  final int imgWidth = pixels.width;
  final int imgHeight = pixels.height;
  final ByteData imgData = pixels.bytes;
  final HashMap<CoordinateSetI, int> stampMap = HashMap<CoordinateSetI, int>();

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
  return _StampPixels(width: imgWidth, height: imgHeight, data: stampMap);
}
