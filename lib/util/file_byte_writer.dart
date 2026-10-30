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

import 'dart:math';
import 'dart:typed_data';

/// Appends values to a buffer that grows as needed; the counterpart of FileByteReader.
class FileByteWriter {
  FileByteWriter([final int initialCapacity = 1024]) : _bytes = Uint8List(initialCapacity);

  Uint8List _bytes;
  late ByteData _data = ByteData.sublistView(_bytes);
  int _length = 0;

  int get length => _length;

  /// What was written so far, as a view on the buffer.
  Uint8List get bytes => Uint8List.sublistView(_bytes, 0, _length);

  void _reserve(final int count)
  {
    if (_length + count > _bytes.length)
    {
      final Uint8List grown = Uint8List(max(_bytes.length * 2, _length + count));
      grown.setRange(0, _length, _bytes);
      _bytes = grown;
      _data = ByteData.sublistView(grown);
    }
  }

  void setUint32(final int value, [final Endian endian = Endian.big])
  {
    _reserve(4);
    _data.setUint32(_length, value, endian);
    _length+=4;
  }

  void setUint16(final int value, [final Endian endian = Endian.big])
  {
    _reserve(2);
    _data.setUint16(_length, value, endian);
    _length+=2;
  }

  void setUint8(final int value)
  {
    _reserve(1);
    _data.setUint8(_length, value);
    _length+=1;
  }

  void setInt8(final int value)
  {
    _reserve(1);
    _data.setInt8(_length, value);
    _length+=1;
  }

  void setFloat32(final double value, [final Endian endian = Endian.big])
  {
    _reserve(4);
    _data.setFloat32(_length, value, endian);
    _length+=4;
  }

  void setBytes(final List<int> values)
  {
    _reserve(values.length);
    _bytes.setRange(_length, _length + values.length, values);
    _length+=values.length;
  }
}
