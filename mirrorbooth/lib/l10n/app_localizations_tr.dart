// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get filterNone => 'Yok';

  @override
  String get filterGlow => 'Işıltı';

  @override
  String get filterSlim => 'İnce';

  @override
  String get filterDoll => 'Bebek';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Dudak';

  @override
  String get filterBigNose => 'Burun';

  @override
  String get filterAlien => 'Uzaylı';

  @override
  String get filterMelt => 'Erime';

  @override
  String get filterBigEars => 'Kulak';

  @override
  String get filterLongNeck => 'Boyun';

  @override
  String get filterPencil => 'Kalem';

  @override
  String get filterComic => 'Çizgi roman';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Termal';

  @override
  String get filterOil => 'Yağlı boya';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampir';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Hayalet';

  @override
  String get filterDemon => 'İblis';

  @override
  String get filterCyborg => 'Siborg';

  @override
  String get filterFrozen => 'Ayaz';

  @override
  String get collectionPretty => 'Güzel';

  @override
  String get collectionUgly => 'Çirkin';

  @override
  String get collectionArt => 'Sanat';

  @override
  String get collectionFantasy => 'Fantastik';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Yavaş';

  @override
  String get audioEffectChipmunk => 'Sincap';

  @override
  String get audioEffectEcho => 'Yankı';

  @override
  String get audioEffectUnderwater => 'Su altı';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Ters';

  @override
  String get mirrorSideLeftShort => 'Sol';

  @override
  String get mirrorSideRightShort => 'Sağ';

  @override
  String get mirrorSideLeft => 'Sol';

  @override
  String get mirrorSideRight => 'Sağ';

  @override
  String get lensFront => 'ÖN';

  @override
  String get lensBack => 'ARKA';

  @override
  String get photoSaveFailedTitle => 'Fotoğraf kaydedilemedi';

  @override
  String get ok => 'Tamam';

  @override
  String get galleryAccessDenied => 'Fotoğraf arşivine erişim reddedildi.';

  @override
  String get galleryNotEnoughSpace => 'Yeterli depolama alanı yok.';

  @override
  String get galleryUnsupportedFormat => 'Bu dosya biçimi desteklenmiyor.';

  @override
  String get genericError => 'Bir sorun oluştu. Lütfen tekrar deneyin.';

  @override
  String shaderLoadError(String error) {
    return 'Filtreler yüklenemedi: $error';
  }

  @override
  String get cameraPermissionDenied => 'Kamera izni reddedildi';

  @override
  String get noCamerasAvailable => 'Kullanılabilir kamera yok';

  @override
  String get cameraStartFailed => 'Kamera başlatılamadı.';

  @override
  String get controlsHint => 'sürükle = döndür  •  ⊙ = fotoğraf  •  ● = video';

  @override
  String get controlsHintVolume => 'ses = fotoğraf  •  sesi basılı tut = video';

  @override
  String collectionUnlocked(String collection) {
    return '$collection koleksiyonunun kilidi açıldı ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection filtreleri';
  }

  @override
  String get paywallPreviewFree =>
      'Önizleme ücretsiz. Fotoğraf ve videoları kaydetmek için kilidi açın.';

  @override
  String get storeUnavailable => 'Mağaza kullanılamıyor';

  @override
  String get loadingPrice => 'Fiyat yükleniyor…';

  @override
  String unlockFor(String price) {
    return '$price karşılığında aç';
  }

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get purchaseFailed => 'Satın alma başarısız';

  @override
  String get discardVideoTitle => 'Video silinsin mi?';

  @override
  String get discardVideoBody => 'Bu kayıt film rulonuza kaydedilmedi.';

  @override
  String get keep => 'Sakla';

  @override
  String get discard => 'Sil';

  @override
  String get processing => 'İşleniyor…';

  @override
  String get applyingEffect => 'Efekt uygulanıyor…';

  @override
  String get saved => 'Kaydedildi ✓';

  @override
  String get saveToCameraRoll => 'Film rulosuna kaydet';

  @override
  String get micPermissionRequired => 'Video kaydı için mikrofon izni gerekli.';

  @override
  String get recordingTooShort => 'Kayıt çok kısa — daha uzun kaydedin.';

  @override
  String get videoAssemblyFailed =>
      'Video oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get audioEffectFailed => 'Ses efekti uygulanamadı.';

  @override
  String get roomEntryPrompt =>
      'Aynalı görüntülü görüşme başlatmak için bir oda kimliği girin.';

  @override
  String get roomIdHint => 'Oda kimliği';

  @override
  String get mirrorSideTitle => 'Ayna tarafı';

  @override
  String get joinCall => 'Görüşmeye katıl';

  @override
  String failedToJoin(String error) {
    return 'Katılınamadı: $error';
  }

  @override
  String get connecting => 'Bağlanıyor…';
}
