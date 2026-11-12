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

import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/widgets/controls/kpix_dropdown.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:material_ui/material_ui.dart';

/// The reset button next to a preference slider, styled like the ones in the shader export.
class _PrefResetButton extends StatelessWidget
{
  static const double size = 32.0;
  static const double padding = 8.0;
  final VoidCallback? onPressed;
  const _PrefResetButton({required this.onPressed});

  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.only(left: padding),
      child: IconButton.outlined(
        tooltip: AppLocalizations.of(context)!.resetValue,
        icon: const Icon(TablerIcons.refresh),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(size, size),
          maximumSize: const Size(size, size),
          iconSize: size - padding,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class PrefSliderRow<E extends num> extends StatelessWidget
{
  const PrefSliderRow({
    super.key,
    required this.text,
    required this.notifier,
    required this.defaultValue,
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
  final E defaultValue;

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
              // Discrete double sliders can land a rounding error away from the default.
              final bool isDefault = (val - defaultValue).abs() < 1e-9;
              return Row(
                children: <Widget>[
                  Expanded(
                    child: KPixSlider(
                      value: val.toDouble(),
                      min: minVal,
                      max: maxVal,
                      divisions: divisions,
                      label: (labelBuilder ?? (final E v) => v.toString())(val),
                      onChanged: (final double newVal) => notifier.value = (E == int ? newVal.round() : newVal) as E,
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    ),
                  ),
                  _PrefResetButton(onPressed: isDefault ? null : () {notifier.value = defaultValue;}),
                ],
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
    required this.defaultIndex,
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
  final int defaultIndex;

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
              return Row(
                children: <Widget>[
                  Expanded(
                    child: KPixSlider(
                      value: index.toDouble(),
                      max: valueList.length.toDouble() - 1.0,
                      divisions: divisions,
                      label: valueList[index].toString(),
                      onChanged: (final double newVal) => notifier.value = newVal.round(),
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    ),
                  ),
                  _PrefResetButton(onPressed: index == defaultIndex ? null : () {notifier.value = defaultIndex;}),
                ],
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
    this.isEnabled = true,
  });

  final String label;
  final bool isEnabled;
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
                    onChanged: isEnabled ? (final bool newVal) => notifier.value = newVal : null,
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

/// A labelled dropdown, styled like the dropdowns in the tool settings.
class PrefDropdownRow<E> extends StatelessWidget {
  const PrefDropdownRow({
    super.key,
    required this.label,
    required this.notifier,
    required this.valueMap,
    this.labelFlex = 1,
    this.dropdownFlex = 2,
  });

  final String label;
  final ValueNotifier<E> notifier;
  final Map<E, String> valueMap;
  final int labelFlex;
  final int dropdownFlex;

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
          flex: dropdownFlex,
          child: ValueListenableBuilder<E>(
            valueListenable: notifier,
            builder: (final BuildContext context, final E val, final Widget? child)
            {
              return KPixDropdown<E>(
                value: val,
                valueMap: valueMap,
                onChanged: (final E newVal) {notifier.value = newVal;},
              );
            },
          ),
        ),
      ],
    );
  }
}
