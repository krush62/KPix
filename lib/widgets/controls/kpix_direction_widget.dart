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

import 'dart:collection';

import 'package:flutter/material.dart';

final Set<Alignment> allAlignments = <Alignment>{Alignment.topLeft, Alignment.topCenter, Alignment.topRight, Alignment.centerRight, Alignment.bottomRight, Alignment.bottomCenter, Alignment.bottomLeft, Alignment.centerLeft};

class KPixDirectionWidget extends StatelessWidget
{
  final bool isExclusive;
  final double padding;
  final Function(HashMap<Alignment, bool> directionMap) onChange;
  final HashMap<Alignment, bool> selectionMap;
  const KPixDirectionWidget({super.key, required this.isExclusive, this.padding = 1.0, required this.onChange, required this.selectionMap});


  HashMap<Alignment, bool> _getCopiedMap({required final HashMap<Alignment, bool> inputMap})
  {
    final HashMap<Alignment, bool> outputMap = HashMap<Alignment, bool>();
    for (final Alignment alignment in allAlignments)
    {
      outputMap[alignment] = inputMap[alignment] ?? false;
    }
    return outputMap;
  }

  void _buttonPressed({required final Alignment alignment})
  {
    final HashMap<Alignment, bool> notificationMap = _getCopiedMap(inputMap: selectionMap,);

    if (isExclusive)
    {
      if (!(notificationMap[alignment] ?? false))
      {
        for (final Alignment loopAlignment in notificationMap.keys)
        {
          notificationMap[loopAlignment] = loopAlignment == alignment;
        }
        onChange(notificationMap);
      }
    }
    else
    {
      final int activeDirectionCount = notificationMap.values.where((final bool element) => element == true).length;
      if (activeDirectionCount > 1 || !(notificationMap[alignment] ?? false))
      {
        notificationMap[alignment] = !(notificationMap[alignment] ?? false);
        onChange(notificationMap);
      }
    }
  }

  HashMap<Alignment, Widget> _getButtonMap({required final BuildContext context, required final HashMap<Alignment, bool> dirMap})
  {
    final HashMap<Alignment, Widget> buttonMap = HashMap<Alignment, Widget>();
    for (final Alignment alignment in allAlignments)
    {
      final bool isSelected = dirMap[alignment] ?? false;
      buttonMap[alignment] = Padding(
        padding: EdgeInsets.all(padding),
        child: AspectRatio(
          aspectRatio: 1,
          child: FilledButton(
            style: !isSelected ? Theme.of(context).filledButtonTheme.style!.copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ) : null,
            onPressed: () {_buttonPressed(alignment: alignment);},
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }
    return buttonMap;
  }

  HashMap<Alignment, bool> _getCheckedMap()
  {
    final HashMap<Alignment, bool> checkedMap = _getCopiedMap(inputMap: selectionMap,);

    final Iterable<MapEntry<Alignment, bool>> selectedEntries = checkedMap.entries.where((final MapEntry<Alignment, bool> entry) {
      return entry.value == true;
    });
    if (selectedEntries.isEmpty)
    {
      checkedMap[Alignment.bottomRight] = true;
    }
    else if (isExclusive && selectedEntries.length > 1)
    {
      for (final MapEntry<Alignment, bool> entry in selectedEntries)
      {
        checkedMap[entry.key] = false;
        checkedMap[Alignment.bottomRight] = true;
      }
    }
    return checkedMap;
  }

  @override
  Widget build(final BuildContext context)
  {
    final HashMap<Alignment, bool> checkedMap = _getCheckedMap();
    final HashMap<Alignment, Widget> buttonMap = _getButtonMap(context: context, dirMap: checkedMap);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buttonMap[Alignment.topLeft]!,
              buttonMap[Alignment.centerLeft]!,
              buttonMap[Alignment.bottomLeft]!,
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buttonMap[Alignment.topCenter]!,
              const AspectRatio(
                aspectRatio: 1,
                child: SizedBox.shrink(),
              ),
              buttonMap[Alignment.bottomCenter]!,
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buttonMap[Alignment.topRight]!,
              buttonMap[Alignment.centerRight]!,
              buttonMap[Alignment.bottomRight]!,
            ],
          ),
        ),
      ],
    );
  }
}
