// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get filterNone => 'कोई नहीं';

  @override
  String get filterGlow => 'चमक';

  @override
  String get filterSlim => 'पतला';

  @override
  String get filterDoll => 'गुड़िया';

  @override
  String get filterChibi => 'चिबी';

  @override
  String get filterLips => 'होंठ';

  @override
  String get filterBigNose => 'नाक';

  @override
  String get filterAlien => 'एलियन';

  @override
  String get filterMelt => 'पिघलना';

  @override
  String get filterBigEars => 'कान';

  @override
  String get filterLongNeck => 'गर्दन';

  @override
  String get filterPencil => 'पेंसिल';

  @override
  String get filterComic => 'कॉमिक';

  @override
  String get filterGlitch => 'ग्लिच';

  @override
  String get filterNeon => 'नियॉन';

  @override
  String get filterThermal => 'ताप';

  @override
  String get filterOil => 'तैल';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'पॉप';

  @override
  String get filterVampire => 'पिशाच';

  @override
  String get filterZombie => 'ज़ॉम्बी';

  @override
  String get filterGhost => 'भूत';

  @override
  String get filterDemon => 'दानव';

  @override
  String get filterCyborg => 'साइबोर्ग';

  @override
  String get filterFrozen => 'पाला';

  @override
  String get collectionPretty => 'सुंदर';

  @override
  String get collectionUgly => 'बदसूरत';

  @override
  String get collectionArt => 'कला';

  @override
  String get collectionFantasy => 'फ़ैंटेसी';

  @override
  String get audioEffectNone => 'सामान्य';

  @override
  String get audioEffectChiptune => '8-बिट';

  @override
  String get audioEffectSlowMo => 'धीमा';

  @override
  String get audioEffectChipmunk => 'गिलहरी';

  @override
  String get audioEffectEcho => 'गूँज';

  @override
  String get audioEffectUnderwater => 'पानी के नीचे';

  @override
  String get audioEffectRobot => 'रोबोट';

  @override
  String get audioEffectReverse => 'उल्टा';

  @override
  String get mirrorSideLeftShort => 'बाएँ';

  @override
  String get mirrorSideRightShort => 'दाएँ';

  @override
  String get mirrorSideLeft => 'बायाँ';

  @override
  String get mirrorSideRight => 'दायाँ';

  @override
  String get lensFront => 'आगे';

  @override
  String get lensBack => 'पीछे';

  @override
  String get photoSaveFailedTitle => 'फ़ोटो सेव नहीं हो सकी';

  @override
  String get ok => 'ठीक है';

  @override
  String get galleryAccessDenied =>
      'फ़ोटो लाइब्रेरी तक पहुँच अस्वीकार कर दी गई।';

  @override
  String get galleryNotEnoughSpace => 'पर्याप्त स्टोरेज नहीं है।';

  @override
  String get galleryUnsupportedFormat => 'यह फ़ाइल फ़ॉर्मैट समर्थित नहीं है।';

  @override
  String get genericError => 'कुछ गड़बड़ हो गई। कृपया फिर से कोशिश करें।';

  @override
  String shaderLoadError(String error) {
    return 'फ़िल्टर लोड नहीं हो सके: $error';
  }

  @override
  String get cameraPermissionDenied => 'कैमरा अनुमति अस्वीकृत';

  @override
  String get noCamerasAvailable => 'कोई कैमरा उपलब्ध नहीं है';

  @override
  String get cameraStartFailed => 'कैमरा शुरू नहीं हो सका।';

  @override
  String get controlsHint => 'खींचें = घुमाएँ  •  ⊙ = फ़ोटो  •  ● = वीडियो';

  @override
  String get controlsHintVolume =>
      'वॉल्यूम = फ़ोटो  •  वॉल्यूम दबाए रखें = वीडियो';

  @override
  String collectionUnlocked(String collection) {
    return '$collection संग्रह अनलॉक हो गया ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection फ़िल्टर';
  }

  @override
  String get paywallPreviewFree =>
      'प्रीव्यू मुफ़्त है। फ़ोटो और वीडियो सेव करने के लिए अनलॉक करें।';

  @override
  String get storeUnavailable => 'स्टोर उपलब्ध नहीं है';

  @override
  String get loadingPrice => 'कीमत लोड हो रही है…';

  @override
  String unlockFor(String price) {
    return '$price में अनलॉक करें';
  }

  @override
  String get restorePurchases => 'खरीदारी पुनर्स्थापित करें';

  @override
  String get purchaseFailed => 'खरीदारी विफल रही';

  @override
  String get discardVideoTitle => 'वीडियो हटाएँ?';

  @override
  String get discardVideoBody =>
      'यह रिकॉर्डिंग आपकी गैलरी में सेव नहीं हुई है।';

  @override
  String get keep => 'रखें';

  @override
  String get discard => 'हटाएँ';

  @override
  String get processing => 'प्रोसेस हो रहा है…';

  @override
  String get applyingEffect => 'इफ़ेक्ट लगाया जा रहा है…';

  @override
  String get saved => 'सेव हो गया ✓';

  @override
  String get saveToCameraRoll => 'गैलरी में सेव करें';

  @override
  String get micPermissionRequired =>
      'वीडियो रिकॉर्डिंग के लिए माइक्रोफ़ोन अनुमति ज़रूरी है।';

  @override
  String get recordingTooShort =>
      'रिकॉर्डिंग बहुत छोटी है — थोड़ी देर और रिकॉर्ड करें।';

  @override
  String get videoAssemblyFailed =>
      'वीडियो नहीं बन सका। कृपया फिर से कोशिश करें।';

  @override
  String get audioEffectFailed => 'ऑडियो इफ़ेक्ट लागू नहीं हो सका।';

  @override
  String get roomEntryPrompt =>
      'मिरर वीडियो कॉल शुरू करने के लिए रूम आईडी डालें।';

  @override
  String get roomIdHint => 'रूम आईडी';

  @override
  String get mirrorSideTitle => 'मिरर की तरफ़';

  @override
  String get joinCall => 'कॉल में जुड़ें';

  @override
  String failedToJoin(String error) {
    return 'जुड़ नहीं सके: $error';
  }

  @override
  String get connecting => 'कनेक्ट हो रहा है…';

  @override
  String get share => 'शेयर करें';

  @override
  String shareMessage(String url) {
    return 'Mirror Booth से बनाया गया: $url';
  }
}
