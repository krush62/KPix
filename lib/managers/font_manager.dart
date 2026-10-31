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

import 'package:flutter/services.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helpers/isolate_helper.dart';
import 'package:kpix/util/helpers/png_helper.dart';

enum PixelFontType
{
  fontAlkhemikal,
  fontBelanidiSerif,
  fontBytesized,
  fontC64esque,
  fontCairopixel,
  fontCartridge,
  fontComicoro,
  fontCutePixel,
  fontCyborgSister,
  fontDigitalDisco,
  fontDigitalDiscoThin,
  fontEnchantedSword,
  fontEnterCommand,
  fontEnterCommandBold,
  fontEnterCommandItalic,
  fontFiveByFive,
  fontGibberesque,
  fontGrapeSoda,
  fontJacquard12,
  fontJacquardaBastarda9,
  fontKapel,
  fontKiwiSoda,
  fontKubasta,
  fontLarceny,
  fontLcdBlock,
  fontLunchMenu,
  fontLycheeSoda,
  fontMicroserif,
  fontMousetrap,
  fontMousetrap2,
  fontNeutrino,
  fontNotepen,
  fontOptixal,
  fontOrangeKid,
  fontOwreKynge,
  fontPearSoda,
  fontPixelifySans,
  fontPixelzone,
  fontPlanetaryContact,
  fontPoco,
  fontQuadrunde,
  fontRootBeer,
  fontScriptorium,
  fontSquarewave,
  fontSquarewaveBold,
  fontTinyUnicode,
  fontUpheavalPro
}

const Map<int, PixelFontType> pixelFontIndexMap =
<int, PixelFontType>{
  0: PixelFontType.fontAlkhemikal,
  1: PixelFontType.fontBelanidiSerif,
  2: PixelFontType.fontBytesized,
  3: PixelFontType.fontC64esque,
  4: PixelFontType.fontCairopixel,
  5: PixelFontType.fontCartridge,
  6: PixelFontType.fontComicoro,
  7: PixelFontType.fontCutePixel,
  8: PixelFontType.fontCyborgSister,
  9: PixelFontType.fontDigitalDisco,
  10: PixelFontType.fontDigitalDiscoThin,
  11: PixelFontType.fontEnchantedSword,
  12: PixelFontType.fontEnterCommand,
  13: PixelFontType.fontEnterCommandBold,
  14: PixelFontType.fontEnterCommandItalic,
  15: PixelFontType.fontFiveByFive,
  16: PixelFontType.fontGibberesque,
  17: PixelFontType.fontGrapeSoda,
  18: PixelFontType.fontJacquard12,
  19: PixelFontType.fontJacquardaBastarda9,
  20: PixelFontType.fontKapel,
  21: PixelFontType.fontKiwiSoda,
  22: PixelFontType.fontKubasta,
  23: PixelFontType.fontLarceny,
  24: PixelFontType.fontLcdBlock,
  25: PixelFontType.fontLunchMenu,
  26: PixelFontType.fontLycheeSoda,
  27: PixelFontType.fontMicroserif,
  28: PixelFontType.fontMousetrap,
  29: PixelFontType.fontMousetrap2,
  30: PixelFontType.fontNeutrino,
  31: PixelFontType.fontNotepen,
  32: PixelFontType.fontOptixal,
  33: PixelFontType.fontOrangeKid,
  34: PixelFontType.fontOwreKynge,
  35: PixelFontType.fontPearSoda,
  36: PixelFontType.fontPixelifySans,
  37: PixelFontType.fontPixelzone,
  38: PixelFontType.fontPlanetaryContact,
  39: PixelFontType.fontPoco,
  40: PixelFontType.fontQuadrunde,
  41: PixelFontType.fontRootBeer,
  42: PixelFontType.fontScriptorium,
  43: PixelFontType.fontSquarewave,
  44: PixelFontType.fontSquarewaveBold,
  45: PixelFontType.fontTinyUnicode,
  46: PixelFontType.fontUpheavalPro,
};


class Glyph
{
  final int width;
  final int height;

  final Uint8List _bits;

  factory Glyph({
    required final int width,
    required final int height,
  }) {
    return Glyph._(
      width: width,
      height: height,
      //Uint8List starts zeroed, so every pixel begins unset
      bits: Uint8List((width * height + 7) >> 3),
    );
  }

  Glyph._({
    required this.width,
    required this.height,
    required final Uint8List bits,
  }) : _bits = bits;

  /// Whether the pixel at [x], [y] is part of the glyph.
  bool getPixel({required final int x, required final int y})
  {
    final int index = x * height + y;
    return _bits[index >> 3] & (1 << (index & 7)) != 0;
  }

