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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/helpers/hash_helper.dart';

const int _fullCircle = 360;
const int _halfCircle = 180;
const int _byteLength = 255;


class IdColor
{
  final KHSV hsv;
  final Color color;
  final String uuid;
  IdColor({required this.hsv, required this.uuid}) : color = hsv.toColor();
  String getTooltipText()
  {
    final String name = GetIt.I.get<PreferenceManager>().colorNames.getColorName(r: color.r, g: color.g, b: color.b);
    final String hsv = "${this.hsv.h.round()}° ${(this.hsv.s * 100).round()}% ${(this.hsv.v * 100).round()}%";
    final String rgb = colorToRGBString(color: color);
    final String hex = colorToHexString(color: color);
    return "$name\n$hsv\n$rgb\n$hex";
  }
}

class ColorReference
{
  final KPalRampData ramp;
  final int colorIndex;
  ColorReference({required this.colorIndex, required this.ramp});
  IdColor getIdColor()
  {
    return ramp.shiftedColors[colorIndex.clamp(0, ramp.shiftedColors.length - 1)].value;
  }

  @override
  bool operator == (final Object other) =>
      identical(this, other) ||
          other is ColorReference &&
              ramp == other.ramp &&
              colorIndex == other.colorIndex;

  @override
  int get hashCode => combineHashes(a: ramp.hashCode, b: colorIndex);
}




class LabColor
{
  static const double abMax = 128.0;
  static const double lMax = 100.0;

  final double L;
  final double A;
  final double B;

  LabColor({
    required this.L,
    required this.A,
    required this.B,
  });
}

class KHSV
{
  final double h;
  final double s;
  final double v;

  KHSV({required this.h, required this.s, required this.v}) :
        assert(h >= 0.0 && h <= _fullCircle, 'Hue must be between 0 and $_fullCircle'),
        assert(s >= 0.0 && s <= 1.0, 'Saturation must be between 0 and 1'),
        assert(v >= 0.0 && v <= 1.0, 'Value must be between 0 and 1');

  KHSV.fromOther({required final KHSV other}) :
        h = other.h,
        s = other.s,
        v = other.v;

  factory KHSV.fromHSV({required final HSVColor hsvColor})
  {
    return KHSV(h: hsvColor.hue, s: hsvColor.saturation, v: hsvColor.value);
  }

  HSVColor toHSV({final double alpha = 1.0})
  {
    return HSVColor.fromAHSV(alpha, h, s, v);
  }

  Color toColor() {
    final double chroma = s * v;
    final double secondary = chroma * (1.0 - (((h / 60.0) % 2.0) - 1.0).abs());
    final double match = v - chroma;

    return _colorFromHue(hue: h, chroma: chroma, secondary: secondary, match: match);
  }


  factory KHSV.fromColor({required final Color color})
  {
    final double maxc = max(color.r, max(color.g, color.b));
    final double minc = min(color.r, min(color.g, color.b));
    final double delta = maxc - minc;
    final double v = maxc;

    if (delta == 0.0) {
      return KHSV(h: 0.0, s: 0.0, v: v);
    }

    final double s = (maxc == 0.0) ? 0.0 : (delta / maxc);
    double h;
    if (maxc == color.r)
    {
      h = 60.0 * (((color.g - color.b) / delta) % 6.0);
    }
    else if (maxc == color.g)
    {
      h = 60.0 * (((color.b - color.r) / delta) + 2.0);
    }
    else
    {
      h = 60.0 * (((color.r - color.g) / delta) + 4.0);
    }
    if (h < 0.0) h += _fullCircle;
    if (h >= _fullCircle) h -= _fullCircle;

    return KHSV(h: h, s: s, v: v);
  }

  factory KHSV.fromRgb({
    required final int r,
    required final int g,
    required final int b,
  }) => KHSV.fromColor(color: Color.fromARGB(0xFF, r, g, b));

  factory KHSV.fromArgb({
    required final int a,
    required final int r,
    required final int g,
    required final int b,
  }) => KHSV.fromColor(color: Color.fromARGB(a, r, g, b));



  Color _colorFromHue({required final double hue, required final double chroma, required final double secondary, required final double match})
  {
    final (double red, double green, double blue) = switch (hue) {
      < 60.0 => (chroma, secondary, 0.0),
      < 120.0 => (secondary, chroma, 0.0),
      < 180.0 => (0.0, chroma, secondary),
      < 240.0 => (0.0, secondary, chroma),
      < 300.0 => (secondary, 0.0, chroma),
      _ => (chroma, 0.0, secondary),
    };
    return Color.fromARGB(
      0xFF,
      ((red + match) * 0xFF).round(),
      ((green + match) * 0xFF).round(),
      ((blue + match) * 0xFF).round(),
    );
  }
}

