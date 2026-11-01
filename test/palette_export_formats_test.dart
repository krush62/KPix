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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/format_readers.dart';
import 'support/selection_harness.dart';

const String _plainName = "Salmon Dark";
const String _markupName = "Salmon & \"Co\" <1> 'x'";
const String _escapedMarkupName = "Salmon &amp; &quot;Co&quot; &lt;1&gt; &apos;x&apos;";

class _FixedNames extends ColorNames
{
  final String name;
  _FixedNames({required this.name}) : super(scheme: ColorNameScheme.general);

  @override
  String getColorName({required final double r, required final double g, required final double b}) => name;
}

List<KPalRampData> _ramps()
{
  return <KPalRampData>[
    KPalRampData(uuid: "warm", settings: KPalRampSettings()..colorCount = 3..baseHue = 10),
    KPalRampData(uuid: "cold", settings: KPalRampSettings()..colorCount = 4..baseHue = 200),
  ];
}

/// Every color of [ramps] in file order.
List<Color> _colors({required final List<KPalRampData> ramps})
{
  return <Color>[
    for (final KPalRampData ramp in ramps)
      for (final ColorReference reference in ramp.references) reference.getIdColor().color,
  ];
}

int _byte(final double channel) => (channel * 255.0).round();

List<int> _channels({required final Color color}) => <int>[_byte(color.r), _byte(color.g), _byte(color.b)];

int _rgb({required final Color color}) => (_byte(color.r) << 16) | (_byte(color.g) << 8) | _byte(color.b);

List<String> _lines({required final Uint8List bytes}) => const LineSplitter().convert(utf8.decode(bytes));

void _paletteTest(final String description, final Future<void> Function(List<KPalRampData> ramps) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 2, y: 2), body: (final ProjectSession projectSession) async
    {
      await body(_ramps());
    },);
  });
}

