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

  /// No description provided for @lockAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Lock Aspect Ratio'**
  String get lockAspectRatio;

  /// No description provided for @exitApplication.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitApplication;

  /// No description provided for @openProjectManager.
  ///
  /// In en, this message translates to:
  /// **'Open Project Manager'**
  String get openProjectManager;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

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

  /// No description provided for @openingImageDot.
  ///
  /// In en, this message translates to:
  /// **'Opening Image...'**
  String get openingImageDot;

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

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file!'**
  String get couldNotOpenFile;

  /// No description provided for @projectWithSameNameExists.
  ///
  /// In en, this message translates to:
  /// **'A project with the same name already exists!'**
  String get projectWithSameNameExists;

  /// No description provided for @pleaseSelectAKPixFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a KPix file!'**
  String get pleaseSelectAKPixFile;

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

  /// No description provided for @cropToSelection.
  ///
  /// In en, this message translates to:
  /// **'Crop To Selection'**
  String get cropToSelection;

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

  /// No description provided for @textToolDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textToolDefaultText;

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

  /// No description provided for @rawModeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Raw Mode does not use any values from shading layers or layer settings that use shading.'**
  String get rawModeExplanation;

  /// No description provided for @rawMode.
  ///
  /// In en, this message translates to:
  /// **'Raw Mode'**
  String get rawMode;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @fillAdjacent.
  ///
  /// In en, this message translates to:
  /// **'Fill Adjacent'**
  String get fillAdjacent;

  /// No description provided for @fillWholeRamp.
  ///
  /// In en, this message translates to:
  /// **'Fill Whole Ramp'**
  String get fillWholeRamp;

  /// No description provided for @integerAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Integer Aspect Ratio'**
  String get integerAspectRatio;

  /// No description provided for @segmentSorting.
  ///
  /// In en, this message translates to:
  /// **'Segment Sorting'**
  String get segmentSorting;

  /// No description provided for @smooth.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get smooth;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @continuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get continuous;

  /// No description provided for @keep1to1.
  ///
  /// In en, this message translates to:
  /// **'Keep 1:1'**
  String get keep1to1;

  /// No description provided for @wholeRamp.
  ///
  /// In en, this message translates to:
  /// **'Whole Ramp'**
  String get wholeRamp;

  /// No description provided for @strokeOnly.
  ///
  /// In en, this message translates to:
  /// **'Stroke Only'**
  String get strokeOnly;

  /// No description provided for @cornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get cornerRadius;

  /// No description provided for @angle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get angle;

  /// No description provided for @cornerCount.
  ///
  /// In en, this message translates to:
  /// **'Corner Count'**
  String get cornerCount;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @blobSize.
  ///
  /// In en, this message translates to:
  /// **'Blob Size'**
  String get blobSize;

  /// No description provided for @intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensity;

  /// No description provided for @noStamp.
  ///
  /// In en, this message translates to:
  /// **'No Stamp'**
  String get noStamp;

  /// No description provided for @scale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scale;

  /// No description provided for @gridAlign.
  ///
  /// In en, this message translates to:
  /// **'Grid Align'**
  String get gridAlign;

  /// No description provided for @offsetX.
  ///
  /// In en, this message translates to:
  /// **'Offset X'**
  String get offsetX;

  /// No description provided for @offsetY.
  ///
  /// In en, this message translates to:
  /// **'Offset Y'**
  String get offsetY;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @invalidFileName.
  ///
  /// In en, this message translates to:
  /// **'Invalid File Name'**
  String get invalidFileName;

  /// No description provided for @insufficientPermissions.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Permissions'**
  String get insufficientPermissions;

  /// No description provided for @overwritingExistingFile.
  ///
  /// In en, this message translates to:
  /// **'Overwriting Existing File'**
  String get overwritingExistingFile;

  /// No description provided for @rotateCanvas.
  ///
  /// In en, this message translates to:
  /// **'Rotate Canvas'**
  String get rotateCanvas;

  /// No description provided for @flipCanvasHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Flip Canvas Horizontally'**
  String get flipCanvasHorizontally;

  /// No description provided for @flipCanvasVertically.
  ///
  /// In en, this message translates to:
  /// **'Flip Canvas Vertically'**
  String get flipCanvasVertically;

  /// No description provided for @canvasSize.
  ///
  /// In en, this message translates to:
  /// **'Canvas Size'**
  String get canvasSize;

  /// No description provided for @offset.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get offset;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @inverseSelection.
  ///
  /// In en, this message translates to:
  /// **'Inverse Selection'**
  String get inverseSelection;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyMerged.
  ///
  /// In en, this message translates to:
  /// **'Copy Merged'**
  String get copyMerged;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @pasteAsNewLayer.
  ///
  /// In en, this message translates to:
  /// **'Paste As New Layer'**
  String get pasteAsNewLayer;

  /// No description provided for @horizontalFlip.
  ///
  /// In en, this message translates to:
  /// **'HorizontalFlip'**
  String get horizontalFlip;

  /// No description provided for @verticalFlip.
  ///
  /// In en, this message translates to:
  /// **'VerticalFlip'**
  String get verticalFlip;

  /// No description provided for @rotate90Clockwise.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90° Clockwise'**
  String get rotate90Clockwise;

  /// No description provided for @alignDot.
  ///
  /// In en, this message translates to:
  /// **'Align...'**
  String get alignDot;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @selectAColor.
  ///
  /// In en, this message translates to:
  /// **'Select a Color'**
  String get selectAColor;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionAvailable;

  /// No description provided for @downloadFromGithub.
  ///
  /// In en, this message translates to:
  /// **'Download from GitHub'**
  String get downloadFromGithub;

  /// No description provided for @aPixelArtCreationTool.
  ///
  /// In en, this message translates to:
  /// **'A Pixel Art Creation Tool'**
  String get aPixelArtCreationTool;

  /// No description provided for @thisIsFreeSoftwareLicensed.
  ///
  /// In en, this message translates to:
  /// **'This is free software licensed under'**
  String get thisIsFreeSoftwareLicensed;

  /// No description provided for @gnuAGPLv3.
  ///
  /// In en, this message translates to:
  /// **'GNU AGPLv3'**
  String get gnuAGPLv3;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @controlsShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Controls/Shortcuts'**
  String get controlsShortcuts;

  /// No description provided for @textToolContent.
  ///
  /// In en, this message translates to:
  /// **'Text Tool Content'**
  String get textToolContent;

  /// No description provided for @gui.
  ///
  /// In en, this message translates to:
  /// **'GUI'**
  String get gui;

  /// No description provided for @behavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get behavior;

  /// No description provided for @controlsPC.
  ///
  /// In en, this message translates to:
  /// **'Controls PC'**
  String get controlsPC;

  /// No description provided for @controlsStylus.
  ///
  /// In en, this message translates to:
  /// **'Controls Stylus'**
  String get controlsStylus;

  /// No description provided for @controlsTouch.
  ///
  /// In en, this message translates to:
  /// **'Controls Touch'**
  String get controlsTouch;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @animation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get animation;

  /// No description provided for @palette.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get palette;

  /// No description provided for @kpixProject.
  ///
  /// In en, this message translates to:
  /// **'KPix Project'**
  String get kpixProject;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @texturePack.
  ///
  /// In en, this message translates to:
  /// **'Texture Pack'**
  String get texturePack;

  /// No description provided for @texturePackAnimation.
  ///
  /// In en, this message translates to:
  /// **'Texture Pack Animation'**
  String get texturePackAnimation;

  /// No description provided for @pngSequence.
  ///
  /// In en, this message translates to:
  /// **'PNG Sequence'**
  String get pngSequence;

  /// No description provided for @scaling.
  ///
  /// In en, this message translates to:
  /// **'Scaling'**
  String get scaling;

  /// No description provided for @selectionOnly.
  ///
  /// In en, this message translates to:
  /// **'Selection Only'**
  String get selectionOnly;

  /// frame plural
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 frames} =1{1 frame} other{{count} frames}}'**
  String nFrames(int count);

  /// No description provided for @frameNumber.
  ///
  /// In en, this message translates to:
  /// **'Frame {number}'**
  String frameNumber(int number);

  /// No description provided for @directory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @changeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Change Directory'**
  String get changeDirectory;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @exportFile.
  ///
  /// In en, this message translates to:
  /// **'Export File'**
  String get exportFile;

  /// message during import regarding image dimensions
  ///
  /// In en, this message translates to:
  /// **'Image dimensions cannot exceed {width}x{height}!'**
  String imageDimensionsExceed(int width, int height);

  /// No description provided for @couldNotDecodeImage.
  ///
  /// In en, this message translates to:
  /// **'Could not decode image!'**
  String get couldNotDecodeImage;

  /// No description provided for @couldNotLoadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not load file!'**
  String get couldNotLoadFile;

  /// No description provided for @importImage.
  ///
  /// In en, this message translates to:
  /// **'Import Image'**
  String get importImage;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No File Selected'**
  String get noFileSelected;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get chooseImage;

  /// No description provided for @scaleDown.
  ///
  /// In en, this message translates to:
  /// **'Scale Down'**
  String get scaleDown;

  /// No description provided for @createNewPaletteFromImage.
  ///
  /// In en, this message translates to:
  /// **'Create a New Palette From Image'**
  String get createNewPaletteFromImage;

  /// No description provided for @maxColorRamps.
  ///
  /// In en, this message translates to:
  /// **'Max Color Ramps'**
  String get maxColorRamps;

  /// No description provided for @maxColorsPerRamp.
  ///
  /// In en, this message translates to:
  /// **'Max Colors per Ramp'**
  String get maxColorsPerRamp;

  /// No description provided for @includeImageAsReferenceLayer.
  ///
  /// In en, this message translates to:
  /// **'Include Image as Reference Layer'**
  String get includeImageAsReferenceLayer;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @saveProjectAs.
  ///
  /// In en, this message translates to:
  /// **'Save Project as'**
  String get saveProjectAs;

  /// No description provided for @hueAbb.
  ///
  /// In en, this message translates to:
  /// **'hue'**
  String get hueAbb;

  /// No description provided for @satAbb.
  ///
  /// In en, this message translates to:
  /// **'sat'**
  String get satAbb;

  /// No description provided for @valAbb.
  ///
  /// In en, this message translates to:
  /// **'val'**
  String get valAbb;

  /// No description provided for @pressToReset.
  ///
  /// In en, this message translates to:
  /// **'Press to Reset'**
  String get pressToReset;

  /// No description provided for @colorCount.
  ///
  /// In en, this message translates to:
  /// **'Color Count'**
  String get colorCount;

  /// No description provided for @baseHue.
  ///
  /// In en, this message translates to:
  /// **'Base Hue'**
  String get baseHue;

  /// No description provided for @hueShift.
  ///
  /// In en, this message translates to:
  /// **'Hue Shift'**
  String get hueShift;

  /// No description provided for @exponent.
  ///
  /// In en, this message translates to:
  /// **'Exponent'**
  String get exponent;

  /// No description provided for @baseSat.
  ///
  /// In en, this message translates to:
  /// **'Base Sat'**
  String get baseSat;

  /// No description provided for @satShift.
  ///
  /// In en, this message translates to:
  /// **'Sat Shift'**
  String get satShift;

  /// No description provided for @satCurve.
  ///
  /// In en, this message translates to:
  /// **'Sat Curve'**
  String get satCurve;

  /// No description provided for @satCurveNoFlat.
  ///
  /// In en, this message translates to:
  /// **'Decreased Saturation for Dark and Bright Values'**
  String get satCurveNoFlat;

  /// No description provided for @satCurveDarkFlat.
  ///
  /// In en, this message translates to:
  /// **'Decreased Saturation for Bright Values'**
  String get satCurveDarkFlat;

  /// No description provided for @satCurveBrightFlat.
  ///
  /// In en, this message translates to:
  /// **'Decreased Saturation for Dark Values'**
  String get satCurveBrightFlat;

  /// No description provided for @satCurveLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear Saturation Progression'**
  String get satCurveLinear;

  /// No description provided for @valueRange.
  ///
  /// In en, this message translates to:
  /// **'Value Range'**
  String get valueRange;

  /// message when deleting ramp
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this color ramp?\n{amount} pixel(s) will be deleted'**
  String deleteColorRampQuestion(int amount);

  /// message when deleting ramp
  ///
  /// In en, this message translates to:
  /// **'({amount} of them in the selection)'**
  String ofThemInSelection(int amount);

  /// message when deleting ramp
  ///
  /// In en, this message translates to:
  /// **'{amount} pixel(s) in the clipboard will no longer be pasted'**
  String pixelsInClipboard(int amount);

  /// No description provided for @shadingRange.
  ///
  /// In en, this message translates to:
  /// **'Shading Range'**
  String get shadingRange;

  /// No description provided for @maxDarken.
  ///
  /// In en, this message translates to:
  /// **'Max Darken'**
  String get maxDarken;

  /// No description provided for @maxBrighten.
  ///
  /// In en, this message translates to:
  /// **'Max Brighten'**
  String get maxBrighten;

  /// No description provided for @layerActionsDot.
  ///
  /// In en, this message translates to:
  /// **'Layer Actions...'**
  String get layerActionsDot;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addNewLayerDot.
  ///
  /// In en, this message translates to:
  /// **'Add New Layer...'**
  String get addNewLayerDot;

  /// No description provided for @layerSettings.
  ///
  /// In en, this message translates to:
  /// **'Layer Settings'**
  String get layerSettings;

  /// No description provided for @symmetryOptions.
  ///
  /// In en, this message translates to:
  /// **'Symmetry Options'**
  String get symmetryOptions;

  /// No description provided for @centerHorizontalRuler.
  ///
  /// In en, this message translates to:
  /// **'Center Horizontal Ruler'**
  String get centerHorizontalRuler;

  /// No description provided for @centerVerticalRuler.
  ///
  /// In en, this message translates to:
  /// **'Center Vertical Ruler'**
  String get centerVerticalRuler;

  /// No description provided for @addNewDrawingLayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Drawing Layer'**
  String get addNewDrawingLayer;

  /// No description provided for @addNewShadingLayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Shading Layer'**
  String get addNewShadingLayer;

  /// No description provided for @addNewDitherLayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Dither Layer'**
  String get addNewDitherLayer;

  /// No description provided for @addNewReferenceLayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Reference Layer'**
  String get addNewReferenceLayer;

  /// No description provided for @addNewGridLayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Grid Layer'**
  String get addNewGridLayer;

  /// No description provided for @deleteLayer.
  ///
  /// In en, this message translates to:
  /// **'Delete Layer'**
  String get deleteLayer;

  /// No description provided for @duplicateLayer.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Layer'**
  String get duplicateLayer;

  /// No description provided for @mergeDownLayer.
  ///
  /// In en, this message translates to:
  /// **'Merge Down Layer'**
  String get mergeDownLayer;

  /// No description provided for @unlinkLayer.
  ///
  /// In en, this message translates to:
  /// **'Unlink Layer / Make Unique'**
  String get unlinkLayer;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open Project'**
  String get openProject;

  /// No description provided for @rasterLayer.
  ///
  /// In en, this message translates to:
  /// **'Raster Layer'**
  String get rasterLayer;

  /// No description provided for @saveProject.
  ///
  /// In en, this message translates to:
  /// **'Save Project'**
  String get saveProject;

  /// No description provided for @exportProjectPalette.
  ///
  /// In en, this message translates to:
  /// **'Export Project/Palette'**
  String get exportProjectPalette;

  /// No description provided for @centerHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Center Horizontally'**
  String get centerHorizontally;

  /// No description provided for @centerVertically.
  ///
  /// In en, this message translates to:
  /// **'Center Vertically'**
  String get centerVertically;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @bottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get bottom;

  /// No description provided for @editColorRamp.
  ///
  /// In en, this message translates to:
  /// **'Edit Color Ramp'**
  String get editColorRamp;

  /// palette manager summary
  ///
  /// In en, this message translates to:
  /// **'{amount} colors'**
  String nColors(int amount);

  /// palette manager summary
  ///
  /// In en, this message translates to:
  /// **'{rampAmount} ramps | {colorAmount} colors'**
  String nRampsColors(int rampAmount, int colorAmount);

  /// No description provided for @remapExistingColors.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remap the existing colors (all pixels will be deleted otherwise)?'**
  String get remapExistingColors;

  /// No description provided for @wantToDeletePalette.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this palette?'**
  String get wantToDeletePalette;

  /// No description provided for @paletteManager.
  ///
  /// In en, this message translates to:
  /// **'Palette Manager'**
  String get paletteManager;

  /// No description provided for @importPalette.
  ///
  /// In en, this message translates to:
  /// **'Import Palette'**
  String get importPalette;

  /// No description provided for @saveCurrentPalette.
  ///
  /// In en, this message translates to:
  /// **'Save Current Palette'**
  String get saveCurrentPalette;

  /// No description provided for @deleteSelectedPalette.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Palette'**
  String get deleteSelectedPalette;

  /// No description provided for @appendToCurrentPalette.
  ///
  /// In en, this message translates to:
  /// **'Append to Current Palette'**
  String get appendToCurrentPalette;

  /// No description provided for @applySelectedPalette.
  ///
  /// In en, this message translates to:
  /// **'Apply Selected Palette'**
  String get applySelectedPalette;

  /// No description provided for @addNewColorRamp.
  ///
  /// In en, this message translates to:
  /// **'Add New Color Ramp'**
  String get addNewColorRamp;

  /// No description provided for @savePalette.
  ///
  /// In en, this message translates to:
  /// **'Save Palette'**
  String get savePalette;

  /// No description provided for @defaultPalette.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultPalette;

  /// No description provided for @errorSavingPalette.
  ///
  /// In en, this message translates to:
  /// **'Error saving palette!'**
  String get errorSavingPalette;

  /// palette manager
  ///
  /// In en, this message translates to:
  /// **'Palette saved successfully at {path}.'**
  String paletteSavedAt(String path);

  /// No description provided for @paletteWithSameNameExists.
  ///
  /// In en, this message translates to:
  /// **'A palette with the same name already exists!'**
  String get paletteWithSameNameExists;

  /// No description provided for @pleaseSelectAKPalFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a KPal file!'**
  String get pleaseSelectAKPalFile;

  /// No description provided for @paletteImportSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Import successful!'**
  String get paletteImportSuccessful;

  /// No description provided for @paletteImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed!'**
  String get paletteImportFailed;

  /// No description provided for @insufficientPermissionsForDir.
  ///
  /// In en, this message translates to:
  /// **'Insufficient permissions for the selected directory!'**
  String get insufficientPermissionsForDir;

  /// No description provided for @undoSteps.
  ///
  /// In en, this message translates to:
  /// **'Undo Steps'**
  String get undoSteps;

  /// No description provided for @selectInsertedLayers.
  ///
  /// In en, this message translates to:
  /// **'Select Inserted Layers'**
  String get selectInsertedLayers;

  /// No description provided for @defaultShadingLayerSettings.
  ///
  /// In en, this message translates to:
  /// **'Default Shading Layer Settings'**
  String get defaultShadingLayerSettings;

  /// No description provided for @defaultFrameTime.
  ///
  /// In en, this message translates to:
  /// **'Default Frame Time'**
  String get defaultFrameTime;

  /// No description provided for @showReferenceLayersOutsideOfCanvas.
  ///
  /// In en, this message translates to:
  /// **'Show Reference Layers outside of canvas'**
  String get showReferenceLayersOutsideOfCanvas;

  /// No description provided for @projectDirectory.
  ///
  /// In en, this message translates to:
  /// **'Project Directory'**
  String get projectDirectory;

  /// No description provided for @defaultDir.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultDir;

  /// No description provided for @customDir.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customDir;

  /// No description provided for @chooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose Directory'**
  String get chooseDirectory;

  /// No description provided for @mouseCursor.
  ///
  /// In en, this message translates to:
  /// **'Mouse Cursor'**
  String get mouseCursor;

  /// No description provided for @languagePreferences.
  ///
  /// In en, this message translates to:
  /// **'Language Preferences'**
  String get languagePreferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @themePreferences.
  ///
  /// In en, this message translates to:
  /// **'Theme Preferences'**
  String get themePreferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @checkerboardPreferences.
  ///
  /// In en, this message translates to:
  /// **'Checkerboard Preferences'**
  String get checkerboardPreferences;

  /// No description provided for @checkerboardSize.
  ///
  /// In en, this message translates to:
  /// **'Checkerboard Size'**
  String get checkerboardSize;

  /// No description provided for @checkerboardContrast.
  ///
  /// In en, this message translates to:
  /// **'Checkerboard Contrast'**
  String get checkerboardContrast;

  /// No description provided for @palettePreferences.
  ///
  /// In en, this message translates to:
  /// **'Palette Preferences'**
  String get palettePreferences;

  /// No description provided for @colorNaming.
  ///
  /// In en, this message translates to:
  /// **'Color Naming'**
  String get colorNaming;

  /// No description provided for @borderPreferences.
  ///
  /// In en, this message translates to:
  /// **'Border Preferences'**
  String get borderPreferences;

  /// No description provided for @toolOutlineOpacity.
  ///
  /// In en, this message translates to:
  /// **'Tool Outline Opacity'**
  String get toolOutlineOpacity;

  /// No description provided for @selectionOutlineOpacity.
  ///
  /// In en, this message translates to:
  /// **'Selection Outline Opacity'**
  String get selectionOutlineOpacity;

  /// No description provided for @pulsatingSelectionOutline.
  ///
  /// In en, this message translates to:
  /// **'Pulsating Selection Outline'**
  String get pulsatingSelectionOutline;

  /// No description provided for @canvasBorerOpacity.
  ///
  /// In en, this message translates to:
  /// **'Canvas Border Opacity'**
  String get canvasBorerOpacity;

  /// No description provided for @pollingTimeToCheck.
  ///
  /// In en, this message translates to:
  /// **'Polling time to check for presses of stylus buttons.'**
  String get pollingTimeToCheck;

  /// No description provided for @pollInterval.
  ///
  /// In en, this message translates to:
  /// **'Poll Interval'**
  String get pollInterval;

  /// No description provided for @timeThatNeedsToBeHeldDown.
  ///
  /// In en, this message translates to:
  /// **'Time that needs to be held down for a long press.'**
  String get timeThatNeedsToBeHeldDown;

  /// No description provided for @longPressDelay.
  ///
  /// In en, this message translates to:
  /// **'Long Press Delay'**
  String get longPressDelay;

  /// No description provided for @distanceThatMustBeMoved.
  ///
  /// In en, this message translates to:
  /// **'Distance that must be moved during a long press to cancel it.'**
  String get distanceThatMustBeMoved;

  /// No description provided for @longPressCancelDistance.
  ///
  /// In en, this message translates to:
  /// **'Long Press Cancel Distance'**
  String get longPressCancelDistance;

  /// No description provided for @distanceThatNeedsToBeMovedVertically.
  ///
  /// In en, this message translates to:
  /// **'Distance that needs to be moved vertically to zoom in or out.'**
  String get distanceThatNeedsToBeMovedVertically;

  /// No description provided for @zoomStepDistance.
  ///
  /// In en, this message translates to:
  /// **'Zoom Step Distance'**
  String get zoomStepDistance;

  /// No description provided for @distanceThatNeedsToBeMovedHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Distance that needs to be moved horizontally to change the size of the current tool.'**
  String get distanceThatNeedsToBeMovedHorizontally;

  /// No description provided for @toolSizeStepDistance.
  ///
  /// In en, this message translates to:
  /// **'Tool Size Step Distance'**
  String get toolSizeStepDistance;

  /// No description provided for @timeoutForPickingAColor.
  ///
  /// In en, this message translates to:
  /// **'Timeout for picking a color.'**
  String get timeoutForPickingAColor;

  /// No description provided for @colorPickTimeout.
  ///
  /// In en, this message translates to:
  /// **'Color Pick Timeout'**
  String get colorPickTimeout;

  /// No description provided for @touchDelay.
  ///
  /// In en, this message translates to:
  /// **'Touch Delay'**
  String get touchDelay;

  /// No description provided for @stampManager.
  ///
  /// In en, this message translates to:
  /// **'Stamp Manager'**
  String get stampManager;

  /// No description provided for @deleteSelectedStamp.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Stamp'**
  String get deleteSelectedStamp;

  /// No description provided for @loadSelectedStamp.
  ///
  /// In en, this message translates to:
  /// **'Load Selected Stamp'**
  String get loadSelectedStamp;

  /// No description provided for @doYouReallyWantToDeleteStamp.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this stamp?'**
  String get doYouReallyWantToDeleteStamp;

  /// No description provided for @frameBlending.
  ///
  /// In en, this message translates to:
  /// **'Frame Blending'**
  String get frameBlending;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @framesBefore.
  ///
  /// In en, this message translates to:
  /// **'Frames Before'**
  String get framesBefore;

  /// No description provided for @wrapAround.
  ///
  /// In en, this message translates to:
  /// **'Wrap Around'**
  String get wrapAround;

  /// No description provided for @framesAfter.
  ///
  /// In en, this message translates to:
  /// **'Frames After'**
  String get framesAfter;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// No description provided for @gradual.
  ///
  /// In en, this message translates to:
  /// **'Gradual'**
  String get gradual;

  /// No description provided for @tinting.
  ///
  /// In en, this message translates to:
  /// **'Tinting'**
  String get tinting;

  /// No description provided for @activeLayerOnly.
  ///
  /// In en, this message translates to:
  /// **'Active Layer Only'**
  String get activeLayerOnly;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @applyToAllFrames.
  ///
  /// In en, this message translates to:
  /// **'Apply to All Frames'**
  String get applyToAllFrames;

  /// No description provided for @applyToCurrentFrame.
  ///
  /// In en, this message translates to:
  /// **'Apply to Current Frame'**
  String get applyToCurrentFrame;

  /// No description provided for @collapseTimeline.
  ///
  /// In en, this message translates to:
  /// **'Collapse Timeline'**
  String get collapseTimeline;

  /// No description provided for @expandTimeline.
  ///
  /// In en, this message translates to:
  /// **'Expand Timeline'**
  String get expandTimeline;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @loopStartMarker.
  ///
  /// In en, this message translates to:
  /// **'Loop Start Marker'**
  String get loopStartMarker;

  /// No description provided for @loopEndMarker.
  ///
  /// In en, this message translates to:
  /// **'Loop End Marker'**
  String get loopEndMarker;

  /// No description provided for @changeDuration.
  ///
  /// In en, this message translates to:
  /// **'Change Duration'**
  String get changeDuration;

  /// No description provided for @moveFrameLeft.
  ///
  /// In en, this message translates to:
  /// **'Move Frame Left'**
  String get moveFrameLeft;

  /// No description provided for @moveFrame.
  ///
  /// In en, this message translates to:
  /// **'Move Frame'**
  String get moveFrame;

  /// No description provided for @moveFrameRight.
  ///
  /// In en, this message translates to:
  /// **'Move Frame Right'**
  String get moveFrameRight;

  /// No description provided for @addFrameLeft.
  ///
  /// In en, this message translates to:
  /// **'Add Frame Left'**
  String get addFrameLeft;

  /// No description provided for @addFrame.
  ///
  /// In en, this message translates to:
  /// **'Add Frame'**
  String get addFrame;

  /// No description provided for @addFrameRight.
  ///
  /// In en, this message translates to:
  /// **'Add Frame Right'**
  String get addFrameRight;

  /// No description provided for @copyFrameLeft.
  ///
  /// In en, this message translates to:
  /// **'Copy Frame Left'**
  String get copyFrameLeft;

  /// No description provided for @copyFrame.
  ///
  /// In en, this message translates to:
  /// **'Copy Frame'**
  String get copyFrame;

  /// No description provided for @copyFrameRight.
  ///
  /// In en, this message translates to:
  /// **'Copy Frame Right'**
  String get copyFrameRight;

  /// No description provided for @createLinkedFrameLeft.
  ///
  /// In en, this message translates to:
  /// **'Create Linked Frame Left'**
  String get createLinkedFrameLeft;

  /// No description provided for @createLinkedFrame.
  ///
  /// In en, this message translates to:
  /// **'Create Linked Frame'**
  String get createLinkedFrame;

  /// No description provided for @createLinkedFrameRight.
  ///
  /// In en, this message translates to:
  /// **'Create Linked Frame Right'**
  String get createLinkedFrameRight;

  /// No description provided for @deleteFrame.
  ///
  /// In en, this message translates to:
  /// **'Delete Frame'**
  String get deleteFrame;

  /// No description provided for @toggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle'**
  String get toggle;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @gridButton.
  ///
  /// In en, this message translates to:
  /// **'GRID'**
  String get gridButton;

  /// No description provided for @perspective.
  ///
  /// In en, this message translates to:
  /// **'Perspective'**
  String get perspective;

  /// No description provided for @perspectiveButton.
  ///
  /// In en, this message translates to:
  /// **'PERSPECTIVE'**
  String get perspectiveButton;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @intervalX.
  ///
  /// In en, this message translates to:
  /// **'Interval X'**
  String get intervalX;

  /// No description provided for @intervalY.
  ///
  /// In en, this message translates to:
  /// **'Interval Y'**
  String get intervalY;

  /// No description provided for @horizon.
  ///
  /// In en, this message translates to:
  /// **'Horizon'**
  String get horizon;

  /// No description provided for @vanishingPoint.
  ///
  /// In en, this message translates to:
  /// **'Vanishing Point'**
  String get vanishingPoint;

  /// No description provided for @horPoints.
  ///
  /// In en, this message translates to:
  /// **'Hor Points'**
  String get horPoints;

  /// No description provided for @verPoint.
  ///
  /// In en, this message translates to:
  /// **'Ver Point'**
  String get verPoint;

  /// No description provided for @couldNotLoadImageFrom.
  ///
  /// In en, this message translates to:
  /// **'Could not load image from {location}.'**
  String couldNotLoadImageFrom(String location);

  /// No description provided for @resetSetting.
  ///
  /// In en, this message translates to:
  /// **'Reset {setting}'**
  String resetSetting(String setting);

  /// No description provided for @noFileLoaded.
  ///
  /// In en, this message translates to:
  /// **'No File Loaded'**
  String get noFileLoaded;

  /// No description provided for @openReferenceImage.
  ///
  /// In en, this message translates to:
  /// **'Open Reference Image'**
  String get openReferenceImage;

  /// No description provided for @aspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get aspectRatio;

  /// No description provided for @zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// No description provided for @expandHorizontallyAndCenter.
  ///
  /// In en, this message translates to:
  /// **'Expand horizontally and center by keeping the current aspect ratio'**
  String get expandHorizontallyAndCenter;

  /// No description provided for @expandVerticallyAndCenter.
  ///
  /// In en, this message translates to:
  /// **'Expand vertically and center by keeping the current aspect ratio'**
  String get expandVerticallyAndCenter;

  /// No description provided for @fitsImageIntoCanvas.
  ///
  /// In en, this message translates to:
  /// **'Fits the image into the canvas (changes aspect ratio)'**
  String get fitsImageIntoCanvas;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @warmth.
  ///
  /// In en, this message translates to:
  /// **'Warmth'**
  String get warmth;

  /// No description provided for @shading.
  ///
  /// In en, this message translates to:
  /// **'Shading'**
  String get shading;

  /// No description provided for @currentRampOnly.
  ///
  /// In en, this message translates to:
  /// **'Current Ramp Only'**
  String get currentRampOnly;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @loadingDot.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingDot;

  /// No description provided for @thisDeviceDoesNotSupportResolution.
  ///
  /// In en, this message translates to:
  /// **'This device does not support the minimum logical resolution to run this application.'**
  String get thisDeviceDoesNotSupportResolution;

  /// No description provided for @customProjectDirectoryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Custom Project directory invalid. Switching to default directory.'**
  String get customProjectDirectoryInvalid;

  /// No description provided for @couldNotCreateInternalDirectories.
  ///
  /// In en, this message translates to:
  /// **'Could not create internal directories.'**
  String get couldNotCreateInternalDirectories;

  /// No description provided for @couldNotInitializeApp.
  ///
  /// In en, this message translates to:
  /// **'Could not initialize the application.'**
  String get couldNotInitializeApp;

  /// No description provided for @aCustomProjectDirectoryIsUsed.
  ///
  /// In en, this message translates to:
  /// **'A custom project directory is used, but KPix does not have the \"All files access\" permission. Project files created by other apps (e.g. sync tools) might not be shown.\nDo you want to open the system settings to grant the permission?'**
  String get aCustomProjectDirectoryIsUsed;

  /// No description provided for @workRecovered.
  ///
  /// In en, this message translates to:
  /// **'Work Recovered'**
  String get workRecovered;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @saveDot.
  ///
  /// In en, this message translates to:
  /// **'Save...'**
  String get saveDot;

  /// No description provided for @newOpenDot.
  ///
  /// In en, this message translates to:
  /// **'New/Open...'**
  String get newOpenDot;

  /// No description provided for @errorImportingImage.
  ///
  /// In en, this message translates to:
  /// **'Error importing image.'**
  String get errorImportingImage;

  /// No description provided for @thereAreUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes, do you want to save first?'**
  String get thereAreUnsavedChanges;

  /// No description provided for @importingImageDot.
  ///
  /// In en, this message translates to:
  /// **'Importing Image...'**
  String get importingImageDot;

  /// No description provided for @exportingDot.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exportingDot;

  /// No description provided for @movingProjectFilesDot.
  ///
  /// In en, this message translates to:
  /// **'Moving project files...'**
  String get movingProjectFilesDot;

  /// No description provided for @targetDirCouldNotBeCreated.
  ///
  /// In en, this message translates to:
  /// **'The directory does not exist and could not be created!'**
  String get targetDirCouldNotBeCreated;

  /// project dir change
  ///
  /// In en, this message translates to:
  /// **'The directory already contains a file named {fileName}!'**
  String dirAlreadyContainsFile(String fileName);

  /// project dir change
  ///
  /// In en, this message translates to:
  /// **'Could not move file {fileName}!'**
  String couldNotMoveFile(String fileName);

  /// No description provided for @unexpectedErrorMovingProjectFiles.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while moving project files!'**
  String get unexpectedErrorMovingProjectFiles;

  /// project dir change
  ///
  /// In en, this message translates to:
  /// **'Changed project directory to {directory} (moved {count} project file(s)).'**
  String changedProjectDirectoryFiles(String directory, int count);

  /// project dir change
  ///
  /// In en, this message translates to:
  /// **'The project directory was not changed!\n{message}'**
  String projectDirWasNotChanged(String message);

  /// palette export
  ///
  /// In en, this message translates to:
  /// **'Exported palette to: {path}'**
  String exportedPaletteTo(String path);

  /// No description provided for @errorExportingPaletteFile.
  ///
  /// In en, this message translates to:
  /// **'Error exporting palette file.'**
  String get errorExportingPaletteFile;

  /// export
  ///
  /// In en, this message translates to:
  /// **'Exported to: {path}'**
  String exportedTo(String path);

  /// No description provided for @errorExportingFile.
  ///
  /// In en, this message translates to:
  /// **'Error exporting file!'**
  String get errorExportingFile;

  /// No description provided for @withoutAllFilesWarning.
  ///
  /// In en, this message translates to:
  /// **'Without the \"All files access\" permission, KPix cannot see project files that were created by other apps (e.g. sync tools) in this directory.\nDo you want to open the system settings to grant the permission?'**
  String get withoutAllFilesWarning;

  /// No description provided for @allFilesAccessNotNeededWarning.
  ///
  /// In en, this message translates to:
  /// **'The \"All files access\" permission is not needed for the default project directory.\nDo you want to open the system settings to revoke the permission?'**
  String get allFilesAccessNotNeededWarning;

  /// No description provided for @initial.
  ///
  /// In en, this message translates to:
  /// **'Initial'**
  String get initial;

  /// No description provided for @generic.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get generic;

  /// No description provided for @saveData.
  ///
  /// In en, this message translates to:
  /// **'Save Data'**
  String get saveData;

  /// No description provided for @loadData.
  ///
  /// In en, this message translates to:
  /// **'Load Data'**
  String get loadData;

  /// No description provided for @selectLayer.
  ///
  /// In en, this message translates to:
  /// **'Select Layer'**
  String get selectLayer;

  /// No description provided for @selectLayerMoveSelection.
  ///
  /// In en, this message translates to:
  /// **'Select Layer (Move Selection)'**
  String get selectLayerMoveSelection;

  /// No description provided for @mergeLayer.
  ///
  /// In en, this message translates to:
  /// **'Merge Layer'**
  String get mergeLayer;

  /// No description provided for @changeLayerOrder.
  ///
  /// In en, this message translates to:
  /// **'Change Layer Order'**
  String get changeLayerOrder;

  /// No description provided for @layerVisibilityChanged.
  ///
  /// In en, this message translates to:
  /// **'Layer Visibility Changed'**
  String get layerVisibilityChanged;

  /// No description provided for @layerLockStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Layer Lock State Changed'**
  String get layerLockStateChanged;

  /// No description provided for @changeReferenceImage.
  ///
  /// In en, this message translates to:
  /// **'Change Reference Image'**
  String get changeReferenceImage;

  /// No description provided for @layerSettingsChange.
  ///
  /// In en, this message translates to:
  /// **'Layer Settings Change'**
  String get layerSettingsChange;

  /// No description provided for @layerSettingsRaster.
  ///
  /// In en, this message translates to:
  /// **'Layer Settings Raster'**
  String get layerSettingsRaster;

  /// No description provided for @newSelection.
  ///
  /// In en, this message translates to:
  /// **'New Selection'**
  String get newSelection;

  /// No description provided for @cutSelection.
  ///
  /// In en, this message translates to:
  /// **'Cut Selection'**
  String get cutSelection;

  /// No description provided for @flipSelectionHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Flip Selection Horizontally'**
  String get flipSelectionHorizontally;

  /// No description provided for @flipSelectionVertically.
  ///
  /// In en, this message translates to:
  /// **'Flip Selection Vertically'**
  String get flipSelectionVertically;

  /// No description provided for @rotateSelection.
  ///
  /// In en, this message translates to:
  /// **'Rotate Selection'**
  String get rotateSelection;

  /// No description provided for @moveSelection.
  ///
  /// In en, this message translates to:
  /// **'Move Selection'**
  String get moveSelection;

  /// No description provided for @pasteSelection.
  ///
  /// In en, this message translates to:
  /// **'Paste Selection'**
  String get pasteSelection;

  /// No description provided for @selectionToNewLayer.
  ///
  /// In en, this message translates to:
  /// **'Selection To New Layer'**
  String get selectionToNewLayer;

  /// No description provided for @deleteSelection.
  ///
  /// In en, this message translates to:
  /// **'Delete Selection'**
  String get deleteSelection;

  /// No description provided for @changeCanvasSize.
  ///
  /// In en, this message translates to:
  /// **'Change Canvas Size'**
  String get changeCanvasSize;

  /// No description provided for @penDrawing.
  ///
  /// In en, this message translates to:
  /// **'Pen Drawing'**
  String get penDrawing;

  /// No description provided for @stampDrawing.
  ///
  /// In en, this message translates to:
  /// **'Stamp Drawing'**
  String get stampDrawing;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @fontDrawing.
  ///
  /// In en, this message translates to:
  /// **'Font Drawing'**
  String get fontDrawing;

  /// No description provided for @shapeDrawing.
  ///
  /// In en, this message translates to:
  /// **'Shape Drawing'**
  String get shapeDrawing;

  /// No description provided for @lineDrawing.
  ///
  /// In en, this message translates to:
  /// **'Line Drawing'**
  String get lineDrawing;

  /// No description provided for @sprayCanDrawing.
  ///
  /// In en, this message translates to:
  /// **'Spray Can Drawing'**
  String get sprayCanDrawing;

  /// No description provided for @changeColorSelection.
  ///
  /// In en, this message translates to:
  /// **'Change Color Selection'**
  String get changeColorSelection;

  /// No description provided for @deleteRamp.
  ///
  /// In en, this message translates to:
  /// **'Delete Ramp'**
  String get deleteRamp;

  /// No description provided for @updateRamp.
  ///
  /// In en, this message translates to:
  /// **'Update Ramp'**
  String get updateRamp;

  /// No description provided for @replacePalette.
  ///
  /// In en, this message translates to:
  /// **'Replace Palette'**
  String get replacePalette;

  /// No description provided for @addNewRamp.
  ///
  /// In en, this message translates to:
  /// **'Add New Ramp'**
  String get addNewRamp;

  /// No description provided for @changeRampOrder.
  ///
  /// In en, this message translates to:
  /// **'Change Ramp Order'**
  String get changeRampOrder;

  /// No description provided for @changeFrameTime.
  ///
  /// In en, this message translates to:
  /// **'Change Frame Time'**
  String get changeFrameTime;

  /// No description provided for @changeLoopMarker.
  ///
  /// In en, this message translates to:
  /// **'Change Loop Marker'**
  String get changeLoopMarker;
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
