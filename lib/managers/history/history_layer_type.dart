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

import 'package:kpix/managers/history/history_drawing_layer.dart';
import 'package:kpix/managers/history/history_grid_layer.dart';
import 'package:kpix/managers/history/history_layer.dart';
import 'package:kpix/managers/history/history_reference_layer.dart';
import 'package:kpix/managers/history/history_shading_layer.dart';

class HistoryLayerType<T extends HistoryLayer> {
  const HistoryLayerType(this.id);
  final int id;
  Type get type => T;
}

const HistoryLayerType<HistoryDrawingLayer> historyDrawingLayerType = HistoryLayerType<HistoryDrawingLayer>(1);
const HistoryLayerType<HistoryReferenceLayer> historyReferenceLayerType = HistoryLayerType<HistoryReferenceLayer>(2);
const HistoryLayerType<HistoryGridLayer> historyGridLayerType = HistoryLayerType<HistoryGridLayer>(3);
const HistoryLayerType<HistoryShadingLayer> historyShadingLayerType = HistoryLayerType<HistoryShadingLayer>(4);
const HistoryLayerType<HistoryDitherLayer> historyDitherLayerType = HistoryLayerType<HistoryDitherLayer>(5);

const List<HistoryLayerType<HistoryLayer>> allHistoryLayerTypes =
<HistoryLayerType<HistoryLayer>>[
  historyDrawingLayerType,
  historyReferenceLayerType,
  historyGridLayerType,
  historyShadingLayerType,
  historyDitherLayerType,
];

final Map<int, Type> historyLayerIdToType = <int, Type>{
  for (final HistoryLayerType<HistoryLayer> descriptor
  in allHistoryLayerTypes)
    descriptor.id: descriptor.type,
};

final Map<Type, int> historyLayerTypeToId = <Type, int>{
  for (final HistoryLayerType<HistoryLayer> descriptor
  in allHistoryLayerTypes)
    descriptor.type: descriptor.id,
};
