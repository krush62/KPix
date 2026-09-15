// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get close => 'Close';

  @override
  String get color => 'color';

  @override
  String get createNewProject => 'Create New Project';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get presets => 'Presets';

  @override
  String get custom => 'Custom';

  @override
  String get projectManager => 'Project Manager';

  @override
  String get filter => 'Filter';

  @override
  String get sortFileNameAsc => 'Order by file name (ascending)';

  @override
  String get sortFileNameDesc => 'Order by file name (descending)';

  @override
  String get sortDateAsc => 'Order by last modification (ascending)';

  @override
  String get sortDateDesc => 'Order by last modification (descending)';

  @override
  String get importProject => 'Import Project';

  @override
  String get deleteSelectedProject => 'Delete Selected Project';

  @override
  String get loadSelectedProject => 'Load Selected Project';

  @override
  String get unsavedChangesSaveFirst =>
      'There are unsaved changes, do you want to save first?';

  @override
  String get openingImage => 'Opening Image...';

  @override
  String get doYouReallyWantToDeleteProject =>
      'Do you really want to delete this project?';

  @override
  String get projectImportSuccessful => 'Project imported successfully!';

  @override
  String get couldNotReadProjectDir => 'Could not read the project directory!';

  @override
  String get noFilesFound => 'No files found!';

  @override
  String get keyShift => 'shift';

  @override
  String get keyAlt => 'alt';

  @override
  String get keyCtrl => 'ctrl';

  @override
  String get keySpace => 'space';

  @override
  String get buttonOff => 'OFF';

  @override
  String get buttonSolid => 'SLD';

  @override
  String get buttonRelative => 'RLT';

  @override
  String get buttonGlow => 'GLW';

  @override
  String get buttonShade => 'SHD';

  @override
  String get buttonBevel => 'BVL';

  @override
  String get outerStrokeOff => 'No outer stroke';

  @override
  String get outerStrokeSolid => 'Solid color outer stroke';

  @override
  String get outerStrokeRelative => 'Color relative outer stroke';

  @override
  String get outerStrokeGlowing => 'Glowing outer stroke';

  @override
  String get outerStrokeShaded => 'Shaded outer stroke';

  @override
  String get innerStrokeOff => 'No inner stroke';

  @override
  String get innerStrokeSolid => 'Solid color inner stroke';

  @override
  String get innerStrokeBeveled => 'Beveled inner stroke';

  @override
  String get innerStrokeGlowing => 'Glowing inner stroke';

  @override
  String get innerStrokeShaded => 'Shaded inner stroke';

  @override
  String get shadowOff => 'No drop shadow';

  @override
  String get shadowSolid => 'Solid color drop shadow';

  @override
  String get shadowShaded => 'Shaded drop shadow';

  @override
  String stepCount(int count, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$value steps',
      one: '$value step',
    );
    return '$_temp0';
  }

  @override
  String get recursive => 'recursive';

  @override
  String get outerStroke => 'Outer Stroke';

  @override
  String get innerStroke => 'Inner Stroke';

  @override
  String get dropShadow => 'Drop Shadow';

  @override
  String get selectOuterStrokeColor => 'Select outer stroke color';

  @override
  String get darkenBrighten => 'Darken/Brighten';

  @override
  String get darkenBrightenBreak => 'Darken /\nBrighten';

  @override
  String get applyOuterStroke => 'Apply Outer Stroke';

  @override
  String get selectInnerStrokeColor => 'Select inner stroke color';

  @override
  String get applyInnerStroke => 'Apply Inner Stroke';

  @override
  String get horizontal => 'horizontal';

  @override
  String get vertical => 'vertical';

  @override
  String get selectDropShadowColor => 'Select drop shadow color';

  @override
  String get applyDropShadow => 'Apply Drop Shadow';

  @override
  String get pixelsAbbrev => 'px';

  @override
  String get couldNotAddAllLayers => 'Could not add all layers.';

  @override
  String get invalidLayerIndex => 'Invalid layer insert index.';

  @override
  String get couldNotAddMoreLayers => 'Could not add more layers.';

  @override
  String get layerAlreadyExistsOnFrame => 'Layer already exists on that frame.';

  @override
  String get cannotAddMoreFrames => 'Cannot add more frames.';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get noLayerBelow => 'No layer below!';

  @override
  String get cannotMergeFromLinkedLayer => 'Cannot merge from a linked layer!';

  @override
  String get cannotMergeToLinkedLayer => 'Cannot merge to a linked layer!';

  @override
  String get cannotMergeFromInvisibleLayer =>
      'Cannot merge from an invisible layer!';

  @override
  String get cannotMergeToInvisibleLayer =>
      'Cannot merge to an invisible layer!';

  @override
  String get cannotMergeFromLockedLayer => 'Cannot merge from a locked layer!';

  @override
  String get cannotMergeToLockedLayer => 'Cannot merge to a locked layer!';

  @override
  String get canOnlyMergeWithDrawingLayer =>
      'Can only merge with drawing layers!';

  @override
  String get cannotMergeWithActiveEffects =>
      'Cannot merge layers with active effects!';

  @override
  String get cannotDeleteLastLayer => 'Cannot delete the last layer!';

  @override
  String get cannotDeleteFromHiddenLayer => 'Cannot delete from hidden layer!';

  @override
  String get cannotDeleteFromLockedLayer => 'Cannot delete from locked layer!';

  @override
  String get cannotCutFromHiddenLayer => 'Cannot cut from hidden layer!';

  @override
  String get cannotCutFromLockedLayer => 'Cannot cut from locked layer!';

  @override
  String get nothingToCopy => 'Nothing to copy!';

  @override
  String get nothingToPasteColorsNotInPalette =>
      'Nothing to paste: the copied colors are no longer in the palette!';

  @override
  String get cannotPasteToHiddenLayer => 'Cannot paste to a hidden layer!';

  @override
  String get cannotPasteToLockedLayer => 'Cannot paste to a locked layer!';

  @override
  String get cannotTransformOnHiddenLayer =>
      'Cannot transform on a hidden layer!';

  @override
  String get cannotTransformOnLockedLayer =>
      'Cannot transform on a locked layer!';

  @override
  String needAtLeastColorRamps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Need at least $count color ramps!',
      one: 'Need at least 1 color ramp!',
    );
    return '$_temp0';
  }

  @override
  String notMoreThanColorRampsAllowed(int count) {
    return 'Not more than $count color ramps allowed!';
  }

  @override
  String get loadingPaletteFailed => 'Loading palette failed!';

  @override
  String undoStep(String description) {
    return 'Undo: $description';
  }

  @override
  String redoStep(String description) {
    return 'Redo: $description';
  }

  @override
  String get historyRestoreFailed => 'History restore failed!';

  @override
  String loadingFailed(String status) {
    return 'Loading failed ($status)';
  }

  @override
  String fileSavedAt(String path) {
    return 'File saved at: $path';
  }

  @override
  String get imageImportSuccessful => 'Image imported successfully!';

  @override
  String get couldNotConvertImageData => 'Could not convert image data!';

  @override
  String get couldNotCrop => 'Could not crop!';

  @override
  String get hidden => 'Hidden';

  @override
  String get visible => 'Visible';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get transparencyLocked => 'Transparency locked';

  @override
  String get locked => 'Locked';

  @override
  String get buttonRec => 'REC';

  @override
  String get buttonDia => 'DIA';

  @override
  String get buttonIso => 'ISO';

  @override
  String get buttonHex => 'HEX';

  @override
  String get buttonTri => 'TRI';

  @override
  String get buttonBrk => 'BRK';

  @override
  String get button1Point => '1-Point';

  @override
  String get button2Point => '2-Point';

  @override
  String get button3Point => '3-Point';

  @override
  String get rectangularGrid => 'Rectangular Grid';

  @override
  String get diagonalGrid => 'Diagonal Grid';

  @override
  String get isometricGrid => 'Isometric Grid';

  @override
  String get hexagonalGrid => 'Hexagonal Grid';

  @override
  String get triangularGrid => 'Triangular Grid';

  @override
  String get bricks => 'Bricks';

  @override
  String get onePointPerspective => '1-Point Perspective';

  @override
  String get twoPointPerspective => '2-Point Perspective';

  @override
  String get threePointPerspective => '3-Point Perspective';

  @override
  String get ascendingSegmentOrder => 'Ascending segment order';

  @override
  String get ascendingDescendingSegmentOrder =>
      'Ascending/Descending segment order';

  @override
  String get descendingAscendingSegmentOrder =>
      'Descending/Ascending segment order';

  @override
  String get descendingSegmentOrder => 'Descending segment order';

  @override
  String get round => 'Round';

  @override
  String get square => 'Square';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get ellipse => 'Ellipse';

  @override
  String get polygon => 'Polygon';

  @override
  String get wand => 'Wand';

  @override
  String get triangle => 'Triangle';

  @override
  String get midAngleRectangle => 'Mid-Angle Rectangle';

  @override
  String get regularPolygon => 'Regular Polygon';

  @override
  String get star => 'Star';

  @override
  String get replaceSelection => 'Replace Selection';

  @override
  String get addToSelection => 'Add to Selection';

  @override
  String get subtractFromSelection => 'Subtract from Selection';

  @override
  String get intersectWithSelection => 'IntersectWithSelection';

  @override
  String get pencil => 'Pencil';

  @override
  String get shape => 'Shape';

  @override
  String get fill => 'Fill';

  @override
  String get select => 'Select';

  @override
  String get colorPicker => 'Color Picker';

  @override
  String get eraser => 'Eraser';

  @override
  String get text => 'Text';

  @override
  String get sprayCan => 'Spray Can';

  @override
  String get line => 'Line';

  @override
  String get stamp => 'Stamp';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get cursorNone => 'None';

  @override
  String get cursorCrosshair => 'Crosshair';

  @override
  String get cursorArrow => 'Arrow';

  @override
  String get rawModeExplanation =>
      'Raw Mode does not use any values from shading layers or layer settings that use shading.';

  @override
  String get rawMode => 'Raw Mode';

  @override
  String get size => 'Size';

  @override
  String get fillAdjacent => 'Fill Adjacent';

  @override
  String get fillWholeRamp => 'Fill Whole Ramp';

  @override
  String get integerAspectRatio => 'Integer Aspect Ratio';

  @override
  String get segmentSorting => 'Segment Sorting';

  @override
  String get smooth => 'Smooth';

  @override
  String get mode => 'Mode';

  @override
  String get continuous => 'Continuous';

  @override
  String get keep1to1 => 'Keep 1:1';

  @override
  String get wholeRamp => 'Whole Ramp';

  @override
  String get strokeOnly => 'Stroke Only';

  @override
  String get cornerRadius => 'Corner Radius';

  @override
  String get angle => 'Angle';

  @override
  String get cornerCount => 'Corner Count';

  @override
  String get radius => 'Radius';

  @override
  String get blobSize => 'Blob Size';

  @override
  String get intensity => 'Intensity';

  @override
  String get noStamp => 'No Stamp';

  @override
  String get scale => 'Scale';

  @override
  String get gridAlign => 'Grid Align';

  @override
  String get offsetX => 'Offset X';

  @override
  String get offsetY => 'Offset Y';

  @override
  String get font => 'Font';

  @override
  String get available => 'Available';

  @override
  String get invalidFileName => 'Invalid File Name';

  @override
  String get insufficientPermissions => 'Insufficient Permissions';

  @override
  String get overwritingExistingFile => 'Overwriting Existing File';

  @override
  String get rotateCanvas => 'Rotate Canvas';

  @override
  String get flipCanvasHorizontally => 'Flip Canvas Horizontally';

  @override
  String get flipCanvasVertically => 'Flip Canvas Vertically';

  @override
  String get canvasSize => 'Canvas Size';

  @override
  String get offset => 'Offset';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselect => 'Deselect';

  @override
  String get inverseSelection => 'Inverse Selection';

  @override
  String get copy => 'Copy';

  @override
  String get copyMerged => 'Copy Merged';

  @override
  String get cut => 'Cut';

  @override
  String get paste => 'Paste';

  @override
  String get pasteAsNewLayer => 'Paste As New Layer';

  @override
  String get horizontalFlip => 'HorizontalFlip';

  @override
  String get verticalFlip => 'VerticalFlip';

  @override
  String get rotate90Clockwise => 'Rotate 90° Clockwise';

  @override
  String get alignDot => 'Align...';

  @override
  String get delete => 'Delete';

  @override
  String get selectAColor => 'Select a Color';

  @override
  String get newVersionAvailable => 'New version available';

  @override
  String get downloadFromGithub => 'Download from GitHub';

  @override
  String get aPixelArtCreationTool => 'A Pixel Art Creation Tool';

  @override
  String get thisIsFreeSoftwareLicensed =>
      'This is free software licensed under';

  @override
  String get gnuAGPLv3 => 'GNU AGPLv3';

  @override
  String get credits => 'Credits';

  @override
  String get licenses => 'Licenses';

  @override
  String get controlsShortcuts => 'Controls/Shortcuts';

  @override
  String get textToolContent => 'Text Tool Content';

  @override
  String get gui => 'GUI';

  @override
  String get behavior => 'Behavior';

  @override
  String get controlsPC => 'Controls PC';

  @override
  String get controlsStylus => 'Controls Stylus';

  @override
  String get controlsTouch => 'Controls Touch';

  @override
  String get image => 'Image';

  @override
  String get animation => 'Animation';

  @override
  String get palette => 'Palette';

  @override
  String get kpixProject => 'KPix Project';

  @override
  String get export => 'Export';

  @override
  String get format => 'Format';

  @override
  String get texturePack => 'Texture Pack';

  @override
  String get texturePackAnimation => 'Texture Pack Animation';

  @override
  String get scaling => 'Scaling';

  @override
  String get selectionOnly => 'Selection Only';

  @override
  String nFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frames',
      one: '1 frame',
      zero: '0 frames',
    );
    return '$_temp0';
  }

  @override
  String get directory => 'Directory';

  @override
  String get changeDirectory => 'Change Directory';

  @override
  String get fileName => 'File Name';

  @override
  String get exportFile => 'Export File';

  @override
  String imageDimensionsExceed(Object height, Object width) {
    return 'Image dimensions cannot exceed ${width}x$height!';
  }

  @override
  String get couldNotDecodeImage => 'Could not decode image!';

  @override
  String get couldNotLoadFile => 'Could not load file!';

  @override
  String get importImage => 'Import Image';

  @override
  String get file => 'File';

  @override
  String get noFileSelected => 'No File Selected';

  @override
  String get chooseImage => 'Choose Image';

  @override
  String get scaleDown => 'Scale Down';

  @override
  String get createNewPaletteFromImage => 'Create a New Palette From Image';

  @override
  String get maxColorRamps => 'Max Color Ramps';

  @override
  String get maxColorsPerRamp => 'Max Colors per Ramp';

  @override
  String get includeImageAsReferenceLayer => 'Include Image as Reference Layer';

  @override
  String get import => 'Import';

  @override
  String get saveProjectAs => 'Save Project as';

  @override
  String get hueAbb => 'hue';

  @override
  String get satAbb => 'sat';

  @override
  String get valAbb => 'val';

  @override
  String get pressToReset => 'Press to Reset';

  @override
  String get colorCount => 'Color Count';

  @override
  String get baseHue => 'Base Hue';

  @override
  String get hueShift => 'Hue Shift';

  @override
  String get exponent => 'Exponent';

  @override
  String get baseSat => 'Base Sat';

  @override
  String get satShift => 'Sat Shift';

  @override
  String get satCurve => 'Sat Curve';

  @override
  String get valueRange => 'Value Range';

  @override
  String deleteColorRampQuestion(int amount) {
    return 'Do you really want to delete this color ramp?\n$amount pixel(s) will be deleted';
  }

  @override
  String ofThemInSelection(int amount) {
    return '($amount of them in the selection)';
  }

  @override
  String pixelsInClipboard(int amount) {
    return '$amount pixel(s) in the clipboard will no longer be pasted';
  }

  @override
  String get shadingRange => 'Shading Range';

  @override
  String get maxDarken => 'Max Darken';

  @override
  String get maxBrighten => 'Max Brighten';

  @override
  String get layerActionsDot => 'Layer Actions...';

  @override
  String get settings => 'Settings';

  @override
  String get addNewLayerDot => 'Add New Layer...';

  @override
  String get layerSettings => 'Layer Settings';

  @override
  String get symmetryOptions => 'Symmetry Options';

  @override
  String get centerHorizontalRuler => 'Center Horizontal Ruler';

  @override
  String get centerVerticalRuler => 'Center Vertical Ruler';
}
