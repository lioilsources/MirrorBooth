// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get filterNone => 'Nincs';

  @override
  String get filterGlow => 'Ragyogás';

  @override
  String get filterSlim => 'Karcsú';

  @override
  String get filterDoll => 'Baba';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Ajkak';

  @override
  String get filterBigNose => 'Orr';

  @override
  String get filterAlien => 'Földönkívüli';

  @override
  String get filterMelt => 'Olvadás';

  @override
  String get filterBigEars => 'Fülek';

  @override
  String get filterLongNeck => 'Nyak';

  @override
  String get filterPencil => 'Ceruza';

  @override
  String get filterComic => 'Képregény';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Hő';

  @override
  String get filterOil => 'Olaj';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vámpír';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Szellem';

  @override
  String get filterDemon => 'Démon';

  @override
  String get filterCyborg => 'Kiborg';

  @override
  String get filterFrozen => 'Fagy';

  @override
  String get collectionPretty => 'Szép';

  @override
  String get collectionUgly => 'Csúnya';

  @override
  String get collectionArt => 'Művészet';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normál';

  @override
  String get audioEffectChiptune => '8 bites';

  @override
  String get audioEffectSlowMo => 'Lassú';

  @override
  String get audioEffectChipmunk => 'Mókus';

  @override
  String get audioEffectEcho => 'Visszhang';

  @override
  String get audioEffectUnderwater => 'Víz alatt';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Visszafelé';

  @override
  String get mirrorSideLeftShort => 'B';

  @override
  String get mirrorSideRightShort => 'J';

  @override
  String get mirrorSideLeft => 'Bal';

  @override
  String get mirrorSideRight => 'Jobb';

  @override
  String get lensFront => 'ELÜLSŐ';

  @override
  String get lensBack => 'HÁTSÓ';

  @override
  String get photoSaveFailedTitle => 'Nem sikerült menteni a fotót';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'A fotókönyvtárhoz való hozzáférés megtagadva.';

  @override
  String get galleryNotEnoughSpace => 'Nincs elég tárhely.';

  @override
  String get galleryUnsupportedFormat => 'Ez a fájlformátum nem támogatott.';

  @override
  String get genericError => 'Hiba történt. Próbáld újra.';

  @override
  String shaderLoadError(String error) {
    return 'Nem sikerült betölteni a szűrőket: $error';
  }

  @override
  String get cameraPermissionDenied => 'Kamera-hozzáférés megtagadva';

  @override
  String get noCamerasAvailable => 'Nincs elérhető kamera';

  @override
  String get cameraStartFailed => 'Nem sikerült elindítani a kamerát.';

  @override
  String get controlsHint => 'húzás = forgatás  •  ⊙ = fotó  •  ● = videó';

  @override
  String get controlsHintVolume => 'hangerő = fotó  •  hangerő nyomva = videó';

  @override
  String collectionUnlocked(String collection) {
    return '$collection gyűjtemény feloldva ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection szűrők';
  }

  @override
  String get paywallPreviewFree =>
      'Az előnézet ingyenes. Oldd fel a fotók és videók mentéséhez.';

  @override
  String get storeUnavailable => 'Az áruház nem érhető el';

  @override
  String get loadingPrice => 'Ár betöltése…';

  @override
  String unlockFor(String price) {
    return 'Feloldás: $price';
  }

  @override
  String get restorePurchases => 'Vásárlások visszaállítása';

  @override
  String get purchaseFailed => 'A vásárlás sikertelen';

  @override
  String get discardVideoTitle => 'Elveted a videót?';

  @override
  String get discardVideoBody => 'Ez a felvétel még nincs mentve a galériába.';

  @override
  String get keep => 'Megtartás';

  @override
  String get discard => 'Elvetés';

  @override
  String get processing => 'Feldolgozás…';

  @override
  String get applyingEffect => 'Effekt alkalmazása…';

  @override
  String get saved => 'Mentve ✓';

  @override
  String get saveToCameraRoll => 'Mentés a galériába';

  @override
  String get micPermissionRequired =>
      'A videófelvételhez mikrofon-hozzáférés szükséges.';

  @override
  String get recordingTooShort => 'Túl rövid felvétel — tartsd nyomva tovább.';

  @override
  String get videoAssemblyFailed =>
      'Nem sikerült összeállítani a videót. Próbáld újra.';

  @override
  String get audioEffectFailed => 'A hangeffekt nem sikerült.';

  @override
  String get roomEntryPrompt =>
      'Adj meg egy szobaazonosítót a tükrözött videóhívás indításához.';

  @override
  String get roomIdHint => 'Szobaazonosító';

  @override
  String get mirrorSideTitle => 'Tükör oldala';

  @override
  String get joinCall => 'Csatlakozás';

  @override
  String failedToJoin(String error) {
    return 'Nem sikerült csatlakozni: $error';
  }

  @override
  String get connecting => 'Kapcsolódás…';

  @override
  String get share => 'Megosztás';

  @override
  String shareMessage(String url) {
    return 'Mirror Booth-tal készült: $url';
  }

  @override
  String get a11yTakePhoto => 'Fotó készítése';

  @override
  String get a11yStartRecording => 'Videófelvétel indítása';

  @override
  String get a11yStopRecording => 'Felvétel leállítása';

  @override
  String get a11ySwitchCamera => 'Kameraváltás';

  @override
  String get a11yMirrorAxis => 'Tükörtengely';

  @override
  String get a11yRotation => 'Kép forgatása';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees fok';
  }

  @override
  String get a11yClose => 'Bezárás';

  @override
  String get a11yToggleLog => 'Napló megjelenítése vagy elrejtése';

  @override
  String unlockAllFor(String price) {
    return 'Minden szűrő: $price';
  }
}
