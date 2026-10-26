// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get filterNone => 'Nenhum';

  @override
  String get filterGlow => 'Brilho';

  @override
  String get filterSlim => 'Magro';

  @override
  String get filterDoll => 'Boneca';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Lábios';

  @override
  String get filterBigNose => 'Nariz';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Derreter';

  @override
  String get filterBigEars => 'Orelhas';

  @override
  String get filterLongNeck => 'Pescoço';

  @override
  String get filterPencil => 'Lápis';

  @override
  String get filterComic => 'HQ';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Calor';

  @override
  String get filterOil => 'Óleo';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampiro';

  @override
  String get filterZombie => 'Zumbi';

  @override
  String get filterGhost => 'Fantasma';

  @override
  String get filterDemon => 'Demônio';

  @override
  String get filterCyborg => 'Ciborgue';

  @override
  String get filterFrozen => 'Gelo';

  @override
  String get collectionPretty => 'Bonito';

  @override
  String get collectionUgly => 'Feio';

  @override
  String get collectionArt => 'Arte';

  @override
  String get collectionFantasy => 'Fantasia';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8 bits';

  @override
  String get audioEffectSlowMo => 'Lento';

  @override
  String get audioEffectChipmunk => 'Esquilo';

  @override
  String get audioEffectEcho => 'Eco';

  @override
  String get audioEffectUnderwater => 'Debaixo d’água';

  @override
  String get audioEffectRobot => 'Robô';

  @override
  String get audioEffectReverse => 'Ao contrário';

  @override
  String get mirrorSideLeftShort => 'E';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Esquerda';

  @override
  String get mirrorSideRight => 'Direita';

  @override
  String get lensFront => 'FRONTAL';

  @override
  String get lensBack => 'TRASEIRA';

  @override
  String get photoSaveFailedTitle => 'Não foi possível salvar a foto';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'O acesso à galeria de fotos foi negado.';

  @override
  String get galleryNotEnoughSpace => 'Espaço de armazenamento insuficiente.';

  @override
  String get galleryUnsupportedFormat =>
      'Este formato de arquivo não é compatível.';

  @override
  String get genericError => 'Algo deu errado. Tente novamente.';

  @override
  String shaderLoadError(String error) {
    return 'Não foi possível carregar os filtros: $error';
  }

  @override
  String get cameraPermissionDenied => 'Permissão da câmera negada';

  @override
  String get noCamerasAvailable => 'Nenhuma câmera disponível';

  @override
  String get cameraStartFailed => 'Não foi possível iniciar a câmera.';

  @override
  String get controlsHint => 'arrastar = girar  •  ⊙ = foto  •  ● = vídeo';

  @override
  String get controlsHintVolume => 'volume = foto  •  segurar volume = vídeo';

  @override
  String collectionUnlocked(String collection) {
    return 'Coleção $collection desbloqueada ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtros: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'A prévia é grátis. Desbloqueie para salvar fotos e vídeos.';

  @override
  String get storeUnavailable => 'Loja indisponível';

  @override
  String get loadingPrice => 'Carregando preço…';

  @override
  String unlockFor(String price) {
    return 'Desbloquear por $price';
  }

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchaseFailed => 'Falha na compra';

  @override
  String get discardVideoTitle => 'Descartar vídeo?';

  @override
  String get discardVideoBody =>
      'Esta gravação não foi salva no rolo da câmera.';

  @override
  String get keep => 'Manter';

  @override
  String get discard => 'Descartar';

  @override
  String get processing => 'Processando…';

  @override
  String get applyingEffect => 'Aplicando efeito…';

  @override
  String get saved => 'Salvo ✓';

  @override
  String get saveToCameraRoll => 'Salvar no rolo da câmera';

  @override
  String get micPermissionRequired =>
      'É necessária permissão do microfone para gravar vídeos.';

  @override
  String get recordingTooShort =>
      'Gravação muito curta — grave por mais tempo.';

  @override
  String get videoAssemblyFailed =>
      'Não foi possível criar o vídeo. Tente novamente.';

  @override
  String get audioEffectFailed => 'Falha no efeito de áudio.';

  @override
  String get roomEntryPrompt =>
      'Digite o ID da sala para iniciar uma videochamada espelhada.';

  @override
  String get roomIdHint => 'ID da sala';

  @override
  String get mirrorSideTitle => 'Lado do espelho';

  @override
  String get joinCall => 'Entrar na chamada';

  @override
  String failedToJoin(String error) {
    return 'Não foi possível entrar: $error';
  }

  @override
  String get connecting => 'Conectando…';
}
