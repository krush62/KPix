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

  @override
  String get hidden => 'Ausgeblendet';

  @override
  String get visible => 'Sichtbar';

  @override
  String get unlocked => 'Entsperrt';

  @override
  String get transparencyLocked => 'Transparenz gesperrt';

  @override
  String get locked => 'Gesperrt';

  @override
  String get buttonRec => 'ORT';

  @override
  String get buttonDia => 'DIA';

  @override
  String get buttonIso => 'ISO';

  @override
  String get buttonHex => 'HEX';

  @override
  String get buttonTri => 'DRK';

  @override
  String get buttonBrk => 'ZIG';

  @override
  String get button1Point => '1-Punkt';

  @override
  String get button2Point => '2-Punkt';

  @override
  String get button3Point => '3-Punkt';

  @override
  String get rectangularGrid => 'Orthogonales Gitter';

  @override
  String get diagonalGrid => 'Diagonalgitter';

  @override
  String get isometricGrid => 'Isometrisches Gitter';

  @override
  String get hexagonalGrid => 'Hexagonales Gitter';

  @override
  String get triangularGrid => 'Dreiecksgitter';

  @override
  String get bricks => 'Ziegel';

  @override
  String get onePointPerspective => '1-Punkt-Perspektive';

  @override
  String get twoPointPerspective => '2-Punkt-Perspektive';

  @override
  String get threePointPerspective => '3-Punkt-Perspektive';

  @override
  String get ascendingSegmentOrder => 'Absteigende Segmentlänge';

  @override
  String get ascendingDescendingSegmentOrder =>
      'Aufsteigende/Absteigende Segmentlänge';

  @override
  String get descendingAscendingSegmentOrder =>
      'Absteigende/Aufsteigende Segmentlänge';

  @override
  String get descendingSegmentOrder => 'Absteigende Segmentlänge';

  @override
  String get round => 'Rund';

  @override
  String get square => 'Quadratisch';

  @override
  String get rectangle => 'Rechteck';

  @override
  String get ellipse => 'Ellipse';

  @override
  String get polygon => 'Polygon';

  @override
  String get wand => 'Zauberstab';

  @override
  String get triangle => 'Dreieck';

  @override
  String get midAngleRectangle => 'Gedrehtes Rechteck';

  @override
  String get regularPolygon => 'Regelmäßiges Polygon';

  @override
  String get star => 'Stern';

  @override
  String get replaceSelection => 'Auswahl ersetzen';

  @override
  String get addToSelection => 'Zur Auswahl hinzufügen';

  @override
  String get subtractFromSelection => 'Von Auswahl subtrahieren';

  @override
  String get intersectWithSelection => 'Mit Auswahl überschneiden';

  @override
  String get pencil => 'Stift';

  @override
  String get shape => 'Form';

  @override
  String get fill => 'Füllen';

  @override
  String get select => 'Auswahl';

  @override
  String get colorPicker => 'Pipette';

  @override
  String get eraser => 'Radierer';

  @override
  String get text => 'Text';

  @override
  String get sprayCan => 'Sprühdose';

  @override
  String get line => 'Linie';

  @override
  String get stamp => 'Stempel';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get cursorNone => 'Aus';

  @override
  String get cursorCrosshair => 'Fadenkreuz';

  @override
  String get cursorArrow => 'Pfeil';

  @override
  String get rawModeExplanation =>
      'Der Rohmodus verwendet keine Werte aus Schattierungsebenen oder Ebeneneinstellungen, die Schattierungen verwenden.';

  @override
  String get rawMode => 'Rohmodus';

  @override
  String get size => 'Größe';

  @override
  String get fillAdjacent => 'Benachbart füllen';

  @override
  String get fillWholeRamp => 'Gesamte Rampe füllen';

  @override
  String get integerAspectRatio => 'Ganzzahliges Seitenverhältnis';

  @override
  String get segmentSorting => 'Segment-Sortierung';

  @override
  String get smooth => 'Geglättet';

  @override
  String get mode => 'Modus';

  @override
  String get continuous => 'Kontinuierlich';

  @override
  String get keep1to1 => '1:1 beibehalten';

  @override
  String get wholeRamp => 'Gesamte Rampe';

  @override
  String get strokeOnly => 'Nur Umriss';

  @override
  String get cornerRadius => 'Eckenradius';

  @override
  String get angle => 'Winkel';

  @override
  String get cornerCount => 'Anzahl der Ecken';

  @override
  String get radius => 'Radius';

  @override
  String get blobSize => 'Blob-Größe';

  @override
  String get intensity => 'Intensität';

  @override
  String get noStamp => 'kein Stempel';

  @override
  String get scale => 'Skalierung';

  @override
  String get gridAlign => 'Rasterausrichtung';

  @override
  String get offsetX => 'Versatz X';

  @override
  String get offsetY => 'Versatz Y';

  @override
  String get font => 'Schriftart';

  @override
  String get available => 'Verfügbar';

  @override
  String get invalidFileName => 'Ungültiger Dateiname';

  @override
  String get insufficientPermissions => 'Unzureichende Berechtigungen';

  @override
  String get overwritingExistingFile => 'Vorhandene Datei wird überschrieben';

  @override
  String get rotateCanvas => 'Leinwand drehen';

  @override
  String get flipCanvasHorizontally => 'Leinwand horizontal spiegeln';

  @override
  String get flipCanvasVertically => 'Leinwand vertikal spiegeln';

  @override
  String get canvasSize => 'Leinwandgröße';

  @override
  String get offset => 'Versatz';

  @override
  String get selectAll => 'Alles auswählen';

  @override
  String get deselect => 'Auswahl aufheben';

  @override
  String get inverseSelection => 'Auswahl umkehren';

  @override
  String get copy => 'Kopieren';

  @override
  String get copyMerged => 'Sichtbares kopieren';

  @override
  String get cut => 'Ausschneiden';

  @override
  String get paste => 'Einfügen';

  @override
  String get pasteAsNewLayer => 'Als neue Ebene einfügen';

  @override
  String get horizontalFlip => 'Horizontal spiegeln';

  @override
  String get verticalFlip => 'Vertikal spiegeln';

  @override
  String get rotate90Clockwise => '90° im Uhrzeigersinn drehen';

  @override
  String get alignDot => 'Ausrichten...';

  @override
  String get delete => 'Löschen';

  @override
  String get selectAColor => 'Farbauswahl';

  @override
  String get newVersionAvailable => 'Neue Version verfügbar';

  @override
  String get downloadFromGithub => 'Von GitHub herunterladen';

  @override
  String get aPixelArtCreationTool => 'Ein Pixel-Art Tool';

  @override
  String get thisIsFreeSoftwareLicensed =>
      'Dies ist freie Software, lizensiert unter';

  @override
  String get gnuAGPLv3 => 'GNU AGPLv3';

  @override
  String get credits => 'Mitwirkende';

  @override
  String get licenses => 'Lizenzen';

  @override
  String get controlsShortcuts => 'Tastenkürzel';

  @override
  String get textToolContent => 'Inhalt für Textwerkzeug';

  @override
  String get gui => 'GUI';

  @override
  String get behavior => 'Verhalten';

  @override
  String get controlsPC => 'Steuerung PC';

  @override
  String get controlsStylus => 'Steuerung Stylus';

  @override
  String get controlsTouch => 'Steuerung Touch';

  @override
  String get image => 'Bild';

  @override
  String get animation => 'Animation';

  @override
  String get palette => 'Palette';

  @override
  String get kpixProject => 'KPix-Projekt';

  @override
  String get export => 'Export';

  @override
  String get format => 'Format';

  @override
  String get texturePack => 'Textur-Bündel';

  @override
  String get texturePackAnimation => 'Textur-Animations-Bündel';

  @override
  String get scaling => 'Skalierung';

  @override
  String get selectionOnly => 'Nur die Auswahl';

  @override
  String nFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Frames',
      one: '1 Frame',
      zero: '0 Frames',
    );
    return '$_temp0';
  }

  @override
  String get directory => 'Verzeichnis';

  @override
  String get changeDirectory => 'Verzeichnis wechseln';

  @override
  String get fileName => 'Dateiname';

  @override
  String get exportFile => 'Datei Exportieren';

  @override
  String imageDimensionsExceed(Object height, Object width) {
    return 'Bildmaße dürfen ${width}x$height nicht überschreiten!';
  }

  @override
  String get couldNotDecodeImage => 'Bild konnte nicht dekodiert werden!';

  @override
  String get couldNotLoadFile => 'Datei konnte nicht geladen werden!';

  @override
  String get importImage => 'Bild importieren';

  @override
  String get file => 'Datei';

  @override
  String get noFileSelected => 'Keine Datei ausgewählt';

  @override
  String get chooseImage => 'Bild wählen';

  @override
  String get scaleDown => 'Runterskalieren';

  @override
  String get createNewPaletteFromImage => 'Neue Palette aus Bild erstellen';

  @override
  String get maxColorRamps => 'Max. Farbrampen';

  @override
  String get maxColorsPerRamp => 'Max. Farben pro Rampe';

  @override
  String get includeImageAsReferenceLayer =>
      'Bild als Referenzebene hinzufügen';

  @override
  String get import => 'Importieren';

  @override
  String get saveProjectAs => 'Projekt speichern als';
}