  void setPixel({required final int x, required final int y, required final bool value})
  {
    final int index = x * height + y;
    final int byteIndex = index >> 3;
    final int mask = 1 << (index & 7);
    if (value)
    {
      _bits[byteIndex] |= mask;
    }
    else
    {
      _bits[byteIndex] &= ~mask & 0xFF;
    }
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

const String sflExtension = ".sfl";
const String pngExtension = ".PNG";


class FontManager
{
  static final Map<PixelFontType, String> _pixelFontNameMap = <PixelFontType, String>{
    PixelFontType.fontAlkhemikal: "Alkhemikal",
    PixelFontType.fontBelanidiSerif: "Belanidi Serif",
    PixelFontType.fontBytesized: "Bytesized",
    PixelFontType.fontC64esque: "C64esque",
    PixelFontType.fontCairopixel: "Cairopixel",
    PixelFontType.fontCartridge: "Cartridge",
    PixelFontType.fontComicoro: "Comicoro",
    PixelFontType.fontCutePixel: "Cute Pixel",
    PixelFontType.fontCyborgSister: "Cyborg Sister",
    PixelFontType.fontDigitalDisco: "Digital Disco",
    PixelFontType.fontDigitalDiscoThin: "Digital Disco Thin",
    PixelFontType.fontEnchantedSword: "Enchanted Sword",
    PixelFontType.fontEnterCommand: "Enter Command",
    PixelFontType.fontEnterCommandBold: "Enter Command Bold",
    PixelFontType.fontEnterCommandItalic: "Enter Command Italic",
    PixelFontType.fontFiveByFive: "Five By Five",
    PixelFontType.fontGibberesque: "Gibberesque",
    PixelFontType.fontGrapeSoda: "Grape Soda",
    PixelFontType.fontJacquard12: "Jacquard 12",
    PixelFontType.fontJacquardaBastarda9: "Jacquarda Bastarda 9",
    PixelFontType.fontKapel: "Kapel",
    PixelFontType.fontKiwiSoda: "Kiwi Soda",
    PixelFontType.fontKubasta: "Kubasta",
    PixelFontType.fontLarceny: "Larceny",
    PixelFontType.fontLcdBlock: "LCD Block",
    PixelFontType.fontLunchMenu: "Lunch Menu",
    PixelFontType.fontLycheeSoda: "Lychee Soda",
    PixelFontType.fontMicroserif: "Microserif",
    PixelFontType.fontMousetrap: "Mousetrap",
    PixelFontType.fontMousetrap2: "Mousetrap 2",
    PixelFontType.fontNeutrino: "Neutrino",
    PixelFontType.fontNotepen: "Notepen",
    PixelFontType.fontOptixal: "Optixal",
    PixelFontType.fontOrangeKid: "Orange Kid",
    PixelFontType.fontOwreKynge: "Owre Kynge",
    PixelFontType.fontPearSoda: "Pear Soda",
    PixelFontType.fontPixelifySans: "Pixelify Sans",
    PixelFontType.fontPixelzone: "Pixelzone",
    PixelFontType.fontPlanetaryContact: "Planetary Contact",
    PixelFontType.fontPoco: "Poco",
    PixelFontType.fontQuadrunde: "Quadrunde",
    PixelFontType.fontRootBeer: "Root Beer",
    PixelFontType.fontScriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave Bold",
    PixelFontType.fontTinyUnicode: "Tiny Unicode",
    PixelFontType.fontUpheavalPro: "Upheaval Pro",
  };

  static final Map<PixelFontType, String> _pixelFontFileMap = <PixelFontType, String>{
    PixelFontType.fontAlkhemikal: "Alkhemikal",
    PixelFontType.fontBelanidiSerif: "BelanidiSerif",
    PixelFontType.fontBytesized: "Bytesized",
    PixelFontType.fontC64esque: "c64esque",
    PixelFontType.fontCairopixel: "Cairopixel",
    PixelFontType.fontCartridge: "Cartridge",
    PixelFontType.fontComicoro: "Comicoro",
    PixelFontType.fontCutePixel: "CutePixel",
    PixelFontType.fontCyborgSister: "CyborgSister",
    PixelFontType.fontDigitalDisco: "DigitalDisco",
    PixelFontType.fontDigitalDiscoThin: "DigitalDisco-Thin",
    PixelFontType.fontEnchantedSword: "EnchantedSword",
    PixelFontType.fontEnterCommand: "EnterCommand",
    PixelFontType.fontEnterCommandBold: "EnterCommand-Bold",
    PixelFontType.fontEnterCommandItalic: "EnterCommand-Italic",
    PixelFontType.fontFiveByFive: "FiveByFive",
    PixelFontType.fontGibberesque: "Gibberesque",
    PixelFontType.fontGrapeSoda: "GrapeSoda",
    PixelFontType.fontJacquard12: "Jacquard12",
    PixelFontType.fontJacquardaBastarda9: "JacquardaBastarda9",
    PixelFontType.fontKapel: "Kapel",
    PixelFontType.fontKiwiSoda: "KiwiSoda",
    PixelFontType.fontKubasta: "Kubasta",
    PixelFontType.fontLarceny: "Larceny",
    PixelFontType.fontLcdBlock: "LCDBlock",
    PixelFontType.fontLunchMenu: "LunchMenu",
    PixelFontType.fontLycheeSoda: "LycheeSoda",
    PixelFontType.fontMicroserif: "Microserif",
    PixelFontType.fontMousetrap: "mousetrap",
    PixelFontType.fontMousetrap2: "mousetrap2",
    PixelFontType.fontNeutrino: "Neutrino",
    PixelFontType.fontNotepen: "Notepen",
    PixelFontType.fontOptixal: "Optixal",
    PixelFontType.fontOrangeKid: "OrangeKid",
    PixelFontType.fontOwreKynge: "OwreKynge",
    PixelFontType.fontPearSoda: "PearSoda",
    PixelFontType.fontPixelifySans: "PixelifySans",
    PixelFontType.fontPixelzone: "Pixelzone",
    PixelFontType.fontPlanetaryContact: "PlanetaryContact",
    PixelFontType.fontPoco: "Poco",
    PixelFontType.fontQuadrunde: "Quadrunde",
    PixelFontType.fontRootBeer: "RootBeer",
    PixelFontType.fontScriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave-Bold",
    PixelFontType.fontTinyUnicode: "TinyUnicode",
    PixelFontType.fontUpheavalPro: "UpheavalPro",
  };

  static String getFontName({required final PixelFontType type})
  {
    return _pixelFontNameMap[type]!;
  }

  KFont getFont({required final PixelFontType type})
  {
    return kFontMap[type]!;
  }

  final Map<PixelFontType, KFont> kFontMap;

  FontManager({required this.kFontMap});

  static Future<Map<PixelFontType, KFont>> readFonts() async
  {
    final List<PixelFontType> types = _pixelFontFileMap.keys.toList();
    final List<String> sflContents = await Future.wait(types.map((final PixelFontType type) => rootBundle.loadString("${PreferenceManager.ASSET_PATH_FONTS}/${_pixelFontFileMap[type]}$sflExtension")));
    final List<Uint8List> pngContents = await Future.wait(types.map((final PixelFontType type) async => (await rootBundle.load("${PreferenceManager.ASSET_PATH_FONTS}/${_pixelFontFileMap[type]}$pngExtension")).buffer.asUint8List()));
    final List<String> fontNames = types.map((final PixelFontType type) => _pixelFontNameMap[type]!).toList();
    final List<KFont> fonts = await _buildFontsOffThread(sflContents: sflContents, pngContents: pngContents, fontNames: fontNames);
    return Map<PixelFontType, KFont>.fromIterables(types, fonts);
  }

  //decoding through the engine costs a round trip and a GPU readback per font
  static Future<List<KFont>> _buildFontsOffThread({required final List<String> sflContents, required final List<Uint8List> pngContents, required final List<String> fontNames})
  {
    return runOffThread<List<KFont>>(
      work: () => <KFont>[
        for (int i = 0; i < fontNames.length; i++) _buildFont(sflContent: sflContents[i], pngBytes: pngContents[i], fontName: fontNames[i]),
      ],
      debugLabel: "font decoding",
    );
  }

  static KFont _buildFont({required final String sflContent, required final Uint8List pngBytes, required final String fontName})
  {
    final List<String> lines = sflContent.split('\n');
    assert(lines.isNotEmpty);

    final RgbaPixels? pixels = decodePngToRgba(pngBytes: pngBytes);
    if (pixels == null)
    {
      throw FormatException("Could not decode the glyph image of font $fontName.");
    }
    final int imgHeight = pixels.height;
    final int imgWidth = pixels.width;
    final ByteData imgData = pixels.bytes;
    final Map<int, Glyph> glyphMap = <int, Glyph>{};

    for (int i = 4; i < lines.length; i++)
    {
      final List<String> splits = lines[i].split(' ');
      if (splits.length >= 4)
      {
        final int id = int.parse(splits[0].trim());
        final int x = int.parse(splits[1].trim());
        final int width = int.parse(splits[3].trim());
        if (x >= 0 && x < imgWidth)
        {
          if (width > 0)
          {
            final Glyph glyph = Glyph(width: width, height: imgHeight);
            for (int a = x; a < x + width; a++)
            {
              for (int b = 0; b < imgHeight; b++)
              {
                final int addr = (b * imgWidth * 4) + (a * 4) + 3;
                final int val = imgData.getUint8(addr);
                glyph.setPixel(x: a - x, y: b, value: val > 0);
              }
            }
            glyphMap[id] = glyph;
          }
          else if (id == 32)
          {
            //the space glyph is blank, which a freshly allocated Glyph already is
            glyphMap[id] = Glyph(width: 1, height: imgHeight);
          }
        }
        else
        {
          //DISCARDING INVALID CHARACTER LOCATION
        }
      }
    }
    return KFont(name: fontName, height: imgHeight, glyphMap: glyphMap);
  }
}
