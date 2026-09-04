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

/// The on-disk vocabulary: format version, magic number, extensions and the
/// names of the sub-directories a project lives in.
///
/// Shared by the file layer, the project manager and several widgets, so it
/// sits below all of them.
const int fileVersion = 4;
const String magicNumber = "4B504958";
const String fileExtensionKpix = "kpix";
const String fileExtensionKpal = "kpal";
const String palettesSubDirName = "palettes";
const String stampsSubDirName = "stamps";
const String projectsSubDirName = "projects";
const String recoverSubDirName = "recover";
const String thumbnailExtension = "png";
const List<String> imageExtensions = <String>["png", "jpg", "jpeg", "gif"];
const String recoverFileName = "___recover___";
