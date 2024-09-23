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
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class PaletteManagerEntryData
{
  final List<KPalRampData> rampDataList;
  final bool isLocked;
  final String name;
  PaletteManagerEntryData({required this.rampDataList, required this.name, required this.isLocked});
}


class PaletteManagerEntryWidget extends StatelessWidget
{
  final PaletteManagerEntryData entryData;
  const PaletteManagerEntryWidget({super.key, required this.entryData});

  @override
  Widget build(BuildContext context)
  {
    final List<Widget> colorColumn = [];
    colorColumn.add(Text(entryData.name));
    for (final KPalRampData rampData in entryData.rampDataList)
    {
      final List<Widget> colorRowWidgetList = [];
      for (final ValueNotifier<IdColor> idColor in rampData.colors)
      {
        colorRowWidgetList.add(ColoredBox(color: idColor.value.color));
      }
      colorColumn.add(Row(children: colorRowWidgetList));
    }

    return Container(
      child: Column(
        children: colorColumn,
      )
    );
  }
}
