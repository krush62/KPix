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

/// Where the main button bar leaves its save and open handlers.
///
/// The application shell has to save the current file before closing, starting
/// a new project or opening another one, but the buttons that know how to do
/// that are built far below it. Kept out of the shell so that nothing has to
/// import the entry point to reach them.
Function({Function()? callback})? saveFileCallback;
Function({Function()? callback})? openFileCallback;
