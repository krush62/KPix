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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/history/history_shift_set.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_manager_data.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/app_directories.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/export_handler.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/import/import_palette.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'support/project_files.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 4, y: 4);

String get _palettesDir => p.join(GetIt.I.get<AppPaths>().internalDir, palettesSubDirName);

String _nameOf(final PaletteManagerEntryData palette) => palette.displayName(l10n: lookupAppLocalizations(const Locale("en")));

/// One ramp of a kpal file, written byte by byte as the format defines it, so a
/// test can say things the exporter never would.
class _Ramp
{
  int nameLength = 0;
  int colorCount = 3;
  int baseHue = 200;
  int baseSat = 50;
  int hueShift = -10;
  double hueShiftExp = 1.5;
  int satShift = 5;
  double satShiftExp = 0.75;
  int valueMin = 20;
  int valueMax = 80;
  int shiftHue = 0;
  int shiftSat = 0;
  int shiftVal = 0;
  List<(int, int)> options = const <(int, int)>[];

  void write(final BytesBuilder out)
  {
    final ByteData scratch = ByteData(4);
    void int16(final int value)
    {
      scratch.setInt16(0, value, Endian.little);
      out.add(scratch.buffer.asUint8List(0, 2));
    }
    void float32(final double value)
    {
      scratch.setFloat32(0, value, Endian.little);
      out.add(scratch.buffer.asUint8List(0, 4));
    }
    out.addByte(nameLength);
    out.add(Uint8List(nameLength));
    out.addByte(colorCount);
    int16(baseHue);
    int16(baseSat);
    out.addByte(hueShift & 0xFF);
    float32(hueShiftExp);
    out.addByte(satShift & 0xFF);
    float32(satShiftExp);
    out.addByte(valueMin);
    out.addByte(valueMax);
    for (int i = 0; i < colorCount; i++)
    {
      out.addByte(shiftHue & 0xFF);
      out.addByte(shiftSat & 0xFF);
      out.addByte(shiftVal & 0xFF);
    }
    out.addByte(options.length);
    for (final (int type, int value) in options)
    {
      out.addByte(type);
      out.addByte(value);
    }
  }
}

Uint8List _kpalFile({required final List<_Ramp> ramps, final int optionCount = 0})
{
  final BytesBuilder out = BytesBuilder();
  out.addByte(optionCount);
  out.add(Uint8List(optionCount * 2));
  out.addByte(ramps.length);
  for (final _Ramp ramp in ramps)
  {
    ramp.write(out);
  }
  return out.takeBytes();
}

void _writePalette({required final String name, required final List<int> bytes})
{
  File(p.join(_palettesDir, name)).writeAsBytesSync(bytes);
}

/// A ramp with every value away from its default, and the shifts of its colors
/// away from zero; both have to survive a round trip.
KPalRampData _customRamp({required final SatCurve satCurve})
{
  return KPalRampData(
    uuid: "custom",
    settings: KPalRampSettings()
      ..colorCount = 4
      ..baseHue = 300
      ..baseSat = 77
      ..hueShift = -33
      ..hueShiftExp = 1.5
      ..satShift = -7
      ..satShiftExp = 0.75
      ..valueRangeMin = 11
      ..valueRangeMax = 88
      ..satCurve = satCurve,
    historyShifts: <HistoryShiftSet>[
      HistoryShiftSet(hueShift: -50, satShift: 25, valShift: -25),
      HistoryShiftSet(hueShift: 50, satShift: -25, valShift: 25),
      HistoryShiftSet(hueShift: 1, satShift: 2, valShift: 3),
      HistoryShiftSet(hueShift: -1, satShift: -2, valShift: -3),
    ],
  );
}

