// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get filterNone => 'Bez';

  @override
  String get filterGlow => 'Sjaj';

  @override
  String get filterSlim => 'Vitkost';

  @override
  String get filterDoll => 'Lutka';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Usne';

  @override
  String get filterBigNose => 'Nos';

  @override
  String get filterAlien => 'Vanzemaljac';

  @override
  String get filterMelt => 'Topljenje';

  @override
  String get filterBigEars => 'Uši';

  @override
  String get filterLongNeck => 'Vrat';

  @override
  String get filterPencil => 'Olovka';

  @override
  String get filterComic => 'Strip';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Toplina';

  @override
  String get filterOil => 'Ulje';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampir';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Duh';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Kiborg';

  @override
  String get filterFrozen => 'Mraz';

  @override
  String get collectionPretty => 'Ljepota';

  @override
  String get collectionUgly => 'Ružnoća';

  @override
  String get collectionArt => 'Umjetnost';

  @override
  String get collectionFantasy => 'Fantazija';

  @override
  String get audioEffectNone => 'Normalno';

  @override
  String get audioEffectChiptune => '8-bitno';

  @override
  String get audioEffectSlowMo => 'Sporo';

  @override
  String get audioEffectChipmunk => 'Vjeverica';

  @override
  String get audioEffectEcho => 'Jeka';

  @override
  String get audioEffectUnderwater => 'Pod vodom';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Unatrag';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Lijevo';

  @override
  String get mirrorSideRight => 'Desno';

  @override
  String get lensFront => 'PREDNJA';

  @override
  String get lensBack => 'STRAŽNJA';

  @override
  String get photoSaveFailedTitle => 'Fotografija se nije mogla spremiti';

  @override
  String get ok => 'U redu';

  @override
  String get galleryAccessDenied =>
      'Pristup biblioteci fotografija je odbijen.';

  @override
  String get galleryNotEnoughSpace => 'Nema dovoljno prostora za pohranu.';

  @override
  String get galleryUnsupportedFormat => 'Ovaj format datoteke nije podržan.';

  @override
  String get genericError => 'Nešto je pošlo po zlu. Pokušajte ponovno.';

  @override
  String shaderLoadError(String error) {
    return 'Filtri se nisu mogli učitati: $error';
  }

  @override
  String get cameraPermissionDenied => 'Pristup kameri je odbijen';

  @override
  String get noCamerasAvailable => 'Nema dostupnih kamera';

  @override
  String get cameraStartFailed => 'Kamera se nije mogla pokrenuti.';

  @override
  String get controlsHint =>
      'povuci = zakreni  •  ⊙ = fotografija  •  ● = video';

  @override
  String get controlsHintVolume => 'glasnoća = fotografija  •  zadrži = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Kolekcija $collection otključana ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtri $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Pregled je besplatan. Otključajte za spremanje fotografija i videozapisa.';

  @override
  String get storeUnavailable => 'Trgovina nije dostupna';

  @override
  String get loadingPrice => 'Učitavanje cijene…';

  @override
  String unlockFor(String price) {
    return 'Otključaj za $price';
  }

  @override
  String get restorePurchases => 'Vrati kupnje';

  @override
  String get purchaseFailed => 'Kupnja nije uspjela';

  @override
  String get discardVideoTitle => 'Odbaciti videozapis?';

  @override
  String get discardVideoBody => 'Ova snimka još nije spremljena u galeriju.';

  @override
  String get keep => 'Zadrži';

  @override
  String get discard => 'Odbaci';

  @override
  String get processing => 'Obrada…';

  @override
  String get applyingEffect => 'Primjena efekta…';

  @override
  String get saved => 'Spremljeno ✓';

  @override
  String get saveToCameraRoll => 'Spremi u galeriju';

  @override
  String get micPermissionRequired =>
      'Za snimanje videozapisa potreban je pristup mikrofonu.';

  @override
  String get recordingTooShort => 'Snimka je prekratka — držite dulje.';

  @override
  String get videoAssemblyFailed =>
      'Videozapis se nije mogao složiti. Pokušajte ponovno.';

  @override
  String get audioEffectFailed => 'Zvučni efekt nije uspio.';

  @override
  String get roomEntryPrompt =>
      'Unesite ID sobe za početak zrcalnog videopoziva.';

  @override
  String get roomIdHint => 'ID sobe';

  @override
  String get mirrorSideTitle => 'Strana zrcala';

  @override
  String get joinCall => 'Pridruži se pozivu';

  @override
  String failedToJoin(String error) {
    return 'Pridruživanje nije uspjelo: $error';
  }

  @override
  String get connecting => 'Povezivanje…';

  @override
  String get share => 'Podijeli';

  @override
  String shareMessage(String url) {
    return 'Napravljeno u aplikaciji Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Snimi fotografiju';

  @override
  String get a11yStartRecording => 'Pokreni snimanje videozapisa';

  @override
  String get a11yStopRecording => 'Zaustavi snimanje';

  @override
  String get a11ySwitchCamera => 'Promijeni kameru';

  @override
  String get a11yMirrorAxis => 'Os zrcala';

  @override
  String get a11yRotation => 'Zakretanje slike';

  @override
  String a11yDegrees(int degrees) {
    return 'Stupnjevi: $degrees';
  }

  @override
  String get a11yClose => 'Zatvori';

  @override
  String get a11yToggleLog => 'Prikaži ili sakrij zapisnik';

  @override
  String unlockAllFor(String price) {
    return 'Svi filtri za $price';
  }
}
