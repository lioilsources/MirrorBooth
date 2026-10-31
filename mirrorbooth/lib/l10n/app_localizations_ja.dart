// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get filterNone => 'なし';

  @override
  String get filterGlow => 'グロウ';

  @override
  String get filterSlim => 'スリム';

  @override
  String get filterDoll => 'ドール';

  @override
  String get filterChibi => 'ちび';

  @override
  String get filterLips => 'くちびる';

  @override
  String get filterBigNose => '鼻';

  @override
  String get filterAlien => 'エイリアン';

  @override
  String get filterMelt => 'とろける';

  @override
  String get filterBigEars => '耳';

  @override
  String get filterLongNeck => '首';

  @override
  String get filterPencil => '鉛筆';

  @override
  String get filterComic => 'コミック';

  @override
  String get filterGlitch => 'グリッチ';

  @override
  String get filterNeon => 'ネオン';

  @override
  String get filterThermal => 'サーモ';

  @override
  String get filterOil => '油絵';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'ポップ';

  @override
  String get filterVampire => 'ヴァンパイア';

  @override
  String get filterZombie => 'ゾンビ';

  @override
  String get filterGhost => 'ゴースト';

  @override
  String get filterDemon => 'デーモン';

  @override
  String get filterCyborg => 'サイボーグ';

  @override
  String get filterFrozen => 'フロスト';

  @override
  String get collectionPretty => 'かわいい';

  @override
  String get collectionUgly => 'へんがお';

  @override
  String get collectionArt => 'アート';

  @override
  String get collectionFantasy => 'ファンタジー';

  @override
  String get audioEffectNone => 'ノーマル';

  @override
  String get audioEffectChiptune => '8ビット';

  @override
  String get audioEffectSlowMo => 'スロー';

  @override
  String get audioEffectChipmunk => 'リス声';

  @override
  String get audioEffectEcho => 'エコー';

  @override
  String get audioEffectUnderwater => '水中';

  @override
  String get audioEffectRobot => 'ロボット';

  @override
  String get audioEffectReverse => '逆再生';

  @override
  String get mirrorSideLeftShort => '左';

  @override
  String get mirrorSideRightShort => '右';

  @override
  String get mirrorSideLeft => '左';

  @override
  String get mirrorSideRight => '右';

  @override
  String get lensFront => '前面';

  @override
  String get lensBack => '背面';

  @override
  String get photoSaveFailedTitle => '写真を保存できませんでした';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => '写真ライブラリへのアクセスが拒否されました。';

  @override
  String get galleryNotEnoughSpace => 'ストレージの空き容量が不足しています。';

  @override
  String get galleryUnsupportedFormat => 'このファイル形式には対応していません。';

  @override
  String get genericError => '問題が発生しました。もう一度お試しください。';

  @override
  String shaderLoadError(String error) {
    return 'フィルターを読み込めませんでした: $error';
  }

  @override
  String get cameraPermissionDenied => 'カメラへのアクセスが拒否されました';

  @override
  String get noCamerasAvailable => '利用できるカメラがありません';

  @override
  String get cameraStartFailed => 'カメラを起動できませんでした。';

  @override
  String get controlsHint => 'ドラッグ = 回転  •  ⊙ = 写真  •  ● = 動画';

  @override
  String get controlsHintVolume => '音量 = 写真  •  音量長押し = 動画';

  @override
  String collectionUnlocked(String collection) {
    return '$collectionコレクションをアンロックしました ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collectionフィルター';
  }

  @override
  String get paywallPreviewFree => 'プレビューは無料。写真や動画を保存するにはアンロックしてください。';

  @override
  String get storeUnavailable => 'ストアを利用できません';

  @override
  String get loadingPrice => '価格を読み込み中…';

  @override
  String unlockFor(String price) {
    return '$priceでアンロック';
  }

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get purchaseFailed => '購入に失敗しました';

  @override
  String get discardVideoTitle => '動画を破棄しますか？';

  @override
  String get discardVideoBody => 'この録画はカメラロールに保存されていません。';

  @override
  String get keep => '残す';

  @override
  String get discard => '破棄';

  @override
  String get processing => '処理中…';

  @override
  String get applyingEffect => 'エフェクトを適用中…';

  @override
  String get saved => '保存しました ✓';

  @override
  String get saveToCameraRoll => 'カメラロールに保存';

  @override
  String get micPermissionRequired => '動画を録画するにはマイクへのアクセスが必要です。';

  @override
  String get recordingTooShort => '録画が短すぎます。もう少し長く撮影してください。';

  @override
  String get videoAssemblyFailed => '動画を作成できませんでした。もう一度お試しください。';

  @override
  String get audioEffectFailed => 'オーディオエフェクトに失敗しました。';

  @override
  String get roomEntryPrompt => 'ルームIDを入力して、ミラービデオ通話を始めましょう。';

  @override
  String get roomIdHint => 'ルームID';

  @override
  String get mirrorSideTitle => 'ミラーの向き';

  @override
  String get joinCall => '通話に参加';

  @override
  String failedToJoin(String error) {
    return '参加できませんでした: $error';
  }

  @override
  String get connecting => '接続中…';

  @override
  String get share => '共有';

  @override
  String shareMessage(String url) {
    return 'Mirror Boothで作成: $url';
  }
}
