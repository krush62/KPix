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

/// Multiplier for [combineHashes]: a large odd prime, so that scaling the first
/// component spreads it across the whole word instead of leaving it in the low
/// bits where it would collide with the second one.
const int _hashPrime = 92821;

/// Mask keeping results inside the 30-bit range that both the VM (tagged small
/// integers) and the web (exact double arithmetic) handle without boxing or
/// precision loss.
const int _hashMask = 0x3fffffff;

/// Combines two hash components into one.
///
/// Pairs of small integers - grid coordinates above all - are the common key
/// type in this app, and XOR is a poor fit for them: `a ^ b` maps `(2,3)` and
/// `(3,2)` to the same value and collapses the whole diagonal onto zero, so a
/// square canvas produces far fewer distinct hashes than it has pixels and the
/// buckets grow chains. Scaling [a] first removes that symmetry.
///
/// Cheaper than [Object.hash] (which mixes for arbitrary arity) while spreading
/// coordinate pairs at least as well, which matters because this runs on every
/// lookup of every pixel.
int combineHashes({required final int a, required final int b})
{
  return (a * _hashPrime + b) & _hashMask;
}
