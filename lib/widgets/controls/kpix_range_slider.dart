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


import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class KPixRangeSlider extends StatefulWidget {
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
  final int hoverAlpha;

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
    this.hoverAlpha = 32,
    this.label,

  });

  @override
  State<KPixRangeSlider> createState() => _KPixRangeSliderState();
}

class _KPixRangeSliderState extends State<KPixRangeSlider>
{
  final ValueNotifier<bool> isHovering = ValueNotifier<bool>(false);

  @override
  Widget build(final BuildContext context)
  {
    final Color fgColor = widget.activeTrackColor ?? Theme.of(context).primaryColorLight;
    final Color bgColor = widget.inActiveTrackColor ?? Theme.of(context).primaryColor;
    final Color disColor = widget.disabledColor ?? Theme.of(context).primaryColorDark;


    return MouseRegion(
      onEnter: (final PointerEnterEvent event) {
        isHovering.value = true;
      },
      onExit: (final PointerExitEvent event) {
        isHovering.value = false;
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: isHovering,
        builder: (final BuildContext context, final bool hoverValue, final Widget? child) {
          final Color bColor = widget.borderColor ?? Theme.of(context).primaryColorLight;
          final Color hoverOverlayColor = Theme.of(context).primaryColorLight.withAlpha(widget.hoverAlpha);
          final Color defaultInActiveTrackColor = widget.inActiveTrackColor ?? Theme.of(context).primaryColor;

          final Color currentInActiveTrackColor;
          if (hoverValue)
          {
            currentInActiveTrackColor = Color.alphaBlend(hoverOverlayColor, defaultInActiveTrackColor);
          }
          else
          {
            currentInActiveTrackColor = defaultInActiveTrackColor;
          }

          return SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: widget.trackHeight,
              activeTrackColor: fgColor,
              inactiveTrackColor: currentInActiveTrackColor,
              overlayShape: SliderComponentShape.noOverlay,
              rangeTrackShape: _KPixRangeSliderTrackShape(borderRadius: widget.borderRadius, strokeColor: bColor, strokeWidth: widget.borderWidth),
              rangeThumbShape: const _InvisibleRangeSliderThumbShape(),
              rangeTickMarkShape: const _InvisibleRangeSliderTickMarkShape(),

            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                RangeSlider(
                  values: widget.values,
                  onChanged: widget.onChanged,
                  divisions: widget.divisions,
                  min: widget.min,
                  max: widget.max,
                ),
                Positioned.fill(
                  child: Center(
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Text(
                            widget.label ?? "${widget.values.start.toStringAsFixed(widget.decimals)}-${widget.values.end.toStringAsFixed(widget.decimals)}",
                            style: TextStyle(
                              fontSize: widget.textStyle.fontSize,
                              fontFamily: widget.textStyle.fontFamily,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = widget.fontStrokeWidth
                                ..color = bgColor,
                            ),
                          ),
                          Text(
                            widget.label ?? "${widget.values.start.toStringAsFixed(widget.decimals)}-${widget.values.end.toStringAsFixed(widget.decimals)}",
                            style: TextStyle(
                              fontSize: widget.textStyle.fontSize,
                              fontFamily: widget.textStyle.fontFamily,
                              fontWeight: FontWeight.bold,
                              color: widget.onChanged != null ? fgColor : disColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

class _KPixRangeSliderTrackShape extends RectangularRangeSliderTrackShape {
  final double borderRadius;
  final double strokeWidth;
  final Color strokeColor;

  const _KPixRangeSliderTrackShape({
    this.borderRadius = 4.0,
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.black,
  });


  @override
  void paint(
    final PaintingContext context,
    final Offset offset, {
        required final RenderBox parentBox,
        required final SliderThemeData sliderTheme,
        required final Animation<double>? enableAnimation,
        required final Offset startThumbCenter,
        required final Offset endThumbCenter,
        final bool isEnabled = true,
        final bool isDiscrete = false,
        required final TextDirection textDirection,
      })
  {
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

    final Paint inActivePaint = Paint()
      ..color = isEnabled ? sliderTheme.inactiveTrackColor! : Colors.transparent
      ..style = PaintingStyle.fill;

    final Rect activeTrack = Rect.fromLTRB(
      startThumbCenter.dx,
      trackRect.top,
      endThumbCenter.dx,
      trackRect.bottom,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(borderRadius)),
      inActivePaint,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(borderRadius)),
      outlinePaint,
    );

    if ((activeTrack.right - activeTrack.left) < borderRadius * 2)
    {
      final RRect clipRect = RRect.fromLTRBR(trackRect.left - strokeWidth / 2, trackRect.top - strokeWidth / 2, trackRect.right + strokeWidth / 2, trackRect.bottom + strokeWidth / 2, Radius.circular(borderRadius));
      context.canvas.clipRRect(clipRect);
    }

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeTrack, Radius.circular(borderRadius)),
      activePaint,
    );

  }

}
