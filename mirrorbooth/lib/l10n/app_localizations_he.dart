// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get filterNone => 'ללא';

  @override
  String get filterGlow => 'זוהר';

  @override
  String get filterSlim => 'רזה';

  @override
  String get filterDoll => 'בובה';

  @override
  String get filterChibi => 'צ\'יבי';

  @override
  String get filterLips => 'שפתיים';

  @override
  String get filterBigNose => 'אף';

  @override
  String get filterAlien => 'חייזר';

  @override
  String get filterMelt => 'התכה';

  @override
  String get filterBigEars => 'אוזניים';

  @override
  String get filterLongNeck => 'צוואר';

  @override
  String get filterPencil => 'עיפרון';

  @override
  String get filterComic => 'קומיקס';

  @override
  String get filterGlitch => 'גליץ\'';

  @override
  String get filterNeon => 'ניאון';

  @override
  String get filterThermal => 'חום';

  @override
  String get filterOil => 'שמן';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'פופ';

  @override
  String get filterVampire => 'ערפד';

  @override
  String get filterZombie => 'זומבי';

  @override
  String get filterGhost => 'רוח רפאים';

  @override
  String get filterDemon => 'שד';

  @override
  String get filterCyborg => 'סייבורג';

  @override
  String get filterFrozen => 'כפור';

  @override
  String get collectionPretty => 'יפה';

  @override
  String get collectionUgly => 'מכוער';

  @override
  String get collectionArt => 'אמנות';

  @override
  String get collectionFantasy => 'פנטזיה';

  @override
  String get audioEffectNone => 'רגיל';

  @override
  String get audioEffectChiptune => '8 ביט';

  @override
  String get audioEffectSlowMo => 'איטי';

  @override
  String get audioEffectChipmunk => 'סנאי';

  @override
  String get audioEffectEcho => 'הד';

  @override
  String get audioEffectUnderwater => 'מתחת למים';

  @override
  String get audioEffectRobot => 'רובוט';

  @override
  String get audioEffectReverse => 'הפוך';

  @override
  String get mirrorSideLeftShort => 'ש';

  @override
  String get mirrorSideRightShort => 'י';

  @override
  String get mirrorSideLeft => 'שמאל';

  @override
  String get mirrorSideRight => 'ימין';

  @override
  String get lensFront => 'קדמית';

  @override
  String get lensBack => 'אחורית';

  @override
  String get photoSaveFailedTitle => 'לא ניתן לשמור את התמונה';

  @override
  String get ok => 'אישור';

  @override
  String get galleryAccessDenied => 'הגישה לספריית התמונות נדחתה.';

  @override
  String get galleryNotEnoughSpace => 'אין מספיק שטח אחסון.';

  @override
  String get galleryUnsupportedFormat => 'פורמט הקובץ אינו נתמך.';

  @override
  String get genericError => 'משהו השתבש. נסו שוב.';

  @override
  String shaderLoadError(String error) {
    return 'לא ניתן לטעון את המסננים: $error';
  }

  @override
  String get cameraPermissionDenied => 'הגישה למצלמה נדחתה';

  @override
  String get noCamerasAvailable => 'אין מצלמה זמינה';

  @override
  String get cameraStartFailed => 'לא ניתן להפעיל את המצלמה.';

  @override
  String get controlsHint => 'גרירה = סיבוב  •  ⊙ = תמונה  •  ● = וידאו';

  @override
  String get controlsHintVolume => 'עוצמה = תמונה  •  לחיצה ארוכה = וידאו';

  @override
  String collectionUnlocked(String collection) {
    return 'אוסף $collection נפתח ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'מסנני $collection';
  }

  @override
  String get paywallPreviewFree =>
      'התצוגה המקדימה בחינם. פתחו את האוסף כדי לשמור תמונות וסרטונים.';

  @override
  String get storeUnavailable => 'החנות אינה זמינה';

  @override
  String get loadingPrice => 'טוען מחיר…';

  @override
  String unlockFor(String price) {
    return 'פתיחה ב-$price';
  }

  @override
  String get restorePurchases => 'שחזור רכישות';

  @override
  String get purchaseFailed => 'הרכישה נכשלה';

  @override
  String get discardVideoTitle => 'למחוק את הסרטון?';

  @override
  String get discardVideoBody => 'ההקלטה הזו עדיין לא נשמרה בגלריה.';

  @override
  String get keep => 'השאר';

  @override
  String get discard => 'מחק';

  @override
  String get processing => 'מעבד…';

  @override
  String get applyingEffect => 'מחיל אפקט…';

  @override
  String get saved => 'נשמר ✓';

  @override
  String get saveToCameraRoll => 'שמירה בגלריה';

  @override
  String get micPermissionRequired => 'להקלטת וידאו נדרשת גישה למיקרופון.';

  @override
  String get recordingTooShort => 'ההקלטה קצרה מדי — החזיקו יותר זמן.';

  @override
  String get videoAssemblyFailed => 'יצירת הסרטון נכשלה. נסו שוב.';

  @override
  String get audioEffectFailed => 'אפקט הקול נכשל.';

  @override
  String get roomEntryPrompt => 'הזינו מזהה חדר כדי להתחיל שיחת וידאו עם מראה.';

  @override
  String get roomIdHint => 'מזהה חדר';

  @override
  String get mirrorSideTitle => 'צד המראה';

  @override
  String get joinCall => 'הצטרפות לשיחה';

  @override
  String failedToJoin(String error) {
    return 'ההצטרפות נכשלה: $error';
  }

  @override
  String get connecting => 'מתחבר…';

  @override
  String get share => 'שיתוף';

  @override
  String shareMessage(String url) {
    return 'נוצר עם Mirror Booth:‏ $url';
  }

  @override
  String get a11yTakePhoto => 'צילום תמונה';

  @override
  String get a11yStartRecording => 'התחלת הקלטת וידאו';

  @override
  String get a11yStopRecording => 'עצירת ההקלטה';

  @override
  String get a11ySwitchCamera => 'החלפת מצלמה';

  @override
  String get a11yMirrorAxis => 'ציר המראה';

  @override
  String get a11yRotation => 'סיבוב התמונה';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees מעלות';
  }

  @override
  String get a11yClose => 'סגירה';

  @override
  String get a11yToggleLog => 'הצגה או הסתרה של היומן';

  @override
  String unlockAllFor(String price) {
    return 'כל המסננים ב-$price';
  }
}
