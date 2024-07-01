import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

enum PixelFontType
{
  fontAlkhemikal,
  fontCartridge,
  fontComicoro,
  fontCyborgSister,
  fontDigitalDisco,
  fontDigitalDiscoThin,
  fontEnchantedSword,
  fontEnterCommand,
  fontEnterCommandBold,
  fontEnterCommandItalic,
  fontFiveByFive,
  fontGrapeSoda,
  fontKapel,
  fontKiwiSoda,
  fontLarceny,
  fontLunchMenu,
  fontLycheeSoda,
  fontMicroserif,
  fontMousetrap,
  fontMousetrap2,
  fontNeutrino,
  fontNotepen,
  fontOptixal,
  fontOwreKynge,
  fontPearSoda,
  fontPlanetaryContact,
  fontPoco,
  fontQuadrunde,
  fontRootBeer,
  Scriptorium,
  fontSquarewave,
  fontSquarewaveBold
}

const Map<int, PixelFontType> pixelFontIndexMap =
{
  0: PixelFontType.fontAlkhemikal,
  1: PixelFontType.fontCartridge,
  2: PixelFontType.fontComicoro,
  3: PixelFontType.fontCyborgSister,
  4: PixelFontType.fontDigitalDisco,
  5: PixelFontType.fontDigitalDiscoThin,
  6: PixelFontType.fontEnchantedSword,
  7: PixelFontType.fontEnterCommand,
  8: PixelFontType.fontEnterCommandBold,
  9: PixelFontType.fontEnterCommandItalic,
  10: PixelFontType.fontFiveByFive,
  11: PixelFontType.fontGrapeSoda,
  12: PixelFontType.fontKapel,
  13: PixelFontType.fontKiwiSoda,
  14: PixelFontType.fontLarceny,
  15: PixelFontType.fontLunchMenu,
  16: PixelFontType.fontLycheeSoda,
  17: PixelFontType.fontMicroserif,
  18: PixelFontType.fontMousetrap,
  19: PixelFontType.fontMousetrap2,
  20: PixelFontType.fontNeutrino,
  21: PixelFontType.fontNotepen,
  22: PixelFontType.fontOptixal,
  23: PixelFontType.fontOwreKynge,
  24: PixelFontType.fontPearSoda,
  25: PixelFontType.fontPlanetaryContact,
  26: PixelFontType.fontPoco,
  27: PixelFontType.fontQuadrunde,
  28: PixelFontType.fontRootBeer,
  29: PixelFontType.Scriptorium,
  30: PixelFontType.fontSquarewave,
  31: PixelFontType.fontSquarewaveBold
};


class Glyph {
  final int width;
  final List<List<bool>> dataMatrix;

  Glyph._({
    required this.width,
    required this.dataMatrix,
  });

  factory Glyph({
    required int width,
    required int height,
  }) {
    List<List<bool>> dataMatrix =
    List.generate(width, (i) => List.filled(height, false, growable: false), growable: false);
    return Glyph._(
      width: width,
      dataMatrix: dataMatrix,
    );
  }
}


class KFont
{
  final String name;
  final int height;
  final Map<int, Glyph> glyphMap;

  KFont({
    required this.name,
    required this.height,
    required this.glyphMap,
  });
}

const String fontPath = "fonts";
const String sflExtension = ".sfl";
const String pngExtension = ".PNG";


class FontManager
{
  static final Map<PixelFontType, String> _pixelFontNameMap = {
    PixelFontType.fontAlkhemikal: "Alkhemikal",
    PixelFontType.fontCartridge: "Cartridge",
    PixelFontType.fontComicoro: "Comicoro",
    PixelFontType.fontCyborgSister: "Cyborg Sister",
    PixelFontType.fontDigitalDisco: "Digital Disco",
    PixelFontType.fontDigitalDiscoThin: "Digital Disco Thin",
    PixelFontType.fontEnchantedSword: "Enchanted Sword",
    PixelFontType.fontEnterCommand: "Enter Command",
    PixelFontType.fontEnterCommandBold: "Enter Command Bold",
    PixelFontType.fontEnterCommandItalic: "Enter Command Italic",
    PixelFontType.fontFiveByFive: "Five By Five",
    PixelFontType.fontGrapeSoda: "Grape Soda",
    PixelFontType.fontKapel: "Kapel",
    PixelFontType.fontKiwiSoda: "Kiwi Soda",
    PixelFontType.fontLarceny: "Larceny",
    PixelFontType.fontLunchMenu: "Lunch Menu",
    PixelFontType.fontLycheeSoda: "Lychee Soda",
    PixelFontType.fontMicroserif: "Microserif",
    PixelFontType.fontMousetrap: "Mousetrap",
    PixelFontType.fontMousetrap2: "Mousetrap 2",
    PixelFontType.fontNeutrino: "Neutrino",
    PixelFontType.fontNotepen: "Notepen",
    PixelFontType.fontOptixal: "Optixal",
    PixelFontType.fontOwreKynge: "Owre Kynge",
    PixelFontType.fontPearSoda: "Pear Soda",
    PixelFontType.fontPlanetaryContact: "Planetary Contact",
    PixelFontType.fontPoco: "Poco",
    PixelFontType.fontQuadrunde: "Quadrunde",
    PixelFontType.fontRootBeer: "Root Beer",
    PixelFontType.Scriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave Bold"
  };

