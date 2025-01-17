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

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';

class StampManagerEntryOptions
{
  final double borderWidth;
  final double borderRadius;
  final int layoutFlex;

  StampManagerEntryOptions({
    required this.borderWidth,
    required this.borderRadius,
    required this.layoutFlex,
  });
}

class StampManagerEntryData
{
  final ui.Image? thumbnail;
  final String path;
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

  StampManagerEntryData({required this.path, required this.thumbnail, required final String name, required this.isLocked}) : _name = name;
}

class StampManagerEntryWidget extends StatefulWidget
{
  final StampManagerEntryData entryData;
  final ValueNotifier<StampManagerEntryWidget?> selectedWidget;
  const StampManagerEntryWidget({super.key, required this.entryData, required this.selectedWidget});

  @override
  State<StampManagerEntryWidget> createState() => _StampManagerEntryWidgetState();
}

class _StampManagerEntryWidgetState extends State<StampManagerEntryWidget>
{
  final StampManagerEntryOptions _options = GetIt.I.get<PreferenceManager>().stampManagerEntryOptions;

  void _onTap()
  {
    widget.selectedWidget.value = widget;
  }

  @override
  Widget build(final BuildContext context)
  {
    return ValueListenableBuilder<StampManagerEntryWidget?>(
      valueListenable: widget.selectedWidget,
      builder: (final BuildContext context, final StampManagerEntryWidget? selectedWidget, final Widget? child) {
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
                  child: RawImage(image: widget.entryData.thumbnail, fit: BoxFit.contain, filterQuality: ui.FilterQuality.none,),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
