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

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/util/helper.dart';
import 'dart:ui' as ui;

enum StampType
{
  stampCircle15,
  stampCircle27,
  stampDiamond7,
  stampDiamond13,
  stampGrass1,
  stampLeaves1,
  stampLeaves2,
  stampLeaves3,
  stampSquare5,
  stampSquare11,
  stampStar3,
  stampStar5,
  stampStar7
}

const Map<int, StampType> stampIndexMap =
{
  0:StampType.stampCircle15,
  1:StampType.stampCircle27,
  2:StampType.stampDiamond7,
  3:StampType.stampDiamond13,
  4:StampType.stampGrass1,
  5:StampType.stampLeaves1,
  6:StampType.stampLeaves2,
  7:StampType.stampLeaves3,
  8:StampType.stampSquare5,
  9:StampType.stampSquare11,
  10:StampType.stampStar3,
  11:StampType.stampStar5,
  12:StampType.stampStar7,
};

const Map<StampType, String> stampNameMap =
{
  StampType.stampCircle15: "Circle 15",
  StampType.stampCircle27: "Circle 27",
  StampType.stampDiamond7: "Diamond 7",
  StampType.stampDiamond13: "Diamond 13",
  StampType.stampGrass1: "Grass 1",
  StampType.stampLeaves1: "Leaves 1",
  StampType.stampLeaves2: "Leaves 2",
  StampType.stampLeaves3: "Leaves 3",
  StampType.stampSquare5: "Square 5",
  StampType.stampSquare11: "Square 11",
  StampType.stampStar3: "Star 3",
  StampType.stampStar5: "Star 5",
  StampType.stampStar7: "Star 7"
};

const Map<StampType, String> _stampFileMap =
{
  StampType.stampCircle15: "Circle15.png",
  StampType.stampCircle27: "Circle27.png",
  StampType.stampDiamond7: "Diamond7.png",
  StampType.stampDiamond13: "Diamond13.png",
  StampType.stampGrass1: "Grass1.png",
  StampType.stampLeaves1: "Leaves1.png",
  StampType.stampLeaves2: "Leaves2.png",
  StampType.stampLeaves3: "Leaves3.png",
  StampType.stampSquare5: "Square5.png",
  StampType.stampSquare11: "Square11.png",
  StampType.stampStar3: "Star3.png",
  StampType.stampStar5: "Star5.png",
  StampType.stampStar7: "Star7.png"
};

class KStamp
{
  final HashMap<CoordinateSetI, int> data;
  final int width;
  final int height;
  KStamp({required this.data, required this.width, required this.height});
}

const String stampPath = "stamps";

class StampManager
{
  final HashMap<StampType, KStamp> stampMap;
  StampManager({required this.stampMap});

  static Future<HashMap<StampType, KStamp>> readStamps() async
  {
    final HashMap<StampType, KStamp> stampMap = HashMap();
    for (final MapEntry<StampType, String> mapEntry in _stampFileMap.entries)
    {
      stampMap[mapEntry.key] = await _readStampFromFile("$stampPath/${mapEntry.value}");
    }
    return stampMap;
  }

  static Future<KStamp> _readStampFromFile(final String fileName) async
  {
    final ByteData byteData = await rootBundle.load(fileName);
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final ui.Image decImg = await decodeImageFromList(pngBytes);
    final int imgHeight = decImg.height;
    final int imgWidth = decImg.width;
    final ByteData? imgData = await decImg.toByteData();
    final HashMap<CoordinateSetI, int> stampMap = HashMap();

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
    }
    return KStamp(data: stampMap, width: imgWidth, height: imgHeight);
  }
}