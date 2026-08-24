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
import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/color_helper.dart';

abstract final class _PaletteManagerEntryOptions
{
  static const double borderWidth = 2.0;
  static const double borderRadius = 3.0;
  static const int layoutFlex = 6;
}

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


class PaletteManagerEntryWidget extends StatefulWidget
{
  final PaletteManagerEntryData entryData;
  final ValueNotifier<PaletteManagerEntryWidget?> selectedWidget;
  const PaletteManagerEntryWidget({super.key, required this.entryData, required this.selectedWidget});



  @override
  State<PaletteManagerEntryWidget> createState() => _PaletteManagerEntryWidgetState();
}

class _PaletteManagerEntryWidgetState extends State<PaletteManagerEntryWidget>
{

  void _onTap()
  {
    widget.selectedWidget.value = widget;
  }

  @override
  Widget build(final BuildContext context)
  {
    final List<Widget> colorColumn = <Widget>[];
    int colorCount = 0;
    for (final KPalRampData rampData in widget.entryData.rampDataList)
    {
      final List<Widget> colorRowWidgetList = <Widget>[];
      for (final ValueNotifier<IdColor> idColor in rampData.shiftedColors)
      {
        colorRowWidgetList.add(Expanded(child: ColoredBox(color: idColor.value.color)));
        colorCount++;
      }
      colorColumn.add(Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: colorRowWidgetList)));
    }

    return ValueListenableBuilder<PaletteManagerEntryWidget?>(
      valueListenable: widget.selectedWidget,
      builder: (final BuildContext context, final PaletteManagerEntryWidget? selectedWidget, final Widget? child) {
        final bool isSelected = (selectedWidget == widget);
        return GestureDetector(
          onTap: _onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                width: _PaletteManagerEntryOptions.borderWidth,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(_PaletteManagerEntryOptions.borderRadius)),
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: Text(
                      widget.entryData.name,
                      style: Theme.of(context).textTheme.titleSmall!.apply(color: Theme.of(context).primaryColorLight),
                    ),
                  ),
                ),
                Expanded(
                  flex: _PaletteManagerEntryOptions.layoutFlex,
                  child: Padding(
                    padding: const EdgeInsets.all(_PaletteManagerEntryOptions.borderWidth),
                    child: Column(
                      children: colorColumn,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.entryData.rampDataList.length == 1 ? "$colorCount colors" : "${widget.entryData.rampDataList.length} ramps | $colorCount colors",
                      style: Theme.of(context).textTheme.bodySmall!.apply(color: Theme.of(context).primaryColorLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
