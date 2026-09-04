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

import 'dart:collection';

import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

typedef CoordinateColorMap = HashMap<CoordinateSetI, ColorReference>;
typedef CoordinateColorMapNullable = HashMap<CoordinateSetI, ColorReference?>;
typedef CoordinateColor = MapEntry<CoordinateSetI, ColorReference>;
typedef CoordinateColorNullable = MapEntry<CoordinateSetI, ColorReference?>;

class StackCol<T> {
  final List<T> _list = <T>[];

  void push(final T value) => _list.add(value);

  T pop() => _list.removeLast();

  T get peek => _list.last;

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  int get length => _list.length;
}
