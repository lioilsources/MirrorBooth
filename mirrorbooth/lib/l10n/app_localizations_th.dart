// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get filterNone => 'ไม่มี';

  @override
  String get filterGlow => 'เปล่งปลั่ง';

  @override
  String get filterSlim => 'หน้าเรียว';

  @override
  String get filterDoll => 'ตุ๊กตา';

  @override
  String get filterChibi => 'จิบิ';

  @override
  String get filterLips => 'ปาก';

  @override
  String get filterBigNose => 'จมูก';

  @override
  String get filterAlien => 'เอเลี่ยน';

  @override
  String get filterMelt => 'ละลาย';

  @override
  String get filterBigEars => 'หู';

  @override
  String get filterLongNeck => 'คอ';

  @override
  String get filterPencil => 'ดินสอ';

  @override
  String get filterComic => 'การ์ตูน';

  @override
  String get filterGlitch => 'กลิตช์';

  @override
  String get filterNeon => 'นีออน';

  @override
  String get filterThermal => 'ความร้อน';

  @override
  String get filterOil => 'สีน้ำมัน';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'ป๊อป';

  @override
  String get filterVampire => 'แวมไพร์';

  @override
  String get filterZombie => 'ซอมบี้';

  @override
  String get filterGhost => 'ผี';

  @override
  String get filterDemon => 'ปีศาจ';

  @override
  String get filterCyborg => 'ไซบอร์ก';

  @override
  String get filterFrozen => 'น้ำแข็ง';

  @override
  String get collectionPretty => 'สวย';

  @override
  String get collectionUgly => 'อัปลักษณ์';

  @override
  String get collectionArt => 'ศิลปะ';

  @override
  String get collectionFantasy => 'แฟนตาซี';

  @override
  String get audioEffectNone => 'ปกติ';

  @override
  String get audioEffectChiptune => '8 บิต';

  @override
  String get audioEffectSlowMo => 'ช้า';

  @override
  String get audioEffectChipmunk => 'ชิปมังก์';

  @override
  String get audioEffectEcho => 'เสียงก้อง';

  @override
  String get audioEffectUnderwater => 'ใต้น้ำ';

  @override
  String get audioEffectRobot => 'หุ่นยนต์';

  @override
  String get audioEffectReverse => 'ย้อนกลับ';

  @override
  String get mirrorSideLeftShort => 'ซ';

  @override
  String get mirrorSideRightShort => 'ข';

  @override
  String get mirrorSideLeft => 'ซ้าย';

  @override
  String get mirrorSideRight => 'ขวา';

  @override
  String get lensFront => 'หน้า';

  @override
  String get lensBack => 'หลัง';

  @override
  String get photoSaveFailedTitle => 'บันทึกรูปภาพไม่ได้';

  @override
  String get ok => 'ตกลง';

  @override
  String get galleryAccessDenied => 'การเข้าถึงคลังรูปภาพถูกปฏิเสธ';

  @override
  String get galleryNotEnoughSpace => 'พื้นที่จัดเก็บไม่เพียงพอ';

  @override
  String get galleryUnsupportedFormat => 'ไม่รองรับรูปแบบไฟล์นี้';

  @override
  String get genericError => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String shaderLoadError(String error) {
    return 'โหลดฟิลเตอร์ไม่ได้: $error';
  }

  @override
  String get cameraPermissionDenied => 'การเข้าถึงกล้องถูกปฏิเสธ';

  @override
  String get noCamerasAvailable => 'ไม่มีกล้องที่ใช้ได้';

  @override
  String get cameraStartFailed => 'เปิดกล้องไม่ได้';

  @override
  String get controlsHint => 'ลาก = หมุน  •  ⊙ = รูปภาพ  •  ● = วิดีโอ';

  @override
  String get controlsHintVolume => 'ปุ่มเสียง = รูปภาพ  •  กดค้าง = วิดีโอ';

  @override
  String collectionUnlocked(String collection) {
    return 'ปลดล็อกคอลเลกชัน $collection แล้ว ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'ฟิลเตอร์ $collection';
  }

  @override
  String get paywallPreviewFree =>
      'ดูตัวอย่างได้ฟรี ปลดล็อกเพื่อบันทึกรูปภาพและวิดีโอ';

  @override
  String get storeUnavailable => 'ร้านค้าไม่พร้อมใช้งาน';

  @override
  String get loadingPrice => 'กำลังโหลดราคา…';

  @override
  String unlockFor(String price) {
    return 'ปลดล็อกในราคา $price';
  }

  @override
  String get restorePurchases => 'กู้คืนการซื้อ';

  @override
  String get purchaseFailed => 'การซื้อล้มเหลว';

  @override
  String get discardVideoTitle => 'ทิ้งวิดีโอนี้ไหม';

  @override
  String get discardVideoBody => 'การบันทึกนี้ยังไม่ได้บันทึกลงในคลังภาพ';

  @override
  String get keep => 'เก็บไว้';

  @override
  String get discard => 'ทิ้ง';

  @override
  String get processing => 'กำลังประมวลผล…';

  @override
  String get applyingEffect => 'กำลังใส่เอฟเฟกต์…';

  @override
  String get saved => 'บันทึกแล้ว ✓';

  @override
  String get saveToCameraRoll => 'บันทึกลงคลังภาพ';

  @override
  String get micPermissionRequired =>
      'ต้องอนุญาตให้เข้าถึงไมโครโฟนเพื่อบันทึกวิดีโอ';

  @override
  String get recordingTooShort => 'บันทึกสั้นเกินไป — กดค้างให้นานขึ้น';

  @override
  String get videoAssemblyFailed => 'สร้างวิดีโอไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get audioEffectFailed => 'เอฟเฟกต์เสียงล้มเหลว';

  @override
  String get roomEntryPrompt => 'ใส่ ID ห้องเพื่อเริ่มวิดีโอคอลแบบกระจก';

  @override
  String get roomIdHint => 'ID ห้อง';

  @override
  String get mirrorSideTitle => 'ด้านกระจก';

  @override
  String get joinCall => 'เข้าร่วมการโทร';

  @override
  String failedToJoin(String error) {
    return 'เข้าร่วมไม่สำเร็จ: $error';
  }

  @override
  String get connecting => 'กำลังเชื่อมต่อ…';

  @override
  String get share => 'แชร์';

  @override
  String shareMessage(String url) {
    return 'สร้างด้วย Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'ถ่ายรูป';

  @override
  String get a11yStartRecording => 'เริ่มบันทึกวิดีโอ';

  @override
  String get a11yStopRecording => 'หยุดบันทึก';

  @override
  String get a11ySwitchCamera => 'สลับกล้อง';

  @override
  String get a11yMirrorAxis => 'แกนกระจก';

  @override
  String get a11yRotation => 'การหมุนภาพ';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees องศา';
  }

  @override
  String get a11yClose => 'ปิด';

  @override
  String get a11yToggleLog => 'แสดงหรือซ่อนบันทึก';

  @override
  String unlockAllFor(String price) {
    return 'ฟิลเตอร์ทั้งหมดในราคา $price';
  }
}
