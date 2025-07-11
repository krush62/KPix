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
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_number_picker_widget.dart';

const int _minFrameTime = 1;
const int _maxFrameTime = 60;

class FrameTimeWidget extends StatefulWidget
{
  final Frame frame;
  final ValueNotifier<int> valueNotifier;
  final Function()? onDismiss;
  final Function({required Frame frame, required int value})? onConfirmSingle;
  final Function({required int value})? onConfirmAll;
  FrameTimeWidget({super.key, required this.frame, this.onDismiss, this.onConfirmSingle, this.onConfirmAll}) : valueNotifier = ValueNotifier<int>(frame.fps.value)
  {
    assert(valueNotifier.value >= _minFrameTime && valueNotifier.value <= _maxFrameTime);
  }


  @override
  State<FrameTimeWidget> createState() => _FrameTimeWidgetState();
}

class _FrameTimeWidgetState extends State<FrameTimeWidget>
{
  static const double _padding = 8.0;
  static const double _width = 400.0;
  static const double _height = 240.0;

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: const BoxConstraints(maxWidth: _width, maxHeight: _height),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(child: OutlinedButton(onPressed: () {widget.valueNotifier.value = 6;}, child: const Text("6 fps"))),
                const SizedBox(width: _padding,),
                Expanded(child: OutlinedButton(onPressed: () {widget.valueNotifier.value = 10;}, child: const Text("10 fps"))),
                const SizedBox(width: _padding,),
                Expanded(child: OutlinedButton(onPressed: () {widget.valueNotifier.value = 12;}, child: const Text("12 fps"))),
                const SizedBox(width: _padding,),
                Expanded(child: OutlinedButton(onPressed: () {widget.valueNotifier.value = 16;}, child: const Text("16 fps"))),
                const SizedBox(width: _padding,),
                Expanded(child: OutlinedButton(onPressed: () {widget.valueNotifier.value = 24;}, child: const Text("24 fps"))),
                const SizedBox(width: _padding,),
                Expanded(child: OutlinedButton(onPressed: () {widget.valueNotifier.value = 30;}, child: const Text("30 fps"))),
              ],
            ),
            const SizedBox(height: _padding,),
            ValueListenableBuilder<int>(
              valueListenable: widget.valueNotifier,
              builder: (final BuildContext context, final int value, final Widget? child) {
                final double msValue = 1000.0 / value.toDouble();
                return Row(
                  children: <Widget>[
                    KPixNumberPickerWidget(
                      value: value,
                      minValue: _minFrameTime,
                      maxValue: _maxFrameTime,
                      onValueChanged: (final int newValue) {
                        widget.valueNotifier.value = newValue;
                      },
                    ),
                    Text(" fps (${msValue.toStringAsFixed(2)} ms)", style: Theme.of(context).textTheme.titleLarge,),
                  ],
                );
              },
            ),
            const SizedBox(height: _padding,),
            Row(
              children: <Widget>[
                Expanded(child: IconButton(onPressed: () {widget.onDismiss?.call();}, icon: const Icon(FontAwesomeIcons.xmark),)),
                const SizedBox(width: _padding,),
                Expanded(child: IconButton(onPressed: () {widget.onConfirmAll?.call(value: widget.valueNotifier.value);}, icon: const Icon(FontAwesomeIcons.checkDouble))),
                const SizedBox(width: _padding,),
                Expanded(child: IconButton(onPressed: () {widget.onConfirmSingle?.call(frame: widget.frame, value: widget.valueNotifier.value);}, icon: const Icon(FontAwesomeIcons.check))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
