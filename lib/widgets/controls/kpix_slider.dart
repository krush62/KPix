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

class KPixSlider extends StatelessWidget
{
  final double value;
  final ValueChanged<double>? onChanged;
  final double trackHeight;
  final double fontStrokeWidth;
  final Color? activeTrackColor;
  final Color? inActiveTrackColor;
  final Color? borderColor;
  final Color? disabledColor;
  final int decimals;
  final int? divisions;
  final double borderRadius;
  final double borderWidth;
  final double min;
  final double max;
  final TextStyle textStyle;
  final double topBottomPadding;
  final String? label;
  final bool isRainbow;

  const KPixSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.trackHeight = 24.0,
    this.fontStrokeWidth = 3,
    this.decimals = 0,
    this.divisions,
    this.activeTrackColor,
    this.inActiveTrackColor,
    this.disabledColor,
    this.borderColor,
    this.borderRadius = 8.0,
    this.borderWidth = 1.0,
    this.min = 0.0,
    this.max = 1.0,
    required this.textStyle,
    this.topBottomPadding = 8.0,
    this.label,
    this.isRainbow = false

  });

  @override
  Widget build(BuildContext context)
  {
    final Color fgColor = activeTrackColor ?? Theme.of(context).primaryColorLight;
    final Color bgColor = inActiveTrackColor ?? Theme.of(context).primaryColor;
    final Color disColor = disabledColor ?? Theme.of(context).primaryColorDark;
    final Color bColor = borderColor ?? Theme.of(context).primaryColorLight;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: topBottomPadding),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: trackHeight,
          thumbShape: !isRainbow ? const _InvisibleSliderThumbShape() : _KPixSliderThumbShape(padding: borderRadius / 2),
          trackShape: _KPixSliderTrackShape(borderRadius: borderRadius, strokeColor: bColor, strokeWidth: borderWidth, isRainbow: isRainbow),
          activeTrackColor: fgColor,
          inactiveTrackColor: bgColor,
          overlayShape: SliderComponentShape.noOverlay,
          tickMarkShape: SliderTickMarkShape.noTickMark,
          disabledActiveTrackColor: disColor
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              divisions: divisions,
            ),
            !isRainbow ? Positioned.fill(
              child: Center(
                child: IgnorePointer(
                  ignoring: true,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        label ?? value.toStringAsFixed(decimals),
                        style: TextStyle(
                          fontSize: textStyle.fontSize,
                          fontFamily: textStyle.fontFamily,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = fontStrokeWidth
                            ..color = bgColor,
                        ),
                      ),
                      Text(
                        label ?? value.toStringAsFixed(decimals),
                        style: TextStyle(
                          fontSize: textStyle.fontSize,
                          fontFamily: textStyle.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: onChanged != null ? fgColor : disColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ) : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _KPixSliderThumbShape extends RoundSliderThumbShape
{
  final double padding;
  const _KPixSliderThumbShape({
    this.padding = 4.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(PaintingContext context, Offset center, {required Animation<double> activationAnimation, required Animation<double> enableAnimation, required bool isDiscrete, required TextPainter labelPainter, required RenderBox parentBox, required SliderThemeData sliderTheme, required TextDirection textDirection, required double value, required double textScaleFactor, required Size sizeWithOverflow}) {

    Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    context.canvas.drawCircle(center, parentBox.size.height / 2 - padding, activePaint);
    context.canvas.drawCircle(center, parentBox.size.height / 2 - padding, inactivePaint);

  }


}

class _InvisibleSliderThumbShape extends SliderComponentShape {
  const _InvisibleSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    // No thumb painting
  }
}

class _KPixSliderTrackShape extends RoundedRectSliderTrackShape {
  final double borderRadius;
  final double strokeWidth;
  final Color strokeColor;
  final bool isRainbow;

  const _KPixSliderTrackShape({
    this.borderRadius = 4.0,
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.black,
    this.isRainbow = false
  });


  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        double additionalActiveTrackHeight = 0,
        required Animation<double> enableAnimation,
        bool isDiscrete = false,
        bool isEnabled = true,
        required RenderBox parentBox,
        Offset? secondaryOffset,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required Offset thumbCenter,
      }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint outlinePaint = Paint()
      ..color = isEnabled ? strokeColor : sliderTheme.disabledActiveTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

      Paint activePaint = Paint()
        ..color = isEnabled ? sliderTheme.activeTrackColor! : sliderTheme.disabledActiveTrackColor!
        ..style = PaintingStyle.fill;

      if (isRainbow)
      {
        activePaint = Paint()
          ..shader = LinearGradient(
            colors: List.generate(360, (hue) => HSVColor.fromAHSV(1, hue.toDouble(), 0.5, 0.7).toColor()),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(trackRect);
      }

      final Rect activeTrack = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      );



      context.canvas.drawRRect(
        RRect.fromRectAndRadius(isRainbow ? trackRect : activeTrack, Radius.circular(borderRadius)),
        activePaint,
      );

      context.canvas.drawRRect(
        RRect.fromRectAndRadius(trackRect, Radius.circular(borderRadius)),
        outlinePaint,
      );



  }
}