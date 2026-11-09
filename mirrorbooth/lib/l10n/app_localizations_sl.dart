// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get filterNone => 'Brez';

  @override
  String get filterGlow => 'Sij';

  @override
  String get filterSlim => 'Vitkost';

  @override
  String get filterDoll => 'Punčka';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Ustnice';

  @override
  String get filterBigNose => 'Nos';

  @override
  String get filterAlien => 'Vesoljec';

  @override
  String get filterMelt => 'Taljenje';

  @override
  String get filterBigEars => 'Ušesa';

  @override
  String get filterLongNeck => 'Vrat';

  @override
  String get filterPencil => 'Svinčnik';

  @override
  String get filterComic => 'Strip';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Toplota';

  @override
  String get filterOil => 'Olje';

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
  String get collectionPretty => 'Lepota';

  @override
  String get collectionUgly => 'Grdost';

  @override
  String get collectionArt => 'Umetnost';

  @override
  String get collectionFantasy => 'Fantazija';

  @override
  String get audioEffectNone => 'Običajno';

  @override
  String get audioEffectChiptune => '8-bitno';

  @override
  String get audioEffectSlowMo => 'Počasi';

  @override
  String get audioEffectChipmunk => 'Veverica';

  @override
  String get audioEffectEcho => 'Odmev';

  @override
  String get audioEffectUnderwater => 'Pod vodo';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Nazaj';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Leva';

  @override
  String get mirrorSideRight => 'Desna';

  @override
  String get lensFront => 'SPREDAJ';

  @override
  String get lensBack => 'ZADAJ';

  @override
  String get photoSaveFailedTitle => 'Fotografije ni bilo mogoče shraniti';

  @override
  String get ok => 'V redu';

  @override
  String get galleryAccessDenied =>
      'Dostop do knjižnice fotografij je bil zavrnjen.';

  @override
  String get galleryNotEnoughSpace => 'Ni dovolj prostora za shranjevanje.';

  @override
  String get galleryUnsupportedFormat => 'Ta oblika datoteke ni podprta.';

  @override
  String get genericError => 'Prišlo je do napake. Poskusite znova.';

  @override
  String shaderLoadError(String error) {
    return 'Filtrov ni bilo mogoče naložiti: $error';
  }

  @override
  String get cameraPermissionDenied => 'Dostop do kamere je zavrnjen';

  @override
  String get noCamerasAvailable => 'Ni razpoložljivih kamer';

  @override
  String get cameraStartFailed => 'Kamere ni bilo mogoče zagnati.';

  @override
  String get controlsHint =>
      'povleci = zasukaj  •  ⊙ = fotografija  •  ● = video';

  @override
  String get controlsHintVolume => 'glasnost = fotografija  •  pridrži = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Zbirka $collection odklenjena ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtri $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Predogled je brezplačen. Odklenite za shranjevanje fotografij in videov.';

  @override
  String get storeUnavailable => 'Trgovina ni na voljo';

  @override
  String get loadingPrice => 'Nalaganje cene…';

  @override
  String unlockFor(String price) {
    return 'Odkleni za $price';
  }

  @override
  String get restorePurchases => 'Obnovi nakupe';

  @override
  String get purchaseFailed => 'Nakup ni uspel';

  @override
  String get discardVideoTitle => 'Zavrzi video?';

  @override
  String get discardVideoBody => 'Ta posnetek še ni shranjen v galerijo.';

  @override
  String get keep => 'Obdrži';

  @override
  String get discard => 'Zavrzi';

  @override
  String get processing => 'Obdelava…';

  @override
  String get applyingEffect => 'Uporaba učinka…';

  @override
  String get saved => 'Shranjeno ✓';

  @override
  String get saveToCameraRoll => 'Shrani v galerijo';

  @override
  String get micPermissionRequired =>
      'Za snemanje videa je potreben dostop do mikrofona.';

  @override
  String get recordingTooShort => 'Posnetek je prekratek — držite dlje.';

  @override
  String get videoAssemblyFailed =>
      'Videa ni bilo mogoče sestaviti. Poskusite znova.';

  @override
  String get audioEffectFailed => 'Zvočni učinek ni uspel.';

  @override
  String get roomEntryPrompt =>
      'Vnesite ID sobe za začetek zrcalnega video klica.';

  @override
  String get roomIdHint => 'ID sobe';

  @override
  String get mirrorSideTitle => 'Stran zrcala';

  @override
  String get joinCall => 'Pridruži se klicu';

  @override
  String failedToJoin(String error) {
    return 'Pridružitev ni uspela: $error';
  }

  @override
  String get connecting => 'Povezovanje…';

  @override
  String get share => 'Deli';

  @override
  String shareMessage(String url) {
    return 'Ustvarjeno z Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Fotografiraj';

  @override
  String get a11yStartRecording => 'Začni snemanje videa';

  @override
  String get a11yStopRecording => 'Ustavi snemanje';

  @override
  String get a11ySwitchCamera => 'Zamenjaj kamero';

  @override
  String get a11yMirrorAxis => 'Os zrcala';

  @override
  String get a11yRotation => 'Zasuk slike';

  @override
  String a11yDegrees(int degrees) {
    return 'Stopinje: $degrees';
  }

  @override
  String get a11yClose => 'Zapri';

  @override
  String get a11yToggleLog => 'Pokaži ali skrij dnevnik';

  @override
  String unlockAllFor(String price) {
    return 'Vsi filtri za $price';
  }
}
