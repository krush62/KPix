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

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/history/history_shift_set.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/pixel_grid.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/util/palette_extraction.dart';

int _rgbOf({required final ColorReference reference})
{
  return reference.getIdColor().color.toARGB32() & 0xFFFFFF;
}

double _deltaE({required final int rgbA, required final int rgbB})
{
  LabColor lab(final int c) => rgb2lab(r: ((c >> 16) & 0xFF) / 255.0, g: ((c >> 8) & 0xFF) / 255.0, b: (c & 0xFF) / 255.0);
  return getDeltaE00Lab(labA: lab(rgbA), labB: lab(rgbB));
}

/// Every color of [ramps] as a run of opaque pixels; the run lengths vary so no two colors weigh the same.
Uint8List _imageOf({required final List<KPalRampData> ramps})
{
  final List<int> bytes = <int>[];
  int run = 0;
  for (final KPalRampData ramp in ramps)
  {
    for (final ColorReference reference in ramp.references)
    {
      final int rgb = _rgbOf(reference: reference);
      for (int i = 0; i < 40 + (run++ % 5) * 13; i++)
      {
        bytes.addAll(<int>[(rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF, 0xFF]);
      }
    }
  }
  return Uint8List.fromList(bytes);
}

List<KPalRampData> _rampsOf({required final List<ExtractedRamp> extracted})
{
  return <KPalRampData>[
    for (int i = 0; i < extracted.length; i++) KPalRampData(uuid: "ramp-$i", settings: extracted[i].settings, historyShifts: extracted[i].shifts),
  ];
}

/// Mean ΔE between every opaque pixel of [bytes] and the palette color it was matched with.
double _meanMatchError({required final Uint8List bytes, required final List<KPalRampData> ramps})
{
  final int pixelCount = bytes.length ~/ 4;
  final PixelGrid grid = matchImageToPalette(imgBytes: bytes, width: pixelCount, height: 1, palette: PaletteLab.fromRamps(ramps: ramps));
  double sum = 0.0;
  for (int i = 0; i < pixelCount; i++)
  {
    final int code = grid.get(x: i, y: 0);
    final int matched = _rgbOf(reference: ramps[PaletteCodec.rampIndexOf(code: code)].references[PaletteCodec.colorIndexOf(code: code)]);
    sum += _deltaE(rgbA: (bytes[i * 4] << 16) | (bytes[i * 4 + 1] << 8) | bytes[i * 4 + 2], rgbB: matched);
  }
  return sum / pixelCount;
}

void main()
{
  test("a ramp's own swatches fit back to settings that draw the same ramp", ()
  {
    //the per-color shifts are left out on purpose: this checks the fitted settings alone
    final Random rng = Random(99);
    const int trials = 60;
    double meanError = 0.0;
    for (int trial = 0; trial < trials; trial++)
    {
      final int colorCount = 4 + rng.nextInt(6);
      final KPalRampData truth = KPalRampData(uuid: "truth", settings: KPalRampSettings.fromValues(
        colorCount: colorCount,
        baseHue: rng.nextInt(360),
        hueShift: -15 + rng.nextInt(31),
        hueShiftExp: 0.7 + rng.nextInt(9) * 0.1,
        baseSat: 30 + rng.nextInt(55),
        satShift: -12 + rng.nextInt(25),
        satShiftExp: 0.7 + rng.nextInt(9) * 0.1,
        satCurve: SatCurve.values[rng.nextInt(SatCurve.values.length)],
        valueRangeMin: 12 + rng.nextInt(25),
        valueRangeMax: 70 + rng.nextInt(28),
      ),);
      final ExtractedRamp extracted = extractColorRamps(imgBytes: _imageOf(ramps: <KPalRampData>[truth]), maxRamps: 1, maxColors: colorCount, adaptiveCounts: false).single;
      final KPalRampData fitted = KPalRampData(uuid: "fitted", settings: extracted.settings);
      for (int i = 0; i < colorCount; i++)
      {
        meanError += _deltaE(rgbA: _rgbOf(reference: truth.references[i]), rgbB: _rgbOf(reference: fitted.references[i])) / (colorCount * trials);
      }
    }
    expect(meanError, lessThan(1.0));
  });

  test("an image painted with the default palette imports with its own colors", ()
  {
    final List<KPalRampData> palette = KPalRampData.getDefaultPalette();
    final Uint8List bytes = _imageOf(ramps: palette);
    final List<KPalRampData> ramps = _rampsOf(extracted: extractColorRamps(imgBytes: bytes, maxRamps: KPalConstraints.rampCountLimits.defaultValue, maxColors: KPalConstraints.colorCountLimits.defaultValue));
    //the old fit landed at 7.6 here
    expect(_meanMatchError(bytes: bytes, ramps: ramps), lessThan(1.5));
  });

  test("an image with few ramps is not padded out to the maximum counts", ()
  {
    final List<KPalRampData> palette = KPalRampData.getDefaultPalette();
    //the default palette's red and green ramps, 6 colors each
    final List<KPalRampData> source = <KPalRampData>[palette[1], palette[4]];
    final Uint8List bytes = _imageOf(ramps: source);
    final List<KPalRampData> ramps = _rampsOf(extracted: extractColorRamps(imgBytes: bytes, maxRamps: 8, maxColors: 12));
    final int colorCount = ramps.fold<int>(0, (final int sum, final KPalRampData ramp) => sum + ramp.settings.colorCount);
    expect(ramps.length, lessThanOrEqualTo(3));
    expect(colorCount, lessThanOrEqualTo(18));
    expect(_meanMatchError(bytes: bytes, ramps: ramps), lessThan(1.0));
  });

  test("without adaptive counts the limits are used as given", ()
  {
    final Uint8List bytes = _imageOf(ramps: <KPalRampData>[KPalRampData.getDefaultPalette()[1]]);
    final List<ExtractedRamp> extracted = extractColorRamps(imgBytes: bytes, maxRamps: 3, maxColors: 9, adaptiveCounts: false);
    expect(extracted.length, 3);
    expect(extracted.every((final ExtractedRamp ramp) => ramp.settings.colorCount == 9), isTrue);
  });

  test("the refined swatches stay inside the shift sliders' limits", ()
  {
    final Uint8List bytes = _imageOf(ramps: KPalRampData.getDefaultPalette());
    for (final ExtractedRamp ramp in extractColorRamps(imgBytes: bytes, maxRamps: 4, maxColors: 5))
    {
      expect(ramp.shifts.length, ramp.settings.colorCount);
      for (final HistoryShiftSet shift in ramp.shifts)
      {
        expect(shift.hueShift, inInclusiveRange(KPalSliderConstraints.hueLimits.min, KPalSliderConstraints.hueLimits.max));
        expect(shift.satShift, inInclusiveRange(KPalSliderConstraints.satLimits.min, KPalSliderConstraints.satLimits.max));
        expect(shift.valShift, inInclusiveRange(KPalSliderConstraints.valLimits.min, KPalSliderConstraints.valLimits.max));
      }
    }
  });

  test("pixels below the alpha threshold neither shape the palette nor get a color", ()
  {
    //a few opaque greens and many faint magentas
    final List<int> bytes = <int>[];
    for (int i = 0; i < 20; i++)
    {
      bytes.addAll(<int>[40, 160 + i * 4, 40, 0xFF]);
    }
    for (int i = 0; i < 200; i++)
    {
      bytes.addAll(<int>[230, 20, 200, importAlphaThreshold - 1]);
    }
    final Uint8List u8 = Uint8List.fromList(bytes);
    final List<KPalRampData> ramps = _rampsOf(extracted: extractColorRamps(imgBytes: u8, maxRamps: 4, maxColors: 5));
    for (final KPalRampData ramp in ramps)
    {
      for (final ColorReference reference in ramp.references)
      {
        final KHSV hsv = reference.getIdColor().hsv;
        expect(hsv.h, inInclusiveRange(80.0, 160.0), reason: "every swatch should be green, not $hsv");
      }
    }
    final PixelGrid grid = matchImageToPalette(imgBytes: u8, width: 220, height: 1, palette: PaletteLab.fromRamps(ramps: ramps));
    expect(grid.nonZeroCount, 20);
  });

  group("scaling down", ()
  {
    test("averages each block", ()
    {
      //2x2 blocks: black/white checker on the left, solid red on the right
      final Uint8List bytes = Uint8List.fromList(<int>[
        0, 0, 0, 255,       255, 255, 255, 255,   200, 0, 0, 255,   200, 0, 0, 255,
        255, 255, 255, 255, 0, 0, 0, 255,         200, 0, 0, 255,   200, 0, 0, 255,
      ]);
      final Uint8List scaled = scaleDownRgba(bytes: bytes, width: 4, height: 2, newWidth: 2, newHeight: 1);
      expect(scaled, <int>[128, 128, 128, 255, 200, 0, 0, 255]);
    });

    test("weights colors by alpha so transparent pixels add no color", ()
    {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0, 0, 255, 0,   200, 100, 0, 255,
        0, 0, 255, 0,   200, 100, 0, 255,
      ]);
      final Uint8List scaled = scaleDownRgba(bytes: bytes, width: 2, height: 2, newWidth: 1, newHeight: 1);
      expect(scaled, <int>[200, 100, 0, 128]);
    });

    test("covers every source pixel when the size does not divide evenly", ()
    {
      //5 pixels onto 2: the last column must not be dropped
      final Uint8List bytes = Uint8List.fromList(<int>[
        0, 0, 0, 255,   0, 0, 0, 255,   0, 0, 0, 255,   0, 0, 0, 255,   250, 250, 250, 255,
      ]);
      final Uint8List scaled = scaleDownRgba(bytes: bytes, width: 5, height: 1, newWidth: 2, newHeight: 1);
      expect(scaled.sublist(4), <int>[83, 83, 83, 255]);
    });
  });
}
