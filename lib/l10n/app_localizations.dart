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

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'step'**
  String get step;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get steps;

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
