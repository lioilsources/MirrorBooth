// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get filterNone => 'Cap';

  @override
  String get filterGlow => 'Brillantor';

  @override
  String get filterSlim => 'Esvelt';

  @override
  String get filterDoll => 'Nina';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Llavis';

  @override
  String get filterBigNose => 'Nas';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Fos';

  @override
  String get filterBigEars => 'Orelles';

  @override
  String get filterLongNeck => 'Coll';

  @override
  String get filterPencil => 'Llapis';

  @override
  String get filterComic => 'Còmic';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neó';

  @override
  String get filterThermal => 'Calor';

  @override
  String get filterOil => 'Oli';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampir';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Fantasma';

  @override
  String get filterDemon => 'Dimoni';

  @override
  String get filterCyborg => 'Cíborg';

  @override
  String get filterFrozen => 'Gebre';

  @override
  String get collectionPretty => 'Bonic';

  @override
  String get collectionUgly => 'Lleig';

  @override
  String get collectionArt => 'Art';

  @override
  String get collectionFantasy => 'Fantasia';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8 bits';

  @override
  String get audioEffectSlowMo => 'Lent';

  @override
  String get audioEffectChipmunk => 'Esquirol';

  @override
  String get audioEffectEcho => 'Eco';

  @override
  String get audioEffectUnderwater => 'Sota l\'aigua';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Al revés';

  @override
  String get mirrorSideLeftShort => 'E';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Esquerra';

  @override
  String get mirrorSideRight => 'Dreta';

  @override
  String get lensFront => 'DAVANT';

  @override
  String get lensBack => 'DARRERE';

  @override
  String get photoSaveFailedTitle => 'No s\'ha pogut desar la foto';

  @override
  String get ok => 'D\'acord';

  @override
  String get galleryAccessDenied => 'S\'ha denegat l\'accés a la fototeca.';

  @override
  String get galleryNotEnoughSpace => 'No hi ha prou espai d\'emmagatzematge.';

  @override
  String get galleryUnsupportedFormat =>
      'Aquest format de fitxer no és compatible.';

  @override
  String get genericError => 'Alguna cosa ha fallat. Torna-ho a provar.';

  @override
  String shaderLoadError(String error) {
    return 'No s\'han pogut carregar els filtres: $error';
  }

  @override
  String get cameraPermissionDenied => 'S\'ha denegat l\'accés a la càmera';

  @override
  String get noCamerasAvailable => 'No hi ha cap càmera disponible';

  @override
  String get cameraStartFailed => 'No s\'ha pogut iniciar la càmera.';

  @override
  String get controlsHint => 'arrossega = gira  •  ⊙ = foto  •  ● = vídeo';

  @override
  String get controlsHintVolume => 'volum = foto  •  mantén el volum = vídeo';

  @override
  String collectionUnlocked(String collection) {
    return 'Col·lecció $collection desbloquejada ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtres $collection';
  }

  @override
  String get paywallPreviewFree =>
      'La previsualització és gratuïta. Desbloqueja per desar fotos i vídeos.';

  @override
  String get storeUnavailable => 'Botiga no disponible';

  @override
  String get loadingPrice => 'Carregant el preu…';

  @override
  String unlockFor(String price) {
    return 'Desbloqueja per $price';
  }

  @override
  String get restorePurchases => 'Restaura les compres';

  @override
  String get purchaseFailed => 'La compra ha fallat';

  @override
  String get discardVideoTitle => 'Vols descartar el vídeo?';

  @override
  String get discardVideoBody => 'Aquesta gravació no s\'ha desat al carret.';

  @override
  String get keep => 'Conserva';

  @override
  String get discard => 'Descarta';

  @override
  String get processing => 'Processant…';

  @override
  String get applyingEffect => 'Aplicant l\'efecte…';

  @override
  String get saved => 'Desat ✓';

  @override
  String get saveToCameraRoll => 'Desa al carret';

  @override
  String get micPermissionRequired => 'Cal accés al micròfon per gravar vídeo.';

  @override
  String get recordingTooShort =>
      'Gravació massa curta — mantén premut més estona.';

  @override
  String get videoAssemblyFailed =>
      'No s\'ha pogut muntar el vídeo. Torna-ho a provar.';

  @override
  String get audioEffectFailed => 'L\'efecte d\'àudio ha fallat.';

  @override
  String get roomEntryPrompt =>
      'Introdueix un ID de sala per començar una videotrucada amb mirall.';

  @override
  String get roomIdHint => 'ID de sala';

  @override
  String get mirrorSideTitle => 'Costat del mirall';

  @override
  String get joinCall => 'Uneix-te a la trucada';

  @override
  String failedToJoin(String error) {
    return 'No s\'ha pogut unir: $error';
  }

  @override
  String get connecting => 'Connectant…';

  @override
  String get share => 'Comparteix';

  @override
  String shareMessage(String url) {
    return 'Fet amb Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Fes una foto';

  @override
  String get a11yStartRecording => 'Comença a gravar vídeo';

  @override
  String get a11yStopRecording => 'Atura la gravació';

  @override
  String get a11ySwitchCamera => 'Canvia de càmera';

  @override
  String get a11yMirrorAxis => 'Eix del mirall';

  @override
  String get a11yRotation => 'Rotació de la imatge';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees graus';
  }

  @override
  String get a11yClose => 'Tanca';

  @override
  String get a11yToggleLog => 'Mostra o amaga el registre';

  @override
  String unlockAllFor(String price) {
    return 'Tots els filtres per $price';
  }
}
