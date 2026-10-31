// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get filterNone => 'Nessuno';

  @override
  String get filterGlow => 'Bagliore';

  @override
  String get filterSlim => 'Snello';

  @override
  String get filterDoll => 'Bambola';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Labbra';

  @override
  String get filterBigNose => 'Naso';

  @override
  String get filterAlien => 'Alieno';

  @override
  String get filterMelt => 'Sciolto';

  @override
  String get filterBigEars => 'Orecchie';

  @override
  String get filterLongNeck => 'Collo';

  @override
  String get filterPencil => 'Matita';

  @override
  String get filterComic => 'Fumetto';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Calore';

  @override
  String get filterOil => 'Olio';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampiro';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Fantasma';

  @override
  String get filterDemon => 'Demone';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Gelo';

  @override
  String get collectionPretty => 'Bello';

  @override
  String get collectionUgly => 'Brutto';

  @override
  String get collectionArt => 'Arte';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normale';

  @override
  String get audioEffectChiptune => '8 bit';

  @override
  String get audioEffectSlowMo => 'Lento';

  @override
  String get audioEffectChipmunk => 'Scoiattolo';

  @override
  String get audioEffectEcho => 'Eco';

  @override
  String get audioEffectUnderwater => 'Sott’acqua';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Al contrario';

  @override
  String get mirrorSideLeftShort => 'S';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Sinistra';

  @override
  String get mirrorSideRight => 'Destra';

  @override
  String get lensFront => 'FRONTE';

  @override
  String get lensBack => 'RETRO';

  @override
  String get photoSaveFailedTitle => 'Impossibile salvare la foto';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'L’accesso alla libreria foto è stato negato.';

  @override
  String get galleryNotEnoughSpace => 'Spazio di archiviazione insufficiente.';

  @override
  String get galleryUnsupportedFormat =>
      'Questo formato di file non è supportato.';

  @override
  String get genericError => 'Qualcosa è andato storto. Riprova.';

  @override
  String shaderLoadError(String error) {
    return 'Impossibile caricare i filtri: $error';
  }

  @override
  String get cameraPermissionDenied => 'Autorizzazione fotocamera negata';

  @override
  String get noCamerasAvailable => 'Nessuna fotocamera disponibile';

  @override
  String get cameraStartFailed => 'Impossibile avviare la fotocamera.';

  @override
  String get controlsHint => 'trascina = ruota  •  ⊙ = foto  •  ● = video';

  @override
  String get controlsHintVolume =>
      'volume = foto  •  tieni premuto volume = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Collezione $collection sbloccata ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtri: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'L’anteprima è gratuita. Sblocca per salvare foto e video.';

  @override
  String get storeUnavailable => 'Store non disponibile';

  @override
  String get loadingPrice => 'Caricamento prezzo…';

  @override
  String unlockFor(String price) {
    return 'Sblocca a $price';
  }

  @override
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get purchaseFailed => 'Acquisto non riuscito';

  @override
  String get discardVideoTitle => 'Eliminare il video?';

  @override
  String get discardVideoBody =>
      'Questa registrazione non è stata salvata nel rullino.';

  @override
  String get keep => 'Tieni';

  @override
  String get discard => 'Elimina';

  @override
  String get processing => 'Elaborazione…';

  @override
  String get applyingEffect => 'Applicazione effetto…';

  @override
  String get saved => 'Salvato ✓';

  @override
  String get saveToCameraRoll => 'Salva nel rullino';

  @override
  String get micPermissionRequired =>
      'Per registrare video serve l’autorizzazione al microfono.';

  @override
  String get recordingTooShort =>
      'Registrazione troppo breve: registra più a lungo.';

  @override
  String get videoAssemblyFailed => 'Impossibile creare il video. Riprova.';

  @override
  String get audioEffectFailed => 'Effetto audio non riuscito.';

  @override
  String get roomEntryPrompt =>
      'Inserisci un ID stanza per avviare una videochiamata a specchio.';

  @override
  String get roomIdHint => 'ID stanza';

  @override
  String get mirrorSideTitle => 'Lato dello specchio';

  @override
  String get joinCall => 'Partecipa alla chiamata';

  @override
  String failedToJoin(String error) {
    return 'Impossibile partecipare: $error';
  }

  @override
  String get connecting => 'Connessione…';

  @override
  String get share => 'Condividi';

  @override
  String shareMessage(String url) {
    return 'Creato con Mirror Booth: $url';
  }
}
