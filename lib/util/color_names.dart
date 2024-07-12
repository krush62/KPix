import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kpix/util/helper.dart';

enum ColorNameScheme
{
  general,
  pms,
  ralClassic,
  ralComplete,
  ralDsp
}

const Map<int, ColorNameScheme> _colorNameSchemeMap =
{
  0: ColorNameScheme.general,
  1: ColorNameScheme.pms,
  2: ColorNameScheme.ralClassic,
  3: ColorNameScheme.ralComplete,
  4: ColorNameScheme.ralDsp
};

const Map<ColorNameScheme, String> _colorNameFileNames =
{
  ColorNameScheme.general: "general.csv",
  ColorNameScheme.pms: "pms.csv",
  ColorNameScheme.ralClassic : "ral_classic.csv",
  ColorNameScheme.ralComplete : "ral_complete.csv",
  ColorNameScheme.ralDsp : "ral_dsp.csv",
};

class ColorNamesOptions{
  final int defaultNameScheme;
  final String defaultColorNamePath;

  ColorNameScheme nameScheme = ColorNameScheme.general;
  String colorNamePath = "color_names";
  String colorFilename = "general.csv";

  ColorNamesOptions({
    required this.defaultNameScheme,
    required this.defaultColorNamePath
  })
  {
    nameScheme = _colorNameSchemeMap[defaultNameScheme] ?? ColorNameScheme.general;
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
    required this.b
  });
}

class ColorNames
{
  final ColorNamesOptions options;
  List<NamedColor> colorList = [];
  bool colorsLoaded = false;

  void _processColorData(final String data)
  {
    LineSplitter ls = const LineSplitter();
    List<String> lines = ls.convert(data);
    for(final String line in lines)
    {
      _processLine(line);
    }


    colorsLoaded = true;
  }


  ColorNames({
   required this.options
  })
  {
    rootBundle.loadString("${options.colorNamePath}/${options.colorFilename}").then((value) {
      _processColorData(value);
    });

  }

  void _processLine(final String line)
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

  String getColorName(final int r, final int g, final int b)
  {
    //TODO magic string
    String bestName = "<UNKNOWN>";
    if (colorsLoaded) {
      double bestDelta = 100;
      for (final NamedColor c in colorList) {
        if (r == c.r && g == c.g && b == c.b) {
          bestName = c.name;
          bestDelta = 0.0;
          break;
        }
        else {
          double delta = Helper.getDeltaE(r, g, b, c.r, c.g, c.b);
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