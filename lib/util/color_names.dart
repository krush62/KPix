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

import 'package:flutter/services.dart';
import 'package:kpix/util/helper.dart';

enum ColorNameScheme
{
  general,
  pms,
  ralClassic,
  ralComplete,
  ralDsp,
  dmc
}

const String noColorName = "<UNKNOWN>";

const Map<int, ColorNameScheme> colorNameSchemeMap =
<int, ColorNameScheme>{
  0: ColorNameScheme.general,
  1: ColorNameScheme.pms,
  2: ColorNameScheme.ralClassic,
  3: ColorNameScheme.ralComplete,
  4: ColorNameScheme.ralDsp,
  5: ColorNameScheme.dmc,
};

const Map<ColorNameScheme, String> _colorNameFileNames =
<ColorNameScheme, String>{
  ColorNameScheme.general: "general.csv",
  ColorNameScheme.pms: "pms.csv",
  ColorNameScheme.ralClassic : "ral_classic.csv",
  ColorNameScheme.ralComplete : "ral_complete.csv",
  ColorNameScheme.ralDsp : "ral_dsp.csv",
  ColorNameScheme.dmc : "dmc.csv",
};

class ColorNamesOptions{
  final int defaultNameScheme;
  final String defaultColorNamePath;

  ColorNameScheme nameScheme = ColorNameScheme.general;
  String colorNamePath = "color_names";
  String colorFilename = "general.csv";

  ColorNamesOptions({
    required this.defaultNameScheme,
    required this.defaultColorNamePath,
  })
  {
    nameScheme = colorNameSchemeMap[defaultNameScheme] ?? ColorNameScheme.general;
    colorNamePath = defaultColorNamePath;
    colorFilename = _colorNameFileNames[nameScheme] ?? "general.csv";

  }
}

class NamedColor
{
  final String name;
  final int r;
  final int g;
  final int b;

  NamedColor({
    required this.name,
    required this.r,
    required this.g,
    required this.b,
  });
}

class ColorNames
{
  final ColorNamesOptions options;
  List<NamedColor> colorList = <NamedColor>[];
  bool colorsLoaded = false;

  void _processColorData({required final String data})
  {
    const LineSplitter ls = LineSplitter();
    final List<String> lines = ls.convert(data);
    for(final String line in lines)
    {
      _processLine(line: line);
    }
    colorsLoaded = true;
  }


  ColorNames({required this.options})
  {
    rootBundle.loadString("${options.colorNamePath}/${options.colorFilename}").then((final String value) {
      _processColorData(data: value);
    });
  }

  void _processLine({required final String line})
  {
    final List<String> split = line.split(';');
    if (split.length == 2 && split[1].length == 6)
    {
      final String name = split[0];
      final String hex = split[1];
      final int red = int.parse(hex.substring(0, 2), radix: 16);
      final int green = int.parse(hex.substring(2, 4), radix: 16);
      final int blue = int.parse(hex.substring(4, 6), radix: 16);
      colorList.add(NamedColor(name: name, r: red, g: green, b: blue));
    }
  }

  String getColorName({required final int r, required final int g, required final int b})
  {
    String bestName = noColorName;
    if (colorsLoaded) {
      double bestDelta = 100;
      for (final NamedColor c in colorList) {
        if (r == c.r && g == c.g && b == c.b) {
          bestName = c.name;
          bestDelta = 0.0;
          break;
        }
        else {
          final double delta = getDeltaE(redA: r, greenA: g, blueA: b, redB: c.r, greenB: c.g, blueB: c.b);
          if (delta < bestDelta) {
            bestDelta = delta;
            bestName = c.name;
          }
        }
      }
    }
    return bestName;
  }
}
