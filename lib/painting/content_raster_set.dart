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

import 'dart:ui' as ui;

import 'package:kpix/util/helpers/geometry_helper.dart';

/// A rendered patch of image, and where on the canvas it belongs.
class ContentRasterSet
{
  final ui.Image image;
  final CoordinateSetI offset;
  final CoordinateSetI size;

  const ContentRasterSet({
    required this.image,
    required this.offset,
    required this.size,
  });
}
