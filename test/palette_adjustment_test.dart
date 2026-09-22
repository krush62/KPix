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

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/history/history_shift_set.dart';
import 'package:kpix/models/palette_adjustment.dart';

/// The settings of the ramps the default palette is built from.
List<KPalRampSettings> _defaultSettings()
{
  return KPalRampData.getDefaultPalette().map((final KPalRampData ramp) => ramp.settings).toList();
}

KPalRampSettings _settings({
  final int baseHue = 210,
  final int baseSat = 60,
  final int hueShift = -10,
  final int satShift = -8,
  final int valueRangeMin = 20,
  final int valueRangeMax = 90,
})
{
  final KPalRampSettings settings = KPalRampSettings();
  settings.baseHue = baseHue;
  settings.baseSat = baseSat;
  settings.hueShift = hueShift;
  settings.satShift = satShift;
  settings.valueRangeMin = valueRangeMin;
  settings.valueRangeMax = valueRangeMax;
  return settings;
}

/// A ramp built from [_settings] with [adjustment] applied to it.
///
/// [shifts] are the per color shifts of the ramp, which are applied on top of
/// the adjusted colors.
KPalRampData _adjustedRamp({
  required final PaletteAdjustment adjustment,
  final List<HistoryShiftSet>? shifts,
  final KPalRampSettings? settings,
})
{
  final KPalRampSettings original = settings ?? _settings();
  final KPalRampData ramp = KPalRampData(uuid: "test", settings: KPalRampSettings.from(other: original), historyShifts: shifts);
  ramp.settings.setFrom(other: adjustRampSettings(settings: original, adjustment: adjustment));
  ramp.updateColors(colorCountChanged: false);
  return ramp;
}

/// The indices of the colors of [ramp] whose value ran into the end of its range.
Iterable<int> _clippedValues({required final KPalRampData ramp})
{
  return Iterable<int>.generate(ramp.shiftedColors.length).where((final int i) => hasValueClipping(ramp: ramp, index: i));
}

/// The indices of the colors of [ramp] whose saturation ran into the end of its
/// range.
Iterable<int> _clippedSaturations({required final KPalRampData ramp})
{
  return Iterable<int>.generate(ramp.shiftedColors.length).where((final int i) => hasSaturationClipping(ramp: ramp, index: i));
}