void _expectEqualRamps({required final KPalRampData actual, required final KPalRampData expected})
{
  expect(actual.settings.colorCount, expected.settings.colorCount);
  expect(actual.settings.baseHue, expected.settings.baseHue);
  expect(actual.settings.baseSat, expected.settings.baseSat);
  expect(actual.settings.hueShift, expected.settings.hueShift);
  expect(actual.settings.hueShiftExp, expected.settings.hueShiftExp);
  expect(actual.settings.satShift, expected.settings.satShift);
  expect(actual.settings.satShiftExp, expected.settings.satShiftExp);
  expect(actual.settings.valueRangeMin, expected.settings.valueRangeMin);
  expect(actual.settings.valueRangeMax, expected.settings.valueRangeMax);
  for (int i = 0; i < expected.settings.colorCount; i++)
  {
    expect(actual.shifts[i].hueShiftNotifier.value, expected.shifts[i].hueShiftNotifier.value, reason: "color $i");
    expect(actual.shifts[i].satShiftNotifier.value, expected.shifts[i].satShiftNotifier.value, reason: "color $i");
    expect(actual.shifts[i].valShiftNotifier.value, expected.shifts[i].valShiftNotifier.value, reason: "color $i");
  }
}

void _paletteTest(final String description, final Future<void> Function() body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
    {
      await createInternalDirectories();
      await body();
    },);
  });
}

