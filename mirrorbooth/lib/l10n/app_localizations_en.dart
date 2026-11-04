// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get filterNone => 'None';

  @override
  String get filterGlow => 'Glow';

  @override
  String get filterSlim => 'Slim';

  @override
  String get filterDoll => 'Doll';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Lips';

  @override
  String get filterBigNose => 'Nose';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Melt';

  @override
  String get filterBigEars => 'Ears';

  @override
  String get filterLongNeck => 'Neck';

  @override
  String get filterPencil => 'Pencil';

  @override
  String get filterComic => 'Comic';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Heat';

  @override
  String get filterOil => 'Oil';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vamp';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Ghost';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Frost';

  @override
  String get collectionPretty => 'Pretty';

  @override
  String get collectionUgly => 'Ugly';

  @override
  String get collectionArt => 'Art';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Slow';

  @override
  String get audioEffectChipmunk => 'Chipmunk';

  @override
  String get audioEffectEcho => 'Echo';

  @override
  String get audioEffectUnderwater => 'Underwater';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Reverse';

  @override
  String get mirrorSideLeftShort => 'L';

  @override
  String get mirrorSideRightShort => 'R';

  @override
  String get mirrorSideLeft => 'Left';

  @override
  String get mirrorSideRight => 'Right';

  @override
  String get lensFront => 'FRONT';

  @override
  String get lensBack => 'BACK';

  @override
  String get photoSaveFailedTitle => 'Could not save photo';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Access to the photo library was denied.';

  @override
  String get galleryNotEnoughSpace => 'Not enough storage space.';

  @override
  String get galleryUnsupportedFormat => 'This file format is not supported.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String shaderLoadError(String error) {
    return 'Could not load filters: $error';
  }

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String get noCamerasAvailable => 'No cameras available';

  @override
  String get cameraStartFailed => 'Could not start the camera.';

  @override
  String get controlsHint => 'drag = rotate  •  ⊙ = photo  •  ● = video';

  @override
  String get controlsHintVolume => 'vol = photo  •  vol hold = video';

  @override
  String collectionUnlocked(String collection) {
    return '$collection collection unlocked ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection filters';
  }

  @override
  String get paywallPreviewFree =>
      'Preview is free. Unlock to save photos and videos.';

  @override
  String get storeUnavailable => 'Store unavailable';

  @override
  String get loadingPrice => 'Loading price…';

  @override
  String unlockFor(String price) {
    return 'Unlock for $price';
  }

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get purchaseFailed => 'Purchase failed';

  @override
  String get discardVideoTitle => 'Discard video?';

  @override
  String get discardVideoBody =>
      'This recording has not been saved to your camera roll.';

  @override
  String get keep => 'Keep';

  @override
  String get discard => 'Discard';

  @override
  String get processing => 'Processing…';

  @override
  String get applyingEffect => 'Applying effect…';

  @override
  String get saved => 'Saved ✓';

  @override
  String get saveToCameraRoll => 'Save to Camera Roll';

  @override
  String get micPermissionRequired =>
      'Microphone permission required for video recording.';

  @override
  String get recordingTooShort => 'Recording too short — hold longer.';

  @override
  String get videoAssemblyFailed => 'Video assembly failed. Please try again.';

  @override
  String get audioEffectFailed => 'Audio effect failed.';

  @override
  String get roomEntryPrompt =>
      'Enter a room ID to start a mirrored video call.';

  @override
  String get roomIdHint => 'Room ID';

  @override
  String get mirrorSideTitle => 'Mirror side';

  @override
  String get joinCall => 'Join call';

  @override
  String failedToJoin(String error) {
    return 'Failed to join: $error';
  }

  @override
  String get connecting => 'Connecting…';

  @override
  String get share => 'Share';

  @override
  String shareMessage(String url) {
    return 'Made with Mirror Booth: $url';
  }
}
