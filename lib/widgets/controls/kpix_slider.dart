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
  final bool showPlusSignForPositive;

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
    this.isRainbow = false,
    this.showPlusSignForPositive = false,

  });

  @override
  Widget build(final BuildContext context)
  {
    final Color fgColor = activeTrackColor ?? Theme.of(context).primaryColorLight;
    final Color bgColor = inActiveTrackColor ?? Theme.of(context).primaryColor;
    final Color disColor = disabledColor ?? Theme.of(context).primaryColorDark;
    final Color bColor = borderColor ?? Theme.of(context).primaryColorLight;

    String displayText;
    if (label != null)
    {
      displayText = label!;
    }
    else if (value > 0 && showPlusSignForPositive)
    {
      displayText = "+${value.toStringAsFixed(decimals)}";
    }
    else
    {
      displayText = value.toStringAsFixed(decimals);
    }

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
          disabledActiveTrackColor: disColor,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              divisions: divisions,
            ),
            if (!isRainbow) Positioned.fill(
              child: Center(
                child: IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Text(
                        displayText,
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
                        displayText,
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
            ) else const SizedBox.shrink(),
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
  Size getPreferredSize(final bool isEnabled, final bool isDiscrete) => Size.zero;

  @override
  void paint(final PaintingContext context, final Offset center, {required final Animation<double> activationAnimation, required final Animation<double> enableAnimation, required final bool isDiscrete, required final TextPainter labelPainter, required final RenderBox parentBox, required final SliderThemeData sliderTheme, required final TextDirection textDirection, required final double value, required final double textScaleFactor, required final Size sizeWithOverflow}) {

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    context.canvas.drawCircle(center, parentBox.size.height / 2 - padding, activePaint);
    context.canvas.drawCircle(center, parentBox.size.height / 2 - padding, inactivePaint);
  }
}

//TODO this might be deleted since SliderComponentShape.noThumb exists which does the exact same thing
class _InvisibleSliderThumbShape extends SliderComponentShape {
  const _InvisibleSliderThumbShape();

  @override
  Size getPreferredSize(final bool isEnabled, final bool isDiscrete) => Size.zero;

  @override
  void paint(
      final PaintingContext context,
      final Offset center, {
        required final Animation<double> activationAnimation,
        required final Animation<double> enableAnimation,
        required final bool isDiscrete,
        required final TextPainter labelPainter,
        required final RenderBox parentBox,
        required final SliderThemeData sliderTheme,
        required final TextDirection textDirection,
        required final double value,
        required final double textScaleFactor,
        required final Size sizeWithOverflow,
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
    this.isRainbow = false,
  });


  @override
  void paint(
      final PaintingContext context,
      final Offset offset, {
        final double additionalActiveTrackHeight = 0,
        required final Animation<double> enableAnimation,
        final bool isDiscrete = false,
        final bool isEnabled = true,
        required final RenderBox parentBox,
        final Offset? secondaryOffset,
        required final SliderThemeData sliderTheme,
        required final TextDirection textDirection,
        required final Offset thumbCenter,
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

      final Paint inActivePaint = Paint()
      ..color = isEnabled ? sliderTheme.inactiveTrackColor! : Colors.transparent
      ..style = PaintingStyle.fill;

      if (isRainbow)
      {
        activePaint = Paint()
          ..shader = LinearGradient(
            colors: List<Color>.generate(360, (final int hue) => HSVColor.fromAHSV(1, hue.toDouble(), 0.5, 0.7).toColor()),
          ).createShader(trackRect);
      }

      final Rect activeTrack = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      );

      if (!isRainbow)
      {
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(trackRect, Radius.circular(borderRadius)),
          inActivePaint,
        );
      }

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
