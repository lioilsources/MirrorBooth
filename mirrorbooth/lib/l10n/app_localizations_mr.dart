// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get filterNone => 'काहीही नाही';

  @override
  String get filterGlow => 'चमक';

  @override
  String get filterSlim => 'बारीक';

  @override
  String get filterDoll => 'बाहुली';

  @override
  String get filterChibi => 'चिबी';

  @override
  String get filterLips => 'ओठ';

  @override
  String get filterBigNose => 'नाक';

  @override
  String get filterAlien => 'एलियन';

  @override
  String get filterMelt => 'वितळणे';

  @override
  String get filterBigEars => 'कान';

  @override
  String get filterLongNeck => 'मान';

  @override
  String get filterPencil => 'पेन्सिल';

  @override
  String get filterComic => 'कॉमिक';

  @override
  String get filterGlitch => 'ग्लिच';

  @override
  String get filterNeon => 'नियॉन';

  @override
  String get filterThermal => 'उष्णता';

  @override
  String get filterOil => 'ऑइल';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'पॉप';

  @override
  String get filterVampire => 'व्हॅम्पायर';

  @override
  String get filterZombie => 'झोंबी';

  @override
  String get filterGhost => 'भूत';

  @override
  String get filterDemon => 'राक्षस';

  @override
  String get filterCyborg => 'सायबॉर्ग';

  @override
  String get filterFrozen => 'बर्फ';

  @override
  String get collectionPretty => 'सुंदर';

  @override
  String get collectionUgly => 'कुरूप';

  @override
  String get collectionArt => 'कला';

  @override
  String get collectionFantasy => 'काल्पनिक';

  @override
  String get audioEffectNone => 'सामान्य';

  @override
  String get audioEffectChiptune => '8-बिट';

  @override
  String get audioEffectSlowMo => 'हळू';

  @override
  String get audioEffectChipmunk => 'खार';

  @override
  String get audioEffectEcho => 'प्रतिध्वनी';

  @override
  String get audioEffectUnderwater => 'पाण्याखाली';

  @override
  String get audioEffectRobot => 'रोबोट';

  @override
  String get audioEffectReverse => 'उलट';

  @override
  String get mirrorSideLeftShort => 'ड';

  @override
  String get mirrorSideRightShort => 'उ';

  @override
  String get mirrorSideLeft => 'डावी';

  @override
  String get mirrorSideRight => 'उजवी';

  @override
  String get lensFront => 'पुढचा';

  @override
  String get lensBack => 'मागचा';

  @override
  String get photoSaveFailedTitle => 'फोटो जतन करता आला नाही';

  @override
  String get ok => 'ठीक आहे';

  @override
  String get galleryAccessDenied => 'फोटो लायब्ररीचा प्रवेश नाकारला गेला.';

  @override
  String get galleryNotEnoughSpace => 'पुरेशी साठवण जागा नाही.';

  @override
  String get galleryUnsupportedFormat => 'हे फाइल स्वरूप समर्थित नाही.';

  @override
  String get genericError => 'काहीतरी चुकले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String shaderLoadError(String error) {
    return 'फिल्टर लोड करता आले नाहीत: $error';
  }

  @override
  String get cameraPermissionDenied => 'कॅमेरा परवानगी नाकारली';

  @override
  String get noCamerasAvailable => 'कॅमेरे उपलब्ध नाहीत';

  @override
  String get cameraStartFailed => 'कॅमेरा सुरू करता आला नाही.';

  @override
  String get controlsHint => 'ओढा = फिरवा  •  ⊙ = फोटो  •  ● = व्हिडिओ';

  @override
  String get controlsHintVolume =>
      'व्हॉल्यूम = फोटो  •  व्हॉल्यूम दाबून ठेवा = व्हिडिओ';

  @override
  String collectionUnlocked(String collection) {
    return '$collection संग्रह अनलॉक झाला ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection फिल्टर';
  }

  @override
  String get paywallPreviewFree =>
      'पूर्वावलोकन मोफत आहे. फोटो आणि व्हिडिओ जतन करण्यासाठी अनलॉक करा.';

  @override
  String get storeUnavailable => 'स्टोअर उपलब्ध नाही';

  @override
  String get loadingPrice => 'किंमत लोड होत आहे…';

  @override
  String unlockFor(String price) {
    return '$price मध्ये अनलॉक करा';
  }

  @override
  String get restorePurchases => 'खरेदी पुनर्संचयित करा';

  @override
  String get purchaseFailed => 'खरेदी अयशस्वी झाली';

  @override
  String get discardVideoTitle => 'व्हिडिओ टाकून द्यायचा?';

  @override
  String get discardVideoBody =>
      'हे रेकॉर्डिंग तुमच्या कॅमेरा रोलमध्ये जतन केलेले नाही.';

  @override
  String get keep => 'ठेवा';

  @override
  String get discard => 'टाकून द्या';

  @override
  String get processing => 'प्रक्रिया सुरू आहे…';

  @override
  String get applyingEffect => 'इफेक्ट लागू होत आहे…';

  @override
  String get saved => 'जतन केले ✓';

  @override
  String get saveToCameraRoll => 'कॅमेरा रोलमध्ये जतन करा';

  @override
  String get micPermissionRequired =>
      'व्हिडिओ रेकॉर्डिंगसाठी मायक्रोफोन परवानगी आवश्यक आहे.';

  @override
  String get recordingTooShort =>
      'रेकॉर्डिंग खूप लहान आहे — जास्त वेळ दाबून ठेवा.';

  @override
  String get videoAssemblyFailed =>
      'व्हिडिओ तयार करता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get audioEffectFailed => 'ऑडिओ इफेक्ट अयशस्वी झाला.';

  @override
  String get roomEntryPrompt =>
      'मिरर केलेला व्हिडिओ कॉल सुरू करण्यासाठी रूम आयडी टाका.';

  @override
  String get roomIdHint => 'रूम आयडी';

  @override
  String get mirrorSideTitle => 'आरशाची बाजू';

  @override
  String get joinCall => 'कॉलमध्ये सामील व्हा';

  @override
  String failedToJoin(String error) {
    return 'सामील होता आले नाही: $error';
  }

  @override
  String get connecting => 'कनेक्ट होत आहे…';

  @override
  String get share => 'शेअर करा';

  @override
  String shareMessage(String url) {
    return 'Mirror Booth ने बनवले: $url';
  }

  @override
  String get a11yTakePhoto => 'फोटो काढा';

  @override
  String get a11yStartRecording => 'व्हिडिओ रेकॉर्डिंग सुरू करा';

  @override
  String get a11yStopRecording => 'रेकॉर्डिंग थांबवा';

  @override
  String get a11ySwitchCamera => 'कॅमेरा बदला';

  @override
  String get a11yMirrorAxis => 'आरशाचा अक्ष';

  @override
  String get a11yRotation => 'प्रतिमा फिरवणे';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees अंश';
  }

  @override
  String get a11yClose => 'बंद करा';

  @override
  String get a11yToggleLog => 'लॉग दाखवा किंवा लपवा';

  @override
  String unlockAllFor(String price) {
    return 'सर्व फिल्टर $price मध्ये';
  }
}
