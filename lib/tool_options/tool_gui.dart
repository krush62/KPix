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
import 'package:kpix/widgets/controls/kpix_slider.dart';

class ToolSwitchRow extends StatelessWidget
{
  const ToolSwitchRow({
    super.key,
    required this.notifier,
    required this.label,
    this.flex = 1,
  });

  final int flex;
  final String label;
  final ValueNotifier<bool> notifier;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          flex: flex,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ValueListenableBuilder<bool>(
              valueListenable: notifier,
              builder: (final BuildContext context, final bool value, final Widget? child)
              {
                return Switch(
                  onChanged: (final bool newVal) {notifier.value = newVal;},
                  value: value,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ToolModifierSwitchRow extends StatefulWidget
{
  const ToolModifierSwitchRow({
    super.key,
    required this.notifier,
    required this.unmodifiedNotifier,
    required this.label,
    required this.defaultState,
    required this.modifierNotifier,
    this.flex = 1,
  });

  final int flex;
  final String label;
  final bool defaultState;
  final ValueNotifier<bool> notifier;
  final ValueNotifier<bool> unmodifiedNotifier;
  final ValueNotifier<bool> modifierNotifier;

  @override
  State<ToolModifierSwitchRow> createState() => _ToolModifierSwitchRowState();
}

class _ToolModifierSwitchRowState extends State<ToolModifierSwitchRow>
{
  @override
  void initState()
  {
    super.initState();
    _addListeners(widget);
    //the initial sync has to be deferred because this runs during the build phase
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (mounted)
      {
        _syncNotifier();
      }
    });
  }

  @override
  void didUpdateWidget(final ToolModifierSwitchRow oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modifierNotifier != widget.modifierNotifier || oldWidget.unmodifiedNotifier != widget.unmodifiedNotifier)
    {
      _removeListeners(oldWidget);
      _addListeners(widget);
    }
  }

  @override
  void dispose()
  {
    _removeListeners(widget);
    super.dispose();
  }

  void _addListeners(final ToolModifierSwitchRow w)
  {
    w.modifierNotifier.addListener(_syncNotifier);
    w.unmodifiedNotifier.addListener(_syncNotifier);
  }

  void _removeListeners(final ToolModifierSwitchRow w)
  {
    w.modifierNotifier.removeListener(_syncNotifier);
    w.unmodifiedNotifier.removeListener(_syncNotifier);
  }

  void _syncNotifier()
  {
    final bool newMode = widget.modifierNotifier.value ? !widget.defaultState : widget.unmodifiedNotifier.value;
    widget.notifier.value = newMode;
  }

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          flex: widget.flex,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.notifier,
              builder: (final BuildContext context, final bool value, final Widget? child)
              {
                return Switch(
                  onChanged: (final bool newVal) {
                    if (!widget.modifierNotifier.value)
                    {
                      widget.unmodifiedNotifier.value = newVal;
                    }
                    widget.notifier.value = newVal;
                  },
                  value: value,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ToolSliderRow<E extends num> extends StatelessWidget
{
  const ToolSliderRow({
    super.key,
    required this.label,
    required this.notifier,
    this.labelBuilder,
    this.textStyle,
    this.minVal = 0.0,
    this.maxVal = 1.0,
    this.divisions,
    this.flex = 1,
  });
  final String label;
  final String Function(E value)? labelBuilder;
  final TextStyle? textStyle;
  final double minVal;
  final double maxVal;
  final int? divisions;
  final ValueNotifier<E> notifier;
  final int flex;

  @override
  Widget build(final BuildContext context)
  {
    final TextStyle? titleStyle = textStyle ?? Theme.of(context).textTheme.labelLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: titleStyle,
            ),
          ),
        ),
        Expanded(
          flex: flex,
          child: ValueListenableBuilder<E>(
            valueListenable: notifier,
            builder: (final BuildContext context, final E val, final Widget? child)
            {
              return KPixSlider(
                value: val.toDouble(),
                min: minVal,
                max: maxVal,
                textStyle: Theme.of(context).textTheme.bodyLarge!,
                label: (labelBuilder ?? (final E v) => v.toString())(val),
                divisions: divisions,
                onChanged: (final double newVal) => notifier.value = (E == int ? newVal.round() : newVal) as E,
              );
            },
          ),
        ),
      ],
    );
  }
}

class ToolDropdownRow<E> extends StatelessWidget
{
  const ToolDropdownRow({
    super.key,
    required this.label,
    required this.notifier,
    required this.valueMap,
    this.flex = 1,
  });

  final String label;
  final int flex;
  final ValueNotifier<E> notifier;
  final Map<E, String> valueMap;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          flex: flex,
          child: ValueListenableBuilder<E>(
            valueListenable: notifier,
            builder: (final BuildContext context, final E val, final Widget? child)
            {
              return DropdownButton<E>(
                value: val,
                dropdownColor: Theme.of(context).primaryColorDark,
                focusColor: Theme.of(context).primaryColor,
                isExpanded: true,
                onChanged: (final E? newVal) {if (newVal != null) notifier.value = newVal;},
                items: valueMap.keys.map<DropdownMenuItem<E>>((final E entry) {
                  return DropdownMenuItem<E>(
                    value: entry,
                    child: Text(valueMap[entry]!),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ToolSegmentedIconButtonRow<E> extends StatelessWidget {
  const ToolSegmentedIconButtonRow({
    super.key,
    required this.label,
    required this.notifier,
    required this.iconData,
    this.flex = 2,
    this.iconSize = 8,
    this.hideLabel = false,
  });

  final String label;
  final ValueNotifier<E> notifier;
  final Map<E, ({String label, IconData icon})> iconData;
  final int flex;
  final double iconSize;
  final bool hideLabel;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Visibility(
          visible: !hideLabel,
          child: Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
        Expanded(
          flex: flex,
          child: ValueListenableBuilder<E>(
            valueListenable: notifier,
            builder: (final BuildContext context, final E value, final Widget? child) {
              return SegmentedButton<E>(
                selected: <E>{value},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<E> selection) =>
                notifier.value = selection.first,
                segments: <ButtonSegment<E>>[
                  for (final MapEntry<E, ({String label, IconData icon})> entry in iconData.entries)
                    ButtonSegment<E>(
                      value: entry.key,
                      tooltip: entry.value.label,
                      label: Icon(
                        entry.value.icon,
                        size: iconSize,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
