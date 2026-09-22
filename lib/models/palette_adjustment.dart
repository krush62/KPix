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

import 'dart:ui';

import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/constraints/palette_adjustment_constraints.dart';
import 'package:kpix/util/helpers/color_helper.dart';

/// The value all ramps are stretched around, in percent.
const double _valuePivot = 50.0;

/// The value the base color is taken at while the channel gains are applied.
///
/// Half brightness leaves every channel enough room to be scaled up without
/// running into the top of the range, so no gain is ever cut short.
const double _gainPivot = 0.5;

const double _percent = 100.0;
const double _fullCircle = 360.0;

/// A set of adjustments applied to the whole palette at once.
///
/// The values are deltas, not absolutes: they are applied to the settings a ramp
/// had before the adjustment started, so going back to the defaults restores the
/// original palette exactly.
class PaletteAdjustment
{
  /// Moves the value range of every ramp up or down, in percentage points.
  final double brightness;

  /// Stretches the value range of every ramp around the middle of the range.
  final double contrast;

  /// Scales the saturation of every ramp.
  final double saturation;

  /// Drives the red and the blue channel of every ramp apart, cool to warm.
  final double whiteBalance;

  /// Drives the green channel of every ramp, green to magenta.
  final double tint;

  /// Rotates the base hue of every ramp.
  final double hueShift;

  /// Scales how far the hue travels from the dark to the bright end of a ramp.
  final double hueSpread;

  const PaletteAdjustment({
    this.brightness = PaletteAdjustmentConstraints.brightnessDefault,
    this.contrast = PaletteAdjustmentConstraints.contrastDefault,
    this.saturation = PaletteAdjustmentConstraints.saturationDefault,
    this.whiteBalance = PaletteAdjustmentConstraints.whiteBalanceDefault,
    this.tint = PaletteAdjustmentConstraints.tintDefault,
    this.hueShift = PaletteAdjustmentConstraints.hueShiftDefault,
    this.hueSpread = PaletteAdjustmentConstraints.hueSpreadDefault,
  });

  PaletteAdjustment copyWith({
    final double? brightness,
    final double? contrast,
    final double? saturation,
    final double? whiteBalance,
    final double? tint,
    final double? hueShift,
    final double? hueSpread,
  })
  {
    return PaletteAdjustment(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      tint: tint ?? this.tint,
      hueShift: hueShift ?? this.hueShift,
      hueSpread: hueSpread ?? this.hueSpread,
    );
  }

  /// Whether the adjustment leaves the palette as it is.
  bool get isNeutral =>
      brightness == PaletteAdjustmentConstraints.brightnessDefault &&
      contrast == PaletteAdjustmentConstraints.contrastDefault &&
      saturation == PaletteAdjustmentConstraints.saturationDefault &&
      whiteBalance == PaletteAdjustmentConstraints.whiteBalanceDefault &&
      tint == PaletteAdjustmentConstraints.tintDefault &&
      hueShift == PaletteAdjustmentConstraints.hueShiftDefault &&
      hueSpread == PaletteAdjustmentConstraints.hueSpreadDefault;
}

/// Applies [adjustment] to [settings] and returns the result.
///
/// [settings] is left untouched, so the same settings can be adjusted again
/// with different values while the dialog is open.
KPalRampSettings adjustRampSettings({
  required final KPalRampSettings settings,
  required final PaletteAdjustment adjustment,
})
{
  final KPalRampSettings adjusted = KPalRampSettings.from(other: settings);
  final double originalHue = settings.baseHue.toDouble() % _fullCircle;
  final double originalSat = (settings.baseSat / _percent).clamp(0.0, 1.0);

  //white balance and tint are channel gains on the base color, as they would be
  //on a photo; hue and saturation are read back off the result. The trip through
  //rgb is not exact, so it is only taken when there is a gain to apply - a hue
  //must not drift while an unrelated slider is being dragged.
  double balancedHue = originalHue;
  double balancedSat = originalSat;
  if (adjustment.whiteBalance != PaletteAdjustmentConstraints.whiteBalanceDefault || adjustment.tint != PaletteAdjustmentConstraints.tintDefault)
  {
    const double gain = PaletteAdjustmentConstraints.channelGainStrength;
    final double warmth = adjustment.whiteBalance / _percent;
    final double tint = adjustment.tint / _percent;
    final Color baseColor = KHSV(h: originalHue, s: originalSat, v: _gainPivot).toColor();
    final KHSV balanced = KHSV.fromColor(
      color: Color.from(
        alpha: 1.0,
        red: (baseColor.r * (1.0 + (warmth * gain))).clamp(0.0, 1.0),
        green: (baseColor.g * (1.0 - (tint * gain))).clamp(0.0, 1.0),
        blue: (baseColor.b * (1.0 - (warmth * gain))).clamp(0.0, 1.0),
      ),
    );
    //a fully desaturated base has no hue of its own to keep shifting
    balancedHue = balanced.s > 0.0 ? balanced.h : originalHue;
    balancedSat = balanced.s;
  }

  final double saturationFactor = 1.0 + (adjustment.saturation / _percent);
  adjusted.baseHue = ((balancedHue + adjustment.hueShift) % _fullCircle).round().clamp(KPalConstraints.baseHueMin, KPalConstraints.baseHueMax);
  adjusted.baseSat = (balancedSat * _percent * saturationFactor).round().clamp(KPalConstraints.baseSatMin, KPalConstraints.baseSatMax);
  adjusted.satShift = (settings.satShift * saturationFactor).round().clamp(KPalConstraints.satShiftMin, KPalConstraints.satShiftMax);

  final double contrastFactor = 1.0 + (adjustment.contrast / _percent);
  adjusted.valueRangeMin = _adjustValue(value: settings.valueRangeMin, contrastFactor: contrastFactor, brightness: adjustment.brightness);
  adjusted.valueRangeMax = _adjustValue(value: settings.valueRangeMax, contrastFactor: contrastFactor, brightness: adjustment.brightness);

  final double spreadFactor = 1.0 + (adjustment.hueSpread / _percent);
  adjusted.hueShift = (settings.hueShift * spreadFactor).round().clamp(KPalConstraints.hueShiftMin, KPalConstraints.hueShiftMax);

  return adjusted;
}

int _adjustValue({required final int value, required final double contrastFactor, required final double brightness})
{
  final double stretched = _valuePivot + ((value - _valuePivot) * contrastFactor) + brightness;
  return stretched.round().clamp(KPalConstraints.valueRangeMin, KPalConstraints.valueRangeMax);
}

/// Whether [component] sits at the end of the 0..1 range a color is clamped to.
bool _isAtRangeEnd({required final double component}) => component <= 0.0 || component >= 1.0;

/// Whether the value of the color at [index] of [ramp] ran into the end of its
/// range.
///
/// The color before the per color shift counts as well: a shift is added on top
/// of an already clamped value, so a ramp driven all the way down to black
/// would otherwise look unclipped wherever a color was raised by hand.
bool hasValueClipping({required final KPalRampData ramp, required final int index}) =>
    _isAtRangeEnd(component: ramp.baseColors[index].v) || _isAtRangeEnd(component: ramp.shiftedColors[index].value.hsv.v);

/// Whether the saturation of the color at [index] of [ramp] ran into the end of
/// its range. See [hasValueClipping].
bool hasSaturationClipping({required final KPalRampData ramp, required final int index}) =>
    _isAtRangeEnd(component: ramp.baseColors[index].s) || _isAtRangeEnd(component: ramp.shiftedColors[index].value.hsv.s);
