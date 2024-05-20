

import 'dart:convert';
import 'dart:io';

import 'package:kpix/helper.dart';

enum ColorNameScheme
{
  general,
  pms,
  ral_classic,
  ral_complete,
  ral_dsp
}

const Map<int, ColorNameScheme> _colorNameSchemeMap =
{
  0: ColorNameScheme.general,
  1: ColorNameScheme.pms,
  2: ColorNameScheme.ral_classic,
  3: ColorNameScheme.ral_complete,
  4: ColorNameScheme.ral_dsp
};

const Map<ColorNameScheme, String> _colorNameFileNames =
{
  ColorNameScheme.general: "general.csv",
  ColorNameScheme.pms: "pms.csv",
  ColorNameScheme.ral_classic : "ral_classic.csv",
  ColorNameScheme.ral_complete : "ral_complete.csv",
  ColorNameScheme.ral_dsp : "ral_dsp.csv",
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

  ColorNames({
   required this.options
  })
  {
    final String path = "${options.colorNamePath}/${options.colorFilename}";
    File(path)
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((l) => _processLine(l));
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
    double bestDelta = 100;
    for (final NamedColor c in colorList)
    {
      if (r == c.r && g == c.g && b == c.b)
      {
        bestName = c.name;
        bestDelta = 0.0;
        break;
      }
      else
      {
        double delta = Helper.getDeltaE(r, g, b, c.r, c.g, c.b);
        if (delta < bestDelta)
        {
          bestDelta = delta;
          bestName = c.name;
        }
      }
    }
    return bestName;
  }

}