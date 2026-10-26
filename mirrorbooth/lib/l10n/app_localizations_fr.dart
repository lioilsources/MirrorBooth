// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get filterNone => 'Aucun';

  @override
  String get filterGlow => 'Éclat';

  @override
  String get filterSlim => 'Mince';

  @override
  String get filterDoll => 'Poupée';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Lèvres';

  @override
  String get filterBigNose => 'Nez';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Fondu';

  @override
  String get filterBigEars => 'Oreilles';

  @override
  String get filterLongNeck => 'Cou';

  @override
  String get filterPencil => 'Crayon';

  @override
  String get filterComic => 'BD';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Néon';

  @override
  String get filterThermal => 'Chaleur';

  @override
  String get filterOil => 'Huile';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampire';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Fantôme';

  @override
  String get filterDemon => 'Démon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Givre';

  @override
  String get collectionPretty => 'Joli';

  @override
  String get collectionUgly => 'Moche';

  @override
  String get collectionArt => 'Art';

  @override
  String get collectionFantasy => 'Fantastique';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8 bits';

  @override
  String get audioEffectSlowMo => 'Ralenti';

  @override
  String get audioEffectChipmunk => 'Écureuil';

  @override
  String get audioEffectEcho => 'Écho';

  @override
  String get audioEffectUnderwater => 'Sous l’eau';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'À l’envers';

  @override
  String get mirrorSideLeftShort => 'G';

  @override
  String get mirrorSideRightShort => 'D';

  @override
  String get mirrorSideLeft => 'Gauche';

  @override
  String get mirrorSideRight => 'Droite';

  @override
  String get lensFront => 'AVANT';

  @override
  String get lensBack => 'ARRIÈRE';

  @override
  String get photoSaveFailedTitle => 'Impossible d’enregistrer la photo';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'L’accès à la photothèque a été refusé.';

  @override
  String get galleryNotEnoughSpace => 'Espace de stockage insuffisant.';

  @override
  String get galleryUnsupportedFormat =>
      'Ce format de fichier n’est pas pris en charge.';

  @override
  String get genericError => 'Une erreur s’est produite. Veuillez réessayer.';

  @override
  String shaderLoadError(String error) {
    return 'Impossible de charger les filtres : $error';
  }

  @override
  String get cameraPermissionDenied => 'Accès à la caméra refusé';

  @override
  String get noCamerasAvailable => 'Aucune caméra disponible';

  @override
  String get cameraStartFailed => 'Impossible de démarrer la caméra.';

  @override
  String get controlsHint => 'glisser = pivoter  •  ⊙ = photo  •  ● = vidéo';

  @override
  String get controlsHintVolume =>
      'volume = photo  •  maintenir volume = vidéo';

  @override
  String collectionUnlocked(String collection) {
    return 'Collection $collection débloquée ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filtres « $collection »';
  }

  @override
  String get paywallPreviewFree =>
      'L’aperçu est gratuit. Débloquez pour enregistrer photos et vidéos.';

  @override
  String get storeUnavailable => 'Boutique indisponible';

  @override
  String get loadingPrice => 'Chargement du prix…';

  @override
  String unlockFor(String price) {
    return 'Débloquer pour $price';
  }

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get purchaseFailed => 'Échec de l’achat';

  @override
  String get discardVideoTitle => 'Supprimer la vidéo ?';

  @override
  String get discardVideoBody =>
      'Cet enregistrement n’a pas été sauvegardé dans votre pellicule.';

  @override
  String get keep => 'Garder';

  @override
  String get discard => 'Supprimer';

  @override
  String get processing => 'Traitement…';

  @override
  String get applyingEffect => 'Application de l’effet…';

  @override
  String get saved => 'Enregistré ✓';

  @override
  String get saveToCameraRoll => 'Enregistrer dans la pellicule';

  @override
  String get micPermissionRequired =>
      'L’accès au micro est requis pour enregistrer des vidéos.';

  @override
  String get recordingTooShort =>
      'Enregistrement trop court — filmez plus longtemps.';

  @override
  String get videoAssemblyFailed =>
      'La création de la vidéo a échoué. Veuillez réessayer.';

  @override
  String get audioEffectFailed => 'Échec de l’effet audio.';

  @override
  String get roomEntryPrompt =>
      'Saisissez un identifiant de salon pour lancer un appel vidéo en miroir.';

  @override
  String get roomIdHint => 'Identifiant du salon';

  @override
  String get mirrorSideTitle => 'Côté du miroir';

  @override
  String get joinCall => 'Rejoindre l’appel';

  @override
  String failedToJoin(String error) {
    return 'Impossible de rejoindre : $error';
  }

  @override
  String get connecting => 'Connexion…';
}
