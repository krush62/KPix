import 'dart:typed_data';
import 'package:flutter/services.dart';


//TODO FIX BROKEN FONTS

enum PixelFontType
{
  fontAlkhemikal,
  fontCartridge,
  fontComicoro,
  //fontCyborgSister,
  //fontDigitalDisco,
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
  //Scriptorium,
  fontSquarewave,
  fontSquarewaveBold
}

const Map<int, PixelFontType> pixelFontIndexMap =
{
  0: PixelFontType.fontAlkhemikal,
  1: PixelFontType.fontCartridge,
  2: PixelFontType.fontComicoro,
  //3: PixelFontType.CyborgSister,
  //4: PixelFontType.DigitalDisco,
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
  //29: PixelFontType.Scriptorium,
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
    List.generate(height + 1, (i) => List.filled(width + 1, false, growable: false), growable: false);
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
const String kFontExtension = ".kfont";


class FontManager
{
  static final Map<PixelFontType, String> _pixelFontNameMap = {
    PixelFontType.fontAlkhemikal: "Alkhemikal",
    PixelFontType.fontCartridge: "Cartridge",
    PixelFontType.fontComicoro: "Comicoro",
    //PixelFontType.CyborgSister: "Cyborg Sister",
    //PixelFontType.DigitalDisco: "Digital Disco",
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
    //PixelFontType.Scriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave Bold"
  };

  static final Map<PixelFontType, String> _pixelFontFileMap = {
    PixelFontType.fontAlkhemikal: "Alkhemikal",
    PixelFontType.fontCartridge: "Cartridge",
    PixelFontType.fontComicoro: "Comicoro",
    //PixelFontType.CyborgSister: "CyborgSister",
    //PixelFontType.DigitalDisco: "DigitalDisco",
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
    //PixelFontType.Scriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave-Bold"
  };

  static String getFontName(final PixelFontType type)
  {
    return _pixelFontNameMap[type]!;
  }

  final Map<PixelFontType, KFont> kFontMap;

  FontManager({required this.kFontMap});

  static Future<Map<PixelFontType, KFont>> readFonts() async
  {
    Map<PixelFontType, KFont> fontMap = {};
    for (final MapEntry<PixelFontType, String> mapEntry in _pixelFontFileMap.entries)
    {
     fontMap[mapEntry.key] = await _readFontFromFile("$fontPath/${mapEntry.value}$kFontExtension", _pixelFontNameMap[mapEntry.key]!);
    }
    return fontMap;
  }


  static Future<KFont> _readFontFromFile(final String filename, final String fontName) async {
    final ByteData byteData = await rootBundle.load(filename);
    final Uint8List bytes = byteData.buffer.asUint8List();

    final ByteData data = bytes.buffer.asByteData();

    // Read header
    final int height = data.getUint8(0);
    final int blocksLength = data.getUint16(1, Endian.little);
    int currentIndex = 3;

    final Map<int, Glyph> glyphMap = {};

    // Read data
    for (int i = 0; i < blocksLength; i++) {
      final unicode = data.getUint16(currentIndex, Endian.little);
      currentIndex += 2;
      final width = data.getUint8(currentIndex);
      currentIndex += 1;

      final glyph = Glyph(width: width, height: height);
      for (int j = 0; j < height; j++) {
        int bitPosition = 0;
        for (int k = 0; k < (width + 7) ~/ 8; k++) {
          final byte = data.getUint8(currentIndex);
          currentIndex += 1;
          for (int bit = 0; bit < 8; bit++) {
            if (bitPosition < width) {
              glyph.dataMatrix[j][bitPosition] = (byte & (1 << (7 - bit))) != 0;
              bitPosition++;
            }
          }
        }
      }

      glyphMap[unicode] = glyph;
    }

    return KFont(name: fontName, height: height, glyphMap: glyphMap);
  }

}