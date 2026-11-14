// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get filterNone => 'بدون';

  @override
  String get filterGlow => 'توهج';

  @override
  String get filterSlim => 'نحيف';

  @override
  String get filterDoll => 'دمية';

  @override
  String get filterChibi => 'تشيبي';

  @override
  String get filterLips => 'شفاه';

  @override
  String get filterBigNose => 'أنف';

  @override
  String get filterAlien => 'فضائي';

  @override
  String get filterMelt => 'ذوبان';

  @override
  String get filterBigEars => 'آذان';

  @override
  String get filterLongNeck => 'رقبة';

  @override
  String get filterPencil => 'رصاص';

  @override
  String get filterComic => 'كوميك';

  @override
  String get filterGlitch => 'خلل';

  @override
  String get filterNeon => 'نيون';

  @override
  String get filterThermal => 'حرارة';

  @override
  String get filterOil => 'زيتي';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'بوب';

  @override
  String get filterVampire => 'مصاص دماء';

  @override
  String get filterZombie => 'زومبي';

  @override
  String get filterGhost => 'شبح';

  @override
  String get filterDemon => 'شيطان';

  @override
  String get filterCyborg => 'سايبورغ';

  @override
  String get filterFrozen => 'صقيع';

  @override
  String get collectionPretty => 'جميل';

  @override
  String get collectionUgly => 'قبيح';

  @override
  String get collectionArt => 'فن';

  @override
  String get collectionFantasy => 'خيال';

  @override
  String get collectionPacks => 'الحزم';

  @override
  String get packMosaic => 'فسيفساء';

  @override
  String get packHalftone => 'نقاط';

  @override
  String get packSketch => 'رسم';

  @override
  String get packOptics => 'بصريات';

  @override
  String get packKaleido => 'كاليدو';

  @override
  String get packTiles => 'بلاط';

  @override
  String get packGlitch => 'غليتش';

  @override
  String get packVhs => 'VHS';

  @override
  String get packFace => 'وجه';

  @override
  String get packLayers => 'طبقات';

  @override
  String get packPaint => 'رسم زيتي';

  @override
  String get packColor => 'ألوان';

  @override
  String get packLight => 'ضوء';

  @override
  String get audioEffectNone => 'عادي';

  @override
  String get audioEffectChiptune => '8 بت';

  @override
  String get audioEffectSlowMo => 'بطيء';

  @override
  String get audioEffectChipmunk => 'سنجاب';

  @override
  String get audioEffectEcho => 'صدى';

  @override
  String get audioEffectUnderwater => 'تحت الماء';

  @override
  String get audioEffectRobot => 'روبوت';

  @override
  String get audioEffectReverse => 'عكسي';

  @override
  String get mirrorSideLeftShort => 'يسار';

  @override
  String get mirrorSideRightShort => 'يمين';

  @override
  String get mirrorSideLeft => 'يسار';

  @override
  String get mirrorSideRight => 'يمين';

  @override
  String get lensFront => 'أمامية';

  @override
  String get lensBack => 'خلفية';

  @override
  String get photoSaveFailedTitle => 'تعذّر حفظ الصورة';

  @override
  String get ok => 'حسنًا';

  @override
  String get galleryAccessDenied => 'تم رفض الوصول إلى مكتبة الصور.';

  @override
  String get galleryNotEnoughSpace => 'لا توجد مساحة تخزين كافية.';

  @override
  String get galleryUnsupportedFormat => 'تنسيق الملف هذا غير مدعوم.';

  @override
  String get genericError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String shaderLoadError(String error) {
    return 'تعذّر تحميل الفلاتر: $error';
  }

  @override
  String get cameraPermissionDenied => 'تم رفض إذن الكاميرا';

  @override
  String get noCamerasAvailable => 'لا توجد كاميرات متاحة';

  @override
  String get cameraStartFailed => 'تعذّر تشغيل الكاميرا.';

  @override
  String get controlsHint => 'اسحب = تدوير  •  ⊙ = صورة  •  ● = فيديو';

  @override
  String get controlsHintVolume =>
      'الصوت = صورة  •  ضغط مطوّل على الصوت = فيديو';

  @override
  String collectionUnlocked(String collection) {
    return 'تم فتح مجموعة $collection ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'فلاتر $collection';
  }

  @override
  String get paywallPreviewFree =>
      'المعاينة مجانية. افتح القفل لحفظ الصور ومقاطع الفيديو.';

  @override
  String get storeUnavailable => 'المتجر غير متاح';

  @override
  String get loadingPrice => 'جارٍ تحميل السعر…';

  @override
  String unlockFor(String price) {
    return 'افتح مقابل $price';
  }

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get purchaseFailed => 'فشل الشراء';

  @override
  String get discardVideoTitle => 'هل تريد حذف الفيديو؟';

  @override
  String get discardVideoBody => 'لم يتم حفظ هذا التسجيل في ألبوم الكاميرا.';

  @override
  String get keep => 'الاحتفاظ';

  @override
  String get discard => 'حذف';

  @override
  String get processing => 'جارٍ المعالجة…';

  @override
  String get applyingEffect => 'جارٍ تطبيق التأثير…';

  @override
  String get saved => 'تم الحفظ ✓';

  @override
  String get saveToCameraRoll => 'حفظ في ألبوم الكاميرا';

  @override
  String get micPermissionRequired => 'يلزم إذن الميكروفون لتسجيل الفيديو.';

  @override
  String get recordingTooShort => 'التسجيل قصير جدًا — استمر لفترة أطول.';

  @override
  String get videoAssemblyFailed =>
      'تعذّر إنشاء الفيديو. يرجى المحاولة مرة أخرى.';

  @override
  String get audioEffectFailed => 'تعذّر تطبيق التأثير الصوتي.';

  @override
  String get roomEntryPrompt => 'أدخل معرّف الغرفة لبدء مكالمة فيديو منعكسة.';

  @override
  String get roomIdHint => 'معرّف الغرفة';

  @override
  String get mirrorSideTitle => 'جهة المرآة';

  @override
  String get joinCall => 'انضمام إلى المكالمة';

  @override
  String failedToJoin(String error) {
    return 'تعذّر الانضمام: $error';
  }

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String get share => 'مشاركة';

  @override
  String shareMessage(String url) {
    return 'صُنع باستخدام Mirror Booth:‏ $url';
  }

  @override
  String get a11yTakePhoto => 'التقاط صورة';

  @override
  String get a11yStartRecording => 'بدء تسجيل الفيديو';

  @override
  String get a11yStopRecording => 'إيقاف التسجيل';

  @override
  String get a11ySwitchCamera => 'تبديل الكاميرا';

  @override
  String get a11yMirrorAxis => 'محور المرآة';

  @override
  String get a11yRotation => 'تدوير الصورة';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees درجة';
  }

  @override
  String get a11yClose => 'إغلاق';

  @override
  String get a11yToggleLog => 'إظهار السجل أو إخفاؤه';

  @override
  String unlockAllFor(String price) {
    return 'كل الفلاتر مقابل $price';
  }

  @override
  String get a11ySettings => 'الإعدادات';

  @override
  String get statsToggle => 'إحصاءات استخدام مجهولة';

  @override
  String get statsToggleHint =>
      'تساعد على تحسين التطبيق. فقط الميزات المستخدمة ومدة استخدامها، ولا تشمل صورك أو أي شيء يحدد هويتك أبدًا.';
}
