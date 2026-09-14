// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get close => 'Schließen';

  @override
  String get createNewProject => 'Neues Projekt erstellen';

  @override
  String get width => 'Breite';

  @override
  String get height => 'Höhe';

  @override
  String get presets => 'Vorlagen';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get projectManager => 'Projektverwaltung';

  @override
  String get filter => 'Filter';

  @override
  String get sortFileNameAsc => 'Nach Dateinamen sortieren (aufsteigend)';

  @override
  String get sortFileNameDesc => 'Nach Dateinamen sortieren (absteigend)';

  @override
  String get sortDateAsc => 'Nach Änderungsdatum sortieren (aufsteigend)';

  @override
  String get sortDateDesc => 'Nach Änderungsdatum sortieren (absteigend)';

  @override
  String get importProject => 'Projekt importieren';

  @override
  String get deleteSelectedProject => 'Ausgewähltes Projekt löschen';

  @override
  String get loadSelectedProject => 'Ausgewähltes Projekt laden';

  @override
  String get unsavedChangesSaveFirst =>
      'Es gibt ungespeicherte Änderungen. Vorher speichern?';

  @override
  String get openingImage => 'Öffne Projekt...';

  @override
  String get doYouReallyWantToDeleteProject =>
      'Soll das Projekt wirklich gelöscht werden?';

  @override
  String get projectImportSuccessful => 'Projekt erfolgreich importiert!';

  @override
  String get couldNotReadProjectDir =>
      'Projektverzeichnis konnte nicht gelesen werden!';

  @override
  String get noFilesFound => 'Keine Dateien gefunden!';
}
