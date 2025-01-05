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

class KPixDirectionWidget extends StatefulWidget
{
  final bool isExclusive;
  final double padding;
  final Function(Set<Alignment> directions)? onChange;
  final HashMap<Alignment, ValueNotifier<bool>> selectionMap;
  const KPixDirectionWidget({super.key, required this.isExclusive, this.padding = 1.0, this.onChange, required this.selectionMap});

  @override
  State<KPixDirectionWidget> createState() => _KPixDirectionWidgetState();
}

class _KPixDirectionWidgetState extends State<KPixDirectionWidget>
{


  final HashMap<Alignment, Widget> _buttonMap = HashMap<Alignment, Widget>();


  void _notify()
  {
    if (widget.onChange != null)
    {
      final Set<Alignment> activeAlignments = <Alignment>{};
      for (final MapEntry<Alignment, ValueNotifier<bool>> entry in widget.selectionMap.entries)
      {
        if (entry.value.value)
        {
          activeAlignments.add(entry.key);
        }
      }
      widget.onChange!(activeAlignments);
    }
  }

  void _buttonPressed({required final Alignment alignment})
  {
    if (widget.isExclusive)
    {
      if (!widget.selectionMap[alignment]!.value)
      {
        for (final Alignment loopAlignment in widget.selectionMap.keys)
        {
          widget.selectionMap[loopAlignment]!.value = loopAlignment == alignment;
        }
        _notify();
      }
    }
    else
    {
      final int activeDirectionCount = widget.selectionMap.values.where((final ValueNotifier<bool> element) => element.value == true).length;
      if (activeDirectionCount > 1 || !widget.selectionMap[alignment]!.value)
      {
        widget.selectionMap[alignment]!.value = !widget.selectionMap[alignment]!.value;
        _notify();
      }
    }
  }

  @override
  void initState()
  {
    super.initState();
    for (final Alignment alignment in allAlignments)
    {
      _buttonMap[alignment] = Padding(
        padding:  EdgeInsets.all(widget.padding),
        child: AspectRatio(
          aspectRatio: 1,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.selectionMap[alignment]!,
            builder: (final BuildContext context, final bool isSelected, final Widget? child)
            {
              return FilledButton(
                style: !isSelected ? Theme.of(context).filledButtonTheme.style!.copyWith(backgroundColor: WidgetStateProperty.all(Theme.of(context).primaryColorDark), tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero)) : null,
                onPressed: () {_buttonPressed(alignment: alignment);},
                child: const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
    }
  }


  @override
  Widget build(final BuildContext context)
  {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buttonMap[Alignment.topLeft]!,
              _buttonMap[Alignment.centerLeft]!,
              _buttonMap[Alignment.bottomLeft]!,
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buttonMap[Alignment.topCenter]!,
              const AspectRatio(
                aspectRatio: 1,
                child: SizedBox.shrink(),
              ),
              _buttonMap[Alignment.bottomCenter]!,
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buttonMap[Alignment.topRight]!,
              _buttonMap[Alignment.centerRight]!,
              _buttonMap[Alignment.bottomRight]!,
            ],
          ),
        ),
      ],
    );
  }
}
