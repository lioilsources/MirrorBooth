// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get filterNone => 'Geen';

  @override
  String get filterGlow => 'Gloed';

  @override
  String get filterSlim => 'Slank';

  @override
  String get filterDoll => 'Pop';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Lippen';

  @override
  String get filterBigNose => 'Neus';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Smelt';

  @override
  String get filterBigEars => 'Oren';

  @override
  String get filterLongNeck => 'Nek';

  @override
  String get filterPencil => 'Potlood';

  @override
  String get filterComic => 'Strip';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Warmte';

  @override
  String get filterOil => 'Olieverf';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop-art';

  @override
  String get filterVampire => 'Vampier';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Spook';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Vorst';

  @override
  String get collectionPretty => 'Mooi';

  @override
  String get collectionUgly => 'Lelijk';

  @override
  String get collectionArt => 'Kunst';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normaal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Traag';

  @override
  String get audioEffectChipmunk => 'Eekhoorn';

  @override
  String get audioEffectEcho => 'Echo';

  @override
  String get audioEffectUnderwater => 'Onderwater';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Achteruit';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'R';

  @override
  String get mirrorSideLeft => 'Links';

  @override
  String get mirrorSideRight => 'Rechts';

  @override
  String get lensFront => 'VOOR';

  @override
  String get lensBack => 'ACHTER';

  @override
  String get photoSaveFailedTitle => 'Foto kon niet worden bewaard';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'Toegang tot de fotobibliotheek is geweigerd.';

  @override
  String get galleryNotEnoughSpace => 'Niet genoeg opslagruimte.';

  @override
  String get galleryUnsupportedFormat =>
      'Dit bestandsformaat wordt niet ondersteund.';

  @override
  String get genericError => 'Er is iets misgegaan. Probeer het opnieuw.';

  @override
  String shaderLoadError(String error) {
    return 'Filters konden niet worden geladen: $error';
  }

  @override
  String get cameraPermissionDenied => 'Cameratoegang geweigerd';

  @override
  String get noCamerasAvailable => 'Geen camera beschikbaar';

  @override
  String get cameraStartFailed => 'De camera kon niet worden gestart.';

  @override
  String get controlsHint => 'slepen = draaien  •  ⊙ = foto  •  ● = video';

  @override
  String get controlsHintVolume =>
      'volume = foto  •  volume vasthouden = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Collectie $collection ontgrendeld ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection-filters';
  }

  @override
  String get paywallPreviewFree =>
      'De preview is gratis. Ontgrendel om foto\'s en video\'s te bewaren.';

  @override
  String get storeUnavailable => 'Store niet beschikbaar';

  @override
  String get loadingPrice => 'Prijs laden…';

  @override
  String unlockFor(String price) {
    return 'Ontgrendel voor $price';
  }

  @override
  String get restorePurchases => 'Aankopen herstellen';

  @override
  String get purchaseFailed => 'Aankoop mislukt';

  @override
  String get discardVideoTitle => 'Video verwijderen?';

  @override
  String get discardVideoBody =>
      'Deze opname is nog niet in je filmrol bewaard.';

  @override
  String get keep => 'Bewaren';

  @override
  String get discard => 'Verwijderen';

  @override
  String get processing => 'Verwerken…';

  @override
  String get applyingEffect => 'Effect toepassen…';

  @override
  String get saved => 'Bewaard ✓';

  @override
  String get saveToCameraRoll => 'Bewaar in filmrol';

  @override
  String get micPermissionRequired =>
      'Voor video-opnames is toegang tot de microfoon nodig.';

  @override
  String get recordingTooShort => 'Opname te kort — houd langer ingedrukt.';

  @override
  String get videoAssemblyFailed => 'Video maken mislukt. Probeer het opnieuw.';

  @override
  String get audioEffectFailed => 'Audio-effect mislukt.';

  @override
  String get roomEntryPrompt =>
      'Voer een kamer-ID in om een gespiegeld videogesprek te starten.';

  @override
  String get roomIdHint => 'Kamer-ID';

  @override
  String get mirrorSideTitle => 'Spiegelkant';

  @override
  String get joinCall => 'Deelnemen';

  @override
  String failedToJoin(String error) {
    return 'Deelnemen mislukt: $error';
  }

  @override
  String get connecting => 'Verbinden…';

  @override
  String get share => 'Delen';

  @override
  String shareMessage(String url) {
    return 'Gemaakt met Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Foto maken';

  @override
  String get a11yStartRecording => 'Video-opname starten';

  @override
  String get a11yStopRecording => 'Opname stoppen';

  @override
  String get a11ySwitchCamera => 'Wissel camera';

  @override
  String get a11yMirrorAxis => 'Spiegelas';

  @override
  String get a11yRotation => 'Beeldrotatie';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees graden';
  }

  @override
  String get a11yClose => 'Sluiten';

  @override
  String get a11yToggleLog => 'Logboek tonen of verbergen';

  @override
  String unlockAllFor(String price) {
    return 'Alle filters voor $price';
  }
}
