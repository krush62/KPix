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

  void _buttonPressed({required final Alignment alignment})
  {
    final HashMap<Alignment, bool> notificationMap = HashMap<Alignment, bool>();
    for (final Alignment alignment in allAlignments)
    {
      notificationMap[alignment] = selectionMap[alignment] ?? false;
    }

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

  HashMap<Alignment, Widget> _getButtonMap({required final BuildContext context})
  {
    final HashMap<Alignment, Widget> buttonMap = HashMap<Alignment, Widget>();
    for (final Alignment alignment in allAlignments)
    {
      final bool isSelected = selectionMap[alignment] ?? false;
      buttonMap[alignment] = Padding(
        padding:  EdgeInsets.all(padding),
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

  @override
  Widget build(final BuildContext context)
  {
    final HashMap<Alignment, Widget> buttonMap = _getButtonMap(context: context);
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
