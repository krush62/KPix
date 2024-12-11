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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class PaletteManagerEntryOptions
{
  final double borderWidth;
  final double borderRadius;
  final int layoutFlex;

  PaletteManagerEntryOptions({
    required this.borderWidth,
    required this.borderRadius,
    required this.layoutFlex,
  });
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
  final PaletteManagerEntryOptions _options = GetIt.I.get<PreferenceManager>().paletteManagerEntryOptions;

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
                width: _options.borderWidth,
              ),
              borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
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
                  flex: _options.layoutFlex,
                  child: Column(
                    children: colorColumn,
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
