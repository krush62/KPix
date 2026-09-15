import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'color'**
  String get color;

  /// No description provided for @createNewProject.
  ///
  /// In en, this message translates to:
  /// **'Create New Project'**
  String get createNewProject;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @projectManager.
  ///
  /// In en, this message translates to:
  /// **'Project Manager'**
  String get projectManager;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortFileNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Order by file name (ascending)'**
  String get sortFileNameAsc;

  /// No description provided for @sortFileNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Order by file name (descending)'**
  String get sortFileNameDesc;

  /// No description provided for @sortDateAsc.
  ///
  /// In en, this message translates to:
  /// **'Order by last modification (ascending)'**
  String get sortDateAsc;

  /// No description provided for @sortDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Order by last modification (descending)'**
  String get sortDateDesc;

  /// No description provided for @importProject.
  ///
  /// In en, this message translates to:
  /// **'Import Project'**
  String get importProject;

  /// No description provided for @deleteSelectedProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Project'**
  String get deleteSelectedProject;

  /// No description provided for @loadSelectedProject.
  ///
  /// In en, this message translates to:
  /// **'Load Selected Project'**
  String get loadSelectedProject;

  /// No description provided for @unsavedChangesSaveFirst.
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes, do you want to save first?'**
  String get unsavedChangesSaveFirst;

  /// No description provided for @openingImage.
  ///
  /// In en, this message translates to:
  /// **'Opening Image...'**
  String get openingImage;

  /// No description provided for @doYouReallyWantToDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this project?'**
  String get doYouReallyWantToDeleteProject;

  /// No description provided for @projectImportSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Project imported successfully!'**
  String get projectImportSuccessful;

  /// No description provided for @couldNotReadProjectDir.
  ///
  /// In en, this message translates to:
  /// **'Could not read the project directory!'**
  String get couldNotReadProjectDir;

  /// No description provided for @noFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No files found!'**
  String get noFilesFound;

  /// No description provided for @keyShift.
  ///
  /// In en, this message translates to:
  /// **'shift'**
  String get keyShift;

  /// No description provided for @keyAlt.
  ///
  /// In en, this message translates to:
  /// **'alt'**
  String get keyAlt;

  /// No description provided for @keyCtrl.
  ///
  /// In en, this message translates to:
  /// **'ctrl'**
  String get keyCtrl;

  /// No description provided for @keySpace.
  ///
  /// In en, this message translates to:
  /// **'space'**
  String get keySpace;

  /// No description provided for @buttonOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get buttonOff;

  /// No description provided for @buttonSolid.
  ///
  /// In en, this message translates to:
  /// **'SLD'**
  String get buttonSolid;

  /// No description provided for @buttonRelative.
  ///
  /// In en, this message translates to:
  /// **'RLT'**
  String get buttonRelative;

  /// No description provided for @buttonGlow.
  ///
  /// In en, this message translates to:
  /// **'GLW'**
  String get buttonGlow;

  /// No description provided for @buttonShade.
  ///
  /// In en, this message translates to:
  /// **'SHD'**
  String get buttonShade;

  /// No description provided for @buttonBevel.
  ///
  /// In en, this message translates to:
  /// **'BVL'**
  String get buttonBevel;

  /// No description provided for @outerStrokeOff.
  ///
  /// In en, this message translates to:
  /// **'No outer stroke'**
  String get outerStrokeOff;

  /// No description provided for @outerStrokeSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid color outer stroke'**
  String get outerStrokeSolid;

  /// No description provided for @outerStrokeRelative.
  ///
  /// In en, this message translates to:
  /// **'Color relative outer stroke'**
  String get outerStrokeRelative;

  /// No description provided for @outerStrokeGlowing.
  ///
  /// In en, this message translates to:
  /// **'Glowing outer stroke'**
  String get outerStrokeGlowing;

  /// No description provided for @outerStrokeShaded.
  ///
  /// In en, this message translates to:
  /// **'Shaded outer stroke'**
  String get outerStrokeShaded;

  /// No description provided for @innerStrokeOff.
  ///
  /// In en, this message translates to:
  /// **'No inner stroke'**
  String get innerStrokeOff;

  /// No description provided for @innerStrokeSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid color inner stroke'**
  String get innerStrokeSolid;

  /// No description provided for @innerStrokeBeveled.
  ///
  /// In en, this message translates to:
  /// **'Beveled inner stroke'**
  String get innerStrokeBeveled;

  /// No description provided for @innerStrokeGlowing.
  ///
  /// In en, this message translates to:
  /// **'Glowing inner stroke'**
  String get innerStrokeGlowing;

  /// No description provided for @innerStrokeShaded.
  ///
  /// In en, this message translates to:
  /// **'Shaded inner stroke'**
  String get innerStrokeShaded;

  /// No description provided for @shadowOff.
  ///
  /// In en, this message translates to:
  /// **'No drop shadow'**
  String get shadowOff;

  /// No description provided for @shadowSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid color drop shadow'**
  String get shadowSolid;

  /// No description provided for @shadowShaded.
  ///
  /// In en, this message translates to:
  /// **'Shaded drop shadow'**
  String get shadowShaded;

  /// A number of steps; count picks the plural form, value is the number as shown (it may carry a sign)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{value} step} other{{value} steps}}'**
  String stepCount(int count, String value);

  /// No description provided for @recursive.
  ///
  /// In en, this message translates to:
  /// **'recursive'**
  String get recursive;

  /// No description provided for @outerStroke.
  ///
  /// In en, this message translates to:
  /// **'Outer Stroke'**
  String get outerStroke;

  /// No description provided for @innerStroke.
  ///
  /// In en, this message translates to:
  /// **'Inner Stroke'**
  String get innerStroke;

  /// No description provided for @dropShadow.
  ///
  /// In en, this message translates to:
  /// **'Drop Shadow'**
  String get dropShadow;

  /// No description provided for @selectOuterStrokeColor.
  ///
  /// In en, this message translates to:
  /// **'Select outer stroke color'**
  String get selectOuterStrokeColor;

  /// No description provided for @darkenBrighten.
  ///
  /// In en, this message translates to:
  /// **'Darken/Brighten'**
  String get darkenBrighten;

  /// No description provided for @darkenBrightenBreak.
  ///
  /// In en, this message translates to:
  /// **'Darken /\nBrighten'**
  String get darkenBrightenBreak;

  /// No description provided for @applyOuterStroke.
  ///
  /// In en, this message translates to:
  /// **'Apply Outer Stroke'**
  String get applyOuterStroke;

  /// No description provided for @selectInnerStrokeColor.
  ///
  /// In en, this message translates to:
  /// **'Select inner stroke color'**
  String get selectInnerStrokeColor;

  /// No description provided for @applyInnerStroke.
  ///
  /// In en, this message translates to:
  /// **'Apply Inner Stroke'**
  String get applyInnerStroke;

  /// No description provided for @horizontal.
  ///
  /// In en, this message translates to:
  /// **'horizontal'**
  String get horizontal;

  /// No description provided for @vertical.
  ///
  /// In en, this message translates to:
  /// **'vertical'**
  String get vertical;

  /// No description provided for @selectDropShadowColor.
  ///
  /// In en, this message translates to:
  /// **'Select drop shadow color'**
  String get selectDropShadowColor;

  /// No description provided for @applyDropShadow.
  ///
  /// In en, this message translates to:
  /// **'Apply Drop Shadow'**
  String get applyDropShadow;

  /// No description provided for @pixelsAbbrev.
  ///
  /// In en, this message translates to:
  /// **'px'**
  String get pixelsAbbrev;

  /// No description provided for @couldNotAddAllLayers.
  ///
  /// In en, this message translates to:
  /// **'Could not add all layers.'**
  String get couldNotAddAllLayers;

  /// No description provided for @invalidLayerIndex.
  ///
  /// In en, this message translates to:
  /// **'Invalid layer insert index.'**
  String get invalidLayerIndex;

  /// No description provided for @couldNotAddMoreLayers.
  ///
  /// In en, this message translates to:
  /// **'Could not add more layers.'**
  String get couldNotAddMoreLayers;

  /// No description provided for @layerAlreadyExistsOnFrame.
  ///
  /// In en, this message translates to:
  /// **'Layer already exists on that frame.'**
  String get layerAlreadyExistsOnFrame;

  /// No description provided for @cannotAddMoreFrames.
  ///
  /// In en, this message translates to:
  /// **'Cannot add more frames.'**
  String get cannotAddMoreFrames;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @noLayerBelow.
  ///
  /// In en, this message translates to:
  /// **'No layer below!'**
  String get noLayerBelow;

  /// No description provided for @cannotMergeFromLinkedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge from a linked layer!'**
  String get cannotMergeFromLinkedLayer;

  /// No description provided for @cannotMergeToLinkedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge to a linked layer!'**
  String get cannotMergeToLinkedLayer;

  /// No description provided for @cannotMergeFromInvisibleLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge from an invisible layer!'**
  String get cannotMergeFromInvisibleLayer;

  /// No description provided for @cannotMergeToInvisibleLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge to an invisible layer!'**
  String get cannotMergeToInvisibleLayer;

  /// No description provided for @cannotMergeFromLockedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge from a locked layer!'**
  String get cannotMergeFromLockedLayer;

  /// No description provided for @cannotMergeToLockedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge to a locked layer!'**
  String get cannotMergeToLockedLayer;

  /// No description provided for @canOnlyMergeWithDrawingLayer.
  ///
  /// In en, this message translates to:
  /// **'Can only merge with drawing layers!'**
  String get canOnlyMergeWithDrawingLayer;

  /// No description provided for @cannotMergeWithActiveEffects.
  ///
  /// In en, this message translates to:
  /// **'Cannot merge layers with active effects!'**
  String get cannotMergeWithActiveEffects;

  /// No description provided for @cannotDeleteLastLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the last layer!'**
  String get cannotDeleteLastLayer;

  /// No description provided for @cannotDeleteFromHiddenLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete from hidden layer!'**
  String get cannotDeleteFromHiddenLayer;

  /// No description provided for @cannotDeleteFromLockedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete from locked layer!'**
  String get cannotDeleteFromLockedLayer;

  /// No description provided for @cannotCutFromHiddenLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot cut from hidden layer!'**
  String get cannotCutFromHiddenLayer;

  /// No description provided for @cannotCutFromLockedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot cut from locked layer!'**
  String get cannotCutFromLockedLayer;

  /// No description provided for @nothingToCopy.
  ///
  /// In en, this message translates to:
  /// **'Nothing to copy!'**
  String get nothingToCopy;

  /// No description provided for @nothingToPasteColorsNotInPalette.
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste: the copied colors are no longer in the palette!'**
  String get nothingToPasteColorsNotInPalette;

  /// No description provided for @cannotPasteToHiddenLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot paste to a hidden layer!'**
  String get cannotPasteToHiddenLayer;

  /// No description provided for @cannotPasteToLockedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot paste to a locked layer!'**
  String get cannotPasteToLockedLayer;

  /// No description provided for @cannotTransformOnHiddenLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot transform on a hidden layer!'**
  String get cannotTransformOnHiddenLayer;

  /// No description provided for @cannotTransformOnLockedLayer.
  ///
  /// In en, this message translates to:
  /// **'Cannot transform on a locked layer!'**
  String get cannotTransformOnLockedLayer;

  /// No description provided for @needAtLeastColorRamps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Need at least 1 color ramp!} other{Need at least {count} color ramps!}}'**
  String needAtLeastColorRamps(int count);

  /// No description provided for @notMoreThanColorRampsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not more than {count} color ramps allowed!'**
  String notMoreThanColorRampsAllowed(int count);

  /// No description provided for @loadingPaletteFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading palette failed!'**
  String get loadingPaletteFailed;

  /// No description provided for @undoStep.
  ///
  /// In en, this message translates to:
  /// **'Undo: {description}'**
  String undoStep(String description);

  /// No description provided for @redoStep.
  ///
  /// In en, this message translates to:
  /// **'Redo: {description}'**
  String redoStep(String description);

  /// No description provided for @historyRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'History restore failed!'**
  String get historyRestoreFailed;

  /// status is the file reader's report and is not translated
  ///
  /// In en, this message translates to:
  /// **'Loading failed ({status})'**
  String loadingFailed(String status);

  /// No description provided for @fileSavedAt.
  ///
  /// In en, this message translates to:
  /// **'File saved at: {path}'**
  String fileSavedAt(String path);

  /// No description provided for @imageImportSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Image imported successfully!'**
  String get imageImportSuccessful;

  /// No description provided for @couldNotConvertImageData.
  ///
  /// In en, this message translates to:
  /// **'Could not convert image data!'**
  String get couldNotConvertImageData;

  /// No description provided for @couldNotCrop.
  ///
  /// In en, this message translates to:
  /// **'Could not crop!'**
  String get couldNotCrop;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @transparencyLocked.
  ///
  /// In en, this message translates to:
  /// **'Transparency locked'**
  String get transparencyLocked;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @buttonRec.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get buttonRec;

  /// No description provided for @buttonDia.
  ///
  /// In en, this message translates to:
  /// **'DIA'**
  String get buttonDia;

  /// No description provided for @buttonIso.
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get buttonIso;

  /// No description provided for @buttonHex.
  ///
  /// In en, this message translates to:
  /// **'HEX'**
  String get buttonHex;

  /// No description provided for @buttonTri.
  ///
  /// In en, this message translates to:
  /// **'TRI'**
  String get buttonTri;

  /// No description provided for @buttonBrk.
  ///
  /// In en, this message translates to:
  /// **'BRK'**
  String get buttonBrk;

  /// No description provided for @button1Point.
  ///
  /// In en, this message translates to:
  /// **'1-Point'**
  String get button1Point;

  /// No description provided for @button2Point.
  ///
  /// In en, this message translates to:
  /// **'2-Point'**
  String get button2Point;

  /// No description provided for @button3Point.
  ///
  /// In en, this message translates to:
  /// **'3-Point'**
  String get button3Point;

  /// No description provided for @rectangularGrid.
  ///
  /// In en, this message translates to:
  /// **'Rectangular Grid'**
  String get rectangularGrid;

  /// No description provided for @diagonalGrid.
  ///
  /// In en, this message translates to:
  /// **'Diagonal Grid'**
  String get diagonalGrid;

  /// No description provided for @isometricGrid.
  ///
  /// In en, this message translates to:
  /// **'Isometric Grid'**
  String get isometricGrid;

  /// No description provided for @hexagonalGrid.
  ///
  /// In en, this message translates to:
  /// **'Hexagonal Grid'**
  String get hexagonalGrid;

  /// No description provided for @triangularGrid.
  ///
  /// In en, this message translates to:
  /// **'Triangular Grid'**
  String get triangularGrid;

  /// No description provided for @bricks.
  ///
  /// In en, this message translates to:
  /// **'Bricks'**
  String get bricks;

  /// No description provided for @onePointPerspective.
  ///
  /// In en, this message translates to:
  /// **'1-Point Perspective'**
  String get onePointPerspective;

  /// No description provided for @twoPointPerspective.
  ///
  /// In en, this message translates to:
  /// **'2-Point Perspective'**
  String get twoPointPerspective;

  /// No description provided for @threePointPerspective.
  ///
  /// In en, this message translates to:
  /// **'3-Point Perspective'**
  String get threePointPerspective;

  /// No description provided for @ascendingSegmentOrder.
  ///
  /// In en, this message translates to:
  /// **'Ascending segment order'**
  String get ascendingSegmentOrder;

  /// No description provided for @ascendingDescendingSegmentOrder.
  ///
  /// In en, this message translates to:
  /// **'Ascending/Descending segment order'**
  String get ascendingDescendingSegmentOrder;

  /// No description provided for @descendingAscendingSegmentOrder.
  ///
  /// In en, this message translates to:
  /// **'Descending/Ascending segment order'**
  String get descendingAscendingSegmentOrder;

  /// No description provided for @descendingSegmentOrder.
  ///
  /// In en, this message translates to:
  /// **'Descending segment order'**
  String get descendingSegmentOrder;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @square.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get square;

  /// No description provided for @rectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// No description provided for @ellipse.
  ///
  /// In en, this message translates to:
  /// **'Ellipse'**
  String get ellipse;

  /// No description provided for @polygon.
  ///
  /// In en, this message translates to:
  /// **'Polygon'**
  String get polygon;

  /// No description provided for @wand.
  ///
  /// In en, this message translates to:
  /// **'Wand'**
  String get wand;

  /// No description provided for @triangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get triangle;

  /// No description provided for @midAngleRectangle.
  ///
  /// In en, this message translates to:
  /// **'Mid-Angle Rectangle'**
  String get midAngleRectangle;

  /// No description provided for @regularPolygon.
  ///
  /// In en, this message translates to:
  /// **'Regular Polygon'**
  String get regularPolygon;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get star;

  /// No description provided for @replaceSelection.
  ///
  /// In en, this message translates to:
  /// **'Replace Selection'**
  String get replaceSelection;

  /// No description provided for @addToSelection.
  ///
  /// In en, this message translates to:
  /// **'Add to Selection'**
  String get addToSelection;

  /// No description provided for @subtractFromSelection.
  ///
  /// In en, this message translates to:
  /// **'Subtract from Selection'**
  String get subtractFromSelection;

  /// No description provided for @intersectWithSelection.
  ///
  /// In en, this message translates to:
  /// **'IntersectWithSelection'**
  String get intersectWithSelection;

  /// No description provided for @pencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get pencil;

  /// No description provided for @shape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get shape;

  /// No description provided for @fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fill;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @colorPicker.
  ///
  /// In en, this message translates to:
  /// **'Color Picker'**
  String get colorPicker;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @sprayCan.
  ///
  /// In en, this message translates to:
  /// **'Spray Can'**
  String get sprayCan;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @stamp.
  ///
  /// In en, this message translates to:
  /// **'Stamp'**
  String get stamp;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @cursorNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get cursorNone;

  /// No description provided for @cursorCrosshair.
  ///
  /// In en, this message translates to:
  /// **'Crosshair'**
  String get cursorCrosshair;

  /// No description provided for @cursorArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get cursorArrow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
