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

import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_layer.dart';

class HistoryTimeline
{
  final List<HistoryFrame> frames;
  final int loopStart;
  final int loopEnd;
  final int selectedFrameIndex;
  const HistoryTimeline({required this.frames, required this.loopStart, required this.loopEnd, required this.selectedFrameIndex});

  int getTotalLayerCount()
  {
    int totalLayerCount = 0;
    for (final HistoryFrame frame in frames)
    {
      totalLayerCount += frame.layers.length;
    }
    return totalLayerCount;
  }

  List<HistoryLayer> getAllLayers()
  {
    final List<HistoryLayer> layers = <HistoryLayer>[];
    for (final HistoryFrame frame in frames)
    {
      layers.addAll(frame.layers);
    }
    return layers;
  }
}
