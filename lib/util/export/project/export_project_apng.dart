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

part of '../../export_functions.dart';

Future<Uint8List?> exportAPNG({required final AnimationExportData exportData}) async
{
  final List<RenderedFrame>? frames = await _renderAnimationFrames(exportData: exportData);
  if (frames == null || frames.isEmpty)
  {
    return null;
  }

  return await runOffThread<Uint8List>(
    debugLabel: "apng-export",
    work: () => _encodeAnimation(frames: frames, format: _AnimationFormat.apng),
  );
}
