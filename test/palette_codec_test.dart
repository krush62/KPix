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

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/kpal_ramp_data.dart';
import 'package:kpix/models/palette_codec.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/selection_harness.dart';

KPalRampData _ramp({required final String uuid, required final int colorCount})
{
  final KPalRampSettings settings = KPalRampSettings();
  settings.colorCount = colorCount;
  return KPalRampData(uuid: uuid, settings: settings);
}

Iterable<ColorReference> _allColors({required final List<KPalRampData> ramps}) sync*
{
  for (final KPalRampData ramp in ramps)
  {
    yield* ramp.references;
  }
}

void main()
{
  //the smallest, the largest and an ordinary color count
  final KPalRampData a = _ramp(uuid: "a", colorCount: KPalConstraints.colorCountMin);
  final KPalRampData b = _ramp(uuid: "b", colorCount: KPalConstraints.colorCountMax);
  final KPalRampData c = _ramp(uuid: "c", colorCount: 7);
  final PaletteCodec codec = PaletteCodec(ramps: <KPalRampData>[a, b, c]);

  group("codes", ()
  {
    test("every color gets a code of its own and decodes to the same object", ()
    {
      final Set<int> seen = <int>{};
      for (final ColorReference color in _allColors(ramps: codec.ramps))
      {
        final int code = codec.encode(color: color);
        expect(code, isNot(PaletteCodec.transparent));
        expect(code, lessThan(codec.codeCount));
        expect(seen.add(code), isTrue, reason: "two colors share code $code");
        expect(codec.decode(code: code), same(color));
      }
    });

    test("no color is transparent both ways", ()
    {
      expect(codec.encode(color: null), PaletteCodec.transparent);
      expect(codec.decode(code: PaletteCodec.transparent), isNull);
    });

    test("codes are the ramp and color index pair that history and files store", ()
    {
      for (int rampIndex = 0; rampIndex < codec.ramps.length; rampIndex++)
      {
        final List<ColorReference> references = codec.ramps[rampIndex].references;
        for (int colorIndex = 0; colorIndex < references.length; colorIndex++)
        {
          final int code = codec.encode(color: references[colorIndex]);
          expect(code, PaletteCodec.codeOf(rampIndex: rampIndex, colorIndex: colorIndex));
          expect(PaletteCodec.rampIndexOf(code: code), rampIndex);
          expect(PaletteCodec.colorIndexOf(code: code), colorIndex);
        }
      }
    });

    test("the largest possible palette still fits into 16 bits", ()
    {
      final int highest = PaletteCodec.codeOf(rampIndex: PaletteCodec.maxRamps - 1, colorIndex: KPalConstraints.colorCountMax - 1);
      expect(highest, lessThanOrEqualTo(0xFFFF));
      final Uint16List stored = Uint16List(1)..[0] = highest;
      expect(stored[0], highest, reason: "a Uint16List must hold the highest code unchanged");
    });

    test("a palette loaded from a file may exceed the ramps that can be added by hand", ()
    {
      //project and palette files store the ramp count in one byte
      final List<KPalRampData> many = List<KPalRampData>.generate(255, (final int i) => _ramp(uuid: "r$i", colorCount: 5));
      final PaletteCodec large = PaletteCodec(ramps: many);
      expect(many.length, greaterThan(KPalConstraints.rampCountMax));
      for (final ColorReference color in _allColors(ramps: many))
      {
        expect(large.decode(code: large.encode(color: color)), same(color));
      }
    });

    test("a color index past the end of its ramp is clamped", ()
    {
      final ColorReference beyond = ColorReference(colorIndex: a.references.length + 3, ramp: a);
      expect(codec.encode(color: beyond), codec.encode(color: a.references.last));
      expect(codec.decode(code: PaletteCodec.codeOf(rampIndex: 0, colorIndex: a.references.length + 3)), same(a.references.last));
    });

    test("a color of a ramp outside the palette asserts", ()
    {
      final KPalRampData foreign = _ramp(uuid: "foreign", colorCount: 5);
      expect(() => codec.encode(color: foreign.references.first), throwsA(isA<AssertionError>()));
      expect(() => codec.decode(code: PaletteCodec.codeOf(rampIndex: codec.ramps.length, colorIndex: 0)), throwsA(isA<AssertionError>()));
    });

    test("appending a ramp keeps every existing code", ()
    {
      final KPalRampData added = _ramp(uuid: "added", colorCount: 5);
      final PaletteCodec extended = codec.withRamp(ramp: added);
      expect(codec.withRamp(ramp: b), same(codec), reason: "a known ramp needs no new codec");
      expect(extended.indexOfRamp(ramp: added), codec.ramps.length);
      for (final ColorReference color in _allColors(ramps: codec.ramps))
      {
        expect(extended.encode(color: color), codec.encode(color: color));
      }
      expect(extended.decode(code: extended.encode(color: added.references[3])), same(added.references[3]));
    });

    test("removing a ramp moves the ones behind it up", ()
    {
      final PaletteCodec reduced = codec.withoutRamp(ramp: b);
      expect(reduced.ramps, <KPalRampData>[a, c]);
      expect(reduced.indexOfRamp(ramp: b), isNull);
      expect(reduced.indexOfRamp(ramp: c), 1);
      expect(reduced.withoutRamp(ramp: b), same(reduced), reason: "an unknown ramp needs no new codec");
    });

    test("a codec matches only the same ramps in the same order", ()
    {
      expect(codec.matches(ramps: <KPalRampData>[a, b, c]), isTrue, reason: "another list with the same ramps");
      expect(codec.matches(ramps: <KPalRampData>[a, c, b]), isFalse);
      expect(codec.matches(ramps: <KPalRampData>[a, b]), isFalse);
      expect(codec.matches(ramps: <KPalRampData>[a, b, _ramp(uuid: "c", colorCount: 7)]), isFalse,
          reason: "a ramp rebuilt with the same uuid is still a different ramp",);
    });
  });

  group("remapLut", ()
  {
    void expectColorsKept({required final Uint16List lut, required final PaletteCodec target, required final Iterable<ColorReference> kept})
    {
      expect(lut[PaletteCodec.transparent], PaletteCodec.transparent);
      for (final ColorReference color in kept)
      {
        expect(lut[codec.encode(color: color)], target.encode(color: color), reason: "color ${color.colorIndex} of ramp ${color.ramp.uuid}");
      }
    }

    test("follows a reorder", ()
    {
      final PaletteCodec target = PaletteCodec(ramps: <KPalRampData>[c, a, b]);
      expectColorsKept(lut: codec.remapLut(target: target), target: target, kept: _allColors(ramps: codec.ramps));
    });

    test("clears the colors of a deleted ramp and moves the ones behind it", ()
    {
      final PaletteCodec target = PaletteCodec(ramps: <KPalRampData>[a, c]);
      final Uint16List lut = codec.remapLut(target: target);
      expectColorsKept(lut: lut, target: target, kept: <ColorReference>[...a.references, ...c.references]);
      for (final ColorReference color in b.references)
      {
        expect(lut[codec.encode(color: color)], PaletteCodec.transparent);
      }
    });

    test("leaves every code alone when a ramp is appended", ()
    {
      final PaletteCodec target = PaletteCodec(ramps: <KPalRampData>[a, b, c, _ramp(uuid: "d", colorCount: 4)]);
      final Uint16List lut = codec.remapLut(target: target);
      for (final ColorReference color in _allColors(ramps: codec.ramps))
      {
        final int code = codec.encode(color: color);
        expect(lut[code], code);
      }
    });

    test("moves the colors of a ramp whose color count changed", ()
    {
      final KPalRampData shrinking = _ramp(uuid: "shrinking", colorCount: 7);
      final PaletteCodec before = PaletteCodec(ramps: <KPalRampData>[a, shrinking]);
      final List<int> codesBefore = <int>[for (final ColorReference color in shrinking.references) before.encode(color: color)];

      shrinking.settings.colorCount = 4;
      shrinking.updateColors(colorCountChanged: true);
      final HashMap<int, int> indexMap = remapIndices(oldLength: 7, newLength: 4);
      final PaletteCodec after = PaletteCodec(ramps: <KPalRampData>[a, shrinking]);
      final Uint16List lut = before.remapLut(target: after, colorIndexMaps: <KPalRampData, Map<int, int>>{shrinking: indexMap});

      for (int oldIndex = 0; oldIndex < codesBefore.length; oldIndex++)
      {
        expect(after.decode(code: lut[codesBefore[oldIndex]]), same(shrinking.references[indexMap[oldIndex]!]), reason: "old color $oldIndex");
      }
      for (final ColorReference color in a.references)
      {
        final int code = before.encode(color: color);
        expect(lut[code], code, reason: "the other ramp is not affected");
      }
    });

    test("maps through the closest colors when the palette is replaced", ()
    {
      final List<KPalRampData> replacement = <KPalRampData>[_ramp(uuid: "x", colorCount: 5), _ramp(uuid: "y", colorCount: 9)];
      final PaletteCodec target = PaletteCodec(ramps: replacement);
      final HashMap<ColorReference, ColorReference> colorMap = getRampMap(rampList1: codec.ramps, rampList2: replacement);
      final Uint16List lut = codec.remapLutByColor(target: target, colorMap: colorMap);

      expect(lut[PaletteCodec.transparent], PaletteCodec.transparent);
      for (final ColorReference color in _allColors(ramps: codec.ramps))
      {
        expect(target.decode(code: lut[codec.encode(color: color)]), same(colorMap[color]));
      }
    });

    test("clears a color the replacement map does not cover", ()
    {
      final PaletteCodec target = PaletteCodec(ramps: <KPalRampData>[c]);
      final Uint16List lut = codec.remapLutByColor(target: target, colorMap: <ColorReference, ColorReference>{a.references.first: c.references.first});
      expect(lut[codec.encode(color: a.references.first)], target.encode(color: c.references.first));
      expect(lut[codec.encode(color: a.references.last)], PaletteCodec.transparent);
    });
  });

  group("rgbaLut", ()
  {
    test("holds the same values as RgbaCache", ()
    {
      final Uint32List lut = codec.rgbaLut();
      final RgbaCache cache = RgbaCache();
      expect(lut.length, codec.codeCount);
      expect(lut[PaletteCodec.transparent], 0, reason: "an empty pixel stays fully transparent");
      for (final ColorReference color in _allColors(ramps: codec.ramps))
      {
        expect(lut[codec.encode(color: color)], cache.rgbaOf(reference: color));
      }
    });

    test("shows the colors as they were when it was built", ()
    {
      final KPalRampData shifted = _ramp(uuid: "shifted", colorCount: 5);
      final PaletteCodec shiftedCodec = PaletteCodec(ramps: <KPalRampData>[shifted]);
      final int code = shiftedCodec.encode(color: shifted.references[2]);
      final Uint32List before = shiftedCodec.rgbaLut();
      final int oldValue = before[code];

      shifted.shifts[2].hueShiftNotifier.value = 40;
      final Uint32List after = shiftedCodec.rgbaLut();

      expect(after[code], isNot(oldValue), reason: "setup: the shift changed the color");
      expect(after[code], RgbaCache().rgbaOf(reference: shifted.references[2]));
      expect(before[code], oldValue, reason: "a table already built keeps its values");
    });
  });

  testWidgets("the palette's codec follows a reorder and the old one keeps the old order", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 4), body: (final ProjectSession projectSession) async
    {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final PaletteCodec before = palette.codec;
      expect(palette.codec, same(before), reason: "an unchanged palette keeps its codec");

      final KPalRampData moved = palette.colorRamps.first;
      palette.changeColorOrder(ramp: moved, newPosition: 2);
      await settle();
      expect(palette.colorRamps.indexOf(moved), 1, reason: "setup: the first ramp moved one place back");

      final PaletteCodec after = palette.codec;
      expect(after, isNot(same(before)));
      expect(after.encode(color: moved.references.first), PaletteCodec.codeOf(rampIndex: 1, colorIndex: 0));
      expect(before.encode(color: moved.references.first), PaletteCodec.codeOf(rampIndex: 0, colorIndex: 0),
          reason: "codes already written with the old codec must keep their meaning",);
      expect(before.remapLut(target: after)[PaletteCodec.codeOf(rampIndex: 0, colorIndex: 0)], PaletteCodec.codeOf(rampIndex: 1, colorIndex: 0));
    },);
  });
}
