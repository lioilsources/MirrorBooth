// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

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
  String get filterLips => 'Læber';

  @override
  String get filterBigNose => 'Næse';

  @override
  String get filterAlien => 'Rumvæsen';

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
  String get filterOil => 'Olie';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampyr';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Spøgelse';

  @override
  String get filterDemon => 'Dæmon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Frost';

  @override
  String get collectionPretty => 'Smukt';

  @override
  String get collectionUgly => 'Grimt';

  @override
  String get collectionArt => 'Kunst';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Langsom';

  @override
  String get audioEffectChipmunk => 'Jordegern';

  @override
  String get audioEffectEcho => 'Ekko';

  @override
  String get audioEffectUnderwater => 'Under vandet';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Baglæns';

  @override
  String get mirrorSideLeftShort => 'V';

  @override
  String get mirrorSideRightShort => 'H';

  @override
  String get mirrorSideLeft => 'Venstre';

  @override
  String get mirrorSideRight => 'Højre';

  @override
  String get lensFront => 'FORAN';

  @override
  String get lensBack => 'BAG';

  @override
  String get photoSaveFailedTitle => 'Billedet kunne ikke gemmes';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Adgang til fotobiblioteket blev nægtet.';

  @override
  String get galleryNotEnoughSpace => 'Ikke nok lagerplads.';

  @override
  String get galleryUnsupportedFormat => 'Filformatet understøttes ikke.';

  @override
  String get genericError => 'Noget gik galt. Prøv igen.';

  @override
  String shaderLoadError(String error) {
    return 'Filtrene kunne ikke indlæses: $error';
  }

  @override
  String get cameraPermissionDenied => 'Adgang til kameraet nægtet';

  @override
  String get noCamerasAvailable => 'Intet kamera tilgængeligt';

  @override
  String get cameraStartFailed => 'Kameraet kunne ikke startes.';

  @override
  String get controlsHint => 'træk = drej  •  ⊙ = billede  •  ● = video';

  @override
  String get controlsHintVolume => 'lydstyrke = billede  •  hold = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Samlingen $collection er låst op ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtre: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Forhåndsvisningen er gratis. Lås op for at gemme billeder og videoer.';

  @override
  String get storeUnavailable => 'Butikken er ikke tilgængelig';

  @override
  String get loadingPrice => 'Henter pris…';

  @override
  String unlockFor(String price) {
    return 'Lås op for $price';
  }

  @override
  String get restorePurchases => 'Gendan køb';

  @override
  String get purchaseFailed => 'Købet mislykkedes';

  @override
  String get discardVideoTitle => 'Kassér video?';

  @override
  String get discardVideoBody => 'Optagelsen er ikke gemt i kamerarullen.';

  @override
  String get keep => 'Behold';

  @override
  String get discard => 'Kassér';

  @override
  String get processing => 'Behandler…';

  @override
  String get applyingEffect => 'Tilføjer effekt…';

  @override
  String get saved => 'Gemt ✓';

  @override
  String get saveToCameraRoll => 'Gem i kamerarullen';

  @override
  String get micPermissionRequired =>
      'Der kræves adgang til mikrofonen for at optage video.';

  @override
  String get recordingTooShort => 'Optagelsen er for kort – hold længere.';

  @override
  String get videoAssemblyFailed => 'Videoen kunne ikke samles. Prøv igen.';

  @override
  String get audioEffectFailed => 'Lydeffekten mislykkedes.';

  @override
  String get roomEntryPrompt =>
      'Indtast et rum-id for at starte et spejlet videoopkald.';

  @override
  String get roomIdHint => 'Rum-id';

  @override
  String get mirrorSideTitle => 'Spejlside';

  @override
  String get joinCall => 'Deltag i opkald';

  @override
  String failedToJoin(String error) {
    return 'Kunne ikke deltage: $error';
  }

  @override
  String get connecting => 'Forbinder…';

  @override
  String get share => 'Del';

  @override
  String shareMessage(String url) {
    return 'Lavet med Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Tag billede';

  @override
  String get a11yStartRecording => 'Start videooptagelse';

  @override
  String get a11yStopRecording => 'Stop optagelse';

  @override
  String get a11ySwitchCamera => 'Skift kamera';

  @override
  String get a11yMirrorAxis => 'Spejlakse';

  @override
  String get a11yRotation => 'Billedrotation';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees grader';
  }

  @override
  String get a11yClose => 'Luk';

  @override
  String get a11yToggleLog => 'Vis eller skjul loggen';

  @override
  String unlockAllFor(String price) {
    return 'Alle filtre for $price';
  }
}
