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

import 'package:kpix/models/color_types.dart';

/// What the manager knows about a saved palette on disk.
class PaletteManagerEntryData
{
  final List<KPalRampData> rampDataList;
  final String? path;
  final bool isLocked;
  final String _name;

  String get name
  {
    if (isLocked)
    {
      return "[$_name]";
    }
    else
    {
      return _name;
    }
  }

  PaletteManagerEntryData({required this.rampDataList, required final String name, required this.isLocked, required this.path}) : _name = name;
}
