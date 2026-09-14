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
  String get color => 'Farbe';

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

  @override
  String get keyShift => 'Umschalt';

  @override
  String get keyAlt => 'Alt';

  @override
  String get keyCtrl => 'Strg';

  @override
  String get keySpace => 'Leertaste';

  @override
  String get buttonOff => 'AUS';

  @override
  String get buttonSolid => 'SLD';

  @override
  String get buttonRelative => 'RLT';

  @override
  String get buttonGlow => 'STR';

  @override
  String get buttonShade => 'SHT';

  @override
  String get buttonBevel => 'FAS';

  @override
  String get outerStrokeOff => 'Kein Außenumriss';

  @override
  String get outerStrokeSolid => 'Solider Außenumriss';

  @override
  String get outerStrokeRelative => 'Farbrelativer Außenumriss';

  @override
  String get outerStrokeGlowing => 'Strahlender Außenumriss';

  @override
  String get outerStrokeShaded => 'Schattierender Außenumriss';

  @override
  String get innerStrokeOff => 'Kein Innenumriss';

  @override
  String get innerStrokeSolid => 'Solider Innenumriss';

  @override
  String get innerStrokeBeveled => 'Gefaster Innenumriss';

  @override
  String get innerStrokeGlowing => 'Strahlender Innenumriss';

  @override
  String get innerStrokeShaded => 'Schattierender Innenumriss';

  @override
  String get shadowOff => 'Kein Schlagschatten';

  @override
  String get shadowSolid => 'Solider Schlagschatten';

  @override
  String get shadowShaded => 'Schattierender Schlagschatten';

  @override
  String stepCount(int count, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$value Stufen',
      one: '$value Stufe',
    );
    return '$_temp0';
  }

  @override
  String get recursive => 'rekursiv';

  @override
  String get outerStroke => 'Außenumriss';

  @override
  String get innerStroke => 'Innenumriss';

  @override
  String get dropShadow => 'Schlagschatten';

  @override
  String get selectOuterStrokeColor => 'Außenumrissfarbe auswählen';

  @override
  String get darkenBrighten => 'Abdunkeln/Aufhellen';

  @override
  String get darkenBrightenBreak => 'Abdunkeln /\nAufhellen';

  @override
  String get applyOuterStroke => 'Außenumriss anwenden';

  @override
  String get selectInnerStrokeColor => 'Innenumrissfarbe auswählen';

  @override
  String get applyInnerStroke => 'Innenumriss anwenden';

  @override
  String get horizontal => 'horizontal';

  @override
  String get vertical => 'vertikal';

  @override
  String get selectDropShadowColor => 'Schlagschattenfarbe auswählen';

  @override
  String get applyDropShadow => 'Schlagschatten anwenden';

  @override
  String get pixelsAbbrev => 'px';

  @override
  String get couldNotAddAllLayers =>
      'Nicht alle Ebenen konnten hinzugefügt werden.';

  @override
  String get invalidLayerIndex => 'Ungültiger Ebenenindex.';

  @override
  String get couldNotAddMoreLayers =>
      'Es konnten keine weiteren Ebenen hinzugefügt werden.';

  @override
  String get layerAlreadyExistsOnFrame =>
      'Die Ebene existiert bereits in diesem Frame.';

  @override
  String get cannotAddMoreFrames =>
      'Es können keine weiteren Frames hinzugefügt werden.';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get noLayerBelow => 'Keine Ebene darunter!';

  @override
  String get cannotMergeFromLinkedLayer =>
      'Von einer verknüpften Ebene kann nicht zusammengeführt werden!';

  @override
  String get cannotMergeToLinkedLayer =>
      'Mit einer verknüpften Ebene kann nicht zusammengeführt werden!';

  @override
  String get cannotMergeFromInvisibleLayer =>
      'Von einer ausgeblendeten Ebene kann nicht zusammengeführt werden!';

  @override
  String get cannotMergeToInvisibleLayer =>
      'Mit einer ausgeblendeten Ebene kann nicht zusammengeführt werden!';

  @override
  String get cannotMergeFromLockedLayer =>
      'Von einer gesperrten Ebene kann nicht zusammengeführt werden!';

  @override
  String get cannotMergeToLockedLayer =>
      'Mit einer gesperrten Ebene kann nicht zusammengeführt werden!';

  @override
  String get canOnlyMergeWithDrawingLayer =>
      'Kann nur mit Zeichenebenen zusammengeführt werden!';

  @override
  String get cannotMergeWithActiveEffects =>
      'Ebenen mit aktiven Effekten können nicht zusammengeführt werden!';

  @override
  String get cannotDeleteLastLayer =>
      'Die letzte Ebene kann nicht gelöscht werden!';

  @override
  String get cannotDeleteFromHiddenLayer =>
      'Aus einer ausgeblendeten Ebene kann nicht gelöscht werden!';

  @override
  String get cannotDeleteFromLockedLayer =>
      'Aus einer gesperrten Ebene kann nicht gelöscht werden!';

  @override
  String get cannotCutFromHiddenLayer =>
      'Aus einer ausgeblendeten Ebene kann nicht ausgeschnitten werden!';

  @override
  String get cannotCutFromLockedLayer =>
      'Aus einer gesperrten Ebene kann nicht ausgeschnitten werden!';

  @override
  String get nothingToCopy => 'Nichts zum Kopieren!';

  @override
  String get nothingToPasteColorsNotInPalette =>
      'Nichts zum Einfügen: Die kopierten Farben sind nicht mehr in der Palette!';

  @override
  String get cannotPasteToHiddenLayer =>
      'In eine ausgeblendete Ebene kann nicht eingefügt werden!';

  @override
  String get cannotPasteToLockedLayer =>
      'In eine gesperrte Ebene kann nicht eingefügt werden!';

  @override
  String get cannotTransformOnHiddenLayer =>
      'Auf einer ausgeblendeten Ebene kann nicht transformiert werden!';

  @override
  String get cannotTransformOnLockedLayer =>
      'Auf einer gesperrten Ebene kann nicht transformiert werden!';

  @override
  String needAtLeastColorRamps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Es werden mindestens $count Farbrampen benötigt!',
      one: 'Es wird mindestens eine Farbrampe benötigt!',
    );
    return '$_temp0';
  }

  @override
  String notMoreThanColorRampsAllowed(int count) {
    return 'Es sind nicht mehr als $count Farbrampen erlaubt!';
  }

  @override
  String get loadingPaletteFailed => 'Laden der Palette fehlgeschlagen!';

  @override
  String undoStep(String description) {
    return 'Rückgängig: $description';
  }

  @override
  String redoStep(String description) {
    return 'Wiederholen: $description';
  }

  @override
  String get historyRestoreFailed =>
      'Wiederherstellen aus dem Verlauf fehlgeschlagen!';

  @override
  String loadingFailed(String status) {
    return 'Laden fehlgeschlagen ($status)';
  }

  @override
  String fileSavedAt(String path) {
    return 'Datei gespeichert unter: $path';
  }

  @override
  String get imageImportSuccessful => 'Bild erfolgreich importiert!';

  @override
  String get couldNotConvertImageData =>
      'Die Bilddaten konnten nicht konvertiert werden!';

  @override
  String get couldNotCrop => 'Zuschneiden nicht möglich!';
}
