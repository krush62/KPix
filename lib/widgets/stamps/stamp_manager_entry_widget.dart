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
import 'package:kpix/models/stamp_manager_data.dart';

abstract final class _StampManagerEntryOptions
{
  static const double borderWidth = 2.0;
  static const double borderRadius = 3.0;
  static const int layoutFlex = 6;
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
                width: _StampManagerEntryOptions.borderWidth,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(_StampManagerEntryOptions.borderRadius)),
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
                  flex: _StampManagerEntryOptions.layoutFlex,
                  child: Padding(
                    padding: const EdgeInsets.all(_StampManagerEntryOptions.borderWidth),
                    child: RawImage(image: widget.entryData.thumbnail, fit: BoxFit.contain, filterQuality: ui.FilterQuality.none,),
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
