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

class GradientSliderTrackShape extends SliderTrackShape
{
  const GradientSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {

    final double horizontalPadding = 24.0;
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx + horizontalPadding;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - (2 * horizontalPadding);
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
      PaintingContext context,
      ui.Offset offset,
      {
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required Animation<double> enableAnimation,
        required ui.Offset thumbCenter,
        ui.Offset? secondaryOffset,
        bool isEnabled = false,
        bool isDiscrete = false,
        required ui.TextDirection textDirection}) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    final Radius cornerRadius = Radius.circular(trackRect.height / 2);
    final RRect roundedRect = RRect.fromRectAndRadius(trackRect, cornerRadius);

    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: List.generate(361, (hue) => HSVColor.fromAHSV(1, hue.toDouble(), 1, 1).toColor()),
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(trackRect);

    context.canvas.drawRRect(roundedRect, paint);
  }
}