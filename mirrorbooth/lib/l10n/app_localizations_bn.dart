// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get filterNone => 'কিছু না';

  @override
  String get filterGlow => 'উজ্জ্বল';

  @override
  String get filterSlim => 'স্লিম';

  @override
  String get filterDoll => 'পুতুল';

  @override
  String get filterChibi => 'চিবি';

  @override
  String get filterLips => 'ঠোঁট';

  @override
  String get filterBigNose => 'নাক';

  @override
  String get filterAlien => 'এলিয়েন';

  @override
  String get filterMelt => 'গলে যাওয়া';

  @override
  String get filterBigEars => 'কান';

  @override
  String get filterLongNeck => 'গলা';

  @override
  String get filterPencil => 'পেনসিল';

  @override
  String get filterComic => 'কমিক';

  @override
  String get filterGlitch => 'গ্লিচ';

  @override
  String get filterNeon => 'নিয়ন';

  @override
  String get filterThermal => 'তাপ';

  @override
  String get filterOil => 'তেলরং';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'পপ';

  @override
  String get filterVampire => 'ভ্যাম্পায়ার';

  @override
  String get filterZombie => 'জম্বি';

  @override
  String get filterGhost => 'ভূত';

  @override
  String get filterDemon => 'দানব';

  @override
  String get filterCyborg => 'সাইবর্গ';

  @override
  String get filterFrozen => 'তুষার';

  @override
  String get collectionPretty => 'সুন্দর';

  @override
  String get collectionUgly => 'কুৎসিত';

  @override
  String get collectionArt => 'শিল্প';

  @override
  String get collectionFantasy => 'ফ্যান্টাসি';

  @override
  String get audioEffectNone => 'সাধারণ';

  @override
  String get audioEffectChiptune => '৮-বিট';

  @override
  String get audioEffectSlowMo => 'ধীর';

  @override
  String get audioEffectChipmunk => 'চিপমাঙ্ক';

  @override
  String get audioEffectEcho => 'প্রতিধ্বনি';

  @override
  String get audioEffectUnderwater => 'পানির নিচে';

  @override
  String get audioEffectRobot => 'রোবট';

  @override
  String get audioEffectReverse => 'উল্টো';

  @override
  String get mirrorSideLeftShort => 'বাঁ';

  @override
  String get mirrorSideRightShort => 'ডান';

  @override
  String get mirrorSideLeft => 'বাঁ দিক';

  @override
  String get mirrorSideRight => 'ডান দিক';

  @override
  String get lensFront => 'সামনে';

  @override
  String get lensBack => 'পেছনে';

  @override
  String get photoSaveFailedTitle => 'ছবি সেভ করা যায়নি';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get galleryAccessDenied =>
      'ফটো লাইব্রেরিতে অ্যাক্সেস প্রত্যাখ্যান করা হয়েছে।';

  @override
  String get galleryNotEnoughSpace => 'যথেষ্ট স্টোরেজ নেই।';

  @override
  String get galleryUnsupportedFormat => 'এই ফাইল ফরম্যাট সমর্থিত নয়।';

  @override
  String get genericError => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String shaderLoadError(String error) {
    return 'ফিল্টার লোড করা যায়নি: $error';
  }

  @override
  String get cameraPermissionDenied => 'ক্যামেরার অনুমতি দেওয়া হয়নি';

  @override
  String get noCamerasAvailable => 'কোনো ক্যামেরা পাওয়া যায়নি';

  @override
  String get cameraStartFailed => 'ক্যামেরা চালু করা যায়নি।';

  @override
  String get controlsHint => 'টানুন = ঘোরান  •  ⊙ = ছবি  •  ● = ভিডিও';

  @override
  String get controlsHintVolume => 'ভলিউম = ছবি  •  ভলিউম চেপে ধরুন = ভিডিও';

  @override
  String collectionUnlocked(String collection) {
    return '$collection কালেকশন আনলক হয়েছে ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection ফিল্টার';
  }

  @override
  String get paywallPreviewFree =>
      'প্রিভিউ বিনামূল্যে। ছবি ও ভিডিও সেভ করতে আনলক করুন।';

  @override
  String get storeUnavailable => 'স্টোর পাওয়া যাচ্ছে না';

  @override
  String get loadingPrice => 'দাম লোড হচ্ছে…';

  @override
  String unlockFor(String price) {
    return '$price-এ আনলক করুন';
  }

  @override
  String get restorePurchases => 'কেনাকাটা পুনরুদ্ধার করুন';

  @override
  String get purchaseFailed => 'কেনা ব্যর্থ হয়েছে';

  @override
  String get discardVideoTitle => 'ভিডিওটি বাদ দেবেন?';

  @override
  String get discardVideoBody => 'এই রেকর্ডিংটি এখনও গ্যালারিতে সেভ হয়নি।';

  @override
  String get keep => 'রাখুন';

  @override
  String get discard => 'বাদ দিন';

  @override
  String get processing => 'প্রসেস হচ্ছে…';

  @override
  String get applyingEffect => 'ইফেক্ট যোগ হচ্ছে…';

  @override
  String get saved => 'সেভ হয়েছে ✓';

  @override
  String get saveToCameraRoll => 'গ্যালারিতে সেভ করুন';

  @override
  String get micPermissionRequired =>
      'ভিডিও রেকর্ড করতে মাইক্রোফোনের অনুমতি দরকার।';

  @override
  String get recordingTooShort => 'রেকর্ডিং খুব ছোট — আরও বেশিক্ষণ চেপে ধরুন।';

  @override
  String get videoAssemblyFailed => 'ভিডিও তৈরি করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get audioEffectFailed => 'অডিও ইফেক্ট ব্যর্থ হয়েছে।';

  @override
  String get roomEntryPrompt => 'মিরর ভিডিও কল শুরু করতে একটি রুম আইডি লিখুন।';

  @override
  String get roomIdHint => 'রুম আইডি';

  @override
  String get mirrorSideTitle => 'আয়নার দিক';

  @override
  String get joinCall => 'কলে যোগ দিন';

  @override
  String failedToJoin(String error) {
    return 'যোগ দেওয়া যায়নি: $error';
  }

  @override
  String get connecting => 'সংযোগ হচ্ছে…';

  @override
  String get share => 'শেয়ার করুন';

  @override
  String shareMessage(String url) {
    return 'Mirror Booth দিয়ে তৈরি: $url';
  }

  @override
  String get a11yTakePhoto => 'ছবি তুলুন';

  @override
  String get a11yStartRecording => 'ভিডিও রেকর্ডিং শুরু করুন';

  @override
  String get a11yStopRecording => 'রেকর্ডিং বন্ধ করুন';

  @override
  String get a11ySwitchCamera => 'ক্যামেরা বদলান';

  @override
  String get a11yMirrorAxis => 'আয়নার অক্ষ';

  @override
  String get a11yRotation => 'ছবির ঘূর্ণন';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees ডিগ্রি';
  }

  @override
  String get a11yClose => 'বন্ধ করুন';

  @override
  String get a11yToggleLog => 'লগ দেখান বা লুকান';

  @override
  String unlockAllFor(String price) {
    return '$price-এ সব ফিল্টার';
  }
}
