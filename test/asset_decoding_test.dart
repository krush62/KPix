/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/util/file_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fonts still decode identically after the atlas is released', () async {
    final Map<PixelFontType, KFont> fonts = await FontManager.readFonts();

    int glyphCount = 0;
    int setPixels = 0;
    for (final KFont font in fonts.values) {
      for (final Glyph glyph in font.glyphMap.values) {
        glyphCount++;
        for (int x = 0; x < glyph.width; x++) {
          for (int y = 0; y < glyph.height; y++) {
            if (glyph.getPixel(x: x, y: y)) {
              setPixels++;
            }
          }
        }
      }
    }

    expect(fonts.length, 32);
    // a disposal that broke decoding would show up as zero or garbage here
    expect(glyphCount, greaterThan(9000));
    expect(setPixels, greaterThan(100000));

    // loading twice must produce the same result, i.e. nothing was consumed
    final Map<PixelFontType, KFont> again = await FontManager.readFonts();
    int glyphCount2 = 0;
    int setPixels2 = 0;
    for (final KFont font in again.values) {
      for (final Glyph glyph in font.glyphMap.values) {
        glyphCount2++;
        for (int x = 0; x < glyph.width; x++) {
          for (int y = 0; y < glyph.height; y++) {
            if (glyph.getPixel(x: x, y: y)) {
              setPixels2++;
            }
          }
        }
      }
    }
    expect(glyphCount2, glyphCount);
    expect(setPixels2, setPixels);
  }, timeout: const Timeout(Duration(minutes: 3)),);

  test('stamps still decode after the source image is released', () async {
    final Map<String, List<StampManagerEntryData>> stamps =
        await loadStamps(loadUserStamps: false);
    int count = 0;
    int withThumbnail = 0;
    for (final List<StampManagerEntryData> list in stamps.values) {
      for (final StampManagerEntryData entry in list) {
        count++;
        if (entry.thumbnail != null) {
          withThumbnail++;
        }
        expect(entry.data.isNotEmpty, isTrue);
      }
    }
    expect(count, greaterThan(50));
    // the thumbnail is decoded by a codec that is now disposed; the image must survive
    expect(withThumbnail, count);
  }, timeout: const Timeout(Duration(minutes: 3)),);
}
