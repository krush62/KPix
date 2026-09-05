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

/// Sizes and widths the canvas painter draws its overlays with.
///
/// Built from the preferences and read by the painter, so it belongs to
/// neither of them.
class KPixPainterOptions
{
  final double cursorSize;
  final double cursorBorderWidth;
  final double selectionSolidStrokeWidth;
  final double pixelExtension;
  final double selectionPolygonCircleRadius;
  final double selectionStrokeWidthLarge;
  final double selectionStrokeWidthSmall;
  final int backupPainterPollingRateMs;

  KPixPainterOptions({
    required this.cursorSize,
    required this.cursorBorderWidth,
    required this.selectionSolidStrokeWidth,
    required this.pixelExtension,
    required this.selectionPolygonCircleRadius,
    required this.selectionStrokeWidthLarge,
    required this.selectionStrokeWidthSmall,
    required this.backupPainterPollingRateMs,
  });
}
