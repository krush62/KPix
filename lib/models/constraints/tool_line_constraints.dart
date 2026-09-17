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


import 'package:kpix/l10n/app_localizations.dart';

enum SegmentSortStyle
{
  asc(0, "<"),
  ascDesc(1, "<>"),
  descAsc(2, "><"),
  desc(3, ">");

  const SegmentSortStyle(this.id, this.iconText);
  final int id;
  final String iconText;

  String label(final AppLocalizations l10n) => switch (this)
  {
    asc => l10n.ascendingSegmentOrder,
    ascDesc => l10n.ascendingDescendingSegmentOrder,
    descAsc => l10n.descendingAscendingSegmentOrder,
    desc => l10n.descendingSegmentOrder,
  };
}

abstract final class LineConstraints
{
  static const int widthMin = 1;
  static const int widthDefault = 1;
  static const int widthMax = 16;

  static const bool integerAspectRatioDefault = false;
  static const bool segmentSortingDefault = false;
  static const SegmentSortStyle segmentSortStyleDefault = SegmentSortStyle.ascDesc;

  static const int bezierCalculationPoints = 1000;
}