void main()
{
  group("jasc", ()
  {
    _paletteTest("holds the header and every color in order", (final List<KPalRampData> ramps) async
    {
      final List<String> lines = _lines(bytes: await getPaletteJascData(rampList: ramps));
      final List<Color> colors = _colors(ramps: ramps);

      expect(lines.take(3), <String>["JASC-PAL", "0100", "${colors.length}"]);
      expect(lines.skip(3), colors.map((final Color c) => _channels(color: c).join(" ")));
    });
  });

  group("gimp", ()
  {
    _paletteTest("holds the header and every color with its name", (final List<KPalRampData> ramps) async
    {
      final List<String> lines = _lines(bytes: await getPaletteGimpData(rampList: ramps, colorNames: _FixedNames(name: _plainName)));

      expect(lines[0], "GIMP Palette");
      expect(lines[1], matches(RegExp(r"^Name: KPix_[0-9_.]+$")));
      expect(lines[2], "Columns: 16");
      expect(lines[3], "#");
      expect(lines.skip(4), _colors(ramps: ramps).map((final Color c) => "${_channels(color: c).join(" ")} $_plainName"));
    });
  });

  group("paint.net", ()
  {
    _paletteTest("holds a comment and every color as upper case hex with its name", (final List<KPalRampData> ramps) async
    {
      final List<String> lines = _lines(bytes: await getPalettePaintNetData(rampList: ramps, colorNames: _FixedNames(name: _plainName)));
      final List<Color> colors = _colors(ramps: ramps);

      expect(lines.first, startsWith("; KPix_"));
      expect(lines.length, colors.length + 1);
      for (int i = 0; i < colors.length; i++)
      {
        final String hex = _rgb(color: colors[i]).toRadixString(16).padLeft(6, "0").toUpperCase();
        expect(lines[i + 1], "$hex ; $i-$_plainName");
      }
    });
  });

  group("corel", ()
  {
    _paletteTest("holds every color with its tints and escaped name", (final List<KPalRampData> ramps) async
    {
      final String text = utf8.decode(await getPaletteCorelData(rampList: ramps, colorNames: _FixedNames(name: _markupName)));
      final List<Color> colors = _colors(ramps: ramps);

      final List<RegExpMatch> entries = RegExp('<color cs="RGB" tints="([0-9.]+),([0-9.]+),([0-9.]+)" name="([^"]*)" />').allMatches(text).toList();
      expect(entries, hasLength(colors.length));
      for (int i = 0; i < colors.length; i++)
      {
        expect(double.parse(entries[i].group(1)!), closeTo(colors[i].r, 0.000001));
        expect(double.parse(entries[i].group(2)!), closeTo(colors[i].g, 0.000001));
        expect(double.parse(entries[i].group(3)!), closeTo(colors[i].b, 0.000001));
        expect(entries[i].group(4), _escapedMarkupName);
      }
    });
  });

  group("open office", ()
  {
    _paletteTest("holds every color as lower case hex with its escaped name", (final List<KPalRampData> ramps) async
    {
      final String text = utf8.decode(await getPaletteOpenOfficeData(rampList: ramps, colorNames: _FixedNames(name: _markupName)));
      final List<Color> colors = _colors(ramps: ramps);

      expect(text, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(text.trim(), endsWith("</office:color-table>"));
      final List<RegExpMatch> entries = RegExp('<draw:color draw:name="([^"]*)" draw:color="(#[0-9a-f]{6})"/>').allMatches(text).toList();
      expect(entries, hasLength(colors.length));
      for (int i = 0; i < colors.length; i++)
      {
        expect(entries[i].group(1), _escapedMarkupName);
        expect(entries[i].group(2), "#${_rgb(color: colors[i]).toRadixString(16).padLeft(6, "0")}");
      }
    });
  });

  group("pixelorama", ()
  {
    _paletteTest("is valid json with every color and its index", (final List<KPalRampData> ramps) async
    {
      final Map<String, dynamic> json = jsonDecode(utf8.decode(await getPaletteJsonData(rampList: ramps))) as Map<String, dynamic>;
      final List<dynamic> entries = json["colors"] as List<dynamic>;
      final List<Color> colors = _colors(ramps: ramps);

      expect(entries, hasLength(colors.length));
      for (int i = 0; i < colors.length; i++)
      {
        final Map<String, dynamic> entry = entries[i] as Map<String, dynamic>;
        expect(entry["index"], i);
        final RegExpMatch match = RegExp(r"^\(([0-9.e-]+), ([0-9.e-]+), ([0-9.e-]+), 1\)$").firstMatch(entry["color"] as String)!;
        expect(double.parse(match.group(1)!), closeTo(colors[i].r, 0.000001));
        expect(double.parse(match.group(2)!), closeTo(colors[i].g, 0.000001));
        expect(double.parse(match.group(3)!), closeTo(colors[i].b, 0.000001));
      }
    });
  });

  group("png", ()
  {
    _paletteTest("is one opaque pixel per color", (final List<KPalRampData> ramps) async
    {
      final img.Image image = img.decodePng((await getPalettePngData(ramps: ramps))!)!;
      final List<Color> colors = _colors(ramps: ramps);

      expect(image.width, colors.length);
      expect(image.height, 1);
      for (int i = 0; i < colors.length; i++)
      {
        final img.Pixel pixel = image.getPixel(i, 0);
        expect(<int>[pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()], _channels(color: colors[i]), reason: "color $i");
        expect(pixel.a, 255, reason: "color $i");
      }
    });
  });

  group("aseprite", ()
  {
    _paletteTest("puts black first as the transparent color and shows every color once", (final List<KPalRampData> ramps) async
    {
      final AsepriteFile file = readAseprite(bytes: (await getPaletteAsepriteData(rampList: ramps))!);
      final List<int> colors = _colors(ramps: ramps).map((final Color c) => _rgb(color: c)).toList();

      expect(file.palette, <int>[0x000000, ...colors]);
      expect(file.oldPalette, file.palette);
      expect(file.transparentIndex, 0);
      expect(file.width, colors.length + 1);
      expect(file.height, 1);
      expect(file.celIndices.single, List<int>.generate(colors.length + 1, (final int i) => i));
    });

    //black takes one of the 255 places, so this is one color too many
    _paletteTest("refuses a palette with more colors than an index holds", (final List<KPalRampData> ramps) async
    {
      final List<KPalRampData> tooMany = <KPalRampData>[for (int i = 0; i < 17; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()..colorCount = 15)];

      expect(await getPaletteAsepriteData(rampList: tooMany), isNull);
    });

    _paletteTest("takes a palette that just fits", (final List<KPalRampData> ramps) async
    {
      final List<KPalRampData> fitting = <KPalRampData>[for (int i = 0; i < 17; i++) KPalRampData(uuid: "ramp $i", settings: KPalRampSettings()..colorCount = i == 0 ? 14 : 15)];

      final AsepriteFile file = readAseprite(bytes: (await getPaletteAsepriteData(rampList: fitting))!);

      expect(file.palette, hasLength(255));
    });
  });

  group("adobe", ()
  {
    _paletteTest("holds every color as rgb floats with its name", (final List<KPalRampData> ramps) async
    {
      final List<AdobeColor> entries = readAdobePalette(bytes: await getPaletteAdobeData(rampList: ramps, colorNames: _FixedNames(name: _plainName)));
      final List<Color> colors = _colors(ramps: ramps);

      expect(entries, hasLength(colors.length));
      for (int i = 0; i < colors.length; i++)
      {
        expect(entries[i].name, _plainName);
        expect(entries[i].model, "RGB ");
        expect(entries[i].type, 0);
        expect(entries[i].red, closeTo(colors[i].r, 0.000001));
        expect(entries[i].green, closeTo(colors[i].g, 0.000001));
        expect(entries[i].blue, closeTo(colors[i].b, 0.000001));
      }
    });

    _paletteTest("leaves hyphens out of a name and stays readable", (final List<KPalRampData> ramps) async
    {
      final List<AdobeColor> entries = readAdobePalette(bytes: await getPaletteAdobeData(rampList: ramps, colorNames: _FixedNames(name: "3713-Salmon-Light")));
      final List<Color> colors = _colors(ramps: ramps);

      expect(entries, hasLength(colors.length));
      for (int i = 0; i < colors.length; i++)
      {
        expect(entries[i].name, "3713SalmonLight");
        expect(entries[i].red, closeTo(colors[i].r, 0.000001));
      }
    });
  });

  group("color names", ()
  {
    testWidgets("are used once the scheme has loaded", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 2, y: 2), body: (final ProjectSession projectSession) async
      {
        final ColorNames names = ColorNames(scheme: ColorNameScheme.ralClassic);
        for (int i = 0; i < 200 && !names.colorsLoaded; i++)
        {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(names.colorsLoaded, isTrue, reason: "setup");
        final List<KPalRampData> ramps = _ramps();

        final List<String> lines = _lines(bytes: await getPaletteGimpData(rampList: ramps, colorNames: names));

        for (final String line in lines.skip(4))
        {
          expect(line, isNot(contains(noColorName)));
        }
      },);
    });

    testWidgets("are marked as unknown until then, and escaped like any other", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 2, y: 2), body: (final ProjectSession projectSession) async
      {
        final ColorNames names = ColorNames(scheme: ColorNameScheme.ralClassic);
        expect(names.colorsLoaded, isFalse, reason: "setup");

        final String text = utf8.decode(await getPaletteOpenOfficeData(rampList: _ramps(), colorNames: names));

        expect(text, contains('draw:name="&lt;UNKNOWN&gt;"'));
      },);
    });
  });
}
