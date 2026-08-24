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
import 'package:flutter/services.dart';
import 'package:kpix/preferences/preference_gui.dart';

enum CursorType
{
  none(0, "None", SystemMouseCursors.none),
  crossHair(1, "CrossHair", SystemMouseCursors.precise),
  arrow(2, "Arrow", SystemMouseCursors.basic);

  final int id;
  final String name;
  final SystemMouseCursor systemCursor;

  const CursorType(this.id, this.name, this.systemCursor);

  static Map<CursorType, String> getNameMap()
  {
    final Map<CursorType, String> map = <CursorType, String>{};
    for (final CursorType curs in CursorType.values) {
      map[curs] = curs.name;
    }
    return map;
  }

  static CursorType fromId(final int id) {
    return CursorType.values.firstWhere((final CursorType curs) => curs.id == id);
  }

}

class DesktopPreferenceContent
{
  final ValueNotifier<CursorType> cursorType;
  factory DesktopPreferenceContent({required final int cursorTypeValue})
  {
    final CursorType cursorType = CursorType.fromId(cursorTypeValue);
    return DesktopPreferenceContent._(cursorType: ValueNotifier<CursorType>(cursorType));
  }

  DesktopPreferenceContent._({required this.cursorType});
  void update({required final int cursorTypeValue})
  {
    cursorType.value = CursorType.fromId(cursorTypeValue);
  }
}

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
