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
}
