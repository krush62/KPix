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

import 'package:flutter/material.dart';
import 'package:kpix/preferences/preference_gui.dart';
import 'package:kpix/preferences/preference_values.dart';

class DesktopPreferences extends StatefulWidget
{
  final DesktopPreferenceContent prefs;
  const DesktopPreferences({super.key, required this.prefs});

  @override
  State<DesktopPreferences> createState() => _DesktopPreferencesState();
}

class _DesktopPreferencesState extends State<DesktopPreferences>
{
  @override
  Widget build(final BuildContext context)
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PrefSegmentedButtonRow<CursorType>(
          label: "Mouse Cursor",
          notifier: widget.prefs.cursorType,
          labels: CursorType.getNameMap(),
        ),
      ],
    );
  }
}
