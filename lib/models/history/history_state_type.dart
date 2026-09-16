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


const Map<HistoryStateTypeIdentifier, HistoryStateType> allStateTypeMap =
<HistoryStateTypeIdentifier, HistoryStateType>{
  HistoryStateTypeIdentifier.initial: HistoryStateType(identifier: HistoryStateTypeIdentifier.initial, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.generic: HistoryStateType(identifier: HistoryStateTypeIdentifier.generic, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.saveData: HistoryStateType(identifier: HistoryStateTypeIdentifier.saveData, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.loadData: HistoryStateType(identifier: HistoryStateTypeIdentifier.loadData, compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.layerChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerChange, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.layerChangeWithSelection: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerChangeWithSelection, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerDelete, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerMerge: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerMerge, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerDuplicate: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerDuplicate, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewDrawing: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewDrawing, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewReference: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewReference, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewGrid: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewGrid, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewShading: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewShading, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewDither: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewDither, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerOrderChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerOrderChange, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.layerVisibilityChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerVisibilityChange, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.layerLockChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerLockChange, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.layerChangeReferenceImage: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerChangeReferenceImage, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerRaster: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerRaster, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerSettingsChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerSettingsChange, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.layerSettingsRaster: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerSettingsRaster, compressionBehavior: HistoryStateCompressionBehavior.merge),


  HistoryStateTypeIdentifier.selectionNew: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionNew, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionDeselect: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionDeselect, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionSelectAll: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionSelectAll, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionInverse: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionInverse, compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionCut: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionCut, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionFlipH: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionFlipH, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionFlipV: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionFlipV, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionRotate: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionRotate, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionMove: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionMove, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.selectionPaste: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionPaste, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionNewLayer: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionNewLayer, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionDelete, compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.canvasSizeChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasSizeChange, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.canvasFlipH: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasFlipH, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.canvasFlipV: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasFlipV, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.canvasRotate: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasRotate, compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.toolPen: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolPen, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolStamp: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolStamp, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolEraser: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolEraser, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolText: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolText, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.toolShape: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolShape, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.toolLine: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolLine, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.toolSprayCan: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolSprayCan, compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolFill: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolFill, compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.colorChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.colorChange, compressionBehavior: HistoryStateCompressionBehavior.merge),

  HistoryStateTypeIdentifier.kPalDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalDelete, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalChange, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalPaletteReplace: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalPaletteReplace, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalAdd: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalAdd, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalOrderChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalOrderChange, compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.timelineFrameAdd: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameAdd, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineFrameDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameDelete, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineFrameMove: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameMove, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineFrameTimeChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameTimeChange, compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineLoopMarkerChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineLoopMarkerChange, compressionBehavior: HistoryStateCompressionBehavior.leave),

};


enum HistoryStateTypeIdentifier
{
  initial,
  generic,
  saveData,
  loadData,

  layerChange,
  layerChangeWithSelection,
  layerDelete,
  layerMerge,
  layerDuplicate,
  layerNewDrawing,
  layerNewReference,
  layerNewGrid,
  layerNewShading,
  layerNewDither,
  layerOrderChange,
  layerVisibilityChange,
  layerLockChange,
  layerChangeReferenceImage,
  layerRaster,
  layerSettingsChange,
  layerSettingsRaster,

  selectionNew,
  selectionDeselect,
  selectionSelectAll,
  selectionInverse,
  selectionCut,
  selectionFlipH,
  selectionFlipV,
  selectionRotate,
  selectionMove,
  selectionPaste,
  selectionNewLayer,
  selectionDelete,

  canvasSizeChange,
  canvasFlipH,
  canvasFlipV,
  canvasRotate,

  toolPen,
  toolStamp,
  toolEraser,
  toolText,
  toolShape,
  toolLine,
  toolSprayCan,
  toolFill,

  colorChange,

  kPalDelete,
  kPalChange,
  kPalPaletteReplace,
  kPalAdd,
  kPalOrderChange,

  timelineFrameAdd,
  timelineFrameDelete,
  timelineFrameMove,
  timelineFrameTimeChange,
  timelineLoopMarkerChange,
}

enum HistoryStateCompressionBehavior
{
  leave,
  merge,
  delete
}

enum HistoryStateTypeGroup
{
  full,
  layerFull,
  colorSelect,
  layerSelect,
}

const Map<HistoryStateTypeIdentifier, HistoryStateTypeGroup> _stateTypeGroupMap = <HistoryStateTypeIdentifier, HistoryStateTypeGroup>
{
  HistoryStateTypeIdentifier.initial: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.generic: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.saveData: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.loadData: HistoryStateTypeGroup.full,

  HistoryStateTypeIdentifier.layerChange: HistoryStateTypeGroup.layerSelect, //layer select
  HistoryStateTypeIdentifier.layerChangeWithSelection: HistoryStateTypeGroup.layerFull,

  HistoryStateTypeIdentifier.layerDelete: HistoryStateTypeGroup.full, //layer delete
  HistoryStateTypeIdentifier.layerMerge: HistoryStateTypeGroup.full, //layer merge
  HistoryStateTypeIdentifier.layerDuplicate: HistoryStateTypeGroup.full, //layer new
  HistoryStateTypeIdentifier.layerNewDrawing: HistoryStateTypeGroup.full, //layer new
  HistoryStateTypeIdentifier.layerNewReference: HistoryStateTypeGroup.full, //layer new
  HistoryStateTypeIdentifier.layerNewGrid: HistoryStateTypeGroup.full, //layer new
  HistoryStateTypeIdentifier.layerNewShading: HistoryStateTypeGroup.full, //layer new
  HistoryStateTypeIdentifier.layerNewDither: HistoryStateTypeGroup.full, //layer new
  HistoryStateTypeIdentifier.layerOrderChange: HistoryStateTypeGroup.full, //frame meta
  HistoryStateTypeIdentifier.layerVisibilityChange: HistoryStateTypeGroup.layerFull, //layer meta
  HistoryStateTypeIdentifier.layerLockChange: HistoryStateTypeGroup.layerFull, //layer meta
  HistoryStateTypeIdentifier.layerChangeReferenceImage: HistoryStateTypeGroup.layerFull, //layer meta
  HistoryStateTypeIdentifier.layerRaster: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.layerSettingsChange: HistoryStateTypeGroup.layerFull, //layer meta
  HistoryStateTypeIdentifier.layerSettingsRaster: HistoryStateTypeGroup.full,

  HistoryStateTypeIdentifier.selectionNew: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionDeselect: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionSelectAll: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionInverse: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionCut: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionFlipH: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionFlipV: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionRotate: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionMove: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionPaste: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.selectionNewLayer: HistoryStateTypeGroup.full, //full — creates a new layer
  HistoryStateTypeIdentifier.selectionDelete: HistoryStateTypeGroup.layerFull, //layer full

  HistoryStateTypeIdentifier.canvasSizeChange: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.canvasFlipH: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.canvasFlipV: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.canvasRotate: HistoryStateTypeGroup.full, //full

  HistoryStateTypeIdentifier.toolPen: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolStamp: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolEraser: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolText: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolShape: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolLine: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolSprayCan: HistoryStateTypeGroup.layerFull, //layer full
  HistoryStateTypeIdentifier.toolFill: HistoryStateTypeGroup.layerFull, //layer full

  HistoryStateTypeIdentifier.colorChange: HistoryStateTypeGroup.colorSelect, //color select

  HistoryStateTypeIdentifier.kPalDelete: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.kPalChange: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.kPalPaletteReplace: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.kPalAdd: HistoryStateTypeGroup.full, //full
  HistoryStateTypeIdentifier.kPalOrderChange: HistoryStateTypeGroup.full, //full

  HistoryStateTypeIdentifier.timelineFrameAdd: HistoryStateTypeGroup.full, //frame add
  HistoryStateTypeIdentifier.timelineFrameDelete: HistoryStateTypeGroup.full, //frame delete
  HistoryStateTypeIdentifier.timelineFrameMove: HistoryStateTypeGroup.full, //timeline
  HistoryStateTypeIdentifier.timelineFrameTimeChange: HistoryStateTypeGroup.full, //timeline
  HistoryStateTypeIdentifier.timelineLoopMarkerChange: HistoryStateTypeGroup.full, //timeline
};



class HistoryStateType
{
  final HistoryStateCompressionBehavior compressionBehavior;
  final HistoryStateTypeIdentifier identifier;
  const HistoryStateType({required this.identifier, required this.compressionBehavior});


  bool get isLeaveCompression => compressionBehavior == HistoryStateCompressionBehavior.leave;
  bool get isMergeCompression => compressionBehavior == HistoryStateCompressionBehavior.merge;
  bool get isDeleteCompression => compressionBehavior == HistoryStateCompressionBehavior.delete;
  HistoryStateTypeGroup get group => _stateTypeGroupMap[identifier] ?? HistoryStateTypeGroup.full;
}
