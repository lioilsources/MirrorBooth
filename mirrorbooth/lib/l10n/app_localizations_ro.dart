// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get filterNone => 'Fără';

  @override
  String get filterGlow => 'Strălucire';

  @override
  String get filterSlim => 'Zvelt';

  @override
  String get filterDoll => 'Păpușă';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Buze';

  @override
  String get filterBigNose => 'Nas';

  @override
  String get filterAlien => 'Extraterestru';

  @override
  String get filterMelt => 'Topire';

  @override
  String get filterBigEars => 'Urechi';

  @override
  String get filterLongNeck => 'Gât';

  @override
  String get filterPencil => 'Creion';

  @override
  String get filterComic => 'Benzi desenate';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Căldură';

  @override
  String get filterOil => 'Ulei';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampir';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Fantomă';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Ger';

  @override
  String get collectionPretty => 'Frumos';

  @override
  String get collectionUgly => 'Urât';

  @override
  String get collectionArt => 'Artă';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8 biți';

  @override
  String get audioEffectSlowMo => 'Lent';

  @override
  String get audioEffectChipmunk => 'Veveriță';

  @override
  String get audioEffectEcho => 'Ecou';

  @override
  String get audioEffectUnderwater => 'Sub apă';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Invers';

  @override
  String get mirrorSideLeftShort => 'S';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Stânga';

  @override
  String get mirrorSideRight => 'Dreapta';

  @override
  String get lensFront => 'FAȚĂ';

  @override
  String get lensBack => 'SPATE';

  @override
  String get photoSaveFailedTitle => 'Fotografia nu a putut fi salvată';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'Accesul la biblioteca foto a fost refuzat.';

  @override
  String get galleryNotEnoughSpace => 'Spațiu de stocare insuficient.';

  @override
  String get galleryUnsupportedFormat =>
      'Acest format de fișier nu este acceptat.';

  @override
  String get genericError => 'A apărut o problemă. Încearcă din nou.';

  @override
  String shaderLoadError(String error) {
    return 'Filtrele nu au putut fi încărcate: $error';
  }

  @override
  String get cameraPermissionDenied => 'Accesul la cameră a fost refuzat';

  @override
  String get noCamerasAvailable => 'Nicio cameră disponibilă';

  @override
  String get cameraStartFailed => 'Camera nu a putut porni.';

  @override
  String get controlsHint => 'trage = rotește  •  ⊙ = foto  •  ● = video';

  @override
  String get controlsHintVolume => 'volum = foto  •  ține volumul = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Colecția $collection a fost deblocată ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtre $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Previzualizarea este gratuită. Deblochează pentru a salva fotografii și videoclipuri.';

  @override
  String get storeUnavailable => 'Magazin indisponibil';

  @override
  String get loadingPrice => 'Se încarcă prețul…';

  @override
  String unlockFor(String price) {
    return 'Deblochează cu $price';
  }

  @override
  String get restorePurchases => 'Restaurează achizițiile';

  @override
  String get purchaseFailed => 'Achiziția a eșuat';

  @override
  String get discardVideoTitle => 'Renunți la videoclip?';

  @override
  String get discardVideoBody =>
      'Această înregistrare nu a fost salvată în galerie.';

  @override
  String get keep => 'Păstrează';

  @override
  String get discard => 'Renunță';

  @override
  String get processing => 'Se procesează…';

  @override
  String get applyingEffect => 'Se aplică efectul…';

  @override
  String get saved => 'Salvat ✓';

  @override
  String get saveToCameraRoll => 'Salvează în galerie';

  @override
  String get micPermissionRequired =>
      'Pentru înregistrarea video este necesar accesul la microfon.';

  @override
  String get recordingTooShort =>
      'Înregistrare prea scurtă — ține apăsat mai mult.';

  @override
  String get videoAssemblyFailed =>
      'Videoclipul nu a putut fi creat. Încearcă din nou.';

  @override
  String get audioEffectFailed => 'Efectul audio a eșuat.';

  @override
  String get roomEntryPrompt =>
      'Introdu un ID de cameră pentru a începe un apel video în oglindă.';

  @override
  String get roomIdHint => 'ID cameră';

  @override
  String get mirrorSideTitle => 'Partea oglinzii';

  @override
  String get joinCall => 'Intră în apel';

  @override
  String failedToJoin(String error) {
    return 'Conectarea a eșuat: $error';
  }

  @override
  String get connecting => 'Se conectează…';

  @override
  String get share => 'Distribuie';

  @override
  String shareMessage(String url) {
    return 'Creat cu Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Fă o fotografie';

  @override
  String get a11yStartRecording => 'Pornește înregistrarea video';

  @override
  String get a11yStopRecording => 'Oprește înregistrarea';

  @override
  String get a11ySwitchCamera => 'Schimbă camera';

  @override
  String get a11yMirrorAxis => 'Axa oglinzii';

  @override
  String get a11yRotation => 'Rotirea imaginii';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees grade';
  }

  @override
  String get a11yClose => 'Închide';

  @override
  String get a11yToggleLog => 'Afișează sau ascunde jurnalul';

  @override
  String unlockAllFor(String price) {
    return 'Toate filtrele cu $price';
  }
}
