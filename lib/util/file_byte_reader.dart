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

import 'dart:typed_data';

class FileByteReader {
  FileByteReader(final Uint8List dataList) : data = ByteData.sublistView(dataList);

  final ByteData data;
  int _offset = 0;

  int get offset => _offset;

  int getUint32([final Endian endian = Endian.big])
  {
    final int val = data.getUint32(_offset, endian);
    _offset+=4;
    return val;
  }

  int getInt32([final Endian endian = Endian.big])
  {
    final int val = data.getInt32(_offset, endian);
    _offset+=4;
    return val;
  }

  int getUint16([final Endian endian = Endian.big])
  {
    final int val = data.getUint16(_offset, endian);
    _offset+=2;
    return val;
  }

  int getInt16([final Endian endian = Endian.big])
  {
    final int val = data.getInt16(_offset, endian);
    _offset+=2;
    return val;
  }

  int getUint8()
  {
    final int val = data.getUint8(_offset);
    _offset+=1;
    return val;
  }

  int getInt8()
  {
    final int val = data.getInt8(_offset);
    _offset+=1;
    return val;
  }

  double getFloat32([final Endian endian = Endian.big])
  {
    final double val = data.getFloat32(_offset, endian);
    _offset+=4;
    return val;
  }

  void moveOffset(final int amount)
  {
    _offset += amount;
  }


}