  static final Map<PixelFontType, String> _pixelFontFileMap = {
    PixelFontType.fontAlkhemikal: "Alkhemikal",
    PixelFontType.fontCartridge: "Cartridge",
    PixelFontType.fontComicoro: "Comicoro",
    PixelFontType.fontCyborgSister: "CyborgSister",
    PixelFontType.fontDigitalDisco: "DigitalDisco",
    PixelFontType.fontDigitalDiscoThin: "DigitalDisco-Thin",
    PixelFontType.fontEnchantedSword: "EnchantedSword",
    PixelFontType.fontEnterCommand: "EnterCommand",
    PixelFontType.fontEnterCommandBold: "EnterCommand-Bold",
    PixelFontType.fontEnterCommandItalic: "EnterCommand-Italic",
    PixelFontType.fontFiveByFive: "FiveByFive",
    PixelFontType.fontGrapeSoda: "GrapeSoda",
    PixelFontType.fontKapel: "Kapel",
    PixelFontType.fontKiwiSoda: "KiwiSoda",
    PixelFontType.fontLarceny: "Larceny",
    PixelFontType.fontLunchMenu: "LunchMenu",
    PixelFontType.fontLycheeSoda: "LycheeSoda",
    PixelFontType.fontMicroserif: "Microserif",
    PixelFontType.fontMousetrap: "mousetrap",
    PixelFontType.fontMousetrap2: "mousetrap2",
    PixelFontType.fontNeutrino: "Neutrino",
    PixelFontType.fontNotepen: "Notepen",
    PixelFontType.fontOptixal: "Optixal",
    PixelFontType.fontOwreKynge: "OwreKynge",
    PixelFontType.fontPearSoda: "PearSoda",
    PixelFontType.fontPlanetaryContact: "PlanetaryContact",
    PixelFontType.fontPoco: "Poco",
    PixelFontType.fontQuadrunde: "Quadrunde",
    PixelFontType.fontRootBeer: "RootBeer",
    PixelFontType.Scriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave-Bold"
  };

  static String getFontName(final PixelFontType type)
  {
    return _pixelFontNameMap[type]!;
  }

  KFont getFont(final PixelFontType type)
  {
    return kFontMap[type]!;
  }

  final Map<PixelFontType, KFont> kFontMap;

  FontManager({required this.kFontMap});

  static Future<Map<PixelFontType, KFont>> readFonts() async
  {
    Map<PixelFontType, KFont> fontMap = {};
    for (final MapEntry<PixelFontType, String> mapEntry in _pixelFontFileMap.entries)
    {
     fontMap[mapEntry.key] = await _readFontFromFile("$fontPath/${mapEntry.value}$sflExtension", "$fontPath/${mapEntry.value}$pngExtension", _pixelFontNameMap[mapEntry.key]!);
    }
    return fontMap;
  }


  static Future<KFont> _readFontFromFile(final String sflName, final String pngName, final String fontName) async
  {
    String sflContent = await rootBundle.loadString(sflName);
    List<String> lines = sflContent.split('\n');
    assert(lines.isNotEmpty);

    final ByteData byteData = await rootBundle.load(pngName);
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final ui.Image decImg = await decodeImageFromList(pngBytes);
    final int imgHeight = decImg.height;
    final int imgWidth = decImg.width;
    final ByteData? imgData = await decImg.toByteData();
    final Map<int, Glyph> glyphMap = {};

    if (imgData != null)
    {
      for (int i = 4; i < lines.length; i++)
      {
        final List<String> splits = lines[i].split(' ');
        if (splits.length >= 4)
        {
          final int id = int.parse(splits[0].trim());
          final int x = int.parse(splits[1].trim());
          final int width = int.parse(splits[3].trim());
          if (x >= 0 && x < decImg.width)
          {
            if (width > 0)
            {
              final glyph = Glyph(width: width, height: imgHeight);
              for (int a = x; a < x + width; a++)
              {
                for (int b = 0; b < imgHeight; b++)
                {
                  final int addr = (b * imgWidth * 4) + (a * 4) + 3;
                  final val = imgData.getUint8(addr);
                  glyph.dataMatrix[a-x][b] = (val > 0);
                }
              }
              glyphMap[id] = glyph;
            }
            else if (id == 32)
            {
              final glyph = Glyph(width: 1, height: imgHeight);
              for (int b = 0; b < imgHeight; b++)
              {
                glyph.dataMatrix[0][b] = false;
              }
              glyphMap[id] = glyph;
            }
          }
          else
          {
            //DISCARDING INVALID CHARACTER LOCATION
          }
        }
      }
    }
    return KFont(name: fontName, height: imgHeight, glyphMap: glyphMap);
  }

}