void main()
{
  group("neutral adjustment", ()
  {
    test("leaves every ramp of the default palette as it is", ()
    {
      for (final KPalRampSettings original in _defaultSettings())
      {
        final KPalRampSettings adjusted = adjustRampSettings(settings: original, adjustment: const PaletteAdjustment());
        expect(adjusted.baseHue, original.baseHue);
        expect(adjusted.baseSat, original.baseSat);
        expect(adjusted.hueShift, original.hueShift);
        expect(adjusted.satShift, original.satShift);
        expect(adjusted.valueRangeMin, original.valueRangeMin);
        expect(adjusted.valueRangeMax, original.valueRangeMax);
      }
    });

    test("is reported as neutral", ()
    {
      expect(const PaletteAdjustment().isNeutral, isTrue);
      expect(const PaletteAdjustment(brightness: 1.0).isNeutral, isFalse);
      expect(const PaletteAdjustment(hueSpread: -1.0).isNeutral, isFalse);
    });

    test("keeps the settings an adjustment does not touch", ()
    {
      final KPalRampSettings original = _settings();
      original.colorCount = 9;
      original.satCurve = SatCurve.brightFlat;
      original.hueShiftExp = 1.25;
      original.satShiftExp = 0.75;
      final KPalRampSettings adjusted = adjustRampSettings(settings: original, adjustment: const PaletteAdjustment(brightness: 20.0, saturation: 40.0, hueShift: 90.0));
      expect(adjusted.colorCount, 9);
      expect(adjusted.satCurve, SatCurve.brightFlat);
      expect(adjusted.hueShiftExp, 1.25);
      expect(adjusted.satShiftExp, 0.75);
    });

    test("leaves the source settings untouched", ()
    {
      final KPalRampSettings original = _settings();
      adjustRampSettings(settings: original, adjustment: const PaletteAdjustment(brightness: 30.0, hueShift: 120.0));
      expect(original.baseHue, 210);
      expect(original.valueRangeMin, 20);
      expect(original.valueRangeMax, 90);
    });
  });

  group("brightness", ()
  {
    test("moves the whole value range", ()
    {
      final KPalRampSettings adjusted = adjustRampSettings(settings: _settings(), adjustment: const PaletteAdjustment(brightness: 5.0));
      expect(adjusted.valueRangeMin, 25);
      expect(adjusted.valueRangeMax, 95);
    });

    test("clamps the range at the top and collapses it at the ends", ()
    {
      final KPalRampSettings up = adjustRampSettings(settings: _settings(), adjustment: const PaletteAdjustment(brightness: 20.0));
      expect(up.valueRangeMin, 40);
      expect(up.valueRangeMax, KPalConstraints.valueRangeMax);

      final KPalRampSettings down = adjustRampSettings(settings: _settings(), adjustment: const PaletteAdjustment(brightness: -100.0));
      expect(down.valueRangeMin, KPalConstraints.valueRangeMin);
      expect(down.valueRangeMax, KPalConstraints.valueRangeMin);
    });
  });

  group("contrast", ()
  {
    test("stretches the value range around the middle", ()
    {
      final KPalRampSettings adjusted = adjustRampSettings(settings: _settings(valueRangeMin: 40, valueRangeMax: 60), adjustment: const PaletteAdjustment(contrast: 50.0));
      expect(adjusted.valueRangeMin, 35);
      expect(adjusted.valueRangeMax, 65);
    });

    test("collapses the value range at the lowest setting", ()
    {
      final KPalRampSettings adjusted = adjustRampSettings(settings: _settings(), adjustment: const PaletteAdjustment(contrast: -100.0));
      expect(adjusted.valueRangeMin, 50);
      expect(adjusted.valueRangeMax, 50);
    });
  });

  group("saturation", ()
  {
    test("scales the base saturation and the saturation shift", ()
    {
      final KPalRampSettings adjusted = adjustRampSettings(settings: _settings(baseSat: 40, satShift: -10), adjustment: const PaletteAdjustment(saturation: 50.0));
      expect(adjusted.baseSat, 60);
      expect(adjusted.satShift, -15);
    });

    test("takes the whole ramp to greyscale at the lowest setting", ()
    {
      for (final KPalRampSettings original in _defaultSettings())
      {
        final KPalRampSettings adjusted = adjustRampSettings(settings: original, adjustment: const PaletteAdjustment(saturation: -100.0));
        expect(adjusted.baseSat, 0);
        expect(adjusted.satShift, 0);
      }
    });

    test("stays inside the ramp constraints", ()
    {
      final KPalRampSettings adjusted = adjustRampSettings(settings: _settings(baseSat: 90, satShift: -20), adjustment: const PaletteAdjustment(saturation: 100.0));
      expect(adjusted.baseSat, KPalConstraints.baseSatMax);
      expect(adjusted.satShift, KPalConstraints.satShiftMin);
    });
  });

  group("hue", ()
  {
    test("rotates the base hue and wraps around", ()
    {
      expect(adjustRampSettings(settings: _settings(baseHue: 200), adjustment: const PaletteAdjustment(hueShift: 30.0)).baseHue, 230);
      expect(adjustRampSettings(settings: _settings(baseHue: 350), adjustment: const PaletteAdjustment(hueShift: 30.0)).baseHue, 20);
      expect(adjustRampSettings(settings: _settings(baseHue: 10), adjustment: const PaletteAdjustment(hueShift: -30.0)).baseHue, 340);
    });

    test("keeps the base hue of a fully desaturated ramp", ()
    {
      final KPalRampSettings adjusted = adjustRampSettings(settings: _settings(baseHue: 191, baseSat: 0), adjustment: const PaletteAdjustment(saturation: 50.0));
      expect(adjusted.baseHue, 191);
      expect(adjusted.baseSat, 0);
    });

    test("scales the hue shift of the ramp with the hue spread", ()
    {
      expect(adjustRampSettings(settings: _settings(hueShift: -20), adjustment: const PaletteAdjustment(hueSpread: 50.0)).hueShift, -30);
      expect(adjustRampSettings(settings: _settings(hueShift: -20), adjustment: const PaletteAdjustment(hueSpread: -100.0)).hueShift, 0);
      expect(adjustRampSettings(settings: _settings(hueShift: 80), adjustment: const PaletteAdjustment(hueSpread: 100.0)).hueShift, KPalConstraints.hueShiftMax);
    });
  });

  group("white balance and tint", ()
  {
    test("drive a grey ramp towards a warm and a cool hue", ()
    {
      final KPalRampSettings warm = adjustRampSettings(settings: _settings(baseHue: 200, baseSat: 0), adjustment: const PaletteAdjustment(whiteBalance: 100.0));
      expect(warm.baseSat, greaterThan(0));
      expect(warm.baseHue, lessThan(60));

      final KPalRampSettings cool = adjustRampSettings(settings: _settings(baseHue: 200, baseSat: 0), adjustment: const PaletteAdjustment(whiteBalance: -100.0));
      expect(cool.baseSat, greaterThan(0));
      expect(cool.baseHue, inInclusiveRange(180, 260));
    });

    test("drives a grey ramp towards green and magenta", ()
    {
      final KPalRampSettings magenta = adjustRampSettings(settings: _settings(baseHue: 200, baseSat: 0), adjustment: const PaletteAdjustment(tint: 100.0));
      expect(magenta.baseSat, greaterThan(0));
      expect(magenta.baseHue, 300);

      final KPalRampSettings green = adjustRampSettings(settings: _settings(baseHue: 200, baseSat: 0), adjustment: const PaletteAdjustment(tint: -100.0));
      expect(green.baseSat, greaterThan(0));
      expect(green.baseHue, 120);
    });

    test("warms a saturated ramp without leaving the hue circle", ()
    {
      for (final KPalRampSettings original in _defaultSettings())
      {
        final KPalRampSettings adjusted = adjustRampSettings(settings: original, adjustment: const PaletteAdjustment(whiteBalance: 100.0, tint: -100.0));
        expect(adjusted.baseHue, inInclusiveRange(KPalConstraints.baseHueMin, KPalConstraints.baseHueMax));
        expect(adjusted.baseSat, inInclusiveRange(KPalConstraints.baseSatMin, KPalConstraints.baseSatMax));
      }
    });
  });

  group("clipping", ()
  {
    test("is not reported for a ramp of the default palette", ()
    {
      for (final KPalRampData ramp in KPalRampData.getDefaultPalette())
      {
        expect(_clippedValues(ramp: ramp), isEmpty, reason: "value clipping without an adjustment");
        expect(_clippedSaturations(ramp: ramp), isEmpty, reason: "saturation clipping without an adjustment");
      }
    });

    test("covers the whole ramp once the brightness is driven up", ()
    {
      final KPalRampData ramp = _adjustedRamp(adjustment: const PaletteAdjustment(brightness: 100.0));
      expect(_clippedValues(ramp: ramp).length, ramp.shiftedColors.length);
    });

    test("covers the whole ramp once the saturation is driven down", ()
    {
      final KPalRampData ramp = _adjustedRamp(adjustment: const PaletteAdjustment(saturation: -100.0));
      expect(_clippedSaturations(ramp: ramp).length, ramp.shiftedColors.length);
    });

    test("is reported for a color a shift lifts back off the end of the range", ()
    {
      //the darkest color is raised by hand, so the brightness cannot push it
      //all the way to black with the rest of the ramp
      final KPalRampData ramp = _adjustedRamp(
        adjustment: const PaletteAdjustment(brightness: -100.0),
        shifts: <HistoryShiftSet>[HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 5)],
      );
      expect(ramp.shiftedColors.first.value.hsv.v, greaterThan(0.0), reason: "the shift lifts the color off black");
      expect(_clippedValues(ramp: ramp).length, ramp.shiftedColors.length);
    });

    test("is reported for a color a shift pushes out of the range", ()
    {
      //a flat ramp at a saturation the shift of the first color reaches past
      final KPalRampData ramp = _adjustedRamp(
        adjustment: const PaletteAdjustment(),
        settings: _settings(baseSat: 20, satShift: 0),
        shifts: <HistoryShiftSet>[HistoryShiftSet(hueShift: 0, satShift: -25, valShift: 0)],
      );
      expect(_clippedSaturations(ramp: ramp), contains(0));
      expect(_clippedSaturations(ramp: ramp), isNot(contains(1)));
    });
  });
}
