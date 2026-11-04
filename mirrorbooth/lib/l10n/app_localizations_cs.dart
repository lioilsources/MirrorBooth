// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get filterNone => 'Žádný';

  @override
  String get filterGlow => 'Záře';

  @override
  String get filterSlim => 'Štíhlost';

  @override
  String get filterDoll => 'Panenka';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Rty';

  @override
  String get filterBigNose => 'Nos';

  @override
  String get filterAlien => 'Ufon';

  @override
  String get filterMelt => 'Tání';

  @override
  String get filterBigEars => 'Uši';

  @override
  String get filterLongNeck => 'Krk';

  @override
  String get filterPencil => 'Tužka';

  @override
  String get filterComic => 'Komiks';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

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
  String get collectionUgly => 'Ošklivost';

  @override
  String get collectionArt => 'Umění';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normální';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Zpomalení';

  @override
  String get audioEffectChipmunk => 'Veverka';

  @override
  String get audioEffectEcho => 'Ozvěna';

  @override
  String get audioEffectUnderwater => 'Pod vodou';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Pozpátku';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'P';

  @override
  String get mirrorSideLeft => 'Vlevo';

  @override
  String get mirrorSideRight => 'Vpravo';

  @override
  String get lensFront => 'PŘEDNÍ';

  @override
  String get lensBack => 'ZADNÍ';

  @override
  String get photoSaveFailedTitle => 'Fotku se nepodařilo uložit';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Přístup ke knihovně fotek byl odepřen.';

  @override
  String get galleryNotEnoughSpace => 'Nedostatek místa v úložišti.';

  @override
  String get galleryUnsupportedFormat =>
      'Tento formát souboru není podporován.';

  @override
  String get genericError => 'Něco se pokazilo. Zkuste to prosím znovu.';

  @override
  String shaderLoadError(String error) {
    return 'Filtry se nepodařilo načíst: $error';
  }

  @override
  String get cameraPermissionDenied => 'Přístup ke kameře byl zamítnut';

  @override
  String get noCamerasAvailable => 'Není k dispozici žádná kamera';

  @override
  String get cameraStartFailed => 'Kameru se nepodařilo spustit.';

  @override
  String get controlsHint => 'táhnout = otočit  •  ⊙ = fotka  •  ● = video';

  @override
  String get controlsHintVolume =>
      'hlasitost = fotka  •  podržet hlasitost = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Kolekce $collection odemčena ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Kolekce $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Náhled je zdarma. Po odemčení můžete ukládat fotky a videa.';

  @override
  String get storeUnavailable => 'Obchod není dostupný';

  @override
  String get loadingPrice => 'Načítání ceny…';

  @override
  String unlockFor(String price) {
    return 'Odemknout za $price';
  }

  @override
  String get restorePurchases => 'Obnovit nákupy';

  @override
  String get purchaseFailed => 'Nákup se nezdařil';

  @override
  String get discardVideoTitle => 'Zahodit video?';

  @override
  String get discardVideoBody => 'Tento záznam ještě není uložený ve fotkách.';

  @override
  String get keep => 'Ponechat';

  @override
  String get discard => 'Zahodit';

  @override
  String get processing => 'Zpracování…';

  @override
  String get applyingEffect => 'Použití efektu…';

  @override
  String get saved => 'Uloženo ✓';

  @override
  String get saveToCameraRoll => 'Uložit do fotek';

  @override
  String get micPermissionRequired =>
      'Pro nahrávání videa je potřeba přístup k mikrofonu.';

  @override
  String get recordingTooShort => 'Záznam je moc krátký — nahrávejte déle.';

  @override
  String get videoAssemblyFailed =>
      'Video se nepodařilo vytvořit. Zkuste to prosím znovu.';

  @override
  String get audioEffectFailed => 'Zvukový efekt se nepodařilo použít.';

  @override
  String get roomEntryPrompt =>
      'Zadejte ID místnosti a zahajte zrcadlový videohovor.';

  @override
  String get roomIdHint => 'ID místnosti';

  @override
  String get mirrorSideTitle => 'Strana zrcadlení';

  @override
  String get joinCall => 'Připojit se';

  @override
  String failedToJoin(String error) {
    return 'Připojení se nezdařilo: $error';
  }

  @override
  String get connecting => 'Připojování…';

  @override
  String get share => 'Sdílet';

  @override
  String shareMessage(String url) {
    return 'Vytvořeno v Mirror Booth: $url';
  }
}
