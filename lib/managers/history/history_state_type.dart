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
  HistoryStateTypeIdentifier.initial: HistoryStateType(identifier: HistoryStateTypeIdentifier.initial, description: "initial", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.generic: HistoryStateType(identifier: HistoryStateTypeIdentifier.generic, description: "generic", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.saveData: HistoryStateType(identifier: HistoryStateTypeIdentifier.saveData, description: "save data", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.loadData: HistoryStateType(identifier: HistoryStateTypeIdentifier.loadData, description: "load data", compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.layerChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerChange, description: "select layer", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.layerDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerDelete, description: "delete layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerMerge: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerMerge, description: "merge layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerDuplicate: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerDuplicate, description: "duplicate layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewDrawing: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewDrawing, description: "add new drawing layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewReference: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewReference, description: "add new reference layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewGrid: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewGrid, description: "add new grid layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewShading: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewShading, description: "add new shading layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerNewDither: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerNewDither, description: "add new dither layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerOrderChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerOrderChange, description: "change layer order", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.layerVisibilityChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerVisibilityChange, description: "layer visibility changed", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.layerLockChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerLockChange, description: "layer lock state changed", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.layerChangeReferenceImage: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerChangeReferenceImage, description: "change reference image", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerRaster: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerRaster, description: "raster layer", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.layerSettingsChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerSettingsChange, description: "layer settings change", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.layerSettingsRaster: HistoryStateType(identifier: HistoryStateTypeIdentifier.layerSettingsRaster, description: "layer settings raster", compressionBehavior: HistoryStateCompressionBehavior.merge),


  HistoryStateTypeIdentifier.selectionNew: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionNew, description: "new selection", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionDeselect: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionDeselect, description: "deselect", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionSelectAll: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionSelectAll, description: "select all", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionInverse: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionInverse, description: "inverse selection", compressionBehavior: HistoryStateCompressionBehavior.delete),
  HistoryStateTypeIdentifier.selectionCut: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionCut, description: "cut selection", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionFlipH: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionFlipH, description: "flip selection horizontally", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionFlipV: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionFlipV, description: "flip selection vertically", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionRotate: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionRotate, description: "rotate selection", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionMove: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionMove, description: "move selection", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.selectionPaste: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionPaste, description: "paste selection", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.selectionDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.selectionDelete, description: "delete selection", compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.canvasSizeChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasSizeChange, description: "change canvas size", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.canvasFlipH: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasFlipH, description: "flip canvas horizontally", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.canvasFlipV: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasFlipV, description: "flip canvas vertically", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.canvasRotate: HistoryStateType(identifier: HistoryStateTypeIdentifier.canvasRotate, description: "rotate canvas", compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.toolPen: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolPen, description: "pen drawing", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolStamp: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolStamp, description: "stamp drawing", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolEraser: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolEraser, description: "erase", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolText: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolText, description: "font drawing", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.toolShape: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolShape, description: "shape drawing", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.toolLine: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolLine, description: "line drawing", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.toolSprayCan: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolSprayCan, description: "spray can drawing", compressionBehavior: HistoryStateCompressionBehavior.merge),
  HistoryStateTypeIdentifier.toolFill: HistoryStateType(identifier: HistoryStateTypeIdentifier.toolFill, description: "fill", compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.colorChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.colorChange, description: "change color selection", compressionBehavior: HistoryStateCompressionBehavior.merge),

  HistoryStateTypeIdentifier.kPalDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalDelete, description: "delete ramp", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalChange, description: "update ramp", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalPaletteReplace: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalPaletteReplace, description: "replace palette", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.kPalAdd: HistoryStateType(identifier: HistoryStateTypeIdentifier.kPalAdd, description: "add new ramp", compressionBehavior: HistoryStateCompressionBehavior.leave),

  HistoryStateTypeIdentifier.timelineFrameAdd: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameAdd, description: "add frame", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineFrameDelete: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameDelete, description: "delete frame", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineFrameMove: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameMove, description: "move frame", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineFrameTimeChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineFrameTimeChange, description: "change frame time", compressionBehavior: HistoryStateCompressionBehavior.leave),
  HistoryStateTypeIdentifier.timelineLoopMarkerChange: HistoryStateType(identifier: HistoryStateTypeIdentifier.timelineLoopMarkerChange, description: "change loop marker", compressionBehavior: HistoryStateCompressionBehavior.leave),

};


enum HistoryStateTypeIdentifier
{
  initial,
  generic,
  saveData,
  loadData,

  layerChange,
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
  frame,
  layer,
  colorSelect,
  layerSelect
}

const Map<HistoryStateTypeIdentifier, HistoryStateTypeGroup> _stateTypeGroupMap = <HistoryStateTypeIdentifier, HistoryStateTypeGroup>
{
  HistoryStateTypeIdentifier.initial: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.generic: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.saveData: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.loadData: HistoryStateTypeGroup.full,

  HistoryStateTypeIdentifier.layerChange: HistoryStateTypeGroup.layerSelect,
  HistoryStateTypeIdentifier.layerDelete: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerMerge: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerDuplicate: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerNewDrawing: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerNewReference: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerNewGrid: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerNewShading: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerNewDither: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerOrderChange: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerVisibilityChange: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.layerLockChange: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.layerChangeReferenceImage: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.layerRaster: HistoryStateTypeGroup.frame,
  HistoryStateTypeIdentifier.layerSettingsChange: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.layerSettingsRaster: HistoryStateTypeGroup.frame,

  HistoryStateTypeIdentifier.selectionNew: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionDeselect: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionSelectAll: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionInverse: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionCut: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionFlipH: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionFlipV: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionRotate: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionMove: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionPaste: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.selectionDelete: HistoryStateTypeGroup.layer,

  HistoryStateTypeIdentifier.canvasSizeChange: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.canvasFlipH: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.canvasFlipV: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.canvasRotate: HistoryStateTypeGroup.full,

  HistoryStateTypeIdentifier.toolPen: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolStamp: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolEraser: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolText: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolShape: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolLine: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolSprayCan: HistoryStateTypeGroup.layer,
  HistoryStateTypeIdentifier.toolFill: HistoryStateTypeGroup.layer,

  HistoryStateTypeIdentifier.colorChange: HistoryStateTypeGroup.colorSelect,

  HistoryStateTypeIdentifier.kPalDelete: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.kPalChange: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.kPalPaletteReplace: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.kPalAdd: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.kPalOrderChange: HistoryStateTypeGroup.full,

  HistoryStateTypeIdentifier.timelineFrameAdd: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.timelineFrameDelete: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.timelineFrameMove: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.timelineFrameTimeChange: HistoryStateTypeGroup.full,
  HistoryStateTypeIdentifier.timelineLoopMarkerChange: HistoryStateTypeGroup.full,
};



class HistoryStateType
{
  final String description;
  final HistoryStateCompressionBehavior compressionBehavior;
  final HistoryStateTypeIdentifier identifier;
  const HistoryStateType({required this.description, required this.compressionBehavior, required this.identifier});

  @override
  String toString()
  {
    return description;
  }
  bool get isLeaveCompression => compressionBehavior == HistoryStateCompressionBehavior.leave;
  bool get isMergeCompression => compressionBehavior == HistoryStateCompressionBehavior.merge;
  bool get isDeleteCompression => compressionBehavior == HistoryStateCompressionBehavior.delete;
  HistoryStateTypeGroup get group => _stateTypeGroupMap[identifier] ?? HistoryStateTypeGroup.full;
}
