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

import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/color_types.dart';

/// What the manager knows about a saved palette on disk.
class PaletteManagerEntryData
{
  final List<KPalRampData> rampDataList;
  final String? path;
  final bool isLocked;
  final String _name;

  /// The name to show, bracketed while the palette cannot be edited.
  ///
  /// The built-in palette has no file behind it, so its name comes from the
  /// localizations instead of being stored.
  String displayName({required final AppLocalizations l10n})
  {
    final String baseName = path == null ? l10n.defaultPalette : _name;
    if (isLocked)
    {
      return "[$baseName]";
    }
    else
    {
      return baseName;
    }
  }

  PaletteManagerEntryData({required this.rampDataList, required final String name, required this.isLocked, required this.path}) : _name = name;
}