/// Clamping the color channel values to 0-255.
int _clampChannel(final double value) => value.clamp(0.0, 1.0) * _byteLength ~/ 1;

/// Converts color to hex string
String colorToHexString({required final Color color, final bool withHashTag = true, final bool toUpper = false})
{
  final String prefix = withHashTag ? "#" : "";
  final String str =
      '$prefix${_clampChannel(color.r).toRadixString(16).padLeft(2, '0')}${_clampChannel(color.g).toRadixString(16).padLeft(2, '0')}${_clampChannel(color.b).toRadixString(16).padLeft(2, '0')}';
  return toUpper ? str.toUpperCase() : str;
}

/// Converts color to RGB string.
String colorToRGBString({required final Color color}) {
  return '${_clampChannel(color.r)} | ${_clampChannel(color.g)} | ${_clampChannel(color.b)}';
}

/// Converts sRGB (0..1) to CIE Lab (D65).
///
/// Inputs [r], [g], [b] are sRGB components normalized to 0..1.
///
/// Uses the D65 reference white and the standard sRGB transfer function.
/// Throws no exceptions; returns a [LabColor].
LabColor rgb2lab({
  required final double r,
  required final double g,
  required final double b,
}) {
  // --- sRGB transfer function constants ---
  const double srgbThreshold = 0.04045;
  const double srgbA = 0.055;
  const double srgbGamma = 2.4;

  // --- Reference white (D65) ---
  const double d65X = 0.95047;
  const double d65Y = 1.00000;
  const double d65Z = 1.08883;

  // --- CIE Lab pivot constants ---
  const double epsilon = 0.008856; // ≈ (6/29)^3
  const double kappa = 903.3;      // ≈ (29/3)^3

  // sRGB → linear RGB
  double linear(final double c) =>
      (c > srgbThreshold)
          ? pow((c + srgbA) / (1.0 + srgbA), srgbGamma).toDouble()
          : c / 12.92;

  final double rLin = linear(r.clamp(0.0, 1.0));
  final double gLin = linear(g.clamp(0.0, 1.0));
  final double bLin = linear(b.clamp(0.0, 1.0));

  // Linear RGB → XYZ (sRGB primaries, D65)
  final double x = (rLin * 0.4124 + gLin * 0.3576 + bLin * 0.1805) / d65X;
  final double y = (rLin * 0.2126 + gLin * 0.7152 + bLin * 0.0722) / d65Y;
  final double z = (rLin * 0.0193 + gLin * 0.1192 + bLin * 0.9505) / d65Z;

  // Pivot function for Lab
  double f(final double t) =>
      (t > epsilon) ? pow(t, 1.0 / 3.0).toDouble() : (kappa * t + 16.0) / 116.0;

  final double fx = f(x);
  final double fy = f(y);
  final double fz = f(z);

  // XYZ (normalized) → Lab
  final double L = (116.0 * fy) - 16.0;
  final double A = 500.0 * (fx - fy);
  final double B = 200.0 * (fy - fz);

  return LabColor(L: L, A: A, B: B);
}

/// Computes the CIEDE94 color difference ΔE94 between two sRGB colors.
///
/// Inputs will be normalized sRGB components in [0, 1]. If your values are
/// 0..255, divide each by 255.0 before calling.
///
/// Returns a non-negative ΔE94 (double).
double getDeltaE94(
    {required final double redA,
      required final double greenA,
      required final double blueA,
      required final double redB,
      required final double greenB,
      required final double blueB,})
{
  final LabColor labA = rgb2lab(r: redA, g: greenA, b: blueA);
  final LabColor labB = rgb2lab(r: redB, g: greenB, b: blueB);
  final double deltaL = labA.L - labB.L;
  final double deltaA = labA.A - labB.A;
  final double deltaB = labA.B - labB.B;
  final double c1 = sqrt(labA.A * labA.A + labA.B * labA.B);
  final double c2 = sqrt(labB.A * labB.A + labB.B * labB.B);
  final double deltaC = c1 - c2;
  double deltaH = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
  deltaH = deltaH < 0 ? 0 : sqrt(deltaH);
  final double sc = 1.0 + 0.045 * c1;
  final double sh = 1.0 + 0.015 * c1;
  final double deltaLKlsl = deltaL / 1.0;
  final double deltaCkcsc = deltaC / sc;
  final double deltaHkhsh = deltaH / sh;
  final double i = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;
  return i < 0.0 ? 0.0 : sqrt(i);
}


