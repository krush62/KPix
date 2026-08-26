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

import 'dart:async';

/// Runs [work] inline, because web builds have no isolates.
///
/// The UI blocks for the duration; a web worker would be needed to avoid that,
/// which the `image` and `archive` encoders cannot be handed to as they stand.
Future<R> runOffThread<R>({required final FutureOr<R> Function() work, required final String debugLabel}) async
{
  return await work();
}
