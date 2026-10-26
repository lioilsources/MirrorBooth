// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get filterNone => 'Ohne';

  @override
  String get filterGlow => 'Glanz';

  @override
  String get filterSlim => 'Schlank';

  @override
  String get filterDoll => 'Puppe';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Lippen';

  @override
  String get filterBigNose => 'Nase';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Schmelze';

  @override
  String get filterBigEars => 'Ohren';

  @override
  String get filterLongNeck => 'Hals';

  @override
  String get filterPencil => 'Bleistift';

  @override
  String get filterComic => 'Comic';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Wärme';

  @override
  String get filterOil => 'Öl';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampir';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Geist';

  @override
  String get filterDemon => 'Dämon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Frost';

  @override
  String get collectionPretty => 'Hübsch';

  @override
  String get collectionUgly => 'Hässlich';

  @override
  String get collectionArt => 'Kunst';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-Bit';

  @override
  String get audioEffectSlowMo => 'Zeitlupe';

  @override
  String get audioEffectChipmunk => 'Piepsig';

  @override
  String get audioEffectEcho => 'Echo';

  @override
  String get audioEffectUnderwater => 'Unterwasser';

  @override
  String get audioEffectRobot => 'Roboter';

  @override
  String get audioEffectReverse => 'Rückwärts';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'R';

  @override
  String get mirrorSideLeft => 'Links';

  @override
  String get mirrorSideRight => 'Rechts';

  @override
  String get lensFront => 'VORNE';

  @override
  String get lensBack => 'HINTEN';

  @override
  String get photoSaveFailedTitle => 'Foto konnte nicht gespeichert werden';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'Der Zugriff auf die Fotomediathek wurde verweigert.';

  @override
  String get galleryNotEnoughSpace => 'Nicht genügend Speicherplatz.';

  @override
  String get galleryUnsupportedFormat =>
      'Dieses Dateiformat wird nicht unterstützt.';

  @override
  String get genericError =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String shaderLoadError(String error) {
    return 'Filter konnten nicht geladen werden: $error';
  }

  @override
  String get cameraPermissionDenied => 'Kamerazugriff verweigert';

  @override
  String get noCamerasAvailable => 'Keine Kamera verfügbar';

  @override
  String get cameraStartFailed => 'Die Kamera konnte nicht gestartet werden.';

  @override
  String get controlsHint => 'ziehen = drehen  •  ⊙ = Foto  •  ● = Video';

  @override
  String get controlsHintVolume =>
      'Lautstärke = Foto  •  Lautstärke halten = Video';

  @override
  String collectionUnlocked(String collection) {
    return 'Kollektion „$collection“ freigeschaltet ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Kollektion „$collection“';
  }

  @override
  String get paywallPreviewFree =>
      'Die Vorschau ist kostenlos. Schalte frei, um Fotos und Videos zu speichern.';

  @override
  String get storeUnavailable => 'Store nicht verfügbar';

  @override
  String get loadingPrice => 'Preis wird geladen…';

  @override
  String unlockFor(String price) {
    return 'Freischalten für $price';
  }

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get purchaseFailed => 'Kauf fehlgeschlagen';

  @override
  String get discardVideoTitle => 'Video verwerfen?';

  @override
  String get discardVideoBody =>
      'Diese Aufnahme wurde noch nicht in deinen Fotos gespeichert.';

  @override
  String get keep => 'Behalten';

  @override
  String get discard => 'Verwerfen';

  @override
  String get processing => 'Wird verarbeitet…';

  @override
  String get applyingEffect => 'Effekt wird angewendet…';

  @override
  String get saved => 'Gespeichert ✓';

  @override
  String get saveToCameraRoll => 'In Fotos speichern';

  @override
  String get micPermissionRequired =>
      'Für Videoaufnahmen wird Mikrofonzugriff benötigt.';

  @override
  String get recordingTooShort => 'Aufnahme zu kurz – nimm länger auf.';

  @override
  String get videoAssemblyFailed =>
      'Video konnte nicht erstellt werden. Bitte versuche es erneut.';

  @override
  String get audioEffectFailed => 'Audioeffekt fehlgeschlagen.';

  @override
  String get roomEntryPrompt =>
      'Gib eine Raum-ID ein, um einen gespiegelten Videoanruf zu starten.';

  @override
  String get roomIdHint => 'Raum-ID';

  @override
  String get mirrorSideTitle => 'Spiegelseite';

  @override
  String get joinCall => 'Anruf beitreten';

  @override
  String failedToJoin(String error) {
    return 'Beitreten fehlgeschlagen: $error';
  }

  @override
  String get connecting => 'Verbinde…';
}
