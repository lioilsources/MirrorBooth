// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get filterNone => 'இல்லை';

  @override
  String get filterGlow => 'ஒளிர்வு';

  @override
  String get filterSlim => 'ஒல்லி';

  @override
  String get filterDoll => 'பொம்மை';

  @override
  String get filterChibi => 'சிபி';

  @override
  String get filterLips => 'உதடுகள்';

  @override
  String get filterBigNose => 'மூக்கு';

  @override
  String get filterAlien => 'ஏலியன்';

  @override
  String get filterMelt => 'உருகல்';

  @override
  String get filterBigEars => 'காதுகள்';

  @override
  String get filterLongNeck => 'கழுத்து';

  @override
  String get filterPencil => 'பென்சில்';

  @override
  String get filterComic => 'காமிக்';

  @override
  String get filterGlitch => 'கிளிட்ச்';

  @override
  String get filterNeon => 'நியான்';

  @override
  String get filterThermal => 'வெப்பம்';

  @override
  String get filterOil => 'எண்ணெய்';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'பாப்';

  @override
  String get filterVampire => 'வாம்பயர்';

  @override
  String get filterZombie => 'ஜாம்பி';

  @override
  String get filterGhost => 'பேய்';

  @override
  String get filterDemon => 'அரக்கன்';

  @override
  String get filterCyborg => 'சைபோர்க்';

  @override
  String get filterFrozen => 'பனி';

  @override
  String get collectionPretty => 'அழகு';

  @override
  String get collectionUgly => 'அசிங்கம்';

  @override
  String get collectionArt => 'கலை';

  @override
  String get collectionFantasy => 'கற்பனை';

  @override
  String get audioEffectNone => 'இயல்பு';

  @override
  String get audioEffectChiptune => '8-பிட்';

  @override
  String get audioEffectSlowMo => 'மெதுவாக';

  @override
  String get audioEffectChipmunk => 'அணில்';

  @override
  String get audioEffectEcho => 'எதிரொலி';

  @override
  String get audioEffectUnderwater => 'நீருக்கடியில்';

  @override
  String get audioEffectRobot => 'ரோபோ';

  @override
  String get audioEffectReverse => 'தலைகீழ்';

  @override
  String get mirrorSideLeftShort => 'இ';

  @override
  String get mirrorSideRightShort => 'வ';

  @override
  String get mirrorSideLeft => 'இடது';

  @override
  String get mirrorSideRight => 'வலது';

  @override
  String get lensFront => 'முன்';

  @override
  String get lensBack => 'பின்';

  @override
  String get photoSaveFailedTitle => 'புகைப்படத்தைச் சேமிக்க முடியவில்லை';

  @override
  String get ok => 'சரி';

  @override
  String get galleryAccessDenied =>
      'புகைப்பட நூலகத்திற்கான அணுகல் மறுக்கப்பட்டது.';

  @override
  String get galleryNotEnoughSpace => 'போதுமான சேமிப்பிடம் இல்லை.';

  @override
  String get galleryUnsupportedFormat =>
      'இந்தக் கோப்பு வடிவம் ஆதரிக்கப்படவில்லை.';

  @override
  String get genericError => 'ஏதோ தவறு நடந்தது. மீண்டும் முயலவும்.';

  @override
  String shaderLoadError(String error) {
    return 'வடிப்பான்களை ஏற்ற முடியவில்லை: $error';
  }

  @override
  String get cameraPermissionDenied => 'கேமரா அனுமதி மறுக்கப்பட்டது';

  @override
  String get noCamerasAvailable => 'கேமராக்கள் இல்லை';

  @override
  String get cameraStartFailed => 'கேமராவைத் தொடங்க முடியவில்லை.';

  @override
  String get controlsHint => 'இழு = சுழற்று  •  ⊙ = புகைப்படம்  •  ● = வீடியோ';

  @override
  String get controlsHintVolume =>
      'ஒலி = புகைப்படம்  •  ஒலி அழுத்திப்பிடி = வீடியோ';

  @override
  String collectionUnlocked(String collection) {
    return '$collection தொகுப்பு திறக்கப்பட்டது ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection வடிப்பான்கள்';
  }

  @override
  String get paywallPreviewFree =>
      'முன்னோட்டம் இலவசம். புகைப்படங்களையும் வீடியோக்களையும் சேமிக்க திறக்கவும்.';

  @override
  String get storeUnavailable => 'ஸ்டோர் கிடைக்கவில்லை';

  @override
  String get loadingPrice => 'விலை ஏற்றப்படுகிறது…';

  @override
  String unlockFor(String price) {
    return '$priceக்குத் திற';
  }

  @override
  String get restorePurchases => 'வாங்கியவற்றை மீட்டமை';

  @override
  String get purchaseFailed => 'வாங்குதல் தோல்வியடைந்தது';

  @override
  String get discardVideoTitle => 'வீடியோவை நிராகரிக்கவா?';

  @override
  String get discardVideoBody =>
      'இந்தப் பதிவு உங்கள் கேமரா ரோலில் சேமிக்கப்படவில்லை.';

  @override
  String get keep => 'வைத்திரு';

  @override
  String get discard => 'நிராகரி';

  @override
  String get processing => 'செயலாக்குகிறது…';

  @override
  String get applyingEffect => 'விளைவைப் பயன்படுத்துகிறது…';

  @override
  String get saved => 'சேமிக்கப்பட்டது ✓';

  @override
  String get saveToCameraRoll => 'கேமரா ரோலில் சேமி';

  @override
  String get micPermissionRequired =>
      'வீடியோ பதிவுக்கு மைக்ரோஃபோன் அனுமதி தேவை.';

  @override
  String get recordingTooShort =>
      'பதிவு மிகக் குறுகியது — நீண்ட நேரம் பிடிக்கவும்.';

  @override
  String get videoAssemblyFailed =>
      'வீடியோவை உருவாக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get audioEffectFailed => 'ஒலி விளைவு தோல்வியடைந்தது.';

  @override
  String get roomEntryPrompt =>
      'பிரதிபலிக்கும் வீடியோ அழைப்பைத் தொடங்க அறை ஐடியை உள்ளிடவும்.';

  @override
  String get roomIdHint => 'அறை ஐடி';

  @override
  String get mirrorSideTitle => 'கண்ணாடிப் பக்கம்';

  @override
  String get joinCall => 'அழைப்பில் சேர்';

  @override
  String failedToJoin(String error) {
    return 'சேர முடியவில்லை: $error';
  }

  @override
  String get connecting => 'இணைக்கிறது…';

  @override
  String get share => 'பகிர்';

  @override
  String shareMessage(String url) {
    return 'Mirror Booth மூலம் உருவாக்கப்பட்டது: $url';
  }

  @override
  String get a11yTakePhoto => 'புகைப்படம் எடு';

  @override
  String get a11yStartRecording => 'வீடியோ பதிவைத் தொடங்கு';

  @override
  String get a11yStopRecording => 'பதிவை நிறுத்து';

  @override
  String get a11ySwitchCamera => 'கேமராவை மாற்று';

  @override
  String get a11yMirrorAxis => 'கண்ணாடி அச்சு';

  @override
  String get a11yRotation => 'படச் சுழற்சி';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees டிகிரி';
  }

  @override
  String get a11yClose => 'மூடு';

  @override
  String get a11yToggleLog => 'பதிவைக் காட்டு அல்லது மறை';

  @override
  String unlockAllFor(String price) {
    return 'அனைத்து வடிப்பான்களும் $priceக்கு';
  }
}
