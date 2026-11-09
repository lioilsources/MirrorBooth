// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get filterNone => 'Ei mitään';

  @override
  String get filterGlow => 'Hehku';

  @override
  String get filterSlim => 'Hoikka';

  @override
  String get filterDoll => 'Nukke';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Huulet';

  @override
  String get filterBigNose => 'Nenä';

  @override
  String get filterAlien => 'Avaruusolio';

  @override
  String get filterMelt => 'Sula';

  @override
  String get filterBigEars => 'Korvat';

  @override
  String get filterLongNeck => 'Kaula';

  @override
  String get filterPencil => 'Lyijykynä';

  @override
  String get filterComic => 'Sarjakuva';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Lämpö';

  @override
  String get filterOil => 'Öljy';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampyyri';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Aave';

  @override
  String get filterDemon => 'Demoni';

  @override
  String get filterCyborg => 'Kyborgi';

  @override
  String get filterFrozen => 'Huurre';

  @override
  String get collectionPretty => 'Kaunis';

  @override
  String get collectionUgly => 'Ruma';

  @override
  String get collectionArt => 'Taide';

  @override
  String get collectionFantasy => 'Fantasia';

  @override
  String get audioEffectNone => 'Normaali';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Hidas';

  @override
  String get audioEffectChipmunk => 'Maaorava';

  @override
  String get audioEffectEcho => 'Kaiku';

  @override
  String get audioEffectUnderwater => 'Veden alla';

  @override
  String get audioEffectRobot => 'Robotti';

  @override
  String get audioEffectReverse => 'Takaperin';

  @override
  String get mirrorSideLeftShort => 'V';

  @override
  String get mirrorSideRightShort => 'O';

  @override
  String get mirrorSideLeft => 'Vasen';

  @override
  String get mirrorSideRight => 'Oikea';

  @override
  String get lensFront => 'ETU';

  @override
  String get lensBack => 'TAKA';

  @override
  String get photoSaveFailedTitle => 'Kuvaa ei voitu tallentaa';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Pääsy kuvakirjastoon estettiin.';

  @override
  String get galleryNotEnoughSpace => 'Tallennustila ei riitä.';

  @override
  String get galleryUnsupportedFormat => 'Tätä tiedostomuotoa ei tueta.';

  @override
  String get genericError => 'Jokin meni pieleen. Yritä uudelleen.';

  @override
  String shaderLoadError(String error) {
    return 'Suodattimia ei voitu ladata: $error';
  }

  @override
  String get cameraPermissionDenied => 'Kameran käyttö estetty';

  @override
  String get noCamerasAvailable => 'Kameraa ei ole saatavilla';

  @override
  String get cameraStartFailed => 'Kameraa ei voitu käynnistää.';

  @override
  String get controlsHint => 'vedä = kierrä  •  ⊙ = kuva  •  ● = video';

  @override
  String get controlsHintVolume => 'äänenvoimakkuus = kuva  •  pidä = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Kokoelma $collection avattu ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Suodattimet: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Esikatselu on ilmainen. Avaa kokoelma tallentaaksesi kuvia ja videoita.';

  @override
  String get storeUnavailable => 'Kauppa ei ole käytettävissä';

  @override
  String get loadingPrice => 'Ladataan hintaa…';

  @override
  String unlockFor(String price) {
    return 'Avaa hintaan $price';
  }

  @override
  String get restorePurchases => 'Palauta ostot';

  @override
  String get purchaseFailed => 'Osto epäonnistui';

  @override
  String get discardVideoTitle => 'Hylätäänkö video?';

  @override
  String get discardVideoBody =>
      'Tätä tallennetta ei ole vielä tallennettu kameran rullaan.';

  @override
  String get keep => 'Säilytä';

  @override
  String get discard => 'Hylkää';

  @override
  String get processing => 'Käsitellään…';

  @override
  String get applyingEffect => 'Lisätään tehostetta…';

  @override
  String get saved => 'Tallennettu ✓';

  @override
  String get saveToCameraRoll => 'Tallenna kameran rullaan';

  @override
  String get micPermissionRequired =>
      'Videon tallentaminen vaatii mikrofonin käyttöoikeuden.';

  @override
  String get recordingTooShort => 'Tallenne on liian lyhyt – pidä pidempään.';

  @override
  String get videoAssemblyFailed =>
      'Videon kokoaminen epäonnistui. Yritä uudelleen.';

  @override
  String get audioEffectFailed => 'Äänitehoste epäonnistui.';

  @override
  String get roomEntryPrompt =>
      'Anna huoneen tunnus aloittaaksesi peilatun videopuhelun.';

  @override
  String get roomIdHint => 'Huoneen tunnus';

  @override
  String get mirrorSideTitle => 'Peilin puoli';

  @override
  String get joinCall => 'Liity puheluun';

  @override
  String failedToJoin(String error) {
    return 'Liittyminen epäonnistui: $error';
  }

  @override
  String get connecting => 'Yhdistetään…';

  @override
  String get share => 'Jaa';

  @override
  String shareMessage(String url) {
    return 'Tehty Mirror Boothilla: $url';
  }

  @override
  String get a11yTakePhoto => 'Ota kuva';

  @override
  String get a11yStartRecording => 'Aloita videon tallennus';

  @override
  String get a11yStopRecording => 'Lopeta tallennus';

  @override
  String get a11ySwitchCamera => 'Vaihda kameraa';

  @override
  String get a11yMirrorAxis => 'Peilin akseli';

  @override
  String get a11yRotation => 'Kuvan kierto';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees astetta';
  }

  @override
  String get a11yClose => 'Sulje';

  @override
  String get a11yToggleLog => 'Näytä tai piilota loki';

  @override
  String unlockAllFor(String price) {
    return 'Kaikki suodattimet hintaan $price';
  }
}
