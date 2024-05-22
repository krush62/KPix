
import 'dart:io';
import 'dart:typed_data';


//TODO FIX BROKEN FONTS

enum PixelFontType
{
  Alkhemikal,
  Cartridge,
  Comicoro,
  //CyborgSister,
  //DigitalDisco,
  DigitalDiscoThin,
  EnchantedSword,
  EnterCommand,
  EnterCommandBold,
  EnterCommandItalic,
  FiveByFive,
  GrapeSoda,
  Kapel,
  KiwiSoda,
  Larceny,
  LunchMenu,
  LycheeSoda,
  Microserif,
  Mousetrap,
  Mousetrap2,
  Neutrino,
  Notepen,
  Optixal,
  OwreKynge,
  PearSoda,
  PlanetaryContact,
  Poco,
  Quadrunde,
  RootBeer,
  //Scriptorium,
  Squarewave,
  SquarewaveBold
}

const Map<int, PixelFontType> pixelFontIndexMap =
{
  0: PixelFontType.Alkhemikal,
  1: PixelFontType.Cartridge,
  2: PixelFontType.Comicoro,
  //3: PixelFontType.CyborgSister,
  //4: PixelFontType.DigitalDisco,
  5: PixelFontType.DigitalDiscoThin,
  6: PixelFontType.EnchantedSword,
  7: PixelFontType.EnterCommand,
  8: PixelFontType.EnterCommandBold,
  9: PixelFontType.EnterCommandItalic,
  10: PixelFontType.FiveByFive,
  11: PixelFontType.GrapeSoda,
  12: PixelFontType.Kapel,
  13: PixelFontType.KiwiSoda,
  14: PixelFontType.Larceny,
  15: PixelFontType.LunchMenu,
  16: PixelFontType.LycheeSoda,
  17: PixelFontType.Microserif,
  18: PixelFontType.Mousetrap,
  19: PixelFontType.Mousetrap2,
  20: PixelFontType.Neutrino,
  21: PixelFontType.Notepen,
  22: PixelFontType.Optixal,
  23: PixelFontType.OwreKynge,
  24: PixelFontType.PearSoda,
  25: PixelFontType.PlanetaryContact,
  26: PixelFontType.Poco,
  27: PixelFontType.Quadrunde,
  28: PixelFontType.RootBeer,
  //29: PixelFontType.Scriptorium,
  30: PixelFontType.Squarewave,
  31: PixelFontType.SquarewaveBold
};


class _Glyph {
  final int width;
  final List<List<bool>> dataMatrix;

  _Glyph._({
    required this.width,
    required this.dataMatrix,
  });

  factory _Glyph({
    required int width,
    required int height,
  }) {
    List<List<bool>> dataMatrix =
    List.generate(height + 1, (i) => List.filled(width + 1, false, growable: false), growable: false);
    return _Glyph._(
      width: width,
      dataMatrix: dataMatrix,
    );
  }
}


class KFont
{
  final String name;
  final int height;
  final Map<int, _Glyph> glyphMap;

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
  static Map<PixelFontType, String> _pixelFontNameMap = {
    PixelFontType.Alkhemikal: "Alkhemikal",
    PixelFontType.Cartridge: "Cartridge",
    PixelFontType.Comicoro: "Comicoro",
    //PixelFontType.CyborgSister: "Cyborg Sister",
    //PixelFontType.DigitalDisco: "Digital Disco",
    PixelFontType.DigitalDiscoThin: "Digital Disco Thin",
    PixelFontType.EnchantedSword: "Enchanted Sword",
    PixelFontType.EnterCommand: "Enter Command",
    PixelFontType.EnterCommandBold: "Enter Command Bold",
    PixelFontType.EnterCommandItalic: "Enter Command Italic",
    PixelFontType.FiveByFive: "Five By Five",
    PixelFontType.GrapeSoda: "Grape Soda",
    PixelFontType.Kapel: "Kapel",
    PixelFontType.KiwiSoda: "Kiwi Soda",
    PixelFontType.Larceny: "Larceny",
    PixelFontType.LunchMenu: "Lunch Menu",
    PixelFontType.LycheeSoda: "Lychee Soda",
    PixelFontType.Microserif: "Microserif",
    PixelFontType.Mousetrap: "Mousetrap",
    PixelFontType.Mousetrap2: "Mousetrap 2",
    PixelFontType.Neutrino: "Neutrino",
    PixelFontType.Notepen: "Notepen",
    PixelFontType.Optixal: "Optixal",
    PixelFontType.OwreKynge: "Owre Kynge",
    PixelFontType.PearSoda: "Pear Soda",
    PixelFontType.PlanetaryContact: "Planetary Contact",
    PixelFontType.Poco: "Poco",
    PixelFontType.Quadrunde: "Quadrunde",
    PixelFontType.RootBeer: "Root Beer",
    //PixelFontType.Scriptorium: "Scriptorium",
    PixelFontType.Squarewave: "Squarewave",
    PixelFontType.SquarewaveBold: "Squarewave Bold"
  };

