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

import 'dart:convert';
import 'dart:typed_data';
import 'package:version/version.dart';

/// Converts a double to a list of bytes.
List<int> intToBytes({required final int value, required final int length, final bool reverse = false})
{
  final ByteData bytes = ByteData(length);
  if (length == 1)
  {
    bytes.setInt8(0, value);
  } else if (length == 2)
  {
    bytes.setInt16(0, value, Endian.little);
  } else if (length == 4)
  {
    bytes.setInt32(0, value, Endian.little);
  }
  else
  {
    throw ArgumentError('Invalid byte length: $length. Supported lengths are 1, 2, or 4 bytes.');
  }

  // Convert to Uint8List and reverse if necessary
  return reverse ? bytes.buffer.asUint8List().reversed.toList() : bytes.buffer.asUint8List();
}

/// Converts a double to a list of bytes.
List<int> float32ToBytes({required final double value, final bool reverse = false})
{
  final ByteData bytes = ByteData(4)..setFloat32(0, value, Endian.little);
  return reverse ? bytes.buffer.asUint8List().reversed.toList() : bytes.buffer.asUint8List();
}

/// Converts a string to a list of bytes.
List<int> stringToBytes({required final String value})
{
  return utf8.encode(value);
}

/// Returns a string with escaped XML characters.
String escapeXml({required final String input})
{
  return input.replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}



/// Returns a string representation of the date and time.
String formatDateTime({required final DateTime dateTime})
{
  final String year = dateTime.year.toString();
  final String month = dateTime.month.toString().padLeft(2, '0'); // Pad with zero if needed
  final String day = dateTime.day.toString().padLeft(2, '0');
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}

/// Converts a string to a version object.
Version? convertStringToVersion({required final String version})
{
  final RegExp versionRegex = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?$');
  final RegExpMatch? match = versionRegex.firstMatch(version);
  if (match != null)
  {
    final List<int> numbers = match.groups(<int>[1, 2, 3, 4])
        .whereType<String>() // Filter out null values
        .map((final String str) => int.parse(str)) // Parse remaining strings to integers
        .toList();
    return Version(numbers[0], numbers[1], numbers[2]);
  }

  else
  {
    return null;
  }
}
