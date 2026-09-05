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

abstract final class SpraycanConstraints
{
  static const int radiusMin = 3;
  static const int radiusDefault = 8;
  static const int radiusMax = 32;

  static const int blobSizeMin = 1;
  static const int blobSizeDefault = 1;
  static const int blobSizeMax = 8;

  static const int intensityMin = 1;
  static const int intensityDefault = 8;
  static const int intensityMax = 128;
}
