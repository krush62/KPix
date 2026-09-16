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
  String get lockAspectRatio => 'Seitenverhältnis sperren';

  @override
  String get exitApplication => 'Anwendung beenden';

  @override
  String get openProjectManager => 'Projektverwaltung öffnen';

  @override
  String get createProject => 'Projekt erstellen';

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
  String get openingImageDot => 'Opening Image...';

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

  @override
  String get hueAbb => 'farb';

  @override
  String get satAbb => 'sätt';

  @override
  String get valAbb => 'hell';

  @override
  String get pressToReset => 'Drücken zum Zurücksetzen';

  @override
  String get colorCount => 'Farbanzahl';

  @override
  String get baseHue => 'Basis-Farbwert';

  @override
  String get hueShift => 'Farbwert-\nverschiebung';

  @override
  String get exponent => 'Exponent';

  @override
  String get baseSat => 'Base Sättigung';

  @override
  String get satShift => 'Sättigungs-\nverschiebung';

  @override
  String get satCurve => 'Sättigungskurve';

  @override
  String get valueRange => 'Helligkeits-\nbereich';

  @override
  String deleteColorRampQuestion(int amount) {
    return 'Soll diese Farbrampe wirklich entfernt werden?\n$amount Pixel werden gelöscht';
  }

  @override
  String ofThemInSelection(int amount) {
    return '($amount davon in der Auswahl)';
  }

  @override
  String pixelsInClipboard(int amount) {
    return '$amount Pixel in der Zwischenablage sind nicht mehr verfügbar';
  }

  @override
  String get shadingRange => 'Schattierungsumfang';

  @override
  String get maxDarken => 'Max. Absunkeln';

  @override
  String get maxBrighten => 'Max. Aufhellen';

  @override
  String get layerActionsDot => 'Ebenenaktionen...';

  @override
  String get settings => 'Einstellungen';

  @override
  String get addNewLayerDot => 'Neue Ebene hinzufügen...';

  @override
  String get layerSettings => 'Ebeneneinstellungen';

  @override
  String get symmetryOptions => 'Symmetrieoptionen';

  @override
  String get centerHorizontalRuler => 'Horizontale Linie zentrieren';

  @override
  String get centerVerticalRuler => 'Vertikale Linie zentrieren';

  @override
  String get addNewDrawingLayer => 'Zeichenebene hinzufügen';

  @override
  String get addNewShadingLayer => 'Schattierungsebene hinzufügen';

  @override
  String get addNewDitherLayer => 'Diffusionsebene hinzufügen';

  @override
  String get addNewReferenceLayer => 'Referenzebene hinzufügen';

  @override
  String get addNewGridLayer => 'Gitterebene hinzufügen';

  @override
  String get deleteLayer => 'Ebene löschen';

  @override
  String get duplicateLayer => 'Ebene duplizieren';

  @override
  String get mergeDownLayer => 'Ebene nach unten zusammenführen';

  @override
  String get unlinkLayer => 'Ebene entknüpfen';

  @override
  String get newProject => 'Neues Projekt';

  @override
  String get openProject => 'Projekt öffnen';

  @override
  String get rasterLayer => 'Ebene rastern';

  @override
  String get saveProject => 'Projekt speichern';

  @override
  String get exportProjectPalette => 'Projekt/Palette exportieren';

  @override
  String get centerHorizontally => 'Horizontal zentrieren';

  @override
  String get centerVertically => 'Vertikal zentrieren';

  @override
  String get left => 'Links';

  @override
  String get right => 'Rechts';

  @override
  String get top => 'Oben';

  @override
  String get bottom => 'Unten';

  @override
  String get editColorRamp => 'Farbrampe bearbeiten';

  @override
  String nColors(int amount) {
    return '$amount Farben';
  }

  @override
  String nRampsColors(int rampAmount, int colorAmount) {
    return '$rampAmount Rampen | $colorAmount Farben';
  }

  @override
  String get remapExistingColors =>
      'Sollen existierende Farben neu zugeordnet werden (sonst werden alle Pixel gelöscht)?';

  @override
  String get wantToDeletePalette =>
      'Soll die Palette wirklich gelöscht werden?';

  @override
  String get paletteManager => 'Palettenverwaltung';

  @override
  String get importPalette => 'Palette importieren';

  @override
  String get saveCurrentPalette => 'Aktuelle Palette speichern';

  @override
  String get deleteSelectedPalette => 'Aktuelle Palette löschen';

  @override
  String get appendToCurrentPalette => 'An aktuelle Palette anhängen';

  @override
  String get applySelectedPalette => 'Ausgewählte Palette anwenden';

  @override
  String get addNewColorRamp => 'Neue Farbrampe hinzufügen';

  @override
  String get savePalette => 'Palette speichern';

  @override
  String get insufficientPermissionsForDir =>
      'Unzureichende Berechtigungen für das ausgewählte Verzeichnis!';

  @override
  String get undoSteps => 'Rückgängig Schritte';

  @override
  String get selectInsertedLayers => 'Eingefügte Ebenen auswählen';

  @override
  String get defaultShadingLayerSettings =>
      'Voreinstellung für Schattierungsebenen';

  @override
  String get defaultFrameTime => 'Voreinstellung Frame-Dauer';

  @override
  String get showReferenceLayersOutsideOfCanvas =>
      'Referenzebenen außerhalb der Leinwand anzeigen';

  @override
  String get projectDirectory => 'Projektverzeichnis';

  @override
  String get defaultDir => 'Standard';

  @override
  String get customDir => 'Benutzerdefiniert';

  @override
  String get chooseDirectory => 'Verzeichnis wählen';

  @override
  String get mouseCursor => 'Mauszeiger';

  @override
  String get themePreferences => 'Thema-Einstellungen';

  @override
  String get theme => 'Thema';

  @override
  String get checkerboardPreferences => 'Schachbrett-Einstellungen';

  @override
  String get checkerboardSize => 'Schachbrettgröße';

  @override
  String get checkerboardContrast => 'Schachbrettkontrast';

  @override
  String get palettePreferences => 'Paletten-Einstellungen';

  @override
  String get colorNaming => 'Farbnamen';

  @override
  String get borderPreferences => 'Umrandungs-Einstellungen';

  @override
  String get toolOutlineOpacity => 'Deckkraft Werkzeugumrandungen';

  @override
  String get selectionOutlineOpacity => 'Deckkraft Auswahlumrandungen';

  @override
  String get pulsatingSelectionOutline => 'Pulsierende Auswahlumrandung';

  @override
  String get canvasBorerOpacity => 'Deckkraft Leinwandumrandung';

  @override
  String get pollingTimeToCheck =>
      'Abfrageintervall für Tastendrücke des Stylus.';

  @override
  String get pollInterval => 'Abfrageintervall';

  @override
  String get timeThatNeedsToBeHeldDown =>
      'Zeit die die Taste des Stylus gedrückt werden muss für einen \"Langen Druck\"';

  @override
  String get longPressDelay => 'Verzögerung für \"Langen Druck\"';

  @override
  String get distanceThatMustBeMoved =>
      'Bewegungsdistanz zum Abbrechen eines \"Langen Drucks\"';

  @override
  String get longPressCancelDistance => 'Abbruchdistanz für \"Langen Druck\"';

  @override
  String get distanceThatNeedsToBeMovedVertically =>
      'Vertikale Distanz um die Zoomstufe zu verändern.';

  @override
  String get zoomStepDistance => 'Bewegungsdistanz für Zoomstufe';

  @override
  String get distanceThatNeedsToBeMovedHorizontally =>
      'Horizontale Distanz um die Werkzeuggröße zu verändern.';

  @override
  String get toolSizeStepDistance => 'Bewegungsdistanz für Werkzeuggröße';

  @override
  String get timeoutForPickingAColor => 'Timeout für Pipette';

  @override
  String get colorPickTimeout => 'Pipetten-Timeout';

  @override
  String get touchDelay => 'Berührungsverzögerung';

  @override
  String get stampManager => 'Stempelverwaltung';

  @override
  String get deleteSelectedStamp => 'Ausgewählten Stempel löschen';

  @override
  String get loadSelectedStamp => 'Ausgewählten Stempel laden';

  @override
  String get doYouReallyWantToDeleteStamp =>
      'Soll der Stempel wirklich gelöscht werden?';

  @override
  String get frameBlending => 'Frame-Überblendung';

  @override
  String get enabled => 'Aktiv';

  @override
  String get framesBefore => 'Frames Davor';

  @override
  String get wrapAround => 'Umlaufend';

  @override
  String get framesAfter => 'Frames Danach';

  @override
  String get opacity => 'Deckkraft';

  @override
  String get gradual => 'Graduell';

  @override
  String get tinting => 'Einfärben';

  @override
  String get activeLayerOnly => 'Nur aktive Ebene';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get applyToAllFrames => 'Auf alle Frames anwenden';

  @override
  String get applyToCurrentFrame => 'Auf aktuellen Frame anwenden';

  @override
  String get collapseTimeline => 'Zeitleiste einklappen';

  @override
  String get expandTimeline => 'Zeitleiste ausklappen';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Abspielen';

  @override
  String get loopStartMarker => 'Startmarkierung für Wiederholung';

  @override
  String get loopEndMarker => 'Enmarkierung für Wiederholung';

  @override
  String get changeDuration => 'Dauer ändern';

  @override
  String get moveFrameLeft => 'Frame nach links bewegen';

  @override
  String get moveFrame => 'Frame bewegen';

  @override
  String get moveFrameRight => 'Frame nach rechts bewegen';

  @override
  String get addFrameLeft => 'Frame links hinzufügen';

  @override
  String get addFrame => 'Frame hinzufügen';

  @override
  String get addFrameRight => 'Frame rechts hinzufügen';

  @override
  String get copyFrameLeft => 'Frame nach links kopieren';

  @override
  String get copyFrame => 'Frame kopieren';

  @override
  String get copyFrameRight => 'Frame nach rechts kopieren';

  @override
  String get createLinkedFrameLeft => 'Verknüpften Frame links hinzufügen';

  @override
  String get createLinkedFrame => 'Verknüpften Frame hinzufügen';

  @override
  String get createLinkedFrameRight => 'Verknüpften Frame rechts hinzufügen';

  @override
  String get deleteFrame => 'Frame löschen';

  @override
  String get toggle => 'Umschalten';

  @override
  String get grid => 'Gitter';

  @override
  String get gridButton => 'GITTER';

  @override
  String get perspective => 'Perspektive';

  @override
  String get perspectiveButton => 'PERSPEkTIVE';

  @override
  String get brightness => 'Helligkeit';

  @override
  String get interval => 'Intervall';

  @override
  String get intervalX => 'Intervall X';

  @override
  String get intervalY => 'Intervall Y';

  @override
  String get horizon => 'Horizont';

  @override
  String get vanishingPoint => 'Fluchtpunkt';

  @override
  String get horPoints => 'Hor Punkte';

  @override
  String get verPoint => 'Ver Punkt';

  @override
  String couldNotLoadImageFrom(String location) {
    return 'Konnte Bild nicht von $location laden.';
  }

  @override
  String resetSetting(String setting) {
    return '$setting zurücksetzen';
  }

  @override
  String get noFileLoaded => 'Keine Datei geladen';

  @override
  String get openReferenceImage => 'Referenzbild öffnen';

  @override
  String get aspectRatio => 'Seitenverhältnis';

  @override
  String get zoom => 'Zoom';

  @override
  String get expandHorizontallyAndCenter =>
      ' Horizontal ausdehnen und zentrieren (aktuelles Seitenverhältnis wird beibehalten)';

  @override
  String get expandVerticallyAndCenter =>
      'Vertikal ausdehnen und zentrieren (aktuelles Seitenverhältnis wird beibehalten)';

  @override
  String get fitsImageIntoCanvas =>
      'Bild in Leinwand einpassen (Seitenverhältnis wird geändert)';

  @override
  String get contrast => 'Kontrast';

  @override
  String get saturation => 'Sättigung';

  @override
  String get warmth => 'Wärme';

  @override
  String get shading => 'Schattierung';

  @override
  String get currentRampOnly => 'nur aktuelle Rampe';

  @override
  String get direction => 'Richtung';

  @override
  String get loadingDot => 'Lade...';

  @override
  String get thisDeviceDoesNotSupportResolution =>
      'Dieses Gerät unterstützt nicht die minimale logische Auflösung, die zum Ausführen dieser Anwendung erforderlich ist.';

  @override
  String get customProjectDirectoryInvalid =>
      'Das benutzerdefinierte Projektverzeichnis ist ungültig. Es wird auf das Standardverzeichnis zurückgegriffen.';

  @override
  String get couldNotCreateInternalDirectories =>
      'Interne Verzeichnisse konnten nicht erstellt werden.';

  @override
  String get couldNotInitializeApp =>
      'Die Anwendung konnte nicht initialisiert werden.';

  @override
  String get aCustomProjectDirectoryIsUsed =>
      'Es wird ein benutzerdefiniertes Projektverzeichnis verwendet, aber KPix verfügt nicht über die Berechtigung „Zugriff auf alle Dateien“. Von anderen Apps (z. B. Synchronisierungstools) erstellte Projektdateien werden möglicherweise nicht angezeigt.\nSollen die Systemeinstellungen geöffnet werden, um die Berechtigung zu erteilen?';

  @override
  String get workRecovered => 'Arbeit wiederhergestellt';

  @override
  String get undo => 'Rückgängig';

  @override
  String get redo => 'Wiederholen';

  @override
  String get about => 'Über';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get saveDot => 'Speichern...';

  @override
  String get newOpenDot => 'Neu/Öffnen...';

  @override
  String get errorImportingImage => 'Fehler beim Importieren des Bildes.';

  @override
  String get thereAreUnsavedChanges =>
      'Es gibt ungespeicherte Änderungen, zuerst speichern?';

  @override
  String get importingImageDot => 'Importiere Bild...';

  @override
  String get exportingDot => 'Exportiere...';

  @override
  String get movingProjectFilesDot => 'Verschiebe Projektdateien...';

  @override
  String changedProjectDirectoryFiles(String directory, int count) {
    return 'Projektverzeichnis geändert zu $directory ($count Projektdatei(en) verschoben).';
  }

  @override
  String projectDirWasNotChanged(String message) {
    return 'Das Projektverzeichnis wurde nicht geändert!\n$message';
  }

  @override
  String exportedPaletteTo(String path) {
    return 'Palette exportiert nach: $path';
  }

  @override
  String get errorExportingPaletteFile => 'Fehler beim Exportieren der Palette';

  @override
  String exportedTo(String path) {
    return 'Exportiert nach: $path';
  }

  @override
  String get errorExportingFile => 'Fehler beim Exportieren der Datei!';

  @override
  String get withoutAllFilesWarning =>
      'Ohne die \"Zugriff auf alle Dateien erlauben\" Erlaubnis, kann KPix keine Projektdateien sehen, die von anderen Programmen (wie Synchronisations-Tools) in diesem Verzeichnis sehen.\nSollen die Systemeinstellungen geöffnet werden um den Zugriff zu erlauben?';

  @override
  String get allFilesAccessNotNeededWarning =>
      'Die \"Zugriff auf alle Dateien erlauben\" Erlaubnis wird für das Standardverzeichnis nicht benötigt.\nSollen die Systemeinstellungen geöffnet werden um die Berechtigung zu entfernen?';

  @override
  String get initial => 'Initial';

  @override
  String get generic => 'Allgemein';

  @override
  String get saveData => 'Daten speichern';

  @override
  String get loadData => 'Daten laden';

  @override
  String get selectLayer => 'Ebene auswählen';

  @override
  String get selectLayerMoveSelection =>
      'Ebene auswählen (Auswahl verschieben)';

  @override
  String get mergeLayer => 'Ebene zusammenführen';

  @override
  String get changeLayerOrder => 'Ebenenreihenfolge ändern';

  @override
  String get layerVisibilityChanged => 'Ebenensichtbarkeit ändern';

  @override
  String get layerLockStateChanged => 'Ebenensperre ändern';

  @override
  String get changeReferenceImage => 'Referenzbild ändern';

  @override
  String get layerSettingsChange => 'Ebeneneinstellungen ändern';

  @override
  String get layerSettingsRaster => 'Ebeneneinstellungen rastern';

  @override
  String get newSelection => 'Neue Auswahl';

  @override
  String get cutSelection => 'Auswahl ausschneiden';

  @override
  String get flipSelectionHorizontally => 'Auswahl horizontal spiegeln';

  @override
  String get flipSelectionVertically => 'Auswahl vertikal spiegeln';

  @override
  String get rotateSelection => 'Auswahl drehen';

  @override
  String get moveSelection => 'Auswahl verschieben';

  @override
  String get pasteSelection => 'Auswahl einfügen';

  @override
  String get selectionToNewLayer => 'Auswahl in neue Ebene umwandeln';

  @override
  String get deleteSelection => 'Auswahl löschen';

  @override
  String get changeCanvasSize => 'Leinwandgröße ändern';

  @override
  String get penDrawing => 'Mit Stift zeichnen';

  @override
  String get stampDrawing => 'Mit Stempel zeichnen';

  @override
  String get erase => 'Radieren';

  @override
  String get fontDrawing => 'Text zeichnen';

  @override
  String get shapeDrawing => 'Form zeichnen';

  @override
  String get lineDrawing => 'Linie zeichnen';

  @override
  String get sprayCanDrawing => 'Mit Sprühdose zeichnen';

  @override
  String get changeColorSelection => 'Farbauswahl ändern';

  @override
  String get deleteRamp => 'Farbrampe löschen';

  @override
  String get updateRamp => 'Farbrampe aktualisieren';

  @override
  String get replacePalette => 'Palette ersetzen';

  @override
  String get addNewRamp => 'Neue Farbrampe hinzufügen';

  @override
  String get changeRampOrder => 'Reihenfolge der Farbrampen ändern';

  @override
  String get changeFrameTime => 'Framedauer ändern';

  @override
  String get changeLoopMarker => 'Loop-Markierung ändern';
}
