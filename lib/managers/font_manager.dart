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
  fontScriptorium,
  fontSquarewave,
  fontSquarewaveBold
}

const Map<int, PixelFontType> pixelFontIndexMap =
<int, PixelFontType>{
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
  29: PixelFontType.fontScriptorium,
  30: PixelFontType.fontSquarewave,
  31: PixelFontType.fontSquarewaveBold,
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
    PixelFontType.fontScriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave Bold",
  };

  static final Map<PixelFontType, String> _pixelFontFileMap = <PixelFontType, String>{
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
    PixelFontType.fontScriptorium: "Scriptorium",
    PixelFontType.fontSquarewave: "Squarewave",
    PixelFontType.fontSquarewaveBold: "Squarewave-Bold",
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
