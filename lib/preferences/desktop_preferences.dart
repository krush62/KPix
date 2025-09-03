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

enum CursorType
{
  none,
  crossHair,
  arrow
}

const Map<int, CursorType> cursorTypeIndexMap =
<int, CursorType>{
  0:CursorType.none,
  1:CursorType.crossHair,
  2:CursorType.arrow,
};

const Map<CursorType, String> cursorTypeStringMap =
<CursorType, String>{
  CursorType.none: "None",
  CursorType.crossHair: "CrossHair",
  CursorType.arrow: "Arrow",
};

const Map<CursorType, SystemMouseCursor> cursorTypeCursorMap =
<CursorType, SystemMouseCursor>{
  CursorType.none: SystemMouseCursors.none,
  CursorType.crossHair: SystemMouseCursors.precise,
  CursorType.arrow: SystemMouseCursors.basic,
};

class DesktopPreferenceContent
{
  final ValueNotifier<CursorType> cursorType;
  factory DesktopPreferenceContent({required final int cursorTypeValue})
  {
    final CursorType cursorType = cursorTypeIndexMap[cursorTypeValue]?? CursorType.crossHair;
    return DesktopPreferenceContent._(cursorType: ValueNotifier<CursorType>(cursorType));
  }

  DesktopPreferenceContent._({required this.cursorType});
  void update({required final int cursorTypeValue})
  {
    cursorType.value = cursorTypeIndexMap[cursorTypeValue]?? CursorType.crossHair;
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Text("Mouse Cursor", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<CursorType>(
                valueListenable: widget.prefs.cursorType,
                builder: (final BuildContext context, final CursorType cursor, final Widget? child)
                {
                  return SegmentedButton<CursorType>(
                    selected: <CursorType>{cursor},
                    showSelectedIcon: false,
                    onSelectionChanged: (final Set<CursorType> cursorList) {widget.prefs.cursorType.value = cursorList.first;},
                    segments: <ButtonSegment<CursorType>>[
                      ButtonSegment<CursorType>(
                        value: CursorType.none,
                        label: Text(cursorTypeStringMap[CursorType.none]!),
                      ),
                      ButtonSegment<CursorType>(
                        value: CursorType.crossHair,
                        label: Text(cursorTypeStringMap[CursorType.crossHair]!),
                      ),
                      ButtonSegment<CursorType>(
                        value: CursorType.arrow,
                        label: Text(cursorTypeStringMap[CursorType.arrow]!),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