void main()
{
  group("saving and loading", ()
  {
    _paletteTest("keeps every setting and shift of every ramp", () async
    {
      final List<KPalRampData> ramps = <KPalRampData>[_customRamp(satCurve: SatCurve.noFlat), KPalRampData(uuid: "plain", settings: KPalRampSettings())];
      _writePalette(name: "saved.$fileExtensionKpal", bytes: await createPaletteKPalData(rampList: ramps));

      final List<PaletteManagerEntryData> palettes = await loadPalettesFromInternal();

      expect(palettes, hasLength(1));
      expect(palettes.single.rampDataList, hasLength(2));
      _expectEqualRamps(actual: palettes.single.rampDataList[0], expected: ramps[0]);
      _expectEqualRamps(actual: palettes.single.rampDataList[1], expected: ramps[1]);
    });

    _paletteTest("names a saved palette after its file and leaves it unlocked", () async
    {
      final String path = p.join(_palettesDir, "my colors.$fileExtensionKpal");
      _writePalette(name: "my colors.$fileExtensionKpal", bytes: await createPaletteKPalData(rampList: GetIt.I.get<PaletteState>().colorRamps));

      final PaletteManagerEntryData palette = (await loadPalettesFromInternal()).single;

      expect(_nameOf(palette), "my colors");
      expect(palette.isLocked, isFalse);
      expect(palette.path, File(path).absolute.path);
    });

    _paletteTest("saving the current palette writes all of its ramps", () async
    {
      final List<KPalRampData> ramps = <KPalRampData>[_customRamp(satCurve: SatCurve.noFlat)];
      GetIt.I.get<PaletteState>().colorRamps = ramps;

      final String? path = await saveCurrentPalette(fileName: "current", directory: _palettesDir, extension: fileExtensionKpal);

      expect(path, p.join(_palettesDir, "current.$fileExtensionKpal"));
      _expectEqualRamps(actual: (await loadPalettesFromInternal()).single.rampDataList.single, expected: ramps.single);
    });

    for (final SatCurve curve in SatCurve.values)
    {
      _paletteTest("keeps the saturation curve ${curve.name}", () async
      {
        _writePalette(name: "saved.$fileExtensionKpal", bytes: await createPaletteKPalData(rampList: <KPalRampData>[_customRamp(satCurve: curve)]));

        final PaletteManagerEntryData palette = (await loadPalettesFromInternal()).single;

        expect(palette.rampDataList.single.settings.satCurve, curve);
      });
    }

    //the ids of the original KPal, so that it can read what is saved here
    for (final (SatCurve curve, int id) mapping in <(SatCurve, int)>[(SatCurve.darkFlat, 0), (SatCurve.noFlat, 1), (SatCurve.linear, 2), (SatCurve.brightFlat, 3)])
    {
      _paletteTest("writes the saturation curve ${mapping.$1.name} as id ${mapping.$2}", () async
      {
        final Uint8List bytes = await createPaletteKPalData(rampList: <KPalRampData>[_customRamp(satCurve: mapping.$1)]);

        //the curve is the last ramp option, followed only by the link count
        expect(bytes[bytes.length - 2], mapping.$2);
      });
    }
  });

  group("reading a file", ()
  {
    _paletteTest("takes the values it finds", () async
    {
      _writePalette(name: "made.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[
        _Ramp()
          ..shiftHue = -50
          ..shiftSat = 25
          ..shiftVal = -25,
      ],),);

      final KPalRampData ramp = (await loadPalettesFromInternal()).single.rampDataList.single;

      expect(ramp.settings.colorCount, 3);
      expect(ramp.settings.baseHue, 200);
      expect(ramp.settings.baseSat, 50);
      expect(ramp.settings.hueShift, -10);
      expect(ramp.settings.hueShiftExp, 1.5);
      expect(ramp.settings.satShift, 5);
      expect(ramp.settings.satShiftExp, 0.75);
      expect(ramp.settings.valueRangeMin, 20);
      expect(ramp.settings.valueRangeMax, 80);
      for (final ShiftSet shift in ramp.shifts.take(ramp.settings.colorCount))
      {
        expect(shift.hueShiftNotifier.value, -50);
        expect(shift.satShiftNotifier.value, 25);
        expect(shift.valShiftNotifier.value, -25);
      }
    });

    _paletteTest("skips options and names it has no use for", () async
    {
      _writePalette(name: "made.$fileExtensionKpal", bytes: _kpalFile(optionCount: 3, ramps: <_Ramp>[
        _Ramp()
          ..nameLength = 12
          ..options = const <(int, int)>[(7, 9), (1, 2), (8, 1)],
      ],),);

      final KPalRampData ramp = (await loadPalettesFromInternal()).single.rampDataList.single;

      expect(ramp.settings.baseHue, 200, reason: "the fields behind the skipped bytes still line up");
      expect(ramp.settings.satCurve, SatCurve.linear);
    });

    //the ids of the original KPal, which the bundled palettes use
    for (final (int id, SatCurve curve) mapping in <(int, SatCurve)>[(0, SatCurve.darkFlat), (1, SatCurve.noFlat), (2, SatCurve.linear), (3, SatCurve.brightFlat)])
    {
      _paletteTest("reads saturation curve id ${mapping.$1} as ${mapping.$2.name}", () async
      {
        _writePalette(name: "made.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp()..options = <(int, int)>[(1, mapping.$1)]]));

        expect((await loadPalettesFromInternal()).single.rampDataList.single.settings.satCurve, mapping.$2);
      });
    }

    _paletteTest("takes an unknown saturation curve as the default", () async
    {
      _writePalette(name: "made.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp()..options = const <(int, int)>[(1, 99)]]));

      expect((await loadPalettesFromInternal()).single.rampDataList.single.settings.satCurve, SatCurve.noFlat);
    });

    _paletteTest("clamps exponents that are only barely out of range", () async
    {
      _writePalette(name: "made.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[
        _Ramp()
          ..hueShiftExp = KPalConstraints.hueShiftExpMax + fileFloatDelta / 2
          ..satShiftExp = KPalConstraints.satShiftExpMin - fileFloatDelta / 2,
      ],),);

      final KPalRampData ramp = (await loadPalettesFromInternal()).single.rampDataList.single;

      expect(ramp.settings.hueShiftExp, KPalConstraints.hueShiftExpMax);
      expect(ramp.settings.satShiftExp, KPalConstraints.satShiftExpMin);
    });

    for (final (String name, void Function(_Ramp) breakIt) invalid in <(String, void Function(_Ramp))>[
      ("too few colors", (final _Ramp r) => r.colorCount = KPalConstraints.colorCountMin - 1),
      ("too many colors", (final _Ramp r) => r.colorCount = KPalConstraints.colorCountMax + 1),
      ("base hue", (final _Ramp r) => r.baseHue = KPalConstraints.baseHueMax + 1),
      ("base sat", (final _Ramp r) => r.baseSat = KPalConstraints.baseSatMax + 1),
      ("hue shift", (final _Ramp r) => r.hueShift = KPalConstraints.hueShiftMax + 1),
      ("hue shift exponent", (final _Ramp r) => r.hueShiftExp = KPalConstraints.hueShiftExpMax + 1.0),
      ("sat shift", (final _Ramp r) => r.satShift = KPalConstraints.satShiftMin - 1),
      ("sat shift exponent", (final _Ramp r) => r.satShiftExp = KPalConstraints.satShiftExpMin - 0.25),
      ("value minimum above maximum", (final _Ramp r) => r..valueMin = 60..valueMax = 40),
      ("value maximum", (final _Ramp r) => r.valueMax = KPalConstraints.valueRangeMax + 1),
      ("color hue shift", (final _Ramp r) => r.shiftHue = KPalSliderConstraints.maxHue + 1),
      ("color sat shift", (final _Ramp r) => r.shiftSat = KPalSliderConstraints.minSat - 1),
      ("color val shift", (final _Ramp r) => r.shiftVal = KPalSliderConstraints.maxVal + 1),
    ])
    {
      _paletteTest("drops a palette with an invalid ${invalid.$1} and keeps the others", () async
      {
        final _Ramp broken = _Ramp();
        invalid.$2(broken);
        _writePalette(name: "broken.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp(), broken]));
        _writePalette(name: "fine.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp()]));

        final List<PaletteManagerEntryData> palettes = await loadPalettesFromInternal();

        expect(palettes.map(_nameOf), <String>["fine"]);
      });
    }

    _paletteTest("drops a palette without ramps", () async
    {
      _writePalette(name: "empty.$fileExtensionKpal", bytes: _kpalFile(ramps: const <_Ramp>[]));

      expect(await loadPalettesFromInternal(), isEmpty);
    });

    _paletteTest("drops a truncated palette and keeps the others", () async
    {
      final Uint8List whole = _kpalFile(ramps: <_Ramp>[_Ramp()]);
      _writePalette(name: "broken.$fileExtensionKpal", bytes: Uint8List.sublistView(whole, 0, whole.length ~/ 2));
      _writePalette(name: "fine.$fileExtensionKpal", bytes: whole);

      final List<PaletteManagerEntryData> palettes = await loadPalettesFromInternal();

      expect(palettes.map(_nameOf), <String>["fine"]);
    });

    _paletteTest("drops an empty file and keeps the others", () async
    {
      _writePalette(name: "broken.$fileExtensionKpal", bytes: const <int>[]);
      _writePalette(name: "fine.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp()]));

      final List<PaletteManagerEntryData> palettes = await loadPalettesFromInternal();

      expect(palettes.map(_nameOf), <String>["fine"]);
    });

    _paletteTest("ignores other files and sub directories", () async
    {
      _writePalette(name: "notes.txt", bytes: const <int>[1, 2, 3]);
      Directory(p.join(_palettesDir, "folder.$fileExtensionKpal")).createSync();
      _writePalette(name: "fine.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp()]));

      final List<PaletteManagerEntryData> palettes = await loadPalettesFromInternal();

      expect(palettes.map(_nameOf), <String>["fine"]);
    });

    testWidgets("finds nothing without a palettes directory", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
      {
        expect(await loadPalettesFromInternal(), isEmpty);
      },);
    });
  });

  group("importing a file", ()
  {
    String outside({required final String name}) => p.join(GetIt.I.get<AppPaths>().exportDir, name);

    _paletteTest("without a path was cancelled", () async
    {
      expect(await importPalette(path: null), PaletteImportResult.cancelled);
      expect(await importPalette(path: ""), PaletteImportResult.cancelled);
    });

    _paletteTest("refuses another file type without opening it", () async
    {
      expect(await importPalette(path: outside(name: "does not exist.png")), PaletteImportResult.notAKPalFile);
    });

    _paletteTest("adds the palette to the saved ones and leaves the source alone", () async
    {
      final List<int> bytes = _kpalFile(ramps: <_Ramp>[_Ramp()]);
      final File source = File(outside(name: "picked.$fileExtensionKpal"))..writeAsBytesSync(bytes);

      expect(await importPalette(path: source.path), PaletteImportResult.success);

      expect(source.existsSync(), isTrue);
      expect(File(p.join(_palettesDir, "picked.$fileExtensionKpal")).readAsBytesSync(), bytes);
      expect((await loadPalettesFromInternal()).map(_nameOf), <String>["picked"]);
    });

    _paletteTest("does not overwrite a palette of the same name", () async
    {
      _writePalette(name: "taken.$fileExtensionKpal", bytes: _kpalFile(ramps: <_Ramp>[_Ramp()..baseHue = 111]));
      final File source = File(outside(name: "taken.$fileExtensionKpal"))..writeAsBytesSync(_kpalFile(ramps: <_Ramp>[_Ramp()..baseHue = 222]));

      expect(await importPalette(path: source.path), PaletteImportResult.paletteAlreadyExists);

      expect((await loadPalettesFromInternal()).single.rampDataList.single.settings.baseHue, 111);
    });

    for (final (String condition, List<int> Function() bytes) damaged in <(String, List<int> Function())>[
      ("empty", () => const <int>[]),
      ("truncated", ()
      {
        final Uint8List whole = _kpalFile(ramps: <_Ramp>[_Ramp()]);
        return Uint8List.sublistView(whole, 0, whole.length ~/ 2);
      }),
      ("holding an invalid value", () => _kpalFile(ramps: <_Ramp>[_Ramp()..baseHue = KPalConstraints.baseHueMax + 1])),
      ("without ramps", () => _kpalFile(ramps: const <_Ramp>[])),
    ])
    {
      _paletteTest("fails for a file ${damaged.$1} and adds nothing", () async
      {
        final File source = File(outside(name: "broken.$fileExtensionKpal"))..writeAsBytesSync(damaged.$2());

        expect(await importPalette(path: source.path), PaletteImportResult.failed);

        expect(Directory(_palettesDir).listSync(), isEmpty);
      });
    }

    _paletteTest("fails for a file that is not there", () async
    {
      expect(await importPalette(path: outside(name: "gone.$fileExtensionKpal")), PaletteImportResult.failed);
      expect(Directory(_palettesDir).listSync(), isEmpty);
    });

    testWidgets("fails without a palettes directory to write to", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, appPaths: createTestPaths(), body: (final ProjectSession projectSession) async
      {
        final File source = File(outside(name: "picked.$fileExtensionKpal"))..writeAsBytesSync(_kpalFile(ramps: <_Ramp>[_Ramp()]));

        expect(await importPalette(path: source.path), PaletteImportResult.failed);
      },);
    });

    //a file picked from a phone over MTP arrives read-only on Windows, and File.copy
    //would pass that on to a palette that could then never be deleted
    _paletteTest("leaves the copy of a read-only file writable", () async
    {
      final File source = File(outside(name: "picked.$fileExtensionKpal"))..writeAsBytesSync(_kpalFile(ramps: <_Ramp>[_Ramp()]));
      await setReadOnly(path: source.path, readOnly: true);
      try
      {
        if (Platform.isWindows)
        {
          expect(() => source.writeAsBytesSync(<int>[1]), throwsA(isA<FileSystemException>()), reason: "setup: the source is read-only");
        }

        expect(await importPalette(path: source.path), PaletteImportResult.success);

        final File copy = File(p.join(_palettesDir, "picked.$fileExtensionKpal"));
        expect(() => copy.writeAsBytesSync(<int>[1]), returnsNormally);
        expect(() => copy.deleteSync(), returnsNormally);
      }
      finally
      {
        await setReadOnly(path: source.path, readOnly: false);
      }
    });
  });

  group("bundled palettes", ()
  {
    _paletteTest("all load, locked and named after their files", () async
    {
      final List<PaletteManagerEntryData> palettes = await loadPalettesFromAssets();

      expect(palettes, hasLength(12));
      expect(palettes.map(_nameOf), containsAll(<String>["[Apollo]", "[Gothic Bit]", "[RGB 62]", "[Sunset]"]));
      for (final PaletteManagerEntryData palette in palettes)
      {
        expect(palette.isLocked, isTrue, reason: _nameOf(palette));
        expect(palette.rampDataList, isNotEmpty, reason: _nameOf(palette));
        for (final KPalRampData ramp in palette.rampDataList)
        {
          expect(ramp.settings.colorCount, inInclusiveRange(KPalConstraints.colorCountMin, KPalConstraints.colorCountMax), reason: _nameOf(palette));
          expect(ramp.references, hasLength(ramp.settings.colorCount), reason: _nameOf(palette));
        }
      }
    });
  });
}
