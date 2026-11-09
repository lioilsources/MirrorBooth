// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get filterNone => 'Tiada';

  @override
  String get filterGlow => 'Sinar';

  @override
  String get filterSlim => 'Langsing';

  @override
  String get filterDoll => 'Anak patung';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Bibir';

  @override
  String get filterBigNose => 'Hidung';

  @override
  String get filterAlien => 'Makhluk asing';

  @override
  String get filterMelt => 'Cair';

  @override
  String get filterBigEars => 'Telinga';

  @override
  String get filterLongNeck => 'Leher';

  @override
  String get filterPencil => 'Pensel';

  @override
  String get filterComic => 'Komik';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Haba';

  @override
  String get filterOil => 'Minyak';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampir';

  @override
  String get filterZombie => 'Zombi';

  @override
  String get filterGhost => 'Hantu';

  @override
  String get filterDemon => 'Syaitan';

  @override
  String get filterCyborg => 'Siborg';

  @override
  String get filterFrozen => 'Fros';

  @override
  String get collectionPretty => 'Cantik';

  @override
  String get collectionUgly => 'Hodoh';

  @override
  String get collectionArt => 'Seni';

  @override
  String get collectionFantasy => 'Fantasi';

  @override
  String get audioEffectNone => 'Biasa';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Perlahan';

  @override
  String get audioEffectChipmunk => 'Tupai';

  @override
  String get audioEffectEcho => 'Gema';

  @override
  String get audioEffectUnderwater => 'Bawah air';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Terbalik';

  @override
  String get mirrorSideLeftShort => 'K';

  @override
  String get mirrorSideRightShort => 'N';

  @override
  String get mirrorSideLeft => 'Kiri';

  @override
  String get mirrorSideRight => 'Kanan';

  @override
  String get lensFront => 'DEPAN';

  @override
  String get lensBack => 'BELAKANG';

  @override
  String get photoSaveFailedTitle => 'Tidak dapat menyimpan foto';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Akses ke pustaka foto ditolak.';

  @override
  String get galleryNotEnoughSpace => 'Ruang storan tidak mencukupi.';

  @override
  String get galleryUnsupportedFormat => 'Format fail ini tidak disokong.';

  @override
  String get genericError => 'Ada masalah. Sila cuba lagi.';

  @override
  String shaderLoadError(String error) {
    return 'Tidak dapat memuatkan penapis: $error';
  }

  @override
  String get cameraPermissionDenied => 'Akses kamera ditolak';

  @override
  String get noCamerasAvailable => 'Tiada kamera tersedia';

  @override
  String get cameraStartFailed => 'Tidak dapat memulakan kamera.';

  @override
  String get controlsHint => 'seret = putar  •  ⊙ = foto  •  ● = video';

  @override
  String get controlsHintVolume => 'kelantangan = foto  •  tahan = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Koleksi $collection dibuka ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Penapis $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Pratonton adalah percuma. Buka kunci untuk menyimpan foto dan video.';

  @override
  String get storeUnavailable => 'Kedai tidak tersedia';

  @override
  String get loadingPrice => 'Memuatkan harga…';

  @override
  String unlockFor(String price) {
    return 'Buka kunci dengan $price';
  }

  @override
  String get restorePurchases => 'Pulihkan pembelian';

  @override
  String get purchaseFailed => 'Pembelian gagal';

  @override
  String get discardVideoTitle => 'Buang video?';

  @override
  String get discardVideoBody => 'Rakaman ini belum disimpan ke galeri anda.';

  @override
  String get keep => 'Simpan';

  @override
  String get discard => 'Buang';

  @override
  String get processing => 'Memproses…';

  @override
  String get applyingEffect => 'Menggunakan kesan…';

  @override
  String get saved => 'Disimpan ✓';

  @override
  String get saveToCameraRoll => 'Simpan ke galeri';

  @override
  String get micPermissionRequired =>
      'Akses mikrofon diperlukan untuk merakam video.';

  @override
  String get recordingTooShort => 'Rakaman terlalu pendek — tahan lebih lama.';

  @override
  String get videoAssemblyFailed => 'Video gagal dihasilkan. Sila cuba lagi.';

  @override
  String get audioEffectFailed => 'Kesan audio gagal.';

  @override
  String get roomEntryPrompt =>
      'Masukkan ID bilik untuk memulakan panggilan video bercermin.';

  @override
  String get roomIdHint => 'ID bilik';

  @override
  String get mirrorSideTitle => 'Sisi cermin';

  @override
  String get joinCall => 'Sertai panggilan';

  @override
  String failedToJoin(String error) {
    return 'Gagal menyertai: $error';
  }

  @override
  String get connecting => 'Menyambung…';

  @override
  String get share => 'Kongsi';

  @override
  String shareMessage(String url) {
    return 'Dibuat dengan Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Ambil foto';

  @override
  String get a11yStartRecording => 'Mula merakam video';

  @override
  String get a11yStopRecording => 'Henti merakam';

  @override
  String get a11ySwitchCamera => 'Tukar kamera';

  @override
  String get a11yMirrorAxis => 'Paksi cermin';

  @override
  String get a11yRotation => 'Putaran imej';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees darjah';
  }

  @override
  String get a11yClose => 'Tutup';

  @override
  String get a11yToggleLog => 'Tunjukkan atau sembunyikan log';

  @override
  String unlockAllFor(String price) {
    return 'Semua penapis dengan $price';
  }
}
