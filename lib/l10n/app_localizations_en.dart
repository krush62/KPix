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
  String get lockAspectRatio => 'Lock Aspect Ratio';

  @override
  String get exitApplication => 'Exit Application';

  @override
  String get openProjectManager => 'Open Project Manager';

  @override
  String get createProject => 'Create Project';

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
  String get openingImageDot => 'Opening Image...';

  @override
  String get doYouReallyWantToDeleteProject =>
      'Do you really want to delete this project?';

  @override
  String get projectImportSuccessful => 'Project imported successfully!';

  @override
  String get couldNotOpenFile => 'Could not open file!';

  @override
  String get projectWithSameNameExists =>
      'A project with the same name already exists!';

  @override
  String get pleaseSelectAKPixFile => 'Please select a KPix file!';

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
  String get cropToSelection => 'Crop To Selection';

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
  String get textToolDefaultText => 'Text';

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
  String get pngSequence => 'PNG Sequence';

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
  String frameNumber(int number) {
    return 'Frame $number';
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
  String imageDimensionsExceed(int width, int height) {
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

  @override
  String get addNewDrawingLayer => 'Add New Drawing Layer';

  @override
  String get addNewShadingLayer => 'Add New Shading Layer';

  @override
  String get addNewDitherLayer => 'Add New Dither Layer';

  @override
  String get addNewReferenceLayer => 'Add New Reference Layer';

  @override
  String get addNewGridLayer => 'Add New Grid Layer';

  @override
  String get deleteLayer => 'Delete Layer';

  @override
  String get duplicateLayer => 'Duplicate Layer';

  @override
  String get mergeDownLayer => 'Merge Down Layer';

  @override
  String get unlinkLayer => 'Unlink Layer / Make Unique';

  @override
  String get newProject => 'New Project';

  @override
  String get openProject => 'Open Project';

  @override
  String get rasterLayer => 'Raster Layer';

  @override
  String get saveProject => 'Save Project';

  @override
  String get exportProjectPalette => 'Export Project/Palette';

  @override
  String get centerHorizontally => 'Center Horizontally';

  @override
  String get centerVertically => 'Center Vertically';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get top => 'Top';

  @override
  String get bottom => 'Bottom';

  @override
  String get editColorRamp => 'Edit Color Ramp';

  @override
  String nColors(int amount) {
    return '$amount colors';
  }

  @override
  String nRampsColors(int rampAmount, int colorAmount) {
    return '$rampAmount ramps | $colorAmount colors';
  }

  @override
  String get remapExistingColors =>
      'Do you want to remap the existing colors (all pixels will be deleted otherwise)?';

  @override
  String get wantToDeletePalette =>
      'Do you really want to delete this palette?';

  @override
  String get paletteManager => 'Palette Manager';

  @override
  String get importPalette => 'Import Palette';

  @override
  String get saveCurrentPalette => 'Save Current Palette';

  @override
  String get deleteSelectedPalette => 'Delete Selected Palette';

  @override
  String get appendToCurrentPalette => 'Append to Current Palette';

  @override
  String get applySelectedPalette => 'Apply Selected Palette';

  @override
  String get addNewColorRamp => 'Add New Color Ramp';

  @override
  String get savePalette => 'Save Palette';

  @override
  String get defaultPalette => 'Default';

  @override
  String get errorSavingPalette => 'Error saving palette!';

  @override
  String paletteSavedAt(String path) {
    return 'Palette saved successfully at $path.';
  }

  @override
  String get paletteWithSameNameExists =>
      'A palette with the same name already exists!';

  @override
  String get pleaseSelectAKPalFile => 'Please select a KPal file!';

  @override
  String get paletteImportSuccessful => 'Import successful!';

  @override
  String get paletteImportFailed => 'Import failed!';

  @override
  String get insufficientPermissionsForDir =>
      'Insufficient permissions for the selected directory!';

  @override
  String get undoSteps => 'Undo Steps';

  @override
  String get selectInsertedLayers => 'Select Inserted Layers';

  @override
  String get defaultShadingLayerSettings => 'Default Shading Layer Settings';

  @override
  String get defaultFrameTime => 'Default Frame Time';

  @override
  String get showReferenceLayersOutsideOfCanvas =>
      'Show Reference Layers outside of canvas';

  @override
  String get projectDirectory => 'Project Directory';

  @override
  String get defaultDir => 'Default';

  @override
  String get customDir => 'Custom';

  @override
  String get chooseDirectory => 'Choose Directory';

  @override
  String get mouseCursor => 'Mouse Cursor';

  @override
  String get themePreferences => 'Theme Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get checkerboardPreferences => 'Checkerboard Preferences';

  @override
  String get checkerboardSize => 'Checkerboard Size';

  @override
  String get checkerboardContrast => 'Checkerboard Contrast';

  @override
  String get palettePreferences => 'Palette Preferences';

  @override
  String get colorNaming => 'Color Naming';

  @override
  String get borderPreferences => 'Border Preferences';

  @override
  String get toolOutlineOpacity => 'Tool Outline Opacity';

  @override
  String get selectionOutlineOpacity => 'Selection Outline Opacity';

  @override
  String get pulsatingSelectionOutline => 'Pulsating Selection Outline';

  @override
  String get canvasBorerOpacity => 'Canvas Border Opacity';

  @override
  String get pollingTimeToCheck =>
      'Polling time to check for presses of stylus buttons.';

  @override
  String get pollInterval => 'Poll Interval';

  @override
  String get timeThatNeedsToBeHeldDown =>
      'Time that needs to be held down for a long press.';

  @override
  String get longPressDelay => 'Long Press Delay';

  @override
  String get distanceThatMustBeMoved =>
      'Distance that must be moved during a long press to cancel it.';

  @override
  String get longPressCancelDistance => 'Long Press Cancel Distance';

  @override
  String get distanceThatNeedsToBeMovedVertically =>
      'Distance that needs to be moved vertically to zoom in or out.';

  @override
  String get zoomStepDistance => 'Zoom Step Distance';

  @override
  String get distanceThatNeedsToBeMovedHorizontally =>
      'Distance that needs to be moved horizontally to change the size of the current tool.';

  @override
  String get toolSizeStepDistance => 'Tool Size Step Distance';

  @override
  String get timeoutForPickingAColor => 'Timeout for picking a color.';

  @override
  String get colorPickTimeout => 'Color Pick Timeout';

  @override
  String get touchDelay => 'Touch Delay';

  @override
  String get stampManager => 'Stamp Manager';

  @override
  String get deleteSelectedStamp => 'Delete Selected Stamp';

  @override
  String get loadSelectedStamp => 'Load Selected Stamp';

  @override
  String get doYouReallyWantToDeleteStamp =>
      'Do you really want to delete this stamp?';

  @override
  String get frameBlending => 'Frame Blending';

  @override
  String get enabled => 'Enabled';

  @override
  String get framesBefore => 'Frames Before';

  @override
  String get wrapAround => 'Wrap Around';

  @override
  String get framesAfter => 'Frames After';

  @override
  String get opacity => 'Opacity';

  @override
  String get gradual => 'Gradual';

  @override
  String get tinting => 'Tinting';

  @override
  String get activeLayerOnly => 'Active Layer Only';

  @override
  String get cancel => 'Cancel';

  @override
  String get applyToAllFrames => 'Apply to All Frames';

  @override
  String get applyToCurrentFrame => 'Apply to Current Frame';

  @override
  String get collapseTimeline => 'Collapse Timeline';

  @override
  String get expandTimeline => 'Expand Timeline';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get loopStartMarker => 'Loop Start Marker';

  @override
  String get loopEndMarker => 'Loop End Marker';

  @override
  String get changeDuration => 'Change Duration';

  @override
  String get moveFrameLeft => 'Move Frame Left';

  @override
  String get moveFrame => 'Move Frame';

  @override
  String get moveFrameRight => 'Move Frame Right';

  @override
  String get addFrameLeft => 'Add Frame Left';

  @override
  String get addFrame => 'Add Frame';

  @override
  String get addFrameRight => 'Add Frame Right';

  @override
  String get copyFrameLeft => 'Copy Frame Left';

  @override
  String get copyFrame => 'Copy Frame';

  @override
  String get copyFrameRight => 'Copy Frame Right';

  @override
  String get createLinkedFrameLeft => 'Create Linked Frame Left';

  @override
  String get createLinkedFrame => 'Create Linked Frame';

  @override
  String get createLinkedFrameRight => 'Create Linked Frame Right';

  @override
  String get deleteFrame => 'Delete Frame';

  @override
  String get toggle => 'Toggle';

  @override
  String get grid => 'Grid';

  @override
  String get gridButton => 'GRID';

  @override
  String get perspective => 'Perspective';

  @override
  String get perspectiveButton => 'PERSPECTIVE';

  @override
  String get brightness => 'Brightness';

  @override
  String get interval => 'Interval';

  @override
  String get intervalX => 'Interval X';

  @override
  String get intervalY => 'Interval Y';

  @override
  String get horizon => 'Horizon';

  @override
  String get vanishingPoint => 'Vanishing Point';

  @override
  String get horPoints => 'Hor Points';

  @override
  String get verPoint => 'Ver Point';

  @override
  String couldNotLoadImageFrom(String location) {
    return 'Could not load image from $location.';
  }

  @override
  String resetSetting(String setting) {
    return 'Reset $setting';
  }

  @override
  String get noFileLoaded => 'No File Loaded';

  @override
  String get openReferenceImage => 'Open Reference Image';

  @override
  String get aspectRatio => 'Aspect Ratio';

  @override
  String get zoom => 'Zoom';

  @override
  String get expandHorizontallyAndCenter =>
      'Expand horizontally and center by keeping the current aspect ratio';

  @override
  String get expandVerticallyAndCenter =>
      'Expand vertically and center by keeping the current aspect ratio';

  @override
  String get fitsImageIntoCanvas =>
      'Fits the image into the canvas (changes aspect ratio)';

  @override
  String get contrast => 'Contrast';

  @override
  String get saturation => 'Saturation';

  @override
  String get warmth => 'Warmth';

  @override
  String get shading => 'Shading';

  @override
  String get currentRampOnly => 'Current Ramp Only';

  @override
  String get direction => 'Direction';

  @override
  String get loadingDot => 'Loading...';

  @override
  String get thisDeviceDoesNotSupportResolution =>
      'This device does not support the minimum logical resolution to run this application.';

  @override
  String get customProjectDirectoryInvalid =>
      'Custom Project directory invalid. Switching to default directory.';

  @override
  String get couldNotCreateInternalDirectories =>
      'Could not create internal directories.';

  @override
  String get couldNotInitializeApp => 'Could not initialize the application.';

  @override
  String get aCustomProjectDirectoryIsUsed =>
      'A custom project directory is used, but KPix does not have the \"All files access\" permission. Project files created by other apps (e.g. sync tools) might not be shown.\nDo you want to open the system settings to grant the permission?';

  @override
  String get workRecovered => 'Work Recovered';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get about => 'About';

  @override
  String get preferences => 'Preferences';

  @override
  String get saveDot => 'Save...';

  @override
  String get newOpenDot => 'New/Open...';

  @override
  String get errorImportingImage => 'Error importing image.';

  @override
  String get thereAreUnsavedChanges =>
      'There are unsaved changes, do you want to save first?';

  @override
  String get importingImageDot => 'Importing Image...';

  @override
  String get exportingDot => 'Exporting...';

  @override
  String get movingProjectFilesDot => 'Moving project files...';

  @override
  String get targetDirCouldNotBeCreated =>
      'The directory does not exist and could not be created!';

  @override
  String dirAlreadyContainsFile(String fileName) {
    return 'The directory already contains a file named $fileName!';
  }

  @override
  String couldNotMoveFile(String fileName) {
    return 'Could not move file $fileName!';
  }

  @override
  String get unexpectedErrorMovingProjectFiles =>
      'An unexpected error occurred while moving project files!';

  @override
  String changedProjectDirectoryFiles(String directory, int count) {
    return 'Changed project directory to $directory (moved $count project file(s)).';
  }

  @override
  String projectDirWasNotChanged(String message) {
    return 'The project directory was not changed!\n$message';
  }

  @override
  String exportedPaletteTo(String path) {
    return 'Exported palette to: $path';
  }

  @override
  String get errorExportingPaletteFile => 'Error exporting palette file.';

  @override
  String exportedTo(String path) {
    return 'Exported to: $path';
  }

  @override
  String get errorExportingFile => 'Error exporting file!';

  @override
  String get withoutAllFilesWarning =>
      'Without the \"All files access\" permission, KPix cannot see project files that were created by other apps (e.g. sync tools) in this directory.\nDo you want to open the system settings to grant the permission?';

  @override
  String get allFilesAccessNotNeededWarning =>
      'The \"All files access\" permission is not needed for the default project directory.\nDo you want to open the system settings to revoke the permission?';

  @override
  String get initial => 'Initial';

  @override
  String get generic => 'Generic';

  @override
  String get saveData => 'Save Data';

  @override
  String get loadData => 'Load Data';

  @override
  String get selectLayer => 'Select Layer';

  @override
  String get selectLayerMoveSelection => 'Select Layer (Move Selection)';

  @override
  String get mergeLayer => 'Merge Layer';

  @override
  String get changeLayerOrder => 'Change Layer Order';

  @override
  String get layerVisibilityChanged => 'Layer Visibility Changed';

  @override
  String get layerLockStateChanged => 'Layer Lock State Changed';

  @override
  String get changeReferenceImage => 'Change Reference Image';

  @override
  String get layerSettingsChange => 'Layer Settings Change';

  @override
  String get layerSettingsRaster => 'Layer Settings Raster';

  @override
  String get newSelection => 'New Selection';

  @override
  String get cutSelection => 'Cut Selection';

  @override
  String get flipSelectionHorizontally => 'Flip Selection Horizontally';

  @override
  String get flipSelectionVertically => 'Flip Selection Vertically';

  @override
  String get rotateSelection => 'Rotate Selection';

  @override
  String get moveSelection => 'Move Selection';

  @override
  String get pasteSelection => 'Paste Selection';

  @override
  String get selectionToNewLayer => 'Selection To New Layer';

  @override
  String get deleteSelection => 'Delete Selection';

  @override
  String get changeCanvasSize => 'Change Canvas Size';

  @override
  String get penDrawing => 'Pen Drawing';

  @override
  String get stampDrawing => 'Stamp Drawing';

  @override
  String get erase => 'Erase';

  @override
  String get fontDrawing => 'Font Drawing';

  @override
  String get shapeDrawing => 'Shape Drawing';

  @override
  String get lineDrawing => 'Line Drawing';

  @override
  String get sprayCanDrawing => 'Spray Can Drawing';

  @override
  String get changeColorSelection => 'Change Color Selection';

  @override
  String get deleteRamp => 'Delete Ramp';

  @override
  String get updateRamp => 'Update Ramp';

  @override
  String get replacePalette => 'Replace Palette';

  @override
  String get addNewRamp => 'Add New Ramp';

  @override
  String get changeRampOrder => 'Change Ramp Order';

  @override
  String get changeFrameTime => 'Change Frame Time';

  @override
  String get changeLoopMarker => 'Change Loop Marker';
}
