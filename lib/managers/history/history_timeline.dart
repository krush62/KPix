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

import 'package:kpix/managers/history/history_frame.dart';
import 'package:kpix/managers/history/history_layer.dart';

class HistoryTimeline
{
  final List<HistoryFrame> frames;
  final int loopStart;
  final int loopEnd;
  final int selectedFrameIndex;
  final LinkedHashSet<HistoryLayer> allLayers;
  const HistoryTimeline({required this.frames, required this.loopStart, required this.loopEnd, required this.selectedFrameIndex, required this.allLayers});

  LinkedHashSet<HistoryLayer> getLayersForFrameIndex({required final int frameIndex})
  {
    if (frameIndex < frames.length && frameIndex >= 0)
    {
      final HistoryFrame frame = frames[frameIndex];
      return getLayersForFrame(frame: frame);
    }
    else
    {
      return LinkedHashSet<HistoryLayer>();
    }

  }

  LinkedHashSet<HistoryLayer> getLayersForFrame({required final HistoryFrame frame})
  {
    final LinkedHashSet<HistoryLayer> layerSet = LinkedHashSet<HistoryLayer>();
    if (frames.contains(frame))
    {
      for (final int layerIndex in frame.layerIndices)
      {
        layerSet.add(allLayers.elementAt(layerIndex));
      }
    }
    return layerSet;
  }

}
