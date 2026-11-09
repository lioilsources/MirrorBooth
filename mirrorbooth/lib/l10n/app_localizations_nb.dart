// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get filterNone => 'Ingen';

  @override
  String get filterGlow => 'Glød';

  @override
  String get filterSlim => 'Slank';

  @override
  String get filterDoll => 'Dukke';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Lepper';

  @override
  String get filterBigNose => 'Nese';

  @override
  String get filterAlien => 'Romvesen';

  @override
  String get filterMelt => 'Smelt';

  @override
  String get filterBigEars => 'Ører';

  @override
  String get filterLongNeck => 'Hals';

  @override
  String get filterPencil => 'Blyant';

  @override
  String get filterComic => 'Tegneserie';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Varme';

  @override
  String get filterOil => 'Olje';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampyr';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Spøkelse';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Kyborg';

  @override
  String get filterFrozen => 'Frost';

  @override
  String get collectionPretty => 'Pent';

  @override
  String get collectionUgly => 'Stygt';

  @override
  String get collectionArt => 'Kunst';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Sakte';

  @override
  String get audioEffectChipmunk => 'Jordekorn';

  @override
  String get audioEffectEcho => 'Ekko';

  @override
  String get audioEffectUnderwater => 'Under vann';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Baklengs';

  @override
  String get mirrorSideLeftShort => 'V';

  @override
  String get mirrorSideRightShort => 'H';

  @override
  String get mirrorSideLeft => 'Venstre';

  @override
  String get mirrorSideRight => 'Høyre';

  @override
  String get lensFront => 'FORAN';

  @override
  String get lensBack => 'BAK';

  @override
  String get photoSaveFailedTitle => 'Kunne ikke lagre bildet';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Tilgang til bildebiblioteket ble nektet.';

  @override
  String get galleryNotEnoughSpace => 'Ikke nok lagringsplass.';

  @override
  String get galleryUnsupportedFormat => 'Filformatet støttes ikke.';

  @override
  String get genericError => 'Noe gikk galt. Prøv igjen.';

  @override
  String shaderLoadError(String error) {
    return 'Kunne ikke laste inn filtrene: $error';
  }

  @override
  String get cameraPermissionDenied => 'Kameratilgang nektet';

  @override
  String get noCamerasAvailable => 'Ingen kamera tilgjengelig';

  @override
  String get cameraStartFailed => 'Kunne ikke starte kameraet.';

  @override
  String get controlsHint => 'dra = roter  •  ⊙ = bilde  •  ● = video';

  @override
  String get controlsHintVolume => 'volum = bilde  •  hold volum = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Samlingen $collection er låst opp ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtre: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Forhåndsvisningen er gratis. Lås opp for å lagre bilder og videoer.';

  @override
  String get storeUnavailable => 'Butikken er ikke tilgjengelig';

  @override
  String get loadingPrice => 'Henter pris…';

  @override
  String unlockFor(String price) {
    return 'Lås opp for $price';
  }

  @override
  String get restorePurchases => 'Gjenopprett kjøp';

  @override
  String get purchaseFailed => 'Kjøpet mislyktes';

  @override
  String get discardVideoTitle => 'Forkaste videoen?';

  @override
  String get discardVideoBody => 'Opptaket er ikke lagret i kamerarullen.';

  @override
  String get keep => 'Behold';

  @override
  String get discard => 'Forkast';

  @override
  String get processing => 'Behandler…';

  @override
  String get applyingEffect => 'Legger på effekt…';

  @override
  String get saved => 'Lagret ✓';

  @override
  String get saveToCameraRoll => 'Lagre i kamerarullen';

  @override
  String get micPermissionRequired => 'Mikrofontilgang kreves for videoopptak.';

  @override
  String get recordingTooShort => 'Opptaket er for kort – hold lenger.';

  @override
  String get videoAssemblyFailed =>
      'Kunne ikke sette sammen videoen. Prøv igjen.';

  @override
  String get audioEffectFailed => 'Lydeffekten mislyktes.';

  @override
  String get roomEntryPrompt =>
      'Skriv inn en rom-ID for å starte en speilet videosamtale.';

  @override
  String get roomIdHint => 'Rom-ID';

  @override
  String get mirrorSideTitle => 'Speilside';

  @override
  String get joinCall => 'Bli med i samtalen';

  @override
  String failedToJoin(String error) {
    return 'Kunne ikke bli med: $error';
  }

  @override
  String get connecting => 'Kobler til…';

  @override
  String get share => 'Del';

  @override
  String shareMessage(String url) {
    return 'Laget med Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Ta bilde';

  @override
  String get a11yStartRecording => 'Start videoopptak';

  @override
  String get a11yStopRecording => 'Stopp opptak';

  @override
  String get a11ySwitchCamera => 'Bytt kamera';

  @override
  String get a11yMirrorAxis => 'Speilakse';

  @override
  String get a11yRotation => 'Bilderotasjon';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees grader';
  }

  @override
  String get a11yClose => 'Lukk';

  @override
  String get a11yToggleLog => 'Vis eller skjul loggen';

  @override
  String unlockAllFor(String price) {
    return 'Alle filtre for $price';
  }
}