/// Computes the CIEDE2000 color difference ΔE00 between two sRGB colors.
///
/// Inputs will be normalized sRGB components in [0, 1]. If your values are
/// 0..255, divide each by 255.0 before calling.
///
/// The calculation expects Lab values using the D65 reference white.
/// If your `rgb2lab` uses D65 (as in your earlier code), you are good.
///
/// You can adjust the weighting factors [kL], [kC], [kH] (normally 1.0).
///
/// Returns a non-negative ΔE00 (double).
double getDeltaE00({
  required final double redA,
  required final double greenA,
  required final double blueA,
  required final double redB,
  required final double greenB,
  required final double blueB,
  final double kL = 1.0,
  final double kC = 1.0,
  final double kH = 1.0,
})
{
  // Convert to Lab
  final LabColor labA = rgb2lab(r: redA, g: greenA, b: blueA);
  final LabColor labB = rgb2lab(r: redB, g: greenB, b: blueB);

  // Unpack
  final double l1 = labA.L;
  final double a1 = labA.A;
  final double b1 = labA.B;

  final double l2 = labB.L;
  final double a2 = labB.A;
  final double b2 = labB.B;

  // 1) Compute chroma
  final double c1 = sqrt(a1 * a1 + b1 * b1);
  final double c2 = sqrt(a2 * a2 + b2 * b2);
  final double cBar = 0.5 * (c1 + c2);

  // 2) G factor to adjust a*
  final double cBar7 = pow(cBar, 7).toDouble();
  const double k25_7 = 6103515625.0; // 25^7
  final double G = 0.5 * (1.0 - sqrt(cBar7 / (cBar7 + k25_7)));

  // 3) Adjusted a' and chroma C'
  final double a1p = (1.0 + G) * a1;
  final double a2p = (1.0 + G) * a2;
  final double c1p = sqrt(a1p * a1p + b1 * b1);
  final double c2p = sqrt(a2p * a2p + b2 * b2);

  // 4) Hue angles h' (in degrees, 0..360)
  double hPrime(final double ap, final double b)
  {
    if (ap == 0.0 && b == 0.0) return 0.0;
    final double ang = atan2(b, ap) * _halfCircle / pi;
    return (ang >= 0.0) ? ang : (ang + _fullCircle);
  }

  final double h1p = hPrime(a1p, b1);
  final double h2p = hPrime(a2p, b2);

  // 5) Differences
  final double dLp = l2 - l1;
  final double dCp = c2p - c1p;

  double dhp;
  if (c1p * c2p == 0.0)
  {
    dhp = 0.0;
  } else {
    dhp = h2p - h1p;
    if (dhp > _halfCircle) {
      dhp -= _fullCircle;
    } else if (dhp < -_halfCircle) {
      dhp += _fullCircle;
    }
  }

  final double dHp = 2.0 * sqrt(c1p * c2p) * sin((dhp * pi / _halfCircle) / 2.0);

  // 6) Means
  final double lbarp = (l1 + l2) / 2.0;
  final double cbarp = (c1p + c2p) / 2.0;

  double hbarp;
  if (c1p * c2p == 0.0)
  {
    hbarp = h1p + h2p; // irrelevant when chroma is zero
  }
  else
  {
    final double hsum = h1p + h2p;
    if ((h1p - h2p).abs() > _halfCircle)
    {
      hbarp = (hsum < _fullCircle) ? (hsum + _fullCircle) / 2.0 : (hsum - _fullCircle) / 2.0;
    }
    else
    {
      hbarp = hsum / 2.0;
    }
  }

  // 7) T term
  final double T = 1.0
      - 0.17 * cos((hbarp - 30.0) * pi / _halfCircle)
      + 0.24 * cos((2.0 * hbarp) * pi / _halfCircle)
      + 0.32 * cos((3.0 * hbarp + 6.0) * pi / _halfCircle)
      - 0.20 * cos((4.0 * hbarp - 63.0) * pi / _halfCircle);

  // 8) Δθ and rc
  final double dTheta = 30.0 * exp(-pow((hbarp - 275.0) / 25.0, 2).toDouble());
  final double rc = 2.0 * sqrt(pow(cbarp, 7).toDouble() / (pow(cbarp, 7).toDouble() + k25_7));

  // 9) sl, sc, sh
  final double sl = 1.0 + (0.015 * pow(lbarp - 50.0, 2).toDouble()) /
      sqrt(20.0 + pow(lbarp - 50.0, 2).toDouble());
  final double sc = 1.0 + 0.045 * cbarp;
  final double sh = 1.0 + 0.015 * cbarp * T;

  // 10) rt
  final double rt = -sin(2.0 * dTheta * pi / _halfCircle) * rc;

  // 11) Final ΔE00
  final double dLterm = dLp / (kL * sl);
  final double dCterm = dCp / (kC * sc);
  final double dHterm = dHp / (kH * sh);

  final double sum = dLterm * dLterm +
      dCterm * dCterm +
      dHterm * dHterm +
      rt * dCterm * dHterm;

  // Guard against tiny negative due to floating point
  return sqrt(sum < 0.0 ? 0.0 : sum);
}

