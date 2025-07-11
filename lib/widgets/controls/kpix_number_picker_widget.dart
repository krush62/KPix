/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class KPixNumberPickerWidget extends StatefulWidget {
  final Function(int newValue)? onValueChanged;
  final ValueNotifier<int> valueNotifier;
  final int maxValue;
  final int minValue;
  KPixNumberPickerWidget({super.key, final int value = 0, this.minValue = 0, this.maxValue = 9, this.onValueChanged}) : valueNotifier = ValueNotifier<int>(value)
  {
    valueNotifier.addListener(() {
      onValueChanged?.call(valueNotifier.value);
    });
  }

  @override
  State<KPixNumberPickerWidget> createState() => _KPixNumberPickerWidgetState();
}

class _KPixNumberPickerWidgetState extends State<KPixNumberPickerWidget> {
  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: widget.valueNotifier,
            builder: (final BuildContext context, final int value, final Widget? child) {
              return IconButton(
                onPressed: widget.valueNotifier.value < widget.maxValue ? () {
                  widget.valueNotifier.value++;
                } : null,
                icon: const Icon(FontAwesomeIcons.chevronUp),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: widget.valueNotifier,
            builder: (final BuildContext context, final int value, final Widget? child) {
              return Text(value.toString(), style: Theme.of(context).textTheme.titleLarge);
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: widget.valueNotifier,
            builder: (final BuildContext context, final int value, final Widget? child) {
              return IconButton(
                onPressed: (widget.valueNotifier.value > widget.minValue) ? () {
                  widget.valueNotifier.value--;
                } : null,
                icon: const Icon(FontAwesomeIcons.chevronDown)
              );
            },
          ),
        ],
      ),
    );
  }
}
