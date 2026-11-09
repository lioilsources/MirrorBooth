// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get filterNone => 'Brak';

  @override
  String get filterGlow => 'Blask';

  @override
  String get filterSlim => 'Smukłość';

  @override
  String get filterDoll => 'Lalka';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Usta';

  @override
  String get filterBigNose => 'Nos';

  @override
  String get filterAlien => 'Kosmita';

  @override
  String get filterMelt => 'Topnienie';

  @override
  String get filterBigEars => 'Uszy';

  @override
  String get filterLongNeck => 'Szyja';

  @override
  String get filterPencil => 'Ołówek';

  @override
  String get filterComic => 'Komiks';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Ciepło';

  @override
  String get filterOil => 'Olej';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Wampir';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Duch';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Mróz';

  @override
  String get collectionPretty => 'Piękno';

  @override
  String get collectionUgly => 'Brzydota';

  @override
  String get collectionArt => 'Sztuka';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normalny';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Wolno';

  @override
  String get audioEffectChipmunk => 'Wiewiórka';

  @override
  String get audioEffectEcho => 'Echo';

  @override
  String get audioEffectUnderwater => 'Pod wodą';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Wspak';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'P';

  @override
  String get mirrorSideLeft => 'Lewa';

  @override
  String get mirrorSideRight => 'Prawa';

  @override
  String get lensFront => 'PRZÓD';

  @override
  String get lensBack => 'TYŁ';

  @override
  String get photoSaveFailedTitle => 'Nie udało się zapisać zdjęcia';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Odmówiono dostępu do biblioteki zdjęć.';

  @override
  String get galleryNotEnoughSpace => 'Za mało miejsca w pamięci.';

  @override
  String get galleryUnsupportedFormat =>
      'Ten format pliku nie jest obsługiwany.';

  @override
  String get genericError => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String shaderLoadError(String error) {
    return 'Nie udało się wczytać filtrów: $error';
  }

  @override
  String get cameraPermissionDenied => 'Brak dostępu do aparatu';

  @override
  String get noCamerasAvailable => 'Brak dostępnych aparatów';

  @override
  String get cameraStartFailed => 'Nie udało się uruchomić aparatu.';

  @override
  String get controlsHint =>
      'przeciągnij = obróć  •  ⊙ = zdjęcie  •  ● = wideo';

  @override
  String get controlsHintVolume => 'głośność = zdjęcie  •  przytrzymaj = wideo';

  @override
  String collectionUnlocked(String collection) {
    return 'Kolekcja „$collection” odblokowana ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtry „$collection”';
  }

  @override
  String get paywallPreviewFree =>
      'Podgląd jest bezpłatny. Odblokuj, aby zapisywać zdjęcia i filmy.';

  @override
  String get storeUnavailable => 'Sklep niedostępny';

  @override
  String get loadingPrice => 'Wczytywanie ceny…';

  @override
  String unlockFor(String price) {
    return 'Odblokuj za $price';
  }

  @override
  String get restorePurchases => 'Przywróć zakupy';

  @override
  String get purchaseFailed => 'Zakup nie powiódł się';

  @override
  String get discardVideoTitle => 'Odrzucić film?';

  @override
  String get discardVideoBody => 'To nagranie nie zostało zapisane w galerii.';

  @override
  String get keep => 'Zachowaj';

  @override
  String get discard => 'Odrzuć';

  @override
  String get processing => 'Przetwarzanie…';

  @override
  String get applyingEffect => 'Nakładanie efektu…';

  @override
  String get saved => 'Zapisano ✓';

  @override
  String get saveToCameraRoll => 'Zapisz w galerii';

  @override
  String get micPermissionRequired =>
      'Do nagrywania wideo potrzebny jest dostęp do mikrofonu.';

  @override
  String get recordingTooShort => 'Nagranie za krótkie — przytrzymaj dłużej.';

  @override
  String get videoAssemblyFailed =>
      'Nie udało się utworzyć filmu. Spróbuj ponownie.';

  @override
  String get audioEffectFailed => 'Nie udało się nałożyć efektu dźwiękowego.';

  @override
  String get roomEntryPrompt =>
      'Wpisz ID pokoju, aby rozpocząć lustrzaną rozmowę wideo.';

  @override
  String get roomIdHint => 'ID pokoju';

  @override
  String get mirrorSideTitle => 'Strona lustra';

  @override
  String get joinCall => 'Dołącz do rozmowy';

  @override
  String failedToJoin(String error) {
    return 'Nie udało się dołączyć: $error';
  }

  @override
  String get connecting => 'Łączenie…';

  @override
  String get share => 'Udostępnij';

  @override
  String shareMessage(String url) {
    return 'Zrobione w Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Zrób zdjęcie';

  @override
  String get a11yStartRecording => 'Rozpocznij nagrywanie wideo';

  @override
  String get a11yStopRecording => 'Zatrzymaj nagrywanie';

  @override
  String get a11ySwitchCamera => 'Przełącz aparat';

  @override
  String get a11yMirrorAxis => 'Oś lustra';

  @override
  String get a11yRotation => 'Obrót obrazu';

  @override
  String a11yDegrees(int degrees) {
    return 'Stopnie: $degrees';
  }

  @override
  String get a11yClose => 'Zamknij';

  @override
  String get a11yToggleLog => 'Pokaż lub ukryj dziennik';

  @override
  String unlockAllFor(String price) {
    return 'Wszystkie filtry za $price';
  }
}
