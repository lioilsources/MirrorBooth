// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get filterNone => 'Žiadny';

  @override
  String get filterGlow => 'Žiara';

  @override
  String get filterSlim => 'Štíhlosť';

  @override
  String get filterDoll => 'Bábika';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Pery';

  @override
  String get filterBigNose => 'Nos';

  @override
  String get filterAlien => 'Ufón';

  @override
  String get filterMelt => 'Topenie';

  @override
  String get filterBigEars => 'Uši';

  @override
  String get filterLongNeck => 'Krk';

  @override
  String get filterPencil => 'Ceruzka';

  @override
  String get filterComic => 'Komiks';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neón';

  @override
  String get filterThermal => 'Teplo';

  @override
  String get filterOil => 'Olej';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Upír';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Duch';

  @override
  String get filterDemon => 'Démon';

  @override
  String get filterCyborg => 'Kyborg';

  @override
  String get filterFrozen => 'Mráz';

  @override
  String get collectionPretty => 'Krása';

  @override
  String get collectionUgly => 'Škaredosť';

  @override
  String get collectionArt => 'Umenie';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normálny';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Pomaly';

  @override
  String get audioEffectChipmunk => 'Veverička';

  @override
  String get audioEffectEcho => 'Ozvena';

  @override
  String get audioEffectUnderwater => 'Pod vodou';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Odzadu';

  @override
  String get mirrorSideLeftShort => 'Ľ';

  @override
  String get mirrorSideRightShort => 'P';

  @override
  String get mirrorSideLeft => 'Ľavá';

  @override
  String get mirrorSideRight => 'Pravá';

  @override
  String get lensFront => 'PREDNÁ';

  @override
  String get lensBack => 'ZADNÁ';

  @override
  String get photoSaveFailedTitle => 'Fotku sa nepodarilo uložiť';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'Prístup ku knižnici fotiek bol zamietnutý.';

  @override
  String get galleryNotEnoughSpace => 'Nedostatok miesta v úložisku.';

  @override
  String get galleryUnsupportedFormat =>
      'Tento formát súboru nie je podporovaný.';

  @override
  String get genericError => 'Niečo sa pokazilo. Skúste to znova.';

  @override
  String shaderLoadError(String error) {
    return 'Filtre sa nepodarilo načítať: $error';
  }

  @override
  String get cameraPermissionDenied => 'Prístup ku kamere bol zamietnutý';

  @override
  String get noCamerasAvailable => 'Žiadna kamera nie je k dispozícii';

  @override
  String get cameraStartFailed => 'Kameru sa nepodarilo spustiť.';

  @override
  String get controlsHint => 'ťahať = otočiť  •  ⊙ = fotka  •  ● = video';

  @override
  String get controlsHintVolume => 'hlasitosť = fotka  •  podržať = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Kolekcia $collection odomknutá ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtre $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Náhľad je zadarmo. Po odomknutí môžete ukladať fotky a videá.';

  @override
  String get storeUnavailable => 'Obchod nie je dostupný';

  @override
  String get loadingPrice => 'Načítava sa cena…';

  @override
  String unlockFor(String price) {
    return 'Odomknúť za $price';
  }

  @override
  String get restorePurchases => 'Obnoviť nákupy';

  @override
  String get purchaseFailed => 'Nákup zlyhal';

  @override
  String get discardVideoTitle => 'Zahodiť video?';

  @override
  String get discardVideoBody => 'Tento záznam ešte nie je uložený v galérii.';

  @override
  String get keep => 'Ponechať';

  @override
  String get discard => 'Zahodiť';

  @override
  String get processing => 'Spracúva sa…';

  @override
  String get applyingEffect => 'Používa sa efekt…';

  @override
  String get saved => 'Uložené ✓';

  @override
  String get saveToCameraRoll => 'Uložiť do galérie';

  @override
  String get micPermissionRequired =>
      'Na nahrávanie videa je potrebný prístup k mikrofónu.';

  @override
  String get recordingTooShort => 'Záznam je príliš krátky — podržte dlhšie.';

  @override
  String get videoAssemblyFailed =>
      'Video sa nepodarilo vytvoriť. Skúste to znova.';

  @override
  String get audioEffectFailed => 'Zvukový efekt zlyhal.';

  @override
  String get roomEntryPrompt =>
      'Zadajte ID miestnosti a začnite zrkadlový videohovor.';

  @override
  String get roomIdHint => 'ID miestnosti';

  @override
  String get mirrorSideTitle => 'Strana zrkadla';

  @override
  String get joinCall => 'Pripojiť sa';

  @override
  String failedToJoin(String error) {
    return 'Pripojenie zlyhalo: $error';
  }

  @override
  String get connecting => 'Pripája sa…';

  @override
  String get share => 'Zdieľať';

  @override
  String shareMessage(String url) {
    return 'Vytvorené v Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Odfotiť';

  @override
  String get a11yStartRecording => 'Spustiť nahrávanie videa';

  @override
  String get a11yStopRecording => 'Zastaviť nahrávanie';

  @override
  String get a11ySwitchCamera => 'Prepnúť kameru';

  @override
  String get a11yMirrorAxis => 'Os zrkadla';

  @override
  String get a11yRotation => 'Otočenie obrazu';

  @override
  String a11yDegrees(int degrees) {
    return 'Stupne: $degrees';
  }

  @override
  String get a11yClose => 'Zavrieť';

  @override
  String get a11yToggleLog => 'Zobraziť alebo skryť záznam';

  @override
  String unlockAllFor(String price) {
    return 'Všetky filtre za $price';
  }
}
