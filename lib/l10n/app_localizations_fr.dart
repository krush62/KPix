// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get close => 'Fermer';

  @override
  String get color => 'Couleur';

  @override
  String get createNewProject => 'Créer un nouveau projet';

  @override
  String get width => 'Largeur';

  @override
  String get height => 'Hauteur';

  @override
  String get presets => 'Préréglages';

  @override
  String get custom => 'Personnalisé';

  @override
  String get lockAspectRatio => 'Verrouiller les proportions';

  @override
  String get exitApplication => 'Quitter l\'application';

  @override
  String get openProjectManager => 'Ouvrir le gestionnaire de projets';

  @override
  String get createProject => 'Créer le projet';

  @override
  String get projectManager => 'Gestionnaire de projets';

  @override
  String get filter => 'Filtre';

  @override
  String get sortFileNameAsc => 'Trier par nom de fichier (croissant)';

  @override
  String get sortFileNameDesc => 'Trier par nom de fichier (décroissant)';

  @override
  String get sortDateAsc => 'Trier par date de modification (croissant)';

  @override
  String get sortDateDesc => 'Trier par date de modification (décroissant)';

  @override
  String get importProject => 'Importer un projet';

  @override
  String get deleteSelectedProject => 'Supprimer le projet sélectionné';

  @override
  String get loadSelectedProject => 'Charger le projet sélectionné';

  @override
  String get unsavedChangesSaveFirst =>
      'Certaines modifications ne sont pas enregistrées. Voulez-vous d\'abord enregistrer ?';

  @override
  String get openingImageDot => 'Ouverture de l\'image...';

  @override
  String get doYouReallyWantToDeleteProject =>
      'Voulez-vous vraiment supprimer ce projet ?';

  @override
  String get projectImportSuccessful => 'Projet importé avec succès !';

  @override
  String get couldNotOpenFile => 'Impossible d\'ouvrir le fichier !';

  @override
  String get projectWithSameNameExists =>
      'Un projet portant le même nom existe déjà !';

  @override
  String projectNameTaken({required String name}) {
    return 'Un projet nommé « $name » existe déjà. Ouvrir ce projet ou importer le fichier en tant que copie ?';
  }

  @override
  String get openExistingProject => 'Ouvrir le projet existant';

  @override
  String get importAsCopy => 'Importer en tant que copie';

  @override
  String droppedImageQuestion({required String name}) {
    return 'Ajouter « $name » comme calque de référence ou l\'importer comme nouveau projet ?';
  }

  @override
  String get addAsReferenceLayer => 'Ajouter comme calque de référence';

  @override
  String get importAsNewProject => 'Importer comme nouveau projet';

  @override
  String droppedFileNotSupported({required String formats}) {
    return 'Seuls les projets KPix et les images ($formats) peuvent être ouverts !';
  }

  @override
  String get pleaseSelectAKPixFile => 'Veuillez sélectionner un fichier KPix !';

  @override
  String get couldNotReadProjectDir =>
      'Impossible de lire le dossier des projets !';

  @override
  String get noFilesFound => 'Aucun fichier trouvé !';

  @override
  String get keyShift => 'Maj';

  @override
  String get keyAlt => 'Alt';

  @override
  String get keyCtrl => 'Ctrl';

  @override
  String get keySpace => 'Espace';

  @override
  String get buttonOff => 'SANS';

  @override
  String get buttonSolid => 'UNI';

  @override
  String get buttonRelative => 'REL';

  @override
  String get buttonGlow => 'LUM';

  @override
  String get buttonShade => 'OMB';

  @override
  String get buttonBevel => 'BIS';

  @override
  String get outerStrokeOff => 'Sans contour extérieur';

  @override
  String get outerStrokeSolid => 'Contour extérieur uni';

  @override
  String get outerStrokeRelative => 'Contour extérieur relatif à la couleur';

  @override
  String get outerStrokeGlowing => 'Contour extérieur lumineux';

  @override
  String get outerStrokeShaded => 'Contour extérieur ombré';

  @override
  String get innerStrokeOff => 'Sans contour intérieur';

  @override
  String get innerStrokeSolid => 'Contour intérieur uni';

  @override
  String get innerStrokeBeveled => 'Contour intérieur biseauté';

  @override
  String get innerStrokeGlowing => 'Contour intérieur lumineux';

  @override
  String get innerStrokeShaded => 'Contour intérieur ombré';

  @override
  String get shadowOff => 'Sans ombre portée';

  @override
  String get shadowSolid => 'Ombre portée unie';

  @override
  String get shadowShaded => 'Ombre portée par ombrage';

  @override
  String stepCount({required int count, required String value}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$value niveaux',
      one: '$value niveau',
    );
    return '$_temp0';
  }

  @override
  String get recursive => 'récursif';

  @override
  String get outerStroke => 'Contour extérieur';

  @override
  String get innerStroke => 'Contour intérieur';

  @override
  String get dropShadow => 'Ombre portée';

  @override
  String get selectOuterStrokeColor =>
      'Choisir la couleur du contour extérieur';

  @override
  String get darkenBrighten => 'Foncer/Éclaircir';

  @override
  String get darkenBrightenBreak => 'Foncer /\nÉclaircir';

  @override
  String get applyOuterStroke => 'Appliquer le contour extérieur';

  @override
  String get selectInnerStrokeColor =>
      'Choisir la couleur du contour intérieur';

  @override
  String get applyInnerStroke => 'Appliquer le contour intérieur';

  @override
  String get horizontal => 'horizontal';

  @override
  String get vertical => 'vertical';

  @override
  String get selectDropShadowColor => 'Choisir la couleur de l\'ombre portée';

  @override
  String get applyDropShadow => 'Appliquer l\'ombre portée';

  @override
  String get pixelsAbbrev => 'px';

  @override
  String get invalidLayerIndex => 'Position d\'insertion du calque invalide.';

  @override
  String get couldNotAddMoreLayers =>
      'Impossible d\'ajouter d\'autres calques.';

  @override
  String get layerAlreadyExistsOnFrame =>
      'Le calque existe déjà dans cette frame.';

  @override
  String get cannotAddMoreFrames => 'Impossible d\'ajouter d\'autres frames.';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get noLayerBelow => 'Aucun calque en dessous !';

  @override
  String get cannotMergeFromLinkedLayer =>
      'Impossible de fusionner depuis un calque lié !';

  @override
  String get cannotMergeToLinkedLayer =>
      'Impossible de fusionner vers un calque lié !';

  @override
  String get cannotMergeFromInvisibleLayer =>
      'Impossible de fusionner depuis un calque masqué !';

  @override
  String get cannotMergeToInvisibleLayer =>
      'Impossible de fusionner vers un calque masqué !';

  @override
  String get cannotMergeFromLockedLayer =>
      'Impossible de fusionner depuis un calque verrouillé !';

  @override
  String get cannotMergeToLockedLayer =>
      'Impossible de fusionner vers un calque verrouillé !';

  @override
  String get canOnlyMergeWithDrawingLayer =>
      'La fusion n\'est possible qu\'avec des calques de dessin !';

  @override
  String get cannotMergeWithActiveEffects =>
      'Impossible de fusionner des calques avec des effets actifs !';

  @override
  String get cannotDeleteLastLayer =>
      'Impossible de supprimer le dernier calque !';

  @override
  String get cannotDeleteFromHiddenLayer =>
      'Impossible de supprimer dans un calque masqué !';

  @override
  String get cannotDeleteFromLockedLayer =>
      'Impossible de supprimer dans un calque verrouillé !';

  @override
  String get cannotCutFromHiddenLayer =>
      'Impossible de couper dans un calque masqué !';

  @override
  String get cannotCutFromLockedLayer =>
      'Impossible de couper dans un calque verrouillé !';

  @override
  String get nothingToCopy => 'Rien à copier !';

  @override
  String get nothingToPasteColorsNotInPalette =>
      'Rien à coller : les couleurs copiées ne sont plus dans la palette !';

  @override
  String get cannotPasteToHiddenLayer =>
      'Impossible de coller dans un calque masqué !';

  @override
  String get cannotPasteToLockedLayer =>
      'Impossible de coller dans un calque verrouillé !';

  @override
  String get cannotTransformOnHiddenLayer =>
      'Impossible de transformer sur un calque masqué !';

  @override
  String get cannotTransformOnLockedLayer =>
      'Impossible de transformer sur un calque verrouillé !';

  @override
  String needAtLeastColorRamps({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Au moins $count rampes de couleurs sont nécessaires !',
      one: 'Au moins $count rampe de couleurs est nécessaire !',
    );
    return '$_temp0';
  }

  @override
  String notMoreThanColorRampsAllowed({required int count}) {
    return 'Pas plus de $count rampes de couleurs autorisées !';
  }

  @override
  String get loadingPaletteFailed => 'Échec du chargement de la palette !';

  @override
  String undoStep({required String description}) {
    return 'Annuler : $description';
  }

  @override
  String redoStep({required String description}) {
    return 'Rétablir : $description';
  }

  @override
  String get historyRestoreFailed =>
      'Échec de la restauration de l\'historique !';

  @override
  String loadingFailed({required String status}) {
    return 'Échec du chargement ($status)';
  }

  @override
  String fileSavedAt({required String path}) {
    return 'Fichier enregistré sous : $path';
  }

  @override
  String get imageImportSuccessful => 'Image importée avec succès !';

  @override
  String get couldNotConvertImageData =>
      'Impossible de convertir les données de l\'image !';

  @override
  String get couldNotCrop => 'Recadrage impossible !';

  @override
  String get cropToSelection => 'Recadrer selon la sélection';

  @override
  String get hidden => 'Masqué';

  @override
  String get visible => 'Visible';

  @override
  String get unlocked => 'Déverrouillé';

  @override
  String get transparencyLocked => 'Transparence verrouillée';

  @override
  String get locked => 'Verrouillé';

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
  String get buttonBrk => 'BRI';

  @override
  String get button1Point => '1 point';

  @override
  String get button2Point => '2 points';

  @override
  String get button3Point => '3 points';

  @override
  String get rectangularGrid => 'Grille rectangulaire';

  @override
  String get diagonalGrid => 'Grille diagonale';

  @override
  String get isometricGrid => 'Grille isométrique';

  @override
  String get hexagonalGrid => 'Grille hexagonale';

  @override
  String get triangularGrid => 'Grille triangulaire';

  @override
  String get bricks => 'Briques';

  @override
  String get onePointPerspective => 'Perspective à 1 point';

  @override
  String get twoPointPerspective => 'Perspective à 2 points';

  @override
  String get threePointPerspective => 'Perspective à 3 points';

  @override
  String get ascendingSegmentOrder => 'Segments par ordre croissant';

  @override
  String get ascendingDescendingSegmentOrder =>
      'Segments par ordre croissant/décroissant';

  @override
  String get descendingAscendingSegmentOrder =>
      'Segments par ordre décroissant/croissant';

  @override
  String get descendingSegmentOrder => 'Segments par ordre décroissant';

  @override
  String get round => 'Rond';

  @override
  String get square => 'Carré';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get ellipse => 'Ellipse';

  @override
  String get polygon => 'Polygone';

  @override
  String get wand => 'Baguette magique';

  @override
  String get triangle => 'Triangle';

  @override
  String get midAngleRectangle => 'Rectangle incliné';

  @override
  String get regularPolygon => 'Polygone régulier';

  @override
  String get star => 'Étoile';

  @override
  String get replaceSelection => 'Remplacer la sélection';

  @override
  String get addToSelection => 'Ajouter à la sélection';

  @override
  String get subtractFromSelection => 'Soustraire de la sélection';

  @override
  String get intersectWithSelection => 'Intersection avec la sélection';

  @override
  String get pencil => 'Crayon';

  @override
  String get shape => 'Forme';

  @override
  String get fill => 'Remplissage';

  @override
  String get select => 'Sélection';

  @override
  String get colorPicker => 'Pipette';

  @override
  String get eraser => 'Gomme';

  @override
  String get text => 'Texte';

  @override
  String get textToolDefaultText => 'Texte';

  @override
  String get sprayCan => 'Aérographe';

  @override
  String get line => 'Ligne';

  @override
  String get stamp => 'Tampon';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get cursorNone => 'Aucun';

  @override
  String get cursorCrosshair => 'Réticule';

  @override
  String get cursorArrow => 'Flèche';

  @override
  String get rawModeExplanation =>
      'Le mode brut n\'utilise aucune valeur des calques d\'ombrage ni des paramètres de calque qui utilisent l\'ombrage.';

  @override
  String get rawMode => 'Mode brut';

  @override
  String get size => 'Taille';

  @override
  String get fillAdjacent => 'Remplissage contigu';

  @override
  String get fillWholeRamp => 'Remplir toute la rampe';

  @override
  String get integerAspectRatio => 'Proportions entières';

  @override
  String get segmentSorting => 'Tri des segments';

  @override
  String get smooth => 'Lissage';

  @override
  String get mode => 'Mode';

  @override
  String get continuous => 'Contigu';

  @override
  String get keep1to1 => 'Garder 1:1';

  @override
  String get wholeRamp => 'Toute la rampe';

  @override
  String get strokeOnly => 'Contour seul';

  @override
  String get cornerRadius => 'Rayon des coins';

  @override
  String get angle => 'Angle';

  @override
  String get cornerCount => 'Nombre de coins';

  @override
  String get radius => 'Rayon';

  @override
  String get blobSize => 'Taille des gouttes';

  @override
  String get intensity => 'Intensité';

  @override
  String get noStamp => 'Aucun tampon';

  @override
  String get scale => 'Échelle';

  @override
  String get gridAlign => 'Aligner sur la grille';

  @override
  String get offsetX => 'Décalage X';

  @override
  String get offsetY => 'Décalage Y';

  @override
  String get font => 'Police';

  @override
  String get available => 'Disponible';

  @override
  String get invalidFileName => 'Nom de fichier invalide';

  @override
  String get insufficientPermissions => 'Autorisations insuffisantes';

  @override
  String get overwritingExistingFile => 'Le fichier existant sera écrasé';

  @override
  String get rotateCanvas => 'Faire pivoter le canevas';

  @override
  String get flipCanvasHorizontally => 'Retourner le canevas horizontalement';

  @override
  String get flipCanvasVertically => 'Retourner le canevas verticalement';

  @override
  String get canvasSize => 'Taille du canevas';

  @override
  String get offset => 'Décalage';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get deselect => 'Désélectionner';

  @override
  String get inverseSelection => 'Inverser la sélection';

  @override
  String get copy => 'Copier';

  @override
  String get copyMerged => 'Copier avec fusion';

  @override
  String get cut => 'Couper';

  @override
  String get paste => 'Coller';

  @override
  String get pasteAsNewLayer => 'Coller comme nouveau calque';

  @override
  String get horizontalFlip => 'Retourner horizontalement';

  @override
  String get verticalFlip => 'Retourner verticalement';

  @override
  String get rotate90Clockwise => 'Rotation de 90° dans le sens horaire';

  @override
  String get alignDot => 'Aligner...';

  @override
  String get delete => 'Supprimer';

  @override
  String get selectAColor => 'Choisir une couleur';

  @override
  String get newVersionAvailable => 'Nouvelle version disponible';

  @override
  String get downloadFromGithub => 'Télécharger depuis GitHub';

  @override
  String get aPixelArtCreationTool => 'Un outil de création de pixel art';

  @override
  String get thisIsFreeSoftwareLicensed =>
      'Ceci est un logiciel libre sous licence';

  @override
  String get gnuAGPLv3 => 'GNU AGPLv3';

  @override
  String get credits => 'Crédits';

  @override
  String get licenses => 'Licences';

  @override
  String get controlsShortcuts => 'Commandes/Raccourcis';

  @override
  String get textToolContent => 'Contenu de l\'outil Texte';

  @override
  String get gui => 'Interface';

  @override
  String get behavior => 'Comportement';

  @override
  String get controlsPC => 'Commandes PC';

  @override
  String get controlsStylus => 'Commandes stylet';

  @override
  String get controlsTouch => 'Commandes tactiles';

  @override
  String get image => 'Image';

  @override
  String get animation => 'Animation';

  @override
  String get palette => 'Palette';

  @override
  String get kpixProject => 'Projet KPix';

  @override
  String get export => 'Export';

  @override
  String get format => 'Format';

  @override
  String get texturePack => 'Pack de textures';

  @override
  String get texturePackAnimation => 'Pack de textures animé';

  @override
  String get pngSequence => 'Séquence PNG';

  @override
  String get scaling => 'Mise à l\'échelle';

  @override
  String get selectionOnly => 'Sélection uniquement';

  @override
  String nFrames({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frames',
      one: '1 frame',
      zero: '0 frame',
    );
    return '$_temp0';
  }

  @override
  String frameNumber({required int number}) {
    return 'Frame $number';
  }

  @override
  String get directory => 'Dossier';

  @override
  String get changeDirectory => 'Changer de dossier';

  @override
  String get fileName => 'Nom du fichier';

  @override
  String get exportFile => 'Exporter le fichier';

  @override
  String imageDimensionsExceed({required int width, required int height}) {
    return 'Les dimensions de l\'image ne peuvent pas dépasser $width × $height !';
  }

  @override
  String get couldNotDecodeImage => 'Impossible de décoder l\'image !';

  @override
  String get couldNotLoadFile => 'Impossible de charger le fichier !';

  @override
  String get importImage => 'Importer une image';

  @override
  String get file => 'Fichier';

  @override
  String get noFileSelected => 'Aucun fichier sélectionné';

  @override
  String get chooseImage => 'Choisir une image';

  @override
  String get scaleDown => 'Réduire';

  @override
  String get createNewPaletteFromImage =>
      'Créer une nouvelle palette à partir de l\'image';

  @override
  String get maxColorRamps => 'Rampes de couleurs max.';

  @override
  String get maxColorsPerRamp => 'Couleurs max. par rampe';

  @override
  String get includeImageAsReferenceLayer =>
      'Inclure l\'image comme calque de référence';

  @override
  String get import => 'Importer';

  @override
  String get saveProjectAs => 'Enregistrer le projet sous';

  @override
  String get hueAbb => 'tein';

  @override
  String get satAbb => 'sat';

  @override
  String get valAbb => 'val';

  @override
  String get pressToReset => 'Appuyer pour réinitialiser';

  @override
  String get colorCount => 'Nombre de couleurs';

  @override
  String get baseHue => 'Teinte de base';

  @override
  String get hueShift => 'Décalage de teinte';

  @override
  String get exponent => 'Exposant';

  @override
  String get baseSat => 'Saturation de base';

  @override
  String get satShift => 'Décalage de saturation';

  @override
  String get satCurve => 'Courbe de saturation';

  @override
  String get satCurveNoFlat =>
      'Saturation réduite pour les valeurs sombres et claires';

  @override
  String get satCurveDarkFlat => 'Saturation réduite pour les valeurs claires';

  @override
  String get satCurveBrightFlat =>
      'Saturation réduite pour les valeurs sombres';

  @override
  String get satCurveLinear => 'Progression linéaire de la saturation';

  @override
  String get valueRange => 'Plage de valeurs';

  @override
  String deleteColorRampQuestion({required int amount}) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount pixels seront supprimés',
      one: '$amount pixel sera supprimé',
    );
    return 'Voulez-vous vraiment supprimer cette rampe de couleurs ?\n$_temp0';
  }

  @override
  String ofThemInSelection({required int amount}) {
    return '(dont $amount dans la sélection)';
  }

  @override
  String pixelsInClipboard({required int amount}) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount pixels du presse-papiers ne seront plus collés',
      one: '$amount pixel du presse-papiers ne sera plus collé',
    );
    return '$_temp0';
  }

  @override
  String get shadingRange => 'Plage d\'ombrage';

  @override
  String get maxDarken => 'Foncer max.';

  @override
  String get maxBrighten => 'Éclaircir max.';

  @override
  String get layerActionsDot => 'Actions du calque...';

  @override
  String get settings => 'Paramètres';

  @override
  String get addNewLayerDot => 'Ajouter un calque...';

  @override
  String get layerSettings => 'Paramètres du calque';

  @override
  String get symmetryOptions => 'Options de symétrie';

  @override
  String get centerHorizontalRuler => 'Centrer l\'axe horizontal';

  @override
  String get centerVerticalRuler => 'Centrer l\'axe vertical';

  @override
  String get addNewDrawingLayer => 'Ajouter un calque de dessin';

  @override
  String get addNewShadingLayer => 'Ajouter un calque d\'ombrage';

  @override
  String get addNewDitherLayer => 'Ajouter un calque de tramage';

  @override
  String get addNewReferenceLayer => 'Ajouter un calque de référence';

  @override
  String get addNewGridLayer => 'Ajouter un calque de grille';

  @override
  String get deleteLayer => 'Supprimer le calque';

  @override
  String get duplicateLayer => 'Dupliquer le calque';

  @override
  String get mergeDownLayer => 'Fusionner avec le calque inférieur';

  @override
  String get unlinkLayer => 'Délier le calque / Rendre unique';

  @override
  String get newProject => 'Nouveau projet';

  @override
  String get openProject => 'Ouvrir un projet';

  @override
  String get rasterLayer => 'Pixelliser le calque';

  @override
  String get saveProject => 'Enregistrer le projet';

  @override
  String get exportProjectPalette => 'Exporter le projet/la palette';

  @override
  String get exportShaderImage => 'Exporter une image avec shader [BÊTA]';

  @override
  String get shaderLcd => 'LCD';

  @override
  String get shaderSmoothEdges => 'Bords lissés';

  @override
  String get shaderDithering => 'Tramage';

  @override
  String get shaderEffects => 'Effets';

  @override
  String get colorTolerance => 'Tolérance de couleur';

  @override
  String get smoothness => 'Lissage';

  @override
  String get antiAliasing => 'Anticrénelage';

  @override
  String get lineWidth => 'Épaisseur des lignes';

  @override
  String get similarityThreshold => 'Seuil de similarité';

  @override
  String get gridWidth => 'Épaisseur de la grille';

  @override
  String get gridColor => 'Couleur de la grille';

  @override
  String get softness => 'Douceur';

  @override
  String get subpixels => 'Sous-pixels RVB';

  @override
  String get gridOnTransparency => 'Grille sur la transparence';

  @override
  String get zoomIn => 'Zoom avant';

  @override
  String get zoomOut => 'Zoom arrière';

  @override
  String get zoomToFit => 'Ajuster à la vue';

  @override
  String get colorDepth => 'Profondeur de couleur';

  @override
  String get tuneDithering => 'Ajuster le tramage';

  @override
  String get bayerLevel => 'Niveau Bayer';

  @override
  String get influence => 'Influence';

  @override
  String get strength => 'Force';

  @override
  String get rounding => 'Arrondi';

  @override
  String get fullRange => 'Plage complète';

  @override
  String get dotSize => 'Taille des points';

  @override
  String get originalMix => 'Mélange avec l\'original';

  @override
  String get dotGain => 'Engraissement du point';

  @override
  String get dotShape => 'Forme des points';

  @override
  String get diamond => 'Losange';

  @override
  String get misregistration => 'Défaut de repérage';

  @override
  String get backgroundBrightness => 'Luminosité du fond';

  @override
  String get backgroundWarmth => 'Chaleur du fond';

  @override
  String get outerRadius => 'Rayon extérieur';

  @override
  String get innerRadius => 'Rayon intérieur';

  @override
  String get sharpness => 'Netteté';

  @override
  String get lightAngle => 'Angle de la lumière';

  @override
  String get depth => 'Profondeur';

  @override
  String get bevelWidth => 'Largeur du biseau';

  @override
  String get heightFromBrightness => 'Hauteur selon la luminosité';

  @override
  String get shaderCrt => 'CRT';

  @override
  String get medium => 'Support';

  @override
  String get signal => 'Signal';

  @override
  String get colorEncoding => 'Codage couleur';

  @override
  String get tv => 'Téléviseur';

  @override
  String get wear => 'Usure';

  @override
  String get artifacts => 'Artefacts';

  @override
  String get noise => 'Bruit';

  @override
  String get ghosting => 'Images fantômes';

  @override
  String get encoding => 'Codage';

  @override
  String get phaseError => 'Erreur de phase';

  @override
  String get convergence => 'Convergence';

  @override
  String get scanlines => 'Lignes de balayage';

  @override
  String get mask => 'Masque';

  @override
  String get maskStrength => 'Intensité du masque';

  @override
  String get bloom => 'Flou lumineux';

  @override
  String get curvature => 'Courbure';

  @override
  String get vignette => 'Vignettage';

  @override
  String get none => 'Aucun';

  @override
  String get apertureGrille => 'Grille';

  @override
  String get slotMask => 'Fentes';

  @override
  String get shadowMask => 'Perforé';

  @override
  String get checkerboard => 'Damier';

  @override
  String get panel => 'Panneau';

  @override
  String get panelColors => 'Couleurs du panneau';

  @override
  String get blackLevel => 'Niveau de noir';

  @override
  String get unevenBacklight => 'Rétroéclairage inégal';

  @override
  String get glow => 'Lueur';

  @override
  String get glowRadius => 'Rayon de la lueur';

  @override
  String get pixelShadow => 'Ombre des pixels';

  @override
  String get shadowDistance => 'Distance de l\'ombre';

  @override
  String get outlineWidth => 'Épaisseur du contour';

  @override
  String get outlineStrength => 'Intensité du contour';

  @override
  String get intensityLevels => 'Niveaux d\'intensité';

  @override
  String get intensityMode => 'Mode d\'intensité';

  @override
  String shaderMinScaling({required int factor}) {
    return 'La mise à l\'échelle doit être d\'au moins $factor:1 pour ce shader.';
  }

  @override
  String get centerHorizontally => 'Centrer horizontalement';

  @override
  String get centerVertically => 'Centrer verticalement';

  @override
  String get left => 'Gauche';

  @override
  String get right => 'Droite';

  @override
  String get top => 'Haut';

  @override
  String get bottom => 'Bas';

  @override
  String get editColorRamp => 'Modifier la rampe de couleurs';

  @override
  String nColors({required int amount}) {
    return '$amount couleurs';
  }

  @override
  String nRampsColors({required int rampAmount, required int colorAmount}) {
    return '$rampAmount rampes | $colorAmount couleurs';
  }

  @override
  String get remapExistingColors =>
      'Voulez-vous réassigner les couleurs existantes (sinon, tous les pixels seront supprimés) ?';

  @override
  String get wantToDeletePalette =>
      'Voulez-vous vraiment supprimer cette palette ?';

  @override
  String get paletteManager => 'Gestionnaire de palettes';

  @override
  String get importPalette => 'Importer une palette';

  @override
  String get saveCurrentPalette => 'Enregistrer la palette actuelle';

  @override
  String get deleteSelectedPalette => 'Supprimer la palette sélectionnée';

  @override
  String get appendToCurrentPalette => 'Ajouter à la palette actuelle';

  @override
  String get applySelectedPalette => 'Appliquer la palette sélectionnée';

  @override
  String get addNewColorRamp => 'Ajouter une rampe de couleurs';

  @override
  String get paletteAdjustments => 'Ajustements de la palette';

  @override
  String get adjustPalette => 'Ajuster la palette';

  @override
  String get whiteBalance => 'Balance des blancs';

  @override
  String get tint => 'Nuance';

  @override
  String get hueSpread => 'Étalement des teintes';

  @override
  String get includeRampInAdjustment => 'Inclure la rampe dans l\'ajustement';

  @override
  String get resetAllAdjustments => 'Réinitialiser tous les ajustements';

  @override
  String get resetValue => 'Réinitialiser la valeur';

  @override
  String get holdToShowOriginal => 'Maintenir pour afficher l\'original';

  @override
  String get valueClipping => 'Écrêtage de la valeur';

  @override
  String get saturationClipping => 'Écrêtage de la saturation';

  @override
  String get savePalette => 'Enregistrer la palette';

  @override
  String get defaultPalette => 'Par défaut';

  @override
  String get errorSavingPalette =>
      'Erreur lors de l\'enregistrement de la palette !';

  @override
  String get errorSavingProject =>
      'Erreur lors de l\'enregistrement du projet ! Vos modifications n\'ont pas été enregistrées.';

  @override
  String paletteSavedAt({required String path}) {
    return 'Palette enregistrée avec succès sous $path.';
  }

  @override
  String get paletteWithSameNameExists =>
      'Une palette portant le même nom existe déjà !';

  @override
  String get pleaseSelectAKPalFile => 'Veuillez sélectionner un fichier KPal !';

  @override
  String get paletteImportSuccessful => 'Importation réussie !';

  @override
  String get paletteImportFailed => 'Échec de l\'importation !';

  @override
  String get insufficientPermissionsForDir =>
      'Autorisations insuffisantes pour le dossier sélectionné !';

  @override
  String get undoSteps => 'Étapes d\'annulation';

  @override
  String get selectInsertedLayers => 'Sélectionner les calques insérés';

  @override
  String get activateSelectionToolAfterPaste =>
      'Activer l\'outil de sélection après le collage';

  @override
  String get defaultShadingLayerSettings =>
      'Paramètres par défaut des calques d\'ombrage';

  @override
  String get defaultFrameTime => 'Durée de frame par défaut';

  @override
  String get showReferenceLayersOutsideOfCanvas =>
      'Afficher les calques de référence hors du canevas';

  @override
  String get projectDirectory => 'Dossier des projets';

  @override
  String get defaultDir => 'Par défaut';

  @override
  String get customDir => 'Personnalisé';

  @override
  String get chooseDirectory => 'Choisir un dossier';

  @override
  String get mouseCursor => 'Curseur de la souris';

  @override
  String get languagePreferences => 'Préférences de langue';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get themePreferences => 'Préférences de thème';

  @override
  String get theme => 'Thème';

  @override
  String get checkerboardPreferences => 'Préférences du damier';

  @override
  String get checkerboardSize => 'Taille du damier';

  @override
  String get checkerboardContrast => 'Contraste du damier';

  @override
  String get palettePreferences => 'Préférences de palette';

  @override
  String get colorNaming => 'Noms des couleurs';

  @override
  String get borderPreferences => 'Préférences des bordures';

  @override
  String get toolOutlineOpacity => 'Opacité du contour de l\'outil';

  @override
  String get selectionOutlineOpacity => 'Opacité du contour de sélection';

  @override
  String get pulsatingSelectionOutline => 'Contour de sélection pulsant';

  @override
  String get canvasBorerOpacity => 'Opacité de la bordure du canevas';

  @override
  String get toolInfoPreferences => 'Préférences des infos d\'outil';

  @override
  String get showMeasurementsAtCursor => 'Afficher les mesures près du curseur';

  @override
  String get measurementInfoIsOnTheRight => 'Mesures à droite du curseur';

  @override
  String get timeThatNeedsToBeHeldDown =>
      'Durée de maintien nécessaire pour un appui long.';

  @override
  String get longPressDelay => 'Délai d\'appui long';

  @override
  String get distanceThatMustBeMoved =>
      'Distance à parcourir avec le bouton maintenu avant de déplacer la vue, de zoomer ou de changer la taille de l\'outil. Les mouvements plus courts comptent toujours comme un appui.';

  @override
  String get longPressCancelDistance =>
      'Distance d\'annulation de l\'appui long';

  @override
  String get distanceThatNeedsToBeMovedVertically =>
      'Distance verticale à parcourir pour zoomer ou dézoomer.';

  @override
  String get zoomStepDistance => 'Distance par cran de zoom';

  @override
  String get distanceThatNeedsToBeMovedHorizontally =>
      'Distance horizontale à parcourir pour changer la taille de l\'outil actuel.';

  @override
  String get toolSizeStepDistance => 'Distance par cran de taille d\'outil';

  @override
  String get timeoutForPickingAColor => 'Délai pour prélever une couleur.';

  @override
  String get colorPickTimeout => 'Délai de la pipette';

  @override
  String get touchDelay => 'Délai tactile';

  @override
  String get showNavigationJoysticks => 'Joysticks de navigation';

  @override
  String get stampManager => 'Gestionnaire de tampons';

  @override
  String get deleteSelectedStamp => 'Supprimer le tampon sélectionné';

  @override
  String get loadSelectedStamp => 'Charger le tampon sélectionné';

  @override
  String get doYouReallyWantToDeleteStamp =>
      'Voulez-vous vraiment supprimer ce tampon ?';

  @override
  String get frameBlending => 'Pelure d\'oignon';

  @override
  String get enabled => 'Activé';

  @override
  String get framesBefore => 'Frames précédentes';

  @override
  String get wrapAround => 'En boucle';

  @override
  String get framesAfter => 'Frames suivantes';

  @override
  String get opacity => 'Opacité';

  @override
  String get gradual => 'Progressif';

  @override
  String get tinting => 'Coloration';

  @override
  String get activeLayerOnly => 'Calque actif uniquement';

  @override
  String get cancel => 'Annuler';

  @override
  String get applyToAllFrames => 'Appliquer à toutes les frames';

  @override
  String get applyToCurrentFrame => 'Appliquer à la frame actuelle';

  @override
  String get collapseTimeline => 'Réduire la timeline';

  @override
  String get expandTimeline => 'Développer la timeline';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Lecture';

  @override
  String get loopStartMarker => 'Marqueur de début de boucle';

  @override
  String get loopEndMarker => 'Marqueur de fin de boucle';

  @override
  String get changeDuration => 'Modifier la durée';

  @override
  String get moveFrameLeft => 'Déplacer la frame vers la gauche';

  @override
  String get moveFrame => 'Déplacer la frame';

  @override
  String get moveFrameRight => 'Déplacer la frame vers la droite';

  @override
  String get addFrameLeft => 'Ajouter une frame à gauche';

  @override
  String get addFrame => 'Ajouter une frame';

  @override
  String get addFrameRight => 'Ajouter une frame à droite';

  @override
  String get copyFrameLeft => 'Copier la frame à gauche';

  @override
  String get copyFrame => 'Copier la frame';

  @override
  String get copyFrameRight => 'Copier la frame à droite';

  @override
  String get createLinkedFrameLeft => 'Créer une frame liée à gauche';

  @override
  String get createLinkedFrame => 'Créer une frame liée';

  @override
  String get createLinkedFrameRight => 'Créer une frame liée à droite';

  @override
  String get deleteFrame => 'Supprimer la frame';

  @override
  String get toggle => 'Activer/désactiver';

  @override
  String get grid => 'Grille';

  @override
  String get gridButton => 'GRILLE';

  @override
  String get perspective => 'Perspective';

  @override
  String get perspectiveButton => 'PERSPECTIVE';

  @override
  String get brightness => 'Luminosité';

  @override
  String get interval => 'Intervalle';

  @override
  String get intervalX => 'Intervalle X';

  @override
  String get intervalY => 'Intervalle Y';

  @override
  String get horizon => 'Horizon';

  @override
  String get vanishingPoint => 'Point de fuite';

  @override
  String get horPoints => 'Points hor.';

  @override
  String get verPoint => 'Point vert.';

  @override
  String couldNotLoadImageFrom({required String location}) {
    return 'Impossible de charger l\'image depuis $location.';
  }

  @override
  String resetSetting({required String setting}) {
    return 'Réinitialiser : $setting';
  }

  @override
  String get noFileLoaded => 'Aucun fichier chargé';

  @override
  String get openReferenceImage => 'Ouvrir une image de référence';

  @override
  String get aspectRatio => 'Proportions';

  @override
  String get zoom => 'Zoom';

  @override
  String get expandHorizontallyAndCenter =>
      'Étendre horizontalement et centrer en conservant les proportions actuelles';

  @override
  String get expandVerticallyAndCenter =>
      'Étendre verticalement et centrer en conservant les proportions actuelles';

  @override
  String get fitsImageIntoCanvas =>
      'Ajuste l\'image au canevas (modifie les proportions)';

  @override
  String get contrast => 'Contraste';

  @override
  String get saturation => 'Saturation';

  @override
  String get warmth => 'Chaleur';

  @override
  String get shading => 'Ombrage';

  @override
  String get currentRampOnly => 'Rampe actuelle uniquement';

  @override
  String get direction => 'Direction';

  @override
  String get loadingDot => 'Chargement...';

  @override
  String get thisDeviceDoesNotSupportResolution =>
      'Cet appareil ne prend pas en charge la résolution logique minimale requise pour exécuter cette application.';

  @override
  String get customProjectDirectoryInvalid =>
      'Le dossier de projets personnalisé est invalide. Le dossier par défaut est utilisé.';

  @override
  String get couldNotCreateInternalDirectories =>
      'Impossible de créer les dossiers internes.';

  @override
  String get couldNotInitializeApp =>
      'Impossible d\'initialiser l\'application.';

  @override
  String get aCustomProjectDirectoryIsUsed =>
      'Un dossier de projets personnalisé est utilisé, mais KPix ne dispose pas de l\'autorisation « Accès à tous les fichiers ». Les fichiers de projet créés par d\'autres applications (p. ex. des outils de synchronisation) risquent de ne pas s\'afficher.\nVoulez-vous ouvrir les paramètres système pour accorder l\'autorisation ?';

  @override
  String get workRecovered => 'Travail récupéré';

  @override
  String get undo => 'Annuler';

  @override
  String get redo => 'Rétablir';

  @override
  String get about => 'À propos';

  @override
  String get preferences => 'Préférences';

  @override
  String get saveDot => 'Enregistrer...';

  @override
  String get newOpenDot => 'Nouveau/Ouvrir...';

  @override
  String get errorImportingImage =>
      'Erreur lors de l\'importation de l\'image.';

  @override
  String get thereAreUnsavedChanges =>
      'Certaines modifications ne sont pas enregistrées. Voulez-vous d\'abord enregistrer ?';

  @override
  String get importingImageDot => 'Importation de l\'image...';

  @override
  String get exportingDot => 'Exportation...';

  @override
  String get movingProjectFilesDot => 'Déplacement des fichiers de projet...';

  @override
  String get targetDirCouldNotBeCreated =>
      'Le dossier n\'existe pas et n\'a pas pu être créé !';

  @override
  String dirAlreadyContainsFile({required String fileName}) {
    return 'Le dossier contient déjà un fichier nommé $fileName !';
  }

  @override
  String couldNotMoveFile({required String fileName}) {
    return 'Impossible de déplacer le fichier $fileName !';
  }

  @override
  String get unexpectedErrorMovingProjectFiles =>
      'Une erreur inattendue s\'est produite lors du déplacement des fichiers de projet !';

  @override
  String changedProjectDirectoryFiles({
    required String directory,
    required int count,
  }) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers de projet déplacés',
      one: '$count fichier de projet déplacé',
    );
    return 'Le dossier des projets est désormais $directory ($_temp0).';
  }

  @override
  String projectDirWasNotChanged({required String message}) {
    return 'Le dossier des projets n\'a pas été modifié !\n$message';
  }

  @override
  String exportedPaletteTo({required String path}) {
    return 'Palette exportée vers : $path';
  }

  @override
  String get errorExportingPaletteFile =>
      'Erreur lors de l\'exportation du fichier de palette.';

  @override
  String exportedTo({required String path}) {
    return 'Exporté vers : $path';
  }

  @override
  String get errorExportingFile => 'Erreur lors de l\'exportation du fichier !';

  @override
  String get withoutAllFilesWarning =>
      'Sans l\'autorisation « Accès à tous les fichiers », KPix ne peut pas voir les fichiers de projet créés dans ce dossier par d\'autres applications (p. ex. des outils de synchronisation).\nVoulez-vous ouvrir les paramètres système pour accorder l\'autorisation ?';

  @override
  String get allFilesAccessNotNeededWarning =>
      'L\'autorisation « Accès à tous les fichiers » n\'est pas nécessaire pour le dossier de projets par défaut.\nVoulez-vous ouvrir les paramètres système pour révoquer l\'autorisation ?';

  @override
  String get initial => 'État initial';

  @override
  String get generic => 'Générique';

  @override
  String get saveData => 'Enregistrer les données';

  @override
  String get loadData => 'Charger les données';

  @override
  String get selectLayer => 'Sélectionner un calque';

  @override
  String get selectLayerMoveSelection =>
      'Sélectionner un calque (déplacer la sélection)';

  @override
  String get mergeLayer => 'Fusionner le calque';

  @override
  String get changeLayerOrder => 'Modifier l\'ordre des calques';

  @override
  String get layerVisibilityChanged => 'Modifier la visibilité du calque';

  @override
  String get layerLockStateChanged => 'Modifier le verrouillage du calque';

  @override
  String get changeReferenceImage => 'Changer l\'image de référence';

  @override
  String get layerSettingsChange => 'Modifier les paramètres du calque';

  @override
  String get layerSettingsRaster => 'Appliquer un effet de calque';

  @override
  String get newSelection => 'Nouvelle sélection';

  @override
  String get cutSelection => 'Couper la sélection';

  @override
  String get flipSelectionHorizontally =>
      'Retourner la sélection horizontalement';

  @override
  String get flipSelectionVertically => 'Retourner la sélection verticalement';

  @override
  String get rotateSelection => 'Faire pivoter la sélection';

  @override
  String get moveSelection => 'Déplacer la sélection';

  @override
  String get pasteSelection => 'Coller la sélection';

  @override
  String get selectionToNewLayer => 'Sélection vers un nouveau calque';

  @override
  String get deleteSelection => 'Supprimer la sélection';

  @override
  String get changeCanvasSize => 'Modifier la taille du canevas';

  @override
  String get penDrawing => 'Dessin au crayon';

  @override
  String get stampDrawing => 'Dessin au tampon';

  @override
  String get erase => 'Effacer';

  @override
  String get fontDrawing => 'Dessin de texte';

  @override
  String get shapeDrawing => 'Dessin de forme';

  @override
  String get lineDrawing => 'Dessin de ligne';

  @override
  String get sprayCanDrawing => 'Dessin à l\'aérographe';

  @override
  String get changeColorSelection => 'Changer la couleur sélectionnée';

  @override
  String get deleteRamp => 'Supprimer la rampe';

  @override
  String get updateRamp => 'Mettre à jour la rampe';

  @override
  String get replacePalette => 'Remplacer la palette';

  @override
  String get addNewRamp => 'Ajouter une rampe';

  @override
  String get changeRampOrder => 'Modifier l\'ordre des rampes';

  @override
  String get changeFrameTime => 'Modifier la durée de la frame';

  @override
  String get changeLoopMarker => 'Modifier le marqueur de boucle';

  @override
  String get apply => 'Appliquer';

  @override
  String get chooseColor => 'Choisir une couleur';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';
}