  static Map<PixelFontType, String> _pixelFontFileMap = {
    PixelFontType.Alkhemikal: "Alkhemikal",
    PixelFontType.Cartridge: "Cartridge",
    PixelFontType.Comicoro: "Comicoro",
    //PixelFontType.CyborgSister: "CyborgSister",
    //PixelFontType.DigitalDisco: "DigitalDisco",
    PixelFontType.DigitalDiscoThin: "DigitalDisco-Thin",
    PixelFontType.EnchantedSword: "EnchantedSword",
    PixelFontType.EnterCommand: "EnterCommand",
    PixelFontType.EnterCommandBold: "EnterCommand-Bold",
    PixelFontType.EnterCommandItalic: "EnterCommand-Italic",
    PixelFontType.FiveByFive: "FiveByFive",
    PixelFontType.GrapeSoda: "GrapeSoda",
    PixelFontType.Kapel: "Kapel",
    PixelFontType.KiwiSoda: "KiwiSoda",
    PixelFontType.Larceny: "Larceny",
    PixelFontType.LunchMenu: "LunchMenu",
    PixelFontType.LycheeSoda: "LycheeSoda",
    PixelFontType.Microserif: "Microserif",
    PixelFontType.Mousetrap: "mousetrap",
    PixelFontType.Mousetrap2: "mousetrap2",
    PixelFontType.Neutrino: "Neutrino",
    PixelFontType.Notepen: "Notepen",
    PixelFontType.Optixal: "Optixal",
    PixelFontType.OwreKynge: "OwreKynge",
    PixelFontType.PearSoda: "PearSoda",
    PixelFontType.PlanetaryContact: "PlanetaryContact",
    PixelFontType.Poco: "Poco",
    PixelFontType.Quadrunde: "Quadrunde",
    PixelFontType.RootBeer: "RootBeer",
    //PixelFontType.Scriptorium: "Scriptorium",
    PixelFontType.Squarewave: "Squarewave",
    PixelFontType.SquarewaveBold: "Squarewave-Bold"
  };

  static String getFontName(final PixelFontType type)
  {
    return _pixelFontNameMap[type]!;
  }

  Map<PixelFontType, KFont> kFontMap = {};

  FontManager()
  {
    for (final MapEntry<PixelFontType, String> mapEntry in _pixelFontFileMap.entries)
    {
      kFontMap[mapEntry.key] = readFontFromFile(fontPath + "/" + mapEntry.value + kFontExtension, _pixelFontNameMap[mapEntry.key]!);
    }
  }

  KFont readFontFromFile(final String filename, final String fontName) {
    final File file = File(filename);
    final Uint8List bytes = file.readAsBytesSync();

    final ByteData data = bytes.buffer.asByteData();

    // Read header
    final int height = data.getUint8(0);
    final int blocksLength = data.getUint16(1, Endian.little);
    int currentIndex = 3;

    final Map<int, _Glyph> glyphMap = {};

    // Read data
    for (int i = 0; i < blocksLength; i++) {
      final unicode = data.getUint16(currentIndex, Endian.little);
      currentIndex += 2;
      final width = data.getUint8(currentIndex);
      currentIndex += 1;

      final glyph = _Glyph(width: width, height: height);
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