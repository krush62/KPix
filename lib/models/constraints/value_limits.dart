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

/// The inclusive range of a setting together with its default value.
final class ValueLimits<T extends num>
{
  const ValueLimits({required this.min, required this.defaultValue, required this.max})
      : assert(min <= defaultValue && defaultValue <= max, "the default has to lie within the limits");

  final T min;
  final T defaultValue;
  final T max;

  bool contains(final num value, {final double tolerance = 0.0}) => value >= min - tolerance && value <= max + tolerance;
}

extension IntValueLimits on ValueLimits<int>
{
  int clamp(final int value) => value.clamp(min, max);

  int get span => max - min;
}

extension DoubleValueLimits on ValueLimits<double>
{
  double clamp(final double value) => value.clamp(min, max);
}