/// Converts an argb color to a rgba color.
int argbToRgba({required final int argb}) {
  final int a = (argb & 0xFF000000) >> 24; // Extract alpha component
  final int r = (argb & 0x00FF0000) >> 16; // Extract red component
  final int g = (argb & 0x0000FF00) >> 8;  // Extract green component
  final int b = argb & 0x000000FF;       // Extract blue component
  final int rgba = (r << 24) | (g << 16) | (b << 8) | a;
  return rgba;
}

// IMAGE ADJUSTMENT FUNCTIONS

List<double> _saturationMatrix({required final double saturation})
{
  final double invSat = 1.0 - saturation;

  // Rec. 709 luminance coefficients
  final double r = 0.2126 * invSat;
  final double g = 0.7152 * invSat;
  final double b = 0.0722 * invSat;

  return <double>[
    r + saturation, g, b, 0, 0,
    r, g + saturation, b, 0, 0,
    r, g, b + saturation, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

List<double> _brightnessMatrix({required final double brightness})
{
  final double offset = brightness * _byteLength;

  return <double>[
    1, 0, 0, 0, offset,
    0, 1, 0, 0, offset,
    0, 0, 1, 0, offset,
    0, 0, 0, 1, 0,
  ];
}

List<double> _contrastMatrix({required final double contrast})
{
  final double offset = 128.0 * (1.0 - contrast);

  return <double>[
    contrast, 0, 0, 0, offset,
    0, contrast, 0, 0, offset,
    0, 0, contrast, 0, offset,
    0, 0, 0, 1, 0,
  ];
}

List<double> _warmthMatrix({required final double warmth})
{
  final double amount = warmth * 0.15;

  final double redScale = 1.0 + amount;
  final double greenScale = 1.0 + amount * 0.4;
  final double blueScale = 1.0 - amount;

  return <double>[
    redScale, 0, 0, 0, 0,
    0, greenScale, 0, 0, 0,
    0, 0, blueScale, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

List<double> _multiplyColorMatrices({required final List<double> a, required final List<double> b,})
{
  final List<double> result = List<double>.filled(20, 0.0);

  for (int row = 0; row < 4; row++)
  {
    final int rowIndex = row * 5;

    for (int col = 0; col < 5; col++)
    {
      if (col == 4)
      {
        result[rowIndex + col] =
            a[rowIndex + 0] * b[4] +
                a[rowIndex + 1] * b[9] +
                a[rowIndex + 2] * b[14] +
                a[rowIndex + 3] * b[19] +
                a[rowIndex + 4];
      }
      else
      {
        result[rowIndex + col] =
            a[rowIndex + 0] * b[col] +
                a[rowIndex + 1] * b[5 + col] +
                a[rowIndex + 2] * b[10 + col] +
                a[rowIndex + 3] * b[15 + col];
      }
    }
  }

  return result;
}

ColorFilter imageAdjustmentsFilter({
  final double saturation = 1.0,
  final double brightness = 0.0,
  final double contrast = 1.0,
  final double warmth = 0.0,
}) {
  final List<double> matrix = _multiplyColorMatrices(a:
  _brightnessMatrix(brightness: brightness),
    b: _multiplyColorMatrices(
      a: _contrastMatrix(contrast: contrast),
      b: _multiplyColorMatrices(
        a: _warmthMatrix(warmth: warmth),
        b: _saturationMatrix(saturation: saturation),
      ),
    ),
  );

  return ColorFilter.matrix(matrix);
}
