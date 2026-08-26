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

/// Runs a piece of pure computation away from the UI isolate where the platform
/// allows it.
///
/// Native builds hand the work to a background isolate; web builds run it inline,
/// so callers must not rely on the UI staying responsive there.
library;

export 'isolate_helper_web.dart' if (dart.library.io) 'isolate_helper_io.dart';
