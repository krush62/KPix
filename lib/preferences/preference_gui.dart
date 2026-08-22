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


class PrefSliderRow<E extends num> extends StatelessWidget
{
  const PrefSliderRow({
    super.key,
    required this.text,
    required this.notifier,
    this.labelBuilder,
    this.textStyle,
    this.minVal = 0.0,
    this.maxVal = 1.0,
    this.divisions,

  });
  final String text;
  final String Function(E value)? labelBuilder;
  final TextStyle? textStyle;
  final double minVal;
  final double maxVal;
  final int? divisions;
  final ValueNotifier<E> notifier;

  @override
  Widget build(final BuildContext context)
  {
    final TextStyle? titleStyle = textStyle ?? Theme.of(context).textTheme.titleSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(child: Text(text, style: titleStyle)),
        Expanded(
          flex: 2,
          child: ValueListenableBuilder<E>(
            valueListenable: notifier,
            builder: (final BuildContext context, final E val, final Widget? child)
            {
              return KPixSlider(
                value: val.toDouble(),
                min: minVal,
                max: maxVal,
                divisions: divisions,
                label: (labelBuilder ?? (final E v) => v.toString())(val),
                onChanged: (final double newVal) => notifier.value = (E == int ? newVal.round() : newVal) as E,
                textStyle: Theme.of(context).textTheme.bodyLarge!,
              );
            },
          ),
        ),
      ],
    );
  }
}

class PrefSliderRowIndexed extends StatelessWidget
{
  const PrefSliderRowIndexed({
    super.key,
    required this.text,
    required this.notifier,
    required this.valueList,
    this.sliderLabel,
    this.textStyle,
    this.divisions,

  });
  final String text;
  final String? sliderLabel;
  final TextStyle? textStyle;
  final int? divisions;
  final ValueNotifier<int> notifier;
  final List<int> valueList;

  @override
  Widget build(final BuildContext context)
  {
    final TextStyle? titleStyle = textStyle ?? Theme.of(context).textTheme.titleSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(child: Text(text, style: titleStyle)),
        Expanded(
          flex: 2,
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int index, final Widget? child)
            {
              return KPixSlider(
                value: index.toDouble(),
                max: valueList.length.toDouble() - 1.0,
                divisions: divisions,
                label: valueList[index].toString(),
                onChanged: (final double newVal) => notifier.value = newVal.round(),
                textStyle: Theme.of(context).textTheme.bodyLarge!,
              );
            },
          ),
        ),
      ],
    );
  }
}

class PrefSegmentedButtonRow<E> extends StatelessWidget {
  const PrefSegmentedButtonRow({
    super.key,
    required this.label,
    required this.notifier,
    required this.labels,
    this.buttonTextStyle,
    this.labelFlex = 1,
    this.segmentFlex = 2,

  });

  final String label;
  final ValueNotifier<E> notifier;
  final Map<E, String> labels;
  final TextStyle? buttonTextStyle;
  final int labelFlex;
  final int segmentFlex;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          flex: labelFlex,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          flex: segmentFlex,
          child: ValueListenableBuilder<E>(
            valueListenable: notifier,
            builder: (final BuildContext context, final E value, final Widget? child) {
              return SegmentedButton<E>(
                selected: <E>{value},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<E> selection) =>
                notifier.value = selection.first,
                segments: <ButtonSegment<E>>[
                  for (final MapEntry<E, String> entry in labels.entries)
                    ButtonSegment<E>(
                      value: entry.key,
                      label: Text(
                        entry.value,
                        style: buttonTextStyle?.apply(
                          color: value == entry.key
                              ? Theme.of(context).primaryColorDark
                              : Theme.of(context).primaryColorLight,),
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

class PrefSwitchRow extends StatelessWidget {
  const PrefSwitchRow({
    super.key,
    required this.label,
    required this.notifier,
  });

  final String label;
  final ValueNotifier<bool> notifier;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: notifier,
                builder: (final BuildContext context, final bool select, final Widget? child)
                {
                  return Switch(
                    value: select,
                    onChanged: (final bool newVal) => notifier.value = newVal,
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}
