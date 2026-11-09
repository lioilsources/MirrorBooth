// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get filterNone => '无';

  @override
  String get filterGlow => '光彩';

  @override
  String get filterSlim => '瘦脸';

  @override
  String get filterDoll => '娃娃';

  @override
  String get filterChibi => 'Q版';

  @override
  String get filterLips => '嘴唇';

  @override
  String get filterBigNose => '大鼻子';

  @override
  String get filterAlien => '外星人';

  @override
  String get filterMelt => '融化';

  @override
  String get filterBigEars => '大耳朵';

  @override
  String get filterLongNeck => '长脖子';

  @override
  String get filterPencil => '铅笔';

  @override
  String get filterComic => '漫画';

  @override
  String get filterGlitch => '故障';

  @override
  String get filterNeon => '霓虹';

  @override
  String get filterThermal => '热感';

  @override
  String get filterOil => '油画';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => '波普';

  @override
  String get filterVampire => '吸血鬼';

  @override
  String get filterZombie => '僵尸';

  @override
  String get filterGhost => '幽灵';

  @override
  String get filterDemon => '恶魔';

  @override
  String get filterCyborg => '赛博格';

  @override
  String get filterFrozen => '冰霜';

  @override
  String get collectionPretty => '美颜';

  @override
  String get collectionUgly => '丑萌';

  @override
  String get collectionArt => '艺术';

  @override
  String get collectionFantasy => '奇幻';

  @override
  String get audioEffectNone => '原声';

  @override
  String get audioEffectChiptune => '8 位';

  @override
  String get audioEffectSlowMo => '慢速';

  @override
  String get audioEffectChipmunk => '花栗鼠';

  @override
  String get audioEffectEcho => '回声';

  @override
  String get audioEffectUnderwater => '水下';

  @override
  String get audioEffectRobot => '机器人';

  @override
  String get audioEffectReverse => '倒放';

  @override
  String get mirrorSideLeftShort => '左';

  @override
  String get mirrorSideRightShort => '右';

  @override
  String get mirrorSideLeft => '左侧';

  @override
  String get mirrorSideRight => '右侧';

  @override
  String get lensFront => '前置';

  @override
  String get lensBack => '后置';

  @override
  String get photoSaveFailedTitle => '无法保存照片';

  @override
  String get ok => '好';

  @override
  String get galleryAccessDenied => '照片图库访问被拒绝。';

  @override
  String get galleryNotEnoughSpace => '存储空间不足。';

  @override
  String get galleryUnsupportedFormat => '不支持此文件格式。';

  @override
  String get genericError => '出了点问题，请重试。';

  @override
  String shaderLoadError(String error) {
    return '无法加载滤镜：$error';
  }

  @override
  String get cameraPermissionDenied => '相机权限被拒绝';

  @override
  String get noCamerasAvailable => '没有可用的相机';

  @override
  String get cameraStartFailed => '无法启动相机。';

  @override
  String get controlsHint => '拖动 = 旋转  •  ⊙ = 拍照  •  ● = 录像';

  @override
  String get controlsHintVolume => '音量键 = 拍照  •  长按音量键 = 录像';

  @override
  String collectionUnlocked(String collection) {
    return '已解锁“$collection”合集 ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '“$collection”滤镜';
  }

  @override
  String get paywallPreviewFree => '预览免费。解锁后即可保存照片和视频。';

  @override
  String get storeUnavailable => '商店不可用';

  @override
  String get loadingPrice => '正在加载价格…';

  @override
  String unlockFor(String price) {
    return '$price 解锁';
  }

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get purchaseFailed => '购买失败';

  @override
  String get discardVideoTitle => '放弃视频？';

  @override
  String get discardVideoBody => '这段录像尚未保存到相册。';

  @override
  String get keep => '保留';

  @override
  String get discard => '放弃';

  @override
  String get processing => '正在处理…';

  @override
  String get applyingEffect => '正在应用效果…';

  @override
  String get saved => '已保存 ✓';

  @override
  String get saveToCameraRoll => '保存到相册';

  @override
  String get micPermissionRequired => '录制视频需要麦克风权限。';

  @override
  String get recordingTooShort => '录制时间太短，请按住更久。';

  @override
  String get videoAssemblyFailed => '视频生成失败，请重试。';

  @override
  String get audioEffectFailed => '音效处理失败。';

  @override
  String get roomEntryPrompt => '输入房间 ID，开始镜像视频通话。';

  @override
  String get roomIdHint => '房间 ID';

  @override
  String get mirrorSideTitle => '镜像侧';

  @override
  String get joinCall => '加入通话';

  @override
  String failedToJoin(String error) {
    return '加入失败：$error';
  }

  @override
  String get connecting => '正在连接…';

  @override
  String get share => '分享';

  @override
  String shareMessage(String url) {
    return '用 Mirror Booth 制作：$url';
  }

  @override
  String get a11yTakePhoto => '拍照';

  @override
  String get a11yStartRecording => '开始录像';

  @override
  String get a11yStopRecording => '停止录像';

  @override
  String get a11ySwitchCamera => '切换相机';

  @override
  String get a11yMirrorAxis => '镜像轴';

  @override
  String get a11yRotation => '画面旋转';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees 度';
  }

  @override
  String get a11yClose => '关闭';

  @override
  String get a11yToggleLog => '显示或隐藏日志';

  @override
  String unlockAllFor(String price) {
    return '$price 解锁全部滤镜';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get filterNone => '無';

  @override
  String get filterGlow => '光彩';

  @override
  String get filterSlim => '瘦臉';

  @override
  String get filterDoll => '娃娃';

  @override
  String get filterChibi => 'Q版';

  @override
  String get filterLips => '嘴唇';

  @override
  String get filterBigNose => '大鼻子';

  @override
  String get filterAlien => '外星人';

  @override
  String get filterMelt => '融化';

  @override
  String get filterBigEars => '大耳朵';

  @override
  String get filterLongNeck => '長脖子';

  @override
  String get filterPencil => '鉛筆';

  @override
  String get filterComic => '漫畫';

  @override
  String get filterGlitch => '故障';

  @override
  String get filterNeon => '霓虹';

  @override
  String get filterThermal => '熱感';

  @override
  String get filterOil => '油畫';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => '普普';

  @override
  String get filterVampire => '吸血鬼';

  @override
  String get filterZombie => '殭屍';

  @override
  String get filterGhost => '幽靈';

  @override
  String get filterDemon => '惡魔';

  @override
  String get filterCyborg => '生化人';

  @override
  String get filterFrozen => '冰霜';

  @override
  String get collectionPretty => '美顏';

  @override
  String get collectionUgly => '醜萌';

  @override
  String get collectionArt => '藝術';

  @override
  String get collectionFantasy => '奇幻';

  @override
  String get audioEffectNone => '原聲';

  @override
  String get audioEffectChiptune => '8 位元';

  @override
  String get audioEffectSlowMo => '慢速';

  @override
  String get audioEffectChipmunk => '花栗鼠';

  @override
  String get audioEffectEcho => '回音';

  @override
  String get audioEffectUnderwater => '水下';

  @override
  String get audioEffectRobot => '機器人';

  @override
  String get audioEffectReverse => '倒放';

  @override
  String get mirrorSideLeftShort => '左';

  @override
  String get mirrorSideRightShort => '右';

  @override
  String get mirrorSideLeft => '左側';

  @override
  String get mirrorSideRight => '右側';

  @override
  String get lensFront => '前置';

  @override
  String get lensBack => '後置';

  @override
  String get photoSaveFailedTitle => '無法儲存照片';

  @override
  String get ok => '好';

  @override
  String get galleryAccessDenied => '照片圖庫的存取權遭拒。';

  @override
  String get galleryNotEnoughSpace => '儲存空間不足。';

  @override
  String get galleryUnsupportedFormat => '不支援此檔案格式。';

  @override
  String get genericError => '發生錯誤，請再試一次。';

  @override
  String shaderLoadError(String error) {
    return '無法載入濾鏡：$error';
  }

  @override
  String get cameraPermissionDenied => '相機權限遭拒';

  @override
  String get noCamerasAvailable => '沒有可用的相機';

  @override
  String get cameraStartFailed => '無法啟動相機。';

  @override
  String get controlsHint => '拖曳 = 旋轉  •  ⊙ = 拍照  •  ● = 錄影';

  @override
  String get controlsHintVolume => '音量鍵 = 拍照  •  長按音量鍵 = 錄影';

  @override
  String collectionUnlocked(String collection) {
    return '已解鎖「$collection」系列 ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '「$collection」濾鏡';
  }

  @override
  String get paywallPreviewFree => '預覽免費。解鎖後即可儲存照片和影片。';

  @override
  String get storeUnavailable => '商店無法使用';

  @override
  String get loadingPrice => '正在載入價格…';

  @override
  String unlockFor(String price) {
    return '以 $price 解鎖';
  }

  @override
  String get restorePurchases => '恢復購買項目';

  @override
  String get purchaseFailed => '購買失敗';

  @override
  String get discardVideoTitle => '要捨棄影片嗎？';

  @override
  String get discardVideoBody => '這段錄影尚未儲存到相簿。';

  @override
  String get keep => '保留';

  @override
  String get discard => '捨棄';

  @override
  String get processing => '正在處理…';

  @override
  String get applyingEffect => '正在套用效果…';

  @override
  String get saved => '已儲存 ✓';

  @override
  String get saveToCameraRoll => '儲存到相簿';

  @override
  String get micPermissionRequired => '錄製影片需要麥克風權限。';

  @override
  String get recordingTooShort => '錄影時間太短，請按住久一點。';

  @override
  String get videoAssemblyFailed => '影片製作失敗，請再試一次。';

  @override
  String get audioEffectFailed => '音效處理失敗。';

  @override
  String get roomEntryPrompt => '輸入房間 ID，開始鏡像視訊通話。';

  @override
  String get roomIdHint => '房間 ID';

  @override
  String get mirrorSideTitle => '鏡像側';

  @override
  String get joinCall => '加入通話';

  @override
  String failedToJoin(String error) {
    return '加入失敗：$error';
  }

  @override
  String get connecting => '正在連線…';

  @override
  String get share => '分享';

  @override
  String shareMessage(String url) {
    return '用 Mirror Booth 製作：$url';
  }

  @override
  String get a11yTakePhoto => '拍照';

  @override
  String get a11yStartRecording => '開始錄影';

  @override
  String get a11yStopRecording => '停止錄影';

  @override
  String get a11ySwitchCamera => '切換相機';

  @override
  String get a11yMirrorAxis => '鏡像軸';

  @override
  String get a11yRotation => '畫面旋轉';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees 度';
  }

  @override
  String get a11yClose => '關閉';

  @override
  String get a11yToggleLog => '顯示或隱藏記錄';

  @override
  String unlockAllFor(String price) {
    return '以 $price 解鎖全部濾鏡';
  }
}
