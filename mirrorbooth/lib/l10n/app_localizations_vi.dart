// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get filterNone => 'Không';

  @override
  String get filterGlow => 'Rạng rỡ';

  @override
  String get filterSlim => 'Thon gọn';

  @override
  String get filterDoll => 'Búp bê';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Môi';

  @override
  String get filterBigNose => 'Mũi';

  @override
  String get filterAlien => 'Người ngoài hành tinh';

  @override
  String get filterMelt => 'Tan chảy';

  @override
  String get filterBigEars => 'Tai';

  @override
  String get filterLongNeck => 'Cổ';

  @override
  String get filterPencil => 'Bút chì';

  @override
  String get filterComic => 'Truyện tranh';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Nhiệt';

  @override
  String get filterOil => 'Sơn dầu';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Ma cà rồng';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Bóng ma';

  @override
  String get filterDemon => 'Quỷ';

  @override
  String get filterCyborg => 'Người máy';

  @override
  String get filterFrozen => 'Băng giá';

  @override
  String get collectionPretty => 'Xinh';

  @override
  String get collectionUgly => 'Xấu';

  @override
  String get collectionArt => 'Nghệ thuật';

  @override
  String get collectionFantasy => 'Kỳ ảo';

  @override
  String get audioEffectNone => 'Bình thường';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Chậm';

  @override
  String get audioEffectChipmunk => 'Sóc chuột';

  @override
  String get audioEffectEcho => 'Tiếng vang';

  @override
  String get audioEffectUnderwater => 'Dưới nước';

  @override
  String get audioEffectRobot => 'Rô-bốt';

  @override
  String get audioEffectReverse => 'Đảo ngược';

  @override
  String get mirrorSideLeftShort => 'T';

  @override
  String get mirrorSideRightShort => 'P';

  @override
  String get mirrorSideLeft => 'Trái';

  @override
  String get mirrorSideRight => 'Phải';

  @override
  String get lensFront => 'TRƯỚC';

  @override
  String get lensBack => 'SAU';

  @override
  String get photoSaveFailedTitle => 'Không thể lưu ảnh';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied =>
      'Quyền truy cập thư viện ảnh đã bị từ chối.';

  @override
  String get galleryNotEnoughSpace => 'Không đủ dung lượng lưu trữ.';

  @override
  String get galleryUnsupportedFormat => 'Định dạng tệp này không được hỗ trợ.';

  @override
  String get genericError => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String shaderLoadError(String error) {
    return 'Không thể tải bộ lọc: $error';
  }

  @override
  String get cameraPermissionDenied => 'Quyền truy cập camera bị từ chối';

  @override
  String get noCamerasAvailable => 'Không có camera nào';

  @override
  String get cameraStartFailed => 'Không thể khởi động camera.';

  @override
  String get controlsHint => 'kéo = xoay  •  ⊙ = ảnh  •  ● = video';

  @override
  String get controlsHintVolume => 'âm lượng = ảnh  •  giữ âm lượng = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Đã mở khóa bộ sưu tập $collection ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Bộ lọc $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Xem trước miễn phí. Mở khóa để lưu ảnh và video.';

  @override
  String get storeUnavailable => 'Cửa hàng không khả dụng';

  @override
  String get loadingPrice => 'Đang tải giá…';

  @override
  String unlockFor(String price) {
    return 'Mở khóa với giá $price';
  }

  @override
  String get restorePurchases => 'Khôi phục giao dịch mua';

  @override
  String get purchaseFailed => 'Mua không thành công';

  @override
  String get discardVideoTitle => 'Bỏ video?';

  @override
  String get discardVideoBody => 'Bản ghi này chưa được lưu vào thư viện ảnh.';

  @override
  String get keep => 'Giữ lại';

  @override
  String get discard => 'Bỏ';

  @override
  String get processing => 'Đang xử lý…';

  @override
  String get applyingEffect => 'Đang áp dụng hiệu ứng…';

  @override
  String get saved => 'Đã lưu ✓';

  @override
  String get saveToCameraRoll => 'Lưu vào thư viện ảnh';

  @override
  String get micPermissionRequired => 'Cần quyền truy cập micrô để quay video.';

  @override
  String get recordingTooShort => 'Bản ghi quá ngắn — hãy giữ lâu hơn.';

  @override
  String get videoAssemblyFailed => 'Không thể tạo video. Vui lòng thử lại.';

  @override
  String get audioEffectFailed => 'Hiệu ứng âm thanh không thành công.';

  @override
  String get roomEntryPrompt =>
      'Nhập ID phòng để bắt đầu cuộc gọi video soi gương.';

  @override
  String get roomIdHint => 'ID phòng';

  @override
  String get mirrorSideTitle => 'Bên gương';

  @override
  String get joinCall => 'Tham gia cuộc gọi';

  @override
  String failedToJoin(String error) {
    return 'Không thể tham gia: $error';
  }

  @override
  String get connecting => 'Đang kết nối…';

  @override
  String get share => 'Chia sẻ';

  @override
  String shareMessage(String url) {
    return 'Tạo bằng Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Chụp ảnh';

  @override
  String get a11yStartRecording => 'Bắt đầu quay video';

  @override
  String get a11yStopRecording => 'Dừng quay';

  @override
  String get a11ySwitchCamera => 'Đổi camera';

  @override
  String get a11yMirrorAxis => 'Trục gương';

  @override
  String get a11yRotation => 'Xoay hình ảnh';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees độ';
  }

  @override
  String get a11yClose => 'Đóng';

  @override
  String get a11yToggleLog => 'Hiện hoặc ẩn nhật ký';

  @override
  String unlockAllFor(String price) {
    return 'Tất cả bộ lọc với giá $price';
  }
}
