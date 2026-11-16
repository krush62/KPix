/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Input border that only draws rounded brackets at the four corners.
class CornerBracketInputBorder extends InputBorder
{
  /// Length of each bracket arm, measured from the corner.
  final double cornerLength;
  final double radius;
  /// Space between the container edge and the brackets/fill.
  final EdgeInsets margin;

  const CornerBracketInputBorder({
    super.borderSide = const BorderSide(),
    this.cornerLength = 8.0,
    this.radius = 5.0,
    this.margin = EdgeInsets.zero,
  });

  @override
  CornerBracketInputBorder copyWith({final BorderSide? borderSide, final double? cornerLength, final double? radius, final EdgeInsets? margin})
  {
    return CornerBracketInputBorder(
      borderSide: borderSide ?? this.borderSide,
      cornerLength: cornerLength ?? this.cornerLength,
      radius: radius ?? this.radius,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => margin + EdgeInsets.all(borderSide.width);

  @override
  CornerBracketInputBorder scale(final double t)
  {
    return CornerBracketInputBorder(borderSide: borderSide.scale(t), cornerLength: cornerLength * t, radius: radius * t, margin: margin * t);
  }

  RRect _outerRRect(final Rect rect) => RRect.fromRectAndRadius(margin.deflateRect(rect), Radius.circular(radius));

  @override
  Path getInnerPath(final Rect rect, {final TextDirection? textDirection})
  {
    return Path()..addRRect(_outerRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(final Rect rect, {final TextDirection? textDirection})
  {
    return Path()..addRRect(_outerRRect(rect));
  }

  @override
  void paintInterior(final Canvas canvas, final Rect rect, final Paint paint, {final TextDirection? textDirection})
  {
    canvas.drawRRect(_outerRRect(rect), paint);
  }

  @override
  bool get preferPaintInterior => true;

  @override
  ShapeBorder? lerpFrom(final ShapeBorder? a, final double t)
  {
    if (a is CornerBracketInputBorder)
    {
      return CornerBracketInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        cornerLength: lerpDouble(a.cornerLength, cornerLength, t)!,
        radius: lerpDouble(a.radius, radius, t)!,
        margin: EdgeInsets.lerp(a.margin, margin, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(final ShapeBorder? b, final double t)
  {
    if (b is CornerBracketInputBorder)
    {
      return CornerBracketInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        cornerLength: lerpDouble(cornerLength, b.cornerLength, t)!,
        radius: lerpDouble(radius, b.radius, t)!,
        margin: EdgeInsets.lerp(margin, b.margin, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    final Canvas canvas,
    final Rect rect, {
    final double? gapStart,
    final double gapExtent = 0.0,
    final double gapPercentage = 0.0,
    final TextDirection? textDirection,
  })
  {
    if (borderSide.style == BorderStyle.none || borderSide.width <= 0.0) return;

    // Stroke centered half a width inside the box; arms end flat exactly cornerLength from its outer edge.
    final Rect outer = margin.deflateRect(rect);
    final double half = borderSide.width / 2.0;
    final Rect r = outer.deflate(half);
    final double arm = max(0.0, min(cornerLength, min(outer.width, outer.height) / 2.0) - half);
    final double rad = min(radius, arm);
    final Path path = Path()
      ..moveTo(r.left, r.top + arm)
      ..lineTo(r.left, r.top + rad)
      ..arcToPoint(Offset(r.left + rad, r.top), radius: Radius.circular(rad))
      ..lineTo(r.left + arm, r.top)
      ..moveTo(r.right - arm, r.top)
      ..lineTo(r.right - rad, r.top)
      ..arcToPoint(Offset(r.right, r.top + rad), radius: Radius.circular(rad))
      ..lineTo(r.right, r.top + arm)
      ..moveTo(r.right, r.bottom - arm)
      ..lineTo(r.right, r.bottom - rad)
      ..arcToPoint(Offset(r.right - rad, r.bottom), radius: Radius.circular(rad))
      ..lineTo(r.right - arm, r.bottom)
      ..moveTo(r.left + arm, r.bottom)
      ..lineTo(r.left + rad, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - rad), radius: Radius.circular(rad))
      ..lineTo(r.left, r.bottom - arm);

    canvas.drawPath(path, borderSide.toPaint());
  }

  @override
  bool operator ==(final Object other)
  {
    if (identical(this, other)) return true;
    return other is CornerBracketInputBorder && other.borderSide == borderSide && other.cornerLength == cornerLength && other.radius == radius && other.margin == margin;
  }

  @override
  int get hashCode => Object.hash(borderSide, cornerLength, radius, margin);
}
