// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get filterNone => 'Κανένα';

  @override
  String get filterGlow => 'Λάμψη';

  @override
  String get filterSlim => 'Λεπτό';

  @override
  String get filterDoll => 'Κούκλα';

  @override
  String get filterChibi => 'Τσίμπι';

  @override
  String get filterLips => 'Χείλη';

  @override
  String get filterBigNose => 'Μύτη';

  @override
  String get filterAlien => 'Εξωγήινος';

  @override
  String get filterMelt => 'Λιώσιμο';

  @override
  String get filterBigEars => 'Αυτιά';

  @override
  String get filterLongNeck => 'Λαιμός';

  @override
  String get filterPencil => 'Μολύβι';

  @override
  String get filterComic => 'Κόμικ';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Νέον';

  @override
  String get filterThermal => 'Θερμό';

  @override
  String get filterOil => 'Λάδι';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Ποπ';

  @override
  String get filterVampire => 'Βρικόλακας';

  @override
  String get filterZombie => 'Ζόμπι';

  @override
  String get filterGhost => 'Φάντασμα';

  @override
  String get filterDemon => 'Δαίμονας';

  @override
  String get filterCyborg => 'Σάιμποργκ';

  @override
  String get filterFrozen => 'Παγωνιά';

  @override
  String get collectionPretty => 'Όμορφα';

  @override
  String get collectionUgly => 'Άσχημα';

  @override
  String get collectionArt => 'Τέχνη';

  @override
  String get collectionFantasy => 'Φαντασία';

  @override
  String get audioEffectNone => 'Κανονικό';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Αργά';

  @override
  String get audioEffectChipmunk => 'Σκιουράκι';

  @override
  String get audioEffectEcho => 'Ηχώ';

  @override
  String get audioEffectUnderwater => 'Υποβρύχια';

  @override
  String get audioEffectRobot => 'Ρομπότ';

  @override
  String get audioEffectReverse => 'Ανάποδα';

  @override
  String get mirrorSideLeftShort => 'Α';

  @override
  String get mirrorSideRightShort => 'Δ';

  @override
  String get mirrorSideLeft => 'Αριστερά';

  @override
  String get mirrorSideRight => 'Δεξιά';

  @override
  String get lensFront => 'ΜΠΡΟΣΤΑ';

  @override
  String get lensBack => 'ΠΙΣΩ';

  @override
  String get photoSaveFailedTitle =>
      'Δεν ήταν δυνατή η αποθήκευση της φωτογραφίας';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'Η πρόσβαση στη βιβλιοθήκη φωτογραφιών απορρίφθηκε.';

  @override
  String get galleryNotEnoughSpace =>
      'Δεν υπάρχει αρκετός αποθηκευτικός χώρος.';

  @override
  String get galleryUnsupportedFormat =>
      'Αυτή η μορφή αρχείου δεν υποστηρίζεται.';

  @override
  String get genericError => 'Κάτι πήγε στραβά. Δοκίμασε ξανά.';

  @override
  String shaderLoadError(String error) {
    return 'Δεν ήταν δυνατή η φόρτωση των φίλτρων: $error';
  }

  @override
  String get cameraPermissionDenied => 'Η πρόσβαση στην κάμερα απορρίφθηκε';

  @override
  String get noCamerasAvailable => 'Δεν υπάρχει διαθέσιμη κάμερα';

  @override
  String get cameraStartFailed => 'Δεν ήταν δυνατή η εκκίνηση της κάμερας.';

  @override
  String get controlsHint => 'σύρε = περιστροφή  •  ⊙ = φωτό  •  ● = βίντεο';

  @override
  String get controlsHintVolume =>
      'ένταση = φωτό  •  κράτα την ένταση = βίντεο';

  @override
  String collectionUnlocked(String collection) {
    return 'Η συλλογή $collection ξεκλειδώθηκε ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Φίλτρα $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Η προεπισκόπηση είναι δωρεάν. Ξεκλείδωσε για να αποθηκεύεις φωτογραφίες και βίντεο.';

  @override
  String get storeUnavailable => 'Το κατάστημα δεν είναι διαθέσιμο';

  @override
  String get loadingPrice => 'Φόρτωση τιμής…';

  @override
  String unlockFor(String price) {
    return 'Ξεκλείδωμα με $price';
  }

  @override
  String get restorePurchases => 'Επαναφορά αγορών';

  @override
  String get purchaseFailed => 'Η αγορά απέτυχε';

  @override
  String get discardVideoTitle => 'Απόρριψη βίντεο;';

  @override
  String get discardVideoBody =>
      'Αυτή η εγγραφή δεν έχει αποθηκευτεί στη συλλογή.';

  @override
  String get keep => 'Διατήρηση';

  @override
  String get discard => 'Απόρριψη';

  @override
  String get processing => 'Επεξεργασία…';

  @override
  String get applyingEffect => 'Εφαρμογή εφέ…';

  @override
  String get saved => 'Αποθηκεύτηκε ✓';

  @override
  String get saveToCameraRoll => 'Αποθήκευση στη συλλογή';

  @override
  String get micPermissionRequired =>
      'Για την εγγραφή βίντεο απαιτείται πρόσβαση στο μικρόφωνο.';

  @override
  String get recordingTooShort => 'Πολύ σύντομη εγγραφή — κράτα περισσότερο.';

  @override
  String get videoAssemblyFailed =>
      'Η δημιουργία του βίντεο απέτυχε. Δοκίμασε ξανά.';

  @override
  String get audioEffectFailed => 'Το ηχητικό εφέ απέτυχε.';

  @override
  String get roomEntryPrompt =>
      'Εισήγαγε ένα ID δωματίου για να ξεκινήσεις βιντεοκλήση με καθρέφτη.';

  @override
  String get roomIdHint => 'ID δωματίου';

  @override
  String get mirrorSideTitle => 'Πλευρά καθρέφτη';

  @override
  String get joinCall => 'Συμμετοχή στην κλήση';

  @override
  String failedToJoin(String error) {
    return 'Η συμμετοχή απέτυχε: $error';
  }

  @override
  String get connecting => 'Σύνδεση…';

  @override
  String get share => 'Κοινοποίηση';

  @override
  String shareMessage(String url) {
    return 'Φτιαγμένο με το Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Λήψη φωτογραφίας';

  @override
  String get a11yStartRecording => 'Έναρξη εγγραφής βίντεο';

  @override
  String get a11yStopRecording => 'Διακοπή εγγραφής';

  @override
  String get a11ySwitchCamera => 'Αλλαγή κάμερας';

  @override
  String get a11yMirrorAxis => 'Άξονας καθρέφτη';

  @override
  String get a11yRotation => 'Περιστροφή εικόνας';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees μοίρες';
  }

  @override
  String get a11yClose => 'Κλείσιμο';

  @override
  String get a11yToggleLog => 'Εμφάνιση ή απόκρυψη αρχείου καταγραφής';

  @override
  String unlockAllFor(String price) {
    return 'Όλα τα φίλτρα με $price';
  }
}
