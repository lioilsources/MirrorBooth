// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get filterNone => 'Tanpa';

  @override
  String get filterGlow => 'Kilau';

  @override
  String get filterSlim => 'Ramping';

  @override
  String get filterDoll => 'Boneka';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Bibir';

  @override
  String get filterBigNose => 'Hidung';

  @override
  String get filterAlien => 'Alien';

  @override
  String get filterMelt => 'Meleleh';

  @override
  String get filterBigEars => 'Telinga';

  @override
  String get filterLongNeck => 'Leher';

  @override
  String get filterPencil => 'Pensil';

  @override
  String get filterComic => 'Komik';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Panas';

  @override
  String get filterOil => 'Cat minyak';

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
  String get filterDemon => 'Iblis';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Beku';

  @override
  String get collectionPretty => 'Cantik';

  @override
  String get collectionUgly => 'Jelek';

  @override
  String get collectionArt => 'Seni';

  @override
  String get collectionFantasy => 'Fantasi';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Lambat';

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
  String get mirrorSideLeftShort => 'Ki';

  @override
  String get mirrorSideRightShort => 'Ka';

  @override
  String get mirrorSideLeft => 'Kiri';

  @override
  String get mirrorSideRight => 'Kanan';

  @override
  String get lensFront => 'DEPAN';

  @override
  String get lensBack => 'BELAKANG';

  @override
  String get photoSaveFailedTitle => 'Foto tidak dapat disimpan';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Akses ke galeri foto ditolak.';

  @override
  String get galleryNotEnoughSpace => 'Ruang penyimpanan tidak cukup.';

  @override
  String get galleryUnsupportedFormat => 'Format file ini tidak didukung.';

  @override
  String get genericError => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String shaderLoadError(String error) {
    return 'Filter tidak dapat dimuat: $error';
  }

  @override
  String get cameraPermissionDenied => 'Izin kamera ditolak';

  @override
  String get noCamerasAvailable => 'Tidak ada kamera tersedia';

  @override
  String get cameraStartFailed => 'Kamera tidak dapat dimulai.';

  @override
  String get controlsHint => 'geser = putar  •  ⊙ = foto  •  ● = video';

  @override
  String get controlsHintVolume => 'volume = foto  •  tahan volume = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Koleksi $collection terbuka ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filter $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Pratinjau gratis. Buka kunci untuk menyimpan foto dan video.';

  @override
  String get storeUnavailable => 'Toko tidak tersedia';

  @override
  String get loadingPrice => 'Memuat harga…';

  @override
  String unlockFor(String price) {
    return 'Buka seharga $price';
  }

  @override
  String get restorePurchases => 'Pulihkan pembelian';

  @override
  String get purchaseFailed => 'Pembelian gagal';

  @override
  String get discardVideoTitle => 'Buang video?';

  @override
  String get discardVideoBody => 'Rekaman ini belum disimpan ke galeri.';

  @override
  String get keep => 'Pertahankan';

  @override
  String get discard => 'Buang';

  @override
  String get processing => 'Memproses…';

  @override
  String get applyingEffect => 'Menerapkan efek…';

  @override
  String get saved => 'Tersimpan ✓';

  @override
  String get saveToCameraRoll => 'Simpan ke galeri';

  @override
  String get micPermissionRequired =>
      'Izin mikrofon diperlukan untuk merekam video.';

  @override
  String get recordingTooShort => 'Rekaman terlalu pendek — rekam lebih lama.';

  @override
  String get videoAssemblyFailed => 'Gagal membuat video. Silakan coba lagi.';

  @override
  String get audioEffectFailed => 'Efek audio gagal.';

  @override
  String get roomEntryPrompt =>
      'Masukkan ID ruang untuk memulai panggilan video cermin.';

  @override
  String get roomIdHint => 'ID ruang';

  @override
  String get mirrorSideTitle => 'Sisi cermin';

  @override
  String get joinCall => 'Gabung panggilan';

  @override
  String failedToJoin(String error) {
    return 'Gagal bergabung: $error';
  }

  @override
  String get connecting => 'Menghubungkan…';
}
