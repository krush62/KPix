// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get close => 'Cerrar';

  @override
  String get color => 'Color';

  @override
  String get createNewProject => 'Crear proyecto nuevo';

  @override
  String get width => 'Ancho';

  @override
  String get height => 'Alto';

  @override
  String get presets => 'Predefinidos';

  @override
  String get custom => 'Personalizado';

  @override
  String get lockAspectRatio => 'Bloquear proporción';

  @override
  String get exitApplication => 'Salir de la aplicación';

  @override
  String get openProjectManager => 'Abrir el gestor de proyectos';

  @override
  String get createProject => 'Crear proyecto';

  @override
  String get projectManager => 'Gestor de proyectos';

  @override
  String get filter => 'Filtro';

  @override
  String get sortFileNameAsc => 'Ordenar por nombre de archivo (ascendente)';

  @override
  String get sortFileNameDesc => 'Ordenar por nombre de archivo (descendente)';

  @override
  String get sortDateAsc => 'Ordenar por fecha de modificación (ascendente)';

  @override
  String get sortDateDesc => 'Ordenar por fecha de modificación (descendente)';

  @override
  String get importProject => 'Importar proyecto';

  @override
  String get deleteSelectedProject => 'Eliminar el proyecto seleccionado';

  @override
  String get loadSelectedProject => 'Cargar el proyecto seleccionado';

  @override
  String get unsavedChangesSaveFirst =>
      'Hay cambios sin guardar. ¿Quieres guardar primero?';

  @override
  String get openingImageDot => 'Abriendo imagen...';

  @override
  String get doYouReallyWantToDeleteProject =>
      '¿Seguro que quieres eliminar este proyecto?';

  @override
  String get projectImportSuccessful => '¡Proyecto importado correctamente!';

  @override
  String get couldNotOpenFile => '¡No se pudo abrir el archivo!';

  @override
  String get projectWithSameNameExists =>
      '¡Ya existe un proyecto con el mismo nombre!';

  @override
  String projectNameTaken({required String name}) {
    return 'Ya existe un proyecto llamado \"$name\". ¿Abrir ese proyecto o importar el archivo como copia?';
  }

  @override
  String get openExistingProject => 'Abrir el proyecto existente';

  @override
  String get importAsCopy => 'Importar como copia';

  @override
  String droppedImageQuestion({required String name}) {
    return '¿Añadir \"$name\" como capa de referencia o importarla como proyecto nuevo?';
  }

  @override
  String get addAsReferenceLayer => 'Añadir como capa de referencia';

  @override
  String get importAsNewProject => 'Importar como proyecto nuevo';

  @override
  String droppedFileNotSupported({required String formats}) {
    return '¡Solo se pueden abrir proyectos de KPix e imágenes ($formats)!';
  }

  @override
  String get pleaseSelectAKPixFile => '¡Selecciona un archivo KPix!';

  @override
  String get couldNotReadProjectDir =>
      '¡No se pudo leer la carpeta de proyectos!';

  @override
  String get noFilesFound => '¡No se encontraron archivos!';

  @override
  String get keyShift => 'Mayús';

  @override
  String get keyAlt => 'Alt';

  @override
  String get keyCtrl => 'Ctrl';

  @override
  String get keySpace => 'Espacio';

  @override
  String get buttonOff => 'SIN';

  @override
  String get buttonSolid => 'SÓL';

  @override
  String get buttonRelative => 'REL';

  @override
  String get buttonGlow => 'LUM';

  @override
  String get buttonShade => 'SOM';

  @override
  String get buttonBevel => 'BIS';

  @override
  String get outerStrokeOff => 'Sin contorno exterior';

  @override
  String get outerStrokeSolid => 'Contorno exterior sólido';

  @override
  String get outerStrokeRelative => 'Contorno exterior relativo al color';

  @override
  String get outerStrokeGlowing => 'Contorno exterior luminoso';

  @override
  String get outerStrokeShaded => 'Contorno exterior sombreado';

  @override
  String get innerStrokeOff => 'Sin contorno interior';

  @override
  String get innerStrokeSolid => 'Contorno interior sólido';

  @override
  String get innerStrokeBeveled => 'Contorno interior biselado';

  @override
  String get innerStrokeGlowing => 'Contorno interior luminoso';

  @override
  String get innerStrokeShaded => 'Contorno interior sombreado';

  @override
  String get shadowOff => 'Sin sombra paralela';

  @override
  String get shadowSolid => 'Sombra paralela sólida';

  @override
  String get shadowShaded => 'Sombra paralela por sombreado';

  @override
  String stepCount({required int count, required String value}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$value niveles',
      one: '$value nivel',
    );
    return '$_temp0';
  }

  @override
  String get recursive => 'recursivo';

  @override
  String get outerStroke => 'Contorno exterior';

  @override
  String get innerStroke => 'Contorno interior';

  @override
  String get dropShadow => 'Sombra paralela';

  @override
  String get selectOuterStrokeColor =>
      'Seleccionar el color del contorno exterior';

  @override
  String get darkenBrighten => 'Oscurecer/Aclarar';

  @override
  String get darkenBrightenBreak => 'Oscuro /\nClaro';

  @override
  String get applyOuterStroke => 'Aplicar contorno exterior';

  @override
  String get selectInnerStrokeColor =>
      'Seleccionar el color del contorno interior';

  @override
  String get applyInnerStroke => 'Aplicar contorno interior';

  @override
  String get horizontal => 'horizontal';

  @override
  String get vertical => 'vertical';

  @override
  String get selectDropShadowColor =>
      'Seleccionar el color de la sombra paralela';

  @override
  String get applyDropShadow => 'Aplicar sombra paralela';

  @override
  String get pixelsAbbrev => 'px';

  @override
  String get invalidLayerIndex => 'Posición de inserción de capa no válida.';

  @override
  String get couldNotAddMoreLayers => 'No se pueden añadir más capas.';

  @override
  String get layerAlreadyExistsOnFrame => 'La capa ya existe en ese fotograma.';

  @override
  String get cannotAddMoreFrames => 'No se pueden añadir más fotogramas.';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get noLayerBelow => '¡No hay ninguna capa debajo!';

  @override
  String get cannotMergeFromLinkedLayer =>
      '¡No se puede combinar desde una capa vinculada!';

  @override
  String get cannotMergeToLinkedLayer =>
      '¡No se puede combinar con una capa vinculada!';

  @override
  String get cannotMergeFromInvisibleLayer =>
      '¡No se puede combinar desde una capa oculta!';

  @override
  String get cannotMergeToInvisibleLayer =>
      '¡No se puede combinar con una capa oculta!';

  @override
  String get cannotMergeFromLockedLayer =>
      '¡No se puede combinar desde una capa bloqueada!';

  @override
  String get cannotMergeToLockedLayer =>
      '¡No se puede combinar con una capa bloqueada!';

  @override
  String get canOnlyMergeWithDrawingLayer =>
      '¡Solo se puede combinar con capas de dibujo!';

  @override
  String get cannotMergeWithActiveEffects =>
      '¡No se pueden combinar capas con efectos activos!';

  @override
  String get cannotDeleteLastLayer => '¡No se puede eliminar la última capa!';

  @override
  String get cannotDeleteFromHiddenLayer =>
      '¡No se puede eliminar en una capa oculta!';

  @override
  String get cannotDeleteFromLockedLayer =>
      '¡No se puede eliminar en una capa bloqueada!';

  @override
  String get cannotCutFromHiddenLayer =>
      '¡No se puede cortar de una capa oculta!';

  @override
  String get cannotCutFromLockedLayer =>
      '¡No se puede cortar de una capa bloqueada!';

  @override
  String get nothingToCopy => '¡No hay nada que copiar!';

  @override
  String get nothingToPasteColorsNotInPalette =>
      'No hay nada que pegar: ¡los colores copiados ya no están en la paleta!';

  @override
  String get cannotPasteToHiddenLayer =>
      '¡No se puede pegar en una capa oculta!';

  @override
  String get cannotPasteToLockedLayer =>
      '¡No se puede pegar en una capa bloqueada!';

  @override
  String get cannotTransformOnHiddenLayer =>
      '¡No se puede transformar en una capa oculta!';

  @override
  String get cannotTransformOnLockedLayer =>
      '¡No se puede transformar en una capa bloqueada!';

  @override
  String needAtLeastColorRamps({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Se necesitan al menos $count rampas de color!',
      one: '¡Se necesita al menos 1 rampa de color!',
    );
    return '$_temp0';
  }

  @override
  String notMoreThanColorRampsAllowed({required int count}) {
    return '¡No se permiten más de $count rampas de color!';
  }

  @override
  String get loadingPaletteFailed => '¡Error al cargar la paleta!';

  @override
  String undoStep({required String description}) {
    return 'Deshacer: $description';
  }

  @override
  String redoStep({required String description}) {
    return 'Rehacer: $description';
  }

  @override
  String get historyRestoreFailed => '¡Error al restaurar el historial!';

  @override
  String loadingFailed({required String status}) {
    return 'Error al cargar ($status)';
  }

  @override
  String fileSavedAt({required String path}) {
    return 'Archivo guardado en: $path';
  }

  @override
  String get imageImportSuccessful => '¡Imagen importada correctamente!';

  @override
  String get couldNotConvertImageData =>
      '¡No se pudieron convertir los datos de la imagen!';

  @override
  String get couldNotCrop => '¡No se pudo recortar!';

  @override
  String get cropToSelection => 'Recortar a la selección';

  @override
  String get hidden => 'Oculta';

  @override
  String get visible => 'Visible';

  @override
  String get unlocked => 'Desbloqueada';

  @override
  String get transparencyLocked => 'Transparencia bloqueada';

  @override
  String get locked => 'Bloqueada';

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
  String get buttonBrk => 'LAD';

  @override
  String get button1Point => '1 punto';

  @override
  String get button2Point => '2 puntos';

  @override
  String get button3Point => '3 puntos';

  @override
  String get rectangularGrid => 'Cuadrícula rectangular';

  @override
  String get diagonalGrid => 'Cuadrícula diagonal';

  @override
  String get isometricGrid => 'Cuadrícula isométrica';

  @override
  String get hexagonalGrid => 'Cuadrícula hexagonal';

  @override
  String get triangularGrid => 'Cuadrícula triangular';

  @override
  String get bricks => 'Ladrillos';

  @override
  String get onePointPerspective => 'Perspectiva de 1 punto';

  @override
  String get twoPointPerspective => 'Perspectiva de 2 puntos';

  @override
  String get threePointPerspective => 'Perspectiva de 3 puntos';

  @override
  String get ascendingSegmentOrder => 'Segmentos en orden ascendente';

  @override
  String get ascendingDescendingSegmentOrder =>
      'Segmentos en orden ascendente/descendente';

  @override
  String get descendingAscendingSegmentOrder =>
      'Segmentos en orden descendente/ascendente';

  @override
  String get descendingSegmentOrder => 'Segmentos en orden descendente';

  @override
  String get round => 'Redondo';

  @override
  String get square => 'Cuadrado';

  @override
  String get rectangle => 'Rectángulo';

  @override
  String get ellipse => 'Elipse';

  @override
  String get polygon => 'Polígono';

  @override
  String get wand => 'Varita mágica';

  @override
  String get triangle => 'Triángulo';

  @override
  String get midAngleRectangle => 'Rectángulo inclinado';

  @override
  String get regularPolygon => 'Polígono regular';

  @override
  String get star => 'Estrella';

  @override
  String get replaceSelection => 'Reemplazar la selección';

  @override
  String get addToSelection => 'Añadir a la selección';

  @override
  String get subtractFromSelection => 'Restar de la selección';

  @override
  String get intersectWithSelection => 'Intersecar con la selección';

  @override
  String get pencil => 'Lápiz';

  @override
  String get shape => 'Forma';

  @override
  String get fill => 'Relleno';

  @override
  String get select => 'Selección';

  @override
  String get colorPicker => 'Cuentagotas';

  @override
  String get eraser => 'Borrador';

  @override
  String get text => 'Texto';

  @override
  String get textToolDefaultText => 'Texto';

  @override
  String get sprayCan => 'Aerógrafo';

  @override
  String get line => 'Línea';

  @override
  String get stamp => 'Sello';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get cursorNone => 'Ninguno';

  @override
  String get cursorCrosshair => 'Cruz';

  @override
  String get cursorArrow => 'Flecha';

  @override
  String get rawModeExplanation =>
      'El modo bruto no usa ningún valor de las capas de sombreado ni de los ajustes de capa que usan sombreado.';

  @override
  String get rawMode => 'Modo bruto';

  @override
  String get size => 'Tamaño';

  @override
  String get fillAdjacent => 'Relleno contiguo';

  @override
  String get fillWholeRamp => 'Rellenar toda la rampa';

  @override
  String get integerAspectRatio => 'Proporción entera';

  @override
  String get segmentSorting => 'Orden de segmentos';

  @override
  String get smooth => 'Suavizado';

  @override
  String get mode => 'Modo';

  @override
  String get continuous => 'Contiguo';

  @override
  String get keep1to1 => 'Mantener 1:1';

  @override
  String get wholeRamp => 'Toda la rampa';

  @override
  String get strokeOnly => 'Solo contorno';

  @override
  String get cornerRadius => 'Radio de las esquinas';

  @override
  String get angle => 'Ángulo';

  @override
  String get cornerCount => 'Número de esquinas';

  @override
  String get radius => 'Radio';

  @override
  String get blobSize => 'Tamaño de gota';

  @override
  String get intensity => 'Intensidad';

  @override
  String get noStamp => 'Ningún sello';

  @override
  String get scale => 'Escala';

  @override
  String get gridAlign => 'Alinear a la cuadrícula';

  @override
  String get offsetX => 'Desplazamiento X';

  @override
  String get offsetY => 'Desplazamiento Y';

  @override
  String get font => 'Fuente';

  @override
  String get available => 'Disponible';

  @override
  String get invalidFileName => 'Nombre de archivo no válido';

  @override
  String get insufficientPermissions => 'Permisos insuficientes';

  @override
  String get overwritingExistingFile => 'Se sobrescribirá el archivo existente';

  @override
  String get rotateCanvas => 'Rotar el lienzo';

  @override
  String get flipCanvasHorizontally => 'Voltear el lienzo horizontalmente';

  @override
  String get flipCanvasVertically => 'Voltear el lienzo verticalmente';

  @override
  String get canvasSize => 'Tamaño del lienzo';

  @override
  String get offset => 'Desplazamiento';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get deselect => 'Deseleccionar';

  @override
  String get inverseSelection => 'Invertir la selección';

  @override
  String get copy => 'Copiar';

  @override
  String get copyMerged => 'Copiar combinado';

  @override
  String get cut => 'Cortar';

  @override
  String get paste => 'Pegar';

  @override
  String get pasteAsNewLayer => 'Pegar como capa nueva';

  @override
  String get horizontalFlip => 'Voltear horizontalmente';

  @override
  String get verticalFlip => 'Voltear verticalmente';

  @override
  String get rotate90Clockwise => 'Rotar 90° en sentido horario';

  @override
  String get alignDot => 'Alinear...';

  @override
  String get delete => 'Eliminar';

  @override
  String get selectAColor => 'Seleccionar un color';

  @override
  String get newVersionAvailable => 'Nueva versión disponible';

  @override
  String get downloadFromGithub => 'Descargar desde GitHub';

  @override
  String get aPixelArtCreationTool => 'Una herramienta para crear pixel art';

  @override
  String get thisIsFreeSoftwareLicensed =>
      'Este es software libre bajo la licencia';

  @override
  String get gnuAGPLv3 => 'GNU AGPLv3';

  @override
  String get credits => 'Créditos';

  @override
  String get licenses => 'Licencias';

  @override
  String get controlsShortcuts => 'Controles/Atajos';

  @override
  String get textToolContent => 'Contenido de la herramienta Texto';

  @override
  String get gui => 'Interfaz';

  @override
  String get behavior => 'Comportamiento';

  @override
  String get controlsPC => 'Controles PC';

  @override
  String get controlsStylus => 'Controles lápiz óptico';

  @override
  String get controlsTouch => 'Controles táctiles';

  @override
  String get image => 'Imagen';

  @override
  String get animation => 'Animación';

  @override
  String get palette => 'Paleta';

  @override
  String get kpixProject => 'Proyecto KPix';

  @override
  String get export => 'Exportar';

  @override
  String get format => 'Formato';

  @override
  String get texturePack => 'Pack de texturas';

  @override
  String get texturePackAnimation => 'Pack de texturas animado';

  @override
  String get pngSequence => 'Secuencia PNG';

  @override
  String get scaling => 'Escalado';

  @override
  String get selectionOnly => 'Solo la selección';

  @override
  String nFrames({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotogramas',
      one: '1 fotograma',
      zero: '0 fotogramas',
    );
    return '$_temp0';
  }

  @override
  String frameNumber({required int number}) {
    return 'Fotograma $number';
  }

  @override
  String get directory => 'Carpeta';

  @override
  String get changeDirectory => 'Cambiar de carpeta';

  @override
  String get fileName => 'Nombre del archivo';

  @override
  String get exportFile => 'Exportar archivo';

  @override
  String imageDimensionsExceed({required int width, required int height}) {
    return '¡Las dimensiones de la imagen no pueden superar $width × $height!';
  }

  @override
  String get couldNotDecodeImage => '¡No se pudo decodificar la imagen!';

  @override
  String get couldNotLoadFile => '¡No se pudo cargar el archivo!';

  @override
  String get importImage => 'Importar imagen';

  @override
  String get file => 'Archivo';

  @override
  String get noFileSelected => 'Ningún archivo seleccionado';

  @override
  String get chooseImage => 'Elegir imagen';

  @override
  String get scaleDown => 'Reducir';

  @override
  String get createNewPaletteFromImage =>
      'Crear una paleta nueva a partir de la imagen';

  @override
  String get maxColorRamps => 'Máx. rampas de color';

  @override
  String get maxColorsPerRamp => 'Máx. colores por rampa';

  @override
  String get includeImageAsReferenceLayer =>
      'Incluir la imagen como capa de referencia';

  @override
  String get import => 'Importar';

  @override
  String get saveProjectAs => 'Guardar proyecto como';

  @override
  String get hueAbb => 'mat';

  @override
  String get satAbb => 'sat';

  @override
  String get valAbb => 'val';

  @override
  String get pressToReset => 'Pulsar para restablecer';

  @override
  String get colorCount => 'Número de colores';

  @override
  String get baseHue => 'Matiz base';

  @override
  String get hueShift => 'Cambio de matiz';

  @override
  String get exponent => 'Exponente';

  @override
  String get baseSat => 'Saturación base';

  @override
  String get satShift => 'Cambio de saturación';

  @override
  String get satCurve => 'Curva de saturación';

  @override
  String get satCurveNoFlat =>
      'Saturación reducida para valores oscuros y claros';

  @override
  String get satCurveDarkFlat => 'Saturación reducida para valores claros';

  @override
  String get satCurveBrightFlat => 'Saturación reducida para valores oscuros';

  @override
  String get satCurveLinear => 'Progresión lineal de la saturación';

  @override
  String get valueRange => 'Rango de valor';

  @override
  String deleteColorRampQuestion({required int amount}) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'Se eliminarán $amount píxeles',
      one: 'Se eliminará 1 píxel',
    );
    return '¿Seguro que quieres eliminar esta rampa de color?\n$_temp0';
  }

  @override
  String ofThemInSelection({required int amount}) {
    return '($amount de ellos en la selección)';
  }

  @override
  String pixelsInClipboard({required int amount}) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount píxeles del portapapeles ya no se pegarán',
      one: '1 píxel del portapapeles ya no se pegará',
    );
    return '$_temp0';
  }

  @override
  String get shadingRange => 'Rango de sombreado';

  @override
  String get maxDarken => 'Oscurecer máx.';

  @override
  String get maxBrighten => 'Aclarar máx.';

  @override
  String get layerActionsDot => 'Acciones de capa...';

  @override
  String get settings => 'Ajustes';

  @override
  String get addNewLayerDot => 'Añadir capa...';

  @override
  String get layerSettings => 'Ajustes de capa';

  @override
  String get symmetryOptions => 'Opciones de simetría';

  @override
  String get centerHorizontalRuler => 'Centrar el eje horizontal';

  @override
  String get centerVerticalRuler => 'Centrar el eje vertical';

  @override
  String get addNewDrawingLayer => 'Añadir capa de dibujo';

  @override
  String get addNewShadingLayer => 'Añadir capa de sombreado';

  @override
  String get addNewDitherLayer => 'Añadir capa de tramado';

  @override
  String get addNewReferenceLayer => 'Añadir capa de referencia';

  @override
  String get addNewGridLayer => 'Añadir capa de cuadrícula';

  @override
  String get deleteLayer => 'Eliminar capa';

  @override
  String get duplicateLayer => 'Duplicar capa';

  @override
  String get mergeDownLayer => 'Combinar con la capa inferior';

  @override
  String get unlinkLayer => 'Desvincular capa / Hacer única';

  @override
  String get newProject => 'Proyecto nuevo';

  @override
  String get openProject => 'Abrir proyecto';

  @override
  String get rasterLayer => 'Rasterizar capa';

  @override
  String get saveProject => 'Guardar proyecto';

  @override
  String get exportProjectPalette => 'Exportar proyecto/paleta';

  @override
  String get exportShaderImage => 'Exportar imagen con shader [BETA]';

  @override
  String get shaderLcd => 'LCD';

  @override
  String get shaderSmoothEdges => 'Suavizado';

  @override
  String get shaderDithering => 'Tramado';

  @override
  String get shaderEffects => 'Efectos';

  @override
  String get colorTolerance => 'Tolerancia de color';

  @override
  String get smoothness => 'Suavidad';

  @override
  String get antiAliasing => 'Antialiasing';

  @override
  String get lineWidth => 'Grosor de línea';

  @override
  String get similarityThreshold => 'Umbral de similitud';

  @override
  String get gridWidth => 'Grosor de la cuadrícula';

  @override
  String get gridColor => 'Color de la cuadrícula';

  @override
  String get softness => 'Difuminado';

  @override
  String get subpixels => 'Subpíxeles RGB';

  @override
  String get gridOnTransparency => 'Cuadrícula sobre transparencia';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get zoomToFit => 'Ajustar a la vista';

  @override
  String get colorDepth => 'Profundidad de color';

  @override
  String get tuneDithering => 'Ajustar tramado';

  @override
  String get bayerLevel => 'Nivel Bayer';

  @override
  String get influence => 'Influencia';

  @override
  String get strength => 'Fuerza';

  @override
  String get rounding => 'Redondeo';

  @override
  String get fullRange => 'Rango completo';

  @override
  String get dotSize => 'Tamaño de punto';

  @override
  String get originalMix => 'Mezcla con el original';

  @override
  String get dotGain => 'Ganancia de punto';

  @override
  String get dotShape => 'Forma de punto';

  @override
  String get diamond => 'Rombo';

  @override
  String get misregistration => 'Error de registro';

  @override
  String get backgroundBrightness => 'Brillo del fondo';

  @override
  String get backgroundWarmth => 'Calidez del fondo';

  @override
  String get outerRadius => 'Radio exterior';

  @override
  String get innerRadius => 'Radio interior';

  @override
  String get sharpness => 'Nitidez';

  @override
  String get lightAngle => 'Ángulo de la luz';

  @override
  String get depth => 'Profundidad';

  @override
  String get bevelWidth => 'Ancho del bisel';

  @override
  String get heightFromBrightness => 'Altura según el brillo';

  @override
  String get shaderCrt => 'CRT';

  @override
  String get medium => 'Soporte';

  @override
  String get signal => 'Señal';

  @override
  String get colorEncoding => 'Codificación de color';

  @override
  String get tv => 'Televisor';

  @override
  String get wear => 'Desgaste';

  @override
  String get artifacts => 'Artefactos';

  @override
  String get noise => 'Ruido';

  @override
  String get ghosting => 'Imágenes fantasma';

  @override
  String get encoding => 'Codificación';

  @override
  String get phaseError => 'Error de fase';

  @override
  String get convergence => 'Convergencia';

  @override
  String get scanlines => 'Líneas de barrido';

  @override
  String get mask => 'Máscara';

  @override
  String get maskStrength => 'Intensidad de la máscara';

  @override
  String get bloom => 'Resplandor';

  @override
  String get curvature => 'Curvatura';

  @override
  String get vignette => 'Viñeta';

  @override
  String get none => 'Ninguno';

  @override
  String get apertureGrille => 'Rejilla';

  @override
  String get slotMask => 'Ranuras';

  @override
  String get shadowMask => 'Sombra';

  @override
  String get checkerboard => 'Damero';

  @override
  String get panel => 'Panel';

  @override
  String get panelColors => 'Colores del panel';

  @override
  String get blackLevel => 'Nivel de negro';

  @override
  String get unevenBacklight => 'Retroiluminación irregular';

  @override
  String get glow => 'Halo';

  @override
  String get glowRadius => 'Radio del halo';

  @override
  String get pixelShadow => 'Sombra de los píxeles';

  @override
  String get shadowDistance => 'Distancia de la sombra';

  @override
  String get outlineWidth => 'Grosor del contorno';

  @override
  String get outlineStrength => 'Intensidad del contorno';

  @override
  String get intensityLevels => 'Niveles de intensidad';

  @override
  String get intensityMode => 'Modo de intensidad';

  @override
  String shaderMinScaling({required int factor}) {
    return 'El escalado debe ser de al menos $factor:1 para este shader.';
  }

  @override
  String get centerHorizontally => 'Centrar horizontalmente';

  @override
  String get centerVertically => 'Centrar verticalmente';

  @override
  String get left => 'Izquierda';

  @override
  String get right => 'Derecha';

  @override
  String get top => 'Arriba';

  @override
  String get bottom => 'Abajo';

  @override
  String get editColorRamp => 'Editar rampa de color';

  @override
  String nColors({required int amount}) {
    return '$amount colores';
  }

  @override
  String nRampsColors({required int rampAmount, required int colorAmount}) {
    return '$rampAmount rampas | $colorAmount colores';
  }

  @override
  String get remapExistingColors =>
      '¿Quieres reasignar los colores existentes (de lo contrario, se eliminarán todos los píxeles)?';

  @override
  String get wantToDeletePalette => '¿Seguro que quieres eliminar esta paleta?';

  @override
  String get paletteManager => 'Gestor de paletas';

  @override
  String get importPalette => 'Importar paleta';

  @override
  String get saveCurrentPalette => 'Guardar la paleta actual';

  @override
  String get deleteSelectedPalette => 'Eliminar la paleta seleccionada';

  @override
  String get appendToCurrentPalette => 'Añadir a la paleta actual';

  @override
  String get applySelectedPalette => 'Aplicar la paleta seleccionada';

  @override
  String get addNewColorRamp => 'Añadir rampa de color';

  @override
  String get paletteAdjustments => 'Ajustes de la paleta';

  @override
  String get adjustPalette => 'Ajustar paleta';

  @override
  String get whiteBalance => 'Balance de blancos';

  @override
  String get tint => 'Tinte';

  @override
  String get hueSpread => 'Dispersión de matiz';

  @override
  String get includeRampInAdjustment => 'Incluir la rampa en el ajuste';

  @override
  String get resetAllAdjustments => 'Restablecer todos los ajustes';

  @override
  String get resetValue => 'Restablecer valor';

  @override
  String get holdToShowOriginal => 'Mantener pulsado para ver el original';

  @override
  String get valueClipping => 'Recorte de valor';

  @override
  String get saturationClipping => 'Recorte de saturación';

  @override
  String get savePalette => 'Guardar paleta';

  @override
  String get defaultPalette => 'Predeterminada';

  @override
  String get errorSavingPalette => '¡Error al guardar la paleta!';

  @override
  String get errorSavingProject =>
      '¡Error al guardar el proyecto! Los cambios no se han guardado.';

  @override
  String paletteSavedAt({required String path}) {
    return 'Paleta guardada correctamente en $path.';
  }

  @override
  String get paletteWithSameNameExists =>
      '¡Ya existe una paleta con el mismo nombre!';

  @override
  String get pleaseSelectAKPalFile => '¡Selecciona un archivo KPal!';

  @override
  String get paletteImportSuccessful => '¡Importación correcta!';

  @override
  String get paletteImportFailed => '¡Error en la importación!';

  @override
  String get insufficientPermissionsForDir =>
      '¡Permisos insuficientes para la carpeta seleccionada!';

  @override
  String get undoSteps => 'Pasos para deshacer';

  @override
  String get selectInsertedLayers => 'Seleccionar las capas insertadas';

  @override
  String get activateSelectionToolAfterPaste =>
      'Activar la herramienta de selección después de pegar';

  @override
  String get defaultShadingLayerSettings =>
      'Ajustes predeterminados de las capas de sombreado';

  @override
  String get defaultFrameTime => 'Duración predeterminada del fotograma';

  @override
  String get showReferenceLayersOutsideOfCanvas =>
      'Mostrar las capas de referencia fuera del lienzo';

  @override
  String get projectDirectory => 'Carpeta de proyectos';

  @override
  String get defaultDir => 'Predeterminada';

  @override
  String get customDir => 'Personalizada';

  @override
  String get chooseDirectory => 'Elegir carpeta';

  @override
  String get mouseCursor => 'Cursor del ratón';

  @override
  String get languagePreferences => 'Preferencias de idioma';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get themePreferences => 'Preferencias de tema';

  @override
  String get theme => 'Tema';

  @override
  String get checkerboardPreferences => 'Preferencias del damero';

  @override
  String get checkerboardSize => 'Tamaño del damero';

  @override
  String get checkerboardContrast => 'Contraste del damero';

  @override
  String get palettePreferences => 'Preferencias de paleta';

  @override
  String get colorNaming => 'Nombres de colores';

  @override
  String get borderPreferences => 'Preferencias de bordes';

  @override
  String get toolOutlineOpacity => 'Opacidad del contorno de la herramienta';

  @override
  String get selectionOutlineOpacity => 'Opacidad del contorno de selección';

  @override
  String get pulsatingSelectionOutline => 'Contorno de selección pulsante';

  @override
  String get canvasBorerOpacity => 'Opacidad del borde del lienzo';

  @override
  String get toolInfoPreferences =>
      'Preferencias de información de herramienta';

  @override
  String get showMeasurementsAtCursor => 'Mostrar medidas junto al cursor';

  @override
  String get measurementInfoIsOnTheRight => 'Medidas a la derecha del cursor';

  @override
  String get timeThatNeedsToBeHeldDown =>
      'Tiempo que hay que mantener pulsado para una pulsación larga.';

  @override
  String get longPressDelay => 'Retardo de pulsación larga';

  @override
  String get distanceThatMustBeMoved =>
      'Distancia que hay que mover con el botón pulsado antes de desplazar, hacer zoom o cambiar el tamaño de la herramienta. Los movimientos más cortos siguen contando como un toque.';

  @override
  String get longPressCancelDistance =>
      'Distancia de cancelación de pulsación larga';

  @override
  String get distanceThatNeedsToBeMovedVertically =>
      'Distancia vertical que hay que mover para acercar o alejar.';

  @override
  String get zoomStepDistance => 'Distancia por paso de zoom';

  @override
  String get distanceThatNeedsToBeMovedHorizontally =>
      'Distancia horizontal que hay que mover para cambiar el tamaño de la herramienta actual.';

  @override
  String get toolSizeStepDistance =>
      'Distancia por paso de tamaño de herramienta';

  @override
  String get timeoutForPickingAColor => 'Tiempo límite para tomar un color.';

  @override
  String get colorPickTimeout => 'Tiempo límite del cuentagotas';

  @override
  String get touchDelay => 'Retardo táctil';

  @override
  String get showNavigationJoysticks => 'Joysticks de navegación';

  @override
  String get stampManager => 'Gestor de sellos';

  @override
  String get deleteSelectedStamp => 'Eliminar el sello seleccionado';

  @override
  String get loadSelectedStamp => 'Cargar el sello seleccionado';

  @override
  String get doYouReallyWantToDeleteStamp =>
      '¿Seguro que quieres eliminar este sello?';

  @override
  String get frameBlending => 'Papel cebolla';

  @override
  String get enabled => 'Activado';

  @override
  String get framesBefore => 'Fotogramas anteriores';

  @override
  String get wrapAround => 'Cíclico';

  @override
  String get framesAfter => 'Fotogramas posteriores';

  @override
  String get opacity => 'Opacidad';

  @override
  String get gradual => 'Gradual';

  @override
  String get tinting => 'Tintado';

  @override
  String get activeLayerOnly => 'Solo la capa activa';

  @override
  String get cancel => 'Cancelar';

  @override
  String get applyToAllFrames => 'Aplicar a todos los fotogramas';

  @override
  String get applyToCurrentFrame => 'Aplicar al fotograma actual';

  @override
  String get collapseTimeline => 'Contraer la línea de tiempo';

  @override
  String get expandTimeline => 'Expandir la línea de tiempo';

  @override
  String get pause => 'Pausa';

  @override
  String get play => 'Reproducir';

  @override
  String get loopStartMarker => 'Marcador de inicio del bucle';

  @override
  String get loopEndMarker => 'Marcador de fin del bucle';

  @override
  String get changeDuration => 'Cambiar duración';

  @override
  String get moveFrameLeft => 'Mover fotograma a la izquierda';

  @override
  String get moveFrame => 'Mover fotograma';

  @override
  String get moveFrameRight => 'Mover fotograma a la derecha';

  @override
  String get addFrameLeft => 'Añadir fotograma a la izquierda';

  @override
  String get addFrame => 'Añadir fotograma';

  @override
  String get addFrameRight => 'Añadir fotograma a la derecha';

  @override
  String get copyFrameLeft => 'Copiar fotograma a la izquierda';

  @override
  String get copyFrame => 'Copiar fotograma';

  @override
  String get copyFrameRight => 'Copiar fotograma a la derecha';

  @override
  String get createLinkedFrameLeft =>
      'Crear fotograma vinculado a la izquierda';

  @override
  String get createLinkedFrame => 'Crear fotograma vinculado';

  @override
  String get createLinkedFrameRight => 'Crear fotograma vinculado a la derecha';

  @override
  String get deleteFrame => 'Eliminar fotograma';

  @override
  String get toggle => 'Activar/desactivar';

  @override
  String get grid => 'Cuadrícula';

  @override
  String get gridButton => 'CUADRÍCULA';

  @override
  String get perspective => 'Perspectiva';

  @override
  String get perspectiveButton => 'PERSPECTIVA';

  @override
  String get brightness => 'Brillo';

  @override
  String get interval => 'Intervalo';

  @override
  String get intervalX => 'Intervalo X';

  @override
  String get intervalY => 'Intervalo Y';

  @override
  String get horizon => 'Horizonte';

  @override
  String get vanishingPoint => 'Punto de fuga';

  @override
  String get horPoints => 'Puntos hor.';

  @override
  String get verPoint => 'Punto vert.';

  @override
  String couldNotLoadImageFrom({required String location}) {
    return 'No se pudo cargar la imagen desde $location.';
  }

  @override
  String resetSetting({required String setting}) {
    return 'Restablecer: $setting';
  }

  @override
  String get noFileLoaded => 'Ningún archivo cargado';

  @override
  String get openReferenceImage => 'Abrir imagen de referencia';

  @override
  String get aspectRatio => 'Proporción';

  @override
  String get zoom => 'Zoom';

  @override
  String get expandHorizontallyAndCenter =>
      'Expandir horizontalmente y centrar manteniendo la proporción actual';

  @override
  String get expandVerticallyAndCenter =>
      'Expandir verticalmente y centrar manteniendo la proporción actual';

  @override
  String get fitsImageIntoCanvas =>
      'Ajusta la imagen al lienzo (cambia la proporción)';

  @override
  String get contrast => 'Contraste';

  @override
  String get saturation => 'Saturación';

  @override
  String get warmth => 'Calidez';

  @override
  String get shading => 'Sombreado';

  @override
  String get currentRampOnly => 'Solo la rampa actual';

  @override
  String get direction => 'Dirección';

  @override
  String get loadingDot => 'Cargando...';

  @override
  String get thisDeviceDoesNotSupportResolution =>
      'Este dispositivo no admite la resolución lógica mínima necesaria para ejecutar esta aplicación.';

  @override
  String get customProjectDirectoryInvalid =>
      'La carpeta de proyectos personalizada no es válida. Se usará la carpeta predeterminada.';

  @override
  String get couldNotCreateInternalDirectories =>
      'No se pudieron crear las carpetas internas.';

  @override
  String get couldNotInitializeApp => 'No se pudo inicializar la aplicación.';

  @override
  String get aCustomProjectDirectoryIsUsed =>
      'Se está usando una carpeta de proyectos personalizada, pero KPix no tiene el permiso \"Acceso a todos los archivos\". Es posible que no se muestren los archivos de proyecto creados por otras aplicaciones (p. ej., herramientas de sincronización).\n¿Quieres abrir los ajustes del sistema para conceder el permiso?';

  @override
  String get workRecovered => 'Trabajo recuperado';

  @override
  String get undo => 'Deshacer';

  @override
  String get redo => 'Rehacer';

  @override
  String get about => 'Acerca de';

  @override
  String get preferences => 'Preferencias';

  @override
  String get saveDot => 'Guardar...';

  @override
  String get newOpenDot => 'Nuevo/Abrir...';

  @override
  String get errorImportingImage => 'Error al importar la imagen.';

  @override
  String get thereAreUnsavedChanges =>
      'Hay cambios sin guardar. ¿Quieres guardar primero?';

  @override
  String get importingImageDot => 'Importando imagen...';

  @override
  String get exportingDot => 'Exportando...';

  @override
  String get movingProjectFilesDot => 'Moviendo archivos de proyecto...';

  @override
  String get targetDirCouldNotBeCreated =>
      '¡La carpeta no existe y no se pudo crear!';

  @override
  String dirAlreadyContainsFile({required String fileName}) {
    return '¡La carpeta ya contiene un archivo llamado $fileName!';
  }

  @override
  String couldNotMoveFile({required String fileName}) {
    return '¡No se pudo mover el archivo $fileName!';
  }

  @override
  String get unexpectedErrorMovingProjectFiles =>
      '¡Se produjo un error inesperado al mover los archivos de proyecto!';

  @override
  String changedProjectDirectoryFiles({
    required String directory,
    required int count,
  }) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos de proyecto movidos',
      one: '1 archivo de proyecto movido',
    );
    return 'La carpeta de proyectos ahora es $directory ($_temp0).';
  }

  @override
  String projectDirWasNotChanged({required String message}) {
    return '¡La carpeta de proyectos no se ha cambiado!\n$message';
  }

  @override
  String exportedPaletteTo({required String path}) {
    return 'Paleta exportada a: $path';
  }

  @override
  String get errorExportingPaletteFile =>
      'Error al exportar el archivo de paleta.';

  @override
  String exportedTo({required String path}) {
    return 'Exportado a: $path';
  }

  @override
  String get errorExportingFile => '¡Error al exportar el archivo!';

  @override
  String get withoutAllFilesWarning =>
      'Sin el permiso \"Acceso a todos los archivos\", KPix no puede ver los archivos de proyecto creados en esta carpeta por otras aplicaciones (p. ej., herramientas de sincronización).\n¿Quieres abrir los ajustes del sistema para conceder el permiso?';

  @override
  String get allFilesAccessNotNeededWarning =>
      'El permiso \"Acceso a todos los archivos\" no es necesario para la carpeta de proyectos predeterminada.\n¿Quieres abrir los ajustes del sistema para revocar el permiso?';

  @override
  String get initial => 'Estado inicial';

  @override
  String get generic => 'Genérico';

  @override
  String get saveData => 'Guardar datos';

  @override
  String get loadData => 'Cargar datos';

  @override
  String get selectLayer => 'Seleccionar capa';

  @override
  String get selectLayerMoveSelection => 'Seleccionar capa (mover selección)';

  @override
  String get mergeLayer => 'Combinar capa';

  @override
  String get changeLayerOrder => 'Cambiar el orden de las capas';

  @override
  String get layerVisibilityChanged => 'Cambiar la visibilidad de la capa';

  @override
  String get layerLockStateChanged => 'Cambiar el bloqueo de la capa';

  @override
  String get changeReferenceImage => 'Cambiar la imagen de referencia';

  @override
  String get layerSettingsChange => 'Cambiar los ajustes de la capa';

  @override
  String get layerSettingsRaster => 'Aplicar efecto de capa';

  @override
  String get newSelection => 'Nueva selección';

  @override
  String get cutSelection => 'Cortar selección';

  @override
  String get flipSelectionHorizontally =>
      'Voltear la selección horizontalmente';

  @override
  String get flipSelectionVertically => 'Voltear la selección verticalmente';

  @override
  String get rotateSelection => 'Rotar selección';

  @override
  String get moveSelection => 'Mover selección';

  @override
  String get pasteSelection => 'Pegar selección';

  @override
  String get selectionToNewLayer => 'Selección a capa nueva';

  @override
  String get deleteSelection => 'Eliminar selección';

  @override
  String get changeCanvasSize => 'Cambiar el tamaño del lienzo';

  @override
  String get penDrawing => 'Dibujo con lápiz';

  @override
  String get stampDrawing => 'Dibujo con sello';

  @override
  String get erase => 'Borrar';

  @override
  String get fontDrawing => 'Dibujo de texto';

  @override
  String get shapeDrawing => 'Dibujo de forma';

  @override
  String get lineDrawing => 'Dibujo de línea';

  @override
  String get sprayCanDrawing => 'Dibujo con aerógrafo';

  @override
  String get changeColorSelection => 'Cambiar el color seleccionado';

  @override
  String get deleteRamp => 'Eliminar rampa';

  @override
  String get updateRamp => 'Actualizar rampa';

  @override
  String get replacePalette => 'Reemplazar paleta';

  @override
  String get addNewRamp => 'Añadir rampa';

  @override
  String get changeRampOrder => 'Cambiar el orden de las rampas';

  @override
  String get changeFrameTime => 'Cambiar la duración del fotograma';

  @override
  String get changeLoopMarker => 'Cambiar el marcador de bucle';

  @override
  String get apply => 'Aplicar';

  @override
  String get chooseColor => 'Elegir color';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';
}
