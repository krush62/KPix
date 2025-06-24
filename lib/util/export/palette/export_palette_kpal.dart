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

const Map<SatCurve, int> _kpixKpalSatCurveMap =
<SatCurve, int>{
  SatCurve.noFlat:1,
  SatCurve.darkFlat:0,
  SatCurve.brightFlat:3,
  SatCurve.linear:2,
};


Future<Uint8List> createPaletteKPalData({required final List<KPalRampData> rampList}) async
{
  final ByteData byteData = ByteData(_calculateKPalFileSize(rampList: rampList));
  int offset = 0;

  //options
  byteData.setUint8(offset++, 0);

  //ramp count
  byteData.setUint8(offset++, rampList.length);
  for (final KPalRampData rampData in rampList)
  {
    //name length
    byteData.setUint8(offset++, 0);
    //color count
    byteData.setUint8(offset++, rampData.settings.colorCount);
    //base hue
    byteData.setUint16(offset, rampData.settings.baseHue, Endian.little);
    offset += 2;
    //base sat
    byteData.setUint16(offset, rampData.settings.baseSat, Endian.little);
    offset += 2;
    //hue shift
    byteData.setUint8(offset++, rampData.settings.hueShift);
    //hueShiftExp
    byteData.setFloat32(offset, rampData.settings.hueShiftExp, Endian.little);
    offset += 4;
    //sat shift
    byteData.setUint8(offset++, rampData.settings.satShift);
    //satShiftExp
    byteData.setFloat32(offset, rampData.settings.satShiftExp, Endian.little);
    offset += 4;
    //val min
    byteData.setUint8(offset++, rampData.settings.valueRangeMin);
    //val max
    byteData.setUint8(offset++, rampData.settings.valueRangeMax);
    for (int j = 0; j < rampData.settings.colorCount; j++)
    {
      //hue shift
      byteData.setUint8(offset++, rampData.shifts[j].hueShiftNotifier.value);
      //sat shift
      byteData.setUint8(offset++, rampData.shifts[j].satShiftNotifier.value);
      //val shift
      byteData.setUint8(offset++, rampData.shifts[j].valShiftNotifier.value);
    }
    //ramp option count
    byteData.setUint8(offset++, 1);
    //sat curve option
    byteData.setUint8(offset++, 1); //option type sat curve
    //sat curve value
    byteData.setUint8(offset++, _kpixKpalSatCurveMap[rampData.settings.satCurve]?? 0);
  }

  //link count
  byteData.setUint8(offset++, 0);

  return byteData.buffer.asUint8List();
}

int _calculateKPalFileSize({required final List<KPalRampData> rampList})
{
  int size = 0;

  //option count
  size += 1;

  //ramp count
  size += 1;
  for (int i = 0; i < rampList.length; i++)
  {
    //name
    size += 1;
    //color count
    size += 1;
    //base hue
    size += 2;
    //base sat
    size += 2;
    //hue shift
    size += 1;
    //hue shift exp
    size += 4;
    //sat shift
    size += 1;
    //sat shift exp
    size += 4;
    //val min
    size += 1;
    //val max
    size += 1;
    for (int j = 0; j < rampList[i].settings.colorCount; j++)
    {
      //hue shift
      size += 1;
      //sat shift
      size += 1;
      //val shift
      size += 1;
    }
    //ramp option count
    size += 1;
    //sat curve option type
    size += 1;
    //sat curve option value
    size += 1;
  }

  //link count
  return size += 1;
}
