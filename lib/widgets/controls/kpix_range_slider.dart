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

class KPixRangeSlider extends StatelessWidget
{
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
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

  const KPixRangeSlider({
    super.key,
    required this.values,
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

  });

  @override
  Widget build(final BuildContext context)
  {
    final Color fgColor = activeTrackColor ?? Theme.of(context).primaryColorLight;
    final Color bgColor = inActiveTrackColor ?? Theme.of(context).primaryColor;
    final Color disColor = disabledColor ?? Theme.of(context).primaryColorDark;
    final Color bColor = borderColor ?? Theme.of(context).primaryColorLight;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: trackHeight,
        activeTrackColor: fgColor,
        inactiveTrackColor: bgColor,
        overlayShape: SliderComponentShape.noOverlay, // No overlay
        rangeTrackShape: _KPixRangeSliderTrackShape(borderRadius: borderRadius, strokeColor: bColor, strokeWidth: borderWidth),
        rangeThumbShape: const _InvisibleRangeSliderThumbShape(),
        rangeTickMarkShape: const _InvisibleRangeSliderTickMarkShape(),

      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          RangeSlider(
            values: values,
            onChanged: onChanged,
            divisions: divisions,
            min: min,
            max: max,
          ),
          Positioned.fill(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Text(
                    label ?? "${values.start.toStringAsFixed(decimals)}-${values.end.toStringAsFixed(decimals)}",
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
                    label ?? "${values.start.toStringAsFixed(decimals)}-${values.end.toStringAsFixed(decimals)}",
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
        ],
      ),
    );
  }
}

class _InvisibleRangeSliderTickMarkShape extends RangeSliderTickMarkShape
{
  const _InvisibleRangeSliderTickMarkShape();

  @override
  Size getPreferredSize({required final SliderThemeData sliderTheme, final bool isEnabled = false})  => Size.zero;

  @override
  void paint(final PaintingContext context, final Offset center, {required final RenderBox parentBox, required final SliderThemeData sliderTheme, required final Animation<double> enableAnimation, required final Offset startThumbCenter, required final Offset endThumbCenter, final bool isEnabled = false, required final TextDirection textDirection}) {
  }
}



class _InvisibleRangeSliderThumbShape extends RangeSliderThumbShape
{
  const _InvisibleRangeSliderThumbShape();

  @override
  Size getPreferredSize(final bool isEnabled, final bool isDiscrete) => Size.zero;

  @override
  void paint(
      final PaintingContext context,
      final Offset center, {
        required final Animation<double> activationAnimation,
        required final Animation<double> enableAnimation,
        final bool isDiscrete = true,
        final bool isEnabled = true,
        final bool isOnTop = true,
        final TextDirection textDirection = TextDirection.ltr,
        required final SliderThemeData sliderTheme,
        final Thumb thumb = Thumb.end,
        final bool isPressed = false,
      })
  {}

}

class _KPixRangeSliderTrackShape extends RoundedRectRangeSliderTrackShape {
  final double borderRadius;
  final double strokeWidth;
  final Color strokeColor;

  const _KPixRangeSliderTrackShape({
    this.borderRadius = 4.0,
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.black,
  });


  @override
  void paint(final PaintingContext context, final Offset offset, {required final RenderBox parentBox, required final SliderThemeData sliderTheme, required final Animation<double> enableAnimation, required final Offset startThumbCenter, required final Offset endThumbCenter, final bool isEnabled = false, final bool isDiscrete = false, required final TextDirection textDirection, final double additionalActiveTrackHeight = 2}) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.fill;

    final Rect activeTrack = Rect.fromLTRB(
      startThumbCenter.dx,
      trackRect.top,
      endThumbCenter.dx,
      trackRect.bottom,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(borderRadius)),
      outlinePaint,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeTrack, Radius.circular(borderRadius)),
      activePaint,
    );

  }

}
