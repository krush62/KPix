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

enum GridType
{
  rectangular(0),
  diagonal(1),
  isometric(2),
  hexagonal(3),
  triangular(4),
  brick(5),
  onePointPerspective(6),
  twoPointPerspective(7),
  threePointPerspective(8);

  const GridType(this.id);
  final int id;
  String label(final AppLocalizations l10n) => switch (this) {
    rectangular => l10n.buttonRec,
    diagonal => l10n.buttonDia,
    isometric => l10n.buttonIso,
    hexagonal => l10n.buttonHex,
    triangular => l10n.buttonTri,
    brick => l10n.buttonBrk,
    onePointPerspective => l10n.button1Point,
    twoPointPerspective => l10n.button2Point,
    threePointPerspective => l10n.button3Point
  };

  String desc(final AppLocalizations l10n) => switch (this) {
  rectangular => l10n.rectangularGrid,
  diagonal => l10n.diagonalGrid,
  isometric => l10n.isometricGrid,
  hexagonal => l10n.hexagonalGrid,
  triangular => l10n.triangularGrid,
  brick => l10n.bricks,
  onePointPerspective => l10n.onePointPerspective,
  twoPointPerspective => l10n.twoPointPerspective,
  threePointPerspective => l10n.threePointPerspective,
  };


  static GridType fromId(final int id)
  {
    return GridType.values.firstWhere((final GridType gridType) => gridType.id == id,
    );
  }
}

abstract final class GridLayerConstraints
{
  static const int opacityMin = 0;
  static const int opacityDefault = 100;
  static const int opacityMax = 100;

  static const int brightnessMin = 0;
  static const int brightnessDefault = 50;
  static const int brightnessMax = 100;

  static const int intervalXMin = 2;
  static const int intervalXDefault = 8;
  static const int intervalXMax = 64;

  static const int intervalYMin = 2;
  static const int intervalYDefault = 8;
  static const int intervalYMax = 64;

  static const double vanishingPointMin = -1.0;
  static const double vanishingPointMax = 2.0;
  static const double horizonDefault = 0.5;
  static const double vanishingPoint1Default = 0.1;
  static const double vanishingPoint2Default = 0.9;
  static const double vanishingPoint3Default = 0.9;
  static const GridType gridTypeDefault = GridType.rectangular;
}
