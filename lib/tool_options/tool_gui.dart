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

class IconStringData {
  const IconStringData({required this.name, required this.icon});
  final String name;
  final IconData icon;
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
  final Map<E, IconStringData> iconData;
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
                  for (final MapEntry<E, IconStringData> entry in iconData.entries)
                    ButtonSegment<E>(
                      value: entry.key,
                      tooltip: entry.value.name,
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
