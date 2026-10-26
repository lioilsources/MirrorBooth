// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get filterNone => 'Ninguno';

  @override
  String get filterGlow => 'Brillo';

  @override
  String get filterSlim => 'Delgado';

  @override
  String get filterDoll => 'Muñeca';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Labios';

  @override
  String get filterBigNose => 'Nariz';

  @override
  String get filterAlien => 'Marciano';

  @override
  String get filterMelt => 'Derretir';

  @override
  String get filterBigEars => 'Orejas';

  @override
  String get filterLongNeck => 'Cuello';

  @override
  String get filterPencil => 'Lápiz';

  @override
  String get filterComic => 'Cómic';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neón';

  @override
  String get filterThermal => 'Calor';

  @override
  String get filterOil => 'Óleo';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampiro';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Fantasma';

  @override
  String get filterDemon => 'Demonio';

  @override
  String get filterCyborg => 'Cíborg';

  @override
  String get filterFrozen => 'Escarcha';

  @override
  String get collectionPretty => 'Bonito';

  @override
  String get collectionUgly => 'Feo';

  @override
  String get collectionArt => 'Arte';

  @override
  String get collectionFantasy => 'Fantasía';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8 bits';

  @override
  String get audioEffectSlowMo => 'Lento';

  @override
  String get audioEffectChipmunk => 'Ardilla';

  @override
  String get audioEffectEcho => 'Eco';

  @override
  String get audioEffectUnderwater => 'Bajo el agua';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Al revés';

  @override
  String get mirrorSideLeftShort => 'I';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Izquierda';

  @override
  String get mirrorSideRight => 'Derecha';

  @override
  String get lensFront => 'FRONTAL';

  @override
  String get lensBack => 'TRASERA';

  @override
  String get photoSaveFailedTitle => 'No se pudo guardar la foto';

  @override
  String get ok => 'Aceptar';

  @override
  String get galleryAccessDenied => 'Se denegó el acceso a la fototeca.';

  @override
  String get galleryNotEnoughSpace =>
      'No hay suficiente espacio de almacenamiento.';

  @override
  String get galleryUnsupportedFormat =>
      'Este formato de archivo no es compatible.';

  @override
  String get genericError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String shaderLoadError(String error) {
    return 'No se pudieron cargar los filtros: $error';
  }

  @override
  String get cameraPermissionDenied => 'Permiso de cámara denegado';

  @override
  String get noCamerasAvailable => 'No hay cámaras disponibles';

  @override
  String get cameraStartFailed => 'No se pudo iniciar la cámara.';

  @override
  String get controlsHint => 'arrastrar = girar  •  ⊙ = foto  •  ● = video';

  @override
  String get controlsHintVolume =>
      'volumen = foto  •  mantener volumen = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Colección $collection desbloqueada ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtros: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'La vista previa es gratis. Desbloquea para guardar fotos y videos.';

  @override
  String get storeUnavailable => 'Tienda no disponible';

  @override
  String get loadingPrice => 'Cargando precio…';

  @override
  String unlockFor(String price) {
    return 'Desbloquear por $price';
  }

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchaseFailed => 'Error en la compra';

  @override
  String get discardVideoTitle => '¿Descartar el video?';

  @override
  String get discardVideoBody =>
      'Esta grabación no se ha guardado en tu galería.';

  @override
  String get keep => 'Conservar';

  @override
  String get discard => 'Descartar';

  @override
  String get processing => 'Procesando…';

  @override
  String get applyingEffect => 'Aplicando efecto…';

  @override
  String get saved => 'Guardado ✓';

  @override
  String get saveToCameraRoll => 'Guardar en la galería';

  @override
  String get micPermissionRequired =>
      'Se necesita permiso del micrófono para grabar video.';

  @override
  String get recordingTooShort =>
      'Grabación demasiado corta: graba más tiempo.';

  @override
  String get videoAssemblyFailed =>
      'No se pudo crear el video. Inténtalo de nuevo.';

  @override
  String get audioEffectFailed => 'No se pudo aplicar el efecto de audio.';

  @override
  String get roomEntryPrompt =>
      'Introduce un ID de sala para iniciar una videollamada en espejo.';

  @override
  String get roomIdHint => 'ID de sala';

  @override
  String get mirrorSideTitle => 'Lado del espejo';

  @override
  String get joinCall => 'Unirse a la llamada';

  @override
  String failedToJoin(String error) {
    return 'No se pudo unir: $error';
  }

  @override
  String get connecting => 'Conectando…';
}
