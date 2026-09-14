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
  String get keyCtrl => 'ctrldfhsh';

  @override
  String get keySpace => 'space';
}